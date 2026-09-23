from api.models import UserPreference


def get_user_preferences(user):
    try:
        preference = UserPreference.objects.get(
            user=user
        )
    except UserPreference.DoesNotExist:
        return None

    return {
        "interests": preference.interests,
        "budget": preference.budget,
        "travel_style": preference.travel_style,
    }