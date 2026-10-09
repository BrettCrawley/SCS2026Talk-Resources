#!/usr/bin/env bash
# Run the matrix. Phase v1 for every cell, then optionally the validation phase.
#
#   REPS=3 bin/run-all.sh
#   REPS=1 CELLS="run3 run4" bin/run-all.sh
#
# Sequential on purpose: parallel runs make wall-clock timings useless and risk
# rate limiting skewing one cell against another.

set -euo pipefail
HARNESS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Model strings and caps come from config/models.env so that a later terminal,
# in particular the one running the --validate phase, uses the same values as
# the batch. Anything already exported wins, so a single run can be overridden
# without editing the file.
if [[ -f "$HARNESS/config/models.env" ]]; then
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# || -z "${line// }" ]] && continue
    key="${line%%=*}"; key="${key// }"
    [[ -n "${!key:-}" ]] && continue          # already exported, leave it
    eval "export $line"
  done < "$HARNESS/config/models.env"
fi
REPS="${REPS:-3}"
CELLS="${CELLS:-$(grep -v '^#' "$HARNESS/config/cells.txt" | grep -v '^[[:space:]]*$' | cut -d'|' -f1 | tr '\n' ' ')}"

: "${FRONTIER_MODEL:?not set. Copy config/models.env.example to config/models.env and fill it in}"
: "${CHEAP_MODEL:?not set. Copy config/models.env.example to config/models.env and fill it in}"

mkdir -p "$HARNESS/results"

{ echo "batch_started=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "frontier_model=$FRONTIER_MODEL"; echo "cheap_model=$CHEAP_MODEL"
  echo "reps=$REPS"; echo "cells=$CELLS"
  echo "max_budget_usd=${MAX_BUDGET_USD:-unset}"; echo "max_turns=${MAX_TURNS:-60}"
  echo "claude_version=$(claude --version 2>/dev/null || echo unknown)"; } > "$HARNESS/results/RUN_METADATA.txt"

# The exact settings this batch ran under, kept with the results.
cp "$HARNESS/config/models.env" "$HARNESS/results/models.env.used" 2>/dev/null || true

# CELLS accepts spaces or commas.
CELLS="${CELLS//,/ }"

# A cell that produces nothing is retried once, because the usual cause is
# transient and re-running is the fix. Set RETRY_EMPTY=0 to disable.
RETRY_EMPTY="${RETRY_EMPTY:-1}"
FAILED=""

for cell in $CELLS; do
  for rep in $(seq 1 "$REPS"); do
    echo "--- $cell v1 rep$rep ---"
    # Invoked through bash so a lost executable bit, which is what downloading
    # or copying off some filesystems does, is not a confusing failure.
    # `if` rather than `cmd; rc=$?`, because errexit would abort the batch on a
    # cell that exits non-zero, which is exactly the case we want to handle.
    if bash "$HARNESS/bin/run-cell.sh" "$cell" "$rep"; then rc=0; else rc=$?; fi

    if [[ $rc -eq 3 && "$RETRY_EMPTY" == "1" ]]; then
      echo "  produced nothing; retrying once" >&2
      if bash "$HARNESS/bin/run-cell.sh" "$cell" "$rep"; then rc=0; else rc=$?; fi
    fi

    [[ $rc -ne 0 ]] && FAILED+=" $cell/rep$rep"
  done
done

echo
echo "=== batch summary ==="
for cell in $CELLS; do
  for rep in $(seq 1 "$REPS"); do
    m="$HARNESS/results/$cell/v1/rep$rep/metadata.txt"
    if [[ -f "$m" ]]; then
      st=$(grep '^artefact_status=' "$m" | cut -d= -f2)
      n=$(grep '^artefact_files_copied=' "$m" | cut -d= -f2)
      w=$(grep '^wall_seconds=' "$m" | cut -d= -f2)
      printf '  %-6s rep%-2s %-10s %3s docs  %5ss\n' "$cell" "$rep" "${st:-?}" "${n:-0}" "${w:-?}"
    else
      printf '  %-6s rep%-2s %-10s\n' "$cell" "$rep" "no result"
    fi
  done
done

if [[ -n "$FAILED" ]]; then
  echo
  echo "Cells needing attention:$FAILED"
fi

echo
echo "Phase v1 complete. Synthesise the sessions, then feed them back:"
echo "  bash bin/run-session.sh       # phase A-prime: a transcript per pack"
echo "  bash bin/run-validation.sh    # phase B: v1.1"
echo
echo "Re-run run-session.sh whenever you re-run v1. A transcript describes a session"
echo "held about one specific pack, and nothing in the document will tell you it is stale."
echo "Then: python3 bin/scorecard.py     # the numbers"
echo "      bash bin/publish.sh          # the documents, browsable, for showing people"
