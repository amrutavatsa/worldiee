import json
import os

os.environ.setdefault(
    "DJANGO_SETTINGS_MODULE",
    "config.settings",
)

import django

django.setup()

from api.assistant.agent import AssistantAgent
from api.assistant.ollama_cloud import OllamaCloud
from api.assistant.tool_schema import build_ollama_tools


llm = OllamaCloud()

agent = AssistantAgent(
    user=None,
)

tools = [
    tool
    for tool in build_ollama_tools()
    if tool["function"]["name"] == "search_places"
]

result = llm.chat_with_tools(
    messages=[
        {
            "role": "user",
            "content": "Find places named Indiranagar.",
        }
    ],
    tools=tools,
    tool_executor=agent.execute_tool,
)

print(json.dumps(result, indent=2, default=str))