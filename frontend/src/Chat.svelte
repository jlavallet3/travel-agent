<script>
    import { connect, onMessage, sendMessage } from "./websocket.js";

    let messages = [];

    connect();

    onMessage((msg) => {
        messages = [...messages, {
            sender: msg.type === "agent_message" ? "agent" : "user",
            text: msg.content
        }];
    });

    function handleSend(e) {
        if (e.key === "Enter") {
            const text = e.target.value;
            sendMessage(text);

            messages = [...messages, { sender: "user", text }];
            e.target.value = "";
        }
    }
</script>

<div class="chat">
    {#each messages as m}
        <div class={m.sender}>{m.text}</div>
    {/each}

    <input placeholder="Type a message..." on:keydown={handleSend} />
</div>

<style>
    .chat { padding: 1rem; }
    .user { text-align: right; color: blue; }
    .agent { text-align: left; color: green; }
</style>
