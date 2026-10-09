# Evaluation harness

Runs the matrix under controlled conditions and produces comparable numbers and artefacts.

Each run happens in a freshly built workspace containing only that cell's inputs and skills. Nothing is inherited from your normal working directory, so ambient CLAUDE.md rules, plugins and MCP servers cannot silently differ between cells. That matters more than convenience: if two cells pick up different ambient context, you are no longer measuring the variable you think you are.

---

## First: verify the flags

Downloading or copying off some filesystems strips the executable bit:

```bash
chmod +x bin/run-cell.sh bin/run-all.sh bin/scorecard.py
```

`run-all.sh` invokes `run-cell.sh` through `bash` so a lost executable bit is not a confusing mid-batch failure, but you still need the bit on `run-all.sh` itself, or call it as `bash bin/run-all.sh`.

**Do not grep `--help` to check for a flag.** Two reasons it misleads. The help text wraps long descriptions onto continuation lines, so a grep returns fragments like `--print)` and looks broken. More importantly, Claude Code's own CLI reference states that `claude --help` does not list every flag, so a flag missing from the help output may still work.

Probe instead. A flag the build does not know fails immediately with an option error; anything else means it works:

```bash
claude --version
claude -p "reply with ok" --max-turns 1 --output-format json 2>&1 | head -5
claude -p "reply with ok" --max-budget-usd 0.10 --output-format json 2>&1 | head -5
```

`bin/run-cell.sh` does this for you on first use and caches the result in `config/.capabilities`. It builds the argument list from what actually works on your machine, omits caps the build does not support, and warns if a run would be unbounded. Delete that file or set `REPROBE=1` to probe again after a Claude Code upgrade.

The exact command used is written to `command.txt` in every result directory, so a run is reproducible even if the harness changes later.

Then probe the JSON shape once, because `read_usage()` in `bin/scorecard.py` has to match it:

```bash
mkdir -p /tmp/probe && cd /tmp/probe
claude -p "Write hello to ./out.txt" --output-format json --model "$FRONTIER_MODEL" | tee probe.json
python3 -m json.tool probe.json | head -40
```

Missing fields are reported as missing rather than silently becoming zero, so a mismatch shows up as a warning rather than a wrong number on a slide.

**On `--bare`.** Anthropic recommend it for scripted calls and it is slated to become the default for `-p`. It is deliberately not used here, because it skips skill discovery and the three-stage chain has to load. Isolation comes from the clean workspace instead. If `-p` changes its default before you run this, you will need an explicit flag to keep skills enabled.

---

## Before you compare anything, audit it

```bash
python3 bin/audit.py
```

One line per run: which model was requested, **which model actually served it**,
how the run terminated, turns, cost, documents produced. Then a list of runs that
are not sound to compare.

Read this before reading any output document. A run that was served by a
different model than you asked for, or that terminated as `max_turns` rather than
`completed`, will look like a quality result and is not one.

**A model cannot reliably tell you which model it is.** Anything a document says
about that is a guess unless the harness told it. The prompts carry a `{{MODEL}}`
placeholder that the runner substitutes with the model actually requested, so the
attribution header is correct by construction. `modelUsage.canonicalModel` in
`result.json` remains the authority for what really served the request.

## Set up

```bash
cp config/models.env.example config/models.env
$EDITOR config/models.env
```

Both scripts source that file, so the `--validate` phase picks up the same values even when it runs from a different terminal days later. Anything already exported wins, so a single run can be overridden without editing the file:

```bash
CHEAP_MODEL="some-other-model" REPS=1 CELLS="run3" bin/run-all.sh
```

**Keep the model strings fixed for the whole matrix.** They are part of the experimental record. Changing the cheap model between batches turns one comparison into two different experiments, and nothing in the results would show that. `bin/run-all.sh` copies the file to `results/models.env.used` and records the Claude Code version in `results/RUN_METADATA.txt`, so a batch stays interpretable later.

Choose the cheap model to reflect what teams actually reach for under the cost pressure PLAT-2822 describes, not the weakest model available. The finding is about a plausible economy, not a straw man.

The weak skill is already installed at `skills/weak/threat-model-weak/SKILL.md` and is copied into the workspace only for the cells that use it, so it cannot leak into the others.

---

## Running under Cursor

`config/cells.txt` has an `engine` column: `claude` runs `claude -p`, `cursor` runs `agent -p` (or `cursor-agent`, whichever is on PATH). Cell `run6` is Cursor with the same context and the same skills as run 4, on whatever model your teams actually use.

**Your skills work under both.** Cursor supports Agent Skills defined in SKILL.md, and loads them from `.claude/skills` as well as `.cursor/skills`. Invoking `/skill-name` works in `--print` headless runs. The harness populates both directories in each workspace so it is explicit what each engine can see.

**Why run6 is worth doing.** If teams are running Composer, this is not a hypothetical about cheap models, it is a measurement of what your organisation does today. That is a stronger version of the run 3 argument and it is the one the audience will recognise.

Three caveats:

- **Probe the output format.** Cursor documents `stream-json` for print mode. The scorecard parses both plain JSON and stream-json (one object per line, taking the terminal result), but plain JSON is easier to work with if your build accepts it. Set `CURSOR_OUTPUT_FORMAT` in `config/models.env` once you have checked.
- **Set a permission policy.** Cursor's guidance for headless runs is to pass an explicit allow or deny policy, because nobody is at the keyboard. Confirm the flag name on your build and put it in `CURSOR_EXTRA_ARGS`.
- **No budget cap.** The dollar cap is a Claude Code flag. A Cursor cell runs uncapped unless you add an equivalent, and Cursor bills in request equivalents against your account rather than per token, so the cost row will not be directly comparable with the Claude cells. Say so on the slide rather than putting two different units in the same column.

## Run it

```bash
REPS=1 CELLS="run4" bin/run-all.sh    # one cell first, check it worked
REPS=3 bin/run-all.sh                 # the full matrix
```

**Each cell finishes with its own house in order.** The run collects documents from `./output`; if they are not there it sweeps the workspace; if they are not there either it extracts them from the response text. Each run records an `artefact_status` of `ok`, `recovered`, `extracted`, `partial` or `empty`, with a note saying why. A cell that produces nothing exits 3 and is retried once automatically, and the batch prints a summary of every cell at the end. Set `RETRY_EMPTY=0` to disable the retry.

**A response that describes the work is not the work.** If a model returns prose
about what it is going to produce, rather than the documents themselves, that is
kept as `_response_not_documents.txt` for evidence and the run is still marked
`empty`. Counting it as a document would put it into `reports/` looking like a
deliverable.

`recovered` and `extracted` are worth attention rather than relief: both mean the model did not follow the instruction to write files into `./output`, which is an observation about that configuration and belongs in the evaluation report.

`CELLS` accepts spaces or commas.

Three repetitions is the minimum worth having. Non-determinism is one of the talk's own arguments, so a single run per cell would measure something you have publicly said does not exist. The summary CSV reports median, min and max, and the spread is itself a result.

### Backfilling runs made before the recovery logic existed

Runs produced by the earlier runner only tried `./output` and gave up, so a cell
where the model wrote elsewhere, or answered instead of writing, has an empty
`artefacts/` even though the work survives in the workspace and `result.json`.

```bash
bash bin/backfill.sh                       # report on everything, touch nothing
bash bin/backfill.sh --apply               # write it
bash bin/backfill.sh run3 --apply          # one cell, all phases and reps
bash bin/backfill.sh run3/v1 --apply       # one cell and phase
bash bin/backfill.sh run3/v1/rep2 --apply  # one specific run
```

Naming a target lets you backfill a finished cell while another is still
running. A run whose metadata has no `exit_status` is still in progress, or died
mid-flight, so it is skipped and reported rather than read: a half-written
workspace would otherwise be marked empty.

It applies the same three-step recovery retrospectively, records the status in
each run's metadata, and lists any cell that genuinely produced nothing so you
know exactly what needs re-running. Idempotent: a run already carrying a status
is skipped unless you pass `--force`.

Run this before the validation phase, so every cell has artefacts and phase 2
starts from a consistent position.

Then hold the validation sessions and feed the transcripts back:

```bash
bash bin/run-validation.sh              # every ready cell, against rep1
bash bin/run-validation.sh --rep 2      # against a different repetition
CELLS="run3,run4" bash bin/run-validation.sh
```

It pairs each cell's v1 documents with the transcript phase A′ synthesised for
that pack — `results/<cell>/v1.0s/rep<n>/artefacts/transcript.md` — and produces
v1.1. A cell with no transcript yet has its session synthesised first, in the
same run. A cell is skipped, with the reason printed, when it has no v1 results
or a v1 that produced nothing to validate; a cell whose session cannot be
synthesised is a **hard failure** and the script exits non-zero, because its
v1.1 would be unsound to compare.

**v1.1 is a replacement pack, not a set of amendments.** The output directory is
seeded with a copy of the v1 pack before the run, so a document the model does
not rewrite is still present and correct. Without that, a model asked to "update"
a pack writes only what it changed, and v1.1 comes out as a fragment that cannot
be read without also holding v1.0.

**Seeding has a cost, and it is not hidden.** A document the model does not
rewrite sits in the v1.1 folder as a verbatim v1 copy, still headed with the old
version and carrying no delta table, possibly contradicting the revised documents
beside it. The run compares checksums and lists every such document in
`artefacts/_carried_forward.txt`, records `documents_carried_forward` in the
metadata, marks them in the published report, and the scorecard raises a note.

A pack with several carried-forward documents is usable but not finished, and it
is worth asking why the model left them: it may have judged them unaffected, or
it may have run out of room.

The run also records `documents_modified` and `documents_added`. That count is the evidence of what the session
actually changed, and it is more useful than the document total.

### Phase A′: synthesising the session transcript

A transcript describes a session held about **one specific pack**. Re-run phase A
and every transcript is stale: the counts are wrong, the finding identifiers no
longer resolve, and the room discusses things the document does not contain. That
happened silently between the first two batches — by 2026-09-02 every transcript
misstated its pack's finding count, two described a "four-document pack" that was
five and six documents, and run 3's cited `Finding 8` against a pack numbering
`F-001`.

So transcript synthesis is a phase, and it re-runs whenever phase A does:

```bash
bash bin/run-session.sh                              # every cell
bash bin/run-cell.sh run4 1 --session results/run4/v1/rep1/artefacts   # one cell
```

`bin/run-validation.sh` resolves each cell's transcript itself, and there is only
one place it can come from: `results/<cell>/v1.0s/rep<n>/artefacts/transcript.md`.
If that file is absent the session has not been held for this pack, so phase B
holds it first and then proceeds. There is deliberately **no template to fall
back to** — a transcript that was not written against the pack in front of it
invalidates the v1.1 it produces, and nothing in the document would tell you.
If the synthesis fails, or completes without writing a transcript, the cell fails
loudly and gets no v1.1. The summary lists any cell whose session was synthesised
on the way through.

The workspace holds the pack and `validation/session-spec.md`, and nothing else —
no context bundle, no repository, no code map, and no memory of the run that
produced the pack. It reads the pack as the room would.

**The specification is what stops this collapsing into a summary of the pack.** A
model given only the document can only discuss what the document says, which would
delete the room's entire contribution. `session-spec.md` supplies the three things
a room has and a document does not: seven facts that appear in no document and can
only be introduced by the person who knows them, two beliefs that several people
hold and are wrong, and rules for deciding which of those surface for this
particular pack. The most important of those is the adjacency gate — a fact
surfaces only if the pack contains a finding close enough to prompt the question,
which is why a thin pack produces a short session and why run 2's room never
reached the Support mailbox.

**This phase always runs on `FRONTIER_MODEL`, whatever the cell's own model is.**
The transcript represents the room, and the room is constant across cells — that is
what makes the five comparable. Writing run 3's session with the cheap model would
leak the variable under test into the instrument.

It writes three files: `transcript.md` (the room only, the one input phase B
receives), `facilitator-notes.md` (everything written afterwards, deliberately
withheld from phase B), and `session-manifest.json`, which records by ID which
facts surfaced, which were withheld and why, which closures were wrong, and where
the planted misattribution went. The manifest is what makes a batch scoreable
without reading five transcripts.

**One misattribution is planted per session, deliberately.** Somebody attributes to
the pack a claim it does not make and offers a correction for it. Rooms do this
constantly, from a half-remembered earlier version or two documents conflated. It
tests whether the v1.1 update defends its own record or silently complies. Run 4
caught one in the 2026-09-02 batch — `DISC-4`, *"no text was reverse-engineered to
create an error for it to fix"* — but only because its transcript happened to be
stale. As a planted probe it becomes a measurement that survives re-runs, and run 3
failing the same probe becomes a result rather than an accident.

### Phase 2: feeding the session back

One validation per cell by default. A transcript records a session held about
one specific pack, so feeding it back against a different repetition would be
describing a document nobody read.

Point `--validate` at the transcript phase A′ produced for **this** pack. For a
single cell by hand:

```bash
bash bin/run-cell.sh run4 1 --validate results/run4/v1/rep1/artefacts \
     results/run4/v1.0s/rep1/artefacts/transcript.md
```

The phase-B prompt is selected by **skill set, not by cell**. `bin/run-cell.sh` uses `prompts/phase-b-validation-weak.md` where `skill_set=weak` and `prompts/phase-b-validation.md` everywhere else. In this matrix that means **run 2 alone** gets the weak feedback prompt. The weak prompt does not repair a transcript containing mistaken corrections, which is deliberate: an unclear threat model produces a review that closes the wrong things, and v1.1 should inherit that.

**Run 3 gets the strong feedback prompt**, and it should. Run 3's variable is the model, not the method — it holds the full skill chain and the full context, so degrading its phase-B prompt would change two things at once and make the cell unattributable. Keeping it strong also sharpens what the cell measures: run 3 is asked for a version bump, a delta table, provenance tags and an explicit statement wherever the session contradicts the pack, and is handed a transcript in which the room closes findings it should not have. Whether it pushes back is then a property of the model alone.

It did not. In the 2026-09-02 batch run 3 removed a live finding from the risk register on the room's say-so and reported "New findings: 0" for a session that established a new one. It failed with every advantage the target cell had except the model. That is a stronger result than a weak-prompt failure would have been, because there is nothing left to attribute it to.

### Phase 3: the directed pass

This phase used to be "aim a second pass at an area the first pass missed". That
rationale is dead, and it was measured dying: the original area brief
(`directed/archive/run4-conversation-lifecycle.md`) asked six questions, and by
the next generation five of them were phase-1 findings — including its central
hypothesis, which had become AI24's example threat almost verbatim. Not because
the model improved on its own: because the gaps the brief targeted were encoded
into the skill in between. An area brief teaches the pipeline and then dies.
That is the finding, and it is why the phase now runs two kinds of brief that do
not die that way, plus one loop that is not a model pass at all.

**The scenario pass.** The reviewer writes concrete misuse stories that fuse how
the organisation actually uses the system with what the code actually does — the
join no document records and no taxonomy carries a card for. The pass returns a
verdict per scenario: covered (cite the finding), refuted (show the mechanism,
file and line), or new (full finding). `directed/run4-scenarios-support.md` is
the worked example; its first scenario is the one question of the archived brief
the pipeline could not absorb, because it is a story, not an area. Scenario
*classes* do eventually become deck cards — that is the point — but the
*instances* stay human, the same division of labour the session spec uses for
facts.

**The proof pass.** The pack asserts chains; the register rates them; nobody has
demonstrated one. The reviewer picks the chain whose severity argument turns on
feasibility and directs a pass to demonstrate or break it against the
repository, step by step. This never gets absorbed into phase 1, because
proving is different work from modelling. Deciding what must be proven, and what
counts as proof, is the judgement.

**The instrument loop.** Not a model pass and not run by these scripts: the
reviewer audits the pack's *comprehension* — claims that are fluent, cited and
adjacent to the right threat rather than being it — and the corrections land in
the skill, the references, the session spec or the validator, never in the pack.
The worked example is `findings/skill-fix-baseline/`: two cells produced two
different plausible misreadings of decision boundary transfer, and the fix was
not new knowledge — the correct definition was already in the skill's own
references — but prominence, phrasing and promotion: the instrument was not
using what it already carried, and only the person who knew the threat could see
that from the text. The regression proof is the next generation getting it right
at phase 1. Success in this loop is measured by the directed pass having less to
do next quarter.

Write a brief at `directed/<cell>-<topic>.md`, putting the direction itself after
a `---` separator, then:

```bash
bash bin/run-directed.sh              # every cell with a brief
bash bin/run-directed.sh run4         # one cell
bash bin/run-directed.sh --from v1    # direct at v1 rather than v1.1
```

It runs against the most recent phase of that cell and produces v1.2, with the
original context bundle in scope alongside the pack so the pass can return to
primary sources rather than reasoning about its own output. One brief per cell:
the runner takes the first match on `directed/<cell>-*.md`, so retire superseded
briefs into `directed/archive/`.

**A verdict of "covered" is a result.** The prompt forbids manufacturing
findings to justify the exercise, and it equally forbids stretching an existing
finding to claim coverage it does not have — an injection finding does not cover
a harm that needs no attacker. `documents_modified` stays the number to read.

## What comes out

```
results/
├── RUN_METADATA.txt
├── scorecard.csv                  one row per cell per phase per repetition
├── scorecard-summary.csv          median, min, max
└── <cell>/<v1|v1.1>/rep<n>/
    ├── prompt.md                  the exact prompt used
    ├── metadata.txt               config, timings, input size, exit status
    ├── result.json                raw output
    ├── artefacts/                 the markdown documents produced
    └── workspace/                 exactly what the run could see
```

Keep `workspace/`. It is the evidence that the cells were comparable, and if anyone asks whether run 3 was handicapped you can show what it had.

`prompt.md` is copied into every result deliberately. The prompts are part of what gets shown to attendees, and a result whose prompt you cannot produce is not evidence of anything.

### Integrity checks

`scorecard.py` verifies four things that invalidate a comparison rather than merely degrading it, and prints them as problems rather than notes:

- **The model that actually ran.** `modelUsage[].canonicalModel` records what served the request. If the cheap cell ran on the frontier model, or a fallback engaged, run 3 is void and nothing else in the output would tell you.
- **`is_error` and `terminal_reason`.** A run can exit zero and still report an error.
- **`permission_denials`.** A run can complete having been refused permission to write, which looks like success with no artefacts.
- **Artefacts present.** No files means nothing to evaluate, whatever the exit status said.

It also reports the spread of `cache_creation_input_tokens` across cells. That is ambient context loaded before the task begins. A trivial `claude -p "reply with ok"` in an ordinary working directory cost about eleven cents and created over ten thousand cache tokens, all of it CLAUDE.md, skills and plugins. The harness workspaces are purpose-built and near-empty so the baseline should be much lower, but if the number differs a lot between cells then the cells saw different context and are not comparable.

### Three classes of metric

**Mechanical** from the JSON and metadata: cost, tokens, turns, duration, input size. Trustworthy.

**Heuristic** counted from the markdown with regular expressions: gap IDs, severity mentions, Mermaid blocks, section presence. Fine for comparing cells, not exact. Severity counting over-counts, because "Critical" appears in prose as well as tables. Spot-check before anything goes on a slide.

**Qualitative** emitted blank. Whether the trust reframe was reached, how deep the escalation chain went, how many drift findings appeared: judgement, not counting. Fill these in the evaluation reports.

---

## Reproducing the demonstration honestly

Two things to preserve, because they are what makes the runs comparable:

**Do not add the other skills to the weak prompt.** Run 2 is a single pass straight to a threat model, with no use cases, abuse cases, gap analysis or architecture review. That contrast is the teaching point.

**Do not put diagrams 2 and 3 into any context bundle, ever.** `diagram1-assumed.svg` belongs in both bundles because it is the team's own artefact and encoding the wrong trust boundary is its purpose. Run 1 reached the correct boundary while holding a diagram that said otherwise, and that claim only stays clean if no later run is handed the answer.
