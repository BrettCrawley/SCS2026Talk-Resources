# Internal AI Assistant — Security Review

**Version:** 1.0 (first pass) · **Date:** 2026-09-09 · **Classification:** Internal
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this review. Produced with AI assistance using the security-review skill set authored by Brett Crawley.
**Model:** Claude Opus 5
**Scope:** Epic PLAT-2810 under initiative PROD-1131 and portfolio PMO-0447
**Companion documents:** `00-context-sources-and-open-questions.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md` · `06-threat-model-candidates.md`

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted.

> This is the document to read first and it was written last. It summarises a review of the internal AI assistant against 217 elicitation prompts across seven instruments, producing 68 findings. It rests on three Confluence pages and two ticket files. **No source code, infrastructure code, Helm charts or schemas were supplied**, although the engagement brief named git repositories as a source; what that costs is stated in §2 and itemised in the context document.

---

## 1. Executive summary

The internal AI assistant is a well-shaped system with two open ends and a documentation problem that hides one of them.

The team made the right structural decisions early. **D-03**, taken on 2026-04-02 before the connector runtime existed, says the assistant acts as the requesting user rather than as a system identity — which is the correct architecture for an agentic system with tool access, and most organisations reach it after an incident rather than before a pilot. **D-05** refused to build a new system of record. The inherited platform baseline — egress allowlisting since 2023, branch protection with signed commits, organisation-wide secret scanning, blocking dependency scans, default-deny network policy — is stronger than most, and eleven of this review's elicitation prompts close on it outright.

**The problem is that D-03 was decided and not delivered, and the approved architecture page describes it as delivered.** PLAT-2820 is To Do. Its first task has been blocked on the Identity Platform team since 2026-04-18 and is not scheduled. PLAT-2820-3 records what runs instead: one app registration with application permissions across all connectors. The consequence is that the assistant currently reaches every mailbox, every channel and every repository in the tenant, for any user who can start a conversation, and the page that the architecture forum approved on 2026-05-20 states the opposite. Anyone designing against that page is building on a control that does not exist.

**The second open end is that the trust boundary is drawn around the network rather than around who wrote the content.** The architecture page names web search as "the one place untrusted content enters". Support's pilot, live since 2026-06-09, reads a shared mailbox of entirely customer-authored mail; the GitHub connector reads issues from outside contributors. Content written by unauthenticated strangers reaches the model as instructions, and because of the first problem the tool calls it produces execute with tenant-wide reach. The exit route is a markdown image tag rendered by the user's own browser — a path the egress proxy cannot see, and one the team already observed and recorded as "Renders fine, looks odd. Not investigated."

Those two conditions combine into a single attack that needs no credential at any stage: **send an email to the published support address, and a Support agent asking for a customer summary causes a private repository to be read and its contents sent to an attacker-controlled host.** That path is described end to end, with its ATLAS technique sequence, in the threat model. Two deterministic controls break it, and both are currently absent: per-user delegated authorisation, which is blocked at portfolio level, and a Content Security Policy header, which is a day of work.

Seven Critical findings sounds like a lot for a system this small, and it is concentration rather than breadth: five of them describe one structural condition from five angles. Deliver PLAT-2820, add argument allowlists and ship the output filter, and the Critical count falls to two. Nothing in this review is a reason not to build this system. Several are reasons not to expand the pilot again first.

**The three things to do this month.** Escalate the Identity Platform dependency at portfolio level — it is not a backlog item, it is three Critical findings behind an unscheduled external team. Correct the architecture page, which costs an hour and stops the gap propagating. Ship the Content Security Policy and markdown-subset change, which costs a day and closes the credential-free path on its own.

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

**No validation session has been held.** Nothing here carries an owner's confirmation. Severities are the reviewer's assessment from documentation and several will move once the team responds — that is what the session is for, and the participants it needs are listed in the threat model's Appendix G.

---

## 3. Risk posture at a glance

| Bucket | Findings | 🔴 Open | 🟡 Partial | 🔵 Planned | Highest severity |
|---|---|---|---|---|---|
| Spoofing | 5 | 3 | 0 | 2 | Critical — S2 shared app registration |
| Tampering | 4 | 3 | 1 | 0 | High — T2, T3, T4 |
| Repudiation | 5 | 4 | 0 | 1 | High — R1 no argument record |
| Information disclosure | 4 | 2 | 1 | 1 | High — I1, I2, I3, I4 |
| Privacy | 7 | 6 | 1 | 0 | Critical — P1 Support mailbox |
| Elevation of privilege | 5 | 3 | 0 | 2 | Critical — E1 tenant-wide reach |
| Denial of service | 5 | 5 | 0 | 0 | High — D1, D3 unbounded cost |
| Cross-cutting | 5 | 5 | 0 | 0 | Critical — O1 documentation drift |
| AI and agentic | 15 | 14 | 1 | 0 | Critical — AI1, AI2, AI3 |
| Cloud | 6 | 5 | 0 | 1 | High — CL1, CL6 |
| Container | 6 | 5 | 1 | 0 | High — C1, C2, C3, C6 |
| Recovery and resilience | 1 | 1 | 0 | 0 | Medium — RR1 |
| **Total** | **68** | **56** | **5** | **7** | **7 Critical, 37 High, 24 Medium** |

**The seven Critical findings.**

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
| **NIS2** | **Applicability undetermined** — no supplied source states the organisation's sector. This is itself the finding. If in scope, four Article 21 measures are weak and the Article 23 24-hour clock cannot start from unrecorded events | 🔴 Open |
| **EU AI Act** | **Applicability undetermined and blocked.** PR-03 records the group governance workstream as not started. Most likely limited-risk with Article 50 transparency obligations, which the missing machine-generated marker would not currently meet | 🔴 Open |
| **EU Cyber Resilience Act** | **Assessed: does not apply.** No product with digital elements is placed on the EU market — no downloadable client, no embedded software, no hardware, no sale or distribution. Re-assess if PROD-1131's Phase 3 customer-facing surfaces proceed | ⚪ Accepted |
| **UK PSTI Act 2022** | **Assessed: does not apply.** No consumer connectable product | ⚪ Accepted |
| **PCI-DSS v4.0** | **Assessed: conditional.** No cardholder data environment. The open question is whether card details have ever arrived in the Support shared mailbox, which the assistant reads in full. Folded into the DPIA | 🔴 Open |
| **HIPAA** | **Assessed: does not apply.** No protected health information, no covered entity relationship. The health-inference finding P7 is a GDPR Article 9 matter, not a HIPAA one | ⚪ Accepted |
| **SOC 2** | Applies indirectly — not a customer-facing service, but operated inside a control environment. Open on CC6.1, CC6.3, CC7.1, CC8.1, C1 and A1 | 🔴 Open |

The governance position is the one to escalate. PMO-0447's PR-03 records that AI governance is undefined at group level, that the workstream has not begun, and that initiatives are proceeding on the basis that governance will be retrofitted — accepted at the July steering group. The consequence is that this system has no organisational standard to pass, and the two regulatory determinations that would shape it (NIS2 sector, EU AI Act tier) are waiting on a workstream with no start date. Those two determinations are days of Legal time and should not wait for the programme.

---

## 6. Prioritised recommendations and gate readiness

**Gate readiness: not ready for GA, and not ready for a third pilot function.** The pilot expanded once, from Platform to Support on 2026-06-09, introducing third-party customer personal data — and PROD-1131 lists the security review as a dependency "before pilot expansion", which did not happen. The current pilot can continue while the launch gates are worked, with two interim controls applied now.

**Do this month.**

1. **Escalate PLAT-2820-1 at portfolio level.** Blocked on Identity Platform since April, unscheduled, sitting behind three Critical findings. This is a conversation with the COO office about the FY26 H2 plan, not a refinement session. *The single most important item in this pack.*
2. **Correct the architecture page.** An hour of writing. Every day it stands unchanged, it propagates a Critical gap to teams that will design against it.
3. **Ship the Content Security Policy and markdown subset.** A day of work. Closes the only attack path in this review that needs no credential at any stage — and the team already recorded the symptom in the pilot notes.
4. **Narrow the connector scopes now, without waiting for PLAT-2820.** An Entra application access policy scoping the O365 registration to the pilot group, and a GitHub App installation limited to a named repository list excluding public repositories. Days of work; moves the blast radius of every injection from tenant-wide to a reviewed list.
5. **Exclude the Support shared mailbox at the connector, pending the DPIA.** An afternoon. Moves the most serious privacy finding from Critical to Medium while the assessment runs, and buys the time the assessment needs.

**Before GA — the remaining launch gates.**

6. Argument allowlists and risk-based confirmation on write tools. The pilot group's objection to confirmation is legitimate and is answered by confirming on risk rather than on frequency, not by confirming nothing.
7. A dispatch audit record, and an action display that reads from it rather than from the model's account of itself. In that order; the second depends on the first.
8. Connector isolation: one namespace, one identity and one secret scope per connector, with a sandboxed runtime for the community web-search connector.
9. SSO on the web console. The owner's own comment already sets this as the gate.

**Fast hygiene, days and cheap.** Hard caps on tokens and loop iterations. Remove document bodies from the debug logging path rather than gating them. Restricted Pod Security Admission, resource limits and disabled token automounting. Start the AI bill of materials with four MCP servers and the model version. Name a kill-switch owner and write four incident playbook entries. Drop the telemetry user dimension after the billing period. Add the machine-generated marker to both surfaces.

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

---

## 8. Next steps

1. Share this pack with the owners listed in the threat model's Appendix G and hold the validation session **before any further pilot expansion**. Ask owners to call out errors and decisions out loud; only what reaches the transcript can be fed back.
2. Escalate the Identity Platform dependency this week.
3. Apply the two interim controls — connector scope narrowing and the Support mailbox exclusion — in parallel with the escalation, not after it.
4. Raise the seventeen gaps that currently have no ticket. Most of the work in this review is not late; it has not been raised.
5. Feed the session transcript into version 1.1, tag the corrections inline, and propagate the changes to the companion documents so they do not drift.
6. Re-run the model when the repositories, the schemas and the PLAT-2790 tickets are available — and sooner if PLAT-2820 lands, since that one change closes or downgrades five findings and earns a fresh severity pass. Open the next version with the delta table so the team gets credit for what it fixed.

---

*This review reflects the Confluence pages and Jira tickets supplied in `input/` as at 2026-09-09; statuses tied to ticket numbers are point-in-time. No source code, infrastructure code, Helm charts or schemas were supplied, so controls described as absent are absent from the documentation rather than confirmed absent from the implementation. Nothing here is legal advice; the GDPR, NIS2, EU AI Act and PCI-DSS positions should be confirmed with counsel and with the Data Protection Officer. The source material is marked "Fictional, for conference demonstration purposes" and has been analysed as though it described a real system.*
