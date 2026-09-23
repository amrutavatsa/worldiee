from api.models import Place


def get_place_details(place_id):
    try:
        place = Place.objects.get(id=place_id)
    except Place.DoesNotExist:
        return None

    snippets = list(
        place.info_snippets.values(
            "topic",
            "content",
        )
    )

    if not snippets:
        snippets = [
            {
                "topic": "general",
                "content": (
                    f"{place.name} is a {place.category} "
                    "in Bengaluru. More details coming soon."
                ),
            }
        ]

    return {
        "place": place.name,
        "category": place.category,
        "info": snippets,
    }
