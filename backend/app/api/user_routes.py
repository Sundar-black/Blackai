from fastapi import APIRouter, HTTPException, Depends
from app.models.user import User, UserCreate
from app.core.database import db
from app.core.security import get_password_hash, verify_password
from bson import ObjectId
from datetime import datetime
from app.api.deps import get_admin_user, get_current_active_user

router = APIRouter()

@router.post("/", response_model=User)
async def create_user(user: UserCreate):
    try:
        database = db.get_db()
        # Check if user already exists
        existing_user = await database.users.find_one({"email": user.email})
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already registered")
            
        user_dict = user.dict()
        # Hash the password
        user_dict["hashed_password"] = get_password_hash(user_dict.pop("password"))
        user_dict["created_at"] = datetime.utcnow()
        user_dict["is_active"] = True
        user_dict["isBlocked"] = False
        
        result = await database.users.insert_one(user_dict)
        user_dict["id"] = str(result.inserted_id)
        return user_dict
    except HTTPException as e:
        raise e
    except Exception as e:
        # Catch unexpected errors and return as JSON so Flutter doesn't crash on HTML
        print(f"CRITICAL Signup Error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@router.get("/me", response_model=User)
async def get_me(current_user: dict = Depends(get_current_active_user)):
    return current_user

@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str, admin_user: dict = Depends(get_admin_user)):
    database = db.get_db()
    if not ObjectId.is_valid(user_id):
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    user = await database.users.find_one({"_id": ObjectId(user_id)})
    if user:
        user["id"] = str(user.pop("_id"))
        return user
    raise HTTPException(status_code=404, detail="User not found")

@router.get("/by-email/{email}", response_model=User)
async def get_user_by_email(email: str, admin_user: dict = Depends(get_admin_user)):
    database = db.get_db()
    user = await database.users.find_one({"email": email})
    if user:
        user["id"] = str(user.pop("_id"))
        return user
    raise HTTPException(status_code=404, detail="User not found")

@router.put("/by-email/{email}", response_model=User)
async def update_user(email: str, user_update: dict, admin_user: dict = Depends(get_admin_user)):
    # Handle password hashing if included in update
    if "password" in user_update and user_update["password"]:
        user_update["hashed_password"] = get_password_hash(user_update.pop("password"))
    elif "password" in user_update:
        user_update.pop("password")

    # Update the user document
    database = db.get_db()
    result = await database.users.update_one(
        {"email": email},
        {"$set": user_update}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
        
    user = await database.users.find_one({"email": email})
    user["id"] = str(user.pop("_id"))
    return user

@router.get("/", response_model=list[dict])
async def get_all_users(admin_user: dict = Depends(get_admin_user)):
    database = db.get_db()
    users = []
    cursor = database.users.find({})
    async for user in cursor:
        user["id"] = str(user.pop("_id"))
        if "hashed_password" in user:
            user.pop("hashed_password")
        users.append(user)
    return {"data": users} # Frontend expects {data: [...]}

@router.put("/{user_id}/block")
async def block_user(user_id: str, admin_user: dict = Depends(get_admin_user)):
    database = db.get_db()
    if not ObjectId.is_valid(user_id):
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    user = await database.users.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    new_status = not user.get("isBlocked", False)
    await database.users.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"isBlocked": new_status}}
    )
    return {"success": True, "isBlocked": new_status}

@router.delete("/{user_id}")
async def delete_user_by_id(user_id: str, admin_user: dict = Depends(get_admin_user)):
    database = db.get_db()
    if not ObjectId.is_valid(user_id):
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    result = await database.users.delete_one({"_id": ObjectId(user_id)})
    if result.deleted_count == 0:
         raise HTTPException(status_code=404, detail="User not found")
    
    # Also delete sessions
    await database.sessions.delete_many({"user_id": user_id})
    return {"success": True}

# Endpoints removed for security. Admin user is now seeded via environment variables.

