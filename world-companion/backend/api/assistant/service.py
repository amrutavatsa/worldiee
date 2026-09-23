from typing import Any

from api.assistant.agent import AssistantAgent
from api.assistant.context import build_user_context
from api.assistant.ollama_cloud import OllamaCloud
from api.assistant.tool_schema import build_ollama_tools


class AssistantService:
    def __init__(self, user):
        self.user = user
        self.agent = AssistantAgent(user)
        self.llm = OllamaCloud()

    def execute_tool(
        self,
        tool_name: str,
        arguments: dict[str, Any] | None = None,
        confirmed: bool = False,
    ) -> dict[str, Any]:
        return self.agent.execute_tool(
            tool_name=tool_name,
            arguments=arguments,
            confirmed=confirmed,
        )

    def execute_plan(
        self,
        plan,
        confirmed: bool = False,
    ) -> dict[str, Any]:
        results = []

        for tool_plan in plan.plans:
            result = self.execute_tool(
                tool_name=tool_plan.tool,
                arguments=tool_plan.arguments,
                confirmed=confirmed,
            )

            results.append(result)

            if result.get("requires_confirmation"):
                return {
                    "success": True,
                    "intent": plan.intent,
                    "results": results,
                    "requires_confirmation": True,
                    "tool": tool_plan.tool,
                }

            if not result.get("success"):
                return {
                    "success": False,
                    "intent": plan.intent,
                    "results": results,
                }

        return {
            "success": True,
            "intent": plan.intent,
            "results": results,
            "requires_confirmation": False,
            "message": plan.response,
        }

    def _is_recommendation_request(self, message: str) -> bool:
        """
        Detect recommendation-style requests before sending the
        message to the LLM tool-selection loop.

        This prevents the LLM from treating recommendation requests
        as generic place searches.
        """

        text = message.lower().strip()

        recommendation_phrases = [
            "recommend",
            "recommendation",
            "recommendations",
            "suggest",
            "suggestion",
            "suggestions",
            "what should i visit",
            "where should i go",
            "where should we go",
            "what should we visit",
            "what can i visit",
            "place to visit",
            "places to visit",
            "somewhere to visit",
            "somewhere to go",
            "place to go",
            "places to go",
            "good place",
            "good places",
            "best place",
            "best places",
            "something relaxing",
            "somewhere relaxing",
            "relaxing place",
            "relaxing places",
            "peaceful place",
            "peaceful places",
            "quiet place",
            "quiet places",
            "nature place",
            "nature places",
            "romantic place",
            "romantic places",
            "family place",
            "family places",
        ]

        preference_words = [
            "relaxing",
            "peaceful",
            "quiet",
            "nature",
            "romantic",
            "family",
            "adventure",
            "shopping",
            "food",
            "dinner",
            "breakfast",
            "lunch",
        ]

        has_recommendation_phrase = any(
            phrase in text
            for phrase in recommendation_phrases
        )

        has_preference = any(
            word in text
            for word in preference_words
        )

        recommendation_verbs = [
            "recommend",
            "suggest",
            "should i",
            "should we",
            "where can i",
            "where can we",
            "what can i",
            "what can we",
        ]

        has_recommendation_verb = any(
            phrase in text
            for phrase in recommendation_verbs
        )

        return (
            has_recommendation_phrase
            or has_recommendation_verb
            or (
                has_preference
                and (
                    "place" in text
                    or "places" in text
                    or "visit" in text
                    or "go" in text
                )
            )
        )

    def _handle_recommendation_request(
        self,
        message: str,
    ) -> dict[str, Any]:
        """
        Deterministically execute the recommendation tool.

        The current recommendation engine uses the authenticated
        user's saved preferences and the current request.
        """

        result = self.execute_tool(
            tool_name="get_recommendations",
            arguments={"query": message},
            confirmed=False,
        )

        if not result.get("success"):
            return {
                "success": False,
                "error": result.get(
                    "error",
                    "Unable to get recommendations.",
                ),
                "requires_confirmation": False,
            }

        recommendations = result.get("data") or []

        if not recommendations:
            return {
                "success": True,
                "message": (
                    "I don't have any personalized recommendations "
                    "for you yet. Your WorldCompanion preferences "
                    "can be used to generate them once they are set."
                ),
                "results": [],
                "tool": "get_recommendations",
                "requires_confirmation": False,
            }

        lines = [
            "Based on your preferences and what you're looking for, "
            "here are some places you may like:"
        ]

        for index, place in enumerate(
            recommendations,
            start=1,
        ):
            name = place.get("name", "Unknown place")
            category = place.get("category")

            if category:
                lines.append(
                    f"{index}. {name} — {category}"
                )
            else:
                lines.append(
                    f"{index}. {name}"
                )

        lines.append(
            "\nThese recommendations combine your saved "
            "WorldCompanion preferences with what you asked for."
        )

        return {
            "success": True,
            "message": "\n".join(lines),
            "results": [
                result,
            ],
            "tool": "get_recommendations",
            "requires_confirmation": False,
        }

    def _is_place_info_request(self, message: str) -> bool:
        """
        Detect requests asking for information about a specific place.

        These requests should be resolved through WorldCompanion's
        place tools instead of relying on the LLM's general knowledge.
        """

        text = message.lower().strip()

        info_phrases = [
            "tell me about",
            "information about",
            "info about",
            "details about",
            "more about",
            "what is",
            "what's",
            "describe",
            "give me information",
            "find information",
        ]

        return any(
            phrase in text
            for phrase in info_phrases
        )

    def _handle_place_info_request(
        self,
        message: str,
    ) -> dict[str, Any]:
        """
        Resolve the requested place through WorldCompanion's
        location and place-details tools.
        """

        info_phrases = [
            "tell me about",
            "information about",
            "info about",
            "details about",
            "more about",
            "what is",
            "what's",
            "describe",
            "give me information",
            "find information",
        ]

        text = message.lower().strip()

        place_name = text

        for phrase in info_phrases:
            if phrase in text:
                place_name = text.split(
                    phrase,
                    1,
                )[1].strip()
                break

        location = self.execute_tool(
            tool_name="resolve_location",
            arguments={
                "place_name": place_name,
            },
            confirmed=False,
        )

        if not location.get("success"):
            return {
                "success": False,
                "error": "I couldn't resolve that place.",
                "requires_confirmation": False,
            }

        resolved = location.get("data")

        if not resolved:
            return {
                "success": False,
                "error": (
                    "I couldn't find that place in "
                    "WorldCompanion."
                ),
                "requires_confirmation": False,
            }

        details = self.execute_tool(
            tool_name="get_place_details",
            arguments={
                "place_id": resolved["id"],
            },
            confirmed=False,
        )

        if not details.get("success"):
            return {
                "success": False,
                "error": (
                    "I couldn't retrieve the place details."
                ),
                "requires_confirmation": False,
            }

        return {
            "success": True,
            "message": details.get("data"),
            "results": [
                location,
                details,
            ],
            "tool": "get_place_details",
            "requires_confirmation": False,
        }

    def handle_message(
        self,
        message: str,
        confirmed: bool = False,
        conversation: list[dict[str, Any]] | None = None,
    ) -> dict[str, Any]:
        message = message.strip()

        if not message:
            return {
                "success": False,
                "error": "Message cannot be empty.",
            }

        context = build_user_context(self.user)

        # ---------------------------------------------------------
        # Deterministic recommendation routing
        # ---------------------------------------------------------
        #
        # If this is clearly a recommendation request, execute
        # get_recommendations directly instead of allowing the
        # LLM to incorrectly select search_places.
        #
        if self._is_recommendation_request(message):
            result = self._handle_recommendation_request(
                message=message,
            )

            result["context"] = context

            return result

        # ---------------------------------------------------------
        # Deterministic place-information routing
        # ---------------------------------------------------------
        #
        # If the user is asking for information about a specific
        # place, resolve the place and retrieve verified
        # WorldCompanion information before involving the LLM.
        #
        if self._is_place_info_request(message):
            result = self._handle_place_info_request(
                message=message,
            )

            result["context"] = context

            return result

        # ---------------------------------------------------------
        # Normal LLM + native tool-calling path
        # ---------------------------------------------------------

        tools = build_ollama_tools()

        messages = []

        if conversation:
            messages.extend(conversation)

        messages.append(
            {
                "role": "user",
                "content": message,
            }
        )

        try:
            result = self.llm.chat_with_tools(
                messages=messages,
                tools=tools,
                tool_executor=lambda tool_name, arguments:
                    self.execute_tool(
                        tool_name=tool_name,
                        arguments=arguments,
                        confirmed=confirmed,
                    ),
            )

            assistant_message = result.get(
                "message",
                {},
            )

            content = assistant_message.get(
                "content",
                "",
            )

            return {
                "success": True,
                "message": content,
                "context": context,
                "requires_confirmation": False,
                "raw": result,
            }

        except Exception as exc:
            return {
                "success": False,
                "error": str(exc),
            }