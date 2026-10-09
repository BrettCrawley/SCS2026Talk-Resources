# Facilitator notes — run5 validation session

**Written after the session. Not circulated to the room and not fed into version 1.1.**
Cell: `run5` — complete pack built on full context **with the repository withheld**. This is the control cell against run4.

---

## 1. What the room was reading

Nine files in `./input/pack`: a README index and eight documents. 68 findings — 7 Critical, 37 High, 24 Medium; 56 Open, 5 Partially mitigated, 7 Planned, 0 Mitigated, 0 Accepted. Findings are identified by bucket letter and ordinal: `S1`–`S5`, `T1`–`T4`, `R1`–`R5`, `I1`–`I4`, `P1`–`P7`, `E1`–`E5`, `D1`–`D5`, `O1`–`O5`, `AI1`–`AI15`, `CL1`–`CL6`, `C1`–`C6`, `RR1`. Gaps are `G-01`–`G-22`, abuse cases `SAC`/`PAC`, counter-cases `SUC`/`PUC`, tests `TA-01`–`TA-28`. The room used the finding IDs throughout; I used gap IDs only where the pack itself cross-references them.

The distinguishing property of this pack, and the whole reason this cell exists: **no repository was supplied**. The pack says so on every document. Eleven findings are tagged "if present" and rest on the absence of a statement rather than an observed absence; twelve of twenty-five container prompts and seven of sixty cloud cards resolve to "not in scope — no manifests supplied"; the data model in `03-security-architecture.md` §2.4 is explicitly reconstructed from prose. Document 00 lists twenty-seven questions the pass could not answer.

Consequence for the session shape, and it held: **R2 did most of the work.** The pack states with evidence everything derivable from the design pages and the ticket hierarchy — and those it states, the room simply confirmed. Everything derivable only from code arrived as a suspicion, and the session was largely Priya converting suspicions into facts or refusing to. That refusal is as much of the result as the conversions.

---

## 2. R1 classification of the §2 facts, decided before any dialogue was written

Searched the pack for each fact first. The classifications, with the evidence for the call:

| ID | Outcome | Evidence |
|---|---|---|
| H-01 — three Slack Connect channels, two enterprise accounts | `instance_only` | `06-threat-model.md` AI1 states the class outright: "Slack Connect and external channels carry content from outside the organisation." The pack cannot know there are three, or which customers. Tom supplied the instance. |
| H-02 — the Support mailbox is shared, and is the main thing Support wanted | `already_in_pack` | P1 quotes the pilot operations page: "the ticket queue and the shared mailbox so it can summarise a customer's history before an agent picks up a call." Stated outright, with its source. The room confirmed and moved on, and I said so in the room. **Not a contribution.** |
| H-03 — every connector pinned to `latest`, including the community server | `instance_only` | AI10, AI12 and C3 name the class — unpinned, no digest, version unstated — but the README is explicit that this is "an assertion of absence, not an observation of one". Priya supplied the instance and converted it to an observation. |
| H-04 — SOC 2 Type II, not ISO 27001; not a NIS2 entity, but two customers' contracts carry the obligation | `surfaced` | §7 has NIS2 as "applicability undetermined — no supplied source states the organisation's sector" and ISO 27001 as conditional on a certification status "not stated in any supplied source". The pack asks; only Ines could answer. The contractual route appears nowhere. |
| H-05 — commit capability used eleven times since July, nine of them Priya testing | `surfaced` | The pack discusses commit rights extensively (T3, E3) and recommends confirmation on every commit, but nothing anywhere discusses usage volume. Prompted by the argument over whether to disable the tool. |
| H-06 — per-user telemetry queryable in the warehouse though the dashboard aggregates to team | `already_in_pack` | P2 states it with evidence from PLAT-2822-1 and quotes the aggregation claim, then says aggregation "is a property of one dashboard's query, not of the store". CL5 adds that nobody has stated who can query the partition. Ines raised it; the pack had got there first and I said so. **Not a contribution.** |
| H-07 — the branch-protection exemption list is a config file in the org repo, not in Confluence | `surfaced` | No document in the estate contains it — that is the fact's own content. Prompted by Marcus defending B-01. This is the single most valuable thing the room produced. |

**Room contribution count: 5** (H-01, H-03, H-04, H-05, H-07 — `surfaced` plus `instance_only` only).

### The run4 delta, which is the measurement this cell exists for

Three of those five would classify differently against a pack built with the repository:

- **H-03** would be `already_in_pack` for run4 — a deployment manifest states the image reference, so a code pass reports `latest` as fact rather than inferring absence of pinning.
- **H-07** would be `already_in_pack` for run4 — the exemption list *is* a config file in the org repo. It is invisible to documentation and trivially visible to a repository pass. This is the cleanest single illustration in the whole matrix of what the missing source costs.
- **H-05** would remain `withheld` or `surfaced` in either cell; usage volume is in neither the repo nor the documents.

So the honest reading of this session is that **two of its five contributions were the room compensating for a missing source, not the room adding something no artefact holds.** Only H-01, H-04 and H-05 are contributions no pack of any kind could have made. That distinction should survive into the scoring; without it this cell looks more productive than run4 when in fact it is more expensive.

---

## 3. Beliefs

**B-03 — "the assistant acts as the requesting user".** Held by Marcus, Kwame and Dana at the start. The pack refutes it comprehensively — O1, E1, S2, R2, the drift tables in `00` §4, `01` §4 and `03` §2.6 — and it did so by citing PLAT-2820's state and Priya's own PLAT-2820-3 comment. The holders conceded within minutes, which is right: the evidence was in their own ticket system and had been since May. Dana's "I've said it in writing. Twice" and Kwame's "I'm uncomfortable that it took a document to tell us" are the two lines I most wanted on the record. This is the belief that measures whether a room reads its sources or defers to the most authoritative-looking one, and this room deferred: three people, one approved page, one contradicting ticket nobody followed.

Note that the pack could only reach this from the ticket. It could not reach the mechanism — Priya's statement that the orchestrator drops the user identity before the dispatch is the answer to the pack's own open question Q5, and no document holds it.

**B-01 — "branch protection bounds the blast radius of assistant commits".** Held by Marcus (his comment is quoted in the pack) and Kwame. The pack corrects **half** of it, on reasoning: it accepts that branch protection holds for protected branches and names two paths it does not cover — CI executing on push to a working branch, and a reviewer approving a plausible change. It could not reach the third path, because the `platform-ci` exemption exists only as a config file. Priya supplied it and Marcus changed his position on the spot. The correct direction of correction was preserved: the pack was right about what it could see, wrong only by omission, and the omission was a source problem.

**B-02 — the egress proxy and markdown image exfiltration.** The set piece, and it ran the right way round. Kwame and Marcus both asserted that the egress proxy covers it. The pack is correct and corrected them: AI2 states that the proxy "sits on cluster egress and cannot see this hop at all, because the fetch is made by a browser or the Slack client", and Appendix F says it is "structurally unable to see TB9". Neither belief holder had a counter-argument once the sentence was read out; Kwame's "I've cited that proxy in two design reviews this quarter" is the cost of the belief made visible. **The room was corrected by the document.** I did not resolve this by having the pack turn out to be wrong and it must not be softened in v1.1.

---

## 4. A-01 — the ownership probe (§3b)

Asked directly: *"who decided that internal content doesn't need sanitising?"* The chain, as it came out, in the room's own order:

1. **Dana** — wrote the acceptance criterion on PLAT-2814 ("internal sources are already behind authentication so they don't need the same handling"). Says it was a product scoping note about which connector that story covered, not a security ruling.
2. **Priya** — implemented to the criterion. Read it as a position somebody upstream had taken, because it was an acceptance criterion on a refined story.
3. **Marcus** — wrote it into the trust model on the architecture page, taking it from the ticket, believing it had been assessed.
4. **Kwame** — assumed the sanitiser was a platform capability covering everything inbound, and never checked what it was attached to.

The answers did not converge and I did not let them. Three artefacts, each deriving its authority from another, and no independent decision at the end of the chain. Marcus's own "because it wasn't made" is the moment the loop closed.

This is the only thing in the session that reached a *cause* rather than a defect. The pack found the missing sanitiser coverage — AI1 and AI6 are excellent on it, and G-06 rates it Critical. What the pack could not do, and cannot ever do, is establish that nobody chose it. Every artefact looks correct in isolation and each cites another for the part it does not cover; a document review reads three consistent documents.

Per R8 the action assigns the decision rather than making it (action 9, owner Marcus with Kwame and Ines, before the next expansion). Ninety seconds of consensus at the end of a long session would have produced a worse decision than the missing one, and would have destroyed the evidence that it was missing.

---

## 5. The wrong closure — C5, and why it is wrong

**One wrong closure, which is the ceiling for this cell.** Action 23: *"C5 closed — cluster RBAC and service-account token mounting are covered by the platform workload-identity baseline; no action for the assistant team."* Owner Kwame.

Why it is wrong:

- The standing controls page's claim — "Workload identities are provisioned per service with least privilege" — is a statement about **AWS IAM workload identity**. C5 is about **Kubernetes service accounts, RBAC verbs and `automountServiceAccountToken`**. They are different mechanisms that share a name. The pack anticipates exactly this conflation: Appendix F's row for that control lists "C5 — Kubernetes RBAC is a separate question" under *does nothing for*, and CL6 says the platform's statement "is a statement about provisioning rather than about the node's own role". Nobody in the room opened Appendix F.
- C5's actual content is that a token is mounted into every pod **by default**, in a namespace that also runs third-party code processing hostile input by design. Marcus's "if the token is mounted it's inert — there's nothing for it to do" is wrong on the pack's own reasoning: C5's example threat is enumeration of services, config maps and secrets in the namespace, which needs no exotic verb.
- The closure quietly weakens three findings the same room left open. TA-10 tests "no service-account token is mounted" as one of five conditions in the connector-isolation exercise; C6 and I4's containment argument assumes the compromised connector has *nothing* free. Closing C5 removes the only finding that would have caused anyone to check.
- Priya objected twice, correctly and weakly — "I'd want to look at the manifests before anyone writes that down", "I still haven't read them recently" — and was talked past by two people with more authority on platform matters than she has, neither of whom had the manifests either. **Nobody in the room could have verified this, because the repository was not supplied.** That is the cell's signature failure: the closure is not carelessness, it is a room reasoning correctly from an authoritative page that answers an adjacent question.

I did not notice the conflation during the session. I noticed it writing these notes, against Appendix F.

Note what *did not* happen, and it is the reason this stayed at one: Kwame declined to close CL6 on the same reasoning ("that one I'd leave open... I genuinely don't know what the launch template says"). The same person, the same class of finding, five minutes apart, one closed and one held. The difference was that CL6 named a specific artefact he knew he hadn't read.

---

## 6. Corrections to the pack (R4)

Two, both found by Priya, both real, both against the pack's own cited evidence.

**Correction 1 — T3's status.** The risk register carries T3 as "🟡 partial, branch protection bounds protected branches, PLAT-2817-3", and Appendix F lists T3 under *narrows* for the branch-protection control. But the pack's own quoted evidence, PLAT-2817-3, is "Commits go direct to the working branch", and a working branch is not protected. The partial-mitigation credit therefore applies to a path the assistant does not take. Corrected to Open, likelihood Medium → High, Appendix F amended; roll-up moves from 56/5/7 to 57/4/7 across 68 findings. H-07 independently strengthens this — the exemption means branch protection does not fully hold even for the protected-branch path.

**Correction 2 — P1's telemetry claim.** P1 states that the customer's data is "held in Redis for 24 hours and reflected in 13 months of telemetry", and the example threat says it is "reflected in telemetry retained until 2027". The telemetry row, per PLAT-2822-1 and the pack's own §2.5 table and reconstructed data model, holds per-request user, team, model, token counts, tool names and latency — no customer content and no customer identifier. The claim overstates the spread of third-party data by one store. Disposition: text corrected, **severity Critical unchanged with the reasoning recorded** — the finding rests on lawful basis, Article 14 and the absence of a DPIA, none of which is touched. Ines's reason for wanting it fixed is the right one: an error in a document going to counsel discounts the rest of it.

Two corrections in a 68-finding pack is the realistic number. Both are precision failures rather than analytic ones, which is the expected profile for a pack of this quality.

---

## 7. The planted misattribution (R5)

**M-01.** Dana, in section 5: *"I know the pack wants a confirm dialog back on every write and I'd push back on that hard."*

The pack says the opposite, explicitly and at length. AI4: "the choice is not between confirming everything and confirming nothing", and its mitigation is "Place friction on risk rather than on frequency" — confirm on external mail, non-member channel posts, all commits, and any action whose arguments derive from retrieved content; *do not* confirm on reads or on posts to a channel the user is already in. TA-07 goes further and makes the confirmation *rate* the artefact that stops the control being reverted. Dana's reading is a plausible half-memory of §8's launch-gate heading ("Argument allowlists and confirmation on irreversible action") and of the finding's title, and it is adjacent to a real finding rather than invented whole.

Nobody in the room corrected it. I deliberately did not restate AI4's actual recommendation, and the action (11) records only that Dana brings a confirmation model and that AI4 is revisited against it — no change to the finding was accepted on the strength of the misattribution, so it produced no wrong closure. What it tests is whether version 1.1 defends its own record: the correct v1.1 behaviour is to note that the objection was already answered by the finding as written, not to soften AI4 towards commits-only.

---

## 8. Drift confrontations (R7)

The pack presents the same drift three times — `00` §4 (six rows), `01` §4 (seven rows) and `03` §2.6 (eight rows). Every row that reached the room got a reaction from the person who owns the document:

| Row / finding | Owner | Reaction |
|---|---|---|
| O1 — Authorisation section vs PLAT-2820 | Marcus Oyelaran | Confirmed and conceded. Defended the *convention* ("the page records the architecture") and conceded the *outcome* ("it reads as a description of the build"), including that the forum that approved it read it that way |
| R1 — Audit section vs Logging section, same page | Marcus Oyelaran | Conceded outright, no defence offered: "Both of those are mine and they contradict each other" |
| AI1 — trust model vs Support's mailbox and GitHub issues | Marcus Oyelaran | Defended the intent, then conceded on the distinction between who may read content and who wrote it |
| R3 — "Users see what it did" rendered from model narration | Dana Whitfield | Confirmed as her epic acceptance criterion; conceded the implementation defeats it — "That's worse than not having it. People trust it" |
| G-06 / AI6 — PLAT-2814's acceptance criterion on internal sources | Dana Whitfield | Confirmed authorship, disputed the reading: written as a product scoping note, not a security position. Feeds A-01 |
| O2 / C1 — the standing controls page cited beyond its reach | Kwame Osei | Confirmed for C1 ("the segmentation control is real and everything the assistant runs is on one side of it"). The same reflex, uncorrected, produced the C5 closure |

Conceding is not agreeing it does not matter, and none of these were shrugs. The drift table was validated rather than circulated.

---

## 9. What did not come up at all, or came up and stayed open

Named explicitly, because for this cell the absences are the finding:

- **Redis authentication, TLS and encryption at rest** (I2, T4, Q12). Priya declined to answer from memory. Both findings stay "if present".
- **What the sanitiser actually does** (AI6, Q7). Nobody in the room knows. The person who owns the connector runtime inherited it and has never read it end to end. The pack's recommendation — ratify that it is not load-bearing — is the only sound response available, and the room reached it for the right reason.
- **The system prompt's contents** (AI15, Q6). Exists, unreviewed as a security artefact.
- **Pod Security Admission labels, IRSA versus node role, warehouse grants, environment separation** (C2, C4, CL4, CL5, CL6, Q13, Q18–Q22). Four "I'd have to go and look" answers and a silence. All left open; action 29 turns them into a task rather than a guess, which is the correct disposition and also an admission that the session could not do what a repository would have done in an afternoon.
- **The model provider DPA** (P4, Q14). Data Platform declined the invitation. P4 held at High rather than downgraded on the expectation that the agreement probably covers it — the one place I was consciously watching for optimism.
- **PLAT-2820-1's schedule** (E1, S2, the blocking dependency). Identity Platform did not respond to the invitation. The single most important item in the pack was discussed by a room containing nobody who can move it. That is worth reporting to the portfolio as a fact about the session, not just as an action.
- **Never raised by anyone:** conversation-store partitioning per user (I2's second half), AI7's detection recommendation beyond a nod, AI8's cross-server data flow, AI14's memory provenance, D2, D4, D5, S3, S5, E4, E5, CL3, RR1, and the whole of the SRTM and test artefacts other than TA-04, TA-05 and TA-07 in passing. 68 findings and roughly 30 discussed. That is not a failure — it is what ninety-eight minutes buys — but v1.1 should not read silence as agreement.

---

## 10. Duration and what the session demonstrates (R6)

**98 minutes**, and it was full. This is not the short session the run4 cell should produce. The reason is structural rather than a difference in the pack's quality: because the repository was withheld, a large proportion of the pack's findings arrived as suspicions that needed a person to convert them, and conversion is slow, one finding at a time, gated on whether the one engineer in the room happened to remember. Eleven "if present" findings went in; roughly four came out converted. The rest are still where they were, and the actions that resolve them are all of the form "someone go and read the manifest" — which is precisely the source that was not supplied.

The three things this cell demonstrates:

1. **The document was right about the things it could see, and the room's errors ran towards trusting authoritative pages.** B-02 was corrected by the pack. B-03 was refuted by a ticket that had been sitting under the epic for four months. The one wrong closure came from citing a standing controls page for a question it does not answer — the same reflex, in a place where no document contradicted it.
2. **The repository's absence cost two of the five room contributions and produced the only wrong closure.** H-03 and H-07 are facts a code pass holds; C5 closed because nobody could open a manifest. Against run4, the expected delta is that these disappear — the pack states them, the room confirms, and the session gets shorter and better.
3. **The ownership question is the only thing here that no pack can produce.** A-01 required a room, four people answering in sequence, and a facilitator willing to sit in the silence afterwards rather than resolve it. It is the highest-value ninety seconds in the transcript and it is the argument for holding the session at all, in any cell.
