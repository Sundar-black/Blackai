# Password Reset Security Analysis & Backend Solution

## 1. Root Cause Analysis: Why Frontend-Only Email Fails
You are currently encountering issues sending emails directly from the Flutter application (Client-Side). This is a common architectural limitation, not just a bug.

### Key Reasons for Failure:
*   **Security Blocking (SMTP ports)**: Most mobile networks (4G/5G) and public Wi-Fi interactions strictly block SMTP ports (25, 465, 587) to prevent spam botnets. This causes connection timeouts.
*   **Credential Exposure**: To send email via SMTP, you must embed your Gmail/SMTP username and password in the App's code. This is **critically insecure**. Anyone can decompile your Flutter app (`flutter build apk`) and extract your email password in minutes.
*   **Spam Filters**: Emails sent directly from dynamic residential IPs (mobile phones) are almost always flagged as Spam-phishing by providers like Outlook and Gmail.

## 2. The Solution: Backend-Mediated Authentication
The industry standard solution is to delegate email dispatch to a **Backend Server**.
1.  **App** sends a request: `POST /reset-password { email: "user@example.com" }`
2.  **Server** (Secure environment) validates the user and talks to the Email Provider (SendGrid, Mailgun, AWS SES).
3.  **Email Provider** sends the email.

## 3. Recommended Implementation: Firebase Authentication
For a Flutter project, **Firebase Authentication** is the best solution as it handles the entire flow (User Database + Email Sending + Security) without needing you to write a custom server.

### The Correct Password Reset Flow (Firebase)
Unlike your current "4-digit code" flow, safe systems use **Magic Links**:
1.  User enters Email in App.
2.  App calls `FirebaseAuth.instance.sendPasswordResetEmail(email: email)`.
3.  Firebase sends an email with a unique **One-Time Link**.
4.  User clicks the link (on their phone or computer).
5.  A secure web page (hosted by Firebase) opens allowing them to set a new password.
6.  User returns to the app and logs in.

## 4. Implementation Steps (Added to this Project)

I have added the `firebase_auth` dependency and a new `FirebaseAuthService` class to your project.

### Step 1: Configure Firebase Console (REQUIRED)
Since I cannot access your Google account, you must do this:
1.  Go to [console.firebase.google.com](https://console.firebase.google.com).
2.  Create a project named **Black AI**.
3.  Enable **Authentication** -> **Email/Password** sign-in providers.
4.  **Add Android App**:
    *   Package name: `com.example.black_ai` (Check your `android/app/build.gradle` to confirm).
    *   Download `google-services.json` and place it in `your_project/android/app/`.
5.  **Add iOS App** (Optional):
    *   Download `GoogleService-Info.plist` and place it in `your_project/ios/Runner/`.

### Step 2: Switch to Firebase Service
Once the configuration files are added:
1.  Open `lib/main.dart`.
2.  Change the provider from `AuthService` to `FirebaseAuthService`.
3.  In `lib/src/features/auth/forgot_password_screen.dart`, update the flow to show "Link Sent" dialog instead of navigating to the Code screen.
