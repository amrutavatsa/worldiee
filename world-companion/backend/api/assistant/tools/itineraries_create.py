import uuid

from api.models import Itinerary, ItineraryStop, Place


def create_itinerary(user, title="My Trip", stops=None):
    stops = stops or []

    itinerary = Itinerary.objects.create(
        id=uuid.uuid4(),
        user=user,
        title=title,
    )

    created_stops = []

    for i, stop in enumerate(stops):
        try:
            place = Place.objects.get(id=stop["place_id"])
        except (Place.DoesNotExist, KeyError):
            continue

        itinerary_stop = ItineraryStop.objects.create(
            itinerary=itinerary,
            day_number=stop.get("day_number", 1),
            order=i,
            place=place,
            scheduled_time=stop.get("scheduled_time", ""),
            notes=stop.get("notes", ""),
        )

        created_stops.append(
            {
                "place_id": place.id,
                "place": place.name,
                "day_number": itinerary_stop.day_number,
                "scheduled_time": itinerary_stop.scheduled_time,
                "notes": itinerary_stop.notes,
            }
        )

    return {
        "id": str(itinerary.id),
        "title": itinerary.title,
        "stops": created_stops,
    }