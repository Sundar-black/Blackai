import requests
import json
import socket

# Configuration
LOCAL_URL = "http://localhost:8000/health"
NGROK_URL = "https://reconstructively-unpervaded-maryln.ngrok-free.dev/health"

print("--- DIAGNOSTIC START ---")

# 1. Check if backend port 8000 is open
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
result = sock.connect_ex(('localhost', 8000))
sock.close()
if result == 0:
    print("✅ Port 8000 is open (Backend is running)")
else:
    print("❌ Port 8000 is CLOSED. Please start uvicorn!")
    print("   Run: uvicorn app.main:app --reload")

# 2. Check Local Health Endpoint
try:
    print(f"Testing Local URL: {LOCAL_URL}")
    resp = requests.get(LOCAL_URL, timeout=5)
    print(f"   Status: {resp.status_code}")
    print(f"   Body: {resp.text[:100]}")
    if resp.status_code == 200:
        print("✅ Local access works!")
    else:
        print("❌ Local access failed (HTTP Error)!")
except Exception as e:
    print(f"❌ Local access failed (Connection Error): {e}")

# 3. Check Ngrok Health Endpoint
try:
    print(f"Testing Ngrok URL: {NGROK_URL}")
    resp = requests.get(NGROK_URL, timeout=10, headers={"ngrok-skip-browser-warning": "true"})
    print(f"   Status: {resp.status_code}")
    
    if resp.headers.get('content-type', '').startswith('text/html'):
       print("⚠️  Ngrok returned HTML (could be error page or warning page)")
       if "ngrok-skip-browser-warning" in resp.text:
           print("   (It's the browser warning page)")
       elif "502 Bad Gateway" in resp.text:
           print("❌ 502 Bad Gateway (Ngrok can't reach localhost:8000)")
       else:
           print(f"   Preview: {resp.text[:200]}")
    elif resp.status_code == 200:
        print("✅ Ngrok access works! API is reachable externally.")
        print(f"   Body: {resp.text[:100]}")
    else:
        print(f"❌ Ngrok returned status {resp.status_code}")

except Exception as e:
    print(f"❌ Ngrok access failed (Connection Error): {e}")

print("--- DIAGNOSTIC END ---")
