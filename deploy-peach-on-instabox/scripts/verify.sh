#!/usr/bin/env bash
# Read-only, on-device checks. Does not claim network/login/download success.
# Usage: bash scripts/verify.sh /absolute/path/compose.yml /absolute/path/.env [relative_media_file]
set -euo pipefail
if [ "$#" -lt 2 ]; then
  echo 'Usage: verify.sh COMPOSE_FILE ENV_FILE [relative_media_file]' >&2
  exit 64
fi
COMPOSE_FILE="$1"
ENV_FILE="$2"
REL_MEDIA="${3:-}"
if [ ! -f "$COMPOSE_FILE" ] || [ ! -f "$ENV_FILE" ]; then
  echo '[STOP] Missing compose/env file.' >&2
  exit 2
fi

dc() { docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"; }

printf '[CHECK] docker compose config --quiet\n'
dc config --quiet
printf '[CHECK] docker compose ps\n'
dc ps
printf '[CHECK] Peach ready health from inside its own container\n'
dc exec -T peach python -c '
import urllib.request
u = "http://127.0.0.1:8900/healthz?ready=1"
try:
    with urllib.request.urlopen(u, timeout=8) as r:
        print("[RESULT] Peach ready HTTP", r.status)
        if r.status != 200: raise SystemExit(2)
except Exception as e:
    print("[FAIL] Peach not ready:", type(e).__name__)
    raise SystemExit(2)
'

printf '[CHECK] Container media root directory\n'
dc exec -T peach python -c '
from pathlib import Path
p=Path("/media")
if not p.is_dir():
    print("[FAIL] /media is not a directory")
    raise SystemExit(2)
print("[RESULT] /media directory exists; mount/content not yet proven")
'

if [ -n "$REL_MEDIA" ]; then
  printf '[CHECK] Read a chosen real media file inside Peach (no contents printed)\n'
  dc exec -T peach python -c '
from pathlib import Path
import sys
base=Path("/media").resolve()
p=(base / sys.argv[1]).resolve()
if p==base or not p.is_relative_to(base) or not p.is_file():
    print("[FAIL] Selected test file absent or outside /media")
    raise SystemExit(2)
try:
    with p.open("rb") as f:
        b=f.read(64)
except OSError:
    print("[FAIL] Cannot read selected test file")
    raise SystemExit(2)
print("[RESULT] Selected media file read OK (bytes sampled:", len(b), ")")
' "$REL_MEDIA"
else
  printf '[NOT_TESTED] Real media read omitted: supply relative_media_file.\n'
fi
printf '[NOT_TESTED] CloudDrive2 mount propagation across reboot; download lifecycle; indexer search; private network login. Verify separately.\n'
