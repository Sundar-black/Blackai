import requests

URL = "https://reconstructively-unpervaded-maryln.ngrok-free.dev/health"
HEADERS = {"ngrok-skip-browser-warning": "true"}

try:
    print(f"Testing {URL}...")
    response = requests.get(URL, headers=HEADERS, timeout=10)
    print(f"Status: {response.status_code}")
    print(f"Body: {response.text}")
except Exception as e:
    print(f"ERROR: {e}")
