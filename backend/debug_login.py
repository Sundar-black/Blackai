import httpx
import asyncio
import traceback

async def test_login():
    url = "http://localhost:8000/api/v1/auth/login"
    payload = {
        "email": "sundar@blackai.com",
        "password": "admin123"
    }
    async with httpx.AsyncClient() as client:
        try:
            print(f"Sending login request to {url}...")
            resp = await client.post(url, json=payload, timeout=10.0)
            print(f"Status: {resp.status_code}")
            print(f"Response: {resp.text}")
        except Exception as e:
            print(f"Exception Type: {type(e)}")
            print(f"Exception Detail: {e}")
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_login())
