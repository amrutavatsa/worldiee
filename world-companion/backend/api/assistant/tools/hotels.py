from api.models import Hotel


def search_hotels(area=None, max_price=None):
    qs = Hotel.objects.all()

    if area:
        qs = qs.filter(area__icontains=area)

    if max_price is not None:
        qs = qs.filter(price_per_night__lte=max_price)

    return list(
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
