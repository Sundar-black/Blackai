from fastapi import APIRouter, HTTPException, Depends, File, UploadFile
from fastapi.responses import StreamingResponse, JSONResponse
import os
import uuid
import shutil
import json
from app.models.chat import ChatSession, Message
from app.core.database import db
from app.core.config import settings
from app.services.ai_service import ai_service
from bson import ObjectId
from datetime import datetime
from app.api.deps import get_current_active_user

router = APIRouter()

@router.post("/sessions")
async def create_session(current_user: dict = Depends(get_current_active_user)):
    try:
        user_id = current_user["id"]
        session = ChatSession(user_id=user_id)
        session_dict = session.dict(by_alias=True)
        session_dict.pop("id", None)
        session_dict.pop("_id", None)
        database = db.get_db()
        result = await database.sessions.insert_one(session_dict)
        session_dict["_id"] = str(result.inserted_id)
        return {"data": session_dict}
    except Exception as e:
        print(f"DEBUG Error creating session: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_active_user)
):
    try:
        # Define upload directory (inside static folder)
        base_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        upload_dir = os.path.join(base_path, "static", "uploads")
        if not os.path.exists(upload_dir):
            os.makedirs(upload_dir, exist_ok=True)

        # Generate unique filename
        file_extension = os.path.splitext(file.filename)[1]
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = os.path.join(upload_dir, unique_filename)

        # Save file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Return the public URL
        file_url = f"/static/uploads/{unique_filename}"
        
        return {"data": {"url": file_url, "filename": file.filename}}
    except Exception as e:
        print(f"DEBUG Upload error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/sessions")
async def get_my_sessions(current_user: dict = Depends(get_current_active_user)):
    database = db.get_db()
    cursor = database.sessions.find({"user_id": current_user["id"]}).sort("updated_at", -1)
    sessions = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        # Ensure createdAt is string for frontend
        if "created_at" in doc and isinstance(doc["created_at"], datetime):
             doc["createdAt"] = doc["created_at"].isoformat()
        elif "created_at" in doc:
             doc["createdAt"] = str(doc["created_at"])
        else:
             doc["createdAt"] = datetime.utcnow().isoformat()
        sessions.append(doc)
    return {"data": sessions}

@router.post("/sessions/{session_id}/messages/stream")
async def stream_message(
    session_id: str, 
    message: Message,
    current_user: dict = Depends(get_current_active_user)
):
    # Validate session_id
    if not ObjectId.is_valid(session_id):
        raise HTTPException(status_code=400, detail="Invalid session ID format.")

    database = db.get_db()
    
    # Check if session exists and belongs to user
    session = await database.sessions.find_one({"_id": ObjectId(session_id)})
    if not session:
        raise HTTPException(status_code=404, detail="Session not found.")
    
    if session.get("user_id") != current_user["id"]:
        raise HTTPException(status_code=403, detail="You do not have access to this session.")

    # 1. Update session in Mongo (User message)
    try:
        await database.sessions.update_one(
            {"_id": ObjectId(session_id)},
            {"$push": {"messages": message.dict()}, "$set": {"updated_at": datetime.utcnow()}}
        )
    except Exception as e:
        print(f"DEBUG Mongo update error: {e}")
        raise HTTPException(status_code=500, detail="Database update error.")

    user_id = current_user["id"]
    
    # Try to use Qdrant for context (ignore if it fails/refuses connection)
    context = []
    try:
        if settings.QDRANT_API_KEY: 
            await ai_service.save_context(user_id, message.content, {"session_id": session_id})
            context = await ai_service.search_context(user_id, message.content)
    except Exception as e:
        print(f"Qdrant context skip: {e}")

    # Prepare AI prompt
    # Re-fetch session to get the user message we just pushed
    session = await database.sessions.find_one({"_id": ObjectId(session_id)})
    ai_prompt = [{"role": m["role"], "content": m["content"]} for m in session["messages"][-10:]]
    if context:
        ai_prompt.insert(0, {"role": "system", "content": f"Relevant context from past: {'. '.join(context)}"})
    else:
        ai_prompt.insert(0, {"role": "system", "content": "You are Black, a helpful AI assistant created and trained by Sundar."})

    async def event_generator():
        try:
            full_response = ""
            async for chunk in ai_service.chat_completion_stream(ai_prompt):
                full_response += chunk
                yield chunk
            
            # Save AI Response after finished streaming
            if full_response:
                ai_message = Message(role="assistant", content=full_response)
                await database.sessions.update_one(
                    {"_id": ObjectId(session_id)},
                    {"$push": {"messages": ai_message.dict()}, "$set": {"updated_at": datetime.utcnow()}}
                )
        except Exception as e:
            print(f"DEBUG Error in stream: {e}")
            yield f"Error: {str(e)}"

    return StreamingResponse(event_generator(), media_type="text/plain")

@router.get("/sessions/user/{user_id}", response_model=list[dict])
async def get_user_sessions(user_id: str, current_user: dict = Depends(get_current_active_user)):
    # Ensure user is requesting their own sessions or is admin
    if user_id != current_user["id"] and current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Access denied.")
        
    database = db.get_db()
    cursor = database.sessions.find({"user_id": user_id}).sort("updated_at", -1)
    sessions = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        sessions.append(doc)
    return {"data": sessions}

from pydantic import BaseModel

class TitleRequest(BaseModel):
    message: str | None = None

@router.post("/sessions/{session_id}/title")
async def generate_title(
    session_id: str, 
    data: TitleRequest | None = None,
    current_user: dict = Depends(get_current_active_user)
):
    if not ObjectId.is_valid(session_id):
        raise HTTPException(status_code=400, detail="Invalid session ID.")
    
    database = db.get_db()
    session = await database.sessions.find_one({"_id": ObjectId(session_id)})
    if not session or session.get("user_id") != current_user["id"]:
        raise HTTPException(status_code=404, detail="Session not found.")
    
    # Use provided message if available (avoids race condition), otherwise fetch from DB
    user_msg = data.message if data and data.message else None
    
    if not user_msg:
        messages = session.get("messages", [])
        if not messages:
            return {"data": "New Chat"}
        user_msg = next((m["content"] for m in messages if m["role"] == "user"), "New Chat")
    
    prompt = [
        {"role": "system", "content": "Generate a short 2-4 word title for a chat that starts with this message. No quotes, no preamble: " + user_msg}
    ]
    
    try:
        title = await ai_service.chat_completion(prompt)
        title = title.strip().strip('"').strip("'")
    except:
        title = "New Chat"
    
    await database.sessions.update_one(
        {"_id": ObjectId(session_id)},
        {"$set": {"title": title}}
    )
    return {"data": title}

@router.delete("/sessions/{session_id}")
async def delete_session(session_id: str, current_user: dict = Depends(get_current_active_user)):
    if not ObjectId.is_valid(session_id):
        raise HTTPException(status_code=400, detail="Invalid session ID format.")
        
    database = db.get_db()
    session = await database.sessions.find_one({"_id": ObjectId(session_id)})
    if not session:
        raise HTTPException(status_code=404, detail="Session not found.")
        
    if session.get("user_id") != current_user["id"] and current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Access denied.")
        
    await database.sessions.delete_one({"_id": ObjectId(session_id)})
    return {"success": True}
