from api.models import Hotel

from places.gateway import search_nearby
from places.geoapify_provider import geocode_location


def _search_internal_hotels(area=None, max_price=None):
    qs = Hotel.objects.all()

    if area:
        qs = qs.filter(area__icontains=area)

    if max_price is not None:
        qs = qs.filter(price_per_night__lte=max_price)

    hotels = []

    for hotel in qs:
        hotels.append(
            {
                "id": hotel.id,
                "name": hotel.name,
                "area": hotel.area,
                "latitude": hotel.latitude,
                "longitude": hotel.longitude,
                "price_per_night": float(
                    hotel.price_per_night
                ),
                "rating": hotel.rating,
                "facilities": hotel.facilities or [],
                "room_types": hotel.room_types or [],
                "source": "worldcompanion",
                "booking_available": True,
                "price_verified": True,
            }
        )

    return hotels


def _search_real_world_hotels(area=None):
    if not area:
        return []

    location = geocode_location(area)

    if not location:
        return []

    places = search_nearby(
        latitude=location["latitude"],
        longitude=location["longitude"],
        radius_km=10.0,
        category="hotel",
    )

    hotels = []

    for place in places:
        category = str(
            place.get("category", "")
        ).lower()

        subcategory = str(
            place.get("subcategory", "")
        ).lower()

        if category not in {
            "hotel",
            "hostel",
            "guest_house",
            "stay",
        } and subcategory not in {
            "hotel",
            "hostel",
            "guest_house",
            "stay",
        }:
            continue

        hotels.append(
            {
                "id": place.get("id"),
                "name": place.get("name"),
                "area": area,
                "latitude": place.get("latitude"),
                "longitude": place.get("longitude"),
                "address": place.get("address", ""),
                "category": category,
                "subcategory": subcategory,
                "distance_km": place.get(
                    "distance_km",
                    0.0,
                ),
                "source": "real_world",
                "booking_available": False,
                "price_verified": False,
                "price_per_night": None,
                "rating": None,
                "facilities": [],
                "room_types": [],
            }
        )

    hotels.sort(
        key=lambda hotel: float(
            hotel.get("distance_km", 999999)
            or 999999
        )
    )

    return hotels[:10]


def search_hotels(area=None, max_price=None):
    """
    Search accommodation for the assistant.

    Internal WorldCompanion hotels provide verified simulated
    pricing and support simulated booking.

    When a specific area is supplied, real-world accommodation
    is also discovered through the Places Gateway.

    Real-world accommodation pricing is not fabricated because
    the current provider search does not provide a verified
    nightly rate.
    """

    area = str(area or "").strip()

    if max_price is not None:
        try:
            max_price = float(max_price)
        except (TypeError, ValueError):
            max_price = None

    internal_hotels = _search_internal_hotels(
        area=area,
        max_price=max_price,
    )

    real_world_hotels = _search_real_world_hotels(
        area=area,
    )

    results = internal_hotels + real_world_hotels

    return {
        "area": area or None,
        "max_price": max_price,
        "results": results,
        "internal_count": len(internal_hotels),
        "real_world_count": len(real_world_hotels),
        "price_note": (
            "Internal WorldCompanion hotels have verified "
            "simulated prices. Real-world accommodation "
            "results do not include a verified nightly price "
            "from the current provider."
        ),
    }