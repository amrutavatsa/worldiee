from math import asin, cos, radians, sin, sqrt

from api.models import Place


EARTH_RADIUS_KM = 6371.0


def _distance_km(
    latitude_1,
    longitude_1,
    latitude_2,
    longitude_2,
):
    lat1 = radians(latitude_1)
    lat2 = radians(latitude_2)

    delta_lat = radians(latitude_2 - latitude_1)
    delta_lon = radians(longitude_2 - longitude_1)

    a = (
        sin(delta_lat / 2) ** 2
        + cos(lat1)
        * cos(lat2)
        * sin(delta_lon / 2) ** 2
    )

    return 2 * EARTH_RADIUS_KM * asin(sqrt(a))


def get_nearby_places(
    latitude,
    longitude,
    radius_km=10,
    category=None,
):
    qs = Place.objects.all()

    if category:
        qs = qs.filter(category=category)

    places = []

    for place in qs:
        distance = _distance_km(
            latitude,
            longitude,
            place.latitude,
            place.longitude,
        )

        if distance <= radius_km:
            places.append(
                {
                    "id": place.id,
                    "name": place.name,
                    "category": place.category,
                    "latitude": place.latitude,
                    "longitude": place.longitude,
                    "distance_km": round(distance, 2),
                    "tags": place.tags,
                }
            )

    places.sort(key=lambda place: place["distance_km"])

    return places