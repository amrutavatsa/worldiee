
import math
import os
import re
from typing import Any, Optional

import requests


GEOAPIFY_URL = "https://api.geoapify.com/v2/places"
GEOAPIFY_PLACE_DETAILS_URL = (
    "https://api.geoapify.com/v2/place-details"
)
GEOAPIFY_GEOCODING_URL = (
    "https://api.geoapify.com/v1/geocode/search"
)
GEOAPIFY_REVERSE_GEOCODING_URL = (
    "https://api.geoapify.com/v1/geocode/reverse"
)

DEFAULT_RADIUS_KM = 10.0
MIN_RADIUS_KM = 1.0
MAX_RADIUS_KM = 15.0
DEFAULT_LIMIT = 20
MAX_LIMIT = 20
FEATURED_DISTRICT_LIMIT = 100
REQUEST_TIMEOUT = 20

_SUBDISTRICT_SUFFIXES = (
    " taluk",
    " taluka",
    " tehsil",
    " tahsil",
    " subdistrict",
    " sub-district",
    " mandal",
)

ADMIN_NAME_ALIASES = {
    "shimoga": "shivamogga",
    "shivamogga": "shivamogga",
    "bengaluru urban": "bengaluru urban",
    "bangalore urban": "bengaluru urban",
}


# ---------------------------------------------------------------------------
# Geoapify configuration and HTTP helpers
# ---------------------------------------------------------------------------

def _get_api_key() -> str:
    api_key = os.getenv("GEOAPIFY_API_KEY", "").strip()

    if not api_key:
        raise RuntimeError(
            "GEOAPIFY_API_KEY is missing. "
            "Set it in your backend environment."
        )

    return api_key


def _get_json(url: str, params: dict) -> dict:
    response = requests.get(
        url,
        params=params,
        timeout=REQUEST_TIMEOUT,
    )
    response.raise_for_status()

    data = response.json()

    if not isinstance(data, dict):
        raise ValueError(
            "The provider returned an invalid JSON response."
        )

    return data


# ---------------------------------------------------------------------------
# Geoapify category configuration
#
# Nearby Places and Featured Destinations use this map, but their defaults
# remain separate:
#
# Nearby Places: missing/unknown category -> "all"
# Featured Destinations: missing/unknown category -> "explore"
#
# Broad parent categories allow Geoapify to return more than landmarks.
# ---------------------------------------------------------------------------

CATEGORY_MAP = {
    "all": ",".join([
        "catering",
        "accommodation",
        "tourism",
        "entertainment",
        "commercial",
        "leisure",
        "sport",
    ]),
    "explore": ",".join([
        "tourism",
        "entertainment",
    ]),
    "food": "catering",
    "restaurants": "catering.restaurant",
    "cafes": "catering.cafe",
    "stays": "accommodation",
    "hotels": "accommodation.hotel,accommodation.motel",
    "shopping": "commercial",
    "leisure": "leisure,sport",
    "parks": "leisure.park,leisure.garden",
}


# ---------------------------------------------------------------------------
# General numeric and geographic helpers
# ---------------------------------------------------------------------------

def _safe_float(value: Any) -> Optional[float]:
    try:
        if value is None or value == "":
            return None

        return float(value)

    except (TypeError, ValueError):
        return None


def _clamp_limit(
    limit: Any,
    maximum: int = MAX_LIMIT,
    default: int = DEFAULT_LIMIT,
) -> int:
    try:
        value = int(limit)
    except (TypeError, ValueError):
        value = default

    return max(1, min(value, maximum))


def _haversine_km(
    latitude_1: float,
    longitude_1: float,
    latitude_2: float,
    longitude_2: float,
) -> float:
    earth_radius_km = 6371.0088

    lat_1 = math.radians(latitude_1)
    lat_2 = math.radians(latitude_2)

    delta_lat = math.radians(latitude_2 - latitude_1)
    delta_lon = math.radians(longitude_2 - longitude_1)

    value = (
        math.sin(delta_lat / 2) ** 2
        + math.cos(lat_1)
        * math.cos(lat_2)
        * math.sin(delta_lon / 2) ** 2
    )

    value = min(1.0, max(0.0, value))

    return earth_radius_km * 2 * math.atan2(
        math.sqrt(value),
        math.sqrt(1 - value),
    )


def _bbox_contains_point(
    bbox: Any,
    latitude: float,
    longitude: float,
) -> Optional[bool]:
    if not isinstance(bbox, dict):
        return None

    lon_1 = _safe_float(bbox.get("lon1"))
    lat_1 = _safe_float(bbox.get("lat1"))
    lon_2 = _safe_float(bbox.get("lon2"))
    lat_2 = _safe_float(bbox.get("lat2"))

    if None in (lon_1, lat_1, lon_2, lat_2):
        return None

    min_lon, max_lon = sorted((lon_1, lon_2))
    min_lat, max_lat = sorted((lat_1, lat_2))

    return (
        min_lon <= longitude <= max_lon
        and min_lat <= latitude <= max_lat
    )


def _feature_properties(feature: dict) -> dict:
    properties = feature.get("properties") or {}

    return properties if isinstance(properties, dict) else {}


def _feature_coordinates(feature: dict) -> tuple:
    properties = _feature_properties(feature)

    latitude = _safe_float(properties.get("lat"))
    longitude = _safe_float(properties.get("lon"))

    if latitude is None or longitude is None:
        geometry = feature.get("geometry") or {}
        coordinates = geometry.get("coordinates") or []

        if len(coordinates) >= 2:
            longitude = _safe_float(coordinates[0])
            latitude = _safe_float(coordinates[1])

    return latitude, longitude


# ---------------------------------------------------------------------------
# Provider category detection
#
# The raw provider category is retained in tags. The gateway converts these
# provider-specific categories to WorldCompanion's UI categories.
# ---------------------------------------------------------------------------

def _detect_result_category(categories: list) -> str:
    normalized = [
        str(item).casefold()
        for item in (categories or [])
        if item
    ]

    category_set = set(normalized)
    combined = " ".join(normalized)

    # Food and dining
    if any(item.startswith("catering.restaurant") for item in category_set):
        return "restaurant"

    if any(item.startswith("catering.cafe") for item in category_set):
        return "cafe"

    if any(item.startswith("catering.fast_food") for item in category_set):
        return "fast_food"

    if any(item.startswith("catering.food_court") for item in category_set):
        return "food_court"

    if any(item.startswith("catering") for item in category_set):
        return "food"

    # Accommodation
    if any(item.startswith("accommodation.hotel") for item in category_set):
        return "hotel"

    if any(item.startswith("accommodation.hostel") for item in category_set):
        return "hostel"

    if any(
        item.startswith("accommodation.guest_house")
        for item in category_set
    ):
        return "guest_house"

    if any(item.startswith("accommodation.motel") for item in category_set):
        return "motel"

    if any(item.startswith("accommodation") for item in category_set):
        return "accommodation"

    # Shopping and retail
    shopping_checks = (
        ("commercial.shopping_mall", "shopping_mall"),
        ("commercial.marketplace", "marketplace"),
        ("commercial.department_store", "department_store"),
        ("commercial.supermarket", "supermarket"),
        ("commercial.convenience", "convenience_store"),
        ("commercial.clothing", "clothing"),
        ("commercial.books", "bookstore"),
        ("commercial.electronics", "electronics"),
    )

    for term, result in shopping_checks:
        if any(item.startswith(term) for item in category_set):
            return result

    if any(item.startswith("commercial") for item in category_set):
        return "shopping"

    # Parks, gardens and recreation
    leisure_checks = (
        ("leisure.park", "park"),
        ("leisure.garden", "garden"),
        ("leisure.playground", "playground"),
        ("leisure.sports_centre", "sports_centre"),
        ("leisure.pitch", "sports_pitch"),
    )

    for term, result in leisure_checks:
        if any(item.startswith(term) for item in category_set):
            return result

    if any(item.startswith("sport") for item in category_set):
        return "sport"

    if any(item.startswith("leisure") for item in category_set):
        return "leisure"

    # Attractions and tourism
    tourism_checks = (
        ("entertainment.museum", "museum"),
        ("entertainment.culture.gallery", "gallery"),
        ("entertainment.aquarium", "aquarium"),
        ("entertainment.zoo", "zoo"),
        ("entertainment.theme_park", "theme_park"),
    )

    for term, result in tourism_checks:
        if any(item.startswith(term) for item in category_set):
            return result

    if any(item.startswith("tourism.attraction") for item in category_set):
        return "attraction"

    if any("tourism.sights" in item for item in category_set):
        return "landmark"

    if any(item.startswith("tourism") for item in category_set):
        return "tourist_place"

    if any(item.startswith("entertainment") for item in category_set):
        return "entertainment"

    # Other useful categories
    if any("healthcare" in item for item in category_set):
        return "healthcare"

    if any("pharmacy" in item for item in category_set):
        return "pharmacy"

    if any("service.financial" in item for item in category_set):
        return "bank"

    if any("vehicle.fuel" in item for item in category_set):
        return "fuel"

    if any("education" in item for item in category_set):
        return "education"

    if any("religion" in item for item in category_set):
        return "religious"

    if any("public_transport" in item for item in category_set):
        return "transport"

    # If the provider returns an unfamiliar taxonomy, preserve it as a
    # generic place. The gateway has the raw category list for classification.
    return "place"


def _detect_subcategory(category: str, categories: list) -> str:
    return category


# ---------------------------------------------------------------------------
# Normalize a Geoapify feature into the provider-independent structure
# ---------------------------------------------------------------------------

def _normalize_feature(
    feature: dict,
    origin_latitude: Optional[float] = None,
    origin_longitude: Optional[float] = None,
    enforce_radius: bool = True,
    radius_km: Optional[float] = None,
) -> Optional[dict]:
    properties = _feature_properties(feature)
    latitude, longitude = _feature_coordinates(feature)

    if latitude is None or longitude is None:
        return None

    distance_km = None

    if origin_latitude is not None and origin_longitude is not None:
        distance_km = _haversine_km(
            origin_latitude,
            origin_longitude,
            latitude,
            longitude,
        )

        if (
            enforce_radius
            and radius_km is not None
            and distance_km > radius_km
        ):
            return None

    categories = properties.get("categories") or []

    if not isinstance(categories, list):
        categories = []

    category = _detect_result_category(categories)

    name = (
        properties.get("name")
        or properties.get("address_line1")
        or properties.get("formatted")
        or "Unnamed place"
    )

    address = (
        properties.get("formatted")
        or properties.get("address_line2")
        or properties.get("address_line1")
        or ""
    )

    datasource = properties.get("datasource") or {}
    if not isinstance(datasource, dict):
        datasource = {}

    raw_datasource = datasource.get("raw") or {}
    if not isinstance(raw_datasource, dict):
        raw_datasource = {}

    tags = {
        "geoapify_categories": categories,
        "formatted": properties.get("formatted", ""),
        "website": properties.get("website", ""),
        "phone": properties.get("phone", ""),
        "opening_hours": properties.get("opening_hours", ""),
        "rating": properties.get("rating"),
        "image": properties.get("image", ""),
        "image_url": properties.get("image_url", ""),
        "photo_url": properties.get("photo_url", ""),
    }

    return {
        "provider_id": (
            properties.get("place_id")
            or raw_datasource.get("osm_id")
            or properties.get("place")
            or ""
        ),
        "name": name,
        "category": category,
        "subcategory": _detect_subcategory(category, categories),
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "type": properties.get("result_type", ""),
        "tags": tags,
        "image": properties.get("image", ""),
        "image_url": properties.get("image_url", ""),
        "photo_url": properties.get("photo_url", ""),
        "distance_km": (
            round(distance_km, 3)
            if distance_km is not None
            else None
        ),
    }


# ---------------------------------------------------------------------------
# Nearby Places
#
# Radius: 1–15 km.
# Default radius: 10 km.
# Maximum results: 20.
#
# A missing or unknown category uses "all", never the Explore-only filter.
# ---------------------------------------------------------------------------

def search_nearby(
    latitude: float,
    longitude: float,
    radius_km: float = DEFAULT_RADIUS_KM,
    category: Optional[str] = None,
    limit: int = DEFAULT_LIMIT,
    **kwargs,
) -> list:
    latitude = _safe_float(latitude)
    longitude = _safe_float(longitude)

    if latitude is None or longitude is None:
        raise ValueError(
            "Valid latitude and longitude are required."
        )

    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        raise ValueError(
            "Latitude or longitude is out of range."
        )

    radius = _safe_float(radius_km)

    if radius is None:
        radius = DEFAULT_RADIUS_KM

    radius = max(
        MIN_RADIUS_KM,
        min(radius, MAX_RADIUS_KM),
    )

    limit = _clamp_limit(
        limit,
        maximum=MAX_LIMIT,
        default=DEFAULT_LIMIT,
    )

    requested_category = str(
        category or "all"
    ).strip().casefold()

    if requested_category not in CATEGORY_MAP:
        requested_category = "all"

    params = {
        "categories": CATEGORY_MAP[requested_category],
        "filter": (
            f"circle:{longitude},{latitude},{int(radius * 1000)}"
        ),
        "bias": f"proximity:{longitude},{latitude}",
        "limit": limit,
        "apiKey": _get_api_key(),
    }

    data = _get_json(GEOAPIFY_URL, params)
    results = []

    for feature in data.get("features") or []:
        place = _normalize_feature(
            feature,
            origin_latitude=latitude,
            origin_longitude=longitude,
            enforce_radius=True,
            radius_km=radius,
        )

        if place:
            results.append(place)

    results.sort(
        key=lambda item: (
            item.get("distance_km")
            if item.get("distance_km") is not None
            else float("inf")
        )
    )

    return results[:limit]


# ---------------------------------------------------------------------------
# Reverse geocoding and administrative-name normalization
# ---------------------------------------------------------------------------

def _clean_admin_name(value: Any) -> str:
    name = str(value or "").strip()
    folded = name.casefold()

    for suffix in _SUBDISTRICT_SUFFIXES:
        if folded.endswith(suffix):
            name = name[:-len(suffix)].strip(" ,-/")
            break

    return name


def _is_subdistrict_name(value: Any) -> bool:
    folded = str(value or "").strip().casefold()

    return any(
        folded.endswith(suffix)
        for suffix in _SUBDISTRICT_SUFFIXES
    )


def _normalized_admin_name(value: Any) -> str:
    name = re.sub(
        r"[^a-z0-9]+",
        " ",
        str(value or "").casefold(),
    ).strip()

    name = re.sub(r"\s+", " ", name)

    return ADMIN_NAME_ALIASES.get(name, name)


def _admin_name_matches(
    result_name: str,
    candidate_name: str,
) -> bool:
    result = _normalized_admin_name(result_name)
    candidate = _normalized_admin_name(candidate_name)

    return bool(result and candidate and result == candidate)


def _looks_like_city_corporation(value: Any) -> bool:
    name = str(value or "").casefold()

    return any(
        term in name
        for term in (
            "city corporation",
            "municipal corporation",
            "municipal council",
            "city municipal council",
            "greater city",
        )
    )


def _canonical_district_name(value: Any) -> str:
    name = _clean_admin_name(value)
    normalized = _normalized_admin_name(name)

    if normalized == "shivamogga":
        return "Shivamogga"

    if normalized == "bengaluru urban":
        return "Bengaluru Urban"

    return name


def reverse_geocode_location(
    latitude: float,
    longitude: float,
) -> dict:
    latitude = _safe_float(latitude)
    longitude = _safe_float(longitude)

    if latitude is None or longitude is None:
        raise ValueError(
            "Valid latitude and longitude are required."
        )

    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        raise ValueError(
            "Latitude or longitude is out of range."
        )

    data = _get_json(
        GEOAPIFY_REVERSE_GEOCODING_URL,
        {
            "lat": latitude,
            "lon": longitude,
            "format": "json",
            "apiKey": _get_api_key(),
        },
    )

    results = data.get("results") or []

    if not results:
        return {
            "district": "",
            "state_district": "",
            "county": "",
            "city": "",
            "state": "",
            "country": "",
            "country_code": "",
            "result_type": "",
            "formatted": "",
        }

    result = results[0]

    raw_district = result.get("district", "")
    county = result.get("county", "")
    state_district = result.get("state_district", "")

    # Reverse geocoding may label a taluk or city corporation as district.
    if (
        _is_subdistrict_name(raw_district)
        or _looks_like_city_corporation(raw_district)
    ):
        district = next(
            (
                value
                for value in (county, state_district)
                if value
                and not _is_subdistrict_name(value)
                and not _looks_like_city_corporation(value)
            ),
            "",
        )
    else:
        district = raw_district

    return {
        "district": _canonical_district_name(district),
        "state_district": _canonical_district_name(state_district),
        "county": _canonical_district_name(county),
        "city": (
            result.get("city")
            or result.get("town")
            or result.get("municipality")
            or ""
        ),
        "state": result.get("state", ""),
        "country": result.get("country", ""),
        "country_code": result.get("country_code", ""),
        "result_type": result.get("result_type", ""),
        "formatted": result.get("formatted", ""),
    }


# ---------------------------------------------------------------------------
# Administrative boundary resolution for Featured Destinations
# ---------------------------------------------------------------------------

def resolve_administrative_place(
    latitude: float,
    longitude: float,
    location: Optional[dict] = None,
    **kwargs,
) -> dict:
    """
    Resolve a verified district-like Geoapify boundary containing the point.

    Smaller administrative units and city corporations are not accepted.
    The candidate must match a reverse-geocoded administrative name and its
    bounding box must contain the requested coordinates.
    """
    latitude = _safe_float(latitude)
    longitude = _safe_float(longitude)

    if latitude is None or longitude is None:
        raise ValueError(
            "Valid latitude and longitude are required."
        )

    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        raise ValueError(
            "Latitude or longitude is out of range."
        )

    if location is None:
        location = reverse_geocode_location(latitude, longitude)

    location = location or {}

    expected_state = str(location.get("state") or "").strip()
    expected_country = str(location.get("country") or "").strip()
    expected_country_code = str(
        location.get("country_code") or ""
    ).strip().casefold()

    raw_candidates = [
        location.get("district"),
        location.get("county"),
        location.get("state_district"),
        location.get("city"),
    ]

    candidates = []
    seen_candidates = set()

    for raw in raw_candidates:
        name = _clean_admin_name(raw)

        if (
            not name
            or _is_subdistrict_name(name)
            or _looks_like_city_corporation(name)
        ):
            continue

        key = _normalized_admin_name(name)

        if key and key not in seen_candidates:
            seen_candidates.add(key)
            candidates.append(name)

    if not candidates:
        raise RuntimeError(
            "Geoapify did not provide a usable district candidate."
        )

    queries = []
    seen_queries = set()

    for name in candidates:
        for query in (f"{name} district", name):
            key = query.casefold()

            if key not in seen_queries:
                seen_queries.add(key)
                queries.append((name, query))

    api_key = _get_api_key()
    matches = []
    provider_errors = []

    for candidate_name, query in queries:
        try:
            data = _get_json(
                GEOAPIFY_GEOCODING_URL,
                {
                    "text": query,
                    "type": "locality",
                    "limit": 10,
                    "bias": f"proximity:{longitude},{latitude}",
                    "format": "json",
                    "apiKey": api_key,
                },
            )
        except (requests.RequestException, ValueError) as exc:
            provider_errors.append(f"{query}: {exc}")
            continue

        for result in data.get("results") or []:
            result_type = str(
                result.get("result_type") or ""
            ).strip().casefold()

            if result_type not in {
                "district",
                "county",
                "state_district",
            }:
                continue

            result_name = str(
                result.get("name")
                or result.get("district")
                or result.get("county")
                or result.get("state_district")
                or ""
            ).strip()

            if (
                not result_name
                or _is_subdistrict_name(result_name)
                or _looks_like_city_corporation(result_name)
            ):
                continue

            if not any(
                _admin_name_matches(result_name, item)
                for item in candidates
            ):
                continue

            result_state = str(
                result.get("state") or ""
            ).strip()

            result_country = str(
                result.get("country") or ""
            ).strip()

            result_country_code = str(
                result.get("country_code") or ""
            ).strip().casefold()

            if (
                expected_state
                and result_state
                and result_state.casefold()
                != expected_state.casefold()
            ):
                continue

            if (
                expected_country
                and result_country
                and result_country.casefold()
                != expected_country.casefold()
            ):
                continue

            if (
                expected_country_code
                and result_country_code
                and result_country_code != expected_country_code
            ):
                continue

            result_lat = _safe_float(result.get("lat"))
            result_lon = _safe_float(result.get("lon"))

            if result_lat is None or result_lon is None:
                continue

            inside_bbox = _bbox_contains_point(
                result.get("bbox"),
                latitude,
                longitude,
            )

            if inside_bbox is not True:
                continue

            distance = _haversine_km(
                latitude,
                longitude,
                result_lat,
                result_lon,
            )

            matches.append({
                "place_id": result.get("place_id"),
                "name": _canonical_district_name(result_name),
                "area_type": result_type,
                "result_type": result_type,
                "distance_km": distance,
                "name_match": _admin_name_matches(
                    result_name,
                    candidate_name,
                ),
            })

    matches = [
        item for item in matches
        if item.get("place_id")
    ]

    if not matches:
        detail = ""

        if provider_errors:
            detail = (
                " Provider errors: "
                + "; ".join(provider_errors)
            )

        raise RuntimeError(
            "Geoapify could not verify a district-level boundary "
            "containing these coordinates. Refusing to substitute "
            "a taluk, city corporation, or unverified boundary."
            + detail
        )

    priority = {
        "district": 0,
        "county": 1,
        "state_district": 2,
    }

    matches.sort(
        key=lambda item: (
            priority.get(item["result_type"], 99),
            not item["name_match"],
            item["distance_km"],
        )
    )

    best = matches[0]

    return {
        "place_id": best["place_id"],
        "name": best["name"],
        "area_type": best["area_type"],
        "result_type": best["result_type"],
    }


# ---------------------------------------------------------------------------
# Search within an administrative place
#
# This remains separate from Nearby Places. Its default is still "explore".
# ---------------------------------------------------------------------------

def search_within_place(
    place_id: str,
    category: str = "explore",
    limit: int = FEATURED_DISTRICT_LIMIT,
    **kwargs,
) -> list:
    place_id = str(place_id or "").strip()

    if not place_id:
        raise ValueError(
            "A Geoapify place_id is required."
        )

    limit = _clamp_limit(
        limit,
        maximum=FEATURED_DISTRICT_LIMIT,
        default=FEATURED_DISTRICT_LIMIT,
    )

    requested_category = str(
        category or "explore"
    ).strip().casefold()

    # Keep Featured Destinations' previous Explore fallback.
    if requested_category not in CATEGORY_MAP:
        requested_category = "explore"

    data = _get_json(
        GEOAPIFY_URL,
        {
            "categories": CATEGORY_MAP[requested_category],
            "filter": f"place:{place_id}",
            "limit": limit,
            "apiKey": _get_api_key(),
        },
    )

    results = []

    for feature in data.get("features") or []:
        place = _normalize_feature(
            feature,
            enforce_radius=False,
        )

        if place:
            results.append(place)

    return results[:limit]


# ---------------------------------------------------------------------------
# Forward geocoding
# ---------------------------------------------------------------------------

def geocode_location(
    query: str,
    bias_latitude: Optional[float] = None,
    bias_longitude: Optional[float] = None,
    **kwargs,
) -> Optional[dict]:
    query = str(query or "").strip()

    if not query:
        return None

    params = {
        "text": query,
        "limit": 1,
        "format": "json",
        "apiKey": _get_api_key(),
    }

    bias_latitude = _safe_float(bias_latitude)
    bias_longitude = _safe_float(bias_longitude)

    if (
        bias_latitude is not None
        and bias_longitude is not None
    ):
        params["bias"] = (
            f"proximity:{bias_longitude},{bias_latitude}"
        )

    results = _get_json(
        GEOAPIFY_GEOCODING_URL,
        params,
    ).get("results") or []

    if not results:
        return None

    result = results[0]

    return {
        "latitude": _safe_float(result.get("lat")),
        "longitude": _safe_float(result.get("lon")),
        "name": result.get("name", ""),
        "formatted": result.get("formatted", ""),
        "result_type": result.get("result_type", ""),
        "place_id": result.get("place_id", ""),
        "state": result.get("state", ""),
        "country": result.get("country", ""),
    }


# ---------------------------------------------------------------------------
# Place details
# ---------------------------------------------------------------------------

def get_place_details(
    place_id: str,
    **kwargs,
) -> Optional[dict]:
    place_id = str(place_id or "").strip()

    if not place_id:
        return None

    data = _get_json(
        GEOAPIFY_PLACE_DETAILS_URL,
        {
            "id": place_id,
            "apiKey": _get_api_key(),
        },
    )

    features = data.get("features") or []

    if features:
        return _normalize_feature(
            features[0],
            enforce_radius=False,
        )

    properties = data.get("properties")

    if properties:
        return _normalize_feature(
            {
                "type": "Feature",
                "properties": properties,
                "geometry": data.get("geometry", {}),
            },
            enforce_radius=False,
        )

    return None
