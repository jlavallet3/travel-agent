from fastapi import FastAPI, WebSocket
from chat_engine import ask_agent
import json

app = FastAPI()

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
