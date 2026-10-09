# Internal AI Assistant — Security Analysis Pack

**Version:** 1.1 — validation session of 2026-09-08 merged, plus the directed second pass of 2026-09-08 · **Date:** 2026-09-08
**Reviewer and facilitator:** **Brett Crawley, Principal Application Security Engineer** · **Model:** Claude Opus 5
**Supersedes:** version 1.0 of 2026-09-08 (pre-validation)

Security and privacy analysis of the internal AI assistant delivered under epic PLAT-2810, initiative PROD-1131 and portfolio PMO-0447, produced from the Confluence design pages, the Jira hierarchy and the `assistant-platform` repository supplied in `./input`, and **validated on 2026-09-08 in a 74-minute session with the seven people who own the system**.

---

## Provenance convention used throughout this version

Every claim added, changed or confirmed by the validation session carries an inline tag so its origin survives independently of this README. The tag set is identical in all eight documents.

| Tag | Meaning |
|---|---|
| `[VS · confirmed]` | The session confirmed the finding as written. No text changed |
| `[VS · corrected]` | The session corrected the pack. The correction is described where it appears |
| `[VS · new]` | A fact, finding or instance first raised in the session and not present in v1.0 |
| `[VS · contradicts]` | The session contradicted an assumption the pack or the approved material made. Stated explicitly, never edited away silently |
| `[VS · accepted, owner: NAME]` | A risk carried knowingly, with the named person who carries it |
| `[VS · moved]` | A severity or status movement, with its rationale |
| `[RV · editorial]` | A reviewer-applied correction made while merging, **not** raised in the session. Distinguished deliberately so the session record is not inflated |
| `[DP2 · new]` | A finding, artefact or claim first raised in the **directed second pass of 2026-09-08**, after the validation session. Kept separate for the same reason as `[RV · editorial]` |
| `[DP2 · extends]` | An existing entry amended by that pass, keeping its identifier, severity and status |
| `[DP2 · confirmed]` | Something the pass checked and found already correct, or an observation about the supplied artefact rather than the system |
| `[DP2 · dismissed]` | An existing finding considered as coverage for a tested scenario and rejected, with the reason recorded |

`VS` = validation session, 2026-09-08, facilitated by Brett Crawley. Attendees are listed in `00-context-sources-and-open-questions.md` section 5 and in Appendix G of the threat model. Where a fact came from one person it is attributed inline, for example `[VS · new · P. Raghunathan]`.

---

## Files, in reading order

| File | What it is |
|---|---|
| `00-context-sources-and-open-questions.md` | What was supplied, what was not, the questions this pass could not answer, and which of them the session closed |
| `01-security-review.md` | Executive verdict, risk posture, regulatory position, prioritised recommendations and gate readiness |
| `02-use-abuse-and-security-privacy-use-cases.md` | 12 use cases, 15 security abuse cases, 8 privacy abuse cases, 40 security use cases and 8 privacy use cases |
| `03-security-architecture.md` | The system as designed and as built, 12 trust boundaries, the data model, 14 documentation-versus-code divergences, and the target design |
| `04-gap-analysis.md` | Requirements classified, 37 gaps, regulatory assessment, refined requirement superset and the recommended sequence |
| `05-srtm-and-test-artefacts.md` | Traceability matrix and 62 test artefact definitions |
| `06-threat-model-candidates.md` | The phase-one elicitation record: 217 prompts across seven instruments, one row each |
| `06-threat-model.md` | The findings themselves, with worked examples, coverage tables, the risk register, **section 0, the directed second pass record**, and **Appendix G, the session validation log** |

Written in authoring order — context, use cases, architecture map, abuse cases, candidate register, threat model, counter-use cases, gap analysis, architecture evaluation, SRTM, test artefacts, and the security review last. Version 1.1 merges the session across all eight without re-authoring them.

---

## Result

**75 findings: 5 Critical, 30 High, 36 Medium, 4 Low.** `[DP2 · new]` Buckets: Spoofing 5 · Tampering 4 · Repudiation 5 · Information Disclosure 5 · Privacy 6 · Elevation of Privilege 6 · Denial of Service 5 · Cross-cutting 7 · AI/ML **19** · Cloud 4 · Container 6 · Recovery and Resilience 3.

By status: **63 Open · 6 Planned · 2 Partial · 4 Accepted with a named owner · 0 Mitigated.**

The headline is unchanged and was confirmed in the room: an organisation-wide credential (ADR-0002), unfiltered retrieval across five sources (ADR-0004) and write actions with no confirmation (ADR-0003) meet in one process, so anyone who can author content the assistant might read can cause it to act. The approved architecture page describes a different system, and three of the seven people in the session were reasoning from that page rather than from the code. `[VS · confirmed]`

---

## Directed second pass, 2026-09-08 `[DP2]`

After the validation session, a directed pass tested **two reviewer-supplied scenarios** against the pack and the code. One verdict was required per scenario — covered, refuted or new. **Both returned new**, and the register moved from 73 findings to 75.

| Scenario | Verdict | Finding | In one line |
|---|---|---|---|
| An afternoon draft to a customer, composed in a conversation that still carries the morning's incident. No attacker | **New** | **AI18** — High 🔴 | A conversation is one undifferentiated context for 24 hours and nothing in the code knows what any part of it was gathered for, so material retrieved for one purpose composes an output for another |
| An author who steers the assistant by writing **volume** rather than an instruction payload | **New** | **AI19** — High 🔴 | The merge keeps the first eight chunks of a fixed-order concatenation with no score, no per-source or per-author cap and no dedupe, so share of voice is decided by position and quantity |

**Neither verdict was reached by stretching an existing finding, and the near misses are recorded rather than glossed.** AI7 and D4 carry AI18's *mechanism* — the untrimmed 24-hour context — but state the harm as behavioural drift and as cost; P5 carries the word *purpose* but only within a single turn, and its connector allowlist would have kept every source involved in either scenario. AI1 was not stretched to cover a scenario with no injection, and AI6 was not stretched to cover a scenario with nothing to sanitise. Section 0 of the threat model lists every finding considered as coverage, with the reason each was dismissed.

**Two things the pass found in the code that were not previously written down.** The merged retrieval list is ordered by the connector array in `registry.ts:11`, so Confluence — the one source an outsider cannot author into, added specifically for the Support pilot — is fourth of five and contributes nothing whenever the three connectors ahead of it return eight rows between them; and the sanitiser sits on `websearch`, which is fifth, so the only content control in the system protects the source least likely of all to reach the model. Separately, `connectors.json` carries a `contentIsExternal` field that **nothing in the tree reads**, and it is recorded `false` for Slack while three Slack Connect channels shared with customers are covered by `search_messages`.

**What did not change.** No severity moved in either direction. No status moved. Nothing was closed or withdrawn. The five Criticals, the launch gates and the whole session record stand as written. Neither new finding has been put to the seven people who own the system, because the pass ran after the session; both need a disposition at the next one.

Propagated as: findings **AI18**, **AI19** · gaps **G-36**, **G-37** · requirements **SEC-40**, **SEC-41** · abuse cases **SAC-15**, **PAC-08** · counter-use cases **SUC-39**, **SUC-40**, **PUC-08** · test artefacts **TA-61**, **TA-62**, with **TA-59** gaining a fifth objective. Neither finding was elicited by the seven instruments. In `06-threat-model-candidates.md` both are carried under that file's existing **"Beyond the instrument"** convention, alongside **O7** — so the candidate register and the threat model register now both read 75, and no finding sits in one without a row in the other. **No prompt row was altered, reweighted or invented:** the instrument walk still reads 217 prompts, 152 rows, 72 findings, and each of the three findings no prompt produced carries a note saying which prompt would have had to exist. The instrument gap is recorded rather than papered over — the prompts ask about injection and about what reaches the prompt, and none asks what an untrimmed context discloses when nobody attacks it, or what bounds one author's share when every chunk is instruction-free.

---

## Master delta, version 1.0 to version 1.1

### Register movements

| ID | 1.0 | 1.1 | Rationale | Tag |
|---|---|---|---|---|
| **AI3** | Critical ⚪ Accepted in ADR-0003 | Critical 🔴 **Open** | The product owner withdrew the acceptance in the room. It had been made on the basis that a human reads the action list; AI13 shows the list carries tool names only, and Support's engineering manager confirmed nobody reads it. Owners: D. Whitfield and P. Raghunathan | `[VS · moved]` |
| **D2** | High 🔵 Planned, PLAT-2822-4 | High ⚪ **Accepted for the pilot** | The product owner elected to carry the risk for the remainder of the pilot in favour of sequencing the confirmation gate first, and to record it on the ticket. Revisit at expansion. Owner: D. Whitfield | `[VS · moved]` |
| **O7** | — | Medium 🔴 **Open** *(new)* | The standing platform controls page states inherited controls without stating their coverage limits. Two senior people in the session applied the egress proxy to a browser-side fetch it cannot see | `[VS · new]` |

**No severity was raised or lowered. No finding was closed.** The facilitator's spoken summary was "two severity movements"; on the record both movements are **status** movements — AI3 and D2 — and the severity column is unchanged throughout. That reconciliation is recorded rather than resolved silently. `[RV · editorial]`

### Corrections to the pack

| # | Correction | Raised by | Effect |
|---|---|---|---|
| **C-01** | S3's example threat had an outsider read a console link from a Slack Connect channel and reach the console over the VPN with the shared password. **They cannot: the VPN carries MFA**, which the pack's own control table in threat model section 4 records. The example is rewritten to the internal path. S5's contractor example stands, because a contractor pending offboarding still holds a VPN credential | K. Osei | Example threat rewritten. **Finding unchanged at High** — the defect is that `history.resolve` performs no ownership check and a resumed turn runs as the stored user |
| **C-02** | The architecture document's per-store table cited G-14 to G-17 as the deletion-path gaps. Those are the confirmation gate, the Redis store, the IAM role and the widening defaults. **The erasure gap is G-20** | P. Raghunathan | Four cross-references repointed. No finding affected |
| **C-03** | Extending C-02: the gap analysis headline cited gap ranges for four of its six themes that do not match the consolidated gap list either | Reviewer, while merging | Four theme citations repointed. **Not raised in the session** and tagged `[RV · editorial]` so the session record is not inflated |
| **C-04** | The v1.0 status roll-up read "8 Planned" against a register containing 7 | Reviewer, while merging | Arithmetic corrected. `[RV · editorial]` |

### Assumptions the session contradicted

Stated here rather than edited away, because each one is a finding about how the material is read.

1. **"The assistant acts as the requesting user."** Decision D-03, the approved architecture page, and the working descriptions given to Platform and to Support. `credentialFor` returns one application-scoped token per connector and the user argument is prefixed with an underscore because it is unused. The pack was right; **three people in the room had been describing a system that does not exist**, and one of them had told the Support group at onboarding that the assistant cannot see anything they cannot see. That statement was wrong the day it was made. `[VS · contradicts]`
2. **"Branch protection bounds the blast radius."** True estate-wide, false for three repositories — and the exemptions live in a config file in the org repo, not in Confluence, so a reader reasoning from the approved controls page cannot see them. `[VS · contradicts]`
3. **"The egress proxy closes the exfiltration path."** Raised against AI4 and withdrawn in the room: the markdown image fetch happens in the user's browser, not in the cluster. The pack already said so in two places. What the session produced instead is O7 and an action to add a coverage note to the standing page. `[VS · contradicts]`
4. **"Internal content is behind authentication so needs no cleaning."** Gap G-05 recorded the premise as false. The session established something the pack could not: **nobody made that decision.** It was written as scoping on a story, implemented as though it were a position, written into the approved trust model because the ticket and the code agreed, and assumed by Platform to be covered by a platform sanitiser that does not exist on this path. `[VS · contradicts]`
5. **NIS2 applicability was open question 1 and is not open.** Meridian is **neither an essential nor an important entity** — that determination exists and is not new. The obligation nonetheless arrives, **contractually**, through two customers who are themselves in scope. The route differs from the one the pack assumed; the practical effect on this system does not. `[VS · contradicts]`
6. **SOC 2 was hedged as "applies where a report covers this estate".** It is not conditional: **Meridian is SOC 2 Type II and the report covers this estate.** Separately, Meridian is **not** ISO 27001 certified, which is widely assumed internally. `[VS · contradicts]`
7. **The Support shared mailbox was treated as one source among several.** It is the **primary** use case — the ticket queue alone does not carry the history, which lives in the mail thread. Worse than the pack assumed in that one respect, and no better in any. `[VS · contradicts]`
8. **AI10 named the community connector as unpinned and vendor versions as "not recorded".** All five connectors, including the four vendor ones, are pinned to `latest`. The class was right; the instance is broader. `[VS · contradicts]`

### Facts the room held that the document did not

Four, by the facilitator's count at the close: two counts, one version string and one contract. `[VS · new]`

| Fact | Source | Effect on the pack |
|---|---|---|
| `commit` has been used **eleven times since July**; nine were the author testing it, two were real, and both were one-line config changes a person could have made faster by hand. Support have never had the tool | P. Raghunathan, T. Egerton | Did not lower E6 or AI17. Produced a **cheaper interim than the pack proposed**: remove `commit` from `ws-platform` today and bring it back through the branch-and-pull-request change |
| **Three Slack Connect channels** are shared with customers; two named enterprise accounts raise issues through them, into channels `search_messages` covers | T. Egerton, P. Raghunathan | AI1's external-author path is not hypothetical here. Recorded as a concrete instance; likelihood already High and now better evidenced |
| **All five connectors are pinned to `latest`** | P. Raghunathan | Broadens AI10 from the community server to the whole connector set |
| **NIS2 arrives through two customer contracts**, not by direct applicability | I. Ferreira | Rewrites the NIS2 position in the review, the gap analysis and the compliance summary |

### Same-day containment applied during or immediately after the session

| Action | Finding | Owner | State |
|---|---|---|---|
| `"read_mail": false` for `ws-support`; ticket queue stays in scope | P1, G-21 | P. Raghunathan | Applied on the day, within ten minutes of the session |
| Remove `commit` from `ws-platform` pending the branch-and-pull-request change | E6, AI17 | P. Raghunathan | Applied on the day |
| Diagnostic routes — **sequenced, not flipped** | I1, I2, O5 | P. Raghunathan (route), K. Osei (standard) | The v1.0 "do today" recommendation to set `EXPOSE_DEBUG_ROUTES: "false"` was overtaken: the incident runbook uses those routes in production and closing them first would blind on-call. The authorised support route is built first, then the flag defaults closed |

### Accepted risks now carried by a named person

T2 (M. Oyelaran, with a length cap and character validation added) · AI12 (D. Whitfield, with `ws-support` moved off `aurora-1-mini` and model choice bounded by what the workspace reads) · D2 (D. Whitfield, for the remainder of the pilot) · O6 (M. Oyelaran, with a local decision register opened whose first row is the content-trust decision). Each was defensible in v1.0 and unowned; the ownership was the gap, and it is closed. `[VS · accepted]`

### The decision that has never been made

Action 7 is the one item in the pack that is not a fix. **Whether internal content requires sanitising has never been decided by anyone.** It is assigned to M. Oyelaran, with data categories from I. Ferreira and pilot needs from D. Whitfield, to be written as an ADR with a named approver by 2026-09-26. It is explicitly not to be answered in flight. `[VS · new]`

---

## Where to find the full session record

`06-threat-model.md` **Appendix G** carries the attendees, the method, the per-finding disposition for all 73 findings, the corrections, the contradicted assumptions, the accepted risks with owners, the severity and status movements, and the facilitator's 30-item action list with owners and dates.

---

## Caveats

**A validation session has now been held**, on 2026-09-08, with the epic owner, the lead architect, the engineer who built the pilot, Support's engineering manager, the Data Protection Officer and a Platform security champion. Every finding in this pack carries a disposition from that session. What remains unvalidated is narrower and is named: the four questions nobody in the room could answer (the GitHub app installation breadth, the granted Slack scope list, the model provider's retention and region terms, and whether the egress allowlist entries went through review), and the six missing inputs listed in `00-context-sources-and-open-questions.md` section 3.

Command execution was disabled in this session, so the house-style shipping checks were not run here — the documents were authored against their rules and the gate is left to the external checker. Nothing in this pack is legal advice; the Article 35 determination, the Article 14 position and the PCI-DSS applicability question sit with the DPO and counsel.
