import asyncio
import os
from app.core.security import get_password_hash
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

async def create_admin():
    load_dotenv()
    
    MONGODB_URL = os.getenv("MONGODB_URL")
    DATABASE_NAME = os.getenv("DATABASE_NAME", "black_ai_db")
    
    if not MONGODB_URL:
        print("Error: MONGODB_URL not found.")
        return

    client = AsyncIOMotorClient(MONGODB_URL)
    database = client[DATABASE_NAME]

    email = "sundarbaskar2411@gmail.com"
    password = "Sundar@123"
    
    print(f"Hashing password for {email}...")
    hashed_password = get_password_hash(password)

    user_data = {
        "email": email,
        "hashed_password": hashed_password,
        "name": "Sundar Baskar",
        "full_name": "Sundar Baskar",
        "role": "admin",
        "is_active": True,
        "isBlocked": False,
        "created_at": datetime.utcnow(),
        "settings": {
             "animations_enabled": True,
             "selected_language": "English",
             "auto_language_match": True,
             "response_tone": "Friendly",
             "answer_length": "Detailed",
             "ai_personalization": 0.7
        }
    }

    # Check if user exists
    existing = await database.users.find_one({"email": email})
    
    if existing:
        print(f"User {email} already exists. Updating password and role...")
        await database.users.update_one(
            {"email": email},
            {"$set": {
                "hashed_password": hashed_password,
                "role": "admin",
                "is_active": True,
                "isBlocked": False,
                "settings": user_data["settings"] # Ensure settings exist
            }}
        )
        print("User updated successfully.")
    else:
        print(f"Creating new admin user {email}...")
        await database.users.insert_one(user_data)
        print("User created successfully.")

if __name__ == "__main__":
    asyncio.run(create_admin())
