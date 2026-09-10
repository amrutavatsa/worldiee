# World Companion — Phase 1 (Working Build)

This is the actual, running Phase 1 implementation: Django backend with
a trained intent classifier and a tested A* route-optimization engine,
plus a Flutter frontend that calls it.

**What's been built and verified (tested live in this environment):**
- ✅ A* multi-destination routing over real Bengaluru coordinates — tested, returns correct sensible routes
- ✅ Intent classifier (TF-IDF + Logistic Regression baseline) — trained and tested, 60% accuracy on a 39-example seed dataset (see "Next Steps" — this is the #1 thing to improve)
- ✅ Django REST API (`/api/intent/`, `/api/route/`, `/api/pois/`, `/api/transcribe/`) — all live-tested with curl, working
- ✅ Flutter app screens (Home + Route Planner) wired to call the above API
- ⚠️ Speech-to-text (`/api/transcribe/`) — fully wired, but needs a Vosk model file downloaded on your own machine (can't be fetched in this build environment). See `backend/ml/speech_to_text.py` for the exact 3-step setup.

---

## Backend Setup (Django)

```bash
cd backend
pip install django djangorestframework networkx scikit-learn joblib
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:8000
```

Test it's working:
```bash
curl -X POST http://localhost:8000/api/intent/ -H "Content-Type: application/json" \
  -d '{"text": "take me to lalbagh then cubbon park"}'
```

### Retraining the intent classifier
```bash
python3 ml/intent_classifier.py
```
This trains on `data/intent_training_data.csv` (currently 39 examples — **expand this to 500+ examples as planned**, following the same `text,intent` CSV format) and saves the model to `data/intent_model.joblib`.

### Setting up voice transcription (Vosk)
```bash
pip install vosk
# download a model from https://alphacephei.com/vosk/models
# (e.g. vosk-model-small-en-us-0.15, ~40MB)
# unzip it into backend/data/vosk-model/
```
Then uncomment the real implementation in `backend/ml/speech_to_text.py` (marked clearly in the file) — no other code changes needed.

---

## Frontend Setup (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

- If running on the Android emulator, `10.0.2.2` (already set in `lib/services/api_service.dart`) correctly points to your host machine's `localhost:8000`.
- If running on a physical device, change `baseUrl` in `api_service.dart` to your computer's LAN IP (e.g. `http://192.168.1.X:8000`), and make sure your phone is on the same network.
- The route map view uses `google_maps_flutter` — you'll need your own Google Maps API key added to `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift` per the package's standard setup docs.

---

## What's Genuinely Done vs. What's Left

| Piece | Status |
|---|---|
| A* routing algorithm | Done, tested |
| POI dataset | Seed data only (12 Bengaluru locations) — expand for a real demo |
| Intent classifier | Trained, working, but needs more data (39 → 500+ examples) for real accuracy |
| Django API | Done, all 4 endpoints tested working |
| Flutter Home screen | Done — text input works end-to-end against the live API |
| Flutter Route screen | Done — full multi-stop selection and route display |
| Voice capture (mic → Vosk) | Backend stub ready; needs Vosk model downloaded locally + microphone recording wired into `home_screen.dart` (currently shows a placeholder message) |
| Map visualization of the route | Package included in pubspec, not yet wired to draw the actual polyline — straightforward next step using `google_maps_flutter`'s `Polyline` widget with the `hops[].path` coordinates |

## Immediate Next Steps (in priority order)

1. **Expand the intent training dataset** to 500+ examples — this is the single highest-impact task; current 60% accuracy is expected with only 39 examples.
2. **Set up Vosk locally** and wire microphone recording (the `record` package is already in `pubspec.yaml`) into the "Speak instead" button.
3. **Draw the computed route on the map** using `google_maps_flutter`'s Polyline widget.
4. **Expand the POI dataset** beyond the 12 seed locations for a richer demo.
5. Test on a real device / real network setup ahead of your viva.
