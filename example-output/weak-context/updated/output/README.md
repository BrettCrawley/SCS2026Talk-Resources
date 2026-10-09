# PLAT-2810 Internal AI Assistant — Security Review Pack

**Date:** 2026-09-09 · **Version:** 1.1 (validation-session merge)
**Supersedes:** version 1.0 of 2026-09-09, the pre-session pack.
**Prepared by:** Brett Crawley, Principal Application Security Engineer — produced with AI assistance.
**Model:** Claude Opus 5
**Validated:** validation session of 2026-09-09, 14:00 to 15:35, facilitated by Brett Crawley with the epic owner, the lead architect, the engineer who built the pilot, the Support engineering manager, the Data Protection Officer and the Platform Security Champion. Log at `06-threat-model.md` Appendix G.

A design-stage security and privacy review of the internal AI assistant described in epic PLAT-2810 and its four child stories, with the trust-boundary sketch supplied alongside them, updated from the owners' validation session.

**Session provenance.** Every claim in this pack that came from the validation session rather than from the supplied tickets is tagged **`[session 2026-09-09]`** at the point it is made, with the speaker named where it asserts a fact about the running system. Where the session contradicted an assumption version 1.0 made, it is marked **`[contradicts v1.0]`** and stated in place rather than edited away. Untagged text still rests on 2.5 KB of tickets and one diagram.

---

## Read in this order

| # | Document | What it is |
|---|---|---|
| **00** | [`00-context-sources-and-open-questions.md`](00-context-sources-and-open-questions.md) | **Read first.** What was supplied, what was requested but absent, what each absence costs, and the twenty questions this review could not answer with what it was given |
| **01** | [`01-security-review.md`](01-security-review.md) | Executive summary, risk posture, regulatory position, gate readiness and prioritised recommendations |
| **02** | [`02-use-abuse-and-security-privacy-use-cases.md`](02-use-abuse-and-security-privacy-use-cases.md) | Ten use cases, fifteen security abuse cases, seven privacy abuse cases, and the counter-use cases that close them |
| **03** | [`03-security-architecture.md`](03-security-architecture.md) | Architecture reconstructed from the acceptance criteria, eight trust boundaries, data model and classification, and the four architectural changes required |
| **04** | [`04-gap-analysis.md`](04-gap-analysis.md) | Requirements classification, thirty gaps, regulatory assessment, **fifty-seven** refined requirements and the recommended sequence |
| **05** | [`05-srtm-and-test-artefacts.md`](05-srtm-and-test-artefacts.md) | Requirements traceability matrix and fifty-eight test artefact definitions |
| **06** | [`06-threat-model.md`](06-threat-model.md) | **Seventy-four** findings across ten buckets, coverage tables for every instrument walked, three MITRE ATLAS attack paths, the risk register, and **the validation session log at Appendix G** |
| **06a** | [`06-threat-model-candidates.md`](06-threat-model-candidates.md) | The phase-1 elicitation record: one row per prompt, 139 rows, written before any finding was drafted, plus the session addendum recording the two findings the walk did not produce |

> **Count correction** `[session 2026-09-09 · Priya Raghunathan]`**.** Version 1.0 of this table said *forty-nine* refined requirements. It is **fifty-seven** — thirty-eight SEC, eleven PRV, eight COMP — and the SRTM already traced all of them. The count was taken before the compliance block was added and never redone.

The file numbers are reading order. Writing order differed: the context document first, then use cases, the architecture map, abuse cases, the candidate register, the threat model, counter-use cases, the gap analysis, the architecture evaluation, the SRTM, and the security review last.

---

## The headline, in three sentences

The assistant as specified can be made to send corporate data to a stranger who has done nothing more than email a member of staff — no credential, no click. Two acceptance criteria cause it: **PLAT-2814** treats four connectors as trusted because they sit behind authentication, which governs who may *read* a mailbox and not who *wrote* the message in it; and **PLAT-2817** removes the confirmation step from every action, including sending mail and committing code. Fourteen findings are Critical; fixing that pair closes seven of them and **seven survive it**, so the pair is the highest-value change in the pack and one of four gates rather than a substitute for them.

**Two sentences the validation session added** `[session 2026-09-09]`**.** The connector the pilot most wants is a *shared* Support mailbox in which every message is authored by a customer or a stranger, so the attacker-authored half of the path is a named daily flow rather than a category. And **the trusted-internal-sources position was never decided by anybody** — a product scoping note, an ADR that cites it, an architecture page that cites the ADR, and an assumed platform sanitiser that is not in the path. That is finding **O5**.

> **Arithmetic correction** `[session 2026-09-09 · Priya Raghunathan]`**.** Version 1.0 of this paragraph said *eleven of the fourteen collapse into that pair* and that fixing it takes the Critical count to three. **Both were wrong and they were two different counts wearing one number** — everything the pair makes reachable, and everything it closes. The pair closes seven Criticals; seven survive it: I2, AI8, I3, AI11, E1, E2, T2. Corrected in `01-security-review.md` §1 and §3 and in `06-threat-model.md` §9 and §10.

---

## What this review rests on, and what it does not

**Supplied:** `input/plat-2810-epic.md` (five Jira issues, 2.5 KB) and `input/diagram1-assumed.svg`. That is all.

**Requested but absent:** Confluence design pages; PMO and PMI tickets; git repositories, Terraform and Helm charts; data schemas; the identity design; deployment topology; the model provider's identity and contract; and every privacy artefact.

**Consequences, stated plainly.** The design-versus-implementation reconciliation could not be performed — there is no implementation. The cloud and container threat surfaces were not walked, because no infrastructure information exists to walk them against. No finding can be recorded as mitigated, because nothing supplied asserts that any control has been built. Every finding is a design-time finding.

**What was walked, exhaustively:** STRIPED (57 prompts), LINDDUN and the AI-specific privacy categories (9), privacy dark patterns and human-centered security (16), the Elevation of Autonomy deck (30 cards), and the AI extension instrument (20) — 132 prompts, every outcome recorded in the candidate register.

---

## Status

**The validation session has been held** — 2026-09-09, 14:00 to 15:35, seven attendees, facilitated by Brett Crawley. Version 1.1 is the transcript merged back into the pack. Appendix G of the threat model is now the session log.

**What came out of it, without varnish.** No finding was closed — not one of seventy-two moved to 🟢 Mitigated. Two findings were added (**O5**, **O6**). Two ratings moved and **both moved up**: P6 from Medium to High, and AI3's likelihood from Medium to High. Five corrections were made to the pack itself, two of them arithmetic errors found by the team rather than by the reviewer. Three questions were answered in whole or part, and thirteen findings are now queued against three named pieces of evidence with dates. Eighteen actions have owners.

**That is a smaller result than a validation session is usually expected to produce, and a more useful one than it looks.** It turned a document that says "not stated" into one that says what is actually true in about a dozen places, and it established that a decision everyone assumed had been made was never made by anybody.

**What is still not agreed.** Roughly fifty findings were not walked — the session's scope was the six launch gates, the regulatory section and the four headline questions. Those findings carry their version 1.0 rating because nobody looked at them, which is **not** the same as their being confirmed. A second session is scheduled for 2026-09-30.

**No risk was formally accepted in the session.** The three residuals version 1.0 proposed for ratification were not reached and carry no owner yet.

The deterministic house-style gate — `check_deliverable.py` and `check_candidates.py` — was left to an external checker for version 1.0, because command execution was disabled in the session that produced these documents. Both are idempotent and should be run before the pack is recirculated.
