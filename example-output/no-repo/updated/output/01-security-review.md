# Internal AI Assistant — Security Review

**Version:** 1.1 (post-validation-session) · **Date:** 2026-09-09 · **Classification:** Internal
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this review and facilitator of the validation session. Produced with AI assistance using the security-review skill set authored by Brett Crawley.
**Model:** Claude Opus 5
**Scope:** Epic PLAT-2810 under initiative PROD-1131 and portfolio PMO-0447
**Companion documents:** `00-context-sources-and-open-questions.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md` · `06-threat-model-candidates.md`

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted.
**Provenance legend:** claims derived from the validation session carry `[VS §n · CONFIRMED / CORRECTED / NEW / CONTESTED / ACCEPTED / CLOSED / STILL OPEN]`, where `n` is the transcript section. Untagged text is v1.0 material the session did not touch.

> This is the document to read first and it was written last. It summarises a review of the internal AI assistant against 217 elicitation prompts across seven instruments, producing **71 findings**. It rests on three Confluence pages, two ticket files and the validation session of 2026-09-09. **No source code, infrastructure code, Helm charts or schemas were supplied**, although the engagement brief named git repositories as a source; what that costs is stated in §2 and itemised in the context document, and the session did not close that gap.

---

## 0. What changed in version 1.1

The validation session ran on 2026-09-09, 13:30–15:08, facilitated by the author, with the product owner, the architecture and engineering owner, the engineer who built the orchestrator and connector runtime, Support's engineering manager, the Data Protection Officer and the Platform Security Champion. Identity Platform did not respond; Data Platform declined; the owner of the standing platform security controls page did not attend.

**The short version: nothing was traded down, three things were added, and five things this review had wrong are corrected below rather than quietly edited.**

| # | Change | Effect | Provenance |
|---|---|---|---|
| 1 | The architecture page's Authorisation paragraph is **confirmed inaccurate by its author**, and the orchestrator is confirmed not to carry the user's identity into the connector call at all | O1, E1, S2, R2 confirmed at rating. The headline of this review is no longer an inference | `[VS §1]` |
| 2 | **T3 corrected: Partially mitigated → Open; likelihood Medium → High** | Branch protection bounds a path the assistant does not take. One partial mitigation withdrawn | `[VS §2]` |
| 3 | **New finding O6** — branch protection carries a standing `platform-ci` exemption recorded in no citable document | The boundary could not have been verified from the documentation even where it applies | `[VS §2]` |
| 4 | **New finding O7** — the position that internal content needs no sanitising **was never decided**; a scoping note was inherited as a security position through three artefacts | This review assumed a decision existed and assessed its quality. It does not exist | `[VS §3]` |
| 5 | **P1 corrected** — customer data reaches context, Redis and the model provider, **not** the telemetry warehouse | Severity Critical unchanged; the reason it is Critical is unaffected | `[VS §7]` |
| 6 | **NIS2 corrected** — the sector question resolves to *no*, and the Article 21 measures apply anyway, contractually, through two customers who are essential or important entities | §5's "applicability undetermined" framing was incomplete, not merely unanswered | `[VS §7]` |
| 7 | **ISO 27001 corrected** — not certified, so it does not apply. **SOC 2 Type II confirmed** as what is held | One conditional row resolved to not applicable | `[VS §7]` |
| 8 | **New finding P8** — the two customers whose contracts carry the NIS2 obligation are the two whose correspondence is most heavily in scope, arriving over three Slack Connect channels | A concentration that lived in two people's heads and no artefact | `[VS §3, §7]` |
| 9 | **AI2's cost corrected: a day → about three days** across two owners | The recommendation is unchanged; the estimate in §1 and §6 was wrong | `[VS §4]` |
| 10 | **C5 closed** on the platform workload-identity baseline, carried as accepted risk **AR-01** with an engineer's dissent recorded | First accepted risk in the pack | `[VS §8]` |
| 11 | **AI10, AI12 and C3 promoted from assertion-of-absence to observation** — all four MCP servers run on `latest`, no digest anywhere | Confidence raised; severities unchanged | `[VS §8]` |
| 12 | **AI4 contested on the shape of the fix, not the finding.** Accepted risk **AR-02**, time-boxed three weeks | The finding was not changed on the strength of an argument about the remedy | `[VS §5]` |

Finding-level detail is `06-threat-model.md` Appendix H; the session log is Appendix G; the action register is Appendix I; the transcript ships as `transcript.md`.

---

## 1. Executive summary

The internal AI assistant is a well-shaped system with two open ends and a documentation problem that hides one of them. `[VS · v1.1]` The validation session left that verdict intact and made the documentation problem larger: it is not one page's error but the estate's convention, and the session found two more instances of it (**O6**, **O7**) in ninety-eight minutes.

The team made the right structural decisions early. **D-03**, taken on 2026-04-02 before the connector runtime existed, says the assistant acts as the requesting user rather than as a system identity — which is the correct architecture for an agentic system with tool access, and most organisations reach it after an incident rather than before a pilot. **D-05** refused to build a new system of record. The inherited platform baseline — egress allowlisting since 2023, branch protection with signed commits, organisation-wide secret scanning, blocking dependency scans, default-deny network policy — is stronger than most, and eleven of this review's elicitation prompts close on it outright.

**The problem is that D-03 was decided and not delivered, and the approved architecture page describes it as delivered.** `[VS §1 · CONFIRMED]` Confirmed in the validation session by the page's own author and owner — "It's accurate about D-03. It isn't accurate about what runs" — and by the engineer who built the orchestrator, who confirmed that the requesting user's identity is dropped before the MCP client sees it and that there is no user field on the connector call. Three people in the room had believed the control was in place, all citing the same approved page, while the ticket contradicting it had sat under the epic since May; the product owner had reported the control as fact to the steering group twice in writing. PLAT-2820 is To Do. Its first task has been blocked on the Identity Platform team since 2026-04-18 and is not scheduled. PLAT-2820-3 records what runs instead: one app registration with application permissions across all connectors. The consequence is that the assistant currently reaches every mailbox, every channel and every repository in the tenant, for any user who can start a conversation, and the page that the architecture forum approved on 2026-05-20 states the opposite. Anyone designing against that page is building on a control that does not exist.

**The second open end is that the trust boundary is drawn around the network rather than around who wrote the content.** The architecture page names web search as "the one place untrusted content enters". Support's pilot, live since 2026-06-09, reads a shared mailbox of entirely customer-authored mail — **one shared address, not nine individual mailboxes, and the primary reason Support wanted the assistant at all** `[VS §3 · NEW]`; the GitHub connector reads issues from outside contributors; and **three Slack Connect channels carry customer-authored content, two of them serving the enterprise accounts whose escalations are read into the assistant most days** `[VS §3 · NEW]`. Content written by unauthenticated strangers reaches the model as instructions, and because of the first problem the tool calls it produces execute with tenant-wide reach. The exit route is a markdown image tag rendered by the user's own browser — a path the egress proxy cannot see, and one the team already observed and recorded as "Renders fine, looks odd. Not investigated." `[VS §4 · CONFIRMED]` Both the Platform Security Champion and the architecture owner entered the session believing the egress proxy covered that path and left having agreed it cannot; the Champion had cited the proxy in two design reviews this quarter.

**And a third thing this review did not know, which changes what the second one needs.** `[VS §3 · CORRECTED]` This review treated the design's position — that internal sources are already behind authentication and so need no sanitising — as a security decision somebody had taken and got wrong. **It was never taken.** The product owner wrote it as a scoping note on one story; the engineer implemented it as a security position because it was an acceptance criterion on an approved story; the architect wrote it into the trust model believing it had been assessed; the Security Champion assumed the sanitiser was a platform control covering everything. Three artefacts each pointing at another, and nothing at the end of the chain. That is finding **O7**, and its remedy is a decision to be taken rather than a page to be corrected — which matters, because correcting the page would otherwise look like closing it.

Those two conditions combine into a single attack that needs no credential at any stage: **send an email to the published support address, and a Support agent asking for a customer summary causes a private repository to be read and its contents sent to an attacker-controlled host.** That path is described end to end, with its ATLAS technique sequence, in the threat model. Two deterministic controls break it, and both are currently absent: per-user delegated authorisation, which is blocked at portfolio level, and a Content Security Policy header, which is **a day for the header and about three days once the markdown subset across both renderers and the outbound composer is included** `[VS §4 · CORRECTED]`.

Seven Critical findings sounds like a lot for a system this small, and it is concentration rather than breadth: five of them describe one structural condition from five angles. Deliver PLAT-2820, add argument allowlists and ship the output filter, and the Critical count falls to two. Nothing in this review is a reason not to build this system. Several are reasons not to expand the pilot again first. `[VS §1 · CONFIRMED]` The session disputed none of this and reduced nothing; it added three findings and withdrew one compensating control.

**The three things to do this month.** Escalate the Identity Platform dependency at portfolio level — it is not a backlog item, it is three Critical findings behind an unscheduled external team, **and the same team blocks the interim control as well as the permanent one, which this review had not appreciated** `[VS §1 · NEW]`. Correct the architecture page, which costs an hour and stops the gap propagating. Ship the Content Security Policy and markdown-subset change, which closes the credential-free path on its own.

**And one thing the session added to that list.** `[VS §3, §9 · NEW]` **Take the input-channel trust decision (O7).** It is not a fix, it is a decision, and it is one of the three items the product owner set as a standing gate on further pilot expansion — alongside the output filter (AI2) and the Support mailbox exclusion (P1). It was deliberately not resolved in the room: "a decision that gets made in ninety seconds at the end of an hour isn't better than the one we're missing."

---

## 2. Scope and method

**What was analysed.** Three Confluence pages — the approved architecture page (2026-05-22), the draft data handling and pilot operations page (2026-06-30), and the approved standing platform security controls reference (2025-11-14) — one SVG diagram, and the full Jira hierarchy PMO-0447 → PROD-1131 → PLAT-2810 with six stories, twenty-one tasks and their comments. Ticket comments carried three of the most material facts in this review and are cited throughout.

**Method.** Every prompt of every applicable instrument was walked and its outcome recorded before any finding was written up, so that coverage was decided by the walk rather than by the writing budget. The elicitation record is `06-threat-model-candidates.md`.

| Instrument | Prompts | Outcome |
|---|---|---|
| STRIPED | 57 | 48 finding rows, 9 no exposure |
| LINDDUN and AI privacy (PRV·L) | 9 | 7 findings, 2 no exposure |
| Privacy dark patterns and human-centered security | 16 | 6 findings, 10 no exposure |
| Elevation of Autonomy | 30 cards | 28 findings, 1 no exposure, 1 not in scope |
| AI extension (output sinks, ASI gaps, ML pipeline) | 20 | 9 findings, 4 no exposure, 8 not in scope |
| OWASP Cumulus (cloud) | 60 cards | 33 findings, 13 no exposure, 7 not in scope |
| Container and orchestration | 25 | 15 findings, 10 not in scope |
| **Total** | **217** | **68 distinct findings** |

**What was not supplied, and what it cost.** No repositories, no Terraform, no Helm charts or Kubernetes manifests, no Dockerfiles, no pipeline definitions, no data schemas, no MCP server manifests, no system prompt, no DPA and no privacy notice. Every finding here derives from documentation and tickets. Twelve of the twenty-five container prompts and seven of the sixty cloud cards could not be walked against a real artefact and are recorded as not in scope with that reason. Eleven findings rest on *the absence of a statement* rather than an *observed absence* and are tagged "if present". The data model in the architecture document is reconstructed from prose. `00-context-sources-and-open-questions.md` lists twenty-seven specific questions this review could not answer and names the exact artefact that would settle each.

**The validation session has been held.** `[VS · v1.1]` 2026-09-09, 13:30–15:08, facilitated by the author; log in the threat model's Appendix G, delta in Appendix H, actions in Appendix I, transcript shipped as `transcript.md`. Every severity walked in the room was confirmed by its owner and none moved; the changes were three additions, one status correction (T3), one closure (C5), and five corrections to this pack's own text. **Three seats were empty and each owns findings**: Identity Platform, who own the dependency behind three Criticals, did not respond; Data Platform, who hold the agreement behind P4, declined; and the owner of the standing platform security controls page did not attend, which is the qualification on C5's closure and on every baseline-coverage answer in the pack. **The session did not substitute for the repository.** Seven questions were put to the room and none was answered — Redis authentication and at-rest encryption, what the sanitiser does, the system prompt, Pod Security Admission labels, IRSA versus node role, the warehouse grants, and pilot-versus-production account separation. Nobody was asked to guess, and nobody did.

---

## 3. Risk posture at a glance

`[VS · v1.1]` Changed rows are marked. One column is added for the pack's first accepted risk.

| Bucket | Findings | 🔴 Open | 🟡 Partial | 🔵 Planned | ⚪ Accepted | Highest severity |
|---|---|---|---|---|---|---|
| Spoofing | 5 | 3 | 0 | 2 | 0 | Critical — S2 shared app registration |
| Tampering *(changed)* | 4 | **4** | **0** | 0 | 0 | High — T2, T3, T4 |
| Repudiation | 5 | 4 | 0 | 1 | 0 | High — R1 no argument record |
| Information disclosure | 4 | 2 | 1 | 1 | 0 | High — I1, I2, I3, I4 |
| Privacy *(changed)* | **8** | **7** | 1 | 0 | 0 | Critical — P1 Support mailbox |
| Elevation of privilege | 5 | 3 | 0 | 2 | 0 | Critical — E1 tenant-wide reach |
| Denial of service | 5 | 5 | 0 | 0 | 0 | High — D1, D3 unbounded cost |
| Cross-cutting *(changed)* | **7** | **7** | 0 | 0 | 0 | Critical — O1 documentation drift |
| AI and agentic | 15 | 14 | 1 | 0 | 0 | Critical — AI1, AI2, AI3 |
| Cloud | 6 | 5 | 0 | 1 | 0 | High — CL1, CL6 |
| Container *(changed)* | 6 | **4** | 1 | 0 | **1** | High — C1, C2, C3, C6 |
| Recovery and resilience | 1 | 1 | 0 | 0 | 0 | Medium — RR1 |
| **Total** | **71** | **59** | **4** | **7** | **1** | **7 Critical, 40 High, 24 Medium** |

**What moved, and why.** `[VS · v1.1]` T3 moved from Partial to Open because branch protection bounds a path the assistant does not take `[VS §2 · CORRECTED]`. C5 moved from Open to Accepted on Platform Security's answer, carried as **AR-01** with an engineer's dissent recorded `[VS §8 · CLOSED]`. Three findings were added, all High and all Open: **O6** (an undocumented branch-protection exemption), **O7** (a security position that was never decided) and **P8** (two contractually-obligated customers corresponding through the least-governed channels). **No severity rating changed in either direction.** One likelihood did: T3, Medium to High.

**The seven Critical findings.** Unchanged in number and in membership; all seven were walked in the session and confirmed at rating by their owners.

| ID | Finding | Why it is Critical |
|---|---|---|
| **E1** | Application permissions let the assistant read anything in the tenant | No authorisation decision is made against the requesting person at any point in the chain |
| **S2** | One shared app registration instead of per-user credentials | The same condition seen from identity: nothing carries who asked |
| **O1** | The approved page documents an authorisation control that does not exist | The mechanism that prevents E1 from being seen, and that propagates it to other teams |
| **AI1** | Externally-authored content reaches the model as trusted instructions | Turns an unauthenticated stranger into the party directing the assistant |
| **AI2** | Markdown rendering exfiltrates context from the user's client | Completes the credential-free path, outside the egress proxy's reach |
| **AI3** | Tool arguments are taken from model output with no value allowlist | Turns a read into a write, and chooses the recipient |
| **P1** | Support's mailbox processes third-party personal data with no basis or DPIA | Live since June, with no lawful basis, no notice and no deletion path |

Five of these seven are one structural condition. That is the good news in the number: the remediation is concentrated, not diffuse.

**The three findings added by the session.** `[VS · v1.1]` All High, all Open, none of them derivable from the supplied documents — which is the argument for holding the session and, separately, the argument for the repository.

| ID | Finding | Why it could not have been found from the documents |
|---|---|---|
| **O6** | Branch protection carries a standing `platform-ci` exemption recorded in no citable document | It exists as a config file in the organisation repository. A reviewer working from the standing controls page, which is what designs are told to cite, cannot see it |
| **O7** | The position that internal content needs no sanitising was inherited across three artefacts and never decided | Every artefact says the same thing. Only the four people who wrote them, in one room, could establish that none of them was the decision |
| **P8** | Two customers carrying contractual NIS2 obligations correspond through three Slack Connect channels and the shared mailbox | Half of it lives in Support's channel configuration and half in two customer contracts. Neither was supplied, and the two halves sat with two different people |

---

## 4. Design versus implementation reconciliation

No implementation was supplied, so this compares the **approved design pages** with the **ticket state** — which is the nearest available equivalent, and which turned out to be where the headline finding lives.

| # | The approved documentation says | The tickets say | Finding |
|---|---|---|---|
| 1 | Per-user delegated OAuth; "a user cannot reach anything through the assistant that they could not reach directly" | PLAT-2820 **To Do**; PLAT-2820-1 blocked since 2026-04-18, unscheduled; PLAT-2820-3: one app registration with application permissions | **O1, E1** |
| 2 | "Every privileged action... recorded with the acting user, the action, and the parameters it was called with" | The same page, one section later: "Tool arguments and results are logged at debug level, off in production" | **R1** |
| 3 | "Actions are attributable to them in the target system's own audit log" | The target system records the application | **R2** |
| 4 | Standing controls page: "All corporate applications authenticate through the identity provider. MFA is enforced" | Console is behind the VPN with a shared password; PLAT-2831-3 To Do | **O2, S1** |
| 5 | Connector table lists bounded per-connector scopes | PLAT-2814-3: Slack "installed with the full scope set"; PLAT-2814-6 To Do, not scheduled | **E2** |
| 6 | "Web search is the only one reaching content originating outside the organisation" | Support reads a customer-authored shared mailbox; GitHub reads outside contributors' issues | **AI1** |
| 7 | "No new persistent stores", following D-05 | Redis conversation state and 13 months of telemetry are both new derived stores | **P2, P3** |

Row 1 deserves the attention, and the mechanism matters as much as the fact. The architecture page's change log reads *"2026-05-22 — Authorisation section updated following D-03."* The page was updated to record a **decision**, and every subsequent reader — including the forum that approved it two days earlier — reads it as a description of the **build**. This is not carelessness; it is a documentation convention that cannot distinguish decided from delivered. The fix is small and structural: every control claim on a design page carries its delivering ticket and that ticket's state, and a page cannot be Approved with a claim whose ticket is not Done. That single convention would have caught the most serious finding in this review before it reached a forum.

---

## 5. Regulatory posture

| Framework | Position | Status |
|---|---|---|
| **GDPR / UK GDPR** | Applies. Open on Articles 5(1)(b), 5(1)(c), 5(1)(d), 5(2), 6, 9, 13, 14, 15, 16, 17, 28, 32, 33 and 35. The most serious is Article 35: high-risk processing of third-party personal data, live for three months, with no DPIA. Article 22 assessed and not triggered — Phase 1 keeps a human present | 🔴 Open |
| **NIS2** `[VS §7 · CORRECTED]` | **Determined, by a route this review could not see.** v1.0 recorded applicability as undetermined pending the sector question and treated that as the finding. **The sector question resolves to no** — the organisation is not an essential or important entity. **The Article 21 measures apply anyway, contractually**, because two customers are essential or important entities and their contracts pass the obligation down. Four of those measures are weak — console MFA (S1, O2), supply-chain security for the MCP surface (AI9, AI10, C3), incident handling (O5) and the early-warning clock, which cannot start from unrecorded events (R1) — and they are weak *in scope*, not conditionally. The two customers concerned are also the two whose correspondence is most heavily in the assistant's scope (**P8**). The contractual measures have not yet been enumerated from the two contracts | 🔴 Open |
| **EU AI Act** | **Applicability undetermined and blocked.** PR-03 records the group governance workstream as not started. Most likely limited-risk with Article 50 transparency obligations, which the missing machine-generated marker would not currently meet | 🔴 Open |
| **EU Cyber Resilience Act** | **Assessed: does not apply.** No product with digital elements is placed on the EU market — no downloadable client, no embedded software, no hardware, no sale or distribution. Re-assess if PROD-1131's Phase 3 customer-facing surfaces proceed | ⚪ Accepted |
| **UK PSTI Act 2022** | **Assessed: does not apply.** No consumer connectable product | ⚪ Accepted |
| **PCI-DSS v4.0** | **Assessed: conditional.** No cardholder data environment. The open question is whether card details have ever arrived in the Support shared mailbox, which the assistant reads in full. Folded into the DPIA | 🔴 Open |
| **HIPAA** | **Assessed: does not apply.** No protected health information, no covered entity relationship. The health-inference finding P7 is a GDPR Article 9 matter, not a HIPAA one | ⚪ Accepted |
| **SOC 2 Type II** `[VS §7 · CONFIRMED]` | Applies indirectly — not a customer-facing service, but operated inside a control environment, and **the organisation is confirmed SOC 2 Type II**. Open on CC6.1, CC6.3, CC7.1, CC8.1, C1 and A1 | 🔴 Open |
| **ISO 27001 / Cyber Essentials** `[VS §7 · CORRECTED]` | **Assessed: does not apply.** v1.0 carried this as conditional on a certification status no source stated. **The organisation is not ISO 27001 certified.** The four control families named there — access control, logging, supplier management, secure development — remain live as findings in their own right; they are not ISO obligations | ⚪ Accepted |

The governance position is the one to escalate. PMO-0447's PR-03 records that AI governance is undefined at group level, that the workstream has not begun, and that initiatives are proceeding on the basis that governance will be retrofitted — accepted at the July steering group. The consequence is that this system has no organisational standard to pass. `[VS §7 · CORRECTED]` **One of the two determinations that were waiting on that workstream is now made**: NIS2 is answered — not by sector, but by contract, and the measures apply. The EU AI Act tier is still waiting. And the correction strengthens rather than weakens the escalation: the interim governance gate in O3 is no longer only a prudent substitute for a missing standard, it is the mechanism by which an obligation the organisation already carries under two customer contracts actually gets met.

---

## 6. Prioritised recommendations and gate readiness

**Gate readiness: not ready for GA, and not ready for a third pilot function.** The pilot expanded once, from Platform to Support on 2026-06-09, introducing third-party customer personal data — and PROD-1131 lists the security review as a dependency "before pilot expansion", which did not happen. The current pilot can continue while the launch gates are worked, with two interim controls applied now. `[VS §9 · CONFIRMED]` **The product owner set this as a standing constraint in the session**: no further pilot expansion until the output filter (AI2), the input-channel decision (**O7**) and the Support mailbox exclusion (P1) are complete. Owner Dana Whitfield, standing.

**Do this month.**

1. **Escalate PLAT-2820-1 at portfolio level.** Blocked on Identity Platform since April, unscheduled, sitting behind three Critical findings. This is a conversation with the COO office about the FY26 H2 plan, not a refinement session. *The single most important item in this pack.*
2. **Correct the architecture page.** An hour of writing. Every day it stands unchanged, it propagates a Critical gap to teams that will design against it.
3. **Ship the Content Security Policy and markdown subset.** `[VS §4 · CORRECTED]` **About three days across two owners**, not one: a day for the CSP header, two for the markdown subset across both renderers and the outbound composer, with TA-04 and TA-05 passing as the completion condition. Still closes the only attack path in this review that needs no credential at any stage, and still the cheapest thing on this list — the team already recorded the symptom in the pilot notes. Owners Priya Raghunathan with Kwame Osei, before any expansion.
3a. **Take the input-channel trust decision (O7).** `[VS §3 · NEW]` Not a fix and not a document correction — a decision that does not exist and must not be inferred from PLAT-2814's acceptance criterion. Owner Marcus Oyelaran, with Kwame Osei and the Data Protection Officer, before any expansion. It gates the same expansion the output filter does.
4. **Narrow the connector scopes now, without waiting for PLAT-2820.** An Entra application access policy scoping the O365 registration to the pilot group, and a GitHub App installation limited to a named repository list excluding public repositories. Days of work; moves the blast radius of every injection from tenant-wide to a reviewed list. `[VS §1, §2 · NEW]` **Two qualifications from the session.** The Entra policy is IT's change, not the team's — "Days, if IT will do it" — and IT here means the same Identity Platform function that has blocked PLAT-2820-1 since April, so the interim and the permanent fix share a blocker. And **the commit tool is being disabled at the dispatcher in the interim as well as the installation being narrowed**: the two are not exclusive, and the usage evidence made the first one cheap — eleven commits since July, nine of them tests, two genuine, none from Support.
5. **Exclude the Support shared mailbox at the connector, pending the DPIA.** An afternoon. Moves the most serious privacy finding from Critical to Medium while the assessment runs, and buys the time the assessment needs.

**Before GA — the remaining launch gates.**

6. Argument allowlists and risk-based confirmation on write tools. The pilot group's objection to confirmation is legitimate and is answered by confirming on risk rather than on frequency, not by confirming nothing. `[VS §5 · CONTESTED]` **The product owner accepts confirmation on commits and refuses it on mail and in-channel posts; outbound mail to customers is unresolved and is Support's objection, not this review's.** She brings a risk-based confirmation model within three weeks and AI4's recommendation is revisited against it. The finding was not changed on the strength of that argument — an argument about the shape of a fix is not evidence about the exposure. The interim residual is carried as accepted risk **AR-02**, owner Dana Whitfield, time-boxed to three weeks.
7. A dispatch audit record, and an action display that reads from it rather than from the model's account of itself. In that order; the second depends on the first.
8. Connector isolation: one namespace, one identity and one secret scope per connector, with a sandboxed runtime for the community web-search connector.
9. SSO on the web console. The owner's own comment already sets this as the gate.

**Fast hygiene, days and cheap.** Hard caps on tokens and loop iterations — confirmed as hours of work, and there is no ceiling on the loop at all today `[VS §9 · CONFIRMED]`. Remove document bodies from the debug logging path rather than gating them — half a day, an allowlist on the log fields `[VS §6 · CONFIRMED]`. Restricted Pod Security Admission and resource limits; **token automounting is no longer on this list** — C5 closed on the platform workload-identity baseline and is carried as accepted risk **AR-01** `[VS §8 · CLOSED]`. Start the AI bill of materials with four MCP servers and the model version, and **pin them by digest — all four currently float on `latest` with no digest anywhere, which the session confirmed as observation rather than inference** `[VS §8 · CONFIRMED]`. Name a kill-switch owner and write four incident playbook entries. Drop the telemetry user dimension after the billing period. Add the machine-generated marker to both surfaces. `[VS §2, §8 · NEW]` **Two additions:** record the `platform-ci` branch-protection exemption where the control is claimed (**O6**), and split the shared connector secret per connector, because rotating it currently breaks all four connectors at once and therefore nobody rotates it.

**Decisions to ratify, not fix.** The model provider agreement scoped for another team's purposes was a portfolio-level commercial trade under a stated procurement constraint — verify its scope and, where it does not cover this processing, carry the residual in an ADR with the COO office as owner. The adversarial-subspace and boundary-transfer hazards cannot be closed at the model layer; ratify in writing that the guarantees rest on the deterministic controls above and that the web-search sanitiser is not load-bearing, so no future design page cites it as the reason untrusted content is safe. And ratify the interim AI governance gate as the standard this system is held to until the group workstream starts.

Full sequencing, with every gap mapped to its finding and its test, is in `04-gap-analysis.md` §7.

---

## 7. What is done well — keep it

Named specifically, because the rest of this review is blunt.

**The platform baseline.** Egress control through a domain-allowlisting proxy, reviewed weekly and in place since 2023, is a control most organisations of this size do not have and it bounds several findings here. Branch protection with required review and signed commits across the whole GitHub estate. Organisation-wide secret scanning with push protection. Dependency scanning that blocks the build on Critical. Base images scanned on push and rebuilt weekly. Debug endpoints disabled in production by configuration before promotion. The assistant team inherited all of this without having to argue for any of it, and it closes eleven prompts outright.

**D-03, and its timing.** "Assistant acts as the requesting user, not as a system identity — preserves attribution and existing permission boundaries", 2026-04-02. The decision is right. Everything this review says about it is a delivery finding, not a design one, and the difference matters when the fix is scoped.

**D-05.** No new systems of record. It removed a whole class of duplication and retention risk before it could exist, and it should be defended when feature pressure arrives.

**The 24-hour conversation TTL.** A real, deliberate retention limit on the store that holds the most sensitive aggregate in the system. Most systems of this kind have no equivalent.

**PLAT-2825 exists at all.** "Users see what it did" was made an epic acceptance criterion. The implementation needs to change because it reads from the model rather than from the dispatcher, but the requirement was correctly identified as a security property at the point where most teams would have omitted it.

**The team writes down what it does not know.** The pilot operations page carries "Known rough edges" and "Open questions we have not resolved". Four findings in this review are the team's own observations promoted to findings with severities and owners — untrimmed context, acting rather than asking, the uninvestigated markdown images, and whether Support's mailbox should be in scope at all. This review agrees with them; it did not discover them, and it says so in each finding. A team that records its unknowns in a draft page is a team a review can actually help.

**And the team says what it does not know out loud.** `[VS · v1.1]` Named here because it is the reason this version is worth more than the last one, and because most of it cost someone something to say. The architecture owner told the room his own approved page was inaccurate, and then withdrew a defence of branch protection mid-argument when an engineer produced a fact he had not had. The engineer refused to answer three questions from memory — Redis configuration, the sanitiser's behaviour, the service account manifests — and said so rather than filling the silence, including where saying so blocked a closure the room was moving towards. The product owner produced a usage estimate, was shown the number, and changed her position on the spot. The Data Protection Officer corrected an error in this pack's own text that made her case look stronger than it was. Support's manager accepted losing most of the value of the assistant to his team. Nobody guessed, and the five people who were asked to confirm findings against their own work confirmed all of them.

---

## 8. Next steps

`[VS · v1.1]` Steps 1 and 5 of v1.0's list are discharged: the session was held on 2026-09-09 and this version merges it with the corrections tagged inline. What follows is the remainder, restated.

1. **Work the action register** in `06-threat-model.md` Appendix I — thirty actions with named owners and dates, agreed in the room. Three of them gate further pilot expansion: the output filter (AI2), the input-channel decision (**O7**) and the Support mailbox exclusion (P1).
2. Escalate the Identity Platform dependency this week, at portfolio level with the COO office and with the finding IDs attached. They did not attend the session, and they block the interim control as well as the permanent one.
3. Apply the interim controls in parallel with the escalation, not after it: the Entra application access policy, the narrowed GitHub App installation, the commit tool disabled at the dispatcher, and the Support mailbox excluded at the connector from Friday.
4. Raise the seventeen gaps that currently have no ticket, plus the three new findings, which map to no ticket and to no supplied artefact. Most of the work in this review is not late; it has not been raised.
5. **Obtain the two artefacts the session could not produce.** The model provider DPA from Data Platform — P4 stays High until its scope is evidenced, and is not downgraded on the expectation of it. And a schedule from Identity Platform for PLAT-2820-1, blocked and unscheduled since 2026-04-18.
6. **Circulate this version to the session participants.** The facilitator's closing condition was that anything recorded here could be disputed until the Friday following the session, after which it is the record.
7. Re-run the model when the repositories, the schemas and the PLAT-2790 tickets are available — and sooner if PLAT-2820 lands, since that one change closes or downgrades five findings and earns a fresh severity pass. **The session did not close the repository gap and did not pretend to**: seven questions were put to the room and none was answered. Open the next version with the delta table so the team gets credit for what it fixed.

---

*This review reflects the Confluence pages and Jira tickets supplied in `input/` as at 2026-09-09 and the validation session of the same date; statuses tied to ticket numbers are point-in-time. No source code, infrastructure code, Helm charts or schemas were supplied, so controls described as absent are absent from the documentation rather than confirmed absent from the implementation — except where a named engineer converted an absence into an observation in the session, which is tagged where it occurs. Session-derived claims carry `[VS §n]` tags resolving to sections of `transcript.md`, which ships with this pack. Nothing here is legal advice; the GDPR, NIS2, EU AI Act and PCI-DSS positions should be confirmed with counsel and with the Data Protection Officer — note that the NIS2 position in §5 rests on two customer contracts that were not supplied and were described in the session by the Data Protection Officer. The source material is marked "Fictional, for conference demonstration purposes" and has been analysed as though it described a real system.*
