#!/usr/bin/env bash
# Apply the finalise logic to results that were produced before it existed.
#
#   bin/backfill.sh                       # report on everything, touch nothing
#   bin/backfill.sh --apply               # do it
#   bin/backfill.sh run3 --apply          # one cell, all its phases and reps
#   bin/backfill.sh run3/v1 --apply       # one cell and phase
#   bin/backfill.sh run3/v1/rep2 --apply  # one specific run
#
# Naming a target lets you backfill a finished cell while another is still
# running. A run that is still in progress is skipped and reported, because
# reading a half-written workspace would mark a live run as empty.
#
# Runs made with the earlier runner only tried ./output and gave up. The
# workspace and result.json were kept, so documents written elsewhere, or
# returned in the response instead of written, can still be recovered without
# re-running anything.
#
# Idempotent: a run already marked with an artefact_status is left alone unless
# --force is given.

set -euo pipefail
HARNESS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS="$HARNESS/results"

APPLY=0; FORCE=0; TARGETS=()
for a in "$@"; do
  case "$a" in
    --apply) APPLY=1 ;;
    --force) FORCE=1 ;;
    -*)      echo "unknown option: $a" >&2; exit 1 ;;
    *)       TARGETS+=("${a%/}") ;;
  esac
done

# Build the list of run directories to consider.
DIRS=()
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  while IFS= read -r d; do DIRS+=("$d"); done \
    < <(find "$RESULTS" -mindepth 3 -maxdepth 3 -type d -name 'rep*' | sort)
else
  for spec in "${TARGETS[@]}"; do
    base="$RESULTS/$spec"
    if [[ ! -e "$base" ]]; then
      echo "no such target: $spec" >&2; exit 1
    fi
    if [[ "$(basename "$base")" == rep* ]]; then
      DIRS+=("$base")
    else
      while IFS= read -r d; do DIRS+=("$d"); done \
        < <(find "$base" -mindepth 1 -maxdepth 2 -type d -name 'rep*' | sort)
    fi
  done
fi

[[ ${#DIRS[@]} -gt 0 ]] || { echo "nothing matched" >&2; exit 1; }

# Fail loudly if a helper is missing. Silently degrading here would report a
# run as empty when the real problem is an incomplete copy of the harness.
for dep in bin/extract_docs.py; do
  [[ -f "$HARNESS/$dep" ]] || { echo "missing $dep. Re-extract the harness." >&2; exit 1; }
done

[[ -d "$RESULTS" ]] || { echo "no results directory" >&2; exit 1; }
[[ $APPLY -eq 1 ]] || echo "DRY RUN. Nothing will be changed. Add --apply to write."
echo

count_files() { find "$1" -type f 2>/dev/null | wc -l | tr -d ' '; }

declare -i n_ok=0 n_rec=0 n_ext=0 n_empty=0 n_skip=0
NEEDS_RERUN=""

declare -i n_live=0

for rep_dir in "${DIRS[@]}"; do
  [[ -d "$rep_dir" ]] || continue
  meta="$rep_dir/metadata.txt"
  [[ -f "$meta" ]] || continue

  # A finished run has recorded its exit status. Anything without one is either
  # still running or died mid-flight, and reading its workspace now would give a
  # wrong answer. Skip it and say so.
  if ! grep -q '^exit_status=' "$meta"; then
    lbl=$(sed -n 's/^cell=//p' "$meta")/$(sed -n 's/^phase=//p' "$meta")/rep$(sed -n 's/^rep=//p' "$meta")
    printf '  %-22s %-10s (no exit_status yet: still running, or it died)\n' "$lbl" "in-progress"
    n_live+=1
    continue
  fi

  label=$(sed -n 's/^cell=//p' "$meta")/$(sed -n 's/^phase=//p' "$meta")/rep$(sed -n 's/^rep=//p' "$meta")

  if grep -q '^artefact_status=' "$meta" && [[ $FORCE -eq 0 ]]; then
    n_skip+=1
    continue
  fi

  art="$rep_dir/artefacts"; ws="$rep_dir/workspace"
  mkdir -p "$art"

  # --force means re-derive, so clear what a previous pass put here. Everything
  # in artefacts is a copy of the workspace or of the response, so this loses
  # nothing, provided at least one of those still exists to rebuild from.
  if [[ $FORCE -eq 1 && $APPLY -eq 1 ]]; then
    if [[ -d "$ws" || -f "$rep_dir/result.json" ]]; then
      rm -rf "$art"; mkdir -p "$art"
    else
      echo "  refusing to clear artefacts: no workspace or result.json to rebuild from" >&2
    fi
  fi

  status=ok; note=""

  # Anything already present that was derived, rather than copied from the
  # workspace, should not be counted as a document on a re-run.
  find "$art" -maxdepth 1 -name '_response_not_documents.txt' -delete 2>/dev/null || true

  # 1. the directory the prompt asked for
  if [[ $(count_files "$art") -eq 0 && -d "$ws/output" ]]; then
    [[ $APPLY -eq 1 ]] && cp -r "$ws/output/." "$art/" 2>/dev/null || true
    [[ $APPLY -eq 0 ]] && ws_n=$(count_files "$ws/output") || ws_n=$(count_files "$art")
  fi

  now=$(count_files "$art")
  [[ $APPLY -eq 0 && -d "$ws/output" ]] && now=$(count_files "$ws/output")

  # 2. anywhere else in the workspace, excluding the inputs we supplied
  if [[ "$now" -eq 0 && -d "$ws" ]]; then
    stray=$(find "$ws" -name '*.md' -type f \
              -not -path "$ws/input/*" -not -path "$ws/.claude/*" \
              -not -path "$ws/.cursor/*" 2>/dev/null || true)
    if [[ -n "$stray" ]]; then
      status=recovered
      note="documents were written outside ./output"
      if [[ $APPLY -eq 1 ]]; then
        while IFS= read -r f; do cp "$f" "$art/" 2>/dev/null || true; done <<< "$stray"
        now=$(count_files "$art")
      else
        now=$(wc -l <<< "$stray" | tr -d ' ')
      fi
    fi
  fi

  # 3. the response text
  if [[ "$now" -eq 0 && -f "$rep_dir/result.json" ]]; then
    if [[ $APPLY -eq 1 ]]; then
      got=$(python3 "$HARNESS/bin/extract_docs.py" "$rep_dir/result.json" "$art" 2>/dev/null || echo 0)
    else
      tmp=$(mktemp -d)
      got=$(python3 "$HARNESS/bin/extract_docs.py" "$rep_dir/result.json" "$tmp" 2>/dev/null || echo 0)
      rm -rf "$tmp"
    fi
    if [[ "$got" -gt 0 ]]; then
      status=extracted
      note="model answered instead of writing; $got document(s) recovered from the response"
      now=$got
    fi
  fi

  if [[ "$now" -eq 0 ]]; then
    status=empty
    if [[ -f "$art/_response_not_documents.txt" ]]; then
      note="the response was prose about the task, not the documents; kept as _response_not_documents.txt. Re-run needed"
    else
      note="nothing written and no response text; this cell needs re-running"
    fi
    NEEDS_RERUN+=" $label"
  fi

  case "$status" in
    ok) n_ok+=1 ;; recovered) n_rec+=1 ;; extracted) n_ext+=1 ;; empty) n_empty+=1 ;;
  esac

  printf '  %-22s %-10s %3s docs' "$label" "$status" "$now"
  [[ -n "$note" ]] && printf '  (%s)' "$note"
  printf '\n'

  if [[ $APPLY -eq 1 ]]; then
    # Replace rather than append, so re-running does not stack duplicate keys.
    grep -v '^artefact_status=\|^artefact_note=\|^artefact_files_copied=' "$meta" > "$meta.tmp"
    printf '%s\n' "artefact_files_copied=$now" "artefact_status=$status" \
                  "artefact_note=$note" >> "$meta.tmp"
    mv "$meta.tmp" "$meta"
  fi
done

echo
echo "ok $n_ok, recovered $n_rec, extracted $n_ext, empty $n_empty, already done $n_skip, in progress $n_live"

if [[ $n_live -gt 0 ]]; then
  echo
  echo "Skipped $n_live run(s) still in progress. Re-run backfill on those once they finish."
fi

if [[ -n "$NEEDS_RERUN" ]]; then
  echo
  echo "Nothing to recover for:$NEEDS_RERUN"
  echo "Those cells produced no files and no usable text. Re-run them:"
  for c in $NEEDS_RERUN; do
    cell="${c%%/*}"; rep="${c##*rep}"
    echo "  bin/run-cell.sh $cell $rep"
  done
fi

if [[ $APPLY -eq 0 ]]; then
  echo
  echo "Dry run. Re-run with --apply to write these changes."
fi
