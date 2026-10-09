#!/usr/bin/env bash
# Run the directed pass for every cell that has a focus brief.
#
#   bin/run-directed.sh                  # every cell with a brief, against rep1
#   bin/run-directed.sh run4             # one cell
#   bin/run-directed.sh --rep 2
#   bin/run-directed.sh --from v1        # direct at v1 instead of v1.1
#
# A brief is directed/<cell>-*.md. The pass runs against the most recent phase
# of that cell, which is v1.1 where a validation has happened and v1 otherwise,
# and produces v1.2.
#

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

REP=1; FROM=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rep)  REP="${2:?--rep needs a number}"; shift 2 ;;
    --from) FROM="${2:?--from needs a phase}"; shift 2 ;;
    -*)     echo "unknown option: $1" >&2; exit 1 ;;
    *)      ARGS+=("$1"); shift ;;
  esac
done

CELLS="${CELLS:-${ARGS[*]:-}}"
if [[ -z "$CELLS" ]]; then
  CELLS=$(grep -v '^#' "$HARNESS/config/cells.txt" | grep -v '^[[:space:]]*$' | cut -d'|' -f1 | tr '\n' ' ')
fi
CELLS="${CELLS//,/ }"

SKIPPED=""; FAILED=""

for cell in $CELLS; do
  brief=$(find "$HARNESS/directed" -maxdepth 1 -name "$cell-*.md" 2>/dev/null | sort | head -1 || true)
  if [[ -z "$brief" ]]; then
    echo "skip $cell: no brief at directed/$cell-*.md"
    SKIPPED+=" $cell(no-brief)"; continue
  fi

  # Direct at the most recent phase unless told otherwise.
  if [[ -n "$FROM" ]]; then
    phase="$FROM"
  elif [[ -d "$HARNESS/results/$cell/v1.1/rep$REP/artefacts" ]]; then
    phase="v1.1"
  else
    phase="v1"
  fi

  src="$HARNESS/results/$cell/$phase/rep$REP/artefacts"
  docs=$(find "$src" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$docs" -eq 0 ]]; then
    echo "skip $cell: $phase rep$REP has no documents to work from"
    SKIPPED+=" $cell(nothing-to-direct-at)"; continue
  fi

  echo "--- $cell v1.2 rep$REP  (from $phase, $docs documents, brief $(basename "$brief")) ---"
  if bash "$HARNESS/bin/run-cell.sh" "$cell" "$REP" --directed "$src" "$brief"; then
    :
  else
    echo "  $cell directed pass exited $?" >&2
    FAILED+=" $cell"
  fi
done

echo
echo "=== directed pass summary ==="
for cell in $CELLS; do
  m="$HARNESS/results/$cell/v1.2/rep$REP/metadata.txt"
  if [[ -f "$m" ]]; then
    st=$(grep '^artefact_status=' "$m" | cut -d= -f2 || true)
    mod=$(grep '^documents_modified=' "$m" | cut -d= -f2 || true)
    cf=$(grep '^documents_carried_forward=' "$m" | cut -d= -f2 || true)
    w=$(grep '^wall_seconds=' "$m" | cut -d= -f2 || true)
    printf '  %-6s %-10s %s modified, %s unchanged  %5ss\n' \
      "$cell" "${st:-?}" "${mod:-?}" "${cf:-?}" "${w:-?}"
  else
    printf '  %-6s %s\n' "$cell" "not run"
  fi
done

[[ -n "$SKIPPED" ]] && { echo; echo "Skipped:$SKIPPED"; }
[[ -n "$FAILED" ]]  && { echo; echo "Failed:$FAILED"; }

echo
echo "The number that matters is documents_modified. A directed pass that changed"
echo "nothing means the first pass had already covered that area, which is a"
echo "result worth reporting rather than a failed run."
echo
echo "Then: python3 bin/audit.py · python3 bin/scorecard.py · bash bin/publish.sh"
