from fastapi import FastAPI, WebSocket
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from chat_engine import ask_agent
import json
import os

app = FastAPI()

# Serve the built frontend static files
frontend_dist = os.path.join(os.path.dirname(__file__), "frontend/dist")
if not os.path.exists(frontend_dist):
    frontend_dist = os.path.join(os.path.dirname(__file__), "../frontend/dist")

if os.path.exists(frontend_dist):
    app.mount("/assets", StaticFiles(directory=os.path.join(frontend_dist, "assets")), name="assets")

@app.get("/")
async def root():
    """Serve index.html for SPA routing"""
    index_path = os.path.join(frontend_dist, "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path, media_type="text/html")
    return {"message": "Frontend not built. Run 'npm run build' in the frontend directory."}

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()

    while True:
        raw = await ws.receive_text()
        data = json.loads(raw)

        user_msg = data.get("content", "")

        agent_reply = await ask_agent(user_msg)

        response = {
            "type": "agent_message",
            "content": agent_reply,
            "timestamp": data.get("timestamp")
        }

        await ws.send_text(json.dumps(response))
