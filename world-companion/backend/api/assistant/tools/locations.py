from places.geoapify_provider import geocode_location


def resolve_location(place_name):
    if not place_name:
        return None

    location = geocode_location(place_name)

    if not location:
        return None

    return {
        "name": location["name"],
        "latitude": location["latitude"],
        "longitude": location["longitude"],
        "address": location.get("address", ""),
    }