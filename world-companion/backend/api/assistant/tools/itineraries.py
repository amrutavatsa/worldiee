from api.models import Itinerary


def get_itinerary(user, itinerary_id):
    try:
        itinerary = Itinerary.objects.get(
            id=itinerary_id,
            user=user,
        )
    except Itinerary.DoesNotExist:
        return None

    stops = itinerary.stops.select_related("place").all()

    days = {}

    for stop in stops:
        days.setdefault(stop.day_number, []).append(
            {
                "place": stop.place.name,
                "scheduled_time": stop.scheduled_time,
                "notes": stop.notes,
            }
        )

    return {
        "id": str(itinerary.id),
        "title": itinerary.title,
        "days": days,
    }