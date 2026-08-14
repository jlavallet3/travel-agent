<script>
    import { connect, onMessage, sendMessage } from "./ws.js";
    import { connected } from "./connectionStore.js";
    import { onMount } from "svelte";

    let messages = [];
    let messagesContainer;
    let agentTyping = false;
    let draft = "";
    let darkMode = false;

    // reactive store
    $: isConnected = $connected;

    connect();

    onMessage((msg) => {
        agentTyping = false;

        messages = [
            ...messages,
            {
                sender: msg.type === "agent_message" ? "agent" : "user",
                text: msg.content,
                timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
            }
        ];
    });

    function handleKey(e) {
        if (e.key === "Enter") {
            e.preventDefault();
            sendDraft();
        }
    }

    function handleClick() {
        sendDraft();
    }

    function sendDraft() {
        const text = draft.trim();
        if (!text || !isConnected) return;

        sendMessage(text);

        messages = [
            ...messages,
            {
                sender: "user",
                text,
                timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
            }
        ];

        agentTyping = true;
        draft = "";
    }

    onMount(() => {
        const observer = new MutationObserver(() => {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        });

        observer.observe(messagesContainer, { childList: true });
    });
</script>

<div class="chat" class:dark={darkMode}>
    <div class="header">
        <span>Travel Agent</span>
        <button class="dark-toggle" on:click={() => (darkMode = !darkMode)}>
            {darkMode ? "☀️" : "🌙"}
        </button>
    </div>

    <div class="messages" bind:this={messagesContainer}>
        {#each messages as m}
            <div class="message-row {m.sender}">
                <div class="avatar">
                    {#if m.sender === "user"}
                        <div class="avatar-circle user-avatar">U</div>
                    {:else}
                        <div class="avatar-circle agent-avatar">A</div>
                    {/if}
                </div>

                <div class="bubble fade-in {m.sender}">
                    <div class="text">{m.text}</div>
                    <div class="timestamp">{m.timestamp}</div>
                </div>
            </div>
        {/each}

        {#if agentTyping}
            <div class="message-row agent">
                <div class="avatar">
                    <div class="avatar-circle agent-avatar">A</div>
                </div>

                <div class="bubble typing-bubble fade-in">
                    <div class="typing-dots">
                        <span>.</span><span>.</span><span>.</span>
                    </div>
                </div>
            </div>
        {/if}
    </div>

    <div class="input-bar">
        <input
            bind:value={draft}
            placeholder={isConnected ? "Type a message..." : "Connecting..."}
            on:keydown={handleKey}
            disabled={!isConnected}
        />

        <button
            class="send-btn"
            on:click={handleClick}
            disabled={!isConnected || !draft.trim()}
        >
            Send
        </button>
    </div>
</div>

<style>
    .chat {
        display: flex;
        flex-direction: column;
        height: 100vh;
        background: #f5f7fa;
        color: #222;
        transition: background 0.3s, color 0.3s;
    }

    .chat.dark {
        background: #1e1e1e;
        color: #eee;
    }

    .header {
        padding: 1rem;
        background: #2d6cdf;
        color: white;
        font-size: 1.2rem;
        font-weight: bold;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .dark-toggle {
        background: transparent;
        border: none;
        font-size: 1.3rem;
        cursor: pointer;
        color: white;
    }

    .messages {
        flex: 1;
        overflow-y: auto;
        padding: 1rem;
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .message-row {
        display: flex;
        gap: 0.5rem;
        align-items: flex-end;
    }

    .message-row.user {
        flex-direction: row-reverse;
    }

    .avatar-circle {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        display: flex;
        justify-content: center;
        align-items: center;
        font-weight: bold;
        color: white;
    }

    .user-avatar {
        background: #2d6cdf;
    }

    .agent-avatar {
        background: #1b5e20;
    }

    .bubble {
        max-width: 70%;
        padding: 0.75rem 1rem;
        border-radius: 12px;
        font-size: 0.95rem;
        line-height: 1.3;
        word-wrap: break-word;
        position: relative;
    }

    .user .bubble {
        background: #d0e2ff;
        color: #003a8c;
    }

    .agent .bubble {
        background: #e8f5e9;
        color: #1b5e20;
    }

    .timestamp {
        font-size: 0.75rem;
        opacity: 0.6;
        margin-top: 4px;
        text-align: right;
    }

    .typing-bubble {
        background: #e8f5e9;
        color: #1b5e20;
    }

    .typing-dots span {
        animation: blink 1.4s infinite both;
        font-size: 1.2rem;
        margin-right: 2px;
    }

    .typing-dots span:nth-child(2) {
        animation-delay: 0.2s;
    }

    .typing-dots span:nth-child(3) {
        animation-delay: 0.4s;
    }

    @keyframes blink {
        0% { opacity: 0.2; }
        20% { opacity: 1; }
        100% { opacity: 0.2; }
    }

    .fade-in {
        animation: fadeIn 0.3s ease-in;
    }

    @keyframes fadeIn {
        from { opacity: 0; transform: translateY(4px); }
        to { opacity: 1; transform: translateY(0); }
    }

    .input-bar {
        display: flex;
        gap: 0.5rem;
        padding: 0.75rem;
        background: white;
        border-top: 1px solid #ddd;
    }

    .chat.dark .input-bar {
        background: #2a2a2a;
        border-color: #444;
    }

    .input-bar input {
        flex: 1;
        padding: 0.75rem;
        border-radius: 8px;
        border: 1px solid #ccc;
        font-size: 1rem;
    }

    .chat.dark .input-bar input {
        background: #3a3a3a;
        color: #eee;
        border-color: #555;
    }

    .send-btn {
        padding: 0.75rem 1rem;
        background: #2d6cdf;
        color: white;
        border: none;
        border-radius: 8px;
        font-size: 1rem;
        cursor: pointer;
        transition: background 0.2s;
    }

    .send-btn:hover:not(:disabled) {
        background: #1f4fb8;
    }

    .send-btn:disabled {
        background: #9bb4e6;
        cursor: not-allowed;
    }
</style>
