from django.contrib import admin
from api.models import (
    Place, PlaceInfo, Hotel, Booking, Review,
    EmergencyContact, SOSEvent, Itinerary, ItineraryStop, UserPreference,
)

admin.site.register(Place)
admin.site.register(PlaceInfo)
admin.site.register(Hotel)
admin.site.register(Booking)
admin.site.register(Review)
admin.site.register(EmergencyContact)
admin.site.register(SOSEvent)
admin.site.register(Itinerary)
admin.site.register(ItineraryStop)
admin.site.register(UserPreference)
