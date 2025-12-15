#!/usr/bin/env bash
# scripts/lib.sh

append_error_log() {
  if [ -z "${ERRORS_PATH:-}" ]; then
    return 0
  fi
  local ctx="${1:-unknown}"
  local f="${2:-}"
  if [ -n "${f:-}" ] && [ -s "$f" ]; then
    printf '\n[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$ctx" >> "$ERRORS_PATH" || true
    cat "$f" >> "$ERRORS_PATH" || true
    printf '\n' >> "$ERRORS_PATH" || true
  fi
}

with_error_log() {
  local ctx="${1:-command}"
  shift || true

  if [ -z "${ERRORS_PATH:-}" ]; then
    "$@"
    return $?
  fi

  local err
  err="$(mktemp)"

  if "$@" 2>"$err"; then
    rm -f "$err" || true
    return 0
  fi

  append_error_log "$ctx" "$err"
  rm -f "$err" || true
  echo "❌ Erro ao tentar executar: $ctx. Obtenha os logs completos em '$ERRORS_PATH'." >&2
  return 1
}
