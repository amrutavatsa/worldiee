from pathlib import Path

path = Path("lib/screens/home_screen.dart")
source = path.read_text(encoding="utf-8")

old_status = """          if (!listening) {
            _cancelSilenceTimer();
          }"""

new_status = """          if (!listening) {
            if (_voiceSubmitting) {
              _cancelSilenceTimer();
            } else if (_controller.text.trim().isNotEmpty) {
              _resetSilenceTimer();
            } else {
              _cancelSilenceTimer();
            }
          }"""

old_guard = """    if (!mounted || !_isListening || _voiceSubmitting) return;"""

new_guard = """    if (!mounted || _voiceSubmitting) return;"""

if source.count(old_status) != 1:
    raise SystemExit("STOPPED: Expected status callback not found exactly once. No changes made.")

if source.count(old_guard) != 1:
    raise SystemExit("STOPPED: Expected timer guard not found exactly once. No changes made.")

updated = source.replace(old_status, new_status, 1)
updated = updated.replace(old_guard, new_guard, 1)

path.write_text(updated, encoding="utf-8", newline="")
print("Voice submission fix applied.")
print("Changed only the speech status timer handling and silence timer guard.")
