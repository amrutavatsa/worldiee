"""
views_phase2.py — Phase 2 feature endpoints, built on top of the Phase 1
Place/routing/intent foundation.

Endpoints:
  GET  /api/places/<id>/info/          — AI place & food info
  GET  /api/places/nearby/             — nearby places discovery (filterable)
  GET  /api/reviews/<target_type>/<target_id>/   — list reviews
  POST /api/reviews/                   — submit a review
  GET  /api/hotels/                    — search hotels
  POST /api/bookings/                  — simulated booking
  GET  /api/bookings/<session>/        — booking history for a session
  POST /api/emergency-contacts/        — add emergency contact
  GET  /api/emergency-contacts/<session>/  — list contacts
  POST /api/sos/trigger/               — start SOS countdown
  POST /api/sos/<id>/activate/         — confirm SOS activation
  POST /api/sos/<id>/resolve/          — "I'm safe" — end SOS
  POST /api/itinerary/create/          — create a day-wise itinerary
  GET  /api/itinerary/<id>/            — fetch itinerary
  POST /api/preferences/               — save user preferences
  GET  /api/recommendations/<session>/ — rule-based recommendations
"""

import json
import uuid
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.utils import timezone

from api.models import (
    Place, PlaceInfo, Hotel, Booking, Review,
    EmergencyContact, SOSEvent, Itinerary, ItineraryStop, UserPreference,
)


def _json_body(request):
    try:
        return json.loads(request.body), None
    except json.JSONDecodeError:
        return None, JsonResponse({"error": "invalid JSON body"}, status=400)


# ---------- AI Place & Food Information ----------

def place_info_view(request, place_id):
    try:
        place = Place.objects.get(id=place_id)
    except Place.DoesNotExist:
        return JsonResponse({"error": "place not found"}, status=404)

    snippets = list(place.info_snippets.values("topic", "content"))
    return JsonResponse({
        "success": True,
        "data": {
            "place": place.name,
            "category": place.category,
            "info": snippets if snippets else [
                {"topic": "general", "content": f"{place.name} is a {place.category} in Bengaluru. More details coming soon."}
            ],
        },
    })


def nearby_places_view(request):
    category = request.GET.get("category")
    qs = Place.objects.all()
    if category:
        qs = qs.filter(category=category)
    data = list(qs.values("id", "name", "category", "latitude", "longitude", "tags"))
    return JsonResponse({"success": True, "data": data})


# ---------- Reviews & Ratings ----------

def reviews_list_view(request, target_type, target_id):
    reviews = Review.objects.filter(target_type=target_type, target_id=target_id)
    avg = sum(r.rating for r in reviews) / reviews.count() if reviews.count() else None
    data = [{"author": r.author_name, "rating": r.rating, "comment": r.comment,
             "created_at": r.created_at.isoformat()} for r in reviews]
    return JsonResponse({"success": True, "data": {"average_rating": avg, "count": reviews.count(), "reviews": data}})


@csrf_exempt
def reviews_create_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    body, err = _json_body(request)
    if err:
        return err
    try:
        review = Review.objects.create(
            id=uuid.uuid4(),
            target_type=body["target_type"],
            target_id=body["target_id"],
            author_name=body.get("author_name", "Anonymous"),
            rating=int(body["rating"]),
            comment=body.get("comment", ""),
        )
    except (KeyError, ValueError) as e:
        return JsonResponse({"error": f"missing/invalid field: {e}"}, status=400)
    return JsonResponse({"success": True, "data": {"id": str(review.id)}})


# ---------- Hotels & Simulated Booking ----------

def hotels_search_view(request):
    area = request.GET.get("area")
    max_price = request.GET.get("max_price")
    qs = Hotel.objects.all()
    if area:
        qs = qs.filter(area__icontains=area)
    if max_price:
        qs = qs.filter(price_per_night__lte=max_price)
    data = list(qs.values("id", "name", "area", "price_per_night", "rating", "facilities", "room_types"))
    return JsonResponse({"success": True, "data": data})


@csrf_exempt
def booking_create_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    body, err = _json_body(request)
    if err:
        return err
    try:
        hotel = Hotel.objects.get(id=body["hotel_id"])
        booking = Booking.objects.create(
            id=uuid.uuid4(),
            hotel=hotel,
            guest_name=body["guest_name"],
            room_type=body["room_type"],
            check_in=body["check_in"],
            check_out=body["check_out"],
            status="confirmed",
        )
    except Hotel.DoesNotExist:
        return JsonResponse({"error": "hotel not found"}, status=404)
    except KeyError as e:
        return JsonResponse({"error": f"missing field: {e}"}, status=400)
    return JsonResponse({"success": True, "data": {
        "booking_id": str(booking.id), "status": booking.status,
        "hotel": hotel.name, "note": "This is a simulated booking — no payment was processed.",
    }})


def booking_history_view(request, session):
    bookings = Booking.objects.filter(guest_name=session)  # simplified: session used as guest identifier
    data = [{"id": str(b.id), "hotel": b.hotel.name, "room_type": b.room_type,
             "check_in": str(b.check_in), "check_out": str(b.check_out), "status": b.status} for b in bookings]
    return JsonResponse({"success": True, "data": data})


# ---------- Emergency Contacts & SOS ----------

@csrf_exempt
def emergency_contact_create_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    body, err = _json_body(request)
    if err:
        return err
    try:
        contact = EmergencyContact.objects.create(
            id=uuid.uuid4(),
            owner_session=body["session"],
            name=body["name"],
            phone=body["phone"],
            relationship=body.get("relationship", ""),
        )
    except KeyError as e:
        return JsonResponse({"error": f"missing field: {e}"}, status=400)
    return JsonResponse({"success": True, "data": {"id": str(contact.id)}})


def emergency_contact_list_view(request, session):
    contacts = EmergencyContact.objects.filter(owner_session=session)
    data = [{"id": str(c.id), "name": c.name, "phone": c.phone, "relationship": c.relationship} for c in contacts]
    return JsonResponse({"success": True, "data": data})


@csrf_exempt
def sos_trigger_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    body, err = _json_body(request)
    if err:
        return err
    event = SOSEvent.objects.create(
        id=uuid.uuid4(),
        owner_session=body.get("session", "anonymous"),
        status="countdown",
        latitude=body.get("latitude"),
        longitude=body.get("longitude"),
    )
    return JsonResponse({"success": True, "data": {"id": str(event.id), "status": event.status}})


@csrf_exempt
def sos_activate_view(request, event_id):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    try:
        event = SOSEvent.objects.get(id=event_id)
    except SOSEvent.DoesNotExist:
        return JsonResponse({"error": "SOS event not found"}, status=404)

    contacts = EmergencyContact.objects.filter(owner_session=event.owner_session)
    event.status = "active"
    event.notified_contacts = [str(c.id) for c in contacts]
    event.save()
    return JsonResponse({
        "success": True,
        "data": {
            "id": str(event.id), "status": event.status,
            "notified": [c.name for c in contacts],
            "note": "Simulated notification — no real SMS/call was sent in this phase.",
        },
    })


@csrf_exempt
def sos_resolve_view(request, event_id):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    try:
        event = SOSEvent.objects.get(id=event_id)
    except SOSEvent.DoesNotExist:
        return JsonResponse({"error": "SOS event not found"}, status=404)
    event.status = "resolved"
    event.resolved_at = timezone.now()
    event.save()
    return JsonResponse({"success": True, "data": {"id": str(event.id), "status": event.status}})


# ---------- Smart Itinerary Planning ----------

@csrf_exempt
def itinerary_create_view(request):
    """Body: { session, title, stops: [{ day_number, place_id, scheduled_time, notes }] } """
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    body, err = _json_body(request)
    if err:
        return err
    itinerary = Itinerary.objects.create(
        id=uuid.uuid4(),
        owner_session=body.get("session", "anonymous"),
        title=body.get("title", "My Trip"),
    )
    for i, stop in enumerate(body.get("stops", [])):
        try:
            place = Place.objects.get(id=stop["place_id"])
        except Place.DoesNotExist:
            continue
        ItineraryStop.objects.create(
            itinerary=itinerary, day_number=stop.get("day_number", 1), order=i,
            place=place, scheduled_time=stop.get("scheduled_time", ""), notes=stop.get("notes", ""),
        )
    return JsonResponse({"success": True, "data": {"id": str(itinerary.id)}})


def itinerary_detail_view(request, itinerary_id):
    try:
        itinerary = Itinerary.objects.get(id=itinerary_id)
    except Itinerary.DoesNotExist:
        return JsonResponse({"error": "itinerary not found"}, status=404)
    stops = itinerary.stops.select_related("place").all()
    days = {}
    for s in stops:
        days.setdefault(s.day_number, []).append({
            "place": s.place.name, "scheduled_time": s.scheduled_time, "notes": s.notes,
        })
    return JsonResponse({"success": True, "data": {"title": itinerary.title, "days": days}})


# ---------- Preferences & Rule-Based Recommendations ----------

@csrf_exempt
def preferences_save_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    body, err = _json_body(request)
    if err:
        return err
    pref, _ = UserPreference.objects.update_or_create(
        owner_session=body.get("session", "anonymous"),
        defaults={
            "interests": body.get("interests", []),
            "budget": body.get("budget", "mid-range"),
            "travel_style": body.get("travel_style", ""),
        },
    )
    return JsonResponse({"success": True, "data": {"session": pref.owner_session}})


def recommendations_view(request, session):
    """Rule-based recommendation: score each Place by tag overlap with the
    user's stated interests. This is intentionally NOT collaborative
    filtering — see PRD/paper Phase 2 note: real CF needs interaction data
    this phase doesn't have yet."""
    try:
        pref = UserPreference.objects.get(owner_session=session)
    except UserPreference.DoesNotExist:
        return JsonResponse({"success": True, "data": [], "note": "No preferences saved yet for this session."})

    interests = set(pref.interests)
    scored = []
    for place in Place.objects.all():
        overlap = len(interests.intersection(set(place.tags)))
        scored.append((overlap, place))
    scored.sort(key=lambda x: x[0], reverse=True)
    top = [{"id": p.id, "name": p.name, "category": p.category, "match_score": score}
           for score, p in scored[:5]]
    return JsonResponse({"success": True, "data": top})
