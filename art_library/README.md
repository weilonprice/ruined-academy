# Pixel Lab generation batch

The 314 request units in `queue.json` cover the visual asset manifest: characters, directional animations, portraits, terrain transitions, architecture, props and states, effects, icons, and UI art. Audio is not supported by this visual generation batch.

Generation is asynchronous and limited by Pixel Lab's concurrent-job allowance. The local worker submits requests as capacity becomes available. A locally queued request is not necessarily submitted to Pixel Lab yet.

- `status.json`: per-request state, remote job IDs, failures, and downloaded file counts.
- `requests/`: exact prompts and generation parameters, without credentials.
- `results/`: original submissions and completed job responses.
- `assets/`: downloaded PNGs grouped by manifest ID.
- `balance-after.json`: final balance after the worker stops.

The worker is `../tools/pixellab_batch.py`. It reads the API key from standard input and keeps it in memory. It never purchases credits. Accepted submissions are saved before polling, allowing completed or pending remote jobs to be resumed without submitting them again. Requests marked `needs_review` are not automatically retried because their submission status may be uncertain.

All generated artwork is a first production pass, pending review. Generating an asset does not add it to the game. These are currently copied into `../game`:

- Wizard: still rotations; walk, cast, dodge, hurt, and death clips (`../tools/copy_character_frames.py`). Walk, dodge, hurt, and death are pinned to the ground line (`../tools/ground_lock_frames.py`). Dodge west is mirrored from east, and dodge north reuses its first two frames because the staff vanishes later.
- Three enemies: still rotations and walk, attack (the Scholar's cast), hurt, and death clips, ground-locked. The Skitter's west death is mirrored from east.
- Two NPCs: still rotations.
- Candle flicker (`../tools/copy_prop_frames.py`), with the stand pinned so only the flame moves.

Every idle (wizard, enemies, NPCs) is a subtle breathing loop built from the stills (`../tools/make_breathing_idle.py`), because the generated idle clips shimmer and exaggerate the motion.

The spell effects (FX-01 to FX-16) are unusable: each came out as an academy building. The brazier (PROP-26) and ward beacon (PROP-20) ambient clips have the same problem.

The game is independently playable while this queue runs. The worker needs the computer to stay running and online. If the worker is interrupted, it can resume with the same queue and a key supplied again on stdin.
