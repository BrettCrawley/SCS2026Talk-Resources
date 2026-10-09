#!/usr/bin/env bash
# Synthesise the validation transcript for every cell that has a v1 pack.
#
#   bin/run-session.sh                  # all cells, against rep1
#   bin/run-session.sh --rep 2          # against rep2 instead
#   CELLS="run3,run4" bin/run-session.sh
#
# Phase A-prime. Runs between phase A and phase B and must be re-run whenever
# phase A is, because a transcript describes a session held about one specific
# pack: re-running v1 makes every existing transcript stale, and nothing in the
# document itself will tell you that.
#
# Always executes on FRONTIER_MODEL regardless of the cell's own model. The
# transcript represents the room, and the room is constant across cells.

set -euo pipefail
HARNESS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$HARNESS/config/models.env" ]]; then
  set -a; . "$HARNESS/config/models.env"; set +a
fi

REP=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rep) REP="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "${CELLS:-}" ]]; then
  CELLS=$(grep -v '^#' "$HARNESS/config/cells.txt" | grep -v '^[[:space:]]*$' | cut -d'|' -f1 | tr '\n' ' ')
fi
CELLS="${CELLS//,/ }"

RAN=""; SKIPPED=""; FAILED=""

for cell in $CELLS; do
  src="$HARNESS/results/$cell/v1/rep$REP"

  if [[ ! -d "$src/artefacts" ]]; then
    echo "skip $cell: no v1 rep$REP results"
    SKIPPED+=" $cell(no-run)"; continue
  fi

  docs=$(find "$src/artefacts" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$docs" -eq 0 ]]; then
    echo "skip $cell: v1 rep$REP produced no pack to hold a session about"
    SKIPPED+=" $cell(nothing-to-review)"; continue
  fi

  echo "--- $cell session rep$REP  ($docs documents) ---"
  if bash "$HARNESS/bin/run-cell.sh" "$cell" "$REP" --session "$src/artefacts"; then
    # run-cell.sh gates on transcript.md itself and exits 4 without it, so this
    # is belt and braces for a caller that reaches here some other way.
    if [[ -f "$HARNESS/results/$cell/v1.0s/rep$REP/artefacts/transcript.md" ]]; then
      RAN+=" $cell"
    else
      echo "FATAL $cell: session completed but no transcript.md was written." >&2
      echo "       Expected results/$cell/v1.0s/rep$REP/artefacts/transcript.md" >&2
      FAILED+=" $cell(no-transcript)"
    fi
  else
    rc=$?
    echo "FATAL $cell: session exited $rc; no usable transcript." >&2
    echo "       See results/$cell/v1.0s/rep$REP/stderr.log" >&2
    FAILED+=" $cell(exit-$rc)"
  fi
done

echo
echo "=== session summary ==="
for cell in $CELLS; do
  mf="$HARNESS/results/$cell/v1.0s/rep$REP/artefacts/session-manifest.json"
  if [[ -f "$mf" ]]; then
    python3 - "$cell" "$mf" <<'PY'
import json, sys
cell, path = sys.argv[1], sys.argv[2]
try:
    m = json.load(open(path))
except Exception as e:
    print(f'  {cell:<6} manifest unreadable: {e}'); raise SystemExit
facts = m.get('human_facts', [])
by = {}
for f in facts:
    by[f.get('outcome', '?')] = by.get(f.get('outcome', '?'), 0) + 1
print(f"  {cell:<6} contributions={m.get('room_contribution_count','?'):<3} "
      f"wrong_closures={len(m.get('wrong_closures',[])):<2} "
      f"drift={len(m.get('drift_confrontations',[])):<2} "
      f"assumptions={len(m.get('divergent_assumptions',[])):<2} "
      f"{m.get('duration_minutes','?')}min  "
      + " ".join(f"{k}:{v}" for k, v in sorted(by.items())))
PY
  else
    printf '  %-6s %s\n' "$cell" "not run"
  fi
done

if [[ -n "$SKIPPED" ]]; then
  echo
  echo "Skipped:$SKIPPED"
fi

if [[ -n "$FAILED" ]]; then
  echo
  echo "FAILED:$FAILED" >&2
  echo "A cell with no transcript cannot be validated, and phase B will refuse to" >&2
  echo "run for it. Fix the cause and re-run the session for those cells." >&2
  exit 1
fi

echo
echo "Then: bash bin/run-validation.sh   # feeds these transcripts back as v1.1"
