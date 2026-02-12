import asyncio
import os
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

# Explicitly load .env file
load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL")
DATABASE_NAME = os.getenv("DATABASE_NAME", "black_ai_db")

if not MONGODB_URL:
    # Try getting from config as fallback
    try:
        from app.core.config import settings
        MONGODB_URL = settings.MONGODB_URL
        if not DATABASE_NAME:
            DATABASE_NAME = settings.DATABASE_NAME
    except ImportError:
        pass

if not MONGODB_URL:
    print("Error: MONGODB_URL not found in environment variables.")
    exit(1)

async def list_users():
    # Hide password in connection log
    safe_url = MONGODB_URL
    if "@" in safe_url:
        safe_url = safe_url.split("@")[-1]
    
    print(f"Connecting to MongoDB at {safe_url}...")
    
    try:
        client = AsyncIOMotorClient(MONGODB_URL)
        db = client[DATABASE_NAME]
        
        print("\n--- Registered Users ---")
        print(f"{'ID':<30} | {'Email':<30} | {'Name':<20} | {'Roles'}")
        print("-" * 100)
        
        cursor = db.users.find({})
        users_list = await cursor.to_list(length=100)
        
        if not users_list:
            print("No users found.")
        
        for user in users_list:
            user_id = str(user["_id"])
            email = user.get("email", "N/A")
            name = user.get("name", "N/A")
            role = user.get("role", "user")
            
            print(f"{user_id:<30} | {email:<30} | {name:<20} | {role}")
            
        print("-" * 100)
        print(f"Total Users: {len(users_list)}\n")
        
    except Exception as e:
        print(f"Error listing users: {e}")

if __name__ == "__main__":
    try:
        asyncio.run(list_users())
    except Exception as e:
        print(f"Script Error: {e}")
