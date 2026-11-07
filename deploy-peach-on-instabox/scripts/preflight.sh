#!/usr/bin/env bash
# Read-only preflight. No changes, no credentials, no sudo.
# Usage: bash scripts/preflight.sh linux-fuse /absolute/media/path
#        bash scripts/preflight.sh peach-only /absolute/media/path
set -u
MODE="${1:-linux-fuse}"
MEDIA="${2:-}"
ERRORS=0
WARNINGS=0

note() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; WARNINGS=$((WARNINGS + 1)); }
fail() { printf '[STOP] %s\n' "$*"; ERRORS=$((ERRORS + 1)); }

case "$MODE" in linux-fuse|peach-only) ;; *) printf 'Usage: %s {linux-fuse|peach-only} /absolute/media/path\n' "$0"; exit 64 ;; esac

note "mode=$MODE host=$(uname -s) kernel_arch=$(uname -m)"
case "$(uname -m)" in
  x86_64|amd64) note 'CPU is x86-64; Peach linux/amd64 target is plausible' ;;
  aarch64|arm64|armv7l|armv7) fail 'Peach official Docker image is not ARM-validated. Do not auto-deploy or emulate.' ;;
  *) fail 'Unknown CPU architecture: verify Peach image support manually.' ;;
esac

if ! command -v docker >/dev/null 2>&1; then
  fail 'Docker command not found.'
else
  if ! docker compose version >/dev/null 2>&1; then
    fail 'Docker Compose plugin missing or inaccessible.'
  else
    note "$(docker compose version 2>/dev/null)"
  fi
  if ! docker info >/dev/null 2>&1; then
    fail 'Cannot query Docker Engine. Check daemon and user permissions.'
  else
    DOCKER_OS="$(docker info --format '{{.OperatingSystem}}' 2>/dev/null || true)"
    DOCKER_ARCH="$(docker info --format '{{.Architecture}}' 2>/dev/null || true)"
    note "Docker server: os=$DOCKER_OS arch=$DOCKER_ARCH"
    case "$DOCKER_ARCH" in x86_64|amd64) ;; *) warn 'Docker server arch is not known amd64. Verify Peach image manifest and actual runtime.' ;; esac
    if printf '%s' "$DOCKER_OS" | grep -iq 'Docker Desktop'; then
      if [ "$MODE" = linux-fuse ]; then
        fail 'Docker Desktop does not support host bind propagation; use peach-only or remote native Linux.'
      else
        warn 'Docker Desktop: stable media bind only; no FUSE submount propagation assumed.'
      fi
    fi
  fi
fi

if [ -z "$MEDIA" ]; then
  fail 'Media root path missing.'
elif [ "${MEDIA#/}" = "$MEDIA" ]; then
  fail 'Media root must be an absolute Unix-style path on the Docker HOST.'
elif [ ! -d "$MEDIA" ]; then
  fail "Media root does not exist: $MEDIA (will not create it)."
else
  note "Media path exists: $MEDIA"
  if command -v df >/dev/null 2>&1; then
    df -hP "$MEDIA" 2>/dev/null | tail -1 | awk '{printf "[INFO] Media filesystem free: %s (mount %s)\n", $4,$6}'
  fi
  if command -v findmnt >/dev/null 2>&1; then
    PROP="$(findmnt -T "$MEDIA" -n -o PROPAGATION 2>/dev/null || true)"
    note "Media mount propagation: ${PROP:-unknown}"
    if [ "$MODE" = linux-fuse ] && [ "$PROP" != shared ]; then
      warn 'CloudDrive2 requires shared host propagation. Diagnose exact mount; DO NOT automatically mount --make-shared or edit systemd.'
    fi
  else
    warn 'findmnt unavailable; inspect /proc/self/mountinfo before FUSE deployment.'
  fi
fi

if [ "$MODE" = linux-fuse ]; then
  if [ "$(uname -s)" != Linux ]; then
    fail 'linux-fuse requires a native Linux Docker host.'
  fi
  if [ ! -c /dev/fuse ]; then
    fail '/dev/fuse character device unavailable on this host.'
  else
    note '/dev/fuse exists (not sufficient to prove privileged mount permission)'
  fi
  warn 'CloudDrive2 uses privileged + host pid namespace. Require explicit user approval before starting.'
fi

if command -v ss >/dev/null 2>&1; then
  note 'Listening ports 8900/19798/9117 (if any):'
  ss -lnt 2>/dev/null | awk 'NR==1 || $4 ~ /:(8900|19798|9117)$/' | head -12
else
  warn 'ss unavailable; check host port conflicts manually.'
fi

note "preflight result: blocking=$ERRORS warnings=$WARNINGS"
if [ "$ERRORS" -gt 0 ]; then
  exit 2
fi
exit 0
