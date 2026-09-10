import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'route_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _lastIntent;
  bool _loading = false;
  String? _error;

  // NOTE: this text field is the Phase 1 fallback / dev-testing input.
  // Wire microphone capture (record package) here once you've set up
  // Vosk locally — call ApiService via a POST to /api/transcribe/ with
  // the recorded audio file, then feed the returned text into
  // _submitQuery() below, same as typed input.
  Future<void> _submitQuery(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final intent = await ApiService.classifyIntent(text);
      setState(() => _lastIntent = intent);

      if (intent["intent"] == "navigation") {
        // For Phase 1, navigation intent takes the user to the route
        // planner screen. A more advanced version would extract stop
        // names directly from the query text via named-entity matching
        // against the POI list — left as a Phase 1 refinement.
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RouteScreen()),
          );
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("World Companion")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Speak or type where you'd like to go, or ask about food, "
              "safety, or local info.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "e.g. take me to lalbagh then cubbon park",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _submitQuery(_controller.text),
                ),
              ),
              onSubmitted: _submitQuery,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text("Speak instead"),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Voice capture needs the Vosk model set up locally — "
                      "see backend/ml/speech_to_text.py for setup steps.",
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text("Error: $_error", style: const TextStyle(color: Colors.red)),
            if (_lastIntent != null && !_loading)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "Detected intent: ${_lastIntent!["intent"]} "
                    "(confidence: ${_lastIntent!["confidence"]})",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
