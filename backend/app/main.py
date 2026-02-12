from fastapi import FastAPI, Request
import os
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import db, connect_to_mongo, close_mongo_connection, connect_to_redis, close_redis_connection
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, RedirectResponse
import uvicorn
import asyncio
import httpx
from fastapi import BackgroundTasks

from app.api.user_routes import router as user_router
from app.api.chat_routes import router as chat_router
from app.api.auth import router as auth_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

app.include_router(user_router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
app.include_router(chat_router, prefix=f"{settings.API_V1_STR}/chat", tags=["chat"])
app.include_router(auth_router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
)

# Mount static files for Admin Dashboard
# Use absolute path to ensure it works in all environments
base_path = os.path.dirname(os.path.abspath(__file__))
static_path = os.path.join(base_path, "static")
if os.path.exists(static_path):
    app.mount("/static", StaticFiles(directory=static_path), name="static")

@app.get("/admin", response_class=HTMLResponse)
async def admin_index():
    index_path = os.path.join(static_path, "admin", "index.html")
    if os.path.exists(index_path):
        with open(index_path, "r", encoding="utf-8") as f:
            return f.read()
    return "Admin interface not found."

from app.core.security import get_password_hash
from datetime import datetime

@app.on_event("startup")
async def startup_event():
    print("STARTUP: Initializing application...")
    
    # 1. Attempt initial DB connection (non-blocking failure allows app to start)
    await connect_to_mongo()
    
    # 2. Secure Admin Seeding
    try:
        if db.db:  # Only seed if DB is connected
            admin_email = os.environ.get("ADMIN_EMAIL")
            admin_password = os.environ.get("ADMIN_PASSWORD")
            
            if admin_email and admin_password:
                print(f"STARTUP: Configuring Admin User: {admin_email}")
                database = db.get_db()
                existing_admin = await database.users.find_one({"email": admin_email})
                hashed_pw = get_password_hash(admin_password)
                
                if existing_admin:
                    await database.users.update_one(
                        {"email": admin_email},
                        {"$set": {"hashed_password": hashed_pw, "role": "admin", "is_active": True, "isBlocked": False}}
                    )
                    print("STARTUP: Admin user updated.")
                else:
                    new_admin = {
                        "email": admin_email,
                        "hashed_password": hashed_pw,
                        "name": "Super Admin",
                        "role": "admin",
                        "is_active": True,
                        "isBlocked": False,
                        "created_at": datetime.utcnow(),
                        "settings": {"animations_enabled": True}
                    }
                    await database.users.insert_one(new_admin)
                    print("STARTUP: Admin user created.")
    except Exception as e:
        print(f"STARTUPING WARNING: Admin seeding failed (DB might be down): {e}")

    # 3. Start Background Maintenance Tasks
    # These tasks run forever to keep the app healthy and awake
    asyncio.create_task(keep_alive())
    asyncio.create_task(maintain_database_connection())
    
    print("STARTUP: All systems go. Maintenance tasks started.")

async def maintain_database_connection():
    """Continuously checks DB connection and reconnects if dropped."""
    print("MAINTENANCE: Database monitor started.")
    while True:
        try:
            if db.client is None or db.db is None:
                print("MAINTENANCE: Database disconnected. Attempting reconnection...")
                await connect_to_mongo()
            else:
                # Optional: Send a ping to verify connection is actually alive
                try:
                    await db.client.admin.command('ping')
                except Exception:
                    print("MAINTENANCE: DB Ping failed. Resetting connection...")
                    db.client = None
                    db.db = None
        except Exception as e:
            print(f"MAINTENANCE: Error in DB monitor: {e}")
        
        await asyncio.sleep(60)  # Check every minute

async def keep_alive():
    """
    Pings the server's own health endpoint to prevent inactivity sleep.
    Works for platforms that count internal traffic or outbound requests.
    """
    url = os.environ.get("RENDER_EXTERNAL_URL") or os.environ.get("SERVER_URL") 
    if not url:
        print("MAINTENANCE: No RENDER_EXTERNAL_URL set. Self-ping disabled. (Server might sleep)")
        # Fallback to local if just for testing logs
        url = f"http://localhost:{os.environ.get('PORT', '8000')}"

    print(f"MAINTENANCE: Keep-alive task running for {url}")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        while True:
            try:
                # Ping health endpoint
                resp = await client.get(f"{url}/health")
                if resp.status_code != 200:
                    print(f"MAINTENANCE WARNING: Health check returned {resp.status_code}")
                # We don't print success every time to avoid log spam, maybe every 10th time?
                # But user wants monitoring, so let's log connection errors at least.
            except Exception as e:
                print(f"MAINTENANCE WARNING: Self-ping failed: {e}")
            
            # Sleep for 14 minutes (Render sleeps after 15)
            await asyncio.sleep(840) 


@app.on_event("shutdown")
async def shutdown_event():
    await close_mongo_connection()
    # await close_redis_connection() # Uncomment if Redis is set up

@app.get("/")
def read_root():
    return {"message": f"Welcome to {settings.PROJECT_NAME} API. Visit /admin for the dashboard."}

@app.get("/health")
async def health_check():
    db_status = "unconnected"
    try:
        if db.client:
            # Short timeout for health check ping
            await db.client.admin.command('ping', serverSelectionTimeoutMS=2000)
            db_status = "connected"
        else:
            db_status = "no client"
    except Exception as e:
        db_status = f"error: {str(e)}"
    
    return {
        "status": "healthy",
        "database": db_status,
        "environment": "Render" if os.environ.get("RENDER") else "Local",
        "port": os.environ.get("PORT", "8000 (default)")
    }

if __name__ == "__main__":
    # This block is used for local development
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    print(f"Starting server on port {port}...")
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)
