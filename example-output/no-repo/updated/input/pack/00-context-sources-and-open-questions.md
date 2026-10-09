# Internal AI Assistant — Context, Sources and Open Questions

**Version:** 1.0 (first pass) · **Date:** 2026-09-09 · **Classification:** Internal
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this document. Produced with AI assistance using the security-review skill set authored by Brett Crawley.
**Model:** Claude Opus 5
**Companion documents:** `01-security-review.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model-candidates.md` · `06-threat-model.md`

> This document exists so that every other document in the pack can be read against a known evidence base. It states exactly what was supplied, exactly what was not, what each absence cost the analysis, and what would need to arrive for the unanswered questions to become answerable. Read it first; it is the difference between "this control is missing" and "this control was not visible to me".

---

## 1. What the system is

**PLAT-2810 — Internal AI assistant.** A conversational agent, reachable from Slack and from a web console, that reads across Office 365 (documents, calendar, mail), Slack, GitHub (issues, pull requests, code) and public web search, and takes actions in those systems on a user's behalf: sending mail, posting to Slack, commenting on and updating GitHub issues, and committing code.

It is an **agentic** system. An orchestrator (`assistant-svc`) assembles context, calls a hosted model provider, interprets the tool calls the model emits, dispatches them, and loops until it produces a final answer. A connector runtime (`assistant-connectors`) hosts an MCP client and four connector processes. Conversation state lives in Redis with a 24-hour expiry. It runs on EKS in a single region.

It is in pilot: Platform since 2026-05-04 (twelve users), Support since 2026-06-09 (nine users).

---

## 2. Sources supplied

| # | Source | Path | Type | Status on the page | Date |
|---|---|---|---|---|---|
| S1 | Internal AI Assistant — Architecture | `input/confluence/architecture.md` | Confluence design page | Approved at the Platform architecture forum 2026-05-20 | 2026-05-22 |
| S2 | Internal AI Assistant — Data Handling and Pilot Operations | `input/confluence/data-handling-and-pilot-ops.md` | Confluence design page | Draft, written during the pilot, not reviewed | 2026-06-30 |
| S3 | Platform Security Controls — Standing Reference | `input/confluence/platform-security-controls.md` | Confluence standing reference | Approved; designs are told to cite it rather than restate it | 2025-11-14 |
| S4 | The assumed trust-boundary model of an agentic AI system | `input/confluence/diagram1-assumed.svg` | SVG diagram | Untitled status; captioned "What most engineers assume" | undated |
| S5 | PLAT-2810 — Epic and children | `input/tickets/plat-2810-hierarchy.md` | Jira epic with 6 stories and 21 tasks | Epic In Progress | as extracted |
| S6 | PMO-0447 / PROD-1131 — Portfolio and initiative | `input/tickets/pmo-0447-prod-1131.md` | Jira portfolio item and product initiative | In Delivery / In Progress | as extracted |

Six files, 24,246 bytes in total. The ticket hierarchy was followed to its children: PLAT-2810 → PLAT-2814, PLAT-2817, PLAT-2820, PLAT-2822, PLAT-2825, PLAT-2831, and each of their tasks. The parent chain PLAT-2810 → PROD-1131 → PMO-0447 was read in full, including the five initiative-level decisions D-01 to D-05 and the three portfolio risks PR-01 to PR-03.

### 2.1 A note on source S4

`diagram1-assumed.svg` is not a design artefact of this system. Its own title is *"The assumed trust-boundary model of an agentic AI system"* and its caption reads *"What most engineers assume — a tidy boundary at every connection; the internet is the only untrusted zone."* It shows the user, the agent and each MCP tool in neat boundaries, with Office 365, Email, Slack and GitHub inside a "Corporate trust zone" and web search labelled "the one untrusted edge".

It has been treated as **evidence of the mental model the design encodes**, not as a description of the system. That mental model is stated almost verbatim in the architecture page's Trust model section, and refuting it is the central finding of this review (see `06-threat-model.md` finding AI1 and `03-security-architecture.md` §2.6).

---

## 3. What was **not** supplied

The engagement brief named three source categories. Two arrived. The third did not.

| Requested | Supplied? | What is absent |
|---|---|---|
| Confluence design documents | **Yes** | — |
| Jira PMO and PMI tickets, following children | **Yes** | PLAT-2790 (search indexing, delivered) and PLAT-2856 (analytics, not started) are named as sibling epics under PROD-1131 but their ticket bodies were not supplied |
| **Git repositories as supporting/reference material** | **No** | Nothing. `input/` contains only `confluence/` and `tickets/` |

Specifically absent, and each named because the brief asked for it:

- **No source code.** No `assistant-svc`, no `assistant-connectors`, no Slack app, no web console.
- **No Terraform or other IaC.** The brief asked that infrastructure code be read for organisational controls; there is none to read.
- **No Helm charts, Kubernetes manifests or kustomize overlays.** Pod security context, `automountServiceAccountToken`, NetworkPolicy, resource limits, admission policy and secret mounting are therefore all unverified.
- **No Dockerfiles, build manifests, lock files or SBOMs.** Base-image pinning, non-root user, image minimisation and dependency provenance cannot be assessed against an artefact.
- **No CI/CD pipeline definitions.** The platform reference asserts a shared CI template with blocking dependency scanning; nothing shows this workload uses it.
- **No data schemas.** No DDL, migrations, ORM models or ERDs. The Redis conversation-state structure and the analytics warehouse table definitions are described in prose only.
- **No MCP server manifests, tool schemas or tool descriptions**, and no version pins for the three vendor MCP servers or the community web-search server.
- **No system prompt or prompt templates.**
- **No parent or programme threat model**, and no previous version of a threat model for this system.
- **No Data Processing Agreement, privacy notice, record of processing, or DPIA** for the assistant or for the model provider.

### 3.1 What each absence cost

| Absence | Consequence for this pack |
|---|---|
| No repositories | Every finding in this pack is derived from documentation and tickets. Findings that would be confirmed or refuted by code are tagged **"if present"** in `06-threat-model.md` and named in its Assumptions & Limitations. |
| No Helm / manifests | 12 of the 25 container prompts resolve to `not in scope — no manifests supplied` in the candidate register. The container findings that remain (C1–C6) rest on statements in the architecture page, chiefly "Connector processes in the same namespace" (PLAT-2814-1). |
| No Dockerfiles / build config | 8 of the 60 Cumulus Delivery cards could not be walked against a real artefact. Supply-chain assurance for the community MCP server (AI10) is therefore an assertion of absence, not an observation of one. |
| No schemas | Every privacy and encryption-at-rest finding is inferred. `03-security-architecture.md` §2.4 carries a **reconstructed** data model, explicitly marked as such, built from the data-handling table in S2 rather than from DDL. |
| No system prompt | AI15 records that the system prompt's contents are unassessed; it cannot say whether anything security-relevant sits in it. |
| No DPA / privacy notice | P4 and P6 are stated as gaps in the evidence, not as confirmed non-compliance. A DPA may exist and not have been supplied. |
| No parent threat model | `06-threat-model.md` §10 Merge Reconciliation records that no parent exists to reconcile against, so nothing in this pack inherits an already-accepted residual. |

---

## 4. The three documents disagree with each other and with the tickets

This is recorded here because it shapes how every other document in the pack reads its sources. Full treatment is in `06-threat-model.md` §6a (findings O1, O2) and `03-security-architecture.md` §2.6.

| # | The approved documentation says | The tickets say | Where |
|---|---|---|---|
| 1 | "Each connector holds a per-user delegated credential obtained through OAuth... A user cannot reach anything through the assistant that they could not reach directly." | PLAT-2820 is **To Do**. PLAT-2820-1 is blocked on Identity Platform, requested 2026-04-18, not scheduled. PLAT-2820-3: "the prototype uses one app registration with application permissions across all connectors". | S1 Authorisation vs S5 PLAT-2820 |
| 2 | "Every privileged action taken by the assistant is recorded with the acting user, the action, and the parameters it was called with." | The same page, one section later: "Tool arguments and results are logged at debug level, off in production for volume reasons." | S1 Audit vs S1 Logging |
| 3 | "Actions are attributable to them in the target system's own audit log." | With one application-permission app registration, the target system records the app. | S1 vs S5 PLAT-2820-3 |
| 4 | "The corporate network boundary is the trust boundary... The one place untrusted content enters is web search." | Support's use case is "reading the ticket queue and the shared mailbox so it can summarise a customer's history" — content authored entirely by people outside the organisation. | S1 Trust model vs S2 Pilot scope |
| 5 | "All corporate applications authenticate through the identity provider. MFA is enforced for all users." | "The web console is behind the VPN with a shared password. SSO is PLAT-2831-3, not scheduled." | S3 Identity vs S2 / S5 PLAT-2831-3 |
| 6 | Connector table lists four connectors with defined scopes. | PLAT-2814-3: Slack "installed with the full scope set for the prototype... Narrow before GA." PLAT-2814-6 is To Do, not scheduled. | S1 Connectors vs S5 PLAT-2814-3 |

The architecture page (S1) is **Approved** and dated 2026-05-22, with a change-log entry reading "Authorisation section updated following D-03". It documents the decision, not the delivery. That distinction is finding O1 and is the headline of this review.

---

## 5. People named in the sources

Recorded because the brief asked for session participants, and because these are the people whose confirmation each finding needs. **No validation session has taken place.** These are the participants a session would need, drawn from the sources; they have not been contacted and none of the findings below carry their confirmation.

| Person | Role in the sources | Which findings need them |
|---|---|---|
| M. Oyelaran | Architecture owner (S1); Engineering owner of PROD-1131 | O1, O2, S2, E1, E3, T3, and the trust-model finding AI1 |
| P. Raghunathan | Orchestrator and connectors owner (S2); author of the PLAT-2820-3 and PLAT-2814-3 comments | E1, E2, AI3, AI8, AI9, AI10, C1, C6, R1 |
| D. Whitfield | Product owner, PROD-1131; product decisions (S2) | AI4 (the no-confirmation decision), P1 (Support mailbox in scope) |
| T. Egerton | Pilot coordination, Support (S2) | P1, P6, and the two mistaken Slack posts recorded in S2 |
| Platform Security | Owner of the standing controls page (S3) | O2, I3, CL1, CL6, C2, C5 |
| Identity Platform team | Dependency owner for delegated authorisation flows (S6) | E1, E5, S2 — the blocking dependency |
| Data Platform team | Holder of the model provider agreement and key management (S6) | P4, CL1 |
| Legal | Owner of PR-03, group AI governance | O3, P1, P6, and the compliance summary |
| COO office | Portfolio owner, PMO-0447; owner of the immovable date (PR-01) | The launch-gate sequencing in `04-gap-analysis.md` §7 |

---

## 6. Questions this pack could **not** answer, and what would answer them

Each row states the question, why it could not be answered from the supplied material, and the specific artefact that would settle it. This is the shopping list for the next iteration.

### 6.1 Authorisation and identity

| # | Question | What would answer it |
|---|---|---|
| Q1 | Does the shared app registration hold *application* permissions (tenant-wide) or *delegated* permissions with admin consent? PLAT-2820-3 says application; nothing confirms the actual grant. | The Entra ID app registration manifest and its consented permission set; the GitHub App's installation permissions and repository scope. |
| Q2 | What is "the full scope set" the Slack app was installed with? | The Slack app manifest (`bot`/`user` token scopes) from the workspace admin console. |
| Q3 | Is the GitHub app installed on all repositories or a subset? | The GitHub App installation record for the organisation. |
| Q4 | Who holds the web console's shared password, how is it distributed, and has it rotated since 2026-05-04? | The console's auth configuration and the credential's entry in Secrets Manager, with its rotation history. |
| Q5 | Does the orchestrator carry the requesting user's identity into the connector call at all, even as a field? | `assistant-svc` tool-dispatch source, and the MCP client's request construction. |

### 6.2 The model and its context

| # | Question | What would answer it |
|---|---|---|
| Q6 | What is in the system prompt, and does anything in it carry a security guarantee? | The prompt template files and their version history. |
| Q7 | What does the web-search "sanitiser" actually do — strip HTML, strip instructions, classify, or transform? | The sanitiser implementation and its test suite. |
| Q8 | Is there any structural delimiting (spotlighting) between system instructions, the user turn, and retrieved content? | The context-assembly code in `assistant-svc`. |
| Q9 | Which model versions are in use per workspace, and is the version pinned or floating? | The per-workspace model configuration store (PLAT-2822-2) and the provider client configuration. |
| Q10 | Is there any cap on tool-call iterations per turn? | The orchestrator loop. |
| Q11 | Which MCP servers are deployed, at which versions, and from where? | The connector runtime's deployment manifest and the MCP server images or packages with their digests. |

### 6.3 Data, retention and privacy

| # | Question | What would answer it |
|---|---|---|
| Q12 | What is actually stored in a Redis conversation record — full retrieved document content, or references? Is Redis encrypted at rest, and is it authenticated? | The conversation-state serialisation code and the ElastiCache/Redis configuration. |
| Q13 | What columns does the usage-telemetry warehouse table hold, and is the user dimension pseudonymised? | The warehouse DDL for the telemetry table. |
| Q14 | Does a Data Processing Agreement with the model provider cover this processing, this data class and these data subjects — including customer data from Support's mailbox? | The DPA and the enterprise agreement's scope, held by Data Platform. |
| Q15 | Is there a privacy notice covering assistant processing, and does anything inform the external correspondents whose mail is read? | The employee privacy notice and the customer-facing notice for Support. |
| Q16 | Has a DPIA been started? PR-03 suggests not. | The record of processing activities and any DPIA register entry. |
| Q17 | What happens to a conversation when its owner leaves? S2 records this as unresolved. | The joiner/mover/leaver process and any offboarding hook in the assistant. |

### 6.4 Infrastructure

| # | Question | What would answer it |
|---|---|---|
| Q18 | Are `assistant-svc` and `assistant-connectors` really in one namespace, and is there a NetworkPolicy between the pods within it? | The Helm chart or Kubernetes manifests. |
| Q19 | What Pod Security Admission level do the namespaces carry, and is there an admission controller (Kyverno/Gatekeeper)? | The namespace labels and the cluster's admission configuration. |
| Q20 | Do connector pods use IRSA, or the node instance role? Is IMDSv2 enforced? | The service account annotations and the node group launch template. |
| Q21 | Which domains are on the egress allowlist for this workload? | The egress proxy configuration for the assistant's namespace. |
| Q22 | Are the pilot and production environments separate AWS accounts, or the same account? | The account topology and the workload's deployment targets. |
| Q23 | Is there any backup, restore drill or rollback path for the conversation store, the model configuration or the connector scopes? | The runbook, if one exists. |

### 6.5 Governance

| # | Question | What would answer it |
|---|---|---|
| Q24 | Is the organisation an essential or important entity under NIS2? Nothing in the sources says what sector it operates in. | The organisation's regulatory classification. |
| Q25 | Does the EU AI Act apply, and at what risk tier? PR-03 says the governance workstream that would decide this has not begun. | The Legal assessment PR-03 is waiting on. |
| Q26 | Was the Security review named as a PROD-1131 dependency ("Scheduled") ever held, and did it cover the Support expansion? | The review record. |
| Q27 | Who is authorised to stop the assistant, and by what mechanism? S2 records this as an open question. | An incident runbook and a decided kill-switch owner. |

---

## 7. Open questions the team has already recorded

Credit where it is due: the team wrote down its own unknowns. All four are real, all four are load-bearing, and none of them is closed. They are carried into this pack rather than rediscovered.

| Recorded in | Question | Where it lands in this pack |
|---|---|---|
| S2 | What happens to a conversation when the person who started it leaves | P3, E5 |
| S2 | Whether Support's shared mailbox should be in scope at all, given whose data is in it | P1 — agreeing with the team; this is the correct question and the answer is currently "not yet" |
| S2 | Whether we need a kill switch, and who would be allowed to use it | AI11 |
| S6 | PR-03 — AI tooling governance is not yet defined at group level; initiatives proceed on the basis that governance will be retrofitted | O3 |

S2 also records five "known rough edges" from the pilot. Three of them are security findings the team has half-identified without labelling them as such: untrimmed context over a 24-hour session (AI5), acting rather than asking when uncertain (AI4), and "model responses occasionally include markdown images referencing external URLs from web results... Not investigated" (AI2). The third is the most serious unlabelled item in the sources.

---

## 8. Method and reading order

The pack was built in dependency order, and the file numbers are reading order rather than writing order.

| Read | File | Contains |
|---|---|---|
| 1 | `01-security-review.md` | Executive verdict, risk posture, gate readiness |
| 2 | `02-use-abuse-and-security-privacy-use-cases.md` | UC, SAC, PAC, SUC, PUC |
| 3 | `03-security-architecture.md` | Architecture map, trust boundaries, reconstructed data model, evaluation |
| 4 | `04-gap-analysis.md` | Required-vs-built, consolidated gap list G-01 onward |
| 5 | `05-srtm-and-test-artefacts.md` | Requirements traceability and test artefact definitions |
| 6 | `06-threat-model.md` | 68 findings across STRIPED, AI/ML, cloud, container and resilience surfaces |
| — | `06-threat-model-candidates.md` | The phase-1 elicitation record: one row per prompt of every instrument walked |

Instruments walked, in full: STRIPED 57 prompts · LINDDUN and AI privacy 9 · privacy dark patterns and human-centered security 16 · Elevation of Autonomy 30 cards · AI extension 20 · OWASP Cumulus 60 cards · container 25. 217 prompts, every one with a recorded outcome.

---

## 9. Attribution

Prepared by Brett Crawley, Principal Application Security Engineer. Produced with AI assistance (Claude Opus 5) using the security-review skill set authored by Brett Crawley.

**Session participants:** none. No validation session has been held. Section 5 lists the participants a session would require and which findings each is needed for. Nothing in this pack carries an owner's confirmation, and every status is derived from ticket state as extracted, not from a conversation.

*The material in `input/` is marked "Fictional, for conference demonstration purposes" on every page. This pack treats it as a real system for the purposes of analysis. Nothing here is legal advice; the GDPR, NIS2 and EU AI Act positions should be confirmed with counsel.*
