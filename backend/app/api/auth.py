from fastapi import APIRouter, HTTPException, Depends, status
from app.core.database import db
from app.core.security import get_password_hash, verify_password, create_access_token
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
import secrets
import string
from app.api.deps import get_current_active_user
from bson import ObjectId
from app.services.email_service import email_service
from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter()

# --- Rate Limiting & Audit Config ---
MAX_LOGIN_ATTEMPTS = 5
BLOCK_DURATION_SECONDS = 300 # 5 minutes
# Store: {email: {"count": int, "block_until": datetime}}
login_attempts_store = {}

import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("auth")

def check_rate_limit(email: str):
    record = login_attempts_store.get(email)
    if record:
        if "block_until" in record and record["block_until"] > datetime.utcnow():
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many failed login attempts. Please try again in 5 minutes."
            )
        # Reset if block expired
        if "block_until" in record and record["block_until"] <= datetime.utcnow():
             login_attempts_store.pop(email)

def record_failed_attempt(email: str):
    record = login_attempts_store.get(email, {"count": 0})
    record["count"] += 1
    
    if record["count"] >= MAX_LOGIN_ATTEMPTS:
        record["block_until"] = datetime.utcnow() + timedelta(seconds=BLOCK_DURATION_SECONDS)
        
    login_attempts_store[email] = record

def reset_attempts(email: str):
    if email in login_attempts_store:
        login_attempts_store.pop(email)

# --- Pydantic Models ---
class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserSignup(BaseModel):
    name: str
    email: EmailStr
    password: str

class EmailCheck(BaseModel):
    email: EmailStr

class ForgotPassword(BaseModel):
    email: EmailStr

class VerifyOTP(BaseModel):
    email: EmailStr
    otp: str

class ResetPassword(BaseModel):
    email: EmailStr
    otp: str
    password: str

class UpdateProfile(BaseModel):
    name: str | None = None
    settings: dict | None = None
    avatar: str | None = None

# --- Helpers ---
def generate_otp(length=6):
    # Secure OTP generation
    return ''.join(secrets.choice(string.digits) for _ in range(length))

# --- Endpoints ---

@router.post("/token")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    """
    OAuth2 compatible token login, get an access token for future requests
    """
    # 1. Rate Limit Check
    email = form_data.username.strip().lower()
    check_rate_limit(email)

    database = db.get_db()
    
    user = await database.users.find_one({"email": email})
    
    if not user:
         user = await database.users.find_one({"email": {"$regex": f"^{email}$", "$options": "i"}})

    if not user or not verify_password(form_data.password, user.get("hashed_password")):
        # 2. Record Failure
        record_failed_attempt(email)
        logger.warning(f"Failed login attempt for {email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if user.get("isBlocked", False):
        raise HTTPException(status_code=403, detail="Your account has been blocked.")

    # 3. Success Reset
    reset_attempts(email)

    # 4. Admin Audit Log
    if user.get("role") == "admin":
        logger.info(f"AUDIT: Admin Login Success for {email}")

    user_id = str(user["_id"])
    access_token = create_access_token(subject=user_id)
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login")
async def login(user_data: UserLogin):
    # 1. Rate Limit Check
    email = user_data.email.strip().lower()
    check_rate_limit(email)

    database = db.get_db()
    
    # Use case-insensitive search or just ensure everything is saved lowercase
    user = await database.users.find_one({"email": email})
    
    if not user:
        # Check if it was saved with different case (fallback)
        user = await database.users.find_one({"email": {"$regex": f"^{email}$", "$options": "i"}})

    if not user or not verify_password(user_data.password, user.get("hashed_password")):
        # 2. Record Failure
        record_failed_attempt(email)
        logger.warning(f"Failed login attempt for {email}")
        raise HTTPException(status_code=400, detail="Invalid credentials. Please check your email and password.")

    if user.get("isBlocked", False):
        raise HTTPException(status_code=403, detail="Your account has been blocked by an administrator.")

    # 3. Success Reset
    reset_attempts(email)

    # 4. Admin Audit Log
    if user.get("role") == "admin":
        logger.info(f"AUDIT: Admin Login Success for {email}")

    user_id = str(user.pop("_id"))
    user["id"] = user_id
    
    # Remove sensitive data
    if "hashed_password" in user:
        user.pop("hashed_password")
    
    # Ensure mandatory fields for frontend
    if "name" not in user or not user["name"]:
        user["name"] = user.get("full_name") or user.get("email", "").split("@")[0] or "User"
    if "role" not in user or not user["role"]:
        user["role"] = "user"
    
    # Generate real JWT
    access_token = create_access_token(subject=user_id)
    
    return {
        "success": True,
        "token": access_token, 
        "user": user
    }

@router.post("/signup", status_code=201)
async def signup(user_data: UserSignup):
    database = db.get_db()
    email = user_data.email.strip().lower()
    existing = await database.users.find_one({"email": email})
    if existing:
        return {"success": False, "message": "Email already exists"}

    new_user = {
        "name": user_data.name,
        "full_name": user_data.name, # Save both for compatibility
        "email": email,
        "hashed_password": get_password_hash(user_data.password),
        "role": "user",
        "created_at": datetime.utcnow(),
        "is_active": True,
        "isBlocked": False,
        "settings": {
             "animations_enabled": True,
             "selected_language": "English",
             "auto_language_match": True,
             "response_tone": "Friendly",
             "answer_length": "Detailed",
             "ai_personalization": 0.7
        }
    }
    
    result = await database.users.insert_one(new_user)
    user_id = str(result.inserted_id)
    print(f"DEBUG: New User Created. ID: {user_id} | Email: {email}")  # LOGGING ID
    new_user["id"] = user_id
    new_user.pop("_id")
    
    # Remove sensitive data before returning
    if "hashed_password" in new_user:
        new_user.pop("hashed_password")
    
    # Generate real JWT
    access_token = create_access_token(subject=user_id)
    
    return {
        "success": True,
        "token": access_token,
        "user": new_user
    }

@router.post("/check-email")
async def check_email(data: EmailCheck):
    database = db.get_db()
    user = await database.users.find_one({"email": data.email})
    return {"exists": bool(user)}

@router.post("/forgot-password")
async def forgot_password(data: ForgotPassword):
    database = db.get_db()
    # 1. Verify user exists
    user = await database.users.find_one({"email": data.email})
    if not user:
        # Rate limiting / User enumeration protection: 
        # Ideally return 200 even if not found, but for UX we return specific message or generic "If account exists..."
        return {"success": False, "message": "User not found"}
    
    # 2. Rate Limiting Check (60 seconds)
    existing_otp = await database.otps.find_one({"email": data.email, "action": "reset_password"})
    if existing_otp:
        last_created = existing_otp.get("created_at")
        if last_created and (datetime.utcnow() - last_created).total_seconds() < 60:
            return {"success": False, "message": "Please wait a minute before requesting a new code."}
    
    # 3. Generate Secure OTP
    otp = generate_otp()
    
    # 4. Hash OTP for security
    hashed_otp = get_password_hash(otp)
    
    # 5. Store with expiration (10 mins)
    expiration = datetime.utcnow() + timedelta(minutes=10)
    
    await database.otps.update_one(
        {"email": data.email},
        {
            "$set": {
                "hashed_otp": hashed_otp,
                "expires_at": expiration,
                "created_at": datetime.utcnow(),
                "action": "reset_password"
            },
            # Remove legacy 'otp' field if it exists to be safe
            "$unset": {"otp": ""}
        },
        upsert=True
    )
    
    # Log plain OTP only to console for Dev Fallback (in production use real email logs)
    print(f"!!! OTP for {data.email}: {otp} !!!")
    
    # Send actual email via SMTP
    sent = await email_service.send_otp(data.email, otp)
    
    if sent:
        return {"success": True, "message": "Verification code sent to your email."}
    else:
        return {"success": False, "message": "Failed to send verification email. Please try again later."}

@router.post("/verify-otp")
async def verify_otp_endpoint(data: VerifyOTP):
    database = db.get_db()
    record = await database.otps.find_one({"email": data.email, "action": "reset_password"})
    
    if not record:
        return {"success": False, "message": "Invalid OTP or expired request"}
        
    if datetime.utcnow() > record["expires_at"]:
        return {"success": False, "message": "OTP expired"}
    
    # Verify Hash
    if "hashed_otp" in record:
        if not verify_password(data.otp, record["hashed_otp"]):
            return {"success": False, "message": "Invalid OTP code"}
    else:
        # Fallback for old records (plain text)
        if record.get("otp") != data.otp:
            return {"success": False, "message": "Invalid OTP code"}
        
    return {"success": True}

@router.put("/reset-password")
async def reset_password(data: ResetPassword):
    database = db.get_db()
    record = await database.otps.find_one({"email": data.email, "action": "reset_password"})
    
    if not record:
        return {"success": False, "message": "Invalid request"}

    if datetime.utcnow() > record["expires_at"]:
        return {"success": False, "message": "OTP expired"}
        
    # Verify Hash again
    valid = False
    if "hashed_otp" in record:
        if verify_password(data.otp, record["hashed_otp"]):
            valid = True
    elif record.get("otp") == data.otp:
        valid = True
        
    if not valid:
        return {"success": False, "message": "Invalid OTP"}

    # Update password
    new_hash = get_password_hash(data.password)
    await database.users.update_one(
        {"email": data.email},
        {"$set": {"hashed_password": new_hash}}
    )
    
    # Clear OTP
    await database.otps.delete_one({"email": data.email})
    
    return {"success": True}

@router.put("/updatedetails")
async def update_details(
    data: UpdateProfile,
    current_user: dict = Depends(get_current_active_user)
):
    database = db.get_db()
    update_data = {}
    if data.name:
        update_data["name"] = data.name
        update_data["full_name"] = data.name
    if data.settings:
        # Merge settings or replace? Usually merge for partial updates but let's replace for simplicity if it's the whole object
        update_data["settings"] = data.settings
    if data.avatar:
        update_data["avatar"] = data.avatar

    if update_data:
        await database.users.update_one(
            {"_id": ObjectId(current_user["id"])},
            {"$set": update_data}
        )
    
    # Get updated user
    updated_user = await database.users.find_one({"_id": ObjectId(current_user["id"])})
    updated_user["id"] = str(updated_user.pop("_id"))
    
    return {"success": True, "user": updated_user}

@router.delete("/deleteme")
async def delete_me(current_user: dict = Depends(get_current_active_user)):
    database = db.get_db()
    await database.users.delete_one({"_id": ObjectId(current_user["id"])})
    # Also delete sessions?
    await database.sessions.delete_many({"user_id": current_user["id"]})
    return {"success": True}
