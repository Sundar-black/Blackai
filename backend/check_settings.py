from app.core.config import settings
print(f"MONGODB_URL: {settings.MONGODB_URL[:20]}...")
print(f"DATABASE_NAME: {settings.DATABASE_NAME}")
print(f"PROJECT_NAME: {settings.PROJECT_NAME}")
