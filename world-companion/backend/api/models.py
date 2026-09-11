"""
models.py — Phase 2 data layer.

Covers: place info (extends poi_data), hotel booking simulation, reviews &
ratings, emergency contacts + SOS events, itinerary planning, user
preferences for rule-based recommendations.

Nearby-traveller chat and travel community are deliberately NOT modeled
here yet — they need real-time infra (accounts, presence, messaging) and
are sequenced last per the build plan.
"""

from django.db import models
from django.contrib.auth.models import User
import uuid


class Place(models.Model):
    """A point of interest — supersedes the hardcoded poi_data.py dict
    once seeded, while poi_data.py remains as a fallback/seed source."""
    CATEGORY_CHOICES = [
        ("area", "Area"),
        ("park", "Park"),
        ("food", "Food"),
        ("shopping", "Shopping"),
        ("landmark", "Landmark"),
        ("restaurant", "Restaurant"),
    ]
    id = models.CharField(max_length=64, primary_key=True)  # matches poi_data keys e.g. "lalbagh"
    name = models.CharField(max_length=200)
    category = models.CharField(max_length=32, choices=CATEGORY_CHOICES)
    latitude = models.FloatField()
    longitude = models.FloatField()
    description = models.TextField(blank=True, default="")
    tags = models.JSONField(default=list, blank=True)  # e.g. ["nature", "family", "budget"]
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class PlaceInfo(models.Model):
    """AI place/food info knowledge base — short factual snippets an AI
    response can draw from for a given place (FR: AI-Powered Place & Food
    Information)."""
    place = models.ForeignKey(Place, on_delete=models.CASCADE, related_name="info_snippets")
    topic = models.CharField(max_length=64)  # e.g. "history", "food", "culture", "tips"
    content = models.TextField()

    def __str__(self):
        return f"{self.place.name} — {self.topic}"


class Hotel(models.Model):
    """Simulated hotel/hostel listing — no real payment processing."""
    id = models.CharField(max_length=64, primary_key=True)
    name = models.CharField(max_length=200)
    area = models.CharField(max_length=120)
    latitude = models.FloatField()
    longitude = models.FloatField()
    price_per_night = models.DecimalField(max_digits=10, decimal_places=2)
    rating = models.FloatField(default=0.0)
    facilities = models.JSONField(default=list, blank=True)  # e.g. ["wifi", "breakfast", "ac"]
    room_types = models.JSONField(default=list, blank=True)  # e.g. [{"type": "single", "price": 1200}]

    def __str__(self):
        return self.name


class Booking(models.Model):
    """Simulated booking record — status flow only, no payment gateway."""
    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("confirmed", "Confirmed"),
        ("cancelled", "Cancelled"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="bookings",
        null=True,
        blank=True,
    )

    hotel = models.ForeignKey(
        Hotel,
        on_delete=models.CASCADE,
        related_name="bookings",
    )

    guest_name = models.CharField(max_length=200)
    room_type = models.CharField(max_length=100)
    check_in = models.DateField()
    check_out = models.DateField()
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="confirmed",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
class Review(models.Model):
    """Review & rating for any Place or Hotel — simple generic-target model."""
    TARGET_TYPE_CHOICES = [("place", "Place"), ("hotel", "Hotel")]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    target_type = models.CharField(max_length=10, choices=TARGET_TYPE_CHOICES)
    target_id = models.CharField(max_length=64)  # Place.id or Hotel.id
    author_name = models.CharField(max_length=120, default="Anonymous")
    rating = models.PositiveSmallIntegerField()  # 1-5
    comment = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class EmergencyContact(models.Model):
    """A traveller's emergency contact for SOS notification (simulated —
    no real SMS/telecom integration in this phase)."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    user = models.ForeignKey(
    User,
    on_delete=models.CASCADE,
    related_name="emergency_contacts",
    )

    name = models.CharField(max_length=120)
    phone = models.CharField(max_length=32)
    relationship = models.CharField(max_length=64, blank=True, default="")

class SOSEvent(models.Model):
    """An SOS trigger event — countdown -> active -> resolved lifecycle."""
    STATUS_CHOICES = [
        ("countdown", "Countdown"),
        ("active", "Active"),
        ("resolved", "Resolved"),
        ("cancelled", "Cancelled"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    user = models.ForeignKey(
    User,
    on_delete=models.CASCADE,
    related_name="sos_events",
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="countdown",
    )

    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    triggered_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    notified_contacts = models.JSONField(
        default=list,
        blank=True,
    )  # list of EmergencyContact ids notified (simulated)


class Itinerary(models.Model):
    """A day-wise travel plan — builds on the existing A* routing engine."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="itineraries",
    )

    title = models.CharField(max_length=200, default="My Trip")
    created_at = models.DateTimeField(auto_now_add=True)


class ItineraryStop(models.Model):
    """A single stop within an Itinerary, ordered by day and sequence."""
    itinerary = models.ForeignKey(Itinerary, on_delete=models.CASCADE, related_name="stops")
    day_number = models.PositiveSmallIntegerField(default=1)
    order = models.PositiveSmallIntegerField(default=0)
    place = models.ForeignKey(Place, on_delete=models.CASCADE)
    scheduled_time = models.CharField(max_length=20, blank=True, default="")  # e.g. "09:00 AM"
    notes = models.CharField(max_length=300, blank=True, default="")

    class Meta:
        ordering = ["day_number", "order"]


class UserPreference(models.Model):
    """Structured preference profile used for rule-based recommendations
    (per the paper: real collaborative filtering needs interaction data
    this phase doesn't have yet — see PRD Phase 2 note)."""
    user = models.OneToOneField(
    User,
    on_delete=models.CASCADE,
    )
    interests = models.JSONField(default=list, blank=True)  # e.g. ["nature", "history", "food"]
    budget = models.CharField(max_length=20, default="mid-range")  # budget / mid-range / luxury
    travel_style = models.CharField(max_length=50, blank=True, default="")
