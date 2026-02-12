import smtplib
import os
from dotenv import load_dotenv
from email.mime.text import MIMEText

# Load current .env
load_dotenv()

SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
PORT = int(os.getenv("SMTP_PORT", 587))
USER = os.getenv("SMTP_USER")
PASSWORD = os.getenv("SMTP_PASSWORD")
SENDER = os.getenv("SENDER_EMAIL")

print("\n--- SMTP Configuration Test ---")
print(f"Server:   {SERVER}:{PORT}")
print(f"User:     {USER}")
print(f"Password: {'*' * len(PASSWORD) if PASSWORD else 'NOT SET'}")
print(f"Sender:   {SENDER}")
print("-" * 30)

if not USER or not PASSWORD:
    print("Error: SMTP_USER or SMTP_PASSWORD is missing in .env")
    exit(1)

try:
    print(f"Connecting to {SERVER}...")
    server = smtplib.SMTP(SERVER, PORT, timeout=10)
    server.set_debuglevel(1)  # Show full SMTP conversation
    
    print("Starting TLS...")
    server.starttls()
    
    print(f"Logging in as {USER}...")
    server.login(USER, PASSWORD)
    print("Login SUCCESSFUL!")
    
    # Try sending a test email to the user (sender)
    msg = MIMEText("This is a test email from the SMTP Diagnostic tool.")
    msg['Subject'] = "SMTP Test Success"
    msg['From'] = SENDER
    msg['To'] = USER # Send to self
    
    print(f"Sending test email to {USER}...")
    server.send_message(msg)
    print("Email Sent Successfully!")
    
    server.quit()
    print("\n[SUCCESS] SMTP is working correctly.")
    
except smtplib.SMTPAuthenticationError as e:
    print("\n[FAILED] Authentication Error. correct username/password?")
    print(f"Details: {e}")
    print("\nTIP: If using Gmail, make sure you are using an 'App Password', NOT your login password.")
    print(f"TIP: Make sure '{USER}' is the correct Google account associated with the App Password.")
    
except Exception as e:
    print(f"\n[FAILED] SMTP Connection Error: {e}")

print("-" * 30)
