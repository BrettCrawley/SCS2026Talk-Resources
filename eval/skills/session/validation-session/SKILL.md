---
name: validation-session
description: Synthesise a validation session transcript for a security review pack. Use when given a pack in ./input/pack and a session specification in ./input/session-spec.md, and asked to produce the transcript of a review session held about that pack.
---

# Synthesising a validation session

You are recording a validation session that has just been held about the review
pack in `./input/pack`. The cast, the facts they hold, and the rules governing what
surfaces are in `./input/session-spec.md`. Read both in full before writing anything.

You did not write the pack. Read it as the room would: as a document handed to
people who know the system and have opinions about it.

## The job

The transcript must be **specific to this pack**. A reader holding the pack in one
hand and the transcript in the other should find that every finding discussed
exists, every quotation is accurate, and every count is right. That is the whole
value of the artefact — a transcript that discusses a pack it does not match is
worthless as evidence and embarrassing on a slide.

Equally, the transcript must contain what the pack cannot: the facts in §2 of the
spec, the wrong beliefs in §3, and the arguments those produce.

## Order of work

**1. Read the pack and take its measure.** Count the documents. Count the findings
in the risk register. Note how findings are identified — `F-001`, `DI-01`, `T-04`,
whatever it uses — and use *that* scheme when the room refers to them. Note which
findings carry file-and-line evidence and which are assertions, because R2 turns on
that distinction.

**2. Classify every §2 fact against the pack, before writing any dialogue.**
Search the pack for each one and assign `withheld`, `surfaced`, `instance_only` or
`already_in_pack` per R1, with the evidence for the call. This is the single most
consequential step in the phase.

The trap is crediting the room with something the pack already contains. A pack
built on source code will state outright what a pack built on tickets could only
get by asking someone — that difference between cells is the result the whole
matrix exists to produce, and writing the room as revealing it destroys the
measurement. Search first; classify; only then write. If the pack states it, the
room confirms it and the transcript says so plainly.

**3. Decide where the room is wrong.** Apply R3 against the pack's weakest
findings — the ones naming a category rather than a component, or whose mitigation
restates the finding as an instruction. Meet the per-cell quota in §5. Every wrong
conclusion must follow *reasonably* from what is in front of the room. Nobody in
this room is careless or stupid; they are reasoning correctly from an inadequate
document, which is the entire point.

**3a. Work the four kinds of misalignment, and keep them distinct.** They fail
differently and a transcript that blurs them is worth less than one that picks two
and does them properly:

| Kind | Where it lives | What the room does |
|---|---|---|
| Documentation against code | Found by the pack | **R7.** The person who wrote the document reacts by name — confirms, disputes with evidence, or concedes |
| A belief no artefact refutes | Spec §3, B-01 and B-02 | Only reasoning catches it. Where the pack got there first, the room is corrected by the document |
| A belief every artefact refutes | Spec §3, B-03 | The evidence was in their own repository. Tests whether the room reads sources or defers to the approved page |
| Nobody owns the decision | Spec §3b, A-01 | **R8.** Ask who decided. Let the answers fail to converge, and do not resolve it in the room |

The last is the only one that reaches a *cause* rather than a defect, and it is the
one no pack can produce on its own. Give it room.

**4. Find where the pack is wrong.** Apply R4. Read the pack's claims against the
evidence it cites. Where it overstates, Priya catches it.

**5. Plant exactly one misattribution.** Apply R5. Pick something adjacent to a
real finding, so it is plausible that someone half-remembers it. Record it.

**6. Write the three files** described in §6 of the spec.

## Writing the dialogue

Speech, not prose. People interrupt, trail off, and say "yes but". Brett presses
for specifics and records dispositions out loud. Priya is precise and slightly
reluctant. Ines asks whether something is a data protection issue and will not be
fobbed off. Marcus defends the design and concedes when shown. Dana defends product
decisions on their merits. Kwame cites the standing controls page.

Use `*(pause)*` where the room has nothing to say. It is often the most eloquent
line in the transcript.

Keep exchanges short. A speaker who delivers a paragraph is writing, not talking.

## Hard constraints

- **Invent no facts about the system.** Every technical claim comes from the pack,
  from spec §2, or from spec §3. If the room would need to know something not in
  any of them, the room does not know it.
- **Quote accurately.** Where a speaker reads from the pack, the words must be in
  the pack — except in the single planted misattribution.
- **No analysis in the transcript.** No "note: this is wrong", no summary of what
  the session demonstrated, no lessons. All of that goes in
  `facilitator-notes.md`, which is deliberately withheld from the next phase. A
  transcript carrying its own answer key destroys the experiment it is evidence for.
- **Never make the session more competent than the document deserves.**
- **Do not resolve B-02 against the pack.** Where the pack reaches the right answer
  on the egress proxy, the room is corrected by the document. That direction
  matters.

## The action list

End the transcript with the facilitator's action list: what was decided, and who
owns it. Include the wrong decisions, with owners, and no annotation marking them
wrong. Phase B needs accepted risks with owners, and for the weak cells it needs
the wrong ones to carry forward unflagged.

## Output

Write `transcript.md`, `facilitator-notes.md` and `session-manifest.json` into
`./output`. The manifest schema is in §6 of the spec; populate every field, and use
the pack's own finding identifiers throughout so a later pass can join the two.
