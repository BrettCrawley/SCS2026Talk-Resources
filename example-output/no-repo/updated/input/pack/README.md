# Internal AI Assistant — Security Analysis Pack

**Date:** 2026-09-09 · **Reviewer:** Brett Crawley, Principal Application Security Engineer · **Model:** Claude Opus 5

Security and privacy analysis of the internal AI assistant delivered under epic PLAT-2810, initiative PROD-1131 and portfolio PMO-0447, produced from the Confluence design pages and the Jira hierarchy supplied in `./input`. **No repository was supplied for this pass** — no source code, Terraform, Helm charts or schemas — so every finding rests on the design documentation and the tickets, and no documentation-versus-code comparison was possible.

## Files, in reading order

| File | What it is |
|---|---|
| `00-context-sources-and-open-questions.md` | What was supplied, what was not, the questions this pass could not answer and what would answer them |
| `01-security-review.md` | Executive verdict, risk posture, regulatory position and prioritised recommendations |
| `02-use-abuse-and-security-privacy-use-cases.md` | 12 use cases, 12 security abuse cases, 8 privacy abuse cases, 12 security use cases and 8 privacy use cases |
| `03-security-architecture.md` | The system as designed, its trust boundaries and data model, and the target design |
| `04-gap-analysis.md` | Requirements classified, 22 gaps, regulatory assessment and 30 refined security requirements |
| `05-srtm-and-test-artefacts.md` | Traceability matrix and 28 test artefact definitions |
| `06-threat-model-candidates.md` | The phase-one elicitation record: 217 prompts across seven instruments — STRIPED 57, PRV·L 9, PRV·DP+H 16, EoA 30, AIX 20, Cumulus 60, CN 25 |
| `06-threat-model.md` | The findings themselves, with worked examples, coverage tables and the risk register |

Authoring order is recorded in the documents' own version lines: the architecture map was written before the threat model and its evaluation after it, and the counter-use cases (SUC, PUC) were authored after the threat model so that each one counters an identified finding.

## Result

**68 findings: 7 Critical, 37 High, 24 Medium.** Status: 56 Open · 5 Partially mitigated · 7 Planned · 0 Mitigated · 0 Accepted.

Buckets: Spoofing 5 · Tampering 4 · Repudiation 5 · Information Disclosure 4 · Privacy 7 · Elevation of Privilege 5 · Denial of Service 5 · Cross-cutting 5 · AI/ML 15 · Cloud 6 · Container 6 · Recovery and Resilience 1.

Seven Critical findings is a high count for a system this size, and the reason is concentration rather than breadth: five of the seven — S2, E1, O1, AI1 and AI3 — describe one structural condition from five angles, namely that the assistant holds a credential nobody's entitlements bound, the documentation says otherwise, untrusted content can direct it, and nothing constrains what it does with it. Fix delegated authorisation and add argument allowlists and the Critical count falls to two. The remaining two are independent: AI2 is an exfiltration channel that closes with a response header, and P1 is a lawful-basis question that closes with a decision.

All 68 findings are net-new. No parent or programme threat model was supplied or referenced, so there was nothing to reconcile against — the organisation has a control baseline in the platform security controls page but no threat baseline.

## Caveats

No validation session has been held; every finding and severity is unvalidated until the team walks it. No repository was in scope, so nothing here reports on implementation, and any place where the code and the documentation disagree is outside what this pass could see. Command execution was disabled in this session, so the house-style shipping checks were not run by the author — they were run externally against the finished pack and both the candidate register and the deliverable checker passed with zero failures. Nothing in this pack is legal advice.
