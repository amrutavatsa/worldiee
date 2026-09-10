"""
speech_to_text.py — FR01: speech capture and transcription.

Uses Vosk (https://alphacephei.com/vosk/), a pretrained, offline
speech-recognition toolkit — this is the "pretrained acoustic front end"
referenced in the merged IEEE paper (Section V-A note), rather than a
model trained from scratch.

SETUP REQUIRED ON YOUR MACHINE (not done in this environment — model
files are too large to fetch here and aren't on the allowed domain list):

    pip install vosk
    # download a model, e.g. the small English model (~40MB):
    # https://alphacephei.com/vosk/models -> vosk-model-small-en-us-0.15
    # unzip it into backend/data/vosk-model/

Once that's done, uncomment the real implementation below and delete
the NotImplementedError stub — no other code changes are needed, since
views.py already calls this function generically.
"""

from pathlib import Path

VOSK_MODEL_PATH = Path(__file__).parent.parent / "data" / "vosk-model"


def transcribe_audio(audio_file) -> str:
    """
    audio_file: a Django UploadedFile (WAV, 16kHz mono recommended for Vosk).
    Returns the transcribed text.
    """
    if not VOSK_MODEL_PATH.exists():
        raise NotImplementedError(
            "Vosk model not found. Download a model from "
            "https://alphacephei.com/vosk/models and unzip it to "
            f"{VOSK_MODEL_PATH} — see this file's docstring for exact steps."
        )

    # --- Real implementation (uncomment once the model is downloaded) ---
    # import wave
    # import json
    # from vosk import Model, KaldiRecognizer
    #
    # model = Model(str(VOSK_MODEL_PATH))
    # wf = wave.open(audio_file, "rb")
    # rec = KaldiRecognizer(model, wf.getframerate())
    #
    # result_text = []
    # while True:
    #     data = wf.readframes(4000)
    #     if len(data) == 0:
    #         break
    #     if rec.AcceptWaveform(data):
    #         result_text.append(json.loads(rec.Result()).get("text", ""))
    # result_text.append(json.loads(rec.FinalResult()).get("text", ""))
    # return " ".join(t for t in result_text if t).strip()

    raise NotImplementedError("Uncomment the real implementation above once the Vosk model is installed.")
