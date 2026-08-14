import { connected } from "./connectionStore.js";

let ws;
let listeners = [];

export function connect() {
    ws = new WebSocket("ws://localhost:8000/ws");

    ws.onopen = () => {
        console.log("WebSocket connected — setting flag TRUE");
        connected.set(true);
    };

    ws.onclose = () => {
        console.log("WebSocket disconnected, retrying in 1s...");
        connected.set(false);
        setTimeout(connect, 1000);
    };

    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        listeners.forEach((fn) => fn(data));
    };
}

export function onMessage(callback) {
    listeners.push(callback);
}

export function sendMessage(text) {
    ws.send(JSON.stringify({
        type: "user_message",
        content: text,
        timestamp: Date.now()
    }));
}
