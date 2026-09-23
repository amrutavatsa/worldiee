from api.auth_views import register_view, login_view, profile_view
from django.urls import path
from django.contrib import admin
from api import views
from api import views_phase2 as v2
from api.assistant.views import assistant_view

urlpatterns = [
    path("admin/", admin.site.urls),

    path("api/auth/register/", register_view),
    path("api/auth/login/", login_view),
    path("api/auth/profile/", profile_view),
    path("api/assistant/", assistant_view),

    # Phase 1 — voice/intent + routing
    path("api/intent/", views.intent_view),
    path("api/route/", views.route_view),
    path("api/transcribe/", views.transcribe_view),
    path("api/pois/", views.pois_view),

    # Phase 2 — AI place/food info & discovery
    path("api/places/nearby/", v2.nearby_places_view),
    path("api/places/<str:place_id>/info/", v2.place_info_view),

    # Phase 2 — reviews & ratings
    path("api/reviews/", v2.reviews_create_view),
    path("api/reviews/<str:target_type>/<str:target_id>/", v2.reviews_list_view),

    # Phase 2 — hotels & simulated booking
    path("api/hotels/", v2.hotels_search_view),
    path("api/bookings/", v2.booking_create_view),
    path("api/bookings/history/", v2.booking_history_view),

    # Phase 2 — emergency contacts & SOS
    path("api/emergency-contacts/", v2.emergency_contact_create_view),
    path("api/emergency-contacts/list/", v2.emergency_contact_list_view),
    path("api/sos/trigger/", v2.sos_trigger_view),
    path("api/sos/<uuid:event_id>/activate/", v2.sos_activate_view),
    path("api/sos/<uuid:event_id>/resolve/", v2.sos_resolve_view),

    # Phase 2 — itinerary planning
    path("api/itinerary/create/", v2.itinerary_create_view),
    path("api/itinerary/", v2.itinerary_list_view),
    path("api/itinerary/<uuid:itinerary_id>/", v2.itinerary_detail_view),

    # Phase 2 — preferences & rule-based recommendations
    path("api/preferences/", v2.preferences_save_view),
    path("api/recommendations/", v2.recommendations_view),
]
