from places.gateway import search_nearby


def get_nearby_places(
    latitude,
    longitude,
    radius_km=10,
    category=None,
):
    return search_nearby(
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        category=category,
    )