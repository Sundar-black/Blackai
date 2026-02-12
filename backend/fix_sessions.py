import asyncio
from app.core.database import connect_to_mongo, db

async def fix_sessions():
    await connect_to_mongo()
    # Get the first user
    user = await db.db.users.find_one({})
    if user:
        user_id = str(user["_id"])
        print(f"Fixing sessions to belong to user: {user_id} ({user.get('email')})")
        result = await db.db.sessions.update_many({}, {"$set": {"user_id": user_id}})
        print(f"Matched: {result.matched_count}, Modified: {result.modified_count}")
    else:
        print("No users found to assign sessions to.")

if __name__ == "__main__":
    asyncio.run(fix_sessions())
