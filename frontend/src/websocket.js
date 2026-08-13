let ws;
let listeners = [];
let isConnected = false;

export function connect() {
    ws = new WebSocket("ws://localhost:8000/ws");

    ws.onopen = () => {
        console.log("WebSocket connected");
        isConnected = true;
    };

    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        listeners.forEach((fn) => fn(data));
    };

    ws.onclose = () => {
        console.log("WebSocket disconnected, retrying in 1s...");
        isConnected = false;
        setTimeout(connect, 1000);
    };
}

export function onMessage(callback) {
    listeners.push(callback);
}

export function sendMessage(text) {
    if (!isConnected) {
        console.warn("Cannot send message — WebSocket not connected");
        return;
    }

    const payload = {
        type: "user_message",
        content: text,
        timestamp: Date.now()
    };

    ws.send(JSON.stringify(payload));
}
