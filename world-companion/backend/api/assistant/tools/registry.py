from .booking_history import get_booking_history
from .emergency import get_emergency_contacts
from .hotels import search_hotels
from .itineraries import get_itinerary
from .nearby import get_nearby_places
from .place_details import get_place_details
from .places import search_places
from .recommendations import get_recommendations
from .reviews import get_reviews
from .routes import calculate_route
from .sos import trigger_sos
from .preferences import get_user_preferences
from .bookings import create_booking
from .itineraries_create import create_itinerary
from .locations import resolve_location


TOOL_REGISTRY = {
    "search_places": {
        "function": search_places,
        "requires_confirmation": False,
        "description": (
            "Search real-world places in a specified city, area, or "
            "location. Use this when the user wants actual matching "
            "places such as restaurants, cafes, attractions, parks, "
            "shopping, food, or other place categories. Extract the "
            "location separately from the category. Example: for "
            "'Find restaurants in Shivamogga', use query='Shivamogga' "
            "and category='restaurant'. Do not use this tool merely "
            "because the user asks for a recommendation."
        ),
    },
    "search_hotels": {
        "function": search_hotels,
        "requires_confirmation": False,
        "description": (
            "Search available hotels, stays, accommodation, rooms, "
            "or lodging by area or maximum price. Extract the "
            "location and budget from the user's request when "
            "provided."
        ),
    },
    "get_place_details": {
        "function": get_place_details,
        "requires_confirmation": False,
        "description": (
            "Get verified detailed information about a specific "
            "WorldCompanion place."
        ),
    },
    "get_nearby_places": {
        "function": get_nearby_places,
        "requires_confirmation": False,
        "description": (
            "Get currently available real-world places near the "
            "provided latitude and longitude. Use this only when "
            "usable coordinates are available."
        ),
    },
    "resolve_location": {
        "function": resolve_location,
        "requires_confirmation": False,
        "description": (
            "Resolve a city, area, or place name into verified "
            "WorldCompanion location information. Use this when "
            "another tool requires a resolved location."
        ),
    },
    "get_reviews": {
        "function": get_reviews,
        "requires_confirmation": False,
        "description": (
            "Get WorldCompanion reviews or ratings for a specific "
            "place or hotel."
        ),
    },
    "calculate_route": {
        "function": calculate_route,
        "requires_confirmation": False,
        "description": (
            "Calculate a multi-stop route between verified "
            "WorldCompanion locations using the existing internal "
            "routing engine. Requires verified location IDs."
        ),
    },
    "get_recommendations": {
        "function": get_recommendations,
        "requires_confirmation": False,
        "requires_user": True,
        "description": (
            "Return personalized travel recommendations for the "
            "authenticated user. Use this tool when the user is "
            "asking what they should choose, where they should go, "
            "or what would suit their preferences. Pass the user's "
            "current request as query so recommendations can combine "
            "the current request with the user's saved interests. "
            "Examples include 'somewhere peaceful', 'something for "
            "my family', 'a romantic place', or 'I want something "
            "historical'. Do not use this tool for simple place "
            "discovery when the user explicitly asks to find or "
            "list places."
        ),
    },
    "get_booking_history": {
        "function": get_booking_history,
        "requires_confirmation": False,
        "requires_user": True,
        "description": (
            "Get the authenticated user's previous hotel bookings "
            "or reservations."
        ),
    },
    "get_itinerary": {
        "function": get_itinerary,
        "requires_confirmation": False,
        "requires_user": True,
        "description": (
            "Get one of the authenticated user's saved itineraries "
            "or trip information."
        ),
    },
    "get_emergency_contacts": {
        "function": get_emergency_contacts,
        "requires_confirmation": False,
        "requires_user": True,
        "description": (
            "Get the authenticated user's saved emergency contacts."
        ),
    },
    "get_user_preferences": {
        "function": get_user_preferences,
        "requires_confirmation": False,
        "requires_user": True,
        "description": (
            "Get the authenticated user's saved travel preferences, "
            "interests, budget, or travel style."
        ),
    },
    "trigger_sos": {
        "function": trigger_sos,
        "requires_confirmation": True,
        "requires_user": True,
        "description": (
            "Start the simulated SOS process for the authenticated "
            "user. Requires explicit user confirmation."
        ),
    },
    "create_booking": {
        "function": create_booking,
        "requires_confirmation": True,
        "requires_user": True,
        "description": (
            "Create a simulated hotel booking for the authenticated "
            "user. Requires explicit confirmation and all required "
            "booking information."
        ),
    },
    "create_itinerary": {
        "function": create_itinerary,
        "requires_confirmation": True,
        "requires_user": True,
        "description": (
            "Create and save a travel itinerary for the authenticated "
            "user. Requires explicit confirmation."
        ),
    },
}


def get_tool_definitions():
    definitions = []

    for name, tool in TOOL_REGISTRY.items():
        definitions.append(
            {
                "name": name,
                "description": tool["description"],
                "requires_confirmation": (
                    tool["requires_confirmation"]
                ),
                "requires_user": tool.get(
                    "requires_user",
                    False,
                ),
            }
        )

    return definitions


def get_tool_schemas():
    return {
        "search_places": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": (
                        "The city, area, or location where places "
                        "should be searched. Pass the location itself, "
                        "not the entire natural-language user request."
                    ),
                },
                "category": {
                    "type": ["string", "null"],
                    "description": (
                        "The actual place category requested by the "
                        "user, such as restaurant, cafe, hotel, "
                        "attraction, park, shopping, or food. Use "
                        "null when no specific category is requested."
                    ),
                },
                "radius_km": {
                    "type": "number",
                    "description": (
                        "Search radius in kilometers. Use approximately "
                        "10 for a city-level search unless the user "
                        "specifies a different area or radius."
                    ),
                },
            },
            "required": ["query"],
        },
        "search_hotels": {
            "type": "object",
            "properties": {
                "area": {
                    "type": ["string", "null"],
                    "description": (
                        "City, area, or location where accommodation "
                        "is required."
                    ),
                },
                "max_price": {
                    "type": ["number", "null"],
                    "description": (
                        "Maximum acceptable price when the user "
                        "specifies a budget."
                    ),
                },
            },
            "required": [],
        },
        "get_place_details": {
            "type": "object",
            "properties": {
                "place_id": {
                    "type": "string",
                    "description": (
                        "Verified WorldCompanion place ID."
                    ),
                },
            },
            "required": ["place_id"],
        },
        "get_nearby_places": {
            "type": "object",
            "properties": {
                "latitude": {
                    "type": "number",
                    "description": (
                        "Latitude of the reference location."
                    ),
                },
                "longitude": {
                    "type": "number",
                    "description": (
                        "Longitude of the reference location."
                    ),
                },
                "radius_km": {
                    "type": "number",
                    "description": (
                        "Search radius in kilometers."
                    ),
                },
                "category": {
                    "type": ["string", "null"],
                    "description": (
                        "Optional place category such as restaurant, "
                        "cafe, park, attraction, or food."
                    ),
                },
            },
            "required": [
                "latitude",
                "longitude",
                "radius_km",
            ],
        },
        "resolve_location": {
            "type": "object",
            "properties": {
                "place_name": {
                    "type": "string",
                    "description": (
                        "City, area, or place name that needs to "
                        "be resolved."
                    ),
                },
            },
            "required": ["place_name"],
        },
        "get_reviews": {
            "type": "object",
            "properties": {
                "target_type": {
                    "type": "string",
                    "description": (
                        "Target type such as place or hotel."
                    ),
                },
                "target_id": {
                    "type": "string",
                    "description": (
                        "Verified ID of the place or hotel."
                    ),
                },
            },
            "required": [
                "target_type",
                "target_id",
            ],
        },
        "calculate_route": {
            "type": "object",
            "properties": {
                "start_id": {
                    "type": "string",
                    "description": (
                        "Verified WorldCompanion starting location ID."
                    ),
                },
                "stop_ids": {
                    "type": "array",
                    "items": {
                        "type": "string",
                    },
                    "description": (
                        "Verified WorldCompanion destination IDs."
                    ),
                },
            },
            "required": [
                "start_id",
                "stop_ids",
            ],
        },
        "get_recommendations": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": (
                        "The user's current recommendation request, "
                        "including relevant preferences such as "
                        "peaceful, family, romantic, food, nature, "
                        "historical, or similar interests."
                    ),
                },
            },
            "required": ["query"],
        },
        "get_booking_history": {
            "type": "object",
            "properties": {},
            "required": [],
        },
        "get_itinerary": {
            "type": "object",
            "properties": {
                "itinerary_id": {
                    "type": "string",
                },
            },
            "required": ["itinerary_id"],
        },
        "get_emergency_contacts": {
            "type": "object",
            "properties": {},
            "required": [],
        },
        "get_user_preferences": {
            "type": "object",
            "properties": {},
            "required": [],
        },
        "trigger_sos": {
            "type": "object",
            "properties": {
                "latitude": {
                    "type": ["number", "null"],
                },
                "longitude": {
                    "type": ["number", "null"],
                },
            },
            "required": [],
        },
        "create_booking": {
            "type": "object",
            "properties": {
                "hotel_id": {
                    "type": "string",
                },
                "guest_name": {
                    "type": "string",
                },
                "room_type": {
                    "type": "string",
                },
                "check_in": {
                    "type": "string",
                },
                "check_out": {
                    "type": "string",
                },
            },
            "required": [
                "hotel_id",
                "guest_name",
                "room_type",
                "check_in",
                "check_out",
            ],
        },
        "create_itinerary": {
            "type": "object",
            "properties": {
                "title": {
                    "type": "string",
                },
                "stops": {
                    "type": "array",
                    "items": {
                        "type": "object",
                    },
                },
            },
            "required": [
                "title",
                "stops",
            ],
        },
    }
