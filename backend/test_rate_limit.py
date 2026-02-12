import requests
import time

BASE_URL = "http://localhost:8000/api/v1"
EMAIL = "rate_limit_test@example.com"
PASSWORD = "password123"

def run_test():
    print("--- OTP Rate Limit & Flow Test ---")
    
    # 1. Signup (Ensure user exists)
    print(f"1. Signing up user {EMAIL}...")
    signup_data = {"name": "Test User", "email": EMAIL, "password": PASSWORD}
    try:
        res = requests.post(f"{BASE_URL}/auth/signup", json=signup_data)
        if res.status_code == 201 or "Email already exists" in res.text:
             print("[PASS] Signup OK (or exists).")
        else:
             print(f"[FAIL] Signup failed: {res.text}")
             return
    except Exception as e:
        print(f"[FAIL] Connection error: {e}")
        return

    # 2. Request OTP (First time) - Should succeed
    print("\n2. Requesting OTP (1st Attempt)...")
    res = requests.post(f"{BASE_URL}/auth/forgot-password", json={"email": EMAIL})
    print(f"Response: {res.status_code} - {res.json()}")
    
    if res.json().get("success"):
        print("[PASS] First OTP Sent Successfully.")
    else:
        print(f"[FAIL] First OTP Failed: {res.json().get('message')}")
        return

    # 3. Request OTP Immediately (2nd Attempt) - Should trigger Rate Limit
    print("\n3. Requesting OTP Immediately (2nd Attempt)...")
    res = requests.post(f"{BASE_URL}/auth/forgot-password", json={"email": EMAIL})
    print(f"Response: {res.status_code} - {res.json()}")
    
    data = res.json()
    if not data.get("success") and "wait a minute" in data.get("message", "").lower():
        print("[PASS] Rate Limiting Working! (Request blocked as expected).")
    else:
        print("[FAIL] Rate Limiting NOT working (or unexpected error).")

if __name__ == "__main__":
    run_test()
