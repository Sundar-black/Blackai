from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from app.core.security import verify_password, create_access_token, get_password_hash
from app.core.database import db
from app.models.user import UserCreate, UserInDB
from datetime import timedelta
from app.core.config import settings
from pydantic import BaseModel

router = APIRouter()

class Token(BaseModel):
    access_token: str
    token_type: str
    user_id: str
    email: str
    name: str

@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    database = db.get_db()
    user = await database.users.find_one({"email": form_data.username})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    if not verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["email"]}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token, 
        "token_type": "bearer",
        "user_id": str(user.get("_id", "")),
        "email": user["email"],
        "name": user.get("name", "User")
    }

class UserSignup(UserCreate):
    pass

@router.post("/signup", response_model=Token)
async def signup(user_in: UserSignup):
    database = db.get_db()
    existing_user = await database.users.find_one({"email": user_in.email})
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="User with this email already exists"
        )
        
    hashed_password = get_password_hash(user_in.password)
    new_user = UserInDB(
        **user_in.dict(exclude={"password"}), 
        hashed_password=hashed_password
    )
    
    result = await database.users.insert_one(new_user.dict(by_alias=True))
    created_user = await database.users.find_one({"_id": result.inserted_id})
    
    access_token = create_access_token(
        data={"sub": created_user["email"]}
    )
    
    return {
        "access_token": access_token, 
        "token_type": "bearer",
        "user_id": str(created_user.get("_id", "")),
        "email": created_user["email"],
        "name": created_user.get("name", "User")
    }
