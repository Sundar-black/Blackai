import requests
import json

URL = "https://reconstructively-unpervaded-maryln.ngrok-free.dev/api/v1/chat/sessions/67ac6d0d26857b6f658098c3/messages/stream"
# I'll need a valid session ID. Let's try to create one first, or just list sessions.

BASE_URL = "https://reconstructively-unpervaded-maryln.ngrok-free.dev/api/v1"
HEADERS = {"ngrok-skip-browser-warning": "true"}

def test_stream():
    # 1. Login to get token (if needed) or just create session if auth is lenient for initial test?
    # Auth is required via Depends(get_current_active_user). 
    # I need a token.
    
    print("0. Signing up...")
    signup_url = f"{BASE_URL}/auth/signup"
    signup_payload = {"name": "Test User", "email": "testuser_stream@gmail.com", "password": "password123"}
    requests.post(signup_url, json=signup_payload, headers=HEADERS) # Ignore if fails (exists)

    print("1. Logging in...")
    login_resp = requests.post(f"{BASE_URL}/auth/login", json={"email": "testuser_stream@gmail.com", "password": "password123"}, headers=HEADERS)
    if login_resp.status_code != 200:
        print(f"Login failed: {login_resp.text}")
        return
    
    data = login_resp.json()
    token = data.get("token") or data.get("access_token")
    if not token:
        print(f"No token found in login response: {data}")
        return

    headers = HEADERS.copy()
    headers["Authorization"] = f"Bearer {token}"
    
    print("2. Creating Session...")
    session_resp = requests.post(f"{BASE_URL}/chat/sessions", headers=headers)
    if session_resp.status_code not in [200, 201]:
        print(f"Create session failed: {session_resp.text}")
        return
    
    session_data = session_resp.json().get("data")
    if not session_data:
         # Maybe list sessions if cannot create?
         list_resp = requests.get(f"{BASE_URL}/chat/sessions", headers=headers)
         session_data = list_resp.json().get("data")[0]
         
    session_id = session_data["_id"]
    print(f"Session ID: {session_id}")
    
    print("3. Streaming Message...")
    stream_url = f"{BASE_URL}/chat/sessions/{session_id}/messages/stream"
    payload = {
        "role": "user",
        "content": "Hello, write a short poem about coding.",
        "language": "English",
        "tone": "Friendly"
    }

    try:
        response = requests.post(stream_url, json=payload, headers=headers, stream=True)
        print(f"Stream Status: {response.status_code}")
        
        if response.status_code == 200:
            for line in response.iter_lines():
                if line:
                    decoded_line = line.decode('utf-8')
                    print(f"CHUNK: {decoded_line}")
        else:
            print(f"Stream failed: {response.text}")
            
    except Exception as e:
        print(f"Streaming Exception: {e}")

if __name__ == "__main__":
    test_stream()
