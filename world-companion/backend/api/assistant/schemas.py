from dataclasses import dataclass
from typing import Any


@dataclass
class AssistantRequest:
    message: str
    conversation_id: str | None = None


@dataclass
class AssistantResponse:
    message: str
    intent: str | None = None
    action: str | None = None
    results: list[dict[str, Any]] | None = None
    requires_confirmation: bool = False
