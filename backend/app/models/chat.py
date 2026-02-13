from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class Message(BaseModel):
    role: str = "user"  # "user" or "assistant"
    content: str = ""
    text: Optional[str] = None # For frontend compatibility
    isUser: Optional[bool] = None # For frontend compatibility
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    attachments: List[str] = []

    def __init__(self, **data):
        super().__init__(**data)
        # Sync content <-> text
        if self.text is None:
            self.text = self.content
        if self.content == "" and self.text:
            self.content = self.text
            
        # Sync role <-> isUser
        if self.isUser is None:
            self.isUser = (self.role == "user")
        if self.role == "user" and self.isUser is False:
            self.role = "assistant"
        elif self.role == "assistant" and self.isUser is True:
            self.role = "user"

class ChatSession(BaseModel):
    id: Optional[str] = Field(alias="_id", default=None)
    user_id: str
    title: Optional[str] = "New Chat"
    messages: List[Message] = []
    isPinned: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
