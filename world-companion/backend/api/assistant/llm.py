import json
import urllib.request
from typing import Any

from api.assistant.planner import AssistantPlan, plan_from_dict
from api.assistant.tools.registry import get_tool_schemas


class LLMAdapter:
    def generate_plan(
        self,
        message: str,
        context: dict[str, Any],
        tools: list[dict[str, Any]],
    ) -> AssistantPlan:
        raise NotImplementedError


class OllamaLLM(LLMAdapter):
    def __init__(
        self,
        base_url: str = "http://127.0.0.1:11434",
        model: str = "qwen3.5:latest",
    ):
        self.base_url = base_url.rstrip("/")
        self.model = model

    def generate_plan(
        self,
        message: str,
        context: dict[str, Any],
        tools: list[dict[str, Any]],
    ) -> AssistantPlan:

        tool_schemas = get_tool_schemas()

        prompt = f"""
You are the AI reasoning engine for WorldCompanion.

Your job is to understand the user's travel request and produce
a structured tool plan.

Available tools:
{json.dumps(tools, indent=2)}

Tool argument schemas:
{json.dumps(tool_schemas, indent=2)}

User context:
{json.dumps(context, indent=2, default=str)}

User message:
{message}

Return ONLY valid JSON in this exact structure:

{{
  "intent": "food",
  "response": "short natural response",
  "plans": [
    {{
      "tool": "tool_name",
      "arguments": {{}},
      "requires_confirmation": false
    }}
  ]
}}

Rules:
- Use only tools from the available tools list.
- Never invent a tool.
- Never invent database results.
- Follow the tool argument schemas exactly.
- Extract all relevant constraints from the user's message.
- Preserve important details such as place names, categories,
  prices, dates, and preferences inside tool arguments.
- Use multiple plans when the request requires multiple tools.
- Set requires_confirmation to true for actions such as booking,
  creating an itinerary, or triggering SOS.
- If no tool is needed, return an empty plans list.
- Return JSON only.
""".strip()

        payload = json.dumps(
            {
                "model": self.model,
                "prompt": prompt,
                "stream": False,
                "think": False,
            }
        ).encode("utf-8")

        request = urllib.request.Request(
            f"{self.base_url}/api/generate",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        with urllib.request.urlopen(request, timeout=120) as response:
            result = json.loads(
                response.read().decode("utf-8")
            )

        raw_response = result.get("response", "").strip()

        parsed = json.loads(raw_response)

        return plan_from_dict(parsed)