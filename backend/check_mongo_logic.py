import asyncio
from app.core.database import connect_to_mongo, db
from app.core.config import settings

async def check():
    print(f"URL: {settings.MONGODB_URL[:20]}...")
    await connect_to_mongo()
    if db.db is not None:
        print("Success! db.db is set.")
    else:
        print("Failure! db.db is None.")

if __name__ == "__main__":
    asyncio.run(check())
