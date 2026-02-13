from fastapi import APIRouter, Depends, HTTPException, File, UploadFile
from typing import List, Optional
from app.models.chat import ChatSession, Message
from app.api.user_routes import get_current_user
from app.core.database import db
from app.services.ai_service import AiService
from bson import ObjectId
import json
from fastapi.responses import StreamingResponse

router = APIRouter()

@router.post("/sessions", response_model=ChatSession)
async def create_session(session: ChatSession, current_user = Depends(get_current_user)):
    database = db.get_db()
    session_dict = session.dict(by_alias=True, exclude={"id"})
    result = await database.chat_sessions.insert_one(session_dict)
    
    # Update user's active session? Ideally frontend tracks this.
    return await database.chat_sessions.find_one({"_id": result.inserted_id})

@router.get("/sessions", response_model=List[ChatSession])
async def get_sessions(current_user = Depends(get_current_user)):
    database = db.get_db()
    cursor = database.chat_sessions.find({"user_id": str(current_user.get("_id"))}).sort("updated_at", -1)
    return await cursor.to_list(length=100)

@router.post("/send")
async def send_message(
    session_id: str,
    message: Message,
    current_user = Depends(get_current_user)
):
    database = db.get_db()
    
    # 1. Verify session ownership
    session = await database.chat_sessions.find_one({"_id": ObjectId(session_id), "user_id": str(current_user.get("_id"))})
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    # 2. Add User Message
    user_message = message.dict()
    user_message["timestamp"] = datetime.utcnow()
    
    await database.chat_sessions.update_one(
        {"_id": ObjectId(session_id)},
        {
            "$push": {"messages": user_message},
            "$set": {"updated_at": datetime.utcnow()}
        }
    )

    # 3. Generate Title if new
    if len(session.get("messages", [])) == 0:
        try:
            new_title = await AiService.generate_title(user_message["content"])
            await database.chat_sessions.update_one(
                {"_id": ObjectId(session_id)},
                {"$set": {"title": new_title}}
            )
        except:
            pass # Title gen failed, ignore

    # 4. Generate AI Response
    # Fetch recent history for context (last 10 messages)
    history = session.get("messages", [])[-10:]
    messages_for_ai = [
        {"role": m["role"], "content": m["content"]} 
        for m in history
    ]
    messages_for_ai.append({"role": "user", "content": user_message["content"]})
    
    ai_response_content = await AiService.chat_completion(messages_for_ai)
    
    ai_message = Message(
        role="assistant",
        content=ai_response_content,
        timestamp=datetime.utcnow()
    )
    
    await database.chat_sessions.update_one(
        {"_id": ObjectId(session_id)},
        {
            "$push": {"messages": ai_message.dict()},
            "$set": {"updated_at": datetime.utcnow()}
        }
    )
    
    return ai_message

@router.post("/send-stream")
async def send_message_stream(
    session_id: str,
    message: Message,
    current_user = Depends(get_current_user)
):
    database = db.get_db()
    
    # Verify session
    try:
        obj_id = ObjectId(session_id)
    except:
        raise HTTPException(status_code=400, detail="Invalid Session ID")
        
    session = await database.chat_sessions.find_one({"_id": obj_id, "user_id": str(current_user.get("_id"))})
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    # Save User Msg
    user_msg_dict = message.dict()
    user_msg_dict["timestamp"] = datetime.utcnow()
    await database.chat_sessions.update_one(
        {"_id": obj_id},
        {"$push": {"messages": user_msg_dict}}
    )

    # History
    history = session.get("messages", [])[-6:] # limit context
    messages_for_ai = [{"role": m["role"], "content": m["content"]} for m in history]
    messages_for_ai.append({"role": "user", "content": message.content})

    async def event_generator():
        full_response = ""
        async for chunk in AiService.chat_completion_stream(messages_for_ai):
            full_response += chunk
            yield chunk

        # Save AI Msg after stream completes
        ai_msg = Message(role="assistant", content=full_response, timestamp=datetime.utcnow())
        await database.chat_sessions.update_one(
            {"_id": obj_id},
            {
                "$push": {"messages": ai_msg.dict()},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )

    return StreamingResponse(event_generator(), media_type="text/event-stream")

@router.post("/upload")
async def upload_file(file: UploadFile = File(...), current_user = Depends(get_current_user)):
    # In a real app, upload to S3/Cloudinary.
    # For now, we simulate success and return a dummy URL or base64 (if small).
    # Since we don't have S3 configured, let's just return a success msg.
    return {"filename": file.filename, "url": f"https://placeholder.com/{file.filename}"}
