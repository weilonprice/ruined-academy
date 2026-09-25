"""Run the approved visual asset manifest. API key is read from stdin, never saved.

Resumes accepted jobs instead of submitting duplicates. Ambiguous network errors
need manual review; only explicitly rejected concurrency requests are retried.
"""
import base64
import concurrent.futures
import json
import pathlib
import signal
import sys
import threading
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
LIB = ROOT / 'art_library'
KEY = sys.stdin.readline().strip()
LOCK = threading.Lock()
STOP = threading.Event()
signal.signal(signal.SIGTERM, lambda *_: STOP.set())
PLAN = json.loads((LIB / 'queue.json').read_text())
STATE_PATH = LIB / 'status.json'
STATE = json.loads(STATE_PATH.read_text()) if STATE_PATH.exists() else {}


def save(asset_id, **values):
    with LOCK:
        STATE.setdefault(asset_id, {}).update(values)
        temp = STATE_PATH.with_suffix('.tmp')
        temp.write_text(json.dumps(STATE, indent=2))
        temp.replace(STATE_PATH)
        print(asset_id, values.get('status', ''), values.get('error', ''), flush=True)


def api(path, payload=None):
    request = urllib.request.Request(
        'https://api.pixellab.ai/v2' + path,
        data=json.dumps(payload).encode() if payload is not None else None,
        headers={'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'},
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        return json.load(response)


def download_images(value, folder, prefix='image'):
    folder.mkdir(parents=True, exist_ok=True)
    if isinstance(value, dict):
        if value.get('base64'):
            encoded = value['base64'].split(',', 1)[-1]
            (folder / (prefix + '.png')).write_bytes(base64.b64decode(encoded))
            return
        for key, child in value.items():
            download_images(child, folder, prefix + '_' + str(key))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            download_images(child, folder, prefix + '_' + str(index).zfill(3))
    elif isinstance(value, str) and value.startswith('https://') and '.png' in value:
        # Public asset URL. Never forward the API authorization header here.
        request = urllib.request.Request(value, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(request, timeout=60) as response:
            (folder / (prefix + '.png')).write_bytes(response.read())


def execute(task):
    asset_id = task['id']
    folder = LIB / 'assets' / asset_id
    result_path = LIB / 'results' / (asset_id + '-submission.json')
    try:
        if result_path.exists():
            result = json.loads(result_path.read_text())
        else:
            balance = api('/balance')
            remaining = balance.get('subscription', {}).get('generations', 0)
            if remaining < task.get('reserve', 8):
                STOP.set()
                save(asset_id, status='blocked', error='Insufficient existing allowance; no purchase attempted.')
                return
            payload = dict(task['payload'])
            if task.get('character'):
                parent = json.loads((LIB / 'results' / (task['character'] + '-submission.json')).read_text())
                payload['character_id'] = parent['character_id']
            if task.get('first_frame'):
                pngs = sorted((LIB / 'assets' / task['first_frame']).glob('*.png'))
                if not pngs:
                    raise RuntimeError('No reference PNG available')
                payload['first_frame'] = {'base64': base64.b64encode(pngs[0].read_bytes()).decode()}
            (LIB / 'requests' / (asset_id + '.json')).write_text(json.dumps(payload, indent=2))
            save(asset_id, status='submitting')
            while not STOP.is_set():
                try:
                    result = api(task['endpoint'], payload)
                    break
                except urllib.error.HTTPError as exc:
                    if exc.code == 429:
                        save(asset_id, status='waiting_for_capacity')
                        time.sleep(25)
                        continue
                    if exc.code in (401, 402, 403):
                        STOP.set()
                    raise
            else:
                save(asset_id, status='queued')
                return
            result_path.write_text(json.dumps(result, indent=2))
        jobs = result.get('background_job_ids', [])
        if result.get('background_job_id'):
            jobs = [result['background_job_id']]
        save(asset_id, status='processing', jobs=jobs)
        for job in jobs:
            while True:
                try:
                    response = api('/background-jobs/' + job)
                except (urllib.error.URLError, TimeoutError):
                    time.sleep(20)
                    continue
                if response.get('status') == 'failed':
                    raise RuntimeError(str(response.get('last_response'))[:800])
                if response.get('status') == 'completed':
                    (LIB / 'results' / (asset_id + '-' + job + '.json')).write_text(json.dumps(response, indent=2))
                    download_images(response.get('last_response', {}), folder)
                    break
                time.sleep(15)
        if task['endpoint'] == '/create-character-v3':
            character = api('/characters/' + result['character_id'])
            (LIB / 'results' / (asset_id + '-character.json')).write_text(json.dumps(character, indent=2))
            download_images(character.get('rotation_urls', {}), folder, 'rotation')
        elif result.get('tileset_id'):
            tileset = api('/tilesets/' + result['tileset_id'])
            (LIB / 'results' / (asset_id + '-tileset.json')).write_text(json.dumps(tileset, indent=2))
            download_images(tileset, folder, 'tileset')
        elif not jobs:
            download_images(result, folder)
        save(asset_id, status='completed', files=len(list(folder.glob('*.png'))))
    except urllib.error.HTTPError as exc:
        save(asset_id, status='failed', error='HTTP ' + str(exc.code) + ': ' + exc.read().decode()[:700])
    except Exception as exc:
        save(asset_id, status='needs_review', error=str(exc)[:700])


def main():
    if not KEY:
        raise SystemExit('API key must be provided on stdin.')
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        active = {}
        while True:
            for future in list(active):
                if future.done():
                    future.result()
                    del active[future]
            running_ids = set(active.values())
            ready = [task for task in PLAN if task['id'] not in running_ids
                     and STATE.get(task['id'], {}).get('status') not in ('completed', 'failed', 'needs_review', 'blocked')
                     and all(STATE.get(dep, {}).get('status') == 'completed' for dep in task.get('depends', []))]
            if not STOP.is_set():
                for task in ready[:4 - len(active)]:
                    active[pool.submit(execute, task)] = task['id']
            if not active and (STOP.is_set() or not ready):
                break
            time.sleep(2)
    (LIB / 'balance-after.json').write_text(json.dumps(api('/balance'), indent=2))
    counts = {}
    for task in PLAN:
        status = STATE.get(task['id'], {}).get('status', 'queued_dependency')
        counts[status] = counts.get(status, 0) + 1
    print(json.dumps(counts), flush=True)


if __name__ == '__main__':
    main()
