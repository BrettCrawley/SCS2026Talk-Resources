# Internal AI Assistant — Security Analysis Pack

**Version:** 1.1 — validation session of 2026-09-08 merged · **Date:** 2026-09-08
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

`VS` = validation session, 2026-09-08, facilitated by Brett Crawley. Attendees are listed in `00-context-sources-and-open-questions.md` section 5 and in Appendix G of the threat model. Where a fact came from one person it is attributed inline, for example `[VS · new · P. Raghunathan]`.

---

## Files, in reading order

| File | What it is |
|---|---|
| `00-context-sources-and-open-questions.md` | What was supplied, what was not, the questions this pass could not answer, and which of them the session closed |
| `01-security-review.md` | Executive verdict, risk posture, regulatory position, prioritised recommendations and gate readiness |
| `02-use-abuse-and-security-privacy-use-cases.md` | 12 use cases, 14 security abuse cases, 7 privacy abuse cases, 38 security use cases and 7 privacy use cases |
| `03-security-architecture.md` | The system as designed and as built, 12 trust boundaries, the data model, 14 documentation-versus-code divergences, and the target design |
| `04-gap-analysis.md` | Requirements classified, 35 gaps, regulatory assessment, refined requirement superset and the recommended sequence |
| `05-srtm-and-test-artefacts.md` | Traceability matrix and 60 test artefact definitions |
| `06-threat-model-candidates.md` | The phase-one elicitation record: 217 prompts across seven instruments, one row each |
| `06-threat-model.md` | The findings themselves, with worked examples, coverage tables, the risk register and **Appendix G, the session validation log** |

Written in authoring order — context, use cases, architecture map, abuse cases, candidate register, threat model, counter-use cases, gap analysis, architecture evaluation, SRTM, test artefacts, and the security review last. Version 1.1 merges the session across all eight without re-authoring them.

---

## Result

**73 findings: 5 Critical, 28 High, 36 Medium, 4 Low.** Buckets: Spoofing 5 · Tampering 4 · Repudiation 5 · Information Disclosure 5 · Privacy 6 · Elevation of Privilege 6 · Denial of Service 5 · Cross-cutting 7 · AI/ML 17 · Cloud 4 · Container 6 · Recovery and Resilience 3.

By status: **61 Open · 6 Planned · 2 Partial · 4 Accepted with a named owner · 0 Mitigated.**

The headline is unchanged and was confirmed in the room: an organisation-wide credential (ADR-0002), unfiltered retrieval across five sources (ADR-0004) and write actions with no confirmation (ADR-0003) meet in one process, so anyone who can author content the assistant might read can cause it to act. The approved architecture page describes a different system, and three of the seven people in the session were reasoning from that page rather than from the code. `[VS · confirmed]`

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
