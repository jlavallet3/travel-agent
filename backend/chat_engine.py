import dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient

dotenv.load_dotenv()

endpoint = dotenv.get_key(dotenv.find_dotenv(), "PROJECT_ENDPOINT")
agent_name = dotenv.get_key(dotenv.find_dotenv(), "AGENT_ID")
agent_version = dotenv.get_key(dotenv.find_dotenv(), "AGENT_VERSION")

project_client = AIProjectClient(
    endpoint=endpoint,
    credential=DefaultAzureCredential(),
)

openai_client = project_client.get_openai_client()

async def ask_agent(message: str) -> str:
    response = openai_client.responses.create(
        input=[{"role": "user", "content": message}],
        extra_body={"agent_reference": {
            "name": agent_name,
            "version": agent_version,
            "type": "agent_reference"
        }},
    )
    return response.output_text
