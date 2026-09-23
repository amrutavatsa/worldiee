from api.models import EmergencyContact


def get_emergency_contacts(user):
    contacts = EmergencyContact.objects.filter(
        user=user
    )

    return [
        {
            "id": str(contact.id),
            "name": contact.name,
            "phone": contact.phone,
            "relationship": contact.relationship,
        }
        for contact in contacts
    ]