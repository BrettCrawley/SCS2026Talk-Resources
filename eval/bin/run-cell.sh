#!/usr/bin/env bash
# Run one cell, one repetition, in an isolated workspace.
#
#   bin/run-cell.sh <cell_id> <rep>
#   bin/run-cell.sh <cell_id> <rep> --session  <pack_dir>
#   bin/run-cell.sh <cell_id> <rep> --validate <pack_dir> <transcript_file>
#   bin/run-cell.sh <cell_id> <rep> --directed <pack_dir> <focus_file>
#
# Each run gets a freshly built workspace containing only that cell's inputs and
# skills. Nothing is inherited from your normal working directory, so ambient
# CLAUDE.md rules, plugins and MCP servers cannot silently differ between cells.
#
# The prompt used is copied into the results, because the prompts are part of
# what gets shown to attendees.

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
CELL="${1:?cell id required}"
REP="${2:?repetition number required}"
MODE="${3:-}"

# Fail loudly if a helper is missing. Silently degrading here would report a
# run as empty when the real problem is an incomplete copy of the harness.
for dep in bin/extract_docs.py; do
  [[ -f "$HARNESS/$dep" ]] || { echo "missing $dep. Re-extract the harness." >&2; exit 1; }
done

MAX_TURNS="${MAX_TURNS:-60}"
MAX_BUDGET_USD="${MAX_BUDGET_USD:-}"

# ------------------------------------------------------------------ resolve cell
# Must come before the capability probe: the probe is engine-specific.
LINE=$(grep -v '^#' "$HARNESS/config/cells.txt" | grep -v '^[[:space:]]*$' | awk -F'|' -v c="$CELL" '$1==c')
[[ -n "$LINE" ]] || { echo "unknown cell: $CELL" >&2; exit 1; }
CTX=$(echo "$LINE" | cut -d'|' -f2)
SKILL_SET=$(echo "$LINE" | cut -d'|' -f3)
MODEL_VAR=$(echo "$LINE" | cut -d'|' -f4)
MODEL="${!MODEL_VAR:?set $MODEL_VAR in config/models.env}"
ENGINE=$(echo "$LINE" | cut -d'|' -f6); ENGINE="${ENGINE:-claude}"

# ---------------------------------------------------------------- capability probe
# claude --help does not list every flag, so absence from --help proves nothing.
# Probe once, cache the answer, and build the argument list from what actually
# works on this machine rather than from what the documentation says.
CAPS="$HARNESS/config/.capabilities"

probe_flag() {
  local flag="$1" value="$2"
  if claude -p "reply with ok" "$flag" "$value" --output-format json >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Cursor invokes as `agent`, or `cursor-agent` depending on how it was installed.
cursor_bin() {
  if command -v agent >/dev/null 2>&1; then echo agent
  elif command -v cursor-agent >/dev/null 2>&1; then echo cursor-agent
  else echo ""; fi
}

if [[ "$ENGINE" == "claude" ]] && [[ ! -f "$CAPS" || -n "${REPROBE:-}" ]]; then
  echo "probing CLI capabilities (once; delete config/.capabilities to redo)" >&2
  : > "$CAPS"
  probe_flag --max-turns 1        && echo "max_turns=yes"       >> "$CAPS" || echo "max_turns=no"       >> "$CAPS"
  probe_flag --max-budget-usd 0.5 && echo "max_budget_usd=yes"  >> "$CAPS" || echo "max_budget_usd=no"  >> "$CAPS"

  probe_flag --disallowedTools WebFetch && echo "disallowed_tools=yes" >> "$CAPS" || echo "disallowed_tools=no" >> "$CAPS"
  cat "$CAPS" >&2
fi

if [[ -f "$CAPS" ]]; then
  HAS_MAX_TURNS=$(grep '^max_turns=' "$CAPS" | cut -d= -f2 || echo no)
  HAS_BUDGET=$(grep '^max_budget_usd=' "$CAPS" | cut -d= -f2 || echo no)
  HAS_DISALLOW=$(grep '^disallowed_tools=' "$CAPS" | cut -d= -f2 || echo no)
else
  HAS_MAX_TURNS=no; HAS_BUDGET=no; HAS_DISALLOW=no   # cursor-only run, never probed
fi

if [[ "$MODE" == "--session" ]]; then
  # Phase A-prime: synthesise the validation session transcript for a pack.
  # Fresh invocation with no memory of phase A, so it reads the pack as the room
  # would. It is given the session specification as well, because the room knows
  # things the pack cannot contain.
  PACK_DIR="${4:?pack directory required}"
  PHASE="v1.0s"
  PROMPT_FILE="$HARNESS/prompts/phase-a2-session.md"
  # The transcript represents the room, and the room is constant across cells.
  # That is what makes the five transcripts comparable. If run 3's session were
  # written by the cheap model the variable under test would leak into the
  # instrument, so this phase always runs on the frontier model whatever the
  # cell's own model is.
  MODEL="${FRONTIER_MODEL:?set FRONTIER_MODEL in config/models.env}"
elif [[ "$MODE" == "--directed" ]]; then
  PACK_DIR="${4:?pack directory required}"; FOCUS_FILE="${5:?focus file required}"
  [[ -f "$FOCUS_FILE" ]] || { echo "no focus file at $FOCUS_FILE" >&2; exit 1; }
  PHASE="v1.2"
  PROMPT_FILE="$HARNESS/prompts/phase-c-directed.md"
elif [[ "$MODE" == "--validate" ]]; then
  PACK_DIR="${4:?pack directory required}"; TRANSCRIPT="${5:?transcript required}"
  PHASE="v1.1"
  if [[ "$SKILL_SET" == "weak" ]]; then
    PROMPT_FILE="$HARNESS/prompts/phase-b-validation-weak.md"
  else
    PROMPT_FILE="$HARNESS/prompts/phase-b-validation.md"
  fi
else
  PHASE="v1"
  PROMPT_FILE="$HARNESS/prompts/$(echo "$LINE" | cut -d'|' -f5)"
fi

OUT="$HARNESS/results/$CELL/$PHASE/rep$REP"
WORK="$OUT/workspace"
rm -rf "$OUT"; mkdir -p "$WORK/input" "$WORK/output" "$WORK/.claude/skills" "$WORK/.cursor/skills"

if [[ "$PHASE" == "v1.0s" ]]; then
  # The pack is what the room read. session-spec.md is what the room knows that
  # the pack cannot contain. Nothing else is in scope: no context bundle, no
  # repository, no code map.
  mkdir -p "$WORK/input/pack"
  cp -r "$PACK_DIR"/. "$WORK/input/pack/"
  cp "$HARNESS/validation/session-spec.md" "$WORK/input/session-spec.md"
  cp -r "$HARNESS/skills/session/." "$WORK/.claude/skills/"
  cp -r "$HARNESS/skills/session/." "$WORK/.cursor/skills/"

elif [[ "$PHASE" == "v1.2" ]]; then
  # The directed pass needs the pack and the material it was built from, so it
  # can go back to primary sources rather than reasoning about its own output.
  mkdir -p "$WORK/input/pack" "$WORK/input/context"
  cp -r "$PACK_DIR"/. "$WORK/input/pack/"
  cp -r "$HARNESS/contexts/$CTX"/. "$WORK/input/context/" 2>/dev/null || true
  cp "$FOCUS_FILE" "$OUT/focus.md"

  cp -r "$PACK_DIR"/. "$WORK/output/" 2>/dev/null || true
  find "$WORK/output" -name '_*' -delete 2>/dev/null || true
  ( cd "$WORK/output" && find . -type f -name '*.md' -exec md5sum {} \; 2>/dev/null \
      | sort > "$OUT/pack-before.md5" ) || true

elif [[ "$PHASE" == "v1.1" ]]; then
  mkdir -p "$WORK/input/pack" "$WORK/input/transcript"
  cp -r "$PACK_DIR"/. "$WORK/input/pack/"
  cp "$TRANSCRIPT" "$WORK/input/transcript/"

  # Seed the output with the pack being revised. A model asked to "update" a set
  # of documents may write only the ones it changed, which would leave v1.1 as a
  # fragment rather than a pack. Seeding means anything it does not touch is
  # still there, and a checksum comparison afterwards shows what it did touch.
  cp -r "$PACK_DIR"/. "$WORK/output/" 2>/dev/null || true
  find "$WORK/output" -name '_*' -delete 2>/dev/null || true
  ( cd "$WORK/output" && find . -type f -name '*.md' -exec md5sum {} \; 2>/dev/null \
      | sort > "$OUT/pack-before.md5" ) || true
else
  cp -r "$HARNESS/contexts/$CTX"/. "$WORK/input/"
fi

# Cursor reads .claude/skills as well as .cursor/skills, so one copy would do.
# Both are populated so the workspace is explicit about what each engine sees.
if [[ "$SKILL_SET" == "weak" ]]; then
  cp -r "$HARNESS/skills/weak/." "$WORK/.claude/skills/"
  cp -r "$HARNESS/skills/weak/." "$WORK/.cursor/skills/"
else
  # Strong cells load the user-level skills, but the sandbox denies reads outside
  # the workspace, so the skill's references/ and scripts/ were unreachable: every
  # strong run to date worked from the embedded deck alone, could not read
  # house-style.md or the ATLAS catalogue, and could not execute
  # check_deliverable.py — each run says so in its Limitations. Pre-populate the
  # skill's own documented fallback location so the full material is inside the
  # workspace. This also pins the reference version each run actually saw.
  TM_SKILL="$HOME/.claude/skills/threat-modeling"
  if [[ -d "$TM_SKILL/references" ]]; then
    mkdir -p "$WORK/.threat-modeling-refs/scripts"
    cp -r "$TM_SKILL/references/." "$WORK/.threat-modeling-refs/"
    cp "$TM_SKILL/scripts/"*.py "$WORK/.threat-modeling-refs/scripts/" 2>/dev/null || true
  fi
fi
echo '{ "enableAllProjectMcpServers": false }' > "$WORK/.claude/settings.json"

# The prompt body is everything after the '---' separator in the prompt document.
#
# Template substitution: {{CELL}}, used by phase-a2-session.md, and {{MODEL}}, which no
# prompt currently uses — kept so that re-adding it works rather than silently not.
#
# Nothing about the model needs to be in a prompt. result.json records what actually ran
# and scorecard.py compares it against what the cell asked for; outside the harness the
# threat-modeling skill's Stop hook checks the attribution against the session transcript,
# which records the model per message and so also catches a mid-session model switch —
# something no substituted value can express.
PROMPT=$(awk 'f{print} /^---$/{f=1}' "$PROMPT_FILE" | sed -e "s|{{MODEL}}|$MODEL|g" -e "s|{{CELL}}|$CELL|g")
sed -e "s|{{MODEL}}|$MODEL|g" -e "s|{{CELL}}|$CELL|g" "$PROMPT_FILE" > "$OUT/prompt.md"

# The directed pass carries its focus text in from the brief. Substituted with
# a python pass rather than sed, because the brief contains slashes and
# newlines that would break a sed replacement.
if [[ "$PHASE" == "v1.2" ]]; then
  PROMPT=$(FOCUS_FILE="$FOCUS_FILE" PROMPT_TEXT="$PROMPT" python3 -c '
import os, re, sys
brief = open(os.environ["FOCUS_FILE"]).read()
parts = re.split(r"^---$", brief, flags=re.MULTILINE)
focus = (parts[1] if len(parts) > 1 else brief).strip()
sys.stdout.write(os.environ["PROMPT_TEXT"].replace("{{FOCUS}}", focus))')
  printf '%s\n' "$PROMPT" > "$OUT/prompt.md"
fi

# Compute first, write once. Holding a redirect open across several command
# substitutions is fragile on some filesystems, and a multi-line tool version
# would corrupt the file if echoed straight into it.
META_PROMPT_FILE=$(basename "$PROMPT_FILE")
META_TURNS=$([[ "$HAS_MAX_TURNS" == "yes" ]] && echo "$MAX_TURNS" || echo "unsupported")
META_STARTED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
META_FILES=$(find "$WORK/input" -type f | wc -l | tr -d ' ')
META_KB=$(du -sk "$WORK/input" | cut -f1 | tr -d ' ')

if [[ "$ENGINE" == "cursor" ]]; then
  META_TOOL=$( { "$(cursor_bin)" --version 2>/dev/null || echo unknown; } | head -1 | tr -d '\r' | cut -c1-60 )
else
  META_TOOL=$( { claude --version 2>/dev/null || echo unknown; } | head -1 | tr -d '\r' | cut -c1-60 )
fi
# A version string should be short. Anything longer is not a version.
[[ ${#META_TOOL} -gt 40 ]] && META_TOOL="unparsed"

printf '%s\n' \
  "cell=$CELL" \
  "phase=$PHASE" \
  "rep=$REP" \
  "engine=$ENGINE" \
  "model=$MODEL" \
  "skill_set=$SKILL_SET" \
  "context=$CTX" \
  "prompt_file=$META_PROMPT_FILE" \
  "focus_file=$([[ -n "${FOCUS_FILE:-}" ]] && basename "$FOCUS_FILE" || echo "")" \
  "max_turns=$META_TURNS" \
  "max_budget_usd=${MAX_BUDGET_USD:-unset}" \
  "started=$META_STARTED" \
  "tool_version=$META_TOOL" \
  "input_files=$META_FILES" \
  "input_kb=$META_KB" \
  > "$OUT/metadata.txt"

# Build the invocation for the engine this cell uses.
if [[ "$ENGINE" == "cursor" ]]; then
  BIN=$(cursor_bin)
  [[ -n "$BIN" ]] || { echo "cursor engine requested but neither 'agent' nor 'cursor-agent' is on PATH" >&2; exit 1; }
  # Cursor documents stream-json for print mode. CURSOR_OUTPUT_FORMAT lets you
  # switch if your build supports plain json; probe once and set it in models.env.
  ARGS=( -p "$PROMPT" --model "$MODEL" --output-format "${CURSOR_OUTPUT_FORMAT:-stream-json}" )
  [[ -n "${CURSOR_EXTRA_ARGS:-}" ]] && ARGS+=( ${CURSOR_EXTRA_ARGS} )
  echo "  note: no budget cap is applied on the cursor engine" >&2
else
  BIN=claude
  # acceptEdits, deliberately not bypassPermissions. The cells read untrusted
  # content — the repository under analysis, and in real use Jira/Confluence
  # tickets — so a prompt injection in that content must not be able to run an
  # arbitrary Bash command or reach the network. acceptEdits auto-approves the
  # model's writes to its own workspace and nothing else; every Bash call is left
  # to be denied under `-p`, which is the safe default here. The one Bash tool the
  # pipeline genuinely needs — the deliverable checker — is run by the harness
  # after the model finishes (see below), deterministically and outside the reach
  # of anything in the content. References are pre-copied into the workspace, so
  # no network is needed either.
  ARGS=( -p "$PROMPT" --model "$MODEL" --output-format json --permission-mode acceptEdits )
  # Deny the model's own web tools so injected content cannot exfiltrate through
  # them. Names two tools explicitly, so MCP connectors (mcp__*) are untouched —
  # autonomous Jira/Confluence retrieval in interactive real use still works.
  [[ "$HAS_DISALLOW" == "yes" ]] && ARGS+=( --disallowedTools WebFetch WebSearch ) \
    || echo "  warning: --disallowedTools unsupported; WebFetch/WebSearch remain enabled (injection egress path)" >&2
  [[ "$HAS_MAX_TURNS" == "yes" ]] && ARGS+=( --max-turns "$MAX_TURNS" )
  [[ "$HAS_BUDGET" == "yes" && -n "$MAX_BUDGET_USD" ]] && ARGS+=( --max-budget-usd "$MAX_BUDGET_USD" )
  if [[ "$HAS_MAX_TURNS" != "yes" && -z "$MAX_BUDGET_USD" ]]; then
    echo "  warning: no turn or budget cap available; this run is unbounded" >&2
  fi
fi

# Record the invocation with the prompt referenced rather than inlined, so the
# file stays readable. prompt.md in this directory is the exact text used.
{
  CMD="$BIN"
  for a in "${ARGS[@]}"; do
    if [[ "$a" == "$PROMPT" ]]; then CMD+=" \"\$(cat prompt.md-body)\""
    else CMD+=" $a"; fi
  done
  printf '%s\n' "$CMD"
} > "$OUT/command.txt"
awk 'f{print} /^---$/{f=1}' "$PROMPT_FILE" > "$OUT/prompt.md-body"

START=$(date +%s)
set +e
( cd "$WORK" && "$BIN" "${ARGS[@]}" > "$OUT/result.json" 2> "$OUT/stderr.log" )
STATUS=$?; set -e
END=$(date +%s)

META_FINISHED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf '%s\n' "exit_status=$STATUS" "wall_seconds=$((END-START))" "finished=$META_FINISHED" \
  >> "$OUT/metadata.txt"

# ---------------------------------------------------------------- finalise
# Every cell tidies up after itself and records a verdict. A run either ends
# with its documents collected, or with a status saying plainly why it did not,
# so a batch never leaves ambiguous wreckage for someone to interpret later.
#
# Four outcomes, in order of preference:
#   ok         documents were where the prompt asked for them
#   recovered  documents were written elsewhere in the workspace
#   extracted  the model answered instead of writing; documents pulled from the text
#   empty      nothing usable; the cell needs re-running

mkdir -p "$OUT/artefacts"
count_files() { find "$1" -type f 2>/dev/null | wc -l | tr -d ' '; }

WS_COUNT=$(count_files "$WORK/output")
cp -r "$WORK/output/." "$OUT/artefacts/" 2>"$OUT/copy.err" || true
AR_COUNT=$(count_files "$OUT/artefacts")

# Retry once after a settle if the copy came up short.
if [[ "$WS_COUNT" -gt 0 && "$AR_COUNT" -lt "$WS_COUNT" ]]; then
  sync 2>/dev/null || true; sleep 2
  cp -r "$WORK/output/." "$OUT/artefacts/" 2>>"$OUT/copy.err" || true
  AR_COUNT=$(count_files "$OUT/artefacts")
fi

ART_STATUS=ok
ART_NOTE=""

if [[ "$WS_COUNT" -gt 0 && "$AR_COUNT" -lt "$WS_COUNT" ]]; then
  ART_STATUS=partial
  ART_NOTE="copied $AR_COUNT of $WS_COUNT; originals remain in workspace/output"
fi

if [[ "$AR_COUNT" -eq 0 ]]; then
  # Nothing in ./output. Sweep the workspace, excluding the inputs.
  # Exclude .threat-modeling-refs: the harness puts the skill's own references there, so
  # sweeping it turns "the run produced nothing" into "12 artefacts recovered" and the
  # gate then checks a blank template. A recovered reference file is not a deliverable.
  STRAY=$(find "$WORK" -name '*.md' -type f \
            -not -path "$WORK/input/*" -not -path "$WORK/.claude/*" \
            -not -path "$WORK/.cursor/*" -not -path "$WORK/.threat-modeling-refs/*" \
            2>/dev/null || true)
  if [[ -n "$STRAY" ]]; then
    while IFS= read -r f; do cp "$f" "$OUT/artefacts/" 2>/dev/null || true; done <<< "$STRAY"
    AR_COUNT=$(count_files "$OUT/artefacts")
    ART_STATUS=recovered
    ART_NOTE="documents were written outside ./output"
  fi
fi

if [[ "$AR_COUNT" -eq 0 ]]; then
  # Last resort: the documents may be in the response rather than on disk.
  EXTRACTED=$(python3 "$HARNESS/bin/extract_docs.py" "$OUT/result.json" "$OUT/artefacts" 2>/dev/null || echo 0)
  if [[ "$EXTRACTED" -gt 0 ]]; then
    AR_COUNT=$(count_files "$OUT/artefacts")
    ART_STATUS=extracted
    ART_NOTE="model answered instead of writing; $EXTRACTED document(s) recovered from the response"
  else
    ART_STATUS=empty
    if [[ -f "$OUT/artefacts/_response_not_documents.txt" ]]; then
      ART_NOTE="the response was prose about the task, not the documents; kept as _response_not_documents.txt. Re-run needed"
    else
      ART_NOTE="nothing written and no response text; this cell needs re-running"
    fi
  fi
fi

printf '%s\n' \
  "workspace_output_files=$WS_COUNT" \
  "artefact_files_copied=$AR_COUNT" \
  "artefact_status=$ART_STATUS" \
  "artefact_note=$ART_NOTE" \
  >> "$OUT/metadata.txt"

# Deliverable check, run by the harness rather than by the model. The model
# cannot run it itself — Bash is denied under -p, deliberately (see the ARGS
# block) — and it should not: a checker the model runs is a checker a prompt
# injection in the content can persuade it to skip or misreport. Running it here,
# after the model finishes, makes it deterministic and out of the content's
# reach. It gates nothing automatically; it records a status so audit.py and the
# scorecard can flag a pack that does not meet house style.
CHECKER="$HOME/.claude/skills/threat-modeling/scripts/check_deliverable.py"
CANDCHK="$HOME/.claude/skills/threat-modeling/scripts/check_candidates.py"
if [[ "$ENGINE" == "claude" && "$SKILL_SET" != "weak" && -f "$CHECKER" ]]; then
  # Two-phase generation writes a phase-1 candidate register alongside the threat model.
  # It matches the same globs but is not a deliverable: gating it against house style
  # produces a page of failures about a document it is not, and would read as a
  # regression in the eval. Exclude it here and check it with its own checker below.
  # `sort` makes the pick deterministic — bare `head -1` on find is filesystem-ordered,
  # so two machines could otherwise check different files from the same artefacts.
  TM=$(find "$OUT/artefacts" -maxdepth 1 -type f \
         \( -name '*threat-model*.md' -o -name '06-*.md' \) \
         ! -name '*-candidates.md' ! -name '*_candidates.md' \
         ! -name '*template*.md' 2>/dev/null | sort | head -1)
  CAND=$(find "$OUT/artefacts" -maxdepth 1 -type f \
         \( -name '*-candidates.md' -o -name '*_candidates.md' \) 2>/dev/null | sort | head -1)

  # Phase 1: was elicitation exhaustive — every prompt of every in-scope instrument
  # walked? Recorded separately from the house-style check because the two fail for
  # different reasons: a gap here is a missing threat, a gap there is a missing example.
  if [[ -n "$CAND" && -f "$CANDCHK" ]]; then
    if python3 "$CANDCHK" "$CAND" > "$OUT/candidates-check.txt" 2>&1; then
      CAND_STATUS=pass; CAND_FAILS=0
    else
      CAND_STATUS=fail
      CAND_FAILS=$(grep -c '^FAIL' "$OUT/candidates-check.txt" 2>/dev/null || echo 0)
    fi
    printf '%s\n' "candidates_check=$CAND_STATUS" "candidates_check_fails=$CAND_FAILS" \
      >> "$OUT/metadata.txt"
    echo "  candidate register: $CAND_STATUS ($CAND_FAILS FAIL) — see candidates-check.txt" >&2
  else
    printf '%s\n' "candidates_check=absent" >> "$OUT/metadata.txt"
  fi

  if [[ -n "$TM" && -f "$TM" ]]; then
    CHECK_OUT="$OUT/deliverable-check.txt"
    # With a register present, also verify phase 2 wrote up exactly what phase 1 found:
    # nothing silently dropped, nothing appearing that never went through elicitation.
    CHECK_ARGS=( "$CHECKER" "$TM" )
    [[ -n "$CAND" ]] && CHECK_ARGS+=( --candidates "$CAND" )
    if python3 "${CHECK_ARGS[@]}" > "$CHECK_OUT" 2>&1; then
      CHECK_STATUS=pass; CHECK_FAILS=0
    else
      CHECK_STATUS=fail
      CHECK_FAILS=$(grep -c '^FAIL' "$CHECK_OUT" 2>/dev/null || echo 0)
    fi
    printf '%s\n' "deliverable_check=$CHECK_STATUS" "deliverable_check_fails=$CHECK_FAILS" \
      >> "$OUT/metadata.txt"
    echo "  deliverable check: $CHECK_STATUS ($CHECK_FAILS FAIL) — see $(basename "$CHECK_OUT")" >&2
  else
    printf '%s\n' "deliverable_check=skipped" "deliverable_check_note=no threat-model document found" \
      >> "$OUT/metadata.txt"
  fi
fi

# For a validation run, say which documents the session actually changed. That
# is the evidence of what the room did, and it is the thing worth showing.
if [[ "$PHASE" == "v1.1" || "$PHASE" == "v1.2" ]] && [[ -f "$OUT/pack-before.md5" ]]; then
  ( cd "$OUT/artefacts" && find . -type f -name '*.md' -exec md5sum {} \; 2>/dev/null \
      | sort > "$OUT/pack-after.md5" ) || true
  BEFORE_N=$(wc -l < "$OUT/pack-before.md5" | tr -d ' ')
  AFTER_N=$(wc -l < "$OUT/pack-after.md5" | tr -d ' ')

  # A document whose checksum is unchanged was not rewritten. It is a verbatim
  # v1 copy sitting in a v1.1 pack: usable, but still headed with the old
  # version and carrying no delta table. Name those explicitly rather than let
  # the seeding disguise which documents the run actually produced.
  CARRIED=$(comm -12 <(sort "$OUT/pack-before.md5") <(sort "$OUT/pack-after.md5") \
              | sed 's|^[a-f0-9]*  \./||' | sort)
  CARRIED_N=$(printf '%s' "$CARRIED" | grep -c . || true)
  MODIFIED_N=$(( BEFORE_N - CARRIED_N ))
  ADDED=$(( AFTER_N - BEFORE_N )); (( ADDED < 0 )) && ADDED=0

  printf '%s\n' "pack_documents_before=$BEFORE_N" "pack_documents_after=$AFTER_N" \
                 "documents_modified=$MODIFIED_N" "documents_added=$ADDED" \
                 "documents_carried_forward=$CARRIED_N" >> "$OUT/metadata.txt"

  if [[ "$CARRIED_N" -gt 0 ]]; then
    {
      echo "Documents carried forward unchanged from the previous version."
      echo
      echo "These were seeded into the output directory before the run and the"
      echo "model did not rewrite them. They are verbatim copies: the version"
      echo "header and any delta table still refer to the previous version, and"
      echo "they may contradict the revised documents alongside them."
      echo
      printf '%s\n' "$CARRIED"
    } > "$OUT/artefacts/_carried_forward.txt"
    echo "  session rewrote $MODIFIED_N of $BEFORE_N documents, added $ADDED," >&2
    echo "  carried $CARRIED_N forward unchanged (see artefacts/_carried_forward.txt)" >&2
  else
    echo "  session rewrote all $BEFORE_N documents, added $ADDED" >&2
  fi
fi

[[ -s "$OUT/copy.err" ]] || rm -f "$OUT/copy.err"

case "$ART_STATUS" in
  ok)        SUMMARY="$AR_COUNT artefacts" ;;
  recovered) SUMMARY="$AR_COUNT artefacts (recovered from outside ./output)" ;;
  extracted) SUMMARY="$AR_COUNT artefacts (extracted from response text)" ;;
  partial)   SUMMARY="$AR_COUNT of $WS_COUNT artefacts, INCOMPLETE" ;;
  empty)     SUMMARY="NO ARTEFACTS, needs re-running" ;;
esac

echo "$CELL $PHASE rep$REP: exit $STATUS, $((END-START))s, $SUMMARY"
[[ -n "$ART_NOTE" ]] && echo "  $ART_NOTE" >&2

# Phase A-prime has exactly one deliverable that anything downstream reads, and
# it is transcript.md. Files landing in artefacts/ is not the same as the
# transcript existing: the session-manifest alone, or prose about the session,
# would otherwise pass as a successful run and leave phase B with nothing to be
# pointed at. Fail here, where the cause is still on screen, rather than letting
# run-validation.sh discover it a phase later.
if [[ "$PHASE" == "v1.0s" && ! -f "$OUT/artefacts/transcript.md" ]]; then
  printf '%s\n' "session_transcript=missing" >> "$OUT/metadata.txt"
  echo "  FATAL: phase A-prime wrote no transcript.md" >&2
  echo "  expected $OUT/artefacts/transcript.md" >&2
  FOUND=$(find "$OUT/artefacts" -type f -exec basename {} \; 2>/dev/null | sort | tr '\n' ' ')
  echo "  artefacts present: ${FOUND:-none}" >&2
  echo "  see $OUT/stderr.log and $OUT/result.json" >&2
  exit 4
fi
if [[ "$PHASE" == "v1.0s" ]]; then
  printf '%s\n' "session_transcript=present" >> "$OUT/metadata.txt"
fi

[[ "$ART_STATUS" == "empty" ]] && exit 3
true
[[ $STATUS -eq 0 ]] || echo "  see $OUT/stderr.log" >&2
