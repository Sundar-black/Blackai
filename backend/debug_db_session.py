import asyncio
from app.core.database import connect_to_mongo, db
from bson import ObjectId

async def check_session():
    await connect_to_mongo()
    try:
        session_id = "6985d2683992ba2b9b2bc486" # From the error log provided by user earlier (though ID looks a bit custom/short for ObjectId? Wait, 24 hex chars is standard. The user provided ID 6985d2683992ba2b9b2bc486 seems to be 24 chars.)
        # Wait, 6985d2683992ba2b9b2bc486 is 24 chars. (6+8+8+2 = 24? No. 6985 d268 3992 ba2b 9b2b c486)
        # 0x69... is valid.
        
        # Let's just list all sessions to be safe if ID is wrong
        print("--- All Sessions ---")
        async for s in db.db.sessions.find({}):
            print(f"Session: {s.get('_id')} | User: {s.get('user_id')} | Title: {s.get('title')}")
            
        print("\n--- All Users ---")
        async for u in db.db.users.find({}):
            print(f"User: {u.get('_id')} | Email: {u.get('email')}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(check_session())
