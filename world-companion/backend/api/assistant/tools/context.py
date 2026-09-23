from api.assistant.tools.preferences import get_user_preferences
from api.assistant.tools.booking_history import get_booking_history
from api.assistant.tools.emergency import get_emergency_contacts


def build_user_context(user):
    return {
        "preferences": get_user_preferences(user),
        "booking_history": get_booking_history(user),
        "emergency_contacts": get_emergency_contacts(user),
    }