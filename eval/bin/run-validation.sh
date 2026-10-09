#!/usr/bin/env bash
# Run the validation phase for every cell that is ready for it.
#
#   bin/run-validation.sh                  # all cells, against rep1
#   bin/run-validation.sh --rep 2          # against rep2 instead
#   CELLS="run3,run4" bin/run-validation.sh
#
# For each cell it pairs the v1 documents with the transcript phase A-prime
# synthesised for that pack and runs the feedback phase, producing v1.1.
#
# There is exactly one transcript for a cell: the one at
# results/<cell>/v1.0s/rep<n>/artefacts/transcript.md. If it is absent the
# session has not been held for this pack, so this script holds it first rather
# than validating against nothing. There is no template to fall back to, by
# design: a transcript that was not written against the pack in front of it
# invalidates the v1.1 it produces, and nothing in the document says so.
#
# A cell whose session cannot be synthesised is a hard failure, not a skip. Its
# v1.1 would be unsound to compare, which is worse than not having one.
#
# One validation per cell by default. A transcript records a session held about
# one specific pack, so feeding it back against a different repetition would be
# describing a document nobody read.

set -euo pipefail
HARNESS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$HARNESS/config/models.env" ]]; then
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# || -z "${line// }" ]] && continue
    key="${line%%=*}"; key="${key// }"
    [[ -n "${!key:-}" ]] && continue
    eval "export $line"
  done < "$HARNESS/config/models.env"
fi

REP=1
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rep) REP="${2:?--rep needs a number}"; shift 2 ;;
    -*)    echo "unknown option: $1" >&2; exit 1 ;;
    *)     ARGS+=("$1"); shift ;;
  esac
done

CELLS="${CELLS:-${ARGS[*]:-}}"
if [[ -z "$CELLS" ]]; then
  CELLS=$(grep -v '^#' "$HARNESS/config/cells.txt" | grep -v '^[[:space:]]*$' | cut -d'|' -f1 | tr '\n' ' ')
fi
CELLS="${CELLS//,/ }"

RAN=""; SKIPPED=""; FAILED=""; SYNTHESISED=""

for cell in $CELLS; do
  src="$HARNESS/results/$cell/v1/rep$REP"

  if [[ ! -d "$src/artefacts" ]]; then
    echo "skip $cell: no v1 rep$REP results"
    SKIPPED+=" $cell(no-run)"; continue
  fi

  status=$(grep '^artefact_status=' "$src/metadata.txt" 2>/dev/null | cut -d= -f2 || echo "")
  docs=$(find "$src/artefacts" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$docs" -eq 0 || "$status" == "empty" ]]; then
    echo "skip $cell: v1 rep$REP produced nothing to validate"
    SKIPPED+=" $cell(nothing-to-validate)"; continue
  fi

  # Hold the session now if it has not been held for this pack. Phase A-prime is
  # cheap next to re-running phase A and it is a precondition, not an option.
  transcript="$HARNESS/results/$cell/v1.0s/rep$REP/artefacts/transcript.md"
  if [[ ! -f "$transcript" ]]; then
    echo "--- $cell v1.0s rep$REP  (no transcript for this pack; synthesising it first) ---"
    session_rc=0
    if bash "$HARNESS/bin/run-cell.sh" "$cell" "$REP" --session "$src/artefacts"; then
      :
    else
      session_rc=$?
    fi

    if [[ "$session_rc" -ne 0 ]]; then
      echo "FATAL $cell: session phase exited $session_rc. No transcript, so no v1.1." >&2
      echo "       See results/$cell/v1.0s/rep$REP/stderr.log" >&2
      FAILED+=" $cell(session-exit-$session_rc)"; continue
    fi
    if [[ ! -f "$transcript" ]]; then
      echo "FATAL $cell: session phase succeeded but wrote no transcript." >&2
      echo "       Expected results/$cell/v1.0s/rep$REP/artefacts/transcript.md" >&2
      FAILED+=" $cell(no-transcript)"; continue
    fi
    SYNTHESISED+=" $cell"
  fi

  echo "--- $cell v1.1 rep$REP  ($docs documents) ---"
  if bash "$HARNESS/bin/run-cell.sh" "$cell" "$REP" --validate "$src/artefacts" "$transcript"; then
    RAN+=" $cell"
  else
    rc=$?
    echo "  $cell validation exited $rc" >&2
    FAILED+=" $cell"
  fi
done

echo
echo "=== validation summary ==="
for cell in $CELLS; do
  m="$HARNESS/results/$cell/v1.1/rep$REP/metadata.txt"
  if [[ -f "$m" ]]; then
    st=$(grep '^artefact_status=' "$m" | cut -d= -f2)
    n=$(grep '^artefact_files_copied=' "$m" | cut -d= -f2)
    w=$(grep '^wall_seconds=' "$m" | cut -d= -f2)
    printf '  %-6s %-10s %3s docs  %5ss\n' "$cell" "${st:-?}" "${n:-0}" "${w:-?}"
  else
    printf '  %-6s %s\n' "$cell" "not run"
  fi
done

if [[ -n "$SYNTHESISED" ]]; then
  echo
  echo "Sessions synthesised on the way through:$SYNTHESISED"
fi
if [[ -n "$SKIPPED" ]]; then
  echo
  echo "Skipped:$SKIPPED"
fi

if [[ -n "$FAILED" ]]; then
  echo
  echo "FAILED:$FAILED" >&2
  echo "These cells have no sound v1.1. Fix the cause and re-run them before" >&2
  echo "putting any number from this batch next to another cell's." >&2
  exit 1
fi

echo
echo "Then: python3 bin/scorecard.py     # the numbers"
echo "      bash bin/publish.sh          # v1 and v1.1 side by side, browsable"
