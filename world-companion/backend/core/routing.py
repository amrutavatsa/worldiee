"""
routing.py — Multi-destination route optimisation via A* search.

Implements the algorithm specified in the IEEE paper (Section VI-B):
    f(n) = g(n) + h(n)
where g(n) is exact accumulated cost from origin, and h(n) is a
Haversine great-circle distance heuristic to the destination.

This module is self-contained (no ML, no external services) and can
be tested standalone.
"""

import math
import itertools
import networkx as nx


def haversine_km(lat1, lon1, lat2, lon2):
    """Great-circle distance between two points, in kilometres."""
    R = 6371.0  # Earth radius, km
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * R * math.asin(math.sqrt(a))


class RouteGraph:
    """
    Wraps a weighted graph of points of interest (POIs).
    Nodes carry (name, lat, lon). Edges carry a 'weight' = real distance (km).
    """

    def __init__(self):
        self.g = nx.Graph()

    def add_poi(self, poi_id, name, lat, lon, category="general"):
        self.g.add_node(poi_id, name=name, lat=lat, lon=lon, category=category)

    def connect_all(self):
        """
        For MVP scale (a few dozen to a few hundred POIs), connect every
        node to every other node with an edge weighted by real distance.
        This lets A* consider any POI-to-POI hop directly, which is
        appropriate at city scale where road-network-level graph data
        isn't available yet (see IEEE paper Future Scope for a
        road-network-aware version).
        """
        nodes = list(self.g.nodes(data=True))
        for (id1, d1), (id2, d2) in itertools.combinations(nodes, 2):
            dist = haversine_km(d1["lat"], d1["lon"], d2["lat"], d2["lon"])
            self.g.add_edge(id1, id2, weight=dist)

    def _heuristic(self, n1, n2):
        d1 = self.g.nodes[n1]
        d2 = self.g.nodes[n2]
        return haversine_km(d1["lat"], d1["lon"], d2["lat"], d2["lon"])

    def shortest_path(self, start_id, end_id):
        """A* search between two POIs. Returns (path_ids, total_distance_km)."""
        path = nx.astar_path(self.g, start_id, end_id, heuristic=self._heuristic, weight="weight")
        dist = nx.astar_path_length(self.g, start_id, end_id, heuristic=self._heuristic, weight="weight")
        return path, dist

    def optimise_multi_stop(self, start_id, stop_ids):
        """
        Given a starting point and a set of destinations to visit (order
        not fixed), greedily builds a route by always travelling next to
        the nearest unvisited stop (nearest-neighbour heuristic), then
        refines with A* for each individual hop's actual path.

        Returns a dict: {
            "order": [poi_id, ...],       # visiting order incl. start
            "hops": [ {from, to, path, distance_km}, ... ],
            "total_distance_km": float
        }
        """
        remaining = set(stop_ids)
        current = start_id
        order = [current]
        hops = []
        total = 0.0

        while remaining:
            # pick nearest remaining stop using the heuristic (fast, no search yet)
            nxt = min(remaining, key=lambda pid: self._heuristic(current, pid))
            path, dist = self.shortest_path(current, nxt)
            hops.append({
                "from": current,
                "to": nxt,
                "path": path,
                "distance_km": round(dist, 3),
            })
            total += dist
            order.append(nxt)
            remaining.remove(nxt)
            current = nxt

        return {
            "order": order,
            "hops": hops,
            "total_distance_km": round(total, 3),
        }
