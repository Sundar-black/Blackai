import time
import requests
import datetime
import os
import sys

# Configuration: Set your backend URL here if you don't use the env var
SERVER_URL = os.environ.get("SERVER_URL", "https://your-app-name.onrender.com")

def ping_server():
    """
    Pings the server health endpoint every 5 minutes to keep it active.
    This script should be run on a separate always-on machine (e.g., local PC, VPS, Raspberry Pi).
    """
    print(f"[{datetime.datetime.now()}] Starting keep-alive monitor for: {SERVER_URL}")
    
    while True:
        try:
            start_time = time.time()
            response = requests.get(f"{SERVER_URL}/health", timeout=30)
            elapsed = time.time() - start_time
            
            if response.status_code == 200:
                print(f"[{datetime.datetime.now()}] SUCCESS: {SERVER_URL} is UP. (Response time: {elapsed:.2f}s)")
            else:
                print(f"[{datetime.datetime.now()}] WARNING: {SERVER_URL} returned status code {response.status_code}")
                
        except requests.exceptions.Timeout:
            print(f"[{datetime.datetime.now()}] ERROR: Connection timed out.")
        except requests.exceptions.ConnectionError:
            print(f"[{datetime.datetime.now()}] ERROR: Connection failed. Server might be down.")
        except Exception as e:
            print(f"[{datetime.datetime.now()}] ERROR: Unexpected error: {e}")
            
        # Sleep for 5 minutes (300 seconds) - well within the 15-minute idle limit
        time.sleep(300)

if __name__ == "__main__":
    if "your-app-name" in SERVER_URL:
        print("CRITICAL: You must set the SERVER_URL environment variable or edit this script with your actual URL.")
        sys.exit(1)
        
    try:
        ping_server()
    except KeyboardInterrupt:
        print("\nMonitor stopped by user.")
