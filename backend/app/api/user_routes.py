from fastapi import APIRouter, Depends, HTTPException
from app.core.database import db
from app.models.user import UserInDB, UserUpdate
from app.core.security import get_current_user # Need to implement this dependency
from typing import List

router = APIRouter()

# Dependency (Should be in app.api.deps but for simplicity here)
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from app.core.config import settings
from app.core.database import db

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
        
    database = db.get_db()
    user = await database.users.find_one({"email": email})
    if user is None:
        raise credentials_exception
    return user

@router.get("/me", response_model=UserInDB)
async def read_users_me(current_user: UserInDB = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=UserInDB)
async def update_user_me(user_in: UserUpdate, current_user: UserInDB = Depends(get_current_user)):
    database = db.get_db()
    update_data = user_in.dict(exclude_unset=True)
    
    if update_data:
        await database.users.update_one(
            {"_id": current_user["_id"]},
            {"$set": update_data}
        )
        current_user = await database.users.find_one({"_id": current_user["_id"]})
        
    return current_user
