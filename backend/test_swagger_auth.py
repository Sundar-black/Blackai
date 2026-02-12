import requests

URL = "http://localhost:8000/api/v1/auth/token"
USERNAME = "sundarbaskar2411@gmail.com"
PASSWORD = "Sundar@123"

def test_token_endpoint():
    print(f"Testing TOKEN endpoint: {URL}")
    print(f"Username: {USERNAME}")
    
    # Swagger sends application/x-www-form-urlencoded
    payload = {
        "username": USERNAME,
        "password": PASSWORD
    }
    
    try:
        res = requests.post(URL, data=payload)
        
        print(f"Status Code: {res.status_code}")
        if res.status_code == 200:
            print("SUCCESS! Token received:")
            print(res.json())
        else:
            print("FAILURE!")
            print(f"Response: {res.text}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_token_endpoint()
