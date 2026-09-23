import json
import urllib.request

payload = {
    "model": "qwen3.5:latest",
    "prompt": "Return only: OK",
    "stream": False,
    "think": False,
}

request = urllib.request.Request(
    "http://127.0.0.1:11434/api/generate",
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json"},
    method="POST",
)

with urllib.request.urlopen(request, timeout=30) as response:
    print(response.read().decode("utf-8"))
