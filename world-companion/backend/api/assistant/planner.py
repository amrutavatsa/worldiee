from dataclasses import dataclass
from typing import Any


@dataclass
class ToolPlan:
    tool: str
    arguments: dict[str, Any]
    requires_confirmation: bool = False


@dataclass
class AssistantPlan:
    intent: str | None
    plans: list[ToolPlan]
    response: str | None = None


def plan_from_dict(data: dict[str, Any]) -> AssistantPlan:
    plans = []

    for item in data.get("plans", []):
        plans.append(
            ToolPlan(
                tool=item["tool"],
                arguments=item.get("arguments", {}),
                requires_confirmation=item.get(
                    "requires_confirmation",
                    False,
                ),
            )
        )

    return AssistantPlan(
        intent=data.get("intent"),
        plans=plans,
        response=data.get("response"),
    )