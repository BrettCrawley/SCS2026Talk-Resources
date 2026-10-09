# Internal AI Assistant — Context, Sources and Open Questions

**Version:** 1.1 (post-validation-session) · **Date:** 2026-09-09 · **Classification:** Internal
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this document and facilitator of the validation session. Produced with AI assistance using the security-review skill set authored by Brett Crawley.
**Model:** Claude Opus 5
**Companion documents:** `01-security-review.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model-candidates.md` · `06-threat-model.md` · `transcript.md`
**Provenance legend:** `[VS §n · CONFIRMED / CORRECTED / NEW / CONTESTED / ACCEPTED / CLOSED / STILL OPEN]`, where `n` is the section of the validation session transcript. Untagged text is v1.0 material the session did not touch.

> This document exists so that every other document in the pack can be read against a known evidence base. It states exactly what was supplied, exactly what was not, what each absence cost the analysis, and what would need to arrive for the unanswered questions to become answerable. Read it first; it is the difference between "this control is missing" and "this control was not visible to me".
>
> **v1.1 adds a third evidence class: testimony.** The validation session of 2026-09-09 converted a handful of absences into observations and left the rest exactly where they were. Testimony is better than a document's silence and it is not a manifest, so §6 now marks each question as **answered in the session**, **still open**, or **answered by a route the pack could not see**. **The repository is still absent.** Nothing in §3 has changed.

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
| No parent threat model | `06-threat-model.md` §10 Merge Reconciliation records that no parent exists to reconcile against, so nothing in this pack inherits an already-accepted residual. `[VS · v1.1]` §10 now also records that the organisation's **control** baseline cannot be safely inherited either, because its exceptions are held outside it (**O6**). |
| **No exceptions register for the standing controls page** `[VS §2 · NEW]` | The `platform-ci` branch-protection exemption (**O6**) exists in configuration and in no document. Nothing establishes it is the only one — see Q28 in §6. Every place this pack credits a standing control as bounding a finding is therefore credited against a page whose exceptions are not enumerable, which is why Appendix F of the threat model now carries a withdrawn credit (T3). |

---

## 4. The three documents disagree with each other and with the tickets

This is recorded here because it shapes how every other document in the pack reads its sources. Full treatment is in `06-threat-model.md` §6a (findings O1, O2) and `03-security-architecture.md` §2.6.

`[VS · v1.1]` **The session added a seventh row, and it is the one that does not fit the pattern.** Rows 1 to 6 are disagreements between two artefacts, which is a comparison anybody can run. Row 7 is a disagreement between the documentation and something that exists in no artefact at all, which is why the pack could not find it and a room could.

| # | The approved documentation says | The tickets say | Where |
|---|---|---|---|
| 7 `[VS §2 · NEW]` | Standing controls page, Source control: protected branches require an approving review and signed commits, organisation-wide | Nothing. **A standing exemption for `platform-ci` exists as a config file in the organisation repository and is written down nowhere a reviewer would look.** Finding **O6** | S3 Source control vs a configuration file in no supplied source |
| 8 `[VS §3 · NEW]` | Architecture page Trust model: internal sources are behind authentication and do not need web search's handling | PLAT-2814's acceptance criterion says the same thing — **and it was written as a scoping note, not a security decision.** The two artefacts agree and neither is the decision. Finding **O7** | S1 Trust model vs S5 PLAT-2814, and neither against anything |
| 1 | "Each connector holds a per-user delegated credential obtained through OAuth... A user cannot reach anything through the assistant that they could not reach directly." | PLAT-2820 is **To Do**. PLAT-2820-1 is blocked on Identity Platform, requested 2026-04-18, not scheduled. PLAT-2820-3: "the prototype uses one app registration with application permissions across all connectors". | S1 Authorisation vs S5 PLAT-2820 |
| 2 | "Every privileged action taken by the assistant is recorded with the acting user, the action, and the parameters it was called with." | The same page, one section later: "Tool arguments and results are logged at debug level, off in production for volume reasons." | S1 Audit vs S1 Logging |
| 3 | "Actions are attributable to them in the target system's own audit log." | With one application-permission app registration, the target system records the app. | S1 vs S5 PLAT-2820-3 |
| 4 | "The corporate network boundary is the trust boundary... The one place untrusted content enters is web search." | Support's use case is "reading the ticket queue and the shared mailbox so it can summarise a customer's history" — content authored entirely by people outside the organisation. | S1 Trust model vs S2 Pilot scope |
| 5 | "All corporate applications authenticate through the identity provider. MFA is enforced for all users." | "The web console is behind the VPN with a shared password. SSO is PLAT-2831-3, not scheduled." | S3 Identity vs S2 / S5 PLAT-2831-3 |
| 6 | Connector table lists four connectors with defined scopes. | PLAT-2814-3: Slack "installed with the full scope set for the prototype... Narrow before GA." PLAT-2814-6 is To Do, not scheduled. | S1 Connectors vs S5 PLAT-2814-3 |

The architecture page (S1) is **Approved** and dated 2026-05-22, with a change-log entry reading "Authorisation section updated following D-03". It documents the decision, not the delivery. That distinction is finding O1 and is the headline of this review.

---

## 5. People named in the sources

Recorded because the brief asked for session participants, and because these are the people whose confirmation each finding needs. `[VS · v1.1]` **The validation session took place on 2026-09-09, 13:30–15:08**, facilitated by the author. Six of the nine required parties attended. Attendance is recorded per row, because a finding confirmed by its owner and a finding nobody was available to confirm are different kinds of claim and the pack should not present them identically.

| Person | Role in the sources | Which findings need them | Attended | What it means for those findings |
|---|---|---|---|---|
| Marcus Oyelaran | Architecture owner (S1); Engineering owner of PROD-1131 | O1, O2, S2, E1, E3, T3, AI1, **O6**, **O7** | **Yes** | Confirmed O1 and AI1 against his own pages; withdrew his defence of branch protection on new evidence (T3, **O6**); owns the input-channel decision (**O7**) |
| Priya Raghunathan | Orchestrator and connectors owner (S2); author of the PLAT-2820-3 and PLAT-2814-3 comments | E1, E2, AI3, AI8, AI9, AI10, AI12, C1, C3, C6, R1, R3, T2, T3, T4, I2, I4, P2, CL1, D1, D3 | **Yes** | Converted AI10, AI12 and C3's provenance half from assertion to observation; confirmed AI3, R1, R3, P2, D1, D3; **refused to answer on Redis, the sanitiser and the manifests** |
| Dana Whitfield | Product owner, PROD-1131; product decisions (S2) | AI4, P1, E4, AI11, and O1's propagation | **Yes** | Contested AI4's remedy and accepted **AR-02**; owns the kill-switch owner decision and the standing expansion gate |
| Tom Egerton | Pilot coordination, Support (S2) | P1, P6, O4, O5, AI1, **P8** | **Yes** | Supplied the three Slack Connect channels (**P8**); accepted the mailbox exclusion's cost (**AR-03**); writes up the two Slack posts as the first playbook entries |
| Ines Ferreira | Data Protection Officer | P1, P2, P3, P4, P6, P7, **P8**, O3, and the compliance summary | **Yes** | Corrected P1's text, the NIS2 route and the ISO 27001 position; confirmed P6 and refused to have AI13 softened |
| Kwame Osei | Security Champion, Platform | O2, I3, CL1, CL6, C1, C2, C5, C6, AI2 | **Yes, in Platform Security's seat** | **He does not own the standing controls page.** His answer closed C5 (**AR-01**) and declined the same closure for CL6 |
| Platform Security | Owner of the standing controls page (S3) | O2, **O6**, C5, and the baseline coverage in Appendix F | **No** | C5's closure and every baseline-coverage answer rest on the Security Champion's testimony, not the page owner's |
| Identity Platform team | Dependency owner for delegated authorisation flows (S6) | E1, E5, S2 — the blocking dependency | **No — no response** | PLAT-2820-1 unchanged: blocked since 2026-04-18, unscheduled. **They also block E1's interim control**, which the pack had not appreciated |
| Data Platform team | Holder of the model provider agreement and key management (S6) | P4, CL1 | **No — declined, holiday** | P4 stays High on absent evidence rather than being downgraded on the expectation of it. Escalation rather than a third request |
| Legal | Owner of PR-03, group AI governance | O3, P1, P6, and the compliance summary | Represented by the DPO | NIS2 resolved by a contractual route; the EU AI Act tier is still blocked behind PR-03 |
| COO office | Portfolio owner, PMO-0447; owner of the immovable date (PR-01) | The launch-gate sequencing in `04-gap-analysis.md` §7 | **No** | The escalation goes to them this week with the finding IDs attached |

---

## 6. Questions this pack could **not** answer, and what would answer them

Each row states the question, why it could not be answered from the supplied material, and the specific artefact that would settle it. This is the shopping list for the next iteration.

`[VS · v1.1]` **Status after the validation session.** Twenty-seven questions went in; the session closed six and part of a seventh, and left twenty open. **The shopping list is essentially unchanged, and the artefact that would settle almost all of it is still the repository.** The session's own conclusion on this was blunt: "this pack was written without a repository and we have not fixed that in a room."

| Outcome | Questions |
|---|---|
| **Answered in the session, from an owner's direct knowledge** | **Q1** (partly — application permissions confirmed, the consented set still unseen), **Q5** (no — the identity is dropped before dispatch), **Q10** (no cap on the loop at all), **Q11** (all four unpinned on `latest`, no digest), **Q13** (`user_ref` on every row, not pseudonymised), **Q24** (see below) |
| **Answered by a route the pack could not see** | **Q24** — the organisation is **not** an essential or important entity under NIS2, and the Article 21 measures apply anyway through two customer contracts. Neither half was in the supplied material |
| **Put to the room and deliberately not answered** | **Q6** (the prompt exists, is in the repo, and has never been reviewed as a security artefact — which is the finding, not the answer), **Q7**, **Q12**, **Q19**, **Q20**, **Q21**, **Q22**, **Q27** (the owner does not exist yet; Dana Whitfield names one within two weeks) |
| **Unchanged — nobody present could answer, or the holder did not attend** | Q2, Q3, Q4, Q8, Q9, Q14 (Data Platform declined), Q15, Q16, Q17, Q18, Q23, Q25, Q26 |

**One question the session added.** `[VS §2 · NEW]` **Q28 — what other standing exemptions to the platform security controls exist that are held only in configuration?** The `platform-ci` branch-protection exemption (**O6**) surfaced because one engineer happened to mention it. Nothing establishes that it is the only one, and the estate has no register in which such a thing would appear. *What would answer it:* the organisation's repository settings, cluster policy configuration and egress proxy configuration, read against the standing controls page — which is a repository question again.

### 6.1 Authorisation and identity

| # | Question | What would answer it |
|---|---|---|
| Q1 | Does the shared app registration hold *application* permissions (tenant-wide) or *delegated* permissions with admin consent? PLAT-2820-3 says application; nothing confirms the actual grant. | The Entra ID app registration manifest and its consented permission set; the GitHub App's installation permissions and repository scope. |
| Q2 | What is "the full scope set" the Slack app was installed with? | The Slack app manifest (`bot`/`user` token scopes) from the workspace admin console. |
| Q3 | Is the GitHub app installed on all repositories or a subset? | The GitHub App installation record for the organisation. |
| Q4 | Who holds the web console's shared password, how is it distributed, and has it rotated since 2026-05-04? | The console's auth configuration and the credential's entry in Secrets Manager, with its rotation history. |
| Q5 | Does the orchestrator carry the requesting user's identity into the connector call at all, even as a field? | `assistant-svc` tool-dispatch source, and the MCP client's request construction. **`[VS §1 · ANSWERED — no]`** P. Raghunathan: "The orchestrator takes the user's identity at the surface and it doesn't carry it into the dispatch. There is no user field on the connector call. It gets dropped before the MCP client sees it." Findings O1, E1, S2 and R2 rest on this and it is no longer an inference. |

### 6.2 The model and its context

| # | Question | What would answer it |
|---|---|---|
| Q6 | What is in the system prompt, and does anything in it carry a security guarantee? | The prompt template files and their version history. |
| Q7 | What does the web-search "sanitiser" actually do — strip HTML, strip instructions, classify, or transform? | The sanitiser implementation and its test suite. **`[VS §3, §10 · STILL OPEN]`** Put to its owner twice and not answered either time: "I don't know. I inherited it and I've never read it end to end." That is why AI6's recommendation is to ratify in writing that it is not load-bearing — the coverage of a control nobody has read cannot be estimated, only removed from the load path. |
| Q8 | Is there any structural delimiting (spotlighting) between system instructions, the user turn, and retrieved content? | The context-assembly code in `assistant-svc`. |
| Q9 | Which model versions are in use per workspace, and is the version pinned or floating? | The per-workspace model configuration store (PLAT-2822-2) and the provider client configuration. |
| Q10 | Is there any cap on tool-call iterations per turn? | The orchestrator loop. |
| Q11 | Which MCP servers are deployed, at which versions, and from where? | The connector runtime's deployment manifest and the MCP server images or packages with their digests. **`[VS §8 · ANSWERED]`** All four are pinned to `latest` — "Latest as in whatever is at that tag when the pod starts. There's no digest anywhere" — stated as observation by the engineer who set it up. AI10, AI12 and C3's provenance half lose their "if present" tag on this. The *identity* of the community project is still unknown. |

### 6.3 Data, retention and privacy

| # | Question | What would answer it |
|---|---|---|
| Q12 | What is actually stored in a Redis conversation record — full retrieved document content, or references? Is Redis encrypted at rest, and is it authenticated? | The conversation-state serialisation code and the ElastiCache/Redis configuration. **`[VS §10 · STILL OPEN]`** Declined rather than guessed: "It's a `requirepass` and a parameter group and I'd be guessing." I2 and T4 stand as written and stay tagged "if present". |
| Q13 | What columns does the usage-telemetry warehouse table hold, and is the user dimension pseudonymised? | The warehouse DDL for the telemetry table. **`[VS §7 · ANSWERED]`** `user_ref` is on every row and is not pseudonymised — "The dashboard groups it away, the table doesn't." The row is user, team, model, token counts, tool names, latency; **no customer content and no customer identifier**, which is the basis of P1's text correction. Who may *query* the partition is still unknown (Q-CL5 / CL5). |
| Q14 | Does a Data Processing Agreement with the model provider cover this processing, this data class and these data subjects — including customer data from Support's mailbox? | The DPA and the enterprise agreement's scope, held by Data Platform. **`[VS §7 · STILL OPEN]`** Data Platform declined the session. The DPO has asked twice and will escalate rather than ask a third time. P4 stays High until the evidence exists; it is expressly not downgraded on the expectation of it. |
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
| Q24 | Is the organisation an essential or important entity under NIS2? Nothing in the sources says what sector it operates in. | The organisation's regulatory classification. **`[VS §7 · ANSWERED — and the question was the wrong one]`** **No**, the organisation is not an essential or important entity. **The Article 21 measures apply anyway**, because two customers are, and their contracts pass the obligation down. The pack framed the sector determination as the finding; the sector determination resolves to no and the obligation arrives by a route that lives in two contracts nobody supplied. *What would now answer the remaining part:* the two customer contracts, and an enumeration of the specific measures they impose. |
| Q25 | Does the EU AI Act apply, and at what risk tier? PR-03 says the governance workstream that would decide this has not begun. | The Legal assessment PR-03 is waiting on. |
| Q26 | Was the Security review named as a PROD-1131 dependency ("Scheduled") ever held, and did it cover the Support expansion? | The review record. |
| Q27 | Who is authorised to stop the assistant, and by what mechanism? S2 records this as an open question. | An incident runbook and a decided kill-switch owner. **`[VS §9 · STILL OPEN — and now owned]`** Nobody. Asked directly, the architecture owner answered "I don't know. Me, probably. Nobody's said." The only available mechanism is scaling the deployment to zero, which takes out both pilots for everyone **and removes the record of what was happening while it is done**. D. Whitfield names the owner within two weeks; the named owner then builds the mechanism. |

---

## 7. Open questions the team has already recorded

Credit where it is due: the team wrote down its own unknowns. All four are real, all four are load-bearing, and none of them is closed. They are carried into this pack rather than rediscovered.

| Recorded in | Question | Where it lands in this pack |
|---|---|---|
| S2 | What happens to a conversation when the person who started it leaves | P3, E5 |
| S2 | Whether Support's shared mailbox should be in scope at all, given whose data is in it | P1 — agreeing with the team; this is the correct question and the answer is currently "not yet" |
| S2 | Whether we need a kill switch, and who would be allowed to use it | AI11 — **`[VS §9]`** raised by T. Egerton in June, still open in September; now owned by D. Whitfield to name an owner within two weeks |
| S6 | PR-03 — AI tooling governance is not yet defined at group level; initiatives proceed on the basis that governance will be retrofitted | O3 — **`[VS §7]`** the NIS2 half of the vacuum is now filled by a contractual obligation rather than by the workstream |

`[VS §7 · NEW]` **A fifth, which the team did not record and which the session surfaced.** The DPO's own account of the mailbox question — "I'd have stopped it in June if I'd been asked… Nobody told me either. That's the finding." The team wrote the right question down in S2 and did not route it to the person who could answer it. That is a different failure from not asking the question, and it is the one worth designing against: O3's interim gate and O4's expansion record both exist to make sure a recorded unknown reaches an owner rather than a page.

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

**Session participants.** `[VS · v1.1]` Validation session held 2026-09-09, 13:30–15:08, facilitated by Brett Crawley: Dana Whitfield (Product), Marcus Oyelaran (architecture and engineering owner), Priya Raghunathan (orchestrator and connector runtime), Tom Egerton (Support), Ines Ferreira (Data Protection Officer), Kwame Osei (Security Champion, Platform). Invited and absent: Identity Platform (no response), Data Platform (declined), the owner of the standing platform security controls page. Section 5 records what each absence costs.

Statuses in this pack are now of three kinds and the distinction is deliberate: **derived from ticket state as extracted**, **confirmed by a named owner in the session** (tagged `[VS §n · CONFIRMED]`), and **corrected against what the session established** (tagged `[VS §n · CORRECTED]`). A fourth kind is marked where it applies — **still open**, meaning the question was put to the room and nobody could answer it. Nothing has been quietly upgraded from one kind to another, and no finding has been closed or downgraded on an argument rather than on evidence.

*The material in `input/` is marked "Fictional, for conference demonstration purposes" on every page. This pack treats it as a real system for the purposes of analysis. Nothing here is legal advice; the GDPR, NIS2 and EU AI Act positions should be confirmed with counsel.*
