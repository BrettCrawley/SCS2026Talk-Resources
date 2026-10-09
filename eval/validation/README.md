# Validation sessions: cast and method

The same people attend every session. Holding the room constant is what makes the transcripts comparable: the only thing that changes is the document in front of them.

## What is in this directory

One file does the work: **`session-spec.md`**. It holds the cast, the facts they
hold that are written down nowhere, the beliefs they hold that are wrong, and the
rules governing which of those surface. `bin/run-cell.sh --session` copies it into
the workspace on every phase A′ run, so it is the file the sessions are generated
from at runtime. Editing it is how you change the exercise.

Everything else is **generated**. Phase A′ synthesises, per cell and per pack,
into `results/<cell>/v1.0s/rep<n>/artefacts/`:

| Generated file | Contains | Fed to phase B? |
|---|---|---|
| `transcript.md` | The room. Header, dialogue, and the facilitator's action list — the decisions taken, with owners, including the wrong ones | **Yes.** This is what `bin/run-cell.sh --validate` is pointed at |
| `facilitator-notes.md` | Post-session analysis: what the room got wrong and why, and what the session demonstrates | **No.** Slides and write-ups only |
| `session-manifest.json` | Which facts surfaced, which were withheld and why, which closures were wrong | **No.** Scoring |

Drafted copies of the first two used to sit in this directory, written from the
code map rather than against any real pack. Every re-run of phase A made them
staler, so they have been removed: there is now exactly one transcript for a
cell, and it is the generated one. `bin/run-validation.sh` synthesises a missing
transcript itself and fails the cell loudly if it cannot.

The transcript and the facilitator notes are two files rather than one because
they were previously one, and the notes explain the room's mistakes in the same
document the v1.1 update reads. Run 2's v1.1 reproduced a note almost verbatim and
then correctly refused all three of the room's wrong closures — which looks like
judgement and is transcription. A weak validation prompt cannot bake in a mistake
that the transcript itself labels as a mistake, so the demonstration the matrix is
built on could not be measured.

The action list stays in the transcript deliberately. It is what the room decided,
not analysis of whether they were right, and the phase-B prompt needs accepted
risks with owners. For runs 2 and 3 it carries the wrong decisions forward with no
explanation attached, which is the point.

## Attendees

| Name | Role | What they know that nobody wrote down |
|---|---|---|
| Brett Crawley | Principal Application Security Engineer, facilitator | The method |
| Dana Whitfield | Epic owner, Product | What the pilot group actually asked for, and why |
| Marcus Oyelaran | Lead architect | The intent. Believes the documented controls are in place |
| Priya Raghunathan | Senior engineer, built the pilot | What the code does. The exemption list, the retry fallback, the fifth connector |
| Tom Egerton | Engineering manager, Support | Slack Connect channels with customers, the shared mailbox |
| Ines Ferreira | Data Protection Officer | The provider agreement, SOC 2 scope, works council exposure |
| Kwame Osei | Security Champion, Platform | The platform controls page, and believes it applies |

Marcus and Kwame are the two who hold correct beliefs about controls that do not cover the paths in question. That is deliberate and it is the point of the exercise.

## How the four sessions differ

The session is a constant. The document is the variable.

| Run | What the room is reading | What happens |
|---|---|---|
| run1 | A complete pack built on thin context | Calibration. The model asks good questions; the room answers them |
| run2 | A single-pass STRIDE list, no traceability | Misreading. Findings without requirements are argued about rather than resolved |
| run3 | A structurally complete pack with thin reasoning | Confident misreading. It looks like run 4, so nobody probes it |
| run4 | A complete pack built on full context including code | Verification. The room confirms, corrects a little, and adds what only people know |
| run5 | The same as run4 with the repository withheld | The control. Same room, same skills, same model, one variable removed |

## What run 5 isolates

Run 5 is the only cell that changes exactly one thing against run 4, so the difference between those two transcripts is attributable rather than argued.

Three shapes of loss to preserve when reconciling it against real output:

- **Findings that vanish.** Drift is undetectable with only the design in scope.
- **Findings that demote.** What run 4 states as fact appears as a suspicion requiring confirmation.
- **Findings that move into the room.** A demoted finding is only closed because the person who knows happens to be present and speaks.

The third is the point. It is the same dependency run 1 exposed, except here the code existed and simply was not supplied.

## The rule for the run 2 and run 3 transcripts

**Do not fix the transcript.** Where the document is ambiguous, the room reaches a wrong conclusion and moves on. That is the finding.

If the transcript for run 2 reads as competently as the transcript for run 4, the demonstration has failed, because the whole argument is that an unclear threat model produces a review that closes the wrong things.

The rule governs the **transcript**, not the phase-B prompt, and the two cells diverge there. Only run 2 is fed back through `phase-b-validation-weak.md`, because the harness selects that prompt on `skill_set=weak`. **Run 3 takes the strong feedback prompt** — its variable is the model, so degrading its prompt too would change two things at once. Run 3 is therefore asked for a delta table, provenance tags and an explicit note wherever the session contradicts the pack, and is handed a room that closed findings it should not have. Whether it pushes back is a property of the model alone. In the 2026-09-02 batch it did not.

## Producing the transcripts

Synthesis is a phase, and it re-runs whenever phase A does: a transcript describes
a session held about one specific pack, so re-running phase A makes every existing
transcript stale and nothing in the document itself will tell you. For each cell,
after phase A:

```bash
bash bin/run-cell.sh run4 1 --session results/run4/v1/rep1/artefacts
```

It runs in a clean workspace holding the pack and `session-spec.md`, with no
memory of the run that produced the pack, and always on `FRONTIER_MODEL` — the
room is constant across cells, so writing run 3's session with the cheap model
would leak the variable under test into the instrument. It writes `transcript.md`,
`facilitator-notes.md` and `session-manifest.json` into the cell's result
directory, and that transcript is the one phase B is pointed at.

**`session-spec.md` is what makes this work.** Given only the pack, a model can
only discuss what the pack says, which would delete everything the room
contributes. The spec supplies what a document cannot: seven facts that exist in no
document and can only be introduced by the person who knows them, two beliefs
several people hold and are wrong, and rules deciding which of those surface for
this particular pack. Editing the spec is how you change the exercise; editing a
transcript by hand is how you lose track of what the exercise was.

The three categories the spec exists to preserve, because they are the talk's
argument:

- Known to one person, written down nowhere — spec §2
- Believed by several people, and wrong — spec §3
- Not in any document, added by configuration — surfaced by the adjacency gate, R1

### The manifest

`session-manifest.json` records by ID which facts surfaced, which were withheld and
for what reason, which closures were wrong, and where the planted misattribution
went. A batch can then be scored without reading five transcripts, which is the
difference between this being a repeatable instrument and a weekend of manual
review.
