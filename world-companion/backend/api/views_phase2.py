"""
views_phase2.py — Phase 2 feature endpoints, built on top of the Phase 1
Place/routing/intent foundation.

Endpoints:
  GET  /api/places/<id>/info/          — AI place & food info
  GET  /api/places/nearby/             — nearby places discovery
  POST /api/routes/real-world/         — real-world road routing
  GET  /api/reviews/<target_type>/<target_id>/   — list reviews
  POST /api/reviews/                   — submit a review
  GET  /api/hotels/                    — search hotels
  POST /api/bookings/                  — simulated booking
  GET  /api/bookings/history/          — booking history
  POST /api/emergency-contacts/        — add emergency contact
  GET  /api/emergency-contacts/list/   — list contacts
  POST /api/sos/trigger/               — start SOS countdown
  POST /api/sos/<id>/activate/         — confirm SOS activation
  POST /api/sos/<id>/resolve/          — "I'm safe" — end SOS
  POST /api/itinerary/create/          — create a day-wise itinerary
  GET  /api/itinerary/                 — list itineraries
  GET  /api/itinerary/<id>/            — fetch itinerary
  POST /api/preferences/               — save user preferences
  GET  /api/recommendations/           — rule-based recommendations
"""

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

import json
import uuid

from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.utils import timezone

from api.models import (
    Place,
    PlaceInfo,
    Hotel,
    Booking,
    Review,
    EmergencyContact,
    SOSEvent,
    Itinerary,
    ItineraryStop,
    UserPreference,
)

from places.gateway import search_nearby
from places.routing_provider import get_real_world_route
from places.geoapify_provider import get_place_details
from api.assistant.service import AssistantService


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _json_body(request):
    try:
        return json.loads(request.body), None

    except json.JSONDecodeError:
        return None, JsonResponse(
            {"error": "invalid JSON body"},
            status=400,
        )


# ---------------------------------------------------------------------------
# AI Place & Food Information
# ---------------------------------------------------------------------------

def place_info_view(request, place_id):
    """
    Return place information.

    Supports two types of places:

    1. WorldCompanion curated places stored in the local Place model.
    2. Real-world Geoapify places returned by Nearby Search.

    The local database is checked first.

    If the place does not exist locally, the provider is queried
    using the Geoapify place ID.
    """

    # -----------------------------------------------------------------------
    # 1. Try WorldCompanion local place
    # -----------------------------------------------------------------------

    try:
        place = Place.objects.get(id=place_id)

        snippets = list(
            place.info_snippets.values(
                "topic",
                "content",
            )
        )

        return JsonResponse(
            {
                "success": True,
                "data": {
                    "source": "worldcompanion",
                    "place": place.name,
                    "category": place.category,
                    "info": snippets if snippets else [
                        {
                            "topic": "general",
                            "content": (
                                f"{place.name} is a "
                                f"{place.category} in Bengaluru. "
                                "More details coming soon."
                            ),
                        }
                    ],
                },
            }
        )

    except Place.DoesNotExist:
        pass

    # -----------------------------------------------------------------------
    # 2. Try real-world provider place
    # -----------------------------------------------------------------------

    try:
        details = get_place_details(place_id)

    except Exception:
        return JsonResponse(
            {
                "success": False,
                "error": "place not found",
            },
            status=404,
        )

    if not details:
        return JsonResponse(
            {
                "success": False,
                "error": "place not found",
            },
            status=404,
        )

    # -----------------------------------------------------------------------
    # Normalize provider response
    # -----------------------------------------------------------------------

    name = (
        details.get("name")
        or "Unknown place"
    )

    category = (
        details.get("category")
        or details.get("type")
        or "place"
    )

    address = details.get(
        "address",
        "",
    )

    website = details.get(
        "website",
    )

    phone = details.get(
        "phone",
    )

    opening_hours = details.get(
        "opening_hours",
    )

    rating = details.get(
        "rating",
    )

    tags = details.get(
        "tags",
        {},
    )

    if not isinstance(tags, dict):
        tags = {}

    categories = tags.get(
        "geoapify_categories",
        [],
    )

    if not isinstance(categories, list):
        categories = []

    # -----------------------------------------------------------------------
    # Build useful information blocks
    # -----------------------------------------------------------------------

    info = []

    if address:
        info.append(
            {
                "topic": "address",
                "content": address,
            }
        )

    if category:
        info.append(
            {
                "topic": "category",
                "content": str(category).replace(
                    "_",
                    " ",
                ),
            }
        )

    if opening_hours:
        info.append(
            {
                "topic": "opening_hours",
                "content": str(opening_hours),
            }
        )

    if rating is not None:
        info.append(
            {
                "topic": "rating",
                "content": (
                    f"Provider rating: {rating}/5"
                ),
            }
        )

    if phone:
        info.append(
            {
                "topic": "contact",
                "content": str(phone),
            }
        )

    if website:
        info.append(
            {
                "topic": "website",
                "content": str(website),
            }
        )

    if categories:
        readable_categories = []

        for value in categories:
            readable = str(value).replace(
                ".",
                " → ",
            ).replace(
                "_",
                " ",
            )

            readable_categories.append(
                readable
            )

        info.append(
            {
                "topic": "provider_categories",
                "content": ", ".join(
                    readable_categories
                ),
            }
        )

    # -----------------------------------------------------------------------
    # General AI-ready context
    #
    # This is intentionally structured so the upcoming
    # AI Place Intelligence milestone can consume it.
    # -----------------------------------------------------------------------

    general_content = (
        f"{name} is a real-world place "
        f"available through WorldCompanion's "
        f"place discovery system."
    )

    if address:
        general_content += (
            f" It is located at {address}."
        )

    if category:
        general_content += (
            f" The place is categorized as "
            f"{str(category).replace('_', ' ')}."
        )

    info.insert(
        0,
        {
            "topic": "general",
            "content": general_content,
        },
    )

    # -----------------------------------------------------------------------
    # Final response
    # -----------------------------------------------------------------------

    return JsonResponse(
        {
            "success": True,
            "data": {
                "source": "geoapify",
                "place": name,
                "category": category,
                "latitude": details.get(
                    "latitude"
                ),
                "longitude": details.get(
                    "longitude"
                ),
                "address": address,
                "website": website,
                "phone": phone,
                "opening_hours": opening_hours,
                "rating": rating,
                "info": info,
                "tags": tags,
            },
        }
    )

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def place_ai_intelligence_view(request, place_id):
    """
    Generate grounded AI intelligence for a real-world place.
    """

    service = AssistantService(request.user)

    result = service.generate_place_intelligence(
        place_id=place_id,
    )

    status = 200 if result.get("success") else 400

    return JsonResponse(
        result,
        status=status,
    )


# ---------------------------------------------------------------------------
# Nearby Places Discovery
# ---------------------------------------------------------------------------

@csrf_exempt
def nearby_places_view(request):
    """
    Return real-world places near a supplied GPS coordinate.

    Query parameters:

        lat       Required user latitude
        lon       Required user longitude

        radius    Optional radius in kilometres.
                  Default: 10 km
                  Minimum: 1 km
                  Maximum: 15 km

        category  Optional category filter.
    """

    if request.method != "GET":
        return JsonResponse(
            {
                "success": False,
                "error": "GET required",
            },
            status=405,
        )

    # -----------------------------------------------------------------------
    # Coordinates
    # -----------------------------------------------------------------------

    lat_raw = request.GET.get("lat")
    lon_raw = request.GET.get("lon")

    if lat_raw is None or lon_raw is None:
        return JsonResponse(
            {
                "success": False,
                "error": (
                    "lat and lon are required. "
                    "Example: "
                    "/api/places/nearby/?lat=13.9380&lon=75.5499"
                ),
            },
            status=400,
        )

    try:
        user_lat = float(lat_raw)
        user_lon = float(lon_raw)

    except (TypeError, ValueError):
        return JsonResponse(
            {
                "success": False,
                "error": (
                    "lat and lon must be valid numbers."
                ),
            },
            status=400,
        )

    if not -90 <= user_lat <= 90:
        return JsonResponse(
            {
                "success": False,
                "error": "lat must be between -90 and 90.",
            },
            status=400,
        )

    if not -180 <= user_lon <= 180:
        return JsonResponse(
            {
                "success": False,
                "error": "lon must be between -180 and 180.",
            },
            status=400,
        )

    # -----------------------------------------------------------------------
    # Radius
    # -----------------------------------------------------------------------

    radius_raw = request.GET.get(
        "radius",
        "10",
    )

    try:
        radius_km = float(radius_raw)

    except (TypeError, ValueError):
        return JsonResponse(
            {
                "success": False,
                "error": (
                    "radius must be a valid number."
                ),
            },
            status=400,
        )

    if radius_km < 1:
        return JsonResponse(
            {
                "success": False,
                "error": (
                    "radius must be at least 1 km."
                ),
            },
            status=400,
        )

    if radius_km > 15:
        return JsonResponse(
            {
                "success": False,
                "error": (
                    "radius cannot be greater than 15 km."
                ),
            },
            status=400,
        )

    # -----------------------------------------------------------------------
    # Category
    # -----------------------------------------------------------------------

    category = request.GET.get(
        "category"
    )

    if category == "":
        category = None

    # -----------------------------------------------------------------------
    # Places Gateway
    # -----------------------------------------------------------------------

    try:
        nearby = search_nearby(
            latitude=user_lat,
            longitude=user_lon,
            radius_km=radius_km,
            category=category,
        )

    except Exception as exc:
        return JsonResponse(
            {
                "success": False,
                "error": (
                    "nearby places provider failed"
                ),
                "detail": str(exc),
            },
            status=502,
        )

    # -----------------------------------------------------------------------
    # Response
    # -----------------------------------------------------------------------

    return JsonResponse(
        {
            "success": True,
            "data": nearby,
            "meta": {
                "latitude": user_lat,
                "longitude": user_lon,
                "radius_km": radius_km,
                "category": category,
                "count": len(nearby),
                "provider": "geoapify",
            },
        }
    )


# ---------------------------------------------------------------------------
# Real-World Road Routing
# ---------------------------------------------------------------------------

@csrf_exempt
def real_world_route_view(request):
    """
    Calculate a real road route between two geographic coordinates.

    This endpoint is intentionally separate from the existing
    /api/route/ A* routing endpoint.

    Supported modes:

        drive
        motorcycle
        scooter
        bicycle
        walk
    """

    if request.method != "POST":
        return JsonResponse(
            {
                "success": False,
                "error": "POST required",
            },
            status=405,
        )

    body, err = _json_body(request)

    if err:
        return JsonResponse(
            {
                "success": False,
                "error": "invalid JSON body",
            },
            status=400,
        )

    try:
        start_lat = float(
            body["start_lat"]
        )

        start_lon = float(
            body["start_lon"]
        )

        destination_lat = float(
            body["destination_lat"]
        )

        destination_lon = float(
            body["destination_lon"]
        )

        mode = body.get(
            "mode",
            "drive",
        )

    except (
        KeyError,
        TypeError,
        ValueError,
    ) as exc:
        return JsonResponse(
            {
                "success": False,
                "error": (
                    "Expected start_lat, start_lon, "
                    "destination_lat, destination_lon "
                    "and optional mode."
                ),
                "detail": str(exc),
            },
            status=400,
        )

    # -----------------------------------------------------------------------
    # Coordinate validation
    # -----------------------------------------------------------------------

    if not -90 <= start_lat <= 90:
        return JsonResponse(
            {
                "success": False,
                "error": "Invalid start latitude.",
            },
            status=400,
        )

    if not -180 <= start_lon <= 180:
        return JsonResponse(
            {
                "success": False,
                "error": "Invalid start longitude.",
            },
            status=400,
        )

    if not -90 <= destination_lat <= 90:
        return JsonResponse(
            {
                "success": False,
                "error": "Invalid destination latitude.",
            },
            status=400,
        )

    if not -180 <= destination_lon <= 180:
        return JsonResponse(
            {
                "success": False,
                "error": "Invalid destination longitude.",
            },
            status=400,
        )

    # -----------------------------------------------------------------------
    # Routing provider
    # -----------------------------------------------------------------------

    try:
        route = get_real_world_route(
            start_lat=start_lat,
            start_lon=start_lon,
            destination_lat=destination_lat,
            destination_lon=destination_lon,
            mode=mode,
        )

    except ValueError as exc:
        return JsonResponse(
            {
                "success": False,
                "error": str(exc),
            },
            status=400,
        )

    except Exception:
        return JsonResponse(
            {
                "success": False,
                "error": (
                    "Unable to calculate the "
                    "real-world route."
                ),
            },
            status=502,
        )

    return JsonResponse(
        {
            "success": True,
            "data": route,
        }
    )


# ---------------------------------------------------------------------------
# Reviews & Ratings
# ---------------------------------------------------------------------------

def reviews_list_view(
    request,
    target_type,
    target_id,
):
    reviews = Review.objects.filter(
        target_type=target_type,
        target_id=target_id,
    )

    review_count = reviews.count()

    avg = (
        sum(
            r.rating
            for r in reviews
        ) / review_count
        if review_count
        else None
    )

    data = [
        {
            "author": r.author_name,
            "rating": r.rating,
            "comment": r.comment,
            "created_at": (
                r.created_at.isoformat()
            ),
        }
        for r in reviews
    ]

    return JsonResponse(
        {
            "success": True,
            "data": {
                "average_rating": avg,
                "count": review_count,
                "reviews": data,
            },
        }
    )


@csrf_exempt
def reviews_create_view(request):
    if request.method != "POST":
        return JsonResponse(
            {"error": "POST required"},
            status=405,
        )

    body, err = _json_body(request)

    if err:
        return err

    try:
        rating = int(
            body["rating"]
        )

        if rating < 1 or rating > 5:
            return JsonResponse(
                {
                    "error": (
                        "rating must be between 1 and 5."
                    )
                },
                status=400,
            )

        target_type = str(
            body["target_type"]
        ).strip()

        target_id = str(
            body["target_id"]
        ).strip()

        if not target_type or not target_id:
            return JsonResponse(
                {
                    "error": (
                        "target_type and target_id "
                        "are required."
                    )
                },
                status=400,
            )

        review = Review.objects.create(
            id=uuid.uuid4(),
            target_type=target_type,
            target_id=target_id,
            author_name=body.get(
                "author_name",
                "Anonymous",
            ),
            rating=rating,
            comment=body.get(
                "comment",
                "",
            ),
        )

    except (
        KeyError,
        TypeError,
        ValueError,
    ) as exc:
        return JsonResponse(
            {
                "error": (
                    f"missing/invalid field: {exc}"
                )
            },
            status=400,
        )

    return JsonResponse(
        {
            "success": True,
            "data": {
                "id": str(review.id),
                "target_type": review.target_type,
                "target_id": review.target_id,
                "author": review.author_name,
                "rating": review.rating,
                "comment": review.comment,
                "created_at": (
                    review.created_at.isoformat()
                ),
            },
        },
        status=201,
    )


# ---------------------------------------------------------------------------
# Hotels & Simulated Booking
# ---------------------------------------------------------------------------

def hotels_search_view(request):
    area = request.GET.get("area")
    max_price = request.GET.get("max_price")

    qs = Hotel.objects.all()

    if area:
        qs = qs.filter(
            area__icontains=area
        )

    if max_price:
        qs = qs.filter(
            price_per_night__lte=max_price
        )

    data = list(
        qs.values(
            "id",
            "name",
            "area",
            "price_per_night",
            "rating",
            "facilities",
            "room_types",
        )
    )

    return JsonResponse(
        {
            "success": True,
            "data": data,
        }
    )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def booking_create_view(request):
    body = request.data

    try:
        hotel = Hotel.objects.get(
            id=body["hotel_id"]
        )

        booking = Booking.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            hotel=hotel,
            guest_name=body["guest_name"],
            room_type=body["room_type"],
            check_in=body["check_in"],
            check_out=body["check_out"],
            status="confirmed",
        )

    except Hotel.DoesNotExist:
        return JsonResponse(
            {"error": "hotel not found"},
            status=404,
        )

    except KeyError as exc:
        return JsonResponse(
            {
                "error": f"missing field: {exc}"
            },
            status=400,
        )

    return JsonResponse(
        {
            "success": True,
            "data": {
                "booking_id": str(
                    booking.id
                ),
                "status": booking.status,
                "hotel": hotel.name,
                "note": (
                    "This is a simulated booking — "
                    "no payment was processed."
                ),
            },
        },
        status=201,
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def booking_history_view(request):
    bookings = (
        Booking.objects
        .filter(user=request.user)
        .select_related("hotel")
    )

    data = [
        {
            "id": str(b.id),
            "hotel": b.hotel.name,
            "room_type": b.room_type,
            "check_in": str(b.check_in),
            "check_out": str(b.check_out),
            "status": b.status,
        }
        for b in bookings
    ]

    return JsonResponse(
        {
            "success": True,
            "data": data,
        }
    )


# ---------------------------------------------------------------------------
# Emergency Contacts & SOS
# ---------------------------------------------------------------------------

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def emergency_contact_create_view(request):
    body = request.data

    try:
        contact = EmergencyContact.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            name=body["name"],
            phone=body["phone"],
            relationship=body.get(
                "relationship",
                "",
            ),
        )

    except KeyError as exc:
        return JsonResponse(
            {
                "error": f"missing field: {exc}"
            },
            status=400,
        )

    return JsonResponse(
        {
            "success": True,
            "data": {
                "id": str(
                    contact.id
                ),
            },
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def emergency_contact_list_view(request):
    contacts = EmergencyContact.objects.filter(
        user=request.user
    )

    data = [
        {
            "id": str(c.id),
            "name": c.name,
            "phone": c.phone,
            "relationship": c.relationship,
        }
        for c in contacts
    ]

    return JsonResponse(
        {
            "success": True,
            "data": data,
        }
    )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def sos_trigger_view(request):
    body = request.data

    event = SOSEvent.objects.create(
        id=uuid.uuid4(),
        user=request.user,
        status="countdown",
        latitude=body.get(
            "latitude"
        ),
        longitude=body.get(
            "longitude"
        ),
    )

    return JsonResponse(
        {
            "success": True,
            "data": {
                "id": str(event.id),
                "status": event.status,
            },
        }
    )

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def sos_active_view(request):
    """
    Return the user's current active SOS event, if one exists.
    """

    event = (
        SOSEvent.objects
        .filter(
            user=request.user,
            status__in=["countdown", "active"],
        )
        .order_by("-triggered_at")
        .first()
    )

    if event is None:
        return JsonResponse(
            {
                "success": True,
                "data": None,
            }
        )

    return JsonResponse(
        {
            "success": True,
            "data": {
                "id": str(event.id),
                "status": event.status,
                "latitude": event.latitude,
                "longitude": event.longitude,
                "created_at": event.triggered_at.isoformat(),
            },
        }
    )

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def sos_activate_view(
    request,
    event_id,
):
    try:
        event = SOSEvent.objects.get(
            id=event_id,
            user=request.user,
        )

    except SOSEvent.DoesNotExist:
        return JsonResponse(
            {
                "error": "SOS event not found"
            },
            status=404,
        )

    contacts = EmergencyContact.objects.filter(
        user=request.user
    )

    event.status = "active"

    event.notified_contacts = [
        str(c.id)
        for c in contacts
    ]

    event.save()

    return JsonResponse(
        {
            "success": True,
            "data": {
                "id": str(
                    event.id
                ),
                "status": event.status,
                "notified": [
                    c.name
                    for c in contacts
                ],
                "note": (
                    "Simulated notification — "
                    "no real SMS/call was sent "
                    "in this phase."
                ),
            },
        }
    )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def sos_resolve_view(
    request,
    event_id,
):
    try:
        event = SOSEvent.objects.get(
            id=event_id,
            user=request.user,
        )

    except SOSEvent.DoesNotExist:
        return JsonResponse(
            {
                "error": "SOS event not found"
            },
            status=404,
        )

    event.status = "resolved"
    event.resolved_at = timezone.now()
    event.save()

    return JsonResponse(
        {
            "success": True,
            "data": {
                "id": str(
                    event.id
                ),
                "status": event.status,
            },
        }
    )


# ---------------------------------------------------------------------------
# Smart Itinerary Planning
# ---------------------------------------------------------------------------

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def itinerary_create_view(request):
    """
    Body:

    {
        "title": "My Trip",
        "stops": [
            {
                "day_number": 1,
                "place_id": "...",
                "scheduled_time": "10:00",
                "notes": "Visit in the morning"
            }
        ]
    }
    """

    body = request.data

    itinerary = Itinerary.objects.create(
        id=uuid.uuid4(),
        user=request.user,
        title=body.get(
            "title",
            "My Trip",
        ),
    )

    for i, stop in enumerate(
        body.get("stops", [])
    ):
        try:
            place = Place.objects.get(
                id=stop["place_id"]
            )

        except (
            Place.DoesNotExist,
            KeyError,
        ):
            continue

        ItineraryStop.objects.create(
            itinerary=itinerary,
            day_number=stop.get(
                "day_number",
                1,
            ),
            order=i,
            place=place,
            scheduled_time=stop.get(
                "scheduled_time",
                "",
            ),
            notes=stop.get(
                "notes",
                "",
            ),
        )

    return JsonResponse(
        {
            "success": True,
            "data": {
                "id": str(
                    itinerary.id
                ),
            },
        },
        status=201,
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def itinerary_list_view(request):
    itineraries = (
        request.user.itineraries
        .order_by("-created_at")
    )

    return JsonResponse(
        {
            "success": True,
            "data": [
                {
                    "id": str(
                        itinerary.id
                    ),
                    "title": itinerary.title,
                    "created_at": (
                        itinerary.created_at
                        .isoformat()
                    ),
                }
                for itinerary in itineraries
            ],
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def itinerary_detail_view(
    request,
    itinerary_id,
):
    try:
        itinerary = Itinerary.objects.get(
            id=itinerary_id,
            user=request.user,
        )

    except Itinerary.DoesNotExist:
        return JsonResponse(
            {
                "error": "itinerary not found"
            },
            status=404,
        )

    stops = (
        itinerary.stops
        .select_related("place")
        .all()
    )

    days = {}

    for stop in stops:
        days.setdefault(
            stop.day_number,
            [],
        ).append(
            {
                "place": stop.place.name,
                "scheduled_time": (
                    stop.scheduled_time
                ),
                "notes": stop.notes,
            }
        )

    return JsonResponse(
        {
            "success": True,
            "data": {
                "id": str(
                    itinerary.id
                ),
                "title": itinerary.title,
                "days": days,
            },
        }
    )


# ---------------------------------------------------------------------------
# Preferences & Rule-Based Recommendations
# ---------------------------------------------------------------------------

@csrf_exempt
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def preferences_save_view(request):
    """
    Save or update travel preferences for
    the authenticated user.
    """

    body = request.data

    pref, _ = UserPreference.objects.update_or_create(
        user=request.user,
        defaults={
            "interests": body.get(
                "interests",
                [],
            ),
            "budget": body.get(
                "budget",
                "mid-range",
            ),
            "travel_style": body.get(
                "travel_style",
                "",
            ),
        },
    )

    return JsonResponse(
        {
            "success": True,
            "data": {
                "user_id": request.user.id,
                "username": (
                    request.user.username
                ),
                "interests": pref.interests,
                "budget": pref.budget,
                "travel_style": (
                    pref.travel_style
                ),
            },
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def recommendations_view(request):
    """
    Rule-based recommendation.

    Score each local Place by tag overlap with the
    authenticated user's stated interests.

    This is intentionally NOT collaborative filtering.
    """

    try:
        pref = UserPreference.objects.get(
            user=request.user
        )

    except UserPreference.DoesNotExist:
        return JsonResponse(
            {
                "success": True,
                "data": [],
                "note": (
                    "No preferences saved yet "
                    "for this user."
                ),
            }
        )

    interests = set(
        pref.interests
    )

    scored = []

    for place in Place.objects.all():
        overlap = len(
            interests.intersection(
                set(place.tags)
            )
        )

        scored.append(
            (
                overlap,
                place,
            )
        )

    scored.sort(
        key=lambda item: item[0],
        reverse=True,
    )

    top = [
        {
            "id": place.id,
            "name": place.name,
            "category": place.category,
            "match_score": score,
        }
        for score, place in scored[:5]
    ]

    return JsonResponse(
        {
            "success": True,
            "data": top,
        }
    )