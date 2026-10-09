from typing import Any

from api.assistant.tools.registry import TOOL_REGISTRY


class AssistantAgent:
    def __init__(self, user):
        self.user = user

    def execute_tool(
        self,
        tool_name: str,
        arguments: dict[str, Any] | None = None,
        confirmed: bool = False,
    ):
        # Copy the arguments so injecting the authenticated user
        # does not mutate the original Ollama assistant message.
        arguments = dict(arguments or {})

        if tool_name not in TOOL_REGISTRY:
            return {
                "success": False,
                "error": f"Unknown assistant tool: {tool_name}",
            }

        tool = TOOL_REGISTRY[tool_name]

        if tool["requires_confirmation"] and not confirmed:
            return {
                "success": False,
                "requires_confirmation": True,
                "tool": tool_name,
                "message": (
                    "This action requires user confirmation "
                    "before it can be executed."
                ),
            }

        function = tool["function"]

        if tool.get("requires_user", False):
            arguments["user"] = self.user

        try:
            result = function(**arguments)

            return {
                "success": True,
                "tool": tool_name,
                "data": result,
            }

        except Exception as exc:
            return {
                "success": False,
                "tool": tool_name,
                "error": str(exc),
            }
