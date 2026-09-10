import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  Map<String, dynamic>? _pois;
  String? _startId;
  final Set<String> _selectedStops = {};
  Map<String, dynamic>? _routeResult;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPois();
  }

  Future<void> _loadPois() async {
    try {
      final pois = await ApiService.getPois();
      setState(() {
        _pois = pois;
        _startId = pois.keys.first;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _computeRoute() async {
    if (_startId == null || _selectedStops.isEmpty) return;
    setState(() => _loading = true);
    try {
      final result = await ApiService.optimizeRoute(
        _startId!,
        _selectedStops.toList(),
      );
      setState(() => _routeResult = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Route Planner")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text("Starting point:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _startId,
                        items: _pois!.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value["name"]),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _startId = v),
                      ),
                      const SizedBox(height: 16),
                      const Text("Select stops to visit:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: ListView(
                          children: _pois!.entries
                              .where((e) => e.key != _startId)
                              .map((e) => CheckboxListTile(
                                    title: Text(e.value["name"]),
                                    subtitle: Text(e.value["category"]),
                                    value: _selectedStops.contains(e.key),
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedStops.add(e.key);
                                        } else {
                                          _selectedStops.remove(e.key);
                                        }
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _computeRoute,
                        child: const Text("Compute Optimized Route"),
                      ),
                      if (_routeResult != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          "Total distance: ${_routeResult!["total_distance_km"]} km",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...List.generate(
                          (_routeResult!["hops"] as List).length,
                          (i) {
                            final hop = _routeResult!["hops"][i];
                            return Text(
                              "${i + 1}. ${hop["from_name"]} → ${hop["to_name"]} "
                              "(${hop["distance_km"]} km)",
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
