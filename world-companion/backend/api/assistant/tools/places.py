from places.gateway import search_nearby
from places.geoapify_provider import geocode_location


def search_places(
    query=None,
    category=None,
    radius_km=10,
):
    query = str(query or "").strip()

    if not query:
        return []

    location = geocode_location(query)

    if not location:
        return []

    places = search_nearby(
        latitude=location["latitude"],
        longitude=location["longitude"],
        radius_km=radius_km,
        category=category,
    )

    return places