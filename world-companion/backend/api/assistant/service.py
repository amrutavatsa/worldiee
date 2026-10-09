import json
from typing import Any

from places.geoapify_provider import get_place_details

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

    def _is_recommendation_request(
        self,
        message: str,
    ) -> bool:
        """
        Legacy recommendation detector.

        Recommendation routing is now handled by the LLM so that
        natural-language travel intent can be understood instead
        of relying on hard-coded phrases.
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
        Legacy deterministic recommendation handler.

        Kept for compatibility, but normal assistant routing now
        uses the LLM intent-understanding path.
        """

        result = self.execute_tool(
            tool_name="get_recommendations",
            arguments={
                "query": message,
            },
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
            name = place.get(
                "name",
                "Unknown place",
            )

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

    def _is_place_info_request(
        self,
        message: str,
    ) -> bool:
        """
        Detect requests asking for information about a specific place.
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

        # ---------------------------------------------------------
        # Resolve the provider/location ID safely.
        #
        # Different location providers may expose the identifier
        # under slightly different keys.
        # ---------------------------------------------------------

        place_id = (
            resolved.get("id")
            or resolved.get("place_id")
            or resolved.get("placeId")
            or resolved.get("location_id")
        )

        if not place_id:
            return {
                "success": False,
                "error": (
                    "I resolved the place, but WorldCompanion "
                    "did not return a usable place ID."
                ),
                "requires_confirmation": False,
            }

        details = self.execute_tool(
            tool_name="get_place_details",
            arguments={
                "place_id": place_id,
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

    def generate_place_intelligence(
        self,
        place_id: str,
    ) -> dict[str, Any]:
        """
        Generate grounded AI intelligence for a specific
        WorldCompanion real-world place.
        """

        place_id = str(place_id or "").strip()

        if not place_id:
            return {
                "success": False,
                "error": "place_id is required.",
            }

        try:
            details = get_place_details(place_id)

        except Exception as exc:
            return {
                "success": False,
                "error": (
                    f"Unable to retrieve place details: {exc}"
                ),
            }

        if not details:
            return {
                "success": False,
                "error": "Place details were not found.",
            }

        place_name = details.get(
            "name",
            "Unknown place",
        )

        grounded_data = {
            "name": place_name,
            "category": details.get("category"),
            "subcategory": details.get("subcategory"),
            "description": details.get("description"),
            "address": details.get("address"),
            "website": details.get("website"),
            "phone": details.get("phone"),
            "opening_hours": details.get("opening_hours"),
            "rating": details.get("rating"),
            "latitude": details.get("latitude"),
            "longitude": details.get("longitude"),
            "tags": details.get("tags"),
        }

        system_message = {
            "role": "system",
            "content": (
                "You are WorldCompanion's Place Intelligence system.\n\n"

                "Your job is to analyze a specific real-world place "
                "using ONLY the verified place data supplied by "
                "WorldCompanion.\n\n"

                "GROUNDING RULES:\n"
                "- Use only the supplied place data.\n"
                "- Never invent facts about the place.\n"
                "- Never invent ratings, prices, opening hours, "
                "facilities, events, history, safety information, "
                "crowd levels, travel times, or reviews.\n"
                "- Do not use general knowledge about the place unless "
                "that information is explicitly present in the supplied "
                "data.\n"
                "- If information required for an answer is unavailable, "
                "say that it is not available in WorldCompanion data.\n"
                "- Do not claim that you personally visited the place.\n\n"

                "OUTPUT FORMAT:\n"
                "Return concise travel intelligence using exactly these "
                "sections:\n\n"

                "WHY VISIT:\n"
                "Give a short useful explanation based only on the data.\n\n"

                "WHAT TO DO:\n"
                "Mention activities only when they can reasonably be "
                "supported by the supplied place data.\n\n"

                "BEST FOR:\n"
                "Identify suitable visitor types only when supported "
                "by the available data.\n\n"

                "BEST TIME:\n"
                "Use opening-hours data if available. Do not invent a "
                "preferred time of day when the data does not support it.\n\n"

                "TRAVEL INSIGHT:\n"
                "Give one concise practical insight based only on the "
                "available information.\n\n"

                "Keep the response concise and useful for a traveler."
            ),
        }

        user_message = {
            "role": "user",
            "content": (
                "Generate Place Intelligence for this verified "
                "WorldCompanion place.\n\n"
                f"{json.dumps(grounded_data, indent=2, default=str)}"
            ),
        }

        try:
            response = self.llm.chat(
                messages=[
                    system_message,
                    user_message,
                ],
            )

        except Exception as exc:
            return {
                "success": False,
                "error": (
                    f"AI Place Intelligence failed: {exc}"
                ),
            }

        assistant_message = response.get(
            "message",
            {},
        )

        content = assistant_message.get(
            "content",
            "",
        ).strip()

        if not content:
            return {
                "success": False,
                "error": (
                    "AI Place Intelligence returned "
                    "an empty response."
                ),
            }

        return {
            "success": True,
            "place": grounded_data,
            "intelligence": content,
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
        # Deterministic place-information routing
        # ---------------------------------------------------------

        if self._is_place_info_request(message):
            result = self._handle_place_info_request(
                message=message,
            )

            result["context"] = context

            return result

        # ---------------------------------------------------------
        # LLM travel-intent + native tool-calling path
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

            requires_confirmation = bool(
                result.get(
                    "requires_confirmation",
                    False,
                )
            )

            confirmation_tool = result.get(
                "tool",
            )

            return {
                "success": True,
                "message": content,
                "context": context,
                "tool_context": result.get(
                    "tool_context",
                    [],
                ),
                "requires_confirmation": requires_confirmation,
                "tool": confirmation_tool,
                "raw": result,
            }

        except Exception as exc:
            return {
                "success": False,
                "error": str(exc),
            }