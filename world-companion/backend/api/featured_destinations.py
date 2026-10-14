
import html
import logging
import re
from urllib.parse import urlparse

import requests
from django.core.cache import cache
from django.http import JsonResponse
from django.views.decorators.http import require_GET

from places.geoapify_provider import (
    reverse_geocode_location,
    resolve_administrative_place,
    search_within_place,
)

logger = logging.getLogger(__name__)

MAX_FEATURED_DESTINATIONS = 4
FEATURED_SEARCH_LIMIT = 100
LOCATION_CACHE_SECONDS = 60 * 60 * 24
DESTINATIONS_CACHE_SECONDS = 60 * 30
IMAGE_CACHE_SECONDS = 60 * 60 * 24
FEATURED_CACHE_VERSION = "v6"

WIKIMEDIA_API_URL = "https://commons.wikimedia.org/w/api.php"
WIKIMEDIA_TIMEOUT = 8
WIKIMEDIA_USER_AGENT = (
    "WorldCompanion/1.0 (destination image lookup; "
    "contact: worldcompanion project)"
)

# These are generic category images, not verified photos of a place.
CATEGORY_FALLBACK_IMAGES = {
    "attraction": (
        "https://images.unsplash.com/photo-1501785888041-af3ef285b470"
        "?w=900&auto=format&fit=crop&q=85"
    ),
    "viewpoint": (
        "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b"
        "?w=900&auto=format&fit=crop&q=85"
    ),
    "landmark": (
        "https://images.unsplash.com/photo-1519491050282-cf00c82424b4"
        "?w=900&auto=format&fit=crop&q=85"
    ),
    "museum": (
        "https://images.unsplash.com/photo-1519491050282-cf00c82424b4"
        "?w=900&auto=format&fit=crop&q=85"
    ),
    "gallery": (
        "https://images.unsplash.com/photo-1513364776144-60967b0f800f"
        "?w=900&auto=format&fit=crop&q=85"
    ),
    "park": (
        "https://images.unsplash.com/photo-1441974231531-c6227db76b6e"
        "?w=900&auto=format&fit=crop&q=85"
    ),
    "garden": (
        "https://images.unsplash.com/photo-1441974231531-c6227db76b6e"
        "?w=900&auto=format&fit=crop&q=85"
    ),
    "zoo": (
        "https://images.unsplash.com/photo-1516026672322-bc52d61a55d5"
        "?w=900&auto=format&fit=crop&q=85"
    ),
    "aquarium": (
        "https://images.unsplash.com/photo-1544551763-46a013bb70d5"
        "?w=900&auto=format&fit=crop&q=85"
    ),
    "theme_park": (
        "https://images.unsplash.com/photo-1513883049090-d0b7439799bf"
        "?w=900&auto=format&fit=crop&q=85"
    ),
    "tourist_place": (
        "https://images.unsplash.com/photo-1501785888041-af3ef285b470"
        "?w=900&auto=format&fit=crop&q=85"
    ),
}
DEFAULT_FALLBACK_IMAGE = CATEGORY_FALLBACK_IMAGES["attraction"]

ALLOWED_CATEGORIES = {
    "attraction", "viewpoint", "landmark", "tourist_place", "museum",
    "gallery", "zoo", "aquarium", "theme_park", "park", "garden",
}

HIGH_VALUE_TERMS = {
    "palace", "safari", "elephant camp", "wildlife sanctuary",
    "national park", "wildlife park", "tiger reserve", "waterfall",
    "falls", "fort", "heritage site", "archaeological site",
    "heritage village", "historical site", "historic site", "zoo",
    "aquarium", "theme park", "botanical garden", "bird sanctuary",
    "bird park", "viewpoint", "observation tower", "hill station",
    "lake", "dam", "cave", "museum", "art gallery", "gallery",
    "temple", "monastery", "church", "mosque", "cathedral",
    "national monument", "garden", "park",
}

LOW_VALUE_EXACT_NAMES = {
    "founder's circle", "founders circle", "founder circle",
    "ambedkar statue", "lion statue", "lion statue 1", "lion statue 2",
}

LOW_VALUE_NAME_PATTERNS = (
    r"\btraffic circle\b",
    r"\broundabout\b",
    r"\broad junction\b",
    r"\broadside landmark\b",
    r"\b(?:lion|ambedkar)\s+statue(?:\s+\d+)?\b",
    r"\bstatue\s+of\s+(?:a\s+)?lion\b",
)

ROAD_TERMS = {
    "road", "street", "cross road", "main road", "highway",
    "lane", "junction", "bus stop", "parking", "parking lot",
}

CATEGORY_PRIORITIES = {
    "attraction": 0,
    "viewpoint": 1,
    "landmark": 2,
    "tourist_place": 3,
    "zoo": 4,
    "aquarium": 5,
    "theme_park": 6,
    "park": 7,
    "garden": 8,
    "museum": 9,
    "gallery": 10,
}

# These words add little value when comparing a Commons filename to a place.
IMAGE_STOPWORDS = {
    "the", "and", "of", "at", "in", "on", "for", "to",
    "india", "karnataka", "district", "city", "place",
    "view", "viewpoint", "tourism", "tourist", "destination",
    "photo", "image", "img", "file", "commons",
    "park", "garden", "museum", "gallery", "attraction",
    "falls", "waterfall", "dam", "lake", "temple",
}


def _clean_text(value):
    return "" if value is None else str(value).strip()


def _normalized_name(value):
    value = _clean_text(value).casefold()
    value = re.sub(r"[^a-z0-9]+", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def _location_metadata(latitude, longitude):
    # Version the key so stale reverse-geocoding results don't survive
    # the district-normalization changes.
    cache_key = f"wc_featured_location_v2_{latitude:.3f}_{longitude:.3f}"
    cached = cache.get(cache_key)
    if cached is not None:
        return cached

    location = reverse_geocode_location(latitude, longitude) or {}
    if location:
        cache.set(cache_key, location, LOCATION_CACHE_SECONDS)
    return location


def _subtitle_for_place(place):
    category = _clean_text(place.get("category"))
    subcategory = _clean_text(place.get("subcategory"))
    address = _clean_text(place.get("address"))
    label = (subcategory or category or "Destination").replace("_", " ").title()
    return f"{label} · {address}" if address else label


def _safe_image_url(value):
    """Accept only direct HTTP(S) URLs; reject Markdown and malformed URLs."""
    value = _clean_text(value)
    if not value:
        return ""

    markdown_match = re.fullmatch(
        r"!? \[([^\]]*)\]\((https?://[^)\s]+)\)".replace(" ", ""),
        value,
        flags=re.IGNORECASE,
    )
    if markdown_match:
        value = markdown_match.group(2).strip()

    if value.startswith("<") and value.endswith(">"):
        value = value[1:-1].strip()

    if "[" in value or "](" in value or ")" in value:
        return ""

    try:
        parsed = urlparse(value)
    except ValueError:
        return ""

    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        return ""

    return value


def _fallback_image(category):
    return CATEGORY_FALLBACK_IMAGES.get(category, DEFAULT_FALLBACK_IMAGE)


def _strip_metadata_html(value):
    value = html.unescape(_clean_text(value))
    value = re.sub(r"<br\s*/?>", " ", value, flags=re.IGNORECASE)
    value = re.sub(r"<[^>]+>", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def _image_search_tokens(value):
    tokens = _normalized_name(value).split()
    return {
        token for token in tokens
        if len(token) >= 3 and token not in IMAGE_STOPWORDS
    }


def _commons_candidate_score(destination_name, file_title):
    """
    Score filename relevance rather than blindly using the first Commons hit.
    The filename is not proof that the photo depicts the destination, so weak
    matches are rejected and the source page is returned for verification.
    """
    wanted = _image_search_tokens(destination_name)
    title = _image_search_tokens(file_title)

    if not wanted or not title:
        return 0.0

    overlap = wanted.intersection(title)
    if not overlap:
        return 0.0

    coverage = len(overlap) / len(wanted)
    precision = len(overlap) / len(title)
    return (coverage * 0.75) + (precision * 0.25)


def _commons_search(query):
    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": query,
        "gsrnamespace": 6,
        "gsrlimit": 10,
        "prop": "imageinfo",
        "iiprop": "url|extmetadata",
        "iiurlwidth": 900,
    }

    response = requests.get(
        WIKIMEDIA_API_URL,
        params=params,
        timeout=WIKIMEDIA_TIMEOUT,
        headers={"User-Agent": WIKIMEDIA_USER_AGENT},
    )
    response.raise_for_status()
    payload = response.json()

    if not isinstance(payload, dict):
        return []

    pages = (payload.get("query") or {}).get("pages") or {}
    results = []

    for page in pages.values():
        title = _clean_text(page.get("title"))
        if not title:
            continue

        lowered_title = title.casefold()
        if lowered_title.endswith((".svg", ".pdf", ".djvu", ".ogg", ".ogv")):
            continue

        imageinfo_list = page.get("imageinfo") or []
        if not imageinfo_list:
            continue

        info = imageinfo_list[0]
        image_url = _safe_image_url(info.get("thumburl") or info.get("url"))
        source_url = _safe_image_url(info.get("descriptionurl"))

        if not image_url or not source_url:
            continue

        metadata = info.get("extmetadata") or {}

        def metadata_value(key):
            item = metadata.get(key) or {}
            return _strip_metadata_html(item.get("value"))

        results.append({
            "title": title,
            "image": image_url,
            "image_source_url": source_url,
            "image_attribution": (
                metadata_value("Attribution")
                or metadata_value("Credit")
                or metadata_value("Artist")
            ),
            "image_license": metadata_value("LicenseShortName"),
            "image_license_url": _safe_image_url(
                metadata_value("LicenseUrl")
            ),
        })

    return results


def _commons_photo_for_destination(name, address):
    """
    Find a Commons image with a relevant filename and preserve attribution.

    Commons search results are best-effort matches, not a guarantee that a
    photograph depicts the exact destination. Weak filename matches are
    rejected instead of being presented as verified destination photos.
    """
    name = _clean_text(name)
    address = _clean_text(address)

    if not name:
        return None

    cache_key = f"wc_featured_image_v2_{_normalized_name(name)}"
    cached = cache.get(cache_key)
    if cached is not None:
        return cached or None

    # Avoid using a long street address as part of the query: it often
    # suppresses relevant image results. Use the destination and its region.
    queries = [
        f'"{name}" Karnataka India',
        f'"{name}"',
    ]

    all_candidates = []
    seen_urls = set()

    for query in queries:
        try:
            results = _commons_search(query)
        except (requests.RequestException, ValueError) as exc:
            logger.info(
                "Wikimedia Commons lookup failed for %s: %s", name, exc
            )
            continue

        for candidate in results:
            if candidate["image"] in seen_urls:
                continue
            seen_urls.add(candidate["image"])

            candidate["relevance"] = _commons_candidate_score(
                name, candidate["title"]
            )
            all_candidates.append(candidate)

        # Stop once this query has produced a reasonably strong match.
        if any(item["relevance"] >= 0.55 for item in all_candidates):
            break

    # Require meaningful filename overlap. This avoids assigning an unrelated
    # landscape image simply because Commons returned it first.
    all_candidates = [
        item for item in all_candidates
        if item["relevance"] >= 0.30
    ]
    all_candidates.sort(
        key=lambda item: item["relevance"],
        reverse=True,
    )

    if not all_candidates:
        cache.set(cache_key, {}, IMAGE_CACHE_SECONDS)
        return None

    best = all_candidates[0]
    result = {
        "image": best["image"],
        "image_source_url": best["image_source_url"],
        "image_attribution": best["image_attribution"],
        "image_license": best["image_license"],
        "image_license_url": best["image_license_url"],
        "image_is_fallback": False,
    }

    cache.set(cache_key, result, IMAGE_CACHE_SECONDS)
    return result


def _image_for_place(place, category):
    """Prefer a direct provider image; otherwise use a marked fallback."""
    tags = place.get("tags") if isinstance(place.get("tags"), dict) else {}

    for candidate in (
        place.get("image"),
        place.get("image_url"),
        place.get("photo_url"),
        tags.get("image"),
        tags.get("image_url"),
        tags.get("photo_url"),
    ):
        image_url = _safe_image_url(candidate)
        if image_url:
            return {
                "image": image_url,
                "image_is_fallback": False,
                "image_source_url": "",
                "image_attribution": "",
                "image_license": "",
                "image_license_url": "",
            }

    return {
        "image": _fallback_image(category),
        "image_is_fallback": True,
        "image_source_url": "",
        "image_attribution": "",
        "image_license": "",
        "image_license_url": "",
    }


def _normalize_destination(place):
    if not isinstance(place, dict):
        return None

    name = _clean_text(place.get("name"))
    if not name:
        return None

    try:
        latitude = float(place["latitude"])
        longitude = float(place["longitude"])
    except (KeyError, TypeError, ValueError):
        return None

    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        return None

    try:
        distance_value = place.get("distance_km")
        distance_km = (
            round(float(distance_value), 3)
            if distance_value is not None else None
        )
        if distance_km is not None and distance_km < 0:
            distance_km = None
    except (TypeError, ValueError):
        distance_km = None

    category = _clean_text(place.get("category")).casefold()
    image_info = _image_for_place(place, category)

    return {
        "id": _clean_text(place.get("provider_id")),
        "name": name,
        "subtitle": _subtitle_for_place(place),
        **image_info,
        "latitude": latitude,
        "longitude": longitude,
        "category": category,
        "address": _clean_text(place.get("address")),
        "distance_km": distance_km,
    }


def _is_worth_featuring(destination):
    category = _clean_text(destination.get("category")).casefold()
    if category not in ALLOWED_CATEGORIES:
        return False

    name = _normalized_name(destination.get("name"))
    if not name:
        return False

    low_value_names = {
        _normalized_name(item) for item in LOW_VALUE_EXACT_NAMES
    }
    if name in low_value_names:
        return False

    if any(re.search(pattern, name) for pattern in LOW_VALUE_NAME_PATTERNS):
        return False

    if name in ROAD_TERMS or any(
        name.endswith(" " + term) for term in ROAD_TERMS
    ):
        return False

    if "statue" in name:
        if "statue of unity" not in name and "liberty statue" not in name:
            return False

    if name in {"circle", "gate", "pillar", "fountain", "monument", "sculpture"}:
        return False

    return True


def _destination_priority(destination):
    name = _normalized_name(destination.get("name"))
    category = _clean_text(destination.get("category")).casefold()
    high_value_score = sum(1 for term in HIGH_VALUE_TERMS if term in name)

    distance = destination.get("distance_km")
    if distance is None:
        distance = float("inf")

    return (
        -high_value_score,
        CATEGORY_PRIORITIES.get(category, 99),
        distance,
        name,
    )


def _unique_destinations(places):
    candidates = []
    seen_ids = set()
    seen_names = set()
    seen_coordinates = set()

    for place in places:
        destination = _normalize_destination(place)
        if not destination or not _is_worth_featuring(destination):
            continue

        provider_id = destination.get("id")
        name_key = _normalized_name(destination["name"])
        coordinate_key = (
            round(destination["latitude"], 4),
            round(destination["longitude"], 4),
        )

        if provider_id and provider_id in seen_ids:
            continue
        if name_key in seen_names or coordinate_key in seen_coordinates:
            continue

        if provider_id:
            seen_ids.add(provider_id)
        seen_names.add(name_key)
        seen_coordinates.add(coordinate_key)
        candidates.append(destination)

    candidates.sort(key=_destination_priority)
    return candidates


def _select_diverse_destinations(candidates):
    remaining = list(candidates)
    selected = []
    selected_categories = set()

    while remaining and len(selected) < MAX_FEATURED_DESTINATIONS:
        remaining.sort(
            key=lambda item: (
                item.get("category") in selected_categories,
                *_destination_priority(item),
            )
        )
        destination = remaining.pop(0)
        selected.append(destination)
        selected_categories.add(destination.get("category"))

    return selected


def _attach_destination_photo(destination):
    """Enrich only selected cards, not every candidate in the district."""
    if not destination.get("image_is_fallback"):
        return destination

    photo = _commons_photo_for_destination(
        destination.get("name", ""),
        destination.get("address", ""),
    )
    if photo:
        destination.update(photo)

    return destination


def _display_district(location, search_area):
    """
    Prefer the verified administrative search area over a reverse-geocoder
    district label that may actually be a city corporation or taluk.
    """
    name = _clean_text((search_area or {}).get("name"))
    area_type = _clean_text((search_area or {}).get("area_type")).casefold()

    if area_type in {"district", "county", "state_district"} and name:
        normalized = _normalized_name(name)
        if normalized in {"shimoga", "shivamogga"}:
            return "Shivamogga"
        if normalized in {"bengaluru urban", "bangalore urban"}:
            return "Bengaluru Urban"
        return name

    district = _clean_text((location or {}).get("district"))
    normalized = _normalized_name(district)

    if normalized in {"shimoga", "shivamogga"}:
        return "Shivamogga"
    if normalized in {"bengaluru urban", "bangalore urban"}:
        return "Bengaluru Urban"

    # Don't expose a known smaller administrative unit as a district.
    if re.search(
        r"\b(taluk|taluka|tehsil|tahsil|subdistrict|sub-district|mandal)\b",
        district,
        flags=re.IGNORECASE,
    ):
        return ""

    if "city corporation" in district.casefold():
        return ""

    return district


def _get_featured_destinations(latitude, longitude, location):
    area = resolve_administrative_place(
        latitude=latitude,
        longitude=longitude,
        location=location,
    )

    place_id = area["place_id"]
    cache_key = f"wc_featured_places_{FEATURED_CACHE_VERSION}_{place_id}"

    cached_destinations = cache.get(cache_key)
    if cached_destinations is not None:
        return cached_destinations, area

    combined_places = []
    seen_provider_records = set()

    for search_category in ("explore", "parks"):
        try:
            places = search_within_place(
                latitude=latitude,
                longitude=longitude,
                place_id=place_id,
                category=search_category,
                limit=FEATURED_SEARCH_LIMIT,
            ) or []
        except Exception:
            logger.exception(
                "Featured Destinations search failed for category %s",
                search_category,
            )
            continue

        for place in places:
            if not isinstance(place, dict):
                continue

            provider_id = _clean_text(place.get("provider_id"))
            if provider_id:
                dedupe_key = ("id", provider_id)
            else:
                try:
                    place_latitude = round(
                        float(place.get("latitude") or 0), 4
                    )
                    place_longitude = round(
                        float(place.get("longitude") or 0), 4
                    )
                except (TypeError, ValueError):
                    place_latitude = place_longitude = 0

                dedupe_key = (
                    "name",
                    _normalized_name(place.get("name")),
                    place_latitude,
                    place_longitude,
                )

            if dedupe_key in seen_provider_records:
                continue

            seen_provider_records.add(dedupe_key)
            combined_places.append(place)

    candidates = _unique_destinations(combined_places)
    destinations = _select_diverse_destinations(candidates)

    for destination in destinations:
        try:
            _attach_destination_photo(destination)
        except Exception:
            logger.exception(
                "Could not enrich Featured Destination image for %s",
                destination.get("name"),
            )

    cache.set(cache_key, destinations, DESTINATIONS_CACHE_SECONDS)
    return destinations, area


@require_GET
def featured_destinations_view(request):
    try:
        latitude = float(request.GET.get("lat", ""))
        longitude = float(request.GET.get("lon", ""))
    except (TypeError, ValueError):
        return JsonResponse(
            {
                "success": False,
                "error": "Valid lat and lon are required.",
                "destinations": [],
            },
            status=400,
        )

    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        return JsonResponse(
            {
                "success": False,
                "error": "Coordinates are out of range.",
                "destinations": [],
            },
            status=400,
        )

    try:
        location = _location_metadata(latitude, longitude)
    except Exception:
        logger.exception("Featured Destinations reverse geocoding failed.")
        location = {}

    try:
        destinations, search_area = _get_featured_destinations(
            latitude, longitude, location
        )
    except Exception:
        logger.exception(
            "Featured Destinations administrative-area search failed."
        )
        return JsonResponse(
            {
                "success": False,
                "error": (
                    "Could not verify and search the district boundary for "
                    "Featured Destinations. Please try again."
                ),
                "district": _clean_text(location.get("district")),
                "city": _clean_text(location.get("city")),
                "state": _clean_text(location.get("state")),
                "country": _clean_text(location.get("country")),
                "destinations": [],
            },
            status=502,
        )

    return JsonResponse(
        {
            "success": True,
            "district": _display_district(location, search_area),
            "city": _clean_text(location.get("city")),
            "state": _clean_text(location.get("state")),
            "country": _clean_text(location.get("country")),
            "search_area": {
                "name": search_area.get("name", ""),
                "type": search_area.get("area_type", ""),
                "provider_result_type": search_area.get("result_type", ""),
            },
            "destinations": destinations,
        }
    )
