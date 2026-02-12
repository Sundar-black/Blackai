import httpx
import asyncio
import json

BASE_URL = "http://localhost:8000/api/v1"

async def run_tests():
    print("🚀 Starting BlackAI Backend API Tests...\n")
    
    async with httpx.AsyncClient() as client:
        # 1. Health Check
        print("🔍 Testing Health Check...")
        try:
            resp = await client.get("http://localhost:8000/health")
            print(f"✅ Health: {resp.status_code} - {resp.json()}\n")
        except Exception as e:
            print(f"❌ Health Check Failed: {e}")
            print("Make sure your backend server is running on port 8000.")
            return

        # 2. Signup Test
        email = f"testuser_{asyncio.get_event_loop().time()}@example.com"
        password = "testpassword123"
        print(f"📝 Testing Signup for {email}...")
        resp = await client.post(f"{BASE_URL}/auth/signup", json={
            "name": "Test User",
            "email": email,
            "password": password
        })
        if resp.status_code == 201:
            data = resp.json()
            token = data["token"]
            user_id = data["user"]["id"]
            print(f"✅ Signup Success! User ID: {user_id}")
            print(f"✅ Token received (JWT length: {len(token)})\n")
        else:
            print(f"❌ Signup Failed: {resp.status_code} - {resp.text}")
            return

        # 3. Login Test
        print("🔑 Testing Login...")
        resp = await client.post(f"{BASE_URL}/auth/login", json={
            "email": email,
            "password": password
        })
        if resp.status_code == 200:
            print("✅ Login Success!\n")
        else:
            print(f"❌ Login Failed: {resp.status_code} - {resp.text}")
            return

        # 4. Protected Route Test (User Dashboard)
        print("👤 Testing Protected Route (Get Me)...")
        resp = await client.get(f"{BASE_URL}/users/me", headers={"Authorization": f"Bearer {token}"})
        if resp.status_code == 200:
            print(f"✅ Profile Fetched: {resp.json()['email']}\n")
        else:
            print(f"❌ Profile Fetch Failed: {resp.status_code} - {resp.text}\n")

        # 5. Unauthorized Admin Access Test
        print("🛡️ Testing Unauthorized Admin Access (Accessing all users)...")
        resp = await client.get(f"{BASE_URL}/users/", headers={"Authorization": f"Bearer {token}"})
        if resp.status_code == 403:
            print("✅ Access Denied correctly for regular user.\n")
        else:
            print(f"❌ Security Flaw? User allowed to access admin route: {resp.status_code}\n")

    print("🏁 Tests completed.")

if __name__ == "__main__":
    try:
        asyncio.run(run_tests())
    except KeyboardInterrupt:
        pass
