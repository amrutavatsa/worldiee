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
        "description": "Search places by name or category.",
    },
    "search_hotels": {
        "function": search_hotels,
        "requires_confirmation": False,
        "description": "Search available hotels by area or maximum price.",
    },
    "get_place_details": {
        "function": get_place_details,
        "requires_confirmation": False,
        "description": "Get detailed information about a place.",
    },
    "get_nearby_places": {
        "function": get_nearby_places,
        "requires_confirmation": False,
        "description": "Get currently available nearby places.",
    },
    "resolve_location": {
        "place_name": "string",
    },
    "get_reviews": {
        "function": get_reviews,
        "requires_confirmation": False,
        "description": "Get WorldCompanion reviews for a place or hotel.",
    },
    "calculate_route": {
        "function": calculate_route,
        "requires_confirmation": False,
        "description": "Calculate a multi-stop route using the existing routing engine.",
    },
    "get_recommendations": {
        "function": get_recommendations,
        "requires_confirmation": False,
        "requires_user": True,
        "description": "Get personalized place recommendations.",
    },
    "get_booking_history": {
        "function": get_booking_history,
        "requires_confirmation": False,
        "requires_user": True,
        "description": "Get the authenticated user's booking history.",
    },
    "get_itinerary": {
        "function": get_itinerary,
        "requires_confirmation": False,
        "requires_user": True,
        "description": "Get one of the authenticated user's saved itineraries.",
    },
    "get_emergency_contacts": {
        "function": get_emergency_contacts,
        "requires_confirmation": False,
        "requires_user": True,
        "description": "Get the authenticated user's emergency contacts.",
    },
    "get_user_preferences": {
        "function": get_user_preferences,
        "requires_confirmation": False,
        "requires_user": True,
        "description": "Get the authenticated user's travel preferences.",
    },
    "trigger_sos": {
        "function": trigger_sos,
        "requires_confirmation": True,
        "requires_user": True,
        "description": "Start the simulated SOS process for the authenticated user.",
    },
    "create_booking": {
        "function": create_booking,
        "requires_confirmation": True,
        "requires_user": True,
        "description": "Create a simulated hotel booking for the authenticated user.",
    },
    "create_itinerary": {
        "function": create_itinerary,
        "requires_confirmation": True,
        "requires_user": True,
        "description": "Create and save a travel itinerary for the authenticated user.",
    },
    "resolve_location": {
    "function": resolve_location,
    "requires_confirmation": False,
    "description": "Resolve a place name into its coordinates.",
    },
}
def get_tool_definitions():
    definitions = []

    for name, tool in TOOL_REGISTRY.items():
        definitions.append(
            {
                "name": name,
                "description": tool["description"],
                "requires_confirmation": tool["requires_confirmation"],
                "requires_user": tool.get("requires_user", False),
            }
        )

    return definitions

def get_tool_schemas():
    return {
        "search_places": {
            "type": "object",
            "properties": {
                "query": {
                    "type": ["string", "null"],
                },
                "category": {
                    "type": ["string", "null"],
                },
            },
            "required": [],
        },
        "search_hotels": {
            "type": "object",
            "properties": {
                "area": {
                    "type": ["string", "null"],
                },
                "max_price": {
                    "type": ["number", "null"],
                },
            },
            "required": [],
        },
        "get_place_details": {
            "type": "object",
            "properties": {
                "place_id": {
                    "type": "string",
                },
            },
            "required": ["place_id"],
        },
        "get_nearby_places": {
            "type": "object",
            "properties": {
                "latitude": {
                    "type": "number",
                },
                "longitude": {
                    "type": "number",
                },
                "radius_km": {
                    "type": "number",
                },
                "category": {
                    "type": ["string", "null"],
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
                },
            },
            "required": ["place_name"],
        },
        "get_reviews": {
            "type": "object",
            "properties": {
                "target_type": {
                    "type": "string",
                },
                "target_id": {
                    "type": "string",
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
                },
                "stop_ids": {
                    "type": "array",
                    "items": {
                        "type": "string",
                    },
                },
            },
            "required": [
                "start_id",
                "stop_ids",
            ],
        },
        "get_recommendations": {
            "type": "object",
            "properties": {},
            "required": [],
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