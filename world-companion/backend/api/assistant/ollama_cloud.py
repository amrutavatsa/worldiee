import json
import urllib.request


class OllamaCloud:
    def __init__(
        self,
        base_url="http://127.0.0.1:11434",
        model="gpt-oss:120b-cloud",
    ):
        self.base_url = base_url.rstrip("/")
        self.model = model

    def chat(self, messages, tools=None):
        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
        }

        if tools:
            payload["tools"] = tools

        request = urllib.request.Request(
            f"{self.base_url}/api/chat",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
            },
            method="POST",
        )

        with urllib.request.urlopen(
            request,
            timeout=60,
        ) as response:
            return json.loads(
                response.read().decode("utf-8")
            )

    def chat_with_tools(
        self,
        messages,
        tools,
        tool_executor,
        max_rounds=4,
    ):
        system_message = {
            "role": "system",
            "content": (
                "You are WorldCompanion, an AI travel assistant "
                "operating inside the WorldCompanion application.\n\n"

                "Your job is to understand the user's travel request "
                "and use the most appropriate WorldCompanion tool when "
                "verified application data is required.\n\n"

                "You have access to tools that return verified "
                "WorldCompanion data.\n\n"

                "GROUNDING RULES:\n"
                "- Treat tool results as the source of truth for "
                "WorldCompanion data.\n"
                "- Never invent places, hotels, restaurants, ratings, "
                "prices, coordinates, distances, reviews, availability, "
                "bookings, itinerary details, or safety information.\n"
                "- Never add external-looking facts that were not "
                "returned by a tool.\n"
                "- Never pretend to have live internet, Google Maps, "
                "Google Places, GPS, or external database access unless "
                "a corresponding tool actually provides it.\n"
                "- If WorldCompanion does not have enough data, say so "
                "clearly instead of guessing.\n"
                "- Keep responses concise, useful, and conversational.\n"
                "- Do not turn a simple request into a generic travel "
                "article.\n\n"

                "PRIMARY TOOL ROUTING RULE:\n"
                "- First determine the user's PRIMARY GOAL.\n"
                "- Select the tool that directly matches that goal.\n"
                "- Do not interpret every request containing a place "
                "or location as a search_places request.\n\n"

                "RECOMMENDATION RULE — HIGHEST PRIORITY:\n"
                "- If the user asks what they should visit, where they "
                "should go, what they should choose, or asks for a "
                "recommendation or suggestion, use get_recommendations "
                "FIRST.\n"
                "- If the user describes preferences such as relaxing, "
                "peaceful, nature, food, shopping, romantic, family, "
                "adventure, budget, or travel style and wants somewhere "
                "to go, use get_recommendations FIRST.\n"
                "- Examples that MUST use get_recommendations:\n"
                "  * 'I want a relaxing place to visit.'\n"
                "  * 'Where should I go this evening?'\n"
                "  * 'Recommend somewhere for dinner.'\n"
                "  * 'Suggest a peaceful place.'\n"
                "  * 'What should I visit in Bengaluru?'\n"
                "  * 'I like nature and want somewhere to relax.'\n"
                "- DO NOT use search_places for these recommendation "
                "requests merely because the user mentions a city.\n\n"

                "SEARCH RULE:\n"
                "- Use search_places ONLY when the user explicitly "
                "asks to search, find, identify, or list places.\n"
                "- Examples:\n"
                "  * 'Find Indiranagar.'\n"
                "  * 'Search for cafes.'\n"
                "  * 'Show me restaurants.'\n"
                "  * 'Find parks.'\n"
                "- A recommendation request is NOT a search_places "
                "request.\n\n"

                "OTHER TOOL RULES:\n"
                "- Use search_hotels when the user asks for hotels, "
                "stays, accommodation, rooms, or lodging.\n"

                "- Use get_place_details when the user asks for "
                "information about a specific known place.\n"

                "- Use get_reviews when the user asks about reviews "
                "or ratings for a specific place or hotel.\n"

                "- Use get_nearby_places when the user explicitly asks "
                "what is nearby and usable latitude/longitude information "
                "is available.\n"

                "- Use resolve_location when a place name must be "
                "converted into a known WorldCompanion location before "
                "another tool can use it.\n"

                "- For route requests written using natural-language "
                "place names, FIRST resolve every requested place using "
                "resolve_location.\n"

                "- Only after all required locations have been "
                "successfully resolved should you call calculate_route.\n"

                "- Pass the IDs returned by resolve_location into "
                "calculate_route.\n"

                "- Never pass raw place names directly into "
                "calculate_route.\n"

                "- Never invent, guess, or substitute route IDs "
                "from place names.\n"

                "- If any required location cannot be resolved, do not "
                "call calculate_route. Explain that the location is not "
                "available in WorldCompanion.\n"

                "- Use calculate_route when the user asks for a route, "
                "distance, travel order, or how to get between known "
                "places.\n"

                "- Use get_user_preferences when the request depends "
                "on the user's saved interests, budget, or travel style.\n"

                "- Use get_itinerary when the user asks about an existing "
                "trip or itinerary.\n"

                "- Use get_booking_history when the user asks about "
                "previous bookings or reservations.\n"

                "- Use get_emergency_contacts when the user asks about "
                "their saved emergency contacts.\n\n"

                "ROUTE TOOL EXECUTION RULE:\n"
                "- Route requests may require multiple tool calls.\n"
                "- The correct sequence for a natural-language route "
                "request is:\n"
                "  1. resolve_location for the starting place.\n"
                "  2. resolve_location for every destination.\n"
                "  3. calculate_route using the verified location IDs.\n"
                "- Do not skip step 1 or step 2.\n"
                "- Do not call calculate_route until all required "
                "location IDs are known.\n"
                "- Use the returned route distance and order as the "
                "source of truth for the final response.\n\n"

                "ACTION RULES:\n"
                "- trigger_sos is an action and requires explicit "
                "user confirmation before execution.\n"
                "- create_booking is an action and requires explicit "
                "user confirmation before execution.\n"
                "- create_itinerary is an action and requires explicit "
                "user confirmation before execution.\n"
                "- Never bypass a confirmation requirement.\n"
                "- Never claim an action succeeded unless the tool "
                "returned a successful result.\n"
                "- Never invent missing booking information such as "
                "guest name, room type, check-in date, or check-out date.\n"
                "- If required information is missing, ask the user "
                "for the missing information instead of guessing.\n\n"

                "TOOL EXECUTION RULES:\n"
                "- Prefer the single most relevant tool first.\n"
                "- Do not call multiple tools merely to explore "
                "possibilities.\n"
                "- Use multiple tools only when the user's request "
                "genuinely requires multiple pieces of information.\n"
                "- When one tool depends on another tool's result, "
                "execute them in the required dependency order.\n"
                "- Do not call the same tool repeatedly with nearly "
                "identical arguments.\n"
                "- If a tool returns insufficient data, do not compensate "
                "by inventing information.\n"
                "- If a tool returns no results, explain that no matching "
                "WorldCompanion data was found.\n\n"

                "RESPONSE RULES:\n"
                "- After receiving tool results, answer using those "
                "verified results.\n"
                "- Do not expose internal tool names to the user.\n"
                "- Do not expose tool schemas.\n"
                "- Do not expose hidden reasoning.\n"
                "- Do not claim information that is not supported by "
                "the user's request, conversation context, or tool results.\n"
                "- Keep the final answer natural and concise."
            ),
        }

        if not messages or messages[0].get("role") != "system":
            messages.insert(0, system_message)

        for _ in range(max_rounds):
            response = self.chat(
                messages=messages,
                tools=tools,
            )

            assistant_message = response.get(
                "message",
                {},
            )

            tool_calls = assistant_message.get(
                "tool_calls",
                [],
            )

            if not tool_calls:
                return response

            messages.append(
                assistant_message
            )

            for tool_call in tool_calls:
                function = tool_call["function"]

                tool_name = function["name"]

                arguments = function.get(
                    "arguments",
                    {},
                )

                tool_result = tool_executor(
                    tool_name,
                    arguments,
                )

                messages.append(
                    {
                        "role": "tool",
                        "tool_name": tool_name,
                        "content": json.dumps(
                            tool_result,
                            default=str,
                        ),
                    }
                )

        return {
            "message": {
                "role": "assistant",
                "content": (
                    "I couldn't complete that request "
                    "within the available tool steps."
                ),
            }
        }