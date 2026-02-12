import smtplib
import os
import logging
from datetime import datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv
from app.core.config import settings

# Ensure environment variables are loaded
load_dotenv()

logger = logging.getLogger(__name__)

class EmailService:
    def __init__(self):
        self.smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
        self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_user = os.getenv("SMTP_USER", "")
        self.smtp_password = os.getenv("SMTP_PASSWORD", "")
        self.sender_email = os.getenv("SENDER_EMAIL", self.smtp_user)

        if "sundar@blackai.com" in self.smtp_user:
            print("\n" + "!"*50)
            print("CRITICAL CONFIGURATION ERROR:")
            print("You are using the placeholder email 'sundar@blackai.com'.")
            print("EMAILS WILL NOT SEND until you configure valid Gmail credentials.")
            print("Run 'python setup_email.py' to fix this.")
            print("!"*50 + "\n")

    async def send_otp(self, email: str, otp: str):
        # 1. Print OTP to console for Development/Fallback
        print(f"\n{'='*40}")
        print(f"DEBUG OTP for {email}: {otp}")
        print(f"{'='*40}\n")
        
        logger.info(f"Generated OTP for {email}: {otp}")

        if not self.smtp_user or not self.smtp_password:
            logger.warning("SMTP credentials not set. Returning True for Dev flow.")
            # For dev purposes, we return True so the flow continues even without email
            return True

        try:
            msg = MIMEMultipart()
            msg['From'] = self.sender_email
            msg['To'] = email
            msg['Subject'] = f"Your {settings.PROJECT_NAME} Verification Code"

            body = f"""
            <html>
                <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                    <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
                        <h2 style="color: #6c5ce7; text-align: center;">Verification Code</h2>
                        <p>Hello,</p>
                        <p>You requested a verification code for your <strong>{settings.PROJECT_NAME}</strong> account. Please use the code below to proceed:</p>
                        <div style="background-color: #f4f4f4; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; color: #6c5ce7; border-radius: 5px; margin: 20px 0;">
                            {otp}
                        </div>
                        <p>This code will expire in 10 minutes.</p>
                        <p>If you did not request this code, please ignore this email.</p>
                        <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #888; text-align: center;">
                            &copy; {datetime.now().year} {settings.PROJECT_NAME}. All rights reserved.
                        </p>
                    </div>
                </body>
            </html>
            """
            msg.attach(MIMEText(body, 'html'))

            # Use synchronous SMTP with timeout
            server = smtplib.SMTP(self.smtp_server, self.smtp_port, timeout=10)
            server.starttls()
            server.login(self.smtp_user, self.smtp_password)
            server.send_message(msg)
            server.quit()
            
            logger.info(f"OTP email sent successfully to {email}")
            return True
        
        except Exception as e:
            logger.error(f"SMTP Error (Using Console Fallback): {e}")
            print(f"!!! SMTP SEND FAILED (Check Creds): {e} !!!")
            print(f"!!! SMTP SEND FAILED: {e} !!!")
            print("FALLBACK MODE: OTP is valid. Check console logs above for the code.")
            return True

# Initialize singleton
email_service = EmailService()
