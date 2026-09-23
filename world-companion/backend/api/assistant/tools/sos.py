from api.models import EmergencyContact, SOSEvent


def trigger_sos(user, latitude=None, longitude=None):
    event = SOSEvent.objects.create(
        user=user,
        status="countdown",
        latitude=latitude,
        longitude=longitude,
    )

    contacts = EmergencyContact.objects.filter(
        user=user
    )

    return {
        "id": str(event.id),
        "status": event.status,
        "contact_count": contacts.count(),
        "note": (
            "SOS is currently simulated. "
            "No real SMS or call is sent in this phase."
        ),
    }