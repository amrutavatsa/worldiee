from api.models import Place


def resolve_location(place_name):
    if not place_name:
        return None

    place = (
        Place.objects
        .filter(name__icontains=place_name)
        .first()
    )

    if not place:
        return None

    return {
        "id": place.id,
        "name": place.name,
        "latitude": place.latitude,
        "longitude": place.longitude,
    }