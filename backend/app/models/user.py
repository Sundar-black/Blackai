from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserSettings(BaseModel):
    animations_enabled: bool = True
    selected_language: str = "English"
    auto_language_match: bool = True
    response_tone: str = "Friendly"
    answer_length: str = "Detailed"
    ai_personalization: float = 0.7

class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    avatar: Optional[str] = None
    role: Optional[str] = "user"
    is_active: bool = True
    settings: UserSettings = Field(default_factory=UserSettings)

class UserCreate(UserBase):
    password: str
    settings: UserSettings = Field(default_factory=UserSettings)

class UserUpdate(UserBase):
    password: Optional[str] = None

class UserInDB(UserBase):
    id: str = Field(alias="_id")
    hashed_password: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

class User(UserBase):
    id: str

    class Config:
        populate_by_name = True
