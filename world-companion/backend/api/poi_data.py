"""
poi_data.py — seed points-of-interest dataset for the routing engine.

Curated Bengaluru POI metadata used by:
- routing
- place search
- recommendations
- place details
- AI assistant

Tags are descriptive attributes used by the recommendation engine.
"""

BENGALURU_POIS = {
    "indiranagar": {
        "name": "Indiranagar",
        "lat": 12.9716,
        "lon": 77.6412,
        "category": "area",
        "tags": [
            "area",
            "dining",
            "shopping",
            "nightlife",
            "social",
        ],
    },

    "mg_road": {
        "name": "MG Road",
        "lat": 12.9758,
        "lon": 77.6045,
        "category": "shopping",
        "tags": [
            "shopping",
            "shopping_area",
            "dining",
            "culture",
            "social",
        ],
    },

    "lalbagh": {
        "name": "Lalbagh Botanical Garden",
        "lat": 12.9507,
        "lon": 77.5848,
        "category": "park",
        "tags": [
            "park",
            "nature",
            "outdoor",
            "relaxing",
            "garden",
        ],
    },

    "cubbon_park": {
        "name": "Cubbon Park",
        "lat": 12.9763,
        "lon": 77.5929,
        "category": "park",
        "tags": [
            "park",
            "nature",
            "outdoor",
            "relaxing",
            "walking",
        ],
    },

    "vv_puram": {
        "name": "VV Puram Food Street",
        "lat": 12.9452,
        "lon": 77.5738,
        "category": "food",
        "tags": [
            "food",
            "street_food",
            "evening",
            "social",
            "dining",
        ],
    },

    "koramangala": {
        "name": "Koramangala",
        "lat": 12.9352,
        "lon": 77.6245,
        "category": "area",
        "tags": [
            "area",
            "food",
            "dining",
            "shopping",
            "social",
            "nightlife",
        ],
    },

    "whitefield": {
        "name": "Whitefield",
        "lat": 12.9698,
        "lon": 77.7500,
        "category": "area",
        "tags": [
            "area",
            "dining",
            "shopping",
            "business",
        ],
    },

    "malleshwaram": {
        "name": "Malleshwaram",
        "lat": 13.0035,
        "lon": 77.5709,
        "category": "area",
        "tags": [
            "area",
            "culture",
            "shopping",
            "food",
        ],
    },

    "jayanagar": {
        "name": "Jayanagar",
        "lat": 12.9308,
        "lon": 77.5838,
        "category": "area",
        "tags": [
            "area",
            "shopping",
            "food",
            "dining",
        ],
    },

    "vidhana_soudha": {
        "name": "Vidhana Soudha",
        "lat": 12.9794,
        "lon": 77.5910,
        "category": "landmark",
        "tags": [
            "landmark",
            "architecture",
            "culture",
        ],
    },

    "bangalore_palace": {
        "name": "Bangalore Palace",
        "lat": 12.9986,
        "lon": 77.5920,
        "category": "landmark",
        "tags": [
            "landmark",
            "history",
            "culture",
            "architecture",
        ],
    },

    "iskcon_temple": {
        "name": "ISKCON Temple",
        "lat": 12.9767,
        "lon": 77.5511,
        "category": "landmark",
        "tags": [
            "landmark",
            "temple",
            "culture",
            "spiritual",
        ],
    },
}