import smtplib
import os
import re

ENV_FILE = ".env"

def update_env_file(email, password):
    if not os.path.exists(ENV_FILE):
        print(f"Error: {ENV_FILE} not found!")
        return False
        
    try:
        with open(ENV_FILE, 'r') as f:
            lines = f.readlines()
            
        new_lines = []
        updated_user = False
        updated_pass = False
        updated_sender = False
        
        for line in lines:
            if line.startswith("SMTP_USER="):
                new_lines.append(f'SMTP_USER="{email}"\n')
                updated_user = True
            elif line.startswith("SMTP_PASSWORD="):
                new_lines.append(f'SMTP_PASSWORD="{password}"\n')
                updated_pass = True
            elif line.startswith("SENDER_EMAIL="):
                new_lines.append(f'SENDER_EMAIL="{email}"\n')
                updated_sender = True
            else:
                new_lines.append(line)
        
        # Append if missing
        if not updated_user:
            new_lines.append(f'\nSMTP_USER="{email}"\n')
        if not updated_pass:
            new_lines.append(f'SMTP_PASSWORD="{password}"\n')
        if not updated_sender:
            new_lines.append(f'SENDER_EMAIL="{email}"\n')
            
        with open(ENV_FILE, 'w') as f:
            f.writelines(new_lines)
            
        print(f"\n[SUCCESS] Updated {ENV_FILE} with new credentials.")
        return True
    
    except Exception as e:
        print(f"Error updating .env: {e}")
        return False

def test_smtp(email, password):
    print(f"\nTesting connection to smtp.gmail.com as {email}...")
    try:
        server = smtplib.SMTP("smtp.gmail.com", 587, timeout=10)
        server.starttls()
        server.login(email, password)
        server.quit()
        print("[SUCCESS] Credentials are valid!")
        return True
    except smtplib.SMTPAuthenticationError:
        print("\n[ERROR] Authentication Failed.")
        print("Tip: Use an App Password (16 chars), NOT your main Gmail password.")
        print("Tip: Ensure 2-Step Verification is enabled on your Google Account.")
        return False
    except Exception as e:
        print(f"\n[ERROR] Connection failed: {e}")
        return False

def main():
    print("--- Black AI Email Setup Wizard ---")
    print("This script will help you configure Gmail SMTP for sending emails.")
    print("Note: You must use a Gmail App Password.\n")
    
    while True:
        email = input("Enter your Gmail address (e.g. user@gmail.com): ").strip()
        if not email:
            print("Email cannot be empty.")
            continue
            
        password = input("Enter your 16-character App Password (e.g. abcd efgh ijkl mnop): ").strip()
        if not password:
            print("Password cannot be empty.")
            continue
            
        if test_smtp(email, password):
            if update_env_file(email, password):
                print("\nDONE! Please restart your backend server to apply changes.")
            break
        else:
            retry = input("\nTry again? (y/n): ").lower()
            if retry != 'y':
                print("Exiting setup.")
                break

if __name__ == "__main__":
    main()
