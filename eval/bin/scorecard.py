#!/usr/bin/env python3
"""Build the evaluation scorecard from harness results.

Two classes of metric, kept separate on purpose:

  MECHANICAL  read from Claude Code's JSON output and the run metadata.
              Cost, tokens, turns, duration, input size. Trustworthy.

  HEURISTIC   counted from the produced markdown with regular expressions.
              Finding counts, severity mix, diagram counts, section presence.
              Directionally useful, close enough to compare cells, not exact.
              Spot-check before putting any of it on a slide.

Qualitative rows from the run 1 evaluation report are emitted blank for
manual completion. They need judgement, not counting.

Usage: python3 bin/scorecard.py [--results DIR] [--out FILE]
"""

import argparse
import csv
import json
import re
import statistics
import sys
from pathlib import Path

HEURISTIC_PATTERNS = {
    "gap_ids": r"\bG-\d{2,}\b",
    "requirement_ids": r"\bSEC-\d{3}\b",
    "adr_count": r"^#{2,4}\s*ADR-\d+",
    "mermaid_blocks": r"^```mermaid",
    "critical_mentions": r"\*\*Critical\*\*|\bCritical\b",
    "high_mentions": r"\bHigh\b",
    "medium_mentions": r"\bMedium\b",
}

SECTION_MARKERS = {
    "has_srtm": r"Security Requirements Traceability Matrix|\bSRTM\b",
    "has_abuse_cases": r"[Aa]buse case",
    "has_privacy": r"LINDDUN|GDPR|DPIA|Art\.\s*\d+",
    "has_supply_chain": r"supply.chain|AI-BOM|SBOM",
    "has_agentic": r"agentic|prompt injection|MCP",
    "has_cloud": r"\bcloud\b|Kubernetes|container",
    "has_limitations": r"[Ll]imitation|not given|were not supplied|inferred rather than",
    "declares_inputs": r"context (I |we )?(was|were) given|[Aa]ssumptions and context|[Ii]nputs (supplied|provided)",
}

QUALITATIVE_ROWS = [
    "per_chunk_trust_reframe_reached",
    "escalation_chain_depth",
    "injection_channels_identified",
    "diagram2_elements_reached",
    "diagram3_controls_reached",
    "names_specific_components",
    "mitigation_architecture_completeness",
    "post_validation_net_movement",
]


def read_metadata(path: Path) -> dict:
    meta = {}
    if path.exists():
        for line in path.read_text().splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                meta[k.strip()] = v.strip()
    return meta


def read_usage(path: Path) -> dict:
    """Pull cost, tokens and run integrity out of --output-format json.

    Field names verified against Claude Code 2.1.252. Anything not found stays
    absent and is reported as such rather than silently becoming zero.
    """
    if not path.exists():
        return {}

    raw = path.read_text().strip()
    if not raw:
        return {"parse_error": "empty"}

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        # stream-json: one JSON object per line. Cursor's print mode emits this,
        # and Claude Code does too when asked for it. The final object carries
        # the result; earlier lines are events.
        events = []
        for line in raw.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
        if not events:
            return {"parse_error": "true"}
        terminal = [e for e in events
                    if isinstance(e, dict) and (e.get("type") == "result" or "total_cost_usd" in e)]
        data = terminal[-1] if terminal else events[-1]
        data = dict(data)
        data["_stream_events"] = len(events)

    out = {}
    if "_stream_events" in data:
        out["stream_events"] = data["_stream_events"]

    # --- cost and shape -----------------------------------------------------
    for key in ("total_cost_usd", "cost_usd"):
        if isinstance(data.get(key), (int, float)):
            out["cost_usd"] = round(float(data[key]), 6)
            break
    if isinstance(data.get("duration_ms"), (int, float)):
        out["api_duration_s"] = round(data["duration_ms"] / 1000, 1)
    if isinstance(data.get("duration_api_ms"), (int, float)):
        out["model_time_s"] = round(data["duration_api_ms"] / 1000, 1)
    if isinstance(data.get("num_turns"), int):
        out["turns"] = data["num_turns"]

    # --- run integrity ------------------------------------------------------
    # A run can exit zero, report is_error, and produce no artefacts. Or it can
    # complete having been refused permission to write. Both look like success
    # from the shell, so record them explicitly.
    out["is_error"] = str(data.get("is_error", "")).lower() or "unknown"
    out["subtype"] = data.get("subtype", "")
    out["terminal_reason"] = data.get("terminal_reason", "")
    denials = data.get("permission_denials")
    if isinstance(denials, list):
        out["permission_denials"] = len(denials)

    # --- token usage --------------------------------------------------------
    usage = data.get("usage")
    if isinstance(usage, dict) and "input_tokens" in usage:
        out["input_tokens"] = usage.get("input_tokens")
        out["output_tokens"] = usage.get("output_tokens")
        out["cache_read_tokens"] = usage.get("cache_read_input_tokens")
        out["cache_creation_tokens"] = usage.get("cache_creation_input_tokens")
        # Everything the model actually had to look at this run.
        parts = [usage.get(k) or 0 for k in
                 ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")]
        out["total_input_tokens"] = sum(parts)

    # --- which model actually ran -------------------------------------------
    # The integrity check that matters most. If the cheap cell ran on the
    # frontier model, or a fallback kicked in, the comparison is void and
    # nothing else in the output would tell you.
    mu = data.get("modelUsage")
    if isinstance(mu, dict) and mu:
        keys = sorted(mu.keys())
        out["model_keys"] = "|".join(keys)
        canon = sorted({v.get("canonicalModel", "") for v in mu.values() if isinstance(v, dict)} - {""})
        out["model_actual"] = "|".join(canon)
        out["models_used_count"] = len(keys)
    return out


def analyse_artefacts(directory: Path) -> dict:
    if not directory.exists():
        return {"artefact_files": 0}

    files = sorted(p for p in directory.rglob("*.md"))
    corpus = "\n".join(p.read_text(errors="replace") for p in files)

    result = {
        "artefact_files": len(files),
        "artefact_words": len(corpus.split()),
    }
    for name, pattern in HEURISTIC_PATTERNS.items():
        matches = re.findall(pattern, corpus, re.MULTILINE)
        if name.endswith("_ids"):
            result[name] = len(set(matches))
        else:
            result[name] = len(matches)
    for name, pattern in SECTION_MARKERS.items():
        result[name] = "yes" if re.search(pattern, corpus, re.MULTILINE) else "no"
    return result


def read_check(path: Path, prefix: str) -> dict:
    """Detail from a checker's output that metadata.txt does not carry.

    metadata.txt records pass/fail and a FAIL count. For the candidate register the
    interesting number is different: how many prompts were never walked. A run that
    skipped prompts has not measured the same surface as its sibling reps, so a
    diff between them is comparing different experiments.
    """
    out = {}
    if not path.exists():
        return out
    text = path.read_text(errors="replace")
    unwalked = sum(int(m) for m in re.findall(r'(\d+) prompt\(s\) never walked', text))
    if unwalked:
        out[f"{prefix}_unwalked"] = str(unwalked)
    m = re.search(r'(\d+) candidate findings across .*?, (\d+) prompts walked', text)
    if m:
        out[f"{prefix}_findings"] = m.group(1)
        out[f"{prefix}_prompts"] = m.group(2)
    return out


def collect(results_dir: Path) -> list:
    rows = []
    for cell_dir in sorted(p for p in results_dir.iterdir() if p.is_dir()):
        for phase_dir in sorted(p for p in cell_dir.iterdir() if p.is_dir()):
          for rep_dir in sorted(phase_dir.glob("rep*")):
              meta = read_metadata(rep_dir / "metadata.txt")
              row = {
                  "cell": cell_dir.name,
                  "phase": phase_dir.name,
                  "rep": rep_dir.name.replace("rep", ""),
                  "engine": meta.get("engine", "claude"),
                "model": meta.get("model", ""),
                  "skill_set": meta.get("skill_set", ""),
                  "context": Path(meta.get("context", "")).name,
                  "exit_status": meta.get("exit_status", ""),
                "tool_version": meta.get("tool_version", ""),
                "artefact_status": meta.get("artefact_status", ""),
                "documents_modified": meta.get("documents_modified", ""),
                "documents_added": meta.get("documents_added", ""),
                "documents_carried_forward": meta.get("documents_carried_forward", ""),
                "artefact_note": meta.get("artefact_note", ""),
                "workspace_output_files": meta.get("workspace_output_files", ""),
                "result_text_chars": meta.get("result_text_chars", ""),
                  "wall_seconds": meta.get("wall_seconds", ""),
                  "input_files": meta.get("input_files", ""),
                  "input_kb": meta.get("input_kb", ""),
                # House-style gate and two-phase elicitation. Two separate signals:
                # deliverable_check answers "was the write-up to house style",
                # candidates_check answers "was elicitation exhaustive". A gap in the
                # first is a missing example; a gap in the second is a missing threat.
                "deliverable_check": meta.get("deliverable_check", ""),
                "deliverable_check_fails": meta.get("deliverable_check_fails", ""),
                "candidates_check": meta.get("candidates_check", ""),
                "candidates_check_fails": meta.get("candidates_check_fails", ""),
              }
              row.update(read_usage(rep_dir / "result.json"))
              row.update(analyse_artefacts(rep_dir / "artefacts"))
              row.update(read_check(rep_dir / "candidates-check.txt", "candidates"))
              for q in QUALITATIVE_ROWS:
                  row.setdefault(q, "")
              rows.append(row)
    return rows


def summarise(rows: list) -> list:
    """Per-cell aggregate with spread, because non-determinism is the point."""
    numeric = ["cost_usd", "wall_seconds", "input_tokens", "output_tokens",
               "gap_ids", "mermaid_blocks", "artefact_words", "turns",
               # Spread on these is the point: a candidate-finding count that is
               # stable across reps while diff_candidates.py reports divergence is
               # the signature of sampled rather than determined elicitation.
               "deliverable_check_fails", "candidates_check_fails", "candidates_findings"]
    cells = {}
    for r in rows:
        cells.setdefault((r["cell"], r.get("phase","v1")), []).append(r)

    out = []
    for (cell, phase), reps in sorted(cells.items()):
        agg = {"cell": cell, "phase": phase, "reps": len(reps), "model": reps[0].get("model", "")}
        for field in numeric:
            vals = []
            for r in reps:
                try:
                    vals.append(float(r.get(field)))
                except (TypeError, ValueError):
                    continue
            if vals:
                agg[f"{field}_median"] = round(statistics.median(vals), 4)
                agg[f"{field}_min"] = round(min(vals), 4)
                agg[f"{field}_max"] = round(max(vals), 4)
            else:
                agg[f"{field}_median"] = agg[f"{field}_min"] = agg[f"{field}_max"] = ""
        out.append(agg)
    return out


def write_csv(path: Path, rows: list) -> None:
    if not rows:
        print(f"no rows for {path.name}", file=sys.stderr)
        return
    fields = []
    for r in rows:
        for k in r:
            if k not in fields:
                fields.append(k)
    with path.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)
    print(f"wrote {path} ({len(rows)} rows)")


def main() -> int:
    here = Path(__file__).resolve().parent.parent
    ap = argparse.ArgumentParser()
    ap.add_argument("--results", default=str(here / "results"))
    ap.add_argument("--out", default=str(here / "results" / "scorecard.csv"))
    args = ap.parse_args()

    results_dir = Path(args.results)
    if not results_dir.exists():
        print(f"no results directory at {results_dir}", file=sys.stderr)
        return 1

    rows = collect(results_dir)
    if not rows:
        print("no completed runs found", file=sys.stderr)
        return 1

    # --out names a file, but a directory is the natural thing to type and used to
    # fail with a bare IsADirectoryError from deep inside pathlib. Accept both.
    out = Path(args.out)
    if out.is_dir():
        out = out / "scorecard.csv"
    if not out.parent.exists():
        print(f"no directory at {out.parent} to write {out.name} into", file=sys.stderr)
        return 1
    write_csv(out, rows)
    write_csv(out.with_name("scorecard-summary.csv"), summarise(rows))

    def label(r):
        return f'{r["cell"]}/{r.get("phase", "v1")}/rep{r["rep"]}'

    missing = [label(r) for r in rows if not r.get("cost_usd")]
    if missing:
        print("\nNo cost recorded for: " + ", ".join(missing))
        print("Check the shape of result.json and extend read_usage() to match.")

    # Integrity checks. These invalidate a comparison rather than merely
    # degrading it, so they are errors rather than notes.
    problems, notes = [], []
    for r in rows:
        if r.get("is_error") == "true":
            problems.append(f'{label(r)}: is_error true ({r.get("terminal_reason", "?")})')
        if r.get("permission_denials"):
            problems.append(f'{label(r)}: {r["permission_denials"]} permission denial(s)')
        if r.get("models_used_count", 1) and int(r.get("models_used_count") or 1) > 1:
            problems.append(f'{label(r)}: more than one model ran ({r.get("model_keys")})')
        req, act = (r.get("model") or "").strip(), (r.get("model_actual") or "").strip()
        if req and act and req not in act and act not in req:
            problems.append(f'{label(r)}: asked for "{req}", ran "{act}"')
        cf = r.get("documents_carried_forward") or ""
        if cf.isdigit() and int(cf) > 0:
            notes.append(f'{label(r)}: {cf} document(s) carried forward unchanged from the '
                         'previous version. They are verbatim copies and still carry the old '
                         'version header. See artefacts/_carried_forward.txt')
        if r.get("engine") == "cursor" and not act:
            notes.append(f'{label(r)}: cursor engine does not report the model that ran; '
                         'record it by hand from the CLI output')
        # Elicitation completeness. Un-walked prompts are an integrity problem rather
        # than a note: reps that walked different prompt sets are different experiments,
        # so a diff between them measures the harness, not the model.
        uw = r.get("candidates_unwalked") or ""
        if uw.isdigit() and int(uw) > 0:
            problems.append(f'{label(r)}: phase 1 left {uw} prompt(s) unwalked — this rep did '
                            'not cover the same surface as its siblings; see candidates-check.txt')
        cc = r.get("candidates_check", "")
        if cc == "fail" and not (uw.isdigit() and int(uw) > 0):
            notes.append(f'{label(r)}: candidate register failed validation '
                         f'({r.get("candidates_check_fails")} FAIL), but every prompt was walked — '
                         'the elicitation is complete, the record is malformed')
        elif cc == "absent" and r.get("skill_set") != "weak" and r.get("engine") == "claude":
            notes.append(f'{label(r)}: no candidate register — this run was single-pass, so it '
                         'cannot be compared with diff_candidates.py')
        if r.get("deliverable_check") == "fail":
            notes.append(f'{label(r)}: threat model does not meet house style '
                         f'({r.get("deliverable_check_fails")} FAIL); see deliverable-check.txt')

        st = r.get("artefact_status", "")
        if st == "empty":
            problems.append(f'{label(r)}: {r.get("artefact_note") or "no artefacts"}')
        elif st == "partial":
            problems.append(f'{label(r)}: {r.get("artefact_note")}')
        elif st in ("recovered", "extracted"):
            notes.append(f'{label(r)}: {r.get("artefact_note")}. '
                         'Recovered, and worth recording as an instruction-following '
                         'observation about this configuration')

    if problems:
        print("\nIntegrity problems. A comparison built on these is not sound:")
        for p in problems:
            print("  " + p)
    else:
        print("\nIntegrity checks passed: right model, no denials, artefacts present.")

    if notes:
        print("\nNotes:")
        for n in notes:
            print("  " + n)

    # Ambient context baseline. Cache creation on the first call of a run is
    # everything loaded before the task starts. If it differs a lot between
    # cells, the cells are not comparable.
    caches = [(label(r), r.get("cache_creation_tokens")) for r in rows if r.get("cache_creation_tokens")]
    if caches:
        vals = [c for _, c in caches]
        print(f"\nCache creation tokens: min {min(vals):,}, max {max(vals):,}. "
              "Large spread means the cells saw different ambient context.")
    print("\nQualitative rows are intentionally blank. Fill them from the "
          "evaluation report; they need judgement rather than counting.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
