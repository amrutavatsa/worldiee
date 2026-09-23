from api.models import Booking


def get_booking_history(user):
    bookings = (
        Booking.objects
        .filter(user=user)
        .select_related("hotel")
    )

    return [
        {
            "id": str(booking.id),
            "hotel": booking.hotel.name,
            "room_type": booking.room_type,
            "check_in": str(booking.check_in),
            "check_out": str(booking.check_out),
            "status": booking.status,
        }
        for booking in bookings
    ]