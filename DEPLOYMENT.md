# How to Deploy Backend to Production Server (Cloud)

Currently, your app connects to your local computer (localhost) via **ngrok**. This means **if you close your laptop, the app stops working**.

To fix this, you need to deploy your backend to a **Cloud Server** that runs 24/7. We recommend **Render.com** (it has a free tier and matches your code setup).

## Step 1: Push Code to GitHub
1. Create a new repository on [GitHub](https://github.com/new).
2. Push your `black_ai` folder to this repository.
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```

## Step 2: Deploy to Render.com
1. Sign up/Log in to [Render.com](https://render.com).
2. Click **New +** -> **Web Service**.
3. Connect your GitHub repository.
4. Select the repo you just pushed.
5. Configure the settings:
   - **Name**: `black-ai-backend`
   - **Root Directory**: `backend` (Important!)
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type**: Free

6. scroll down to **Environment Variables** and add these (copy from your `.env` file):
   - `MONGODB_URL`: `mongodb+srv://...`
   - `OPENAI_API_KEY`: `...` (or `sk-or-...` for OpenRouter)
   - `QDRANT_URL`: `...`
   - `QDRANT_API_KEY`: `...`
   - `SECRET_KEY`: (Generate a random string)

7. Click **Create Web Service**.
8. Wait for the deployment to finish. You will get a URL like `https://black-ai-backend.onrender.com`.

## Step 3: Connect App to New Server
1. Open `lib/config/app_config.dart`.
2. Replace the `baseUrl` and `rootUrl` with your new Render URL:
   ```dart
   class AppConfig {
     // OLD: "https://reconstructively-unpervaded-maryln.ngrok-free.dev"
     // NEW:
     static const String baseUrl = "https://black-ai-backend.onrender.com/api/v1";
     static String get rootUrl => "https://black-ai-backend.onrender.com";
     static String get fullUrl => baseUrl;
   }
   ```
3. Rebuild and run your app.

## Done!
Now your app connects to the cloud server. It will work 24/7, even when your computer is off.
