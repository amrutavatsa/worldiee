from places.geoapify_provider import (
    search_nearby as geoapify_search_nearby,
)


def search_nearby(
    latitude,
    longitude,
    radius_km=10.0,
    category=None,
):
    """
    Provider-independent entry point for nearby places.

    WorldCompanion uses Geoapify as the current provider,
    but the rest of the application does not depend on
    Geoapify's response format.
    """

    places = geoapify_search_nearby(
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        category=category,
    )

    normalized = []

    for place in places:
        normalized_place = _normalize_place(place)

        if normalized_place is None:
            continue

        normalized.append(normalized_place)

    return normalized


def _normalize_place(place):
    """
    Convert one provider result into the
    WorldCompanion place format.
    """

    name = str(place.get("name", "")).strip()

    if not name:
        return None

    category = _normalize_category(
        category=place.get("category"),
        place_type=place.get("type"),
        tags=place.get("tags", {}),
    )

    if category is None:
        return None

    if _is_obvious_noise(
        name=name,
        category=category,
        place_type=place.get("type"),
    ):
        return None

    subcategory = _normalize_subcategory(
        category=category,
        place_type=place.get("type"),
        tags=place.get("tags", {}),
    )

    return {
        "id": place.get("provider_id"),
        "name": name,
        "category": category,
        "subcategory": subcategory,
        "latitude": place.get("latitude"),
        "longitude": place.get("longitude"),
        "address": place.get("address", ""),
        "type": place.get("type", "place"),
        "tags": place.get("tags", {}),
        "distance_km": place.get("distance_km", 0.0),
    }


def _normalize_category(
    category,
    place_type,
    tags,
):
    """
    Convert provider-specific categories into
    WorldCompanion's five travel categories.

    Utilities remain supported but are kept separate
    from the primary travel categories.
    """

    category_text = str(category or "").lower().strip()
    type_text = str(place_type or "").lower().strip()

    geoapify_categories = tags.get(
        "geoapify_categories",
        [],
    )

    if not isinstance(geoapify_categories, list):
        geoapify_categories = []

    geo_text = " ".join(
        str(value).lower()
        for value in geoapify_categories
    )

    combined = " ".join(
        [
            category_text,
            type_text,
            geo_text,
        ]
    )

    # -------------------------
    # FOOD & DINING
    # -------------------------

    if (
        "catering.restaurant" in combined
        or "catering.cafe" in combined
        or "catering.bar" in combined
        or "catering.pub" in combined
        or "catering.biergarten" in combined
        or "catering.fast_food" in combined
        or "catering.food_court" in combined
        or "catering" == category_text
    ):
        return "food"

    # -------------------------
    # STAYS
    # -------------------------

    if (
        "accommodation" in combined
        or "accommodation.hotel" in combined
        or "accommodation.hostel" in combined
        or "accommodation.guest_house" in combined
    ):
        return "stays"

    # -------------------------
    # EXPLORE
    # -------------------------

    if (
        "tourism" in combined
        or "entertainment.museum" in combined
        or "entertainment.culture" in combined
        or "entertainment.aquarium" in combined
        or "entertainment.zoo" in combined
        or "entertainment.theme_park" in combined
    ):
        return "explore"

    # -------------------------
    # SHOPPING
    # -------------------------

    if (
        "commercial.shopping_mall" in combined
        or "commercial.marketplace" in combined
        or "commercial.department_store" in combined
        or "commercial" == category_text
        or "shopping" in combined
    ):
        return "shopping"

    # -------------------------
    # LEISURE
    # -------------------------

    if (
        "leisure" in combined
        or "entertainment" in combined
    ):
        return "leisure"

    # -------------------------
    # UTILITIES
    # -------------------------

    if "healthcare" in combined:
        return "healthcare"

    if "pharmacy" in combined:
        return "pharmacy"

    if (
        "service.financial" in combined
        or "financial" in combined
        or "bank" == category_text
    ):
        return "bank"

    if (
        "vehicle.fuel" in combined
        or "service.vehicle.fuel" in combined
        or "fuel" == category_text
    ):
        return "fuel"

    if "education" in combined:
        return "education"

    if (
        "religion" in combined
        or "place_of_worship" in combined
    ):
        return "religious"

    if (
        "public_transport" in combined
        or "transport" in combined
    ):
        return "transport"

    # Unknown provider result.
    return None


def _normalize_subcategory(
    category,
    place_type,
    tags,
):
    """
    Produce a useful travel-facing subcategory.
    """

    type_text = str(place_type or "").lower()

    geoapify_categories = tags.get(
        "geoapify_categories",
        [],
    )

    if not isinstance(geoapify_categories, list):
        geoapify_categories = []

    geo_text = " ".join(
        str(value).lower()
        for value in geoapify_categories
    )

    combined = f"{type_text} {geo_text}"

    if category == "food":
        if "restaurant" in combined:
            return "restaurant"

        if "cafe" in combined:
            return "cafe"

        if "bar" in combined:
            return "bar"

        if "pub" in combined:
            return "pub"

        if "biergarten" in combined:
            return "biergarten"

        if "fast_food" in combined:
            return "fast_food"

        if "food_court" in combined:
            return "food_court"

        return "food"

    if category == "stays":
        if "hotel" in combined:
            return "hotel"

        if "hostel" in combined:
            return "hostel"

        if "guest_house" in combined:
            return "guest_house"

        if "resort" in combined:
            return "resort"

        return "accommodation"

    if category == "explore":
        if "museum" in combined:
            return "museum"

        if "zoo" in combined:
            return "zoo"

        if "aquarium" in combined:
            return "aquarium"

        if "theme_park" in combined:
            return "theme_park"

        if "viewpoint" in combined:
            return "viewpoint"

        if "attraction" in combined:
            return "attraction"

        if "tourism" in combined:
            return "attraction"

        return "explore"

    if category == "shopping":
        if "shopping_mall" in combined:
            return "mall"

        if "marketplace" in combined:
            return "market"

        if "department_store" in combined:
            return "department_store"

        return "shopping"

    if category == "leisure":
        if "park" in combined:
            return "park"

        if "garden" in combined:
            return "garden"

        if "cinema" in combined:
            return "cinema"

        if "playground" in combined:
            return "playground"

        return "leisure"

    return category


def _is_obvious_noise(
    name,
    category,
    place_type,
):
    """
    Remove only high-confidence provider mistakes.

    We intentionally DO NOT reject names merely because
    they contain words such as Road, Nagar, Market, etc.
    """

    normalized_name = " ".join(
        name.lower().split()
    )

    normalized_type = str(
        place_type or ""
    ).lower()

    # Provider occasionally returns a road/highway as
    # accommodation or catering.
    if category == "stays":
        if normalized_name in {
            "nh69",
            "nh 69",
        }:
            return True

    # Provider occasionally returns a locality/postal
    # area as a park.
    if category == "leisure":
        if normalized_type == "leisure.park":
            if normalized_name in {
                "shivamogga - 577200",
                "shivamogga 577200",
            }:
                return True

    # A road should not become a leisure destination merely
    # because the provider attached leisure.playground to it.
    if category == "leisure":
        if normalized_type == "leisure.playground":
            if (
                " road" in f" {normalized_name}"
                or normalized_name.endswith("road")
            ):
                return True

    return False