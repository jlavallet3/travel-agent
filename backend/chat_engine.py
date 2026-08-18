import os

import dotenv
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential


def _load_foundry_config():
    dotenv.load_dotenv(dotenv.find_dotenv(usecwd=True), override=False)

    endpoint = os.getenv("PROJECT_ENDPOINT") or dotenv.get_key(dotenv.find_dotenv(usecwd=True), "PROJECT_ENDPOINT")
    agent_name = os.getenv("AGENT_ID") or dotenv.get_key(dotenv.find_dotenv(usecwd=True), "AGENT_ID")
    agent_version = os.getenv("AGENT_VERSION") or dotenv.get_key(dotenv.find_dotenv(usecwd=True), "AGENT_VERSION")

    missing = []
    if not endpoint:
        missing.append("PROJECT_ENDPOINT")
    if not agent_name:
        missing.append("AGENT_ID")
    if not agent_version:
        missing.append("AGENT_VERSION")

    if missing:
        raise ValueError(f"Missing Azure Foundry env vars: {', '.join(missing)}")

    return endpoint, agent_name, agent_version


def _get_openai_client():
    endpoint, agent_name, agent_version = _load_foundry_config()
    project_client = AIProjectClient(
        endpoint=endpoint,
        credential=DefaultAzureCredential(),
    )
    openai_client = project_client.get_openai_client()
    return openai_client, agent_name, agent_version


async def ask_agent(message: str) -> str:
    try:
        openai_client, agent_name, agent_version = _get_openai_client()
    except Exception as exc:  # pragma: no cover - runtime error path
        return f"Foundry configuration error: {exc}"

    try:
        response = openai_client.responses.create(
            input=[{"role": "user", "content": message}],
            extra_body={"agent_reference": {
                "name": agent_name,
                "version": agent_version,
                "type": "agent_reference"
            }},
        )
        return response.output_text
    except Exception as exc:  # pragma: no cover - runtime error path
        return f"Foundry request failed: {exc}"
