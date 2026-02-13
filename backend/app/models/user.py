from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List, Dict, Any
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    name: Optional[str] = None
    avatar: Optional[str] = None
    role: str = "user"
    is_active: bool = True
    isBlocked: bool = False
    
class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    avatar: Optional[str] = None
    password: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None

class UserInDB(UserBase):
    id: Optional[str] = Field(alias="_id", default=None)
    hashed_password: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    settings: Dict[str, Any] = {}

    class Config:
        populate_by_name = True
