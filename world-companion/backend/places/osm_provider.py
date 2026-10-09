import math
import time

import requests


# ---------------------------------------------------------------------------
# WorldCompanion Nearby Search Policy
# ---------------------------------------------------------------------------

DEFAULT_RADIUS_KM = 10.0
MIN_RADIUS_KM = 1.0
MAX_RADIUS_KM = 15.0


# Prefer the primary Overpass instance first.
# The second instance is a fallback when the primary is
# temporarily unavailable, rate-limited, or timing out.
OVERPASS_URLS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]


# ---------------------------------------------------------------------------
# WorldCompanion category -> OpenStreetMap selectors
# ---------------------------------------------------------------------------

CATEGORY_TAGS = {
    "food": [
        '["amenity"~"restaurant|cafe|fast_food|food_court|ice_cream"]',
        '["shop"~"bakery|confectionery|pastry|ice_cream"]',
    ],
    "restaurant": [
        '["amenity"="restaurant"]',
    ],
    "cafe": [
        '["amenity"="cafe"]',
    ],
    "park": [
        '["leisure"~"park|garden|nature_reserve|recreation_ground"]',
    ],
    "landmark": [
        '["tourism"~"attraction|museum|gallery|viewpoint|theme_park|zoo"]',
        '["historic"]',
    ],
    "shopping": [
        '["shop"]',
        '["shop"="mall"]',
    ],
    "hotel": [
        '["tourism"~"hotel|hostel|guest_house|motel|resort|apartment"]',
    ],
    "healthcare": [
        '["amenity"~"hospital|clinic|doctors|dentist"]',
    ],
    "pharmacy": [
        '["amenity"="pharmacy"]',
        '["shop"="chemist"]',
    ],
    "bank": [
        '["amenity"~"bank|atm"]',
    ],
    "fuel": [
        '["amenity"="fuel"]',
    ],
    "education": [
        '["amenity"~"school|college|university|kindergarten"]',
    ],
    "religious": [
        '["amenity"="place_of_worship"]',
    ],
    "transport": [
        '["highway"="bus_stop"]',
        '["railway"~"station|halt|tram_stop"]',
        '["public_transport"~"platform|station|stop_position"]',
    ],
}


# "All" deliberately stays focused on useful travel places.
# We do NOT query every named OSM object because that would make
# a 10-15 km search unnecessarily expensive.
DEFAULT_SELECTORS = [
    '["amenity"~"restaurant|cafe|fast_food|food_court|ice_cream"]',
    '["shop"~"bakery|confectionery|pastry|ice_cream|mall"]',
    '["leisure"~"park|garden|nature_reserve|recreation_ground"]',
    '["tourism"~"attraction|museum|gallery|viewpoint|theme_park|zoo|hotel|hostel|guest_house|motel|resort"]',
    '["historic"]',
    '["amenity"~"hospital|clinic|doctors|dentist|pharmacy|bank|atm|fuel|school|college|university|kindergarten|place_of_worship"]',
    '["highway"="bus_stop"]',
    '["railway"~"station|halt|tram_stop"]',
]


# ---------------------------------------------------------------------------
# Distance calculation
# ---------------------------------------------------------------------------

def _haversine_km(
    lat1,
    lon1,
    lat2,
    lon2,
):
    earth_radius_km = 6371.0

    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)

    delta_lat = math.radians(
        lat2 - lat1
    )
    delta_lon = math.radians(
        lon2 - lon1
    )

    a = (
        math.sin(delta_lat / 2) ** 2
        + math.cos(lat1_rad)
        * math.cos(lat2_rad)
        * math.sin(delta_lon / 2) ** 2
    )

    return (
        2
        * earth_radius_km
        * math.asin(math.sqrt(a))
    )


# ---------------------------------------------------------------------------
# Overpass query construction
# ---------------------------------------------------------------------------

def _build_query(
    latitude,
    longitude,
    radius_m,
    category=None,
):
    if category and category in CATEGORY_TAGS:
        selectors = CATEGORY_TAGS[category]
    else:
        selectors = DEFAULT_SELECTORS

    parts = []

    for selector in selectors:
        parts.append(
            f'nwr{selector}'
            f'(around:{radius_m},{latitude},{longitude});'
        )

    return f"""
[out:json][timeout:20];
(
    {"".join(parts)}
);
out center tags;
"""


# ---------------------------------------------------------------------------
# Overpass HTTP request
# ---------------------------------------------------------------------------

def _request_overpass(
    query,
    headers,
):
    last_error = None

    for index, overpass_url in enumerate(
        OVERPASS_URLS
    ):
        try:
            response = requests.post(
                overpass_url,
                data=query,
                headers=headers,
                timeout=30,
            )

            # Success.
            response.raise_for_status()

            return response

        except requests.RequestException as exc:
            last_error = exc

            # Do not immediately hammer the same public
            # endpoint repeatedly. Give it a short pause
            # before moving to the fallback.
            if index < len(OVERPASS_URLS) - 1:
                time.sleep(1)

    if last_error is not None:
        raise RuntimeError(
            "All Overpass providers failed. "
            f"Last error: {last_error}"
        )

    raise RuntimeError(
        "No Overpass provider was available."
    )


# ---------------------------------------------------------------------------
# Public provider API
# ---------------------------------------------------------------------------

def search_nearby(
    latitude,
    longitude,
    radius_km=DEFAULT_RADIUS_KM,
    category=None,
):
    """
    Search OpenStreetMap for real-world places
    around the supplied GPS coordinates.

    WorldCompanion Nearby policy:

        Minimum radius: 1 km
        Default radius: 10 km
        Maximum radius: 15 km

    Uses public Overpass instances with fallback support.

    Results are returned from nearest to farthest.
    """

    # -----------------------------------------------------------------------
    # Radius validation
    # -----------------------------------------------------------------------

    try:
        radius_km = float(radius_km)
    except (TypeError, ValueError):
        raise ValueError(
            "radius_km must be a valid number."
        )

    if radius_km < MIN_RADIUS_KM:
        raise ValueError(
            "radius_km must be at least 1 km."
        )

    if radius_km > MAX_RADIUS_KM:
        raise ValueError(
            "radius_km cannot be greater than 15 km."
        )

    # -----------------------------------------------------------------------
    # Category normalization
    # -----------------------------------------------------------------------

    if category == "":
        category = None

    if category is not None:
        category = category.strip().lower()

    # -----------------------------------------------------------------------
    # Build query
    # -----------------------------------------------------------------------

    radius_m = int(
        radius_km * 1000
    )

    query = _build_query(
        latitude=latitude,
        longitude=longitude,
        radius_m=radius_m,
        category=category,
    )

    headers = {
        "User-Agent": (
            "WorldCompanion/1.0 "
            "(development project)"
        )
    }

    # -----------------------------------------------------------------------
    # Query Overpass
    # -----------------------------------------------------------------------

    response = _request_overpass(
        query=query,
        headers=headers,
    )

    try:
        payload = response.json()
    except ValueError as exc:
        raise RuntimeError(
            "Overpass returned an invalid JSON response."
        ) from exc

    # -----------------------------------------------------------------------
    # Normalize results
    # -----------------------------------------------------------------------

    places = []

    for element in payload.get(
        "elements",
        [],
    ):
        tags = element.get(
            "tags",
            {},
        )

        name = tags.get("name")

        # We only want useful named places.
        if not name:
            continue

        # Nodes have direct coordinates.
        if element.get("type") == "node":
            place_lat = element.get("lat")
            place_lon = element.get("lon")

        # Ways/relations use the center returned by
        # "out center tags".
        else:
            center = element.get(
                "center",
                {},
            )

            place_lat = center.get(
                "lat"
            )
            place_lon = center.get(
                "lon"
            )

        if (
            place_lat is None
            or place_lon is None
        ):
            continue

        place_lat = float(place_lat)
        place_lon = float(place_lon)

        # -------------------------------------------------------------------
        # Calculate exact distance from user's GPS location.
        # -------------------------------------------------------------------

        distance_km = _haversine_km(
            latitude,
            longitude,
            place_lat,
            place_lon,
        )

        # Defensive filtering so nothing outside the requested
        # radius reaches Flutter.
        if distance_km > radius_km:
            continue

        # -------------------------------------------------------------------
        # Determine provider-specific type.
        # -------------------------------------------------------------------

        place_type = (
            tags.get("amenity")
            or tags.get("tourism")
            or tags.get("leisure")
            or tags.get("shop")
            or tags.get("highway")
            or tags.get("railway")
            or tags.get("historic")
            or "place"
        )

        places.append(
            {
                "provider_id": (
                    f"osm_"
                    f"{element.get('type')}_"
                    f"{element.get('id')}"
                ),
                "name": name,
                "latitude": place_lat,
                "longitude": place_lon,
                "category": category,
                "type": place_type,
                "address": _build_address(
                    tags
                ),
                "tags": tags,
                "distance_km": round(
                    distance_km,
                    3,
                ),
            }
        )

    # -----------------------------------------------------------------------
    # Nearest first
    # -----------------------------------------------------------------------

    places.sort(
        key=lambda place: place[
            "distance_km"
        ]
    )

    return places


# ---------------------------------------------------------------------------
# Address construction
# ---------------------------------------------------------------------------

def _build_address(tags):
    parts = []

    for key in [
        "addr:housenumber",
        "addr:street",
        "addr:suburb",
        "addr:city",
        "addr:state",
        "addr:postcode",
    ]:
        value = tags.get(key)

        if value:
            parts.append(value)

    return ", ".join(parts)
