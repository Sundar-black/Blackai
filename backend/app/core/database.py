from motor.motor_asyncio import AsyncIOMotorClient
from redis import asyncio as aioredis
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class Database:
    client: AsyncIOMotorClient = None
    db = None
    redis = None

    def get_db(self):
        if self.db is None:
            from fastapi import HTTPException
            raise HTTPException(
                status_code=503, 
                detail="Database connection is not active. Please check MongoDB whitelisting."
            )
        return self.db

db = Database()

async def connect_to_mongo():
    if not settings.MONGODB_URL:
        logger.warning("MONGODB_URL is not set. Database features will not work.")
        return
        
    try:
        # Set a short selection timeout so startup doesn't hang forever if DB is down
        print("MONGO: Initializing client...")
        db.client = AsyncIOMotorClient(
            settings.MONGODB_URL,
            serverSelectionTimeoutMS=5000  # 5 seconds timeout
        )
        # Verify connection
        print("MONGO: Pinging admin...")
        await db.client.admin.command('ping')
        db.db = db.client[settings.DATABASE_NAME]
        print(f"MONGO: Successfully connected (Database: {settings.DATABASE_NAME})")
        logger.info(f"Successfully connected to MongoDB Cloud (Database: {settings.DATABASE_NAME})")
    except Exception as e:
        print(f"MONGO CONNECTION ERROR: {e}")
        logger.error("!!!" + "="*40)
        logger.error(f"CRITICAL: FAILED to connect to MongoDB Cloud: {e}")
        logger.error("TIPS:")
        logger.error("1. Check if MONGODB_URL is correctly set in Render environment variables.")
        logger.error("2. Check if Render's IP is whitelisted in MongoDB Atlas (Network Access -> Allow Access from Anywhere 0.0.0.0/0).")
        logger.error("3. Check if your MongoDB username/password in URL are correct.")
        logger.error("="*40 + "!!!")
        # We don't raise the error so the app can still start and serve the /health page

async def close_mongo_connection():
    db.client.close()
    logger.info("Closed MongoDB connection")

async def connect_to_redis():
    db.redis = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
    logger.info("Connected to Redis")

async def close_redis_connection():
    if db.redis:
        await db.redis.close()
        logger.info("Closed Redis connection")
