from api.models import Place


def search_places(query=None, category=None):
    qs = Place.objects.all()

    if query:
        qs = qs.filter(name__icontains=query)

    if category:
        qs = qs.filter(category=category)

    return list(
        qs.values(
            "id",
            "name",
            "category",
            "latitude",
            "longitude",
            "description",
            "tags",
        )
    )
