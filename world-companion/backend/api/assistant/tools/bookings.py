import uuid
from api.models import Booking, Hotel

def create_booking(
    user,
    hotel_id,
    guest_name,
    room_type,
    check_in,
    check_out,
):
    try:
        hotel = Hotel.objects.get(id=hotel_id)
    except Hotel.DoesNotExist:
        return None

    booking = Booking.objects.create(
        id=uuid.uuid4(),
        user=user,
        hotel=hotel,
        guest_name=guest_name,
        room_type=room_type,
        check_in=check_in,
        check_out=check_out,
        status="confirmed",
    )

    return {
        "booking_id": str(booking.id),
        "status": booking.status,
        "hotel": hotel.name,
        "room_type": booking.room_type,
        "check_in": str(booking.check_in),
        "check_out": str(booking.check_out),
        "note": "This is a simulated booking — no payment was processed.",
    }