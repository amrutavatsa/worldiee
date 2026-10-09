import os

import requests
from dotenv import load_dotenv


load_dotenv()


GEOAPIFY_ROUTING_URL = (
    "https://api.geoapify.com/v1/routing"
)


MODE_MAP = {
    "drive": "drive",
    "motorcycle": "motorcycle",
    "scooter": "scooter",
    "bicycle": "bicycle",
    "walk": "walk",
}


def get_real_world_route(
    start_lat,
    start_lon,
    destination_lat,
    destination_lon,
    mode="drive",
):
    """
    Get a real road route between two coordinates.

    This is completely separate from the existing
    WorldCompanion A* routing system.
    """

    api_key = os.getenv("GEOAPIFY_API_KEY")

    if not api_key:
        raise RuntimeError(
            "GEOAPIFY_API_KEY is not configured."
        )

    mode = str(mode or "drive").lower().strip()

    if mode not in MODE_MAP:
        raise ValueError(
            "Unsupported routing mode. "
            "Use drive, motorcycle, scooter, "
            "bicycle, or walk."
        )

    waypoints = (
        f"{start_lat},{start_lon}|"
        f"{destination_lat},{destination_lon}"
    )

    params = {
        "waypoints": waypoints,
        "mode": MODE_MAP[mode],
        "format": "geojson",
        "apiKey": api_key,
    }

    response = requests.get(
        GEOAPIFY_ROUTING_URL,
        params=params,
        timeout=20,
    )

    response.raise_for_status()

    data = response.json()

    features = data.get("features", [])

    if not features:
        raise RuntimeError(
            "No route was returned by the routing provider."
        )

    feature = features[0]

    properties = feature.get(
        "properties",
        {},
    )

    geometry = feature.get(
        "geometry",
        {},
    )

    distance_meters = properties.get(
        "distance",
        0,
    )

    duration_seconds = properties.get(
        "time",
        0,
    )

    return {
        "distance_km": round(
            float(distance_meters) / 1000,
            3,
        ),
        "duration_minutes": round(
            float(duration_seconds) / 60,
            1,
        ),
        "geometry": geometry,
        "mode": mode,
    }