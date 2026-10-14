from places.geoapify_provider import (
    search_nearby as geoapify_search_nearby,
)


def search_nearby(
    latitude,
    longitude,
    radius_km=10.0,
    category=None,
):
    """Provider-independent nearby places search."""
    places = geoapify_search_nearby(
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        category=category,
    )

    normalized = []
    seen = set()

    for place in places or []:
        if not isinstance(place, dict):
            continue

        normalized_place = _normalize_place(place)
        if normalized_place is None:
            continue

        provider_id = str(normalized_place.get("id") or "").strip()
        if provider_id:
            key = ("id", provider_id)
        else:
            key = (
                "location",
                normalized_place["name"].casefold(),
                normalized_place.get("latitude"),
                normalized_place.get("longitude"),
            )

        if key in seen:
            continue

        seen.add(key)
        normalized.append(normalized_place)

    return normalized


def _normalize_place(place):
    """Convert a provider result into WorldCompanion's place format."""
    name = str(place.get("name") or "").strip()
    if not name:
        return None

    tags = place.get("tags") or {}
    if not isinstance(tags, dict):
        tags = {}

    category = _normalize_category(
        category=place.get("category"),
        place_type=place.get("type"),
        tags=tags,
    )

    if _is_obvious_noise(
        name=name,
        category=category,
        place_type=place.get("type"),
    ):
        return None

    return {
        "id": place.get("provider_id") or place.get("id"),
        "name": name,
        "category": category,
        "subcategory": _normalize_subcategory(
            category=category,
            place_type=place.get("type"),
            tags=tags,
        ),
        "latitude": place.get("latitude"),
        "longitude": place.get("longitude"),
        "address": place.get("address") or "",
        "type": place.get("type") or "place",
        "tags": tags,
        "distance_km": place.get("distance_km", 0.0),
    }


def _normalize_category(category, place_type, tags):
    """Map Geoapify categories to WorldCompanion discovery categories."""
    category_text = str(category or "").casefold().strip()
    type_text = str(place_type or "").casefold().strip()

    geo_categories = tags.get("geoapify_categories", [])
    if not isinstance(geo_categories, list):
        geo_categories = []

    combined = " ".join(
        [category_text, type_text]
        + [str(value).casefold() for value in geo_categories]
    )

    # Food and dining.
    if any(term in combined for term in (
        "catering",
        "restaurant",
        "fast_food",
        "food_court",
        "food_stand",
        "ice_cream",
        "biergarten",
        "cafe",
        "pub",
    )):
        return "food"

    # Accommodation.
    if any(term in combined for term in (
        "accommodation",
        "hotel",
        "hostel",
        "motel",
        "guest_house",
        "guesthouse",
        "resort",
    )):
        return "stays"

    # Shopping and retail, including everyday shopping.
    if any(term in combined for term in (
        "commercial",
        "shopping",
        "supermarket",
        "convenience",
        "department_store",
        "shopping_mall",
        "marketplace",
        "clothing",
        "books",
        "electronics",
        "gift",
        "florist",
        "hardware",
    )):
        return "shopping"

    # Parks, gardens, playgrounds, sports and recreation.
    if any(term in combined for term in (
        "leisure",
        "sport",
        "park",
        "garden",
        "playground",
        "sports_centre",
        "sports_centre",
        "stadium",
        "fitness",
        "recreation",
    )):
        return "leisure"

    # Attractions and places to explore.
    if any(term in combined for term in (
        "tourism",
        "entertainment",
        "museum",
        "gallery",
        "aquarium",
        "zoo",
        "theme_park",
        "viewpoint",
        "attraction",
        "historic",
        "heritage",
        "monument",
        "castle",
    )):
        return "explore"

    # Keep useful service categories separate from travel discovery.
    if "healthcare" in combined:
        return "healthcare"

    if "pharmacy" in combined:
        return "pharmacy"

    if any(term in combined for term in (
        "service.financial",
        "financial",
        "bank",
    )):
        return "bank"

    if any(term in combined for term in (
        "vehicle.fuel",
        "service.vehicle.fuel",
        "fuel",
        "petrol",
    )):
        return "fuel"

    if "education" in combined or "school" in combined or "university" in combined:
        return "education"

    if any(term in combined for term in (
        "religion",
        "place_of_worship",
        "church",
        "temple",
        "mosque",
    )):
        return "religious"

    if "public_transport" in combined or "transport" in combined:
        return "transport"

    # Do not silently drop new provider categories.
    return "explore"


def _normalize_subcategory(category, place_type, tags):
    """Produce a more specific label for display and icons."""
    type_text = str(place_type or "").casefold()

    geo_categories = tags.get("geoapify_categories", [])
    if not isinstance(geo_categories, list):
        geo_categories = []

    combined = " ".join(
        [type_text] + [str(value).casefold() for value in geo_categories]
    )

    if category == "food":
        for term, label in (
            ("restaurant", "restaurant"),
            ("fast_food", "fast_food"),
            ("food_court", "food_court"),
            ("ice_cream", "ice_cream"),
            ("food_stand", "food_stand"),
            ("biergarten", "biergarten"),
            ("cafe", "cafe"),
            ("pub", "pub"),
            ("bar", "bar"),
        ):
            if term in combined:
                return label
        return "food"

    if category == "stays":
        for term in (
            "hotel",
            "hostel",
            "guest_house",
            "guesthouse",
            "motel",
            "resort",
            "camp_site",
        ):
            if term in combined:
                return term
        return "accommodation"

    if category == "shopping":
        for term, label in (
            ("shopping_mall", "mall"),
            ("marketplace", "market"),
            ("department_store", "department_store"),
            ("supermarket", "supermarket"),
            ("convenience", "convenience_store"),
            ("clothing", "clothing"),
            ("books", "bookstore"),
            ("electronics", "electronics"),
            ("florist", "florist"),
            ("hardware", "hardware"),
        ):
            if term in combined:
                return label
        return "shopping"

    if category == "leisure":
        for term in (
            "playground",
            "sports_centre",
            "park",
            "garden",
            "pitch",
            "stadium",
            "fitness",
            "recreation",
        ):
            if term in combined:
                return term
        return "leisure"

    if category == "explore":
        for term in (
            "museum",
            "gallery",
            "aquarium",
            "zoo",
            "theme_park",
            "viewpoint",
            "attraction",
            "historic",
            "heritage",
            "monument",
            "tourism.sights",
        ):
            if term in combined:
                return term.replace("tourism.", "")
        return "attraction"

    return category


def _is_obvious_noise(name, category, place_type):
    """Reject only high-confidence provider mistakes."""
    normalized_name = " ".join(str(name).casefold().split())
    normalized_type = str(place_type or "").casefold()

    if category == "stays" and normalized_name in {"nh69", "nh 69"}:
        return True

    if category == "leisure":
        if normalized_type == "leisure.park" and normalized_name in {
            "shivamogga - 577200",
            "shivamogga 577200",
        }:
            return True

        if normalized_type == "leisure.playground":
            if (
                " road" in f" {normalized_name}"
                or normalized_name.endswith("road")
            ):
                return True

    return False
