import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv

load_dotenv()

async def test_mongo():
    url = os.getenv("MONGODB_URL")
    print(f"Testing connection to: {url}")
    try:
        client = AsyncIOMotorClient(url, serverSelectionTimeoutMS=10000)
        await client.admin.command('ping')
        print("MongoDB Ping Successful!")
    except Exception as e:
        print(f"MongoDB Connection Failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_mongo())
