import json
import urllib.request


def get_weather(city):
    return {
        "city": city,
        "temperature": "25°C",
    }


tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get the weather for a city.",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {
                        "type": "string",
                        "description": "The city name.",
                    }
                },
                "required": ["city"],
            },
        },
    }
]


payload = {
    "model": "gpt-oss:120b-cloud",
    "messages": [
        {
            "role": "user",
            "content": "What is the weather in Bengaluru?",
        }
    ],
    "tools": tools,
    "stream": False,
}


request = urllib.request.Request(
    "http://127.0.0.1:11434/api/chat",
    data=json.dumps(payload).encode("utf-8"),
    headers={
        "Content-Type": "application/json",
    },
    method="POST",
)

with urllib.request.urlopen(request, timeout=60) as response:
    result = json.loads(
        response.read().decode("utf-8")
    )

print(json.dumps(result, indent=2))