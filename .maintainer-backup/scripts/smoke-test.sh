#!/usr/bin/env bash
# Smoke-test the ReductrAI Docker stack using the shared service manifests.
# Requires Docker + docker compose CLI, curl, and jq.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_CMD=${COMPOSE_CMD:-"docker compose"}

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ docker CLI not found" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "❌ curl is required" >&2
  exit 1
fi

wait_for_http() {
  local name="$1" url="$2" timeout="${3:-60}"
  local start time_elapsed
  start=$(date +%s)
  until curl -fsS "$url" >/dev/null 2>&1; do
    sleep 2
    time_elapsed=$(( $(date +%s) - start ))
    if (( time_elapsed > timeout )); then
      echo "❌ $name did not become healthy at $url (timeout ${timeout}s)" >&2
      return 1
    fi
  done
  echo "✅ $name reachable at $url"
}

stack_up() {
  local profiles=()
  if (($# > 0)); then
    profiles=("$@")
  fi
  local label="(none)"
  if (( ${#profiles[@]} > 0 )); then
    label="${profiles[*]}"
  fi
  echo "▶️  Starting compose stack (profiles: ${label})"
  (cd "$COMPOSE_DIR" && $COMPOSE_CMD down --volumes --remove-orphans >/dev/null 2>&1 || true)
  if (( ${#profiles[@]} )); then
    local profile_flags=()
    for profile in "${profiles[@]}"; do
      profile_flags+=(--profile "$profile")
    done
    (cd "$COMPOSE_DIR" && $COMPOSE_CMD "${profile_flags[@]}" up -d)
  else
    (cd "$COMPOSE_DIR" && $COMPOSE_CMD up -d)
  fi
}

stack_down() {
  echo "⏹  Stopping compose stack"
  (cd "$COMPOSE_DIR" && $COMPOSE_CMD down --volumes --remove-orphans) || true
}

trap stack_down EXIT

echo "=== Scenario 1: Proxy only ==="
stack_up
wait_for_http "Proxy" "http://localhost:8080/health"

echo "=== Scenario 2: UI profile (dashboard) ==="
stack_up ui
wait_for_http "Proxy" "http://localhost:8080/health"
wait_for_http "Dashboard" "http://localhost:5173"

echo "=== Scenario 3: AI profile (Ollama + AI Query) ==="
stack_up ai
wait_for_http "Proxy" "http://localhost:8080/health"
wait_for_http "AI Query" "http://localhost:8081/health"
wait_for_http "Ollama" "http://localhost:11434/api/tags"

echo "=== Scenario 4: Full stack (UI + AI) ==="
stack_up ui ai
wait_for_http "Proxy" "http://localhost:8080/health"
wait_for_http "Dashboard" "http://localhost:5173"
wait_for_http "AI Query" "http://localhost:8081/health"
wait_for_http "Ollama" "http://localhost:11434/api/tags"

echo "🎉 All smoke tests passed"
