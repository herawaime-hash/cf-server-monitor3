#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-}"
TARGET="${2:-}"
LAB_ROOT="${3:-/opt/security-lab}"

if [[ -z "$PROFILE" || -z "$TARGET" ]]; then
  echo "Usage: $0 <web|api|recon> <target> [lab-root]" >&2
  exit 1
fi

ENV_FILE="$LAB_ROOT/.env"
ALLOWLIST_FILE="$LAB_ROOT/allowlist.txt"
AUDIT_LOG="$LAB_ROOT/logs/audit.log"
REPORT_DIR="$LAB_ROOT/reports"
TS="$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "$LAB_ROOT/logs" "$REPORT_DIR"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

ACK="${LEGAL_ACKNOWLEDGEMENT:-}"
if [[ "$ACK" != "I_HAVE_AUTHORIZATION" ]]; then
  echo "Blocked: LEGAL_ACKNOWLEDGEMENT must be I_HAVE_AUTHORIZATION" >&2
  exit 1
fi

if [[ ! -f "$ALLOWLIST_FILE" ]]; then
  echo "Blocked: missing allowlist file: $ALLOWLIST_FILE" >&2
  exit 1
fi

if ! grep -vE '^\s*#|^\s*$' "$ALLOWLIST_FILE" | grep -Fxq "$TARGET"; then
  echo "Blocked: target not allowlisted: $TARGET" >&2
  exit 1
fi

RATE_LIMIT="${DEFAULT_RATE_LIMIT:-50}"
CONCURRENCY="${DEFAULT_CONCURRENCY:-10}"
COMPOSE_FILE="/home/runner/work/cf-server-monitor3/cf-server-monitor3/scripts/security-lab/docker-compose.yml"

log_audit() {
  printf '{"timestamp":"%s","profile":"%s","target":"%s","rate_limit":%s,"concurrency":%s}\n' \
    "$TS" "$PROFILE" "$TARGET" "$RATE_LIMIT" "$CONCURRENCY" >> "$AUDIT_LOG"
}

run_web() {
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" run --rm nuclei \
    -u "$TARGET" -rl "$RATE_LIMIT" -jsonl -o "/reports/web-$TS.jsonl"
}

run_api() {
  if [[ ! -f "$LAB_ROOT/workspace/api-collection.json" ]]; then
    echo "Missing collection: $LAB_ROOT/workspace/api-collection.json" >&2
    exit 1
  fi

  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" run --rm newman \
    run /workspace/api-collection.json --reporters cli,json \
    --reporter-json-export "/reports/api-$TS.json"
}

run_recon() {
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" run --rm subfinder \
    -d "$TARGET" -silent | \
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" run --rm -T httpx \
      -silent -threads "$CONCURRENCY" -json -o "/reports/recon-$TS.jsonl"
}

log_audit

case "$PROFILE" in
  web) run_web ;;
  api) run_api ;;
  recon) run_recon ;;
  *)
    echo "Unknown profile: $PROFILE (expected: web|api|recon)" >&2
    exit 1
    ;;
esac

echo "Completed profile '$PROFILE'. Reports in: $REPORT_DIR"
