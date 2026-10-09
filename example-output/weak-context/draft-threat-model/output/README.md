# PLAT-2810 Internal AI Assistant — Security Review Pack

**Date:** 2026-09-09 · **Version:** 1.0
**Prepared by:** Brett Crawley, Principal Application Security Engineer — produced with AI assistance.
**Model:** Claude Opus 5

A design-stage security and privacy review of the internal AI assistant described in epic PLAT-2810 and its four child stories, with the trust-boundary sketch supplied alongside them.

---

## Read in this order

| # | Document | What it is |
|---|---|---|
| **00** | [`00-context-sources-and-open-questions.md`](00-context-sources-and-open-questions.md) | **Read first.** What was supplied, what was requested but absent, what each absence costs, and the twenty questions this review could not answer with what it was given |
| **01** | [`01-security-review.md`](01-security-review.md) | Executive summary, risk posture, regulatory position, gate readiness and prioritised recommendations |
| **02** | [`02-use-abuse-and-security-privacy-use-cases.md`](02-use-abuse-and-security-privacy-use-cases.md) | Ten use cases, fifteen security abuse cases, seven privacy abuse cases, and the counter-use cases that close them |
| **03** | [`03-security-architecture.md`](03-security-architecture.md) | Architecture reconstructed from the acceptance criteria, eight trust boundaries, data model and classification, and the four architectural changes required |
| **04** | [`04-gap-analysis.md`](04-gap-analysis.md) | Requirements classification, thirty gaps, regulatory assessment, forty-nine refined requirements and the recommended sequence |
| **05** | [`05-srtm-and-test-artefacts.md`](05-srtm-and-test-artefacts.md) | Requirements traceability matrix and fifty-eight test artefact definitions |
| **06** | [`06-threat-model.md`](06-threat-model.md) | Seventy-two findings across ten buckets, coverage tables for every instrument walked, three MITRE ATLAS attack paths and the risk register |
| **06a** | [`06-threat-model-candidates.md`](06-threat-model-candidates.md) | The phase-1 elicitation record: one row per prompt, 139 rows, written before any finding was drafted |

The file numbers are reading order. Writing order differed: the context document first, then use cases, the architecture map, abuse cases, the candidate register, the threat model, counter-use cases, the gap analysis, the architecture evaluation, the SRTM, and the security review last.

---

## The headline, in three sentences

The assistant as specified can be made to send corporate data to a stranger who has done nothing more than email a member of staff — no credential, no click. Two acceptance criteria cause it: **PLAT-2814** treats four connectors as trusted because they sit behind authentication, which governs who may *read* a mailbox and not who *wrote* the message in it; and **PLAT-2817** removes the confirmation step from every action, including sending mail and committing code. Fourteen findings are Critical and eleven of them collapse into that pair, so the fix is one sequenced change rather than a programme.

---

## What this review rests on, and what it does not

**Supplied:** `input/plat-2810-epic.md` (five Jira issues, 2.5 KB) and `input/diagram1-assumed.svg`. That is all.

**Requested but absent:** Confluence design pages; PMO and PMI tickets; git repositories, Terraform and Helm charts; data schemas; the identity design; deployment topology; the model provider's identity and contract; and every privacy artefact.

**Consequences, stated plainly.** The design-versus-implementation reconciliation could not be performed — there is no implementation. The cloud and container threat surfaces were not walked, because no infrastructure information exists to walk them against. No finding can be recorded as mitigated, because nothing supplied asserts that any control has been built. Every finding is a design-time finding.

**What was walked, exhaustively:** STRIPED (57 prompts), LINDDUN and the AI-specific privacy categories (9), privacy dark patterns and human-centered security (16), the Elevation of Autonomy deck (30 cards), and the AI extension instrument (20) — 132 prompts, every outcome recorded in the candidate register.

---

## Status

**No validation session has been held.** This is the pre-session pack. Nothing in it should be treated as agreed until the PLAT-2810 owners have walked it, and Appendix G of the threat model becomes a session log at that point.

The deterministic house-style gate — `check_deliverable.py` and `check_candidates.py` — was left to an external checker, because command execution was disabled in the session that produced these documents. Both are idempotent and should be run before the pack is circulated.
