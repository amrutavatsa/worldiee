from api.assistant.tools.registry import (
    get_tool_definitions,
    get_tool_schemas,
)


def build_ollama_tools():
    definitions = get_tool_definitions()
    schemas = get_tool_schemas()

    tools = []

    for definition in definitions:
        name = definition["name"]

        tools.append(
            {
                "type": "function",
                "function": {
                    "name": name,
                    "description": definition["description"],
                    "parameters": schemas.get(
                        name,
                        {
                            "type": "object",
                            "properties": {},
                        },
                    ),
                },
            }
        )

    return tools