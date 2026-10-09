#!/usr/bin/env bash
# Assemble the run outputs into something you can show people.
#
#   bin/publish.sh
#
# The results tree is evidence: workspaces, raw JSON, stderr, metadata. Useful
# for proving a comparison was sound, useless for showing an audience.
#
# This writes reports/ instead: the markdown documents, flat, with an index per
# run carrying the configuration and the numbers, and a top-level index listing
# every run side by side. Nothing here is generated content; the documents are
# copied verbatim from the run that produced them.

set -euo pipefail
HARNESS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS="$HARNESS/results"
REPORTS="$HARNESS/reports"

[[ -d "$RESULTS" ]] || { echo "no results directory; run a batch first" >&2; exit 1; }

# A missing key must return empty, not fail. Under pipefail a grep that matches
# nothing would otherwise abort the whole script through set -e.
meta() { grep "^$2=" "$1/metadata.txt" 2>/dev/null | cut -d= -f2- | head -1 || true; }

jf() {  # jf <result.json> <field>
  python3 - "$1" "$2" <<'PY' 2>/dev/null || echo ""
import json, sys
try:
    raw = open(sys.argv[1]).read().strip()
    try:
        d = json.loads(raw)
    except json.JSONDecodeError:
        d = {}
        for line in raw.splitlines():
            try:
                o = json.loads(line)
            except Exception:
                continue
            if isinstance(o, dict) and (o.get("type") == "result" or "total_cost_usd" in o):
                d = o
    v = d.get(sys.argv[2], "")
    print(round(v, 2) if isinstance(v, float) else v)
except Exception:
    print("")
PY
}

rm -rf "$REPORTS"; mkdir -p "$REPORTS"

TOP="$REPORTS/index.md"
ROWS=$(mktemp)

count=0
for cell_dir in "$RESULTS"/*/; do
  cell=$(basename "$cell_dir")
  [[ -d "$cell_dir" ]] || continue
  for phase_dir in "$cell_dir"*/; do
    phase=$(basename "$phase_dir")
    [[ -d "$phase_dir" ]] || continue
    for rep_dir in "$phase_dir"rep*/; do
      [[ -d "$rep_dir/artefacts" ]] || continue
      docs=$(find "$rep_dir/artefacts" -name '*.md' | wc -l | tr -d ' ')
      [[ "$docs" -gt 0 ]] || continue

      rep=$(basename "$rep_dir")
      label="$cell-$phase-$rep"
      dest="$REPORTS/$label"
      mkdir -p "$dest"
      find "$rep_dir/artefacts" -name '*.md' -exec cp {} "$dest/" \;

      ctx=$(meta "$rep_dir" context);   skill=$(meta "$rep_dir" skill_set)
      model=$(meta "$rep_dir" model);   engine=$(meta "$rep_dir" engine)
      wall=$(meta "$rep_dir" wall_seconds); prompt_file=$(meta "$rep_dir" prompt_file)
      cost=$(jf "$rep_dir/result.json" total_cost_usd)
      turns=$(jf "$rep_dir/result.json" num_turns)

      cp "$rep_dir/prompt.md" "$dest/_prompt.md" 2>/dev/null || true

      {
        echo "# $cell $phase $rep"
        echo
        echo "| | |"
        echo "|---|---|"
        echo "| Context | ${ctx:-?} |"
        echo "| Skill | ${skill:-?} |"
        echo "| Model | ${model:-?} |"
        echo "| Engine | ${engine:-claude} |"
        echo "| Prompt | ${prompt_file:-?} |"
        echo "| Turns | ${turns:-?} |"
        echo "| Duration | ${wall:-?} s |"
        echo "| Cost | $([[ -n "$cost" ]] && echo "\$$cost" || echo "not recorded") |"
        echo
        echo "## Documents"
        echo
        carried="$rep_dir/artefacts/_carried_forward.txt"
        for f in "$dest"/*.md; do
          b=$(basename "$f")
          [[ "$b" == "index.md" || "$b" == "_prompt.md" ]] && continue
          words=$(wc -w < "$f" | tr -d ' ')
          if [[ -f "$carried" ]] && grep -qx "$b" "$carried"; then
            echo "- [$b]($b) — $words words — **carried forward unchanged**"
          else
            echo "- [$b]($b) — $words words"
          fi
        done
        if [[ -f "$carried" ]]; then
          echo
          echo "Documents marked *carried forward* were not rewritten by this run."
          echo "They are verbatim copies from the previous version and still carry"
          echo "its version header."
        fi
        echo
        echo "The exact prompt used is in [_prompt.md](_prompt.md)."
        echo
        echo "Evidence for this run, including the raw output and the workspace"
        echo "the run could see, is in \`results/$cell/$phase/$rep/\`."
      } > "$dest/index.md"

      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$cell" "$phase" "$rep" "$label" "${ctx:-?}" "${skill:-?}" "${model:-?}" \
        "$docs" "${cost:-}" "${wall:-}" >> "$ROWS"
      count=$((count+1))
    done
  done
done

python3 "$HARNESS/bin/build_index.py" "$ROWS" "$TOP"
rm -f "$ROWS"

echo "published $count run(s) to reports/"
echo "start at reports/index.md"
