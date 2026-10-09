# Internal AI Assistant — Security Analysis Pack

**Version:** 1.1 (post-validation-session) · **Date:** 2026-09-09 · **Reviewer and facilitator:** Brett Crawley, Principal Application Security Engineer · **Model:** Claude Opus 5

Security and privacy analysis of the internal AI assistant delivered under epic PLAT-2810, initiative PROD-1131 and portfolio PMO-0447, produced from the Confluence design pages and the Jira hierarchy supplied in `./input`. **No repository was supplied for this pass** — no source code, Terraform, Helm charts or schemas — so every finding rests on the design documentation and the tickets, and no documentation-versus-code comparison was possible.

**Version 1.1 merges the validation session of 2026-09-09, 13:30–15:08**, facilitated by Brett Crawley with Dana Whitfield (Product), Marcus Oyelaran (architecture and engineering owner), Priya Raghunathan (orchestrator and connectors), Tom Egerton (Support), Ines Ferreira (Data Protection Officer) and Kwame Osei (Security Champion, Platform). The transcript ships with this pack. **The repository is still absent** — the session converted a handful of "if present" findings into observations and left the rest exactly as they were.

## Provenance tagging

Every claim in v1.1 that derives from the session carries an inline tag, so its origin survives the next edit of these documents. Untagged text is v1.0 material that the session did not touch.

| Tag | Meaning |
|---|---|
| `[VS §n · CONFIRMED]` | A named owner confirmed the pack's statement as fact. Section `n` of the transcript |
| `[VS §n · CORRECTED]` | The pack was wrong. The correction and its rationale are recorded, not quietly applied |
| `[VS §n · NEW]` | A fact or finding raised in the session that appears in no supplied document |
| `[VS §n · CONTESTED]` | Disagreement recorded and left unresolved, with the shape of the resolution named |
| `[VS §n · ACCEPTED]` | Risk accepted, with an owner and any dissent recorded |
| `[VS §n · CLOSED]` | Finding closed on an owner's answer |
| `[VS §n · STILL OPEN]` | Question put to the room and not answered. Nobody was asked to guess |

## Delta from v1.0 — headline

| # | Change | Findings | Provenance |
|---|---|---|---|
| 1 | **The architecture page's Authorisation paragraph is confirmed inaccurate by its own author.** Q5 answered: the orchestrator does not carry the requesting user's identity into the connector call, not even as a field | O1, E1, S2, R2 | `[VS §1]` |
| 2 | **T3 corrected: Partially mitigated → Open; likelihood Medium → High.** Branch protection bounds a path the assistant does not take. Appendix F amended | T3 | `[VS §2]` |
| 3 | **New: a standing `platform-ci` exemption from branch protection exists in a config file and in no document in the estate** | **O6** (new) | `[VS §2]` |
| 4 | **New: the decision that internal content needs no sanitising was never taken.** A scoping note was inherited as a security position through three artefacts. The pack assumed a decision existed; it does not | **O7** (new), AI1, AI6 | `[VS §3]` |
| 5 | **P1 corrected: customer data reaches context, Redis and the model provider — not the telemetry warehouse.** Severity Critical unchanged and its rationale unaffected | P1 | `[VS §7]` |
| 6 | **NIS2 corrected: the sector question resolves to "no", and the obligations apply anyway** — two customers are essential or important entities and their contracts pass the measures down. A route the pack could not see | O3, §7 | `[VS §7]` |
| 7 | **ISO 27001 corrected: not certified, so it does not apply.** SOC 2 Type II is what is held | §7 | `[VS §7]` |
| 8 | **New: the two customers whose contracts carry the NIS2 obligation are the two whose correspondence is most heavily in scope**, arriving over three Slack Connect channels and the shared mailbox | **P8** (new), AI1, P1 | `[VS §3, §7]` |
| 9 | **C5 closed** as covered by the platform workload-identity baseline, owner Kwame Osei, over a recorded engineering reservation | C5 | `[VS §8]` |
| 10 | **AI10, AI12 and C3 promoted from assertion-of-absence to observation.** All four MCP servers run on the `latest` tag with no digest anywhere | AI10, AI12, C3 | `[VS §8]` |
| 11 | **AI3, P2, R1, R3, D1/D3 confirmed** against the code by the engineer who wrote it | AI3, P2, R1, R3, D1, D3 | `[VS §5, §6, §7, §9]` |
| 12 | **AI4 contested on the shape of the fix, not on the finding.** A risk-based confirmation model is owed in three weeks | AI4 | `[VS §5]` |

Full delta, row per finding, in `06-threat-model.md` Appendix H. The session's own action list is Appendix I.

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
| `06-threat-model.md` | The findings themselves, with worked examples, coverage tables and the risk register. Appendix G is now the session log; Appendix H is the finding-level delta; Appendix I is the action register |
| `transcript.md` | The validation session transcript, shipped with the pack so every tagged claim can be read back to its source |

Authoring order is recorded in the documents' own version lines: the architecture map was written before the threat model and its evaluation after it, and the counter-use cases (SUC, PUC) were authored after the threat model so that each one counters an identified finding.

## Result

**71 findings: 7 Critical, 40 High, 24 Medium.** Status: 59 Open · 4 Partially mitigated · 7 Planned · 0 Mitigated · 1 Accepted.

| | v1.0 | v1.1 | Why |
|---|---|---|---|
| Findings | 68 | **71** | O6, O7 and P8 raised in the session `[VS §2, §3, §7]` |
| Critical | 7 | 7 | No severity crossed the Critical line in either direction |
| High | 37 | **40** | The three new findings are all High |
| Open | 56 | **59** | T3 Partial → Open; C5 Open → Accepted; three new Open |
| Partially mitigated | 5 | **4** | T3's partial mitigation bounded a path the assistant does not take |
| Accepted | 0 | **1** | C5, owner Kwame Osei |

Buckets: Spoofing 5 · Tampering 4 · Repudiation 5 · Information Disclosure 4 · Privacy 8 · Elevation of Privilege 5 · Denial of Service 5 · Cross-cutting 7 · AI/ML 15 · Cloud 6 · Container 6 · Recovery and Resilience 1.

Seven Critical findings is a high count for a system this size, and the reason is concentration rather than breadth: five of the seven — S2, E1, O1, AI1 and AI3 — describe one structural condition from five angles, namely that the assistant holds a credential nobody's entitlements bound, the documentation says otherwise, untrusted content can direct it, and nothing constrains what it does with it. Fix delegated authorisation and add argument allowlists and the Critical count falls to two. The remaining two are independent: AI2 is an exfiltration channel that closes with a response header, and P1 is a lawful-basis question that closes with a decision. **The session disputed none of this.** `[VS §1 · CONFIRMED]`

All 71 findings are net-new. No parent or programme threat model was supplied or referenced, so there was nothing to reconcile against — the organisation has a control baseline in the platform security controls page but no threat baseline.

## What the session changed about how this pack should be read

Three of the v1.0 pack's own assumptions did not survive the room, and they are named here rather than edited away.

1. **The pack assumed that somebody had decided internal content does not need sanitising.** It reasoned about the *quality* of that decision. `[VS §3 · CORRECTED]` The decision does not exist. Dana Whitfield wrote a scoping note on PLAT-2814; Priya Raghunathan implemented it as a security position; Marcus Oyelaran wrote it into the architecture page's trust model believing it had been assessed; Kwame Osei assumed the sanitiser was a platform control covering everything. Three artefacts each point at another and there is no decision at the end of the chain. This is finding **O7**, and its remedy is a decision to be taken, not a document to be corrected. It was deliberately not resolved in the session.
2. **The pack credited branch protection with partially mitigating T3.** `[VS §2 · CORRECTED]` It bounds protected branches; the assistant commits to working branches. The credit was for a path the assistant does not take. Separately, a standing `platform-ci` exemption exists in a config file in the org repo and in no Confluence page — so the boundary could not have been proven from the documentation even where it does apply (**O6**).
3. **The pack treated NIS2 as "applicability undetermined, pending the sector question".** `[VS §7 · CORRECTED]` The sector question resolves to *no* — the organisation is not an essential or important entity. The obligations land anyway, contractually, from two customers who are. The pack's frame was not merely unanswered; it was missing a route, because that route lives in two contracts nobody supplied.

## Caveats

**The validation session has now been held and its outcomes are tagged inline throughout.** What it did not do was replace the missing repository: the eleven "if present" findings are still eleven "if present" findings, less the handful Priya Raghunathan converted to observations from memory of work she did herself. `[VS §10 · STILL OPEN]` Nobody in the room was asked to guess, and C2, C4, CL4, CL5 and CL6 remain open and unconfirmed as a result. Two seats were empty and both matter: Identity Platform, who own the dependency behind three Critical findings, did not respond; Data Platform, who hold the model provider agreement behind P4, declined. The owner of the standing platform security controls page was also absent — Kwame Osei attended as Security Champion and does not own that page, which bounds what §2's and §8's answers can be relied on for.

No repository was in scope, so nothing here reports on implementation, and any place where the code and the documentation disagree is still outside what this pack can see. Command execution was disabled in this session, so the house-style shipping checks were not run by the author — they were run externally against the finished pack and both the candidate register and the deliverable checker passed with zero failures. Nothing in this pack is legal advice.
