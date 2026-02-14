import sys
import traceback
import os

# 1. Try to import FastAPI
try:
    from fastapi import FastAPI
    from fastapi.responses import PlainTextResponse
except ImportError:
    # If FastAPI is missing, we can't do much with Uvicorn, 
    # but we can try to define a raw ASGI app to show the error
    FASTAPI_MISSING = True
else:
    FASTAPI_MISSING = False

# 2. Capture Environmental Info
env_info = "\n".join([f"{k}={v}" for k, v in os.environ.items() if k in ['PORT', 'PYTHONPATH', 'PWD']])
python_info = sys.version

if FASTAPI_MISSING:
    async def app(scope, receive, send):
        error_msg = f"CRITICAL: FastAPI is missing!\nPython: {python_info}\nEnv: {env_info}"
        await send({
            'type': 'http.response.start',
            'status': 200,
            'headers': [[b'content-type', b'text/plain']],
        })
        await send({
            'type': 'http.response.body',
            'body': error_msg.encode('utf-8'),
        })

else:
    # FastAPI is present, let's try to import the real main app
    app = FastAPI()

    @app.get("/")
    def debug_root():
        results = ["✅ Debug App Running"]
        results.append(f"Python: {python_info}")
        results.append(f"CWD: {os.getcwd()}")
        
        # Try importing the real app modules
        try:
            import app.main
            results.append("✅ app.main imported successfully")
        except Exception as e:
            results.append(f"❌ app.main FAILED: {str(e)}")
            results.append(traceback.format_exc())
            
        try:
            from app.core.config import settings
            results.append("✅ Config loaded")
            results.append(f"MONGODB_URL: {'Set' if settings.MONGODB_URL else 'MISSING'}")
        except Exception as e:
            results.append(f"❌ Config load FAILED: {str(e)}")

        return PlainTextResponse("\n".join(results))

    @app.get("/health")
    def health():
        return {"status": "debug_healthy"}
