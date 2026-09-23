from api.poi_data import BENGALURU_POIS
from core.routing import RouteGraph


def _graph_from_pois():
    graph = RouteGraph()

    for poi_id, info in BENGALURU_POIS.items():
        graph.add_poi(
            poi_id,
            info["name"],
            info["lat"],
            info["lon"],
            info.get("category", "general"),
        )

    graph.connect_all()

    return graph


def calculate_route(start_id, stop_ids):
    graph = _graph_from_pois()

    result = graph.optimise_multi_stop(
        start_id,
        stop_ids,
    )

    for hop in result["hops"]:
        hop["from_name"] = BENGALURU_POIS[hop["from"]]["name"]
        hop["to_name"] = BENGALURU_POIS[hop["to"]]["name"]

    return result
