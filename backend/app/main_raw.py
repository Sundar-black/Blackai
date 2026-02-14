import sys
import os

async def app(scope, receive, send):
    """
    Raw ASGI application to debug environment without FastAPI dependencies
    """
    if scope['type'] == 'http':
        await send({
            'type': 'http.response.start',
            'status': 200,
            'headers': [
                [b'content-type', b'text/plain'],
            ],
        })
        
        # Gather debug info
        debug_info = [
            "✅ RAW ASGI APP WORKING",
            f"Python Version: {sys.version}",
            f"Platform: {sys.platform}",
            f"CWD: {os.getcwd()}",
            "Environment Variables:",
        ]
        
        # Add safe env vars
        for k, v in os.environ.items():
            if k in ['PORT', 'PYTHONPATH', 'RENDER', 'DYNO', 'PWD']:
                debug_info.append(f"{k}={v}")
                
        # Check installed packages
        try:
            import pkg_resources
            debug_info.append("\nInstalled Packages:")
            for p in pkg_resources.working_set:
                debug_info.append(f"{p.project_name}=={p.version}")
        except:
            debug_info.append("\nCould not list packages")

        body = "\n".join(debug_info).encode('utf-8')
        
        await send({
            'type': 'http.response.body',
            'body': body,
        })
