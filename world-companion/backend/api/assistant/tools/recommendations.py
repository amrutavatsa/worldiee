import re

from api.models import Place, UserPreference
from places.gateway import search_nearby
from places.geoapify_provider import geocode_location


QUERY_TAG_MAP = {
    "relaxing": {"relaxing", "nature", "park", "outdoor", "garden", "walking"},
    "peaceful": {"relaxing", "nature", "park", "outdoor", "garden", "walking"},
    "quiet": {"relaxing", "nature", "park", "outdoor", "garden"},
    "nature": {"nature", "park", "outdoor", "garden", "walking"},
    "food": {"food", "dining", "street_food"},
    "eat": {"food", "dining", "street_food"},
    "restaurant": {"food", "dining"},
    "dinner": {"food", "dining", "street_food", "evening"},
    "breakfast": {"food", "dining"},
    "lunch": {"food", "dining"},
    "shopping": {"shopping", "shopping_area"},
    "history": {"history", "landmark", "culture", "architecture"},
    "historical": {"history", "landmark", "culture", "architecture"},
    "culture": {"culture", "landmark", "architecture"},
    "temple": {"temple", "spiritual", "culture", "landmark"},
    "evening": {"evening", "dining", "food", "social"},
    "walking": {"walking", "nature", "park", "outdoor"},
    "family": {"family", "kid_friendly", "safe"},
    "kids": {"family", "kid_friendly", "safe"},
    "children": {"family", "kid_friendly", "safe"},
    "romantic": {"romantic", "couples", "dining", "evening"},
    "adventure": {"adventure", "outdoor", "nature"},
}


LOCATION_WORDS = {
    "in",
    "at",
    "near",
    "around",
    "within",
    "from",
}


def _extract_query_tags(query):
    if not query:
        return set()

    words = re.findall(r"\b[a-z_]+\b", str(query).lower())

    query_tags = set()

    for word in words:
        query_tags.update(
            QUERY_TAG_MAP.get(word, set())
        )

    return query_tags


def _extract_location(query):
    """
    Extract a likely location phrase from a natural-language
    recommendation request.

    Examples:
        "peaceful places in Shivamogga"
        -> "Shivamogga"

        "something relaxing near Mysore"
        -> "Mysore"
    """
    if not query:
        return None

    text = str(query).strip()

    pattern = (
        r"\b(?:in|at|near|around|within|from)\s+"
        r"([A-Za-z][A-Za-z\s.-]{1,80})"
        r"$"
    )

    match = re.search(
        pattern,
        text,
        re.IGNORECASE,
    )

    if not match:
        return None

    location = match.group(1).strip(
        " .,!?;:"
    )

    return location or None


def _calculate_match_score(
    place,
    interests,
    query_tags,
):
    place_tags = set(
        place.tags or []
    )

    preference_overlap = len(
        interests.intersection(place_tags)
    )

    query_overlap = len(
        query_tags.intersection(place_tags)
    )

    score = (
        preference_overlap
        + (query_overlap * 2)
    )

    return (
        score,
        query_overlap,
        preference_overlap,
    )


def _calculate_real_world_score(
    place,
    interests,
    query_tags,
):
    tags = set(
        place.get("tags", {}).keys()
        if isinstance(place.get("tags"), dict)
        else place.get("tags", [])
    )

    category = str(
        place.get("category", "")
    ).lower()

    subcategory = str(
        place.get("subcategory", "")
    ).lower()

    searchable_tags = (
        tags
        | {category}
        | {subcategory}
    )

    preference_overlap = len(
        interests.intersection(searchable_tags)
    )

    query_overlap = len(
        query_tags.intersection(searchable_tags)
    )

    score = (
        preference_overlap
        + (query_overlap * 2)
    )

    return (
        score,
        query_overlap,
        preference_overlap,
    )


def _get_internal_recommendations(
    interests,
    query_tags,
):
    scored = []

    for place in Place.objects.all():
        (
            score,
            query_overlap,
            preference_overlap,
        ) = _calculate_match_score(
            place=place,
            interests=interests,
            query_tags=query_tags,
        )

        scored.append(
            (
                score,
                query_overlap,
                preference_overlap,
                place,
            )
        )

    scored.sort(
        key=lambda item: (
            item[0],
            item[1],
            item[2],
        ),
        reverse=True,
    )

    recommendations = []

    for (
        score,
        query_overlap,
        preference_overlap,
        place,
    ) in scored[:5]:
        recommendations.append({
            "id": place.id,
            "name": place.name,
            "category": place.category,
            "match_score": score,
            "query_match": query_overlap > 0,
            "preference_match": preference_overlap > 0,
            "source": "worldcompanion",
        })

    return recommendations


def _get_real_world_recommendations(
    location,
    interests,
    query_tags,
):
    resolved_location = geocode_location(
        location
    )

    if not resolved_location:
        return []

    places = search_nearby(
        latitude=resolved_location["latitude"],
        longitude=resolved_location["longitude"],
        radius_km=10.0,
        category=None,
    )

    scored = []

    for place in places:
        (
            score,
            query_overlap,
            preference_overlap,
        ) = _calculate_real_world_score(
            place=place,
            interests=interests,
            query_tags=query_tags,
        )

        scored.append(
            (
                score,
                query_overlap,
                preference_overlap,
                place,
            )
        )

    scored.sort(
        key=lambda item: (
            item[0],
            item[1],
            item[2],
            -float(
                item[3].get(
                    "distance_km",
                    999999,
                )
                or 999999
            ),
        ),
        reverse=True,
    )

    recommendations = []

    for (
        score,
        query_overlap,
        preference_overlap,
        place,
    ) in scored[:5]:
        recommendations.append({
            "id": place.get("id"),
            "name": place.get("name"),
            "category": place.get("category"),
            "subcategory": place.get("subcategory"),
            "latitude": place.get("latitude"),
            "longitude": place.get("longitude"),
            "address": place.get("address", ""),
            "distance_km": place.get(
                "distance_km",
                0.0,
            ),
            "match_score": score,
            "query_match": query_overlap > 0,
            "preference_match": preference_overlap > 0,
            "source": "real_world",
        })

    return recommendations


def get_recommendations(
    user,
    query=None,
):
    try:
        pref = UserPreference.objects.get(
            user=user
        )
    except UserPreference.DoesNotExist:
        pref = None

    interests = set(
        pref.interests or []
    ) if pref else set()

    query_tags = _extract_query_tags(
        query
    )

    location = _extract_location(
        query
    )

    # If the user explicitly mentions a city,
    # use real-world places for that location.
    if location:
        return _get_real_world_recommendations(
            location=location,
            interests=interests,
            query_tags=query_tags,
        )

    # Otherwise use the existing WorldCompanion
    # personalized place database.
    return _get_internal_recommendations(
        interests=interests,
        query_tags=query_tags,
    )
