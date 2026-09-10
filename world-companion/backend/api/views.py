"""
views.py — Phase 1 API endpoints.

POST /api/intent/        { "text": "..." }              -> classify intent (FR02)
POST /api/route/         { "start": {...}, "stops": [...] } -> A* multi-stop route (FR03)
POST /api/transcribe/    (audio upload)                  -> speech-to-text (FR01, stub — see note)

FR01 (speech-to-text) requires a pretrained acoustic model (Vosk) whose
model files must be downloaded on your own machine — they're too large
and the download isn't reachable from this build environment. The
endpoint below is fully wired and ready; see ml/speech_to_text.py for
the two-line change needed once you've downloaded a Vosk model locally.
"""

import json
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse

from ml.intent_classifier import IntentClassifier
from core.routing import RouteGraph
from api.poi_data import BENGALURU_POIS


def _graph_from_pois():
    g = RouteGraph()
    for poi_id, info in BENGALURU_POIS.items():
        g.add_poi(poi_id, info["name"], info["lat"], info["lon"], info.get("category", "general"))
    g.connect_all()
    return g


@csrf_exempt
def intent_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    try:
        body = json.loads(request.body)
        text = body["text"]
    except (KeyError, json.JSONDecodeError):
        return JsonResponse({"error": "expected JSON body: {\"text\": \"...\"}"}, status=400)

    result = IntentClassifier.predict(text)
    return JsonResponse({"success": True, "data": result})


@csrf_exempt
def route_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    try:
        body = json.loads(request.body)
        start_id = body["start_id"]
        stop_ids = body["stop_ids"]
    except (KeyError, json.JSONDecodeError):
        return JsonResponse(
            {"error": "expected JSON body: {\"start_id\": \"...\", \"stop_ids\": [\"...\"]}"},
            status=400,
        )

    g = _graph_from_pois()
    try:
        result = g.optimise_multi_stop(start_id, stop_ids)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=400)

    # attach human-readable names to the response
    for hop in result["hops"]:
        hop["from_name"] = BENGALURU_POIS[hop["from"]]["name"]
        hop["to_name"] = BENGALURU_POIS[hop["to"]]["name"]

    return JsonResponse({"success": True, "data": result})


@csrf_exempt
def transcribe_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    from ml.speech_to_text import transcribe_audio
    audio_file = request.FILES.get("audio")
    if not audio_file:
        return JsonResponse({"error": "no audio file provided (multipart field 'audio')"}, status=400)

    try:
        text = transcribe_audio(audio_file)
    except NotImplementedError as e:
        return JsonResponse({"error": str(e)}, status=501)

    return JsonResponse({"success": True, "data": {"text": text}})


def pois_view(request):
    """Convenience endpoint: list available POIs for the Flutter app to populate pickers."""
    return JsonResponse({"success": True, "data": BENGALURU_POIS})
