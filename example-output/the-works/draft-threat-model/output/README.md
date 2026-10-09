# Internal AI Assistant — Security Analysis Pack

**Date:** 2026-09-08 · **Reviewer:** Brett Crawley, Principal Application Security Engineer · **Model:** Claude Opus 5

Security and privacy analysis of the internal AI assistant delivered under epic PLAT-2810, initiative PROD-1131 and portfolio PMO-0447, produced from the Confluence design pages, the Jira hierarchy and the `assistant-platform` repository supplied in `./input`.

## Files, in reading order

| File | What it is |
|---|---|
| `00-context-sources-and-open-questions.md` | What was supplied, what was not, the questions this pass could not answer and what would answer them |
| `01-security-review.md` | Executive verdict, risk posture, regulatory position, prioritised recommendations and gate readiness |
| `02-use-abuse-and-security-privacy-use-cases.md` | 12 use cases, 14 security abuse cases, 7 privacy abuse cases, 37 security use cases and 7 privacy use cases |
| `03-security-architecture.md` | The system as designed and as built, 12 trust boundaries, the data model, 14 documentation-versus-code divergences, and the target design |
| `04-gap-analysis.md` | Requirements classified, 34 gaps, regulatory assessment, refined requirement superset and the recommended sequence |
| `05-srtm-and-test-artefacts.md` | Traceability matrix and 59 test artefact definitions |
| `06-threat-model-candidates.md` | The phase-one elicitation record: 217 prompts across seven instruments, one row each |
| `06-threat-model.md` | The findings themselves, with worked examples, coverage tables and the risk register |

Written in authoring order — context, use cases, architecture map, abuse cases, candidate register, threat model, counter-use cases, gap analysis, architecture evaluation, SRTM, test artefacts, and the security review last.

## Result

**72 findings: 5 Critical, 28 High, 35 Medium, 4 Low.** Buckets: Spoofing 5 · Tampering 4 · Repudiation 5 · Information Disclosure 5 · Privacy 6 · Elevation of Privilege 6 · Denial of Service 5 · Cross-cutting 6 · AI/ML 17 · Cloud 4 · Container 6 · Recovery and Resilience 3.

The headline is a combination, not a single defect: an organisation-wide credential (ADR-0002), unfiltered retrieval across five sources (ADR-0004) and write actions with no confirmation (ADR-0003) meet in one process, so anyone who can author content the assistant might read can cause it to act. The approved architecture page describes a different system.

## Caveats

No validation session has been held; every finding and severity is unvalidated until the team walks it. Command execution was disabled in this session, so the house-style shipping checks were not run here — the documents were authored against their rules and the gate is left to the external checker. Nothing in this pack is legal advice.
