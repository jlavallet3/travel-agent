# Before running the sample:
#    pip install -r requirements.txt
import dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient

def main():
    endpoint = dotenv.get_key(dotenv.find_dotenv(), "PROJECT_ENDPOINT")
    my_agent = dotenv.get_key(dotenv.find_dotenv(), "AGENT_ID")
    my_version = dotenv.get_key(dotenv.find_dotenv(), "AGENT_VERSION")

    # Use the Foundry SDK to create a client for the project
    project_client = AIProjectClient(
        endpoint=endpoint,
        credential=DefaultAzureCredential(),
    )

    # get the OpenAI client from the project client
    openai_client = project_client.get_openai_client()


    # Reference the agent to get a response
    response = openai_client.responses.create(
        input=[{"role": "user", "content": "Tell me what you can help with."}],
        extra_body={"agent_reference": {"name": my_agent, "version": my_version, "type": "agent_reference"}},
    )

    print(f"Response output: {response.output_text}")

if __name__ == "__main__":
    print("Running agent.py")
    main()