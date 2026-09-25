# Pixel Lab generation batch

The 314 request units in `queue.json` cover the visual asset manifest: characters, directional animations, portraits, terrain transitions, architecture, props and states, effects, icons, and UI art. Audio is not supported by this visual generation batch.

Generation is asynchronous and limited by Pixel Lab's concurrent-job allowance. The local worker submits requests as capacity becomes available. A locally queued request is not necessarily submitted to Pixel Lab yet.

- `status.json`: per-request state, remote job IDs, failures, and downloaded file counts.
- `requests/`: exact prompts and generation parameters, without credentials.
- `results/`: original submissions and completed job responses.
- `assets/`: downloaded PNGs grouped by manifest ID.
- `balance-after.json`: final balance after the worker stops.

The worker is `../tools/pixellab_batch.py`. It reads the API key from standard input and keeps it in memory. It never purchases credits. Accepted submissions are saved before polling, allowing completed or pending remote jobs to be resumed without submitting them again. Requests marked `needs_review` are not automatically retried because their submission status may be uncertain.

All generated artwork is a first production pass, pending review. Only the wizard's directional sprites, idle, walk, and cast frames (via `../tools/copy_character_frames.py`) and three enemy sprites are currently copied into `../game`; generating another asset does not add it to the game.

The game is independently playable while this queue runs. The worker needs the computer to stay running and online. If the worker is interrupted, it can resume with the same queue and a key supplied again on stdin.
