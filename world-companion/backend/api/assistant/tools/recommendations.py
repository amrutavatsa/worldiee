import re

from api.models import Place, UserPreference


QUERY_TAG_MAP = {
    "relaxing": {
        "relaxing",
        "nature",
        "park",
        "outdoor",
        "garden",
        "walking",
    },
    "peaceful": {
        "relaxing",
        "nature",
        "park",
        "outdoor",
        "garden",
        "walking",
    },
    "quiet": {
        "relaxing",
        "nature",
        "park",
        "outdoor",
        "garden",
    },
    "nature": {
        "nature",
        "park",
        "outdoor",
        "garden",
        "walking",
    },
    "food": {
        "food",
        "dining",
        "street_food",
    },
    "dinner": {
        "food",
        "dining",
        "street_food",
        "evening",
    },
    "breakfast": {
        "food",
        "dining",
    },
    "lunch": {
        "food",
        "dining",
    },
    "shopping": {
        "shopping",
        "shopping_area",
    },
    "history": {
        "history",
        "landmark",
        "culture",
        "architecture",
    },
    "culture": {
        "culture",
        "landmark",
        "architecture",
    },
    "temple": {
        "temple",
        "spiritual",
        "culture",
        "landmark",
    },
    "evening": {
        "evening",
        "dining",
        "food",
        "social",
    },
    "walking": {
        "walking",
        "nature",
        "park",
        "outdoor",
    },
}


def get_recommendations(user, query=None):
    try:
        pref = UserPreference.objects.get(user=user)
    except UserPreference.DoesNotExist:
        return []

    interests = set(pref.interests or [])

    query_tags = set()

    if query:
        words = re.findall(r"\b[a-z_]+\b", query.lower())

        for word in words:
            query_tags.update(QUERY_TAG_MAP.get(word, set()))

    scored = []

    for place in Place.objects.all():
        place_tags = set(place.tags or [])

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

        scored.append(
            (
                score,
                query_overlap,
                preference_overlap,
                place,
            )
        )

    scored.sort(
        key=lambda x: (
            x[0],
            x[1],
            x[2],
        ),
        reverse=True,
    )

    return [
        {
            "id": place.id,
            "name": place.name,
            "category": place.category,
            "match_score": score,
        }
        for score, _, _, place in scored[:5]
    ]