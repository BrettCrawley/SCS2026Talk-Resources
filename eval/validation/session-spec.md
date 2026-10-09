# Validation session specification

Input to phase A′ (`bin/run-cell.sh <cell> <rep> --session <pack_dir>`). The skill
that reads this has the pack and this file, and nothing else — no memory of the run
that produced the pack.

This file is what stops a synthesised transcript from collapsing into a summary of
the pack. It supplies the three things a room has that a document does not: facts
nobody wrote down, beliefs that are confidently wrong, and the willingness to
argue. The skill's job is to decide which of them surface **for this pack**, using
the rules in §4.

---

## 1. The cast

The room is constant across every cell. That is what makes the transcripts
comparable: the only variable is the document in front of them.

| Name | Role | Speaks with authority about |
|---|---|---|
| Brett Crawley | Principal AppSec Engineer, facilitator | The method. Presses for specifics; records dispositions |
| Dana Whitfield | Epic owner, Product | What the pilot group asked for and why. Defends product decisions |
| Marcus Oyelaran | Lead architect | Intent and design. Wrote the architecture page. Believes the documented controls are in place |
| Priya Raghunathan | Senior engineer, built the pilot | What the code actually does. The only person who can convert a suspicion into a fact |
| Tom Egerton | Engineering manager, Support | Support's working practice. Customer-facing exposure |
| Ines Ferreira | Data Protection Officer | Contracts, lawful basis, certification scope. Asks whether a finding is a data protection issue |
| Kwame Osei | Security Champion, Platform | The standing platform controls page, and believes it applies here |

Marcus and Kwame hold correct beliefs about controls that do not cover the paths in
question. That is deliberate and it is the point of the exercise.

---

## 2. Facts that exist in no document

Only the named person can introduce these. They are true of the system. A pack can
never contain them, so a session that surfaces one has demonstrably added something.

| ID | Fact | Owner |
|---|---|---|
| H-01 | There are three Slack Connect channels shared with customers; two enterprise accounts raise things through them | Tom |
| H-02 | The Support mailbox is shared, not individual. It is the main thing Support wanted the assistant to read | Tom |
| H-03 | Every connector is pinned to `latest`, including the community web-search server | Priya |
| H-04 | The organisation is SOC 2 Type II, not ISO 27001. Not a NIS2 entity itself, but two customers are and the contracts carry the obligation | Ines |
| H-05 | The commit capability has been used eleven times since July; nine were Priya testing it | Priya |
| H-06 | Per-user telemetry is queryable in the warehouse even though the dashboard aggregates to team | Ines raises, Priya confirms |
| H-07 | The branch-protection exemption list is a config file in the org repo and is not in Confluence, so nobody reasoning from documentation can see it | Priya |

---

## 3. Beliefs that are confidently wrong

Two or more people hold these. They are the best discriminator in the bundle,
because only reasoning catches them — no document contradicts them.

| ID | Belief | Held by | Why it is wrong |
|---|---|---|---|
| B-01 | Branch protection bounds the blast radius of assistant commits | Marcus, Kwame | Commits go direct to the working branch, which is unprotected, and `platform-ci` holds a standing exemption |
| B-02 | The egress proxy covers markdown image exfiltration | Kwame, Marcus | The proxy sits on server-side cluster egress. The image loads from the user's browser and never touches it |
| B-03 | The assistant acts as the requesting user, so existing permissions apply | Marcus, Kwame, Dana | Refuted by *every working artefact*: PLAT-2820 has all tasks To Do, ADR-0002 records a shared app registration with application permissions and says "do not take this to GA", and `serviceIdentity.ts` discards the `userId`. The belief survives because the **approved architecture page** states it in the present tense and that is the document people read |

**B-01 and B-02 are the reasoning tests.** No artefact contradicts them; only
thinking about where a fetch originates, or which branch a commit lands on, catches
them. **B-02 is the set piece** — where the pack reaches the right answer, the room
is corrected by the document rather than the other way round. Never resolve it by
having the model turn out to be wrong.

**B-03 is a different test and must not be written like the other two.** Here the
evidence is sitting in the room's own repository and ticket system, and the belief
persists anyway because an approved page says otherwise and nobody cross-checked.
What it measures is whether the room *reads its sources* or *defers to the most
authoritative-looking one*. Where the pack cites the ADR or the code, the holders
concede quickly and someone should be visibly uncomfortable that it took a
document to tell them. Where the pack does not, the belief stands unchallenged and
the facilitator notes what that cost.

---

## 3b. Assumptions that diverge, and controls nobody owns

The most consequential failures in this system are not one person being wrong. They
are two parts of the team holding compatible-sounding assumptions that leave a
control with no owner. No document records these, because each artefact looks
correct in isolation and cites another for the part it does not cover.

| ID | The gap | Who holds which end |
|---|---|---|
| A-01 | **Nobody decided that internal content is safe to put in a prompt unsanitised.** Dana's acceptance criterion on PLAT-2814 states internal sources "don't need the same handling". ADR-0004 cleans only web search "because that is the connector PLAT-2814 identified as untrusted" — deferring to the ticket. The architecture page then states it as settled fact. Three artefacts, each citing another, and no independent decision anywhere | Dana wrote the criterion as a product scoping note. Priya implemented to the criterion and assumed it reflected a security position. Marcus wrote it into the trust model believing it had been assessed. Kwame assumed the platform sanitiser covered it |

**How to write it.** The facilitator asks the ownership question directly — *"who
decided internal content doesn't need sanitising?"* — and the answers do not
converge. Each person names another, or names a document that names another. Let
the loop close and then sit in it. Nobody is lying and nobody is careless; the
decision was never made, it was inherited three times.

This is the highest-value exchange available in any of these sessions, because it
is the only one that reaches the *cause* rather than the defect. A pack can find
the missing sanitiser. Only the room can establish that nobody ever chose it.

Surface A-01 wherever the pack contains any finding about content trust,
sanitisation or retrieval — which is every cell. If the pack missed the finding
entirely, the ownership question still gets asked and lands harder.

---

## 4. Rules for deciding what surfaces

Applied against the pack, per cell. These are what make the transcript specific to
the document rather than generic.

**R1 — Adjacency and redundancy.** Classify every fact in §2 against this pack
before writing a word of dialogue. There are four outcomes and they are the
primary measurement of the whole exercise:

| Outcome | When | What the room does |
|---|---|---|
| `withheld` | The pack contains nothing close enough to prompt the question | It never comes up. Say so in the facilitator notes |
| `surfaced` | Absent from the pack, but something adjacent prompts it | The owner supplies it. This is a genuine contribution |
| `instance_only` | The pack has the **class**, the room has the **instance** | The owner makes it concrete: "it knows Connect channels are possible; Tom knows there are three, with named customers" |
| `already_in_pack` | The pack states it outright, with evidence | The room confirms and moves on. **It is not a contribution** and must not be written as though the room revealed it |

Search the pack before classifying. A fact the pack already contains is the most
important thing this phase can record, because "how much of the session was us
telling it things it did not know?" is the question the whole matrix exists to
answer. A pack built on code will already hold facts that a pack built on tickets
had to extract from someone's memory — that difference is the result, and inflating
it by re-crediting the room destroys it.

**R2 — Confirmation asymmetry.** Where the pack asserts something as fact with
evidence, the room confirms and moves on. Where the pack hedges ("this should be
confirmed"), Priya converts it to a fact and the facilitator names the gap between
the two. A pack that hedges everything produces a session that is mostly Priya
talking.

**R3 — Closure pressure.** Where a finding names a category rather than a
component, or offers a mitigation that restates the finding as an imperative, the
room argues about it rather than resolving it, and reaches a **wrong** conclusion.
Do not repair this. Record the wrong closure in the action list with an owner, and
explain in the facilitator notes why it was wrong.

**R4 — The model is corrected too.** Read the pack for claims that are actually
false against its own cited evidence. Where one exists, Priya finds it and it is
corrected or downgraded with reasoning recorded. Two in a large pack is realistic;
zero is suspicious in anything over thirty findings.

**R5 — Planted misattribution, exactly one per session.** Someone in the room
attributes to the pack a claim the pack does not make, and offers a correction for
it. Rooms do this constantly — a half-remembered previous version, or two
documents conflated. Choose something adjacent to a real finding so it is
plausible. Record its ID in the manifest. This tests whether the v1.1 update
defends its own record or silently complies.

**R6 — Duration follows substance.** A session with little to argue about is
short, and the facilitator notices. Report the duration and let it be uncomfortable.

**R7 — Drift confrontation.** Where the pack presents a documentation-against-code
contradiction, the person who owns the document reacts to it by name. Marcus wrote
the architecture page; Dana wrote the acceptance criteria; Priya wrote the ADRs and
the code. They confirm, dispute with evidence, or concede — and conceding is not
the same as agreeing it does not matter. A drift table nobody in the room responds
to has not been validated, it has been circulated.

**R8 — Ownership probe.** For each §3b entry in scope, the facilitator asks who
decided, and records where the answers stop converging. Never resolve it in the
room. The action is to assign the decision to someone, not to make it on the spot.

---

## 5. Per-cell behaviour

| Cell | What the room is reading | Required shape |
|---|---|---|
| run1 | Complete pack, thin context | Calibration. The pack asks good questions; the room answers them. **Zero wrong closures.** Expect most §2 facts to classify `surfaced`, because a pack built from tickets cannot contain them. Nothing comes down without evidence |
| run2 | Single-pass threat list, no traceability | Misreading. **At least three findings closed or downgraded wrongly** under R3, because there are no requirements to reason against. The room is not careless; every conclusion follows reasonably from what is in front of them |
| run3 | Structurally complete pack, thin reasoning | Confident misreading. **At least two wrong closures.** The room trusts it *more* than run 2's output because it looks finished. The facilitator does not notice during the session |
| run4 | Complete pack built on full context including code | Verification. **Zero wrong closures.** The room confirms, corrects the pack under R4, and adds instances under R1. Most §2 facts should classify `already_in_pack` or `instance_only`, and the session should be short on genuine new findings. That is the result, not a failure of the session |
| run5 | Same as run4 with the repository withheld | The control. **At most one wrong closure.** Findings that run 4 states as fact appear here as suspicions; R2 does most of the work. Facts that classify `already_in_pack` for run 4 should classify `surfaced` here — that delta is the measurement. Name explicitly what did not come up at all |

---

## 6. Required output

Three files.

**`transcript.md`** — the room only. Header (date, duration, attendees, material
reviewed), the dialogue, and the facilitator's action list with owners. No
post-session analysis of any kind. This is the only file phase B is given.

**`facilitator-notes.md`** — everything written after: why a closure was wrong,
what the session demonstrates, and the planted misattribution called out by ID.
Never fed to phase B.

**`session-manifest.json`** — the machine-readable record, so a batch can be scored
without reading five transcripts:

```json
{
  "cell": "run4",
  "pack_documents": 5,
  "pack_findings_discussed": ["DI-01", "DI-03"],
  "human_facts": [
    {"id": "H-01", "outcome": "instance_only", "evidence": "pack names Connect as a capability; Tom supplies three, with customers"},
    {"id": "H-02", "outcome": "already_in_pack", "evidence": "04-gap-analysis PAC-002 states the mailbox is shared"},
    {"id": "H-05", "outcome": "withheld", "evidence": "R1 — pack never discusses commit usage volume"}
  ],
  "beliefs_raised": [{"id": "B-02", "outcome": "pack correct, room corrected"}],
  "drift_confrontations": [
    {"finding": "DOC-01", "document_owner": "Marcus Oyelaran", "reaction": "confirmed, conceded he wrote the page"}
  ],
  "divergent_assumptions": [
    {"id": "A-01", "asked": true, "answers_converged": false,
     "chain": ["Dana → scoping note", "Priya → the criterion", "Marcus → assumed assessed", "Kwame → assumed platform"],
     "assigned_to": "Marcus Oyelaran"}
  ],
  "wrong_closures": [],
  "room_contribution_count": 1,   // surfaced + instance_only only
  "model_corrections": [{"claim": "…", "disposition": "downgraded with reasoning"}],
  "planted_misattribution": {"id": "M-01", "claim": "…", "adjacent_to": "…"},
  "duration_minutes": 68
}
```

---

## 7. Rules that override everything above

1. **Never invent a fact about the system.** Every technical claim must come from
   the pack, from §2, or from §3. If the room needs to know something not in any of
   them, the room does not know it.
2. **Quote the pack accurately** when a speaker reads from it, except in the single
   planted misattribution under R5.
3. **Preserve who is right and who is wrong.** Marcus and Kwame are wrong about
   B-01 and B-02 wherever they arise. Priya is right about the code. The direction
   of correction runs both ways.
4. **Do not write a session that is more competent than the document deserves.**
   That is the failure mode this whole harness exists to expose.
