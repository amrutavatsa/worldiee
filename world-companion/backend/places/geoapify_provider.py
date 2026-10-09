import math
import os

import requests
from dotenv import load_dotenv


# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

load_dotenv()


# ---------------------------------------------------------------------------
# WorldCompanion Nearby Search Policy
# ---------------------------------------------------------------------------

DEFAULT_RADIUS_KM = 10.0
MIN_RADIUS_KM = 1.0
MAX_RADIUS_KM = 15.0

DEFAULT_LIMIT = 20
MAX_LIMIT = 20


# ---------------------------------------------------------------------------
# Geoapify API
# ---------------------------------------------------------------------------

GEOAPIFY_URL = "https://api.geoapify.com/v2/places"

GEOAPIFY_PLACE_DETAILS_URL = (
    "https://api.geoapify.com/v2/place-details"
)
GEOAPIFY_GEOCODING_URL = (
    "https://api.geoapify.com/v1/geocode/search"
)


# ---------------------------------------------------------------------------
# WorldCompanion travel categories
# ---------------------------------------------------------------------------

CATEGORY_MAP = {
    # Food & Dining
    "food": ",".join(
        [
            "catering.restaurant",
            "catering.cafe",
            "catering.bar",
            "catering.pub",
            "catering.biergarten",
            "catering.fast_food",
            "catering.food_court",
        ]
    ),

    "restaurant": "catering.restaurant",
    "cafe": "catering.cafe",
    "bar": "catering.bar",
    "pub": "catering.pub",

    # Stays
    "stays": "accommodation",
    "hotel": "accommodation.hotel",
    "hostel": "accommodation.hostel",
    "guest_house": "accommodation.guest_house",

    # Explore
    "explore": ",".join(
        [
            "tourism",
            "entertainment.museum",
            "entertainment.culture.gallery",
            "entertainment.aquarium",
            "entertainment.zoo",
            "entertainment.theme_park",
        ]
    ),

    "landmark": "tourism",
    "museum": "entertainment.museum",

    # Shopping
    "shopping": ",".join(
        [
            "commercial.shopping_mall",
            "commercial.marketplace",
            "commercial.department_store",
        ]
    ),

    "mall": "commercial.shopping_mall",
    "market": "commercial.marketplace",

    # Leisure
    "leisure": ",".join(
        [
            "leisure",
            "entertainment",
        ]
    ),

    "park": "leisure.park",

    # Utilities
    "healthcare": "healthcare",
    "pharmacy": "healthcare.pharmacy",
    "bank": "service.financial.bank",
    "fuel": "service.vehicle.fuel",
    "transport": "public_transport",
}


# ---------------------------------------------------------------------------
# Categories used by the main Nearby "All" view
# ---------------------------------------------------------------------------

ALL_CATEGORIES = [
    "food",
    "stays",
    "explore",
    "shopping",
    "leisure",
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
# Category handling
# ---------------------------------------------------------------------------

def _resolve_category(category):
    if category is None:
        return None

    category = category.strip().lower()

    if category in {
        "",
        "all",
    }:
        return None

    return CATEGORY_MAP.get(category)


# ---------------------------------------------------------------------------
# Address handling
# ---------------------------------------------------------------------------

def _build_address(properties):
    address = properties.get(
        "formatted"
    )

    if address:
        return address

    parts = []

    for key in [
        "street",
        "suburb",
        "district",
        "city",
        "state",
        "postcode",
        "country",
    ]:
        value = properties.get(key)

        if value:
            parts.append(
                str(value)
            )

    return ", ".join(parts)


# ---------------------------------------------------------------------------
# Type handling
# ---------------------------------------------------------------------------

def _get_place_type(properties):
    categories = properties.get(
        "categories",
        [],
    )

    if categories:
        return categories[-1]

    return "place"


# ---------------------------------------------------------------------------
# Valid place detection
# ---------------------------------------------------------------------------

def _is_valid_place(properties):
    categories = properties.get(
        "categories",
        [],
    )

    if not isinstance(
        categories,
        list,
    ):
        categories = []

    category_text = " ".join(
        str(value).lower()
        for value in categories
    )

    rejected_terms = [
        "railway",
        "rail",
        "building",
        "boundary",
        "administrative",
    ]

    for term in rejected_terms:
        if term in category_text:
            return False

    name = properties.get(
        "name"
    )

    address_line1 = properties.get(
        "address_line1"
    )

    if not name and not address_line1:
        return False

    return True


# ---------------------------------------------------------------------------
# Result category detection
# ---------------------------------------------------------------------------

def _detect_result_category(
    requested_category,
    categories,
):
    """
    Convert Geoapify categories into the WorldCompanion
    travel taxonomy.

    This function is shared by Nearby Search and
    Place Details so both endpoints return consistent
    category information.
    """

    category_text = " ".join(
        str(value).lower()
        for value in categories
    )

    # -----------------------------------------------------------------------
    # Food & Dining
    # -----------------------------------------------------------------------

    if (
        "catering.restaurant"
        in category_text
    ):
        return "restaurant"

    if "catering.cafe" in category_text:
        return "cafe"

    if "catering.bar" in category_text:
        return "bar"

    if "catering.pub" in category_text:
        return "pub"

    if (
        "catering.biergarten"
        in category_text
    ):
        return "pub"

    if (
        "catering.fast_food"
        in category_text
    ):
        return "food"

    if (
        "catering.food_court"
        in category_text
    ):
        return "food"

    if "catering" in category_text:
        return "food"

    # -----------------------------------------------------------------------
    # Stays
    # -----------------------------------------------------------------------

    if "accommodation" in category_text:
        if (
            "accommodation.hotel"
            in category_text
        ):
            return "hotel"

        if (
            "accommodation.hostel"
            in category_text
        ):
            return "hostel"

        if (
            "accommodation.guest_house"
            in category_text
        ):
            return "guest_house"

        return "stay"

    # -----------------------------------------------------------------------
    # Explore
    # -----------------------------------------------------------------------

    if (
        "tourism.attraction"
        in category_text
    ):
        if (
            "tourism.attraction.viewpoint"
            in category_text
        ):
            return "viewpoint"

        return "attraction"

    if (
        "tourism.sights"
        in category_text
    ):
        return "landmark"

    if "tourism" in category_text:
        return "tourist_place"

    if (
        "entertainment.museum"
        in category_text
    ):
        return "museum"

    if (
        "entertainment.culture.gallery"
        in category_text
    ):
        return "gallery"

    if (
        "entertainment.aquarium"
        in category_text
    ):
        return "aquarium"

    if (
        "entertainment.zoo"
        in category_text
    ):
        return "zoo"

    if (
        "entertainment.theme_park"
        in category_text
    ):
        return "theme_park"

    # -----------------------------------------------------------------------
    # Shopping
    # -----------------------------------------------------------------------

    if (
        "commercial.shopping_mall"
        in category_text
    ):
        return "mall"

    if (
        "commercial.marketplace"
        in category_text
    ):
        return "market"

    if (
        "commercial.department_store"
        in category_text
    ):
        return "shopping"

    if "commercial" in category_text:
        return "shopping"

    # -----------------------------------------------------------------------
    # Leisure
    # -----------------------------------------------------------------------

    if (
        "leisure.park"
        in category_text
    ):
        return "park"

    if (
        "leisure.garden"
        in category_text
    ):
        return "garden"

    if "leisure" in category_text:
        return "leisure"

    if "entertainment" in category_text:
        return "entertainment"

    # -----------------------------------------------------------------------
    # Utilities
    # -----------------------------------------------------------------------

    if (
        "healthcare.pharmacy"
        in category_text
    ):
        return "pharmacy"

    if "healthcare" in category_text:
        return "healthcare"

    if (
        "service.financial.bank"
        in category_text
    ):
        return "bank"

    if (
        "service.vehicle.fuel"
        in category_text
    ):
        return "fuel"

    if (
        "public_transport"
        in category_text
    ):
        return "transport"

    # -----------------------------------------------------------------------
    # Fallback
    # -----------------------------------------------------------------------

    if requested_category:
        return requested_category

    return "other"


# ---------------------------------------------------------------------------
# Subcategory detection
# ---------------------------------------------------------------------------

def _detect_subcategory(
    category,
    categories,
):
    """
    Convert detailed Geoapify categories into a useful
    WorldCompanion subcategory.
    """

    category_text = " ".join(
        str(value).lower()
        for value in categories
    )

    if category == "restaurant":
        return "restaurant"

    if category == "cafe":
        return "cafe"

    if category == "bar":
        return "bar"

    if category == "pub":
        return "pub"

    if category == "food":
        if "fast_food" in category_text:
            return "fast_food"

        if "food_court" in category_text:
            return "food_court"

        return "food"

    if category in {
        "hotel",
        "hostel",
        "guest_house",
        "stay",
    }:
        return category

    if category in {
        "attraction",
        "viewpoint",
        "landmark",
        "tourist_place",
        "museum",
        "gallery",
        "aquarium",
        "zoo",
        "theme_park",
    }:
        return category

    if category in {
        "mall",
        "market",
        "shopping",
    }:
        return category

    if category in {
        "park",
        "garden",
        "leisure",
        "entertainment",
    }:
        return category

    return category


# ---------------------------------------------------------------------------
# Normalize one Geoapify feature
# ---------------------------------------------------------------------------

def _normalize_feature(
    feature,
    latitude,
    longitude,
    radius_km,
    category,
):
    properties = feature.get(
        "properties",
        {},
    )

    if not _is_valid_place(
        properties
    ):
        return None

    geometry = feature.get(
        "geometry",
        {},
    )

    coordinates = geometry.get(
        "coordinates",
        [],
    )

    if (
        not isinstance(
            coordinates,
            list,
        )
        or len(coordinates) < 2
    ):
        return None

    place_lon = coordinates[0]
    place_lat = coordinates[1]

    if (
        place_lat is None
        or place_lon is None
    ):
        return None

    try:
        place_lat = float(
            place_lat
        )

        place_lon = float(
            place_lon
        )

    except (
        TypeError,
        ValueError,
    ):
        return None

    name = (
        properties.get("name")
        or properties.get(
            "address_line1"
        )
        or ""
    )

    if not name:
        return None

    distance_km = _haversine_km(
        latitude,
        longitude,
        place_lat,
        place_lon,
    )

    if distance_km > radius_km:
        return None

    categories = properties.get(
        "categories",
        [],
    )

    if not isinstance(
        categories,
        list,
    ):
        categories = []

    result_category = (
        _detect_result_category(
            requested_category=category,
            categories=categories,
        )
    )

    subcategory = (
        _detect_subcategory(
            category=result_category,
            categories=categories,
        )
    )

    return {
        "provider_id": (
            properties.get(
                "place_id"
            )
            or ""
        ),
        "name": name,
        "category": result_category,
        "subcategory": subcategory,
        "latitude": place_lat,
        "longitude": place_lon,
        "address": _build_address(
            properties
        ),
        "type": _get_place_type(
            properties
        ),
        "tags": {
            "geoapify_categories": categories,
            "formatted": properties.get(
                "formatted"
            ),
            "website": properties.get(
                "website"
            ),
            "phone": properties.get(
                "contact:phone"
            ),
            "opening_hours": properties.get(
                "opening_hours"
            ),
            "rating": properties.get(
                "rating"
            ),
        },
        "distance_km": round(
            distance_km,
            3,
        ),
    }


# ---------------------------------------------------------------------------
# Geoapify request
# ---------------------------------------------------------------------------

def _request_geoapify(
    latitude,
    longitude,
    radius_km,
    categories,
    limit,
    api_key,
):
    radius_meters = (
        radius_km * 1000
    )

    params = {
        "filter": (
            f"circle:"
            f"{longitude},"
            f"{latitude},"
            f"{radius_meters}"
        ),
        "bias": (
            f"proximity:"
            f"{longitude},"
            f"{latitude}"
        ),
        "categories": categories,
        "limit": limit,
        "apiKey": api_key,
        "lang": "en",
    }

    try:
        response = requests.get(
            GEOAPIFY_URL,
            params=params,
            headers={
                "User-Agent": (
                    "WorldCompanion/1.0 "
                    "(development project)"
                )
            },
            timeout=20,
        )

        response.raise_for_status()

    except requests.RequestException as exc:
        raise RuntimeError(
            f"Geoapify request failed: {exc}"
        ) from exc

    try:
        return response.json()

    except ValueError as exc:
        raise RuntimeError(
            "Geoapify returned invalid JSON."
        ) from exc


# ---------------------------------------------------------------------------
# Merge and deduplicate
# ---------------------------------------------------------------------------

def _merge_places(
    merged_places,
    places,
):
    for place in places:
        provider_id = place.get(
            "provider_id"
        )

        if provider_id:
            if (
                provider_id
                not in merged_places
            ):
                merged_places[
                    provider_id
                ] = place

            continue

        fallback_key = (
            f"{place['name'].lower()}|"
            f"{place['latitude']:.6f}|"
            f"{place['longitude']:.6f}"
        )

        if (
            fallback_key
            not in merged_places
        ):
            merged_places[
                fallback_key
            ] = place


# ---------------------------------------------------------------------------
# Public provider API — Nearby Search
# ---------------------------------------------------------------------------

def search_nearby(
    latitude,
    longitude,
    radius_km=DEFAULT_RADIUS_KM,
    category=None,
    limit=DEFAULT_LIMIT,
):
    api_key = os.getenv(
        "GEOAPIFY_API_KEY"
    )

    if not api_key:
        raise RuntimeError(
            "GEOAPIFY_API_KEY is not configured."
        )

    try:
        radius_km = float(
            radius_km
        )

    except (
        TypeError,
        ValueError,
    ):
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

    try:
        limit = int(limit)

    except (
        TypeError,
        ValueError,
    ):
        raise ValueError(
            "limit must be a valid integer."
        )

    if limit < 1:
        raise ValueError(
            "limit must be at least 1."
        )

    if limit > MAX_LIMIT:
        limit = MAX_LIMIT

    geoapify_category = (
        _resolve_category(
            category
        )
    )

    # -----------------------------------------------------------------------
    # Explicit category
    # -----------------------------------------------------------------------

    if geoapify_category:
        payload = _request_geoapify(
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
            categories=geoapify_category,
            limit=limit,
            api_key=api_key,
        )

        places = []

        for feature in payload.get(
            "features",
            [],
        ):
            place = _normalize_feature(
                feature=feature,
                latitude=latitude,
                longitude=longitude,
                radius_km=radius_km,
                category=category,
            )

            if place:
                places.append(
                    place
                )

        places.sort(
            key=lambda place: place[
                "distance_km"
            ]
        )

        return places[:limit]

    # -----------------------------------------------------------------------
    # All travel categories
    # -----------------------------------------------------------------------

    merged_places = {}

    for worldcompanion_category in (
        ALL_CATEGORIES
    ):
        geoapify_category = (
            _resolve_category(
                worldcompanion_category
            )
        )

        if not geoapify_category:
            continue

        payload = _request_geoapify(
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
            categories=geoapify_category,
            limit=MAX_LIMIT,
            api_key=api_key,
        )

        category_places = []

        for feature in payload.get(
            "features",
            [],
        ):
            place = _normalize_feature(
                feature=feature,
                latitude=latitude,
                longitude=longitude,
                radius_km=radius_km,
                category=worldcompanion_category,
            )

            if place:
                category_places.append(
                    place
                )

        _merge_places(
            merged_places,
            category_places,
        )

    places = list(
        merged_places.values()
    )

    places.sort(
        key=lambda place: place[
            "distance_km"
        ]
    )

    return places[:limit]


# ---------------------------------------------------------------------------
# Public provider API — Place Details
# ---------------------------------------------------------------------------

def get_place_details(
    place_id
):
    """
    Get detailed information for one Geoapify place.

    The returned structure follows the same WorldCompanion
    category taxonomy used by Nearby Search.
    """

    api_key = os.getenv(
        "GEOAPIFY_API_KEY"
    )

    if not api_key:
        raise RuntimeError(
            "GEOAPIFY_API_KEY is not configured."
        )

    place_id = str(
        place_id or ""
    ).strip()

    if not place_id:
        raise ValueError(
            "place_id is required."
        )

    params = {
        "id": place_id,
        "apiKey": api_key,
        "lang": "en",
    }

    try:
        response = requests.get(
            GEOAPIFY_PLACE_DETAILS_URL,
            params=params,
            headers={
                "User-Agent": (
                    "WorldCompanion/1.0 "
                    "(development project)"
                )
            },
            timeout=20,
        )

        response.raise_for_status()

    except requests.RequestException as exc:
        raise RuntimeError(
            f"Geoapify place details request failed: {exc}"
        ) from exc

    try:
        data = response.json()

    except ValueError as exc:
        raise RuntimeError(
            "Geoapify returned invalid JSON."
        ) from exc

    features = data.get(
        "features",
        [],
    )

    if not features:
        raise RuntimeError(
            "No place details were returned."
        )

    feature = features[0]

    properties = feature.get(
        "properties",
        {},
    )

    geometry = feature.get(
        "geometry",
        {},
    )

    coordinates = geometry.get(
        "coordinates",
        [],
    )

    # -----------------------------------------------------------------------
    # Coordinates
    # -----------------------------------------------------------------------

    latitude = properties.get(
        "lat"
    )

    longitude = properties.get(
        "lon"
    )

    if (
        latitude is None
        and isinstance(
            coordinates,
            list,
        )
        and len(coordinates) >= 2
    ):
        longitude = coordinates[0]
        latitude = coordinates[1]

    # -----------------------------------------------------------------------
    # Categories
    # -----------------------------------------------------------------------

    categories = properties.get(
        "categories",
        [],
    )

    if not isinstance(
        categories,
        list,
    ):
        categories = []

    category = (
        _detect_result_category(
            requested_category=None,
            categories=categories,
        )
    )

    subcategory = (
        _detect_subcategory(
            category=category,
            categories=categories,
        )
    )

    # -----------------------------------------------------------------------
    # Contact information
    # -----------------------------------------------------------------------

    contact = properties.get(
        "contact",
        {},
    )

    if not isinstance(
        contact,
        dict,
    ):
        contact = {}

    phone = (
        contact.get(
            "phone"
        )
        or properties.get(
            "contact:phone"
        )
        or ""
    )

    website = (
        properties.get(
            "website"
        )
        or ""
    )

    opening_hours = (
        properties.get(
            "opening_hours"
        )
        or ""
    )

    # -----------------------------------------------------------------------
    # Rating
    # -----------------------------------------------------------------------

    rating = properties.get(
        "rating"
    )

    # -----------------------------------------------------------------------
    # Return normalized details
    # -----------------------------------------------------------------------

    return {
        "provider_id": place_id,
        "name": properties.get(
            "name",
            "",
        ),
        "description": properties.get(
            "description",
            "",
        ),
        "category": category,
        "subcategory": subcategory,
        "address": _build_address(
            properties
        ),
        "latitude": latitude,
        "longitude": longitude,
        "website": website,
        "phone": phone,
        "opening_hours": opening_hours,
        "rating": rating,
        "type": _get_place_type(
            properties
        ),
        "tags": {
            "geoapify_categories": categories,
            "formatted": properties.get(
                "formatted"
            ),
            "brand": properties.get(
                "brand"
            ),
            "operator": properties.get(
                "operator"
            ),
        },
    }

def geocode_location(place_name):
    api_key = os.getenv("GEOAPIFY_API_KEY")

    if not api_key:
        raise RuntimeError(
            "GEOAPIFY_API_KEY is not configured."
        )

    place_name = str(place_name or "").strip()

    if not place_name:
        return None

    params = {
        "text": place_name,
        "format": "json",
        "limit": 1,
        "apiKey": api_key,
        "lang": "en",
    }

    response = requests.get(
        GEOAPIFY_GEOCODING_URL,
        params=params,
        timeout=20,
    )
    response.raise_for_status()

    data = response.json()

    results = data.get("results", [])

    if not results:
        return None

    result = results[0]

    latitude = result.get("lat")
    longitude = result.get("lon")

    if latitude is None or longitude is None:
        return None

    return {
        "name": result.get(
            "formatted",
            place_name,
        ),
        "latitude": float(latitude),
        "longitude": float(longitude),
        "address": result.get(
            "formatted",
            "",
        ),
    }