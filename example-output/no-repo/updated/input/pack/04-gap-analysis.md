# Internal AI Assistant — Gap Analysis

**Version:** 1.0 (first pass) · **Date:** 2026-09-09 · **Classification:** Internal
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this document. Produced with AI assistance using the security-review skill set authored by Brett Crawley.
**Model:** Claude Opus 5
**Frameworks:** STRIPED · LINDDUN · OWASP Top 10 (2021) · OWASP LLM and Agentic Top 10 · GDPR and Privacy by Design
**Regulatory scope:** GDPR and UK GDPR (applies) · NIS2 (unassessed, sector not stated) · EU AI Act (unassessed, blocked behind PR-03) · EU CRA (does not apply) · UK PSTI (does not apply) · PCI-DSS (conditional on Support mailbox content) · HIPAA (does not apply) · SOC 2 (indirect)
**Companion documents:** `03-security-architecture.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md` · `02-use-abuse-and-security-privacy-use-cases.md`

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted.

---

## 0. Headline

Start with what is genuinely strong, because it is specific and it is load-bearing for the rest of this document.

**The inherited platform baseline is better than most.** Egress control through a domain-allowlisting proxy, in place since 2023 and reviewed weekly by Platform Security. Branch protection with required review and signed commits across the whole GitHub organisation. Organisation-wide secret scanning with push protection. Dependency scanning that blocks the build on Critical findings. Base images scanned on push and rebuilt weekly. Default-deny network policy between namespaces. Debug and diagnostic endpoints disabled in production by configuration before promotion. Eleven elicitation prompts in the threat model resolve to "no exposure" solely because of these controls, and the team did not have to argue for any of them.

**D-03 is the right architectural decision, taken early.** "Assistant acts as the requesting user, not as a system identity — preserves attribution and existing permission boundaries", dated 2026-04-02, before a line of the connector runtime existed. That is the correct answer for an agentic system with tool access, and most teams arrive at it after an incident. **D-05 is right too** — refusing to build a new system of record removed a whole class of duplication and retention risk.

**And the team writes down what it does not know.** The pilot operations page carries a "Known rough edges" list and an "Open questions we have not resolved" list. Four of this review's findings are the team's own observations promoted to findings with severities and owners: untrimmed context (AI5), acting rather than asking (AI4), the markdown images that were "not investigated" (AI2), and whether Support's mailbox should be in scope at all (P1). This document agrees with them; it did not discover them.

What remains is a smaller, sharper set. It clusters into six themes.

1. **One control is documented as delivered and is not built.** The approved architecture page states that connectors hold per-user delegated credentials and that a user cannot reach anything through the assistant that they could not reach directly. PLAT-2820 is To Do, blocked on Identity Platform since 2026-04-18 and unscheduled, and PLAT-2820-3 records the prototype running on one app registration with application permissions across all connectors. This is **G-01**, and the documentation defect is **G-22** — separated because they need different fixes and different owners.
2. **The trust boundary is drawn around the network, not around who authored the content.** Web search is treated as the only untrusted input while Support reads a mailbox of entirely customer-authored mail and GitHub reads issues from outside contributors. **G-06.**
3. **Model output reaches sinks with no deterministic filter.** Six sinks, zero filters. The markdown renderer is the one that completes an exfiltration path needing no credential at any stage, and the team already observed the symptom. **G-03, G-04.**
4. **The evidence layer is missing.** Tool arguments are not recorded in production, the action display is rendered from the model's own account of itself, and the conversation the user can delete is the only artefact describing what happened. Every incident scenario in the threat model runs aground on this. **G-09.**
5. **Privacy obligations are unmet across the board, and the highest-risk one the team raised itself.** Support's shared mailbox processes third-party personal data with no lawful basis identified, no DPIA, no notice and no deletion path. **G-13, G-14, G-15, G-16, G-17, G-19, G-20.**
6. **Nothing can be stopped, and nothing is inventoried.** No kill switch, no agent inventory, no AI-BOM, no incident playbook — and PR-03 records that the governance workstream that would require any of them has not started. **G-11, G-12, G-21.**

There is also a cluster of **residual design risks worth a decision rather than a fix**: the model provider agreement scoped for another team's purposes (D-01, a portfolio-level commercial trade), the structural hazards that cannot be closed at the model layer (adversarial subspace and boundary transfer), and proceeding without group AI governance (PR-03, accepted at the July steering group). Each should be carried knowingly in an ADR with a named owner, not left as an assumption.

Nothing here is a reason not to build this system. Several are reasons not to expand the pilot again first, and one — the CSP header in G-03 — is a day of work standing between the organisation and a credential-free exfiltration path.

---

## 1. Assumptions and context

| Question | Answer from the inputs |
|---|---|
| What is being built | An agentic assistant reachable from Slack and a web console, reading across Office 365, Slack, GitHub and public web search through four MCP connectors, and acting in those systems — sending mail, posting to Slack, commenting and committing. An orchestrator loops model calls and tool dispatches; conversation state lives in Redis for 24 hours; usage telemetry lives in a warehouse for 13 months. EKS, single region. |
| Actors | 21 pilot users (12 Platform since 2026-05-04, 9 Support since 2026-06-09); the orchestrator; four connector processes including one community MCP server; the hosted model provider as sub-processor; and **external correspondents** — customers, GitHub issue authors and web page authors — who author content the assistant reads and who hold no account. |
| Data | Document content and mail (Internal, some Confidential, some personal), calendar (Internal), Slack messages (Internal), source code (Confidential), customer correspondence (personal data of third parties, potentially special category), conversation state (all of the above, 24h), usage telemetry (personal data, 13 months). |
| Deployment | EKS single region, public ingress to the two surfaces only, internal services with no ingress route, egress through a domain-allowlisting proxy, secrets in AWS Secrets Manager mounted at pod start. All connectors and the orchestrator share one namespace. |
| Regulatory | GDPR and UK GDPR apply. NIS2 and EU AI Act applicability are unassessed. CRA and PSTI do not apply. PCI-DSS is conditional on what has arrived in the Support mailbox. |
| Market or expansion triggers | PROD-1131 Phase 3 names unattended operation and customer-facing surfaces as future scope. A customer-facing surface would trigger a CRA re-assessment and would move the EU AI Act question from likely-limited-risk to a question that must be answered. |
| Downloadable or embedded software | None. Two hosted surfaces, no client, no device, no firmware. This is why CRA and PSTI do not apply. |

**Assumptions carried — flag any that are wrong.** (a) The organisation and its employees are in the EU or UK, since the model endpoint is EU-hosted and the pages are written to a GDPR frame; (b) PLAT-2820-3's description of the prototype is current, since nothing supersedes it; (c) the platform security controls page describes controls that are actually live, since it is Approved and dated and designs are instructed to rely on it; (d) the pilot is running with real data, since S2 describes real incidents; (e) `assistant-svc` and `assistant-connectors` are the only two workloads in the assistant's namespace; (f) no Data Processing Agreement covering this processing exists, since none was supplied — this one in particular may simply be a supply gap rather than a real absence.

---

## 2. Requirements classification

Requirements are extracted from the epic and story acceptance criteria, the initiative decisions, and the control claims made on the approved design pages. A control claim on an approved page is a requirement the organisation has set itself, whether or not it was written as one.

### 2.1 Functional (FR)

| ID | Requirement | Source | Status |
|---|---|---|---|
| FR-01 | Available in Slack and in a web console | PLAT-2810 AC | 🟢 Live |
| FR-02 | Answer questions using content from Office 365, Slack, GitHub and web search | PLAT-2810 AC, PLAT-2814 | 🟢 Live |
| FR-03 | Take actions, not just read: send mail, post to Slack, comment and update GitHub issues, commit changes | PLAT-2810 AC, PLAT-2817 | 🟢 Live |
| FR-04 | Users see what the assistant did | PLAT-2810 AC, PLAT-2825 | 🟡 Live but sourced from the model's narration, PLAT-2825-1 |
| FR-05 | A user can review their own conversation history and delete their own conversations | PLAT-2825-2 | 🟢 Live |
| FR-06 | Token usage tracked per team; teams can see their own consumption | PLAT-2822 AC, PLAT-2822-3 | 🟢 Live |
| FR-07 | Cheaper model tiers configurable per workspace | PLAT-2822 AC, PLAT-2822-2 | 🟢 Live |
| FR-08 | Content returned from web search is treated as untrusted and cleaned before use | PLAT-2814 AC | 🟡 Sanitiser exists on one of five untrusted channels, PLAT-2814-5 |

### 2.2 Security (SEC)

| ID | Requirement | Source | Status | Gap? |
|---|---|---|---|---|
| SEC-01 | Per-user delegated credentials for every connector, short TTL, refreshed rather than long-lived | PLAT-2820 AC, D-03, architecture page Authorisation | 🔴 Open | **G-01** |
| SEC-02 | A user cannot reach anything through the assistant that they could not reach directly | PLAT-2820 AC, architecture page | 🔴 Open | **G-01** |
| SEC-03 | Actions attributable to the requesting user in the target system's own audit log | PLAT-2820 AC, architecture page | 🔴 Open | **G-01** |
| SEC-04 | Every privileged action recorded with acting user, action and the parameters it was called with | Architecture page Audit | 🔴 Open — contradicted by the same page's Logging section | **G-09** |
| SEC-05 | Connector scopes narrowed to the designed set before GA | PLAT-2814-6 | 🔵 Planned, not scheduled | **G-02** |
| SEC-06 | SSO on the web console before anyone outside the pilot sees it | PLAT-2831-3 | 🔵 Planned, not scheduled | **G-08** |
| SEC-07 | All corporate applications authenticate through the identity provider with MFA | Platform controls page Identity | 🔴 Open for the console | **G-08**, **G-22** |
| SEC-08 | Public ingress reaches the surfaces only; internal services carry no ingress route | Architecture page Deployment | 🟢 Live | — |
| SEC-09 | Outbound traffic passes the egress proxy domain allowlist | Platform controls page Network | 🟡 Live, and does not bound allowlisted user-content hosts or client-side fetches | **G-03** |
| SEC-10 | Default-deny network policy between namespaces | Platform controls page Runtime | 🟡 Live, and does not separate components inside one namespace | **G-07** |
| SEC-11 | Secrets in AWS Secrets Manager, workload identity scoped to the specific secrets a service requires | Platform controls page Secrets | 🟡 Live, and one shared secret set is mounted alongside third-party code | **G-07** |
| SEC-12 | Debug and diagnostic endpoints disabled in production builds | Platform controls page Runtime | 🟢 Live — and does not cover debug log level | **G-09** |
| SEC-13 | Protected branches require an approving review; signed commits; secret scanning with push protection | Platform controls page Source control | 🟢 Live | — |
| SEC-14 | Dependency scanning blocks the build on Critical findings; base images scanned and rebuilt weekly | Platform controls page Vulnerability management | 🟡 Live, and reaches neither the MCP tool surface nor image provenance at admission | **G-11** |
| SEC-15 | TLS in transit between services and to managed datastores | Platform controls page Runtime | 🟢 Live | — |

### 2.3 Privacy (PRV)

| ID | Requirement | Source | Status | Gap? |
|---|---|---|---|---|
| PRV-01 | No new persistent stores; read from systems of record in place | D-05, architecture page Data handling | 🟡 Honoured for systems of record; conversation state and telemetry are new derived stores | **G-14** |
| PRV-02 | Conversation state expires after 24 hours | Architecture page Data handling, data handling table | 🟢 Live — genuinely good, and the strongest privacy control in the design | — |
| PRV-03 | Usage telemetry retained 13 months, aggregated to team for cost attribution | PLAT-2822-1, data handling table | 🔴 Open — the store retains the per-user dimension the dashboard hides | **G-14** |
| PRV-04 | Users can delete their own conversations | PLAT-2825-2 | 🟡 Live for one of four stores, and unavailable to third parties | **G-15** |
| PRV-05 | Lawful basis identified for each category of personal data processed | Not stated in any source | 🔴 Open | **G-13** |
| PRV-06 | DPIA completed for high-risk processing | Not stated; PR-03 records the governance workstream has not started | 🔴 Open | **G-13** |
| PRV-07 | Privacy notice covering the processing, for each audience | Not stated in any source | 🔴 Open | **G-20** |
| PRV-08 | Subject access, rectification, erasure and objection executable in practice | Not stated in any source | 🔴 Open | **G-15**, **G-19** |
| PRV-09 | Processor agreement covering the model provider for this purpose and these categories | D-01 references an existing agreement held by Data Platform | 🔴 Open — scope unverified | **G-16** |
| PRV-10 | Data minimisation in context assembly and in output | Not stated in any source | 🔴 Open | **G-18** |
| PRV-11 | Special-category data not derived without an Article 9 condition | Not stated in any source | 🔴 Open | **G-17** |
| PRV-12 | Conversation and data disposition on offboarding | Recorded as an unresolved open question, S2 | 🔴 Open | **G-15** |

### 2.4 Performance (PERF)

| ID | Requirement | Source | Status | Gap? |
|---|---|---|---|---|
| PERF-01 | Response under 6 seconds for a typical question | PLAT-2810 AC | 🟡 Degrades on long conversations, S2 rough edges | **G-18** |
| PERF-02 | Running cost predictable and attributable to a cost centre | PMO-0447 constraint | 🟡 Attributable via PLAT-2822-3; not predictable, because nothing caps it | **G-10** |
| PERF-03 | Provider rate limiting handled without user-visible failure | S2 rough edges | 🟡 Handled by retry, which amplifies | **G-10** |
| PERF-04 | Availability under partial dependency failure | Not stated | 🔴 Open — fails open with an answer the user cannot distinguish | **G-09** |

### 2.5 Compliance (COMP)

| ID | Requirement | Source | Status | Gap? |
|---|---|---|---|---|
| COMP-01 | GDPR Articles 5, 6, 9, 12–17, 28, 32, 33, 35 satisfied for all processing | Regulatory | 🔴 Open on 5(1)(b), 5(1)(c), 5(1)(d), 5(2), 6, 9, 13, 14, 15, 16, 17, 28, 32, 35 | **G-13** to **G-20** |
| COMP-02 | NIS2 applicability determined and, if in scope, Article 21 and 23 measures met | Regulatory | 🔴 Open — the sector determination itself is missing | **G-21** |
| COMP-03 | EU AI Act applicability determined and transparency obligations met | PR-03, regulatory | 🔴 Open — blocked behind a workstream that has not started | **G-21**, **G-20** |
| COMP-04 | EU CRA applicability assessed | Regulatory | ⚪ Assessed: does not apply — no product with digital elements is placed on the EU market | — |
| COMP-05 | UK PSTI applicability assessed | Regulatory | ⚪ Assessed: does not apply — no consumer connectable product | — |
| COMP-06 | PCI-DSS applicability assessed | Regulatory | 🔴 Open — conditional on whether cardholder data has reached the Support mailbox | **G-13** |
| COMP-07 | HIPAA applicability assessed | Regulatory | ⚪ Assessed: does not apply — no protected health information, no covered entity relationship | — |
| COMP-08 | SOC 2 criteria met where the assistant sits inside an operated control environment | Regulatory | 🔴 Open on CC6.1, CC6.3, CC7.1, CC8.1, C1, A1 | **G-01**, **G-09** |
| COMP-09 | Group AI governance requirements met | PMO-0447 PR-03 | 🔴 Open — workstream not started, retrofit accepted at the July steering group | **G-21** |

---

## 3. Consolidated gap list

| Gap | Title | Severity | Type | Findings | Ticket |
|---|---|---|---|---|---|
| **G-01** | Per-user delegated authorisation is documented as delivered and is not built | **Critical** | Design decision | E1, S2, R2, E5, O1 | PLAT-2820 |
| **G-02** | Connector scopes are at prototype width with narrowing unscheduled | **High** | Hardening | E1, E2, E3, E4, CL4 | PLAT-2814-6 |
| **G-03** | No deterministic filter on model output at any rendering or posting sink | **Critical** | Design decision | AI2, I3 | none |
| **G-04** | Tool arguments are not value-validated before dispatch | **Critical** | Design decision | AI3, T3 | none |
| **G-05** | Irreversible actions execute with no confirmation and no provenance gate | **High** | Design decision | AI4, AI13, S4 | none |
| **G-06** | The untrusted-content boundary covers one of five input channels | **Critical** | Design decision | AI1, AI6, AI14, AI5 | none |
| **G-07** | Connector runtime has no isolation boundary or per-connector identity | **High** | Design decision | C1, C6, I4, I2, T4, S5, CL6, C2, C5 | none |
| **G-08** | Web console authenticates with a shared password | **High** | Deploy lag | S1, I1, S3, O2 | PLAT-2831-3 |
| **G-09** | No independent record of what the assistant dispatched | **High** | Assurance | R1, R3, R4, R5, T2, D5, AI7 | none |
| **G-10** | No hard cap on tokens, iterations or per-user rate | **High** | Hardening | D1, D2, D3, D4, CL2, C4 | PLAT-2822-4 |
| **G-11** | No AI-BOM; MCP servers and tool descriptions unpinned and unreviewed on update | **High** | Assurance | AI9, AI10, AI12, AI15, C3, T1 | none |
| **G-12** | No kill switch, agent inventory, incident playbook or tested rollback | **High** | Assurance | AI11, O5, RR1, CL3 | none |
| **G-13** | No lawful basis or DPIA for third-party personal data in the Support mailbox | **Critical\*** | Compliance | P1, O4 | none |
| **G-14** | Telemetry retains a per-user dimension beyond its stated purpose | **High** | Compliance | P2, CL5, PRV-01 | none |
| **G-15** | No deletion path spans the four stores, and none triggers on offboarding | **High** | Compliance | P3, R5, E5 | none |
| **G-16** | Model provider agreement scope is unverified for this processing | **High** | Compliance | P4 | none |
| **G-17** | Special-category inference from calendar and mail with no Article 9 condition | **High** | Compliance | P7 | none |
| **G-18** | Context is neither minimised nor bounded to one purpose within a session | **Medium** | Hardening | P5, AI5, PERF-01 | none |
| **G-19** | No grounding, citation or rectification route for statements about people | **High** | Compliance | AI13, R3 | none |
| **G-20** | No privacy notice or machine-generated marker for any audience | **High** | Compliance | P6, S4 | none |
| **G-21** | No AI governance gate; applicability of NIS2 and the EU AI Act undetermined | **High** | Compliance | O3, O4 | PMO-0447 PR-03 |
| **G-22** | Approved design pages state control claims that the ticket state contradicts | **Critical** | Doc-drift | O1, O2 | none |

\* **G-13** carries a conditional severity. It is Critical while Support's shared mailbox is in active connector scope with real customer correspondence, which it has been since 2026-06-09. Removing the mailbox from scope — an afternoon's work as a connector-side allowlist — moves it to Medium as a design risk against future expansion, without removing the need for the DPIA. The conditionality is stated so the sequencing argument stays honest: the cheap interim control and the required compliance work are different things and both are needed.

**Twenty-two gaps. Seventeen have no ticket at all** — G-03, G-04, G-05, G-06, G-07, G-09, G-11, G-12, G-13, G-14, G-15, G-16, G-17, G-18, G-19, G-20 and G-22. Four map to tickets that exist and are unscheduled (G-01, G-02, G-08, G-10), and G-21 has a portfolio risk entry (PR-03) rather than a delivery ticket. That ratio is the practical finding: most of the work in this review is not late, it has not been raised.

---

## 4. Regulatory compliance assessment

### 4.1 GDPR and UK GDPR — applies

| Article | Obligation | Position | Gap |
|---|---|---|---|
| 5(1)(a) | Lawfulness, fairness, transparency | No notice to any audience; processing is invisible to employees, colleagues and external correspondents | G-20 |
| 5(1)(b) | Purpose limitation | Telemetry collected for cost attribution supports behavioural analysis; context assembled for one question serves another for 24 hours | G-14, G-18 |
| 5(1)(c) | Data minimisation | Per-user telemetry for a team dashboard; whole document bodies where excerpts would serve | G-14, G-18 |
| 5(1)(d) | Accuracy | Statements about identifiable people are composed and published with no grounding and no rectification route | G-19 |
| 5(1)(e) | Storage limitation | 24-hour conversation TTL is exemplary; 13-month telemetry exceeds its purpose; logs have no stated position | G-14, G-15 |
| 5(2) | Accountability | Tool arguments are not recorded, so processing cannot be demonstrated or reconstructed | G-09 |
| 6 | Lawful basis | None identified for third-party correspondence in the Support mailbox | G-13 |
| 9 | Special categories | Health and similar inference from calendar and mail with no identified condition | G-17 |
| 12–14 | Information to data subjects | No notice to employees; no Article 14 route to external correspondents | G-20 |
| 15–17 | Access, rectification, erasure | No mechanism spanning the four stores; unavailable to third parties entirely | G-15, G-19 |
| 22 | Automated decision-making | **Assessed and not triggered** — Phase 1 is read-and-act with a human present; no decision with legal or similarly significant effect. Re-assess if Phase 3 unattended operation proceeds | — |
| 25 | Data protection by design and default | Defaults grant rather than restrict at every level: connector scope, workspace onboarding, telemetry collection, action confirmation | G-02, G-05, G-14 |
| 28 | Processor agreements | Model provider agreement held by another team for another purpose; scope unverified | G-16 |
| 32 | Technical and organisational measures | Shared console credential, unprotected conversation store, no audit of arguments, tenant-wide connector reach | G-01, G-07, G-08, G-09 |
| 33 | Breach notification | The 72-hour clock cannot start from an event nobody recorded, and scope cannot be described without arguments | G-09, G-12 |
| 35 | DPIA | High-risk processing — large-scale, systematic, involving third-party data and autonomous action — with no assessment | G-13 |
| 44–49 | International transfers | EU endpoint stated; the sub-processor chain behind it is unverified | G-16 |

### 4.2 NIS2 — applicability unassessed

No supplied source states the organisation's sector, so this cannot be determined here. **This is itself the finding (G-21).** If the organisation is an essential or important entity, the assistant is in scope for Article 21 risk-management measures, and the position on four of them is poor: MFA is not enforced on the console (G-08), supply-chain security does not reach the MCP surface (G-11), incident handling does not exist (G-12), and the Article 23 24-hour early-warning obligation cannot be met from unrecorded events (G-09). The determination is a question for Legal and should not wait for the group workstream.

### 4.3 EU Cyber Resilience Act — does not apply

CRA applies to products with digital elements placed on the EU market. The assistant is an internal hosted service: no downloadable client, no embedded software, no hardware, and no placement on the market — it is not sold, distributed or made available to any third party. It is therefore outside CRA scope on the current design. **Re-assess if PROD-1131's Phase 3 customer-facing surfaces proceed**, which is recorded at initiative level as not yet scoped. Recorded as ⚪ Accepted with a review trigger rather than closed.

### 4.4 UK PSTI Act 2022 — does not apply

PSTI covers consumer connectable products: internet-connectable or network-connectable physical devices made available to consumers in the UK. There is no device and no consumer sale. No further assessment required.

### 4.5 PCI-DSS v4.0 — conditional, and the condition is untested

No cardholder data environment is described and no connector reaches a payment system, so PCI-DSS does not apply on the current evidence. The condition worth testing is Support's shared mailbox: customers send card details in correspondence despite being told not to, and the assistant reads that mailbox in full. If cardholder data has arrived there, the mailbox and every store downstream of it — model provider context, conversation state, telemetry, platform logs — enters scope. **Fold this question into the DPIA (G-13)** rather than raising it separately; it is answered by the same mailbox review.

### 4.6 HIPAA — does not apply

No protected health information is described, no US healthcare context is named, and the organisation is not identified as a covered entity or business associate. Note that G-17 concerns health *inference* about employees under GDPR Article 9, which is a different obligation under a different regime and does not bring HIPAA into scope.

### 4.7 SOC 2 — applies indirectly

The assistant is not a customer-facing service and is not itself in a SOC 2 boundary. It reads systems that hold customer data and is operated by a team whose controls may be in one, so it inherits the criteria as an internal control question. Open against CC6.1 and CC6.3 (G-01, G-02, G-08), CC7.1 (G-09, G-10), CC8.1 (G-11, G-22), C1 (G-07, G-14, G-16) and A1 (G-10, G-12).

### 4.8 EU AI Act — unassessed and blocked

PR-03 records that the group AI governance workstream has not begun and that initiatives are proceeding on the basis that governance will be retrofitted, accepted at the July steering group. On the current design the assistant is most likely limited-risk with Article 50 transparency obligations — users must know they are interacting with an AI system, and machine-generated content should be identifiable, which is G-20. If the assistant is ever used for anything bearing on employment decisions, Annex III would need testing, and the 13-month per-user telemetry dataset (G-14) is the most plausible route to that. **G-21.**

---

## 5. Refined requirements

A strict superset. Every requirement in §2 is retained; the following are added, each cross-referenced to its origin so provenance is traceable.

### Security

- **SEC-16** `[NEW — from G-01/SAC-04]` The orchestrator must carry the requesting user's identity into every tool dispatch and record it with the dispatch.
- **SEC-17** `[NEW — from G-04/SAC-02]` Every write tool must have its argument *values* validated against an allowlist at the dispatcher, before the call leaves the connector runtime and independently of the MCP server.
- **SEC-18** `[NEW — from G-05/SAC-02]` Irreversible or externally-visible actions, and any action whose arguments derive from retrieved rather than user-authored content, must require out-of-band confirmation.
- **SEC-19** `[NEW — from G-06/SAC-01]` Content entering model context must carry a provenance tag identifying its source and trust class, and provenance must gate which tools may subsequently be invoked.
- **SEC-20** `[NEW — from G-03/SAC-01]` Assistant output must pass a deterministic filter at every rendering and posting sink, stripping image and link tags and enforced by Content Security Policy in the browser surface.
- **SEC-21** `[NEW — from G-07/SAC-05]` Each connector must run in its own namespace with its own service account, its own secret scope and a default-deny egress policy.
- **SEC-22** `[NEW — from G-07/SAC-05]` Any workload processing externally-authored content must run on a sandboxed runtime or a dedicated tainted node pool.
- **SEC-23** `[NEW — from G-09/SAC-10]` Tool dispatches must be recorded — acting user, tool, full arguments, target, decision, outcome, correlation ID — in a store the workload identity may append to but not modify or delete.
- **SEC-24** `[NEW — from G-09/SAC-10]` The in-conversation action display must be rendered from the dispatch record, not from model output.
- **SEC-25** `[NEW — from G-10/SAC-09]` Tool-call iterations per turn, tokens per conversation, tokens per user per day and tokens per workspace per month must have hard caps enforced at the orchestrator, refusing at the ceiling.
- **SEC-26** `[NEW — from G-11/SAC-06]` MCP server images must be digest-pinned and signature-verified at admission, and tool descriptions and schemas must be hashed at approval, verified at start-up and diff-reviewed on every version bump.
- **SEC-27** `[NEW — from G-12/SAC-05]` A kill switch with a named owner, granular to workspace, connector and tool class, must exist with a stated maximum propagation time and be drilled quarterly.
- **SEC-28** `[NEW — from G-11/AI12]` An AI bill of materials covering models and versions, MCP servers and digests, tool description hashes, prompt template versions and connector scopes must be maintained and emitted with request telemetry.
- **SEC-29** `[NEW — from G-07/C2]` Assistant namespaces must be labelled Restricted under Pod Security Admission, with an admission controller enforcing digest pinning, signature verification, resource limits and disabled service-account token automounting.
- **SEC-30** `[NEW — from G-02/E4]` A workspace must hold an explicit connector scope record with an approving review reference; an absent or empty record must mean refuse, not unrestricted.

### Privacy

- **PRV-13** `[NEW — from G-13/PAC-01]` A DPIA covering the assistant must be completed before Support's use of the shared mailbox continues past an agreed date.
- **PRV-14** `[NEW — from G-14/PAC-02]` Usage telemetry must drop the user dimension after the current billing period and aggregate to team, with cell suppression below a threshold.
- **PRV-15** `[NEW — from G-15/PAC-03]` A single erasure operation must locate and remove a named individual's data across conversation state, telemetry, platform logs and the model provider's contractual position, produce evidence, and trigger automatically on offboarding.
- **PRV-16** `[NEW — from G-17/PAC-05]` Calendar entry bodies and free-text subjects must be excluded from context by default; only free/busy is passed where availability is the question.
- **PRV-17** `[NEW — from G-18/PAC-06]` Context must be bounded by a token budget and a retrieval expiry shorter than the session, and a turn touching a different data class must open a new session.
- **PRV-18** `[NEW — from G-19/PAC-07]` Any assertion naming an individual must carry a citation to a source actually retrieved in that turn, checked against the dispatch record, and a rectification route must suppress corrected assertions across sessions.
- **PRV-19** `[NEW — from G-20/PAC-08]` Both surfaces must display a persistent marker, rendered by the surface rather than by the model, that output is machine-generated; posted and sent content must carry an equivalent marker for the recipient.
- **PRV-20** `[NEW — from G-14/CL5]` Access to the telemetry partition must be restricted to named roles and logged.

### Compliance

- **COMP-10** `[NEW — from G-16/PAC-04]` The model provider agreement must be confirmed in writing to cover this purpose, these data categories including third-party correspondence, these data subjects, the prompt retention position and the sub-processor chain.
- **COMP-11** `[NEW — from G-21/O3]` NIS2 applicability and EU AI Act applicability must be determined by Legal, independently of the group AI governance workstream's start date.
- **COMP-12** `[NEW — from G-21/O3]` An interim AI governance gate, jointly owned by Platform Security and Legal, must apply to the assistant until the group workstream produces one.
- **COMP-13** `[NEW — from G-12/O5]` An incident response playbook must cover four AI-specific incident types with named owners, containment steps, evidence collection and notification assessment.
- **COMP-14** `[NEW — from G-22/O1]` Design pages must state each control claim with its delivering ticket and that ticket's state, and may not be marked Approved with a claim whose ticket is not Done.
- **COMP-15** `[NEW — from G-22/O2]` Deviations from the standing platform controls page must be recorded in an exceptions register on that page, with a compensating control, an owner and an expiry date.

### Performance

- **PERF-05** `[NEW — from G-10/PERF-03]` Provider rate limiting must be handled with a bounded retry budget and a circuit breaker, not unbounded retry.
- **PERF-06** `[NEW — from G-09/PERF-04]` A partial answer produced after a failed tool call must be marked as partial, from the dispatch outcome rather than from model output.

---

## 6. Requirements coverage check

| Category | Original | New | Total | Traced in the SRTM |
|---|---|---|---|---|
| FR | 8 | 0 | 8 | 8 |
| SEC | 15 | 15 | 30 | 30 |
| PRV | 12 | 8 | 20 | 20 |
| PERF | 4 | 2 | 6 | 6 |
| COMP | 9 | 6 | 15 | 15 |
| **Total** | **48** | **31** | **79** | **79** |

Nothing was dropped. Every original requirement, including the ones the organisation set itself on approved pages and has not met, is carried forward with its status.

---

## 7. Recommended sequence

Ordered by safety bought per unit of delivery time, not by severity alone. PR-01 records the board date as immovable and accepted, so the sequence assumes that constraint rather than arguing with it.

### Before GA or the next pilot expansion — launch gates

1. **Escalate the Identity Platform dependency (G-01).** PLAT-2820-1 has been blocked and unscheduled since 2026-04-18 and sits behind three Critical findings. This is a portfolio conversation with the COO office, not a backlog refinement. *This is the single most important item in this document.*
2. **Correct the architecture page (G-22).** An hour of writing. It costs nothing, and every day it stands it propagates a Critical gap to teams that will build on it.
3. **Ship the output filter (G-03).** CSP with `img-src 'self'` on the console, markdown subset stripping image and link tags in both surfaces and on outbound content. A day of work; closes the only attack path in the model that needs no credential at any stage.
4. **Interim scope narrowing (G-02).** Application access policy scoping the O365 registration to the pilot group, GitHub App installation restricted to a named repository list excluding public repositories, and PLAT-2814-6 scheduled. Days, not weeks, and it moves the blast radius of every injection from tenant-wide to a reviewed list.
5. **Mailbox allowlist at the connector (G-13, interim).** An afternoon. Moves G-13 from Critical to Medium while the DPIA runs, and buys the time the DPIA needs.
6. **Argument allowlists and risk-based confirmation (G-04, G-05).** Value validation at the dispatcher, confirmation on external mail, non-member posts, all commits, and any action whose arguments derive from retrieved content.
7. **Dispatch audit record, then the action display (G-09).** In that order. The record is the prerequisite for the display, for incident response, for the Article 33 clock and for the detection in AI7.
8. **Connector isolation (G-07).** Namespace, service account and secret scope per connector; sandboxed runtime for the web-search connector. The only chain in the model where one compromise reaches every credential the assistant holds.
9. **SSO on the console (G-08).** PLAT-2831-3. The owner's own comment already sets this as the gate: "Needs SSO before anyone outside the pilot sees it."

### Fast hygiene — days, cheap, should not wait

10. Hard caps on tokens and loop iterations (G-10). Hours; removes the unbounded-cost class outright.
11. Remove document and mail bodies from the debug logging path (G-09). Do not gate the capability — remove it.
12. Restricted Pod Security Admission, resource limits, `automountServiceAccountToken: false` (G-07). Configuration, not development.
13. Start the AI-BOM with four MCP servers and the model version, and pin them (G-11).
14. Name a kill-switch owner and write four incident playbook entries (G-12). A page of writing; every containment step depends on it.
15. Drop the telemetry user dimension after the billing period (G-14). One scheduled job.
16. Add the machine-generated marker to both surfaces and to outbound content (G-20). A component, not a project.

### Near-term

17. DPIA covering the assistant, with the mailbox as its central question (G-13).
18. Deletion path across the four stores, triggered on offboarding, tested with a synthetic request (G-15).
19. Model provider agreement scope confirmation from Data Platform (G-16).
20. Calendar field allowlist and the special-category assessment (G-17).
21. Context budget, retrieval expiry and fresh sessions on data-class change (G-18) — this fixes the performance complaint in PERF-01 as well.
22. Citation enforcement and a rectification route (G-19).
23. Provenance-delimited context and provenance-gated dispatch (G-06), sequenced after G-04 and G-05 because those carry the guarantee while this narrows the funnel.
24. NIS2 and EU AI Act determinations, and the interim governance gate (G-21).
25. Backups, restore drills and rollback for configuration and scopes (G-12).

### Decisions to ratify — not fixes

26. **The model provider agreement (G-16, D-01).** A portfolio-level commercial trade made under a stated procurement constraint. Verify the scope; where it does not cover this processing, carry the residual explicitly in an ADR with the COO office as owner.
27. **The structural hazards (AI6, AI7).** Adversarial subspace and decision boundary transfer cannot be closed at the model layer. Ratify in writing that the security guarantees rest on the deterministic controls in items 3, 4, 6 and 7, and that the web-search sanitiser is not load-bearing — so that no future design page cites it as the reason untrusted content is safe.
28. **Proceeding without group AI governance (G-21, PR-03).** Accepted at the July steering group. Ratify the interim gate in COMP-12 as the standard this system is held to in the meantime, with a named owner and a review date.
29. **The 24-hour session TTL and the no-new-stores decision (D-05, PRV-02).** Both are good and both should be recorded as deliberate, so they survive the next round of feature pressure.

---

*This document reflects the Confluence pages and Jira tickets supplied in `input/` as at 2026-09-09; statuses tied to ticket numbers are point-in-time. No source code, infrastructure code, Helm charts or schemas were supplied, so gaps described as absent are absent from the documentation rather than confirmed absent from the implementation — see `00-context-sources-and-open-questions.md` §3. Nothing here is legal advice; the GDPR, NIS2, EU AI Act and PCI-DSS positions should be confirmed with counsel and with the Data Protection Officer.*

---

## Appendix A — Privacy by Design scorecard

| PbD principle | Posture |
|---|---|
| **Proactive not reactive** | 🔴 Weak. The team identified four real problems in the pilot and recorded them as rough edges and open questions rather than acting on them. Three months of Support pilot have run on an unanswered lawful-basis question. The instinct to write them down is genuinely good; the gap is that nothing converts a recorded unknown into a decision with a date. |
| **Privacy as the default** | 🔴 Weak. Defaults grant at every level: connector scope at the API maximum, workspace onboarding inheriting everything, telemetry collected with a user dimension nobody asked for, actions executing without confirmation. Restriction requires configuration in every case. |
| **Privacy embedded into design** | 🟡 Mixed, and better than it looks. D-05 — no new systems of record — is a structural privacy decision taken early and for the right reason, and the 24-hour conversation TTL is a real limit that most systems of this kind do not have. Against that, the derived stores those decisions did not cover are where the data now accumulates. |
| **Full functionality, positive-sum** | 🟡 Mixed. The design consistently treats security and privacy as costs to be traded against the 6-second target and the board date, most visibly in the removal of the confirmation step. That trade was made with users in the room, which is the right process reaching the wrong control — confirmation on risk rather than on frequency is positive-sum and was not considered. |
| **End-to-end security** | 🔴 Weak at both ends. **The connector boundary has no per-user authorisation at all**, and the rendering boundary has no output filter at all. Between them the inherited platform baseline is strong — egress control, segmentation, secret management, source-control integrity — which makes the two open ends more conspicuous rather than less. |
| **Visibility and transparency** | 🔴 Weak. No privacy notice for any audience. The one transparency control that exists, PLAT-2825's action display, is rendered from the model's own account of itself and is falsifiable by the same input that causes the harm. External correspondents whose mail is read are told nothing at all. |
| **Respect for user privacy** | 🟡 Mixed. Users can delete their own conversations, which is a real and deliberate feature. But they were enrolled without notice, are measured per-request for 13 months, cannot see or revoke what the assistant reaches on their behalf, and colleagues whose mail is surfaced in other people's answers have no standing in the design at all. |

The scorecard's shape is worth naming: this is not a team that ignored privacy. It is a team that made two good structural decisions early (D-05 and the TTL), then met a fixed date and a blocked dependency, and let the derived stores, the notices and the authorisation model fall behind. The remedies are mostly small and mostly unraised, which is a better position than it appears from the colour of the rows.
