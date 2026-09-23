"""
seed_data.py — populates Place, PlaceInfo, and Hotel from the existing
poi_data.py dict plus hand-authored info snippets and sample hotels.

Run with: python manage.py shell -c "from api.seed_data import seed; seed()"
"""
from api.models import Place, PlaceInfo, Hotel
from api.poi_data import BENGALURU_POIS


def seed():
    for poi_id, info in BENGALURU_POIS.items():
        Place.objects.update_or_create(
            id=poi_id,
            defaults={
                "name": info["name"],
                "category": info.get("category", "area"),
                "latitude": info["lat"],
                "longitude": info["lon"],
                "tags": info.get("tags", [info.get("category", "area")]),
            },
        )
    print(f"Seeded {Place.objects.count()} places.")

    info_snippets = [
        ("lalbagh", "history", "Lalbagh was commissioned in 1760 by Hyder Ali and completed by his son Tipu Sultan, modeled on the Mughal gardens of Sira."),
        ("lalbagh", "tips", "Best visited early morning (6-9 AM) for the flower show and fewer crowds. The glasshouse hosts biannual flower shows in January and August."),
        ("cubbon_park", "history", "Cubbon Park was laid out in 1870 by British engineer Richard Sankey, named after Lord Cubbon, a former Commissioner of Mysore."),
        ("cubbon_park", "tips", "A popular spot for morning walks and yoga; the park is vehicle-free on Sundays."),
        ("vv_puram", "food", "VV Puram is known locally as 'Thindi Beedi' (Food Street) — famous for Karnataka-style street food like masala puri, mangalore buns, and dosa varieties."),
        ("vv_puram", "tips", "Best visited in the evening (6-10 PM) when most stalls open; go hungry, portions are generous."),
        ("mg_road", "culture", "MG Road (Mahatma Gandhi Road) is Bengaluru's commercial heart, blending colonial-era buildings with modern shopping and dining."),
        ("iskcon_temple", "culture", "One of the largest ISKCON temple complexes in the world, combining traditional and modern temple architecture."),
        ("bangalore_palace", "history", "Built in 1887 in Tudor-style architecture, inspired by England's Windsor Castle."),
    ]
    for place_id, topic, content in info_snippets:
        try:
            place = Place.objects.get(id=place_id)
            PlaceInfo.objects.update_or_create(place=place, topic=topic, defaults={"content": content})
        except Place.DoesNotExist:
            print(f"Skipped info for missing place: {place_id}")
    print(f"Seeded {PlaceInfo.objects.count()} info snippets.")

    hotels = [
        {"id": "hotel_indiranagar_inn", "name": "Indiranagar Inn", "area": "Indiranagar", "lat": 12.9719, "lon": 77.6411,
         "price": 2200, "rating": 4.2, "facilities": ["wifi", "breakfast", "ac"],
         "room_types": [{"type": "single", "price": 2200}, {"type": "double", "price": 3200}]},
        {"id": "hotel_koramangala_stay", "name": "Koramangala Budget Stay", "area": "Koramangala", "lat": 12.9352, "lon": 77.6245,
         "price": 1400, "rating": 3.9, "facilities": ["wifi"],
         "room_types": [{"type": "dorm_bed", "price": 700}, {"type": "single", "price": 1400}]},
        {"id": "hotel_mg_grand", "name": "MG Road Grand", "area": "MG Road", "lat": 12.9758, "lon": 77.6045,
         "price": 4500, "rating": 4.6, "facilities": ["wifi", "breakfast", "ac", "pool", "gym"],
         "room_types": [{"type": "deluxe", "price": 4500}, {"type": "suite", "price": 7200}]},
    ]
    for h in hotels:
        Hotel.objects.update_or_create(
            id=h["id"],
            defaults={
                "name": h["name"], "area": h["area"], "latitude": h["lat"], "longitude": h["lon"],
                "price_per_night": h["price"], "rating": h["rating"],
                "facilities": h["facilities"], "room_types": h["room_types"],
            },
        )
    print(f"Seeded {Hotel.objects.count()} hotels.")


if __name__ == "__main__":
    seed()
