# Internal AI Assistant (PLAT-2810) — Gap Analysis

**Version:** 1.0 (first pass against the supplied epic and trust-boundary sketch) · **Date:** 2026-09-09
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this gap analysis; produced with AI assistance.
**Model:** Claude Opus 5
**Frameworks:** STRIDE/STRIPED · LINDDUN · OWASP Top 10 (2021) · OWASP LLM and Agentic Top 10 · Privacy by Design · GDPR · EU AI Act · NIS2 · CRA · PSTI
**Regulatory scope:** UK and EU GDPR (applies); EU AI Act (conditional on EU deployment); NIS2 (conditional on entity classification); CRA and PSTI (assessed, out of scope); SOC 2 and ISO 27001 (internal framework, conditional)
**Companion documents:** `00-context-sources-and-open-questions.md` · `01-security-review.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md`
**Method:** Requirements classified from the acceptance criteria of PLAT-2810 and its four children, compared against what the threat model found, with each divergence recorded as a numbered gap.

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted. Severities: Critical / High / Medium / Low / Info.

---

## 0. Headline

**What this team got right, named specifically.** Three things, and they are not throwaway credit.

**PLAT-2825 exists.** A great many agentic assistants ship with no action visibility at all, discover that nobody can tell what the thing did, and retrofit it badly. This team wrote "users see what it did" into the epic as an acceptance criterion before any security review asked, and then wrote a story to deliver it. It is the right instinct and it is the surface that the provenance work in this analysis extends rather than replaces.

**PLAT-2814 identifies untrusted content as a category and commits to handling it.** The boundary is drawn in the wrong place — that is G-01 and it is the most serious finding in the pack — but the team was reasoning about the right problem. A design that had never considered content trust at all would be in a worse position, because it would have no concept to correct.

**The 6-second target is quantified.** Latency budgets are usually aspirational, and an aspirational one makes every security trade-off unarguable. A number makes it a design conversation: the action gate in this analysis costs a human decision on a small subset of actions, and because the budget is written down, that cost can be measured against it rather than argued about.

**What remains clusters into five themes.**

1. **The trust boundary is at the network, not at the authorship of the content.** PLAT-2814's acceptance criterion treats four connectors as trusted because they are behind authentication. Authentication governs who may read a mailbox; it says nothing about who wrote the message in it. Email bodies, public GitHub issues, Slack guest messages and externally shared documents all carry attacker-authored text into the model's context, and the design's own diagram has no node for the person who writes it. **G-01.**
2. **The one control that holds when the model does not has been deliberately removed.** PLAT-2817 removes confirmation from every action on pilot feedback that a dialog on every action is slower than doing the work by hand. That observation is correct and this analysis keeps it; the conclusion drawn from it applies equally to reading a calendar entry and mailing four hundred people. **G-02.** Combined with G-01 and the egress channel in G-05, this is the lethal trifecta, and it is the reason the review's headline is what it is.
3. **Nothing in the design decides who may see what.** No authorisation model, no per-user credential, no statement of whose permissions apply to a retrieval. This is one unanswered question — Q1 in the context document — and its answer re-rates six findings. **G-03, G-04.**
4. **Nothing produces a record a defender could use.** PLAT-2825's user-facing view is not an audit trail: it is scoped to one actor and stored where the acting component can amend it. No detection, no alerting, no telemetry. Every attack path in the threat model would execute unobserved. **G-08.**
5. **The privacy work has not started.** No lawful basis, no record of processing, no retention, no deletion, no executable subject rights, no DPIA, and an unnamed processor receiving corporate personal data on every turn. **G-11 to G-17.** This is the cluster with the longest external lead time, which is why it should start today rather than at the gate.

**Residual design risks worth a decision rather than a fix.** Three, and each belongs in an architecture decision record so it is carried knowingly: per-workspace model tiering as a cost lever (**G-23**, acceptable with a floor once the deterministic controls exist); the commit capability itself (**G-07**, acceptable behind a pull request, not acceptable direct); and the breadth of the connector set for any given workspace (**G-21**, a per-function decision rather than a global default).

**Calibration.** Nothing here is a reason not to build this. Several are reasons not to open it beyond Platform and Support yet. The pilot population is two technical teams; the general population includes the mailboxes where the special-category data, the payment instructions and the customer personal data live, and the change in population is the change in risk.

---

## 1. Assumptions & context

| Question | Answer from the inputs |
|---|---|
| What is being built | An agentic LLM assistant on Slack and a web console, reading from and acting on Office 365 documents and calendar, corporate email, Slack, GitHub and web search, driven by a reasoning loop over MCP tool calls, with per-workspace model tiering for cost |
| Actors | Pilot users in Platform and Support, then all staff; workspace administrators; team cost owners; and third-party data subjects in mailboxes, calendars and documents who have no relationship with the system |
| Data | Corporate content of every classification, employee personal data, third-party personal data, and special-category data reachable through calendar and mail. No schema was supplied, so classification is derived from what the connectors necessarily carry |
| Deployment | Unstated. No cloud provider, region, account structure, cluster or network design was supplied |
| Regulatory | UK and EU GDPR apply. EU AI Act Article 50 transparency applies on EU deployment. NIS2 conditional. CRA and PSTI assessed and out of scope |
| Market or expansion triggers | Packaging any part of this for customers would bring CRA into scope and would make the AI bill of materials in AI22 a regulatory obligation rather than good practice |
| Downloadable or embedded software | None. Internal hosted service only, which is what keeps CRA and PSTI out of scope |

**Assumptions carried, flag any that are wrong.** (a) The model is a hosted third-party inference service, because PLAT-2822 meters tokens and offers tiers; (b) the five connectors are separate MCP server processes, per the diagram's labelling; (c) a persistent conversation and history store exists, because PLAT-2825 requires history review; (d) the assistant runs as a hosted service in the corporate estate rather than on each user's device; (e) no retrieval index or vector store has been decided on, and retrieval is live query. Assumptions (a) to (d) follow from the tickets. Assumption (e) is a guess, and it is why G-30 and finding AI13 are tagged "if present".

---

## 2. Requirements classification

Classified from the eighteen acceptance criteria across the five tickets. The shape of this section is itself a finding: the Security, Privacy and Compliance tables are empty of original requirements, because there are none.

### 2.1 Functional (FR)

| ID | Requirement | Source | Status |
|----|-------------|--------|--------|
| FR-01 | Answer plain-language questions using content from existing tools | PLAT-2810 | 🔵 Planned |
| FR-02 | Available in Slack | PLAT-2810 | 🔵 Planned |
| FR-03 | Available in a web console | PLAT-2810 | 🔵 Planned |
| FR-04 | Take actions, not only read | PLAT-2810 | 🔵 Planned |
| FR-05 | Connect to Office 365 documents and calendar | PLAT-2814 | 🔵 Planned |
| FR-06 | Connect to corporate email | PLAT-2814 | 🔵 Planned |
| FR-07 | Connect to Slack | PLAT-2814 | 🔵 Planned |
| FR-08 | Connect to GitHub issues, pull requests and code | PLAT-2814 | 🔵 Planned |
| FR-09 | Connect to web search | PLAT-2814 | 🔵 Planned |
| FR-10 | Send email on the user's behalf | PLAT-2817 | 🔵 Planned |
| FR-11 | Post to Slack on the user's behalf | PLAT-2817 | 🔵 Planned |
| FR-12 | Comment on and update GitHub issues | PLAT-2817 | 🔵 Planned |
| FR-13 | Commit changes where the user asks | PLAT-2817 | 🔵 Planned |
| FR-14 | Track token usage per team | PLAT-2822 | 🔵 Planned |
| FR-15 | Teams can see their own consumption | PLAT-2822 | 🔵 Planned |
| FR-16 | Route each task to the smallest acceptable model | PLAT-2822 | 🔵 Planned |
| FR-17 | Cheaper model tiers configurable per workspace | PLAT-2822 | 🔵 Planned |
| FR-18 | Show actions taken in the conversation | PLAT-2825 | 🔵 Planned |
| FR-19 | A user can review their own history | PLAT-2825 | 🔵 Planned |
| FR-20 | Pilot with Platform and Support, then open up | PLAT-2810 | 🟡 pilot under way, expansion criteria undefined (PLAT-2810) |

### 2.2 Performance (PERF)

| ID | Requirement | Source | Status | Gap? |
|----|-------------|--------|--------|------|
| PERF-01 | Response under 6 seconds for a typical question | PLAT-2810 | 🔵 Planned | **G-19** — no behaviour is defined for when the budget cannot be met |
| PERF-02 | Model usage cost should not scale linearly with adoption | PLAT-2822 | 🔵 Planned | **G-18** — the story measures cost and does not limit it |

### 2.3 Security (SEC)

| ID | Requirement | Source | Status | Gap? |
|----|-------------|--------|--------|------|
| — | **No security requirement appears in any of the five tickets.** Two acceptance criteria actively remove controls: PLAT-2814 disapplies untrusted-content handling to four connectors, and PLAT-2817 removes the confirmation step | PLAT-2814, PLAT-2817 | 🔴 Open | **G-27** — and every other gap in §3 follows from this one |

### 2.4 Privacy (PRV)

| ID | Requirement | Source | Status | Gap? |
|----|-------------|--------|--------|------|
| — | **No privacy requirement appears in any of the five tickets**, despite processing employee and third-party personal data through a third-party processor on every turn | — | 🔴 Open | **G-11**, **G-12**, **G-13**, **G-16** |

### 2.5 Compliance (COMP)

| ID | Requirement | Source | Status | Gap? |
|----|-------------|--------|--------|------|
| — | **No compliance requirement appears in any of the five tickets.** No DPIA trigger assessment, no record of processing, no processor agreement, no retention schedule | — | 🔴 Open | **G-13**, **G-14** |

---

## 3. Gap analysis

### 3.1 Consolidated gap list

| Gap | Title | Severity | Type | Findings |
|-----|-------|----------|------|----------|
| **G-01** | Trust boundary placed at the network rather than at the authorship of the content | **Critical** | Design decision | AI1, O1, AI18 |
| **G-02** | Confirmation removed from every action, including irreversible and outbound ones | **Critical** | Design decision | AI21, E5, AI7 |
| **G-03** | No authorisation decision on any retrieval or any tool call | **Critical** | Design decision | I2, E2, AI12 |
| **G-04** | No per-user, per-task credential model; identity model unstated | **Critical** | Design decision | AI8, E1, R3, S4 |
| **G-05** | No egress control and no cross-server data-flow policy | **Critical** | Design decision | I3, AI11 |
| **G-06** | No output filtering at any sink the model's output reaches | **Critical** | Design decision | AI6, AI25, AI26 |
| **G-07** | Commit capability bypasses the pull-request review gate and reaches CI | **Critical** | Design decision | T2, AI24 |
| **G-08** | No defender-readable, tamper-evident action record and no detection | **High** | Assurance | R1, R2, R4, O2 |
| **G-09** | No tool classification and no per-task scoping of the tool set | **High** | Design decision | AI7, E5, AI2 |
| **G-10** | MCP supply chain unmanaged: no inventory, pinning, signing or re-review | **High** | Design decision | AI3, AI4, AI16, AI22, AI10 |
| **G-11** | No lawful basis identified and no record of processing | **High** | Compliance | P1 |
| **G-12** | No retention period and no deletion path in any store the assistant creates | **High** | Compliance | P3, P4, RR3 |
| **G-13** | No DPIA for high-risk processing, with expansion planned | **High** | Compliance | P7 |
| **G-14** | Model provider unnamed; no processor agreement, region or retention terms | **High** | Compliance | I6 |
| **G-15** | Special-category data reachable and inferable with no Article 9 condition | **High** | Compliance | P5 |
| **G-16** | Third-party data subjects processed with no notice | **High** | Compliance | P2 |
| **G-17** | Per-team metering is a per-person behavioural record open to secondary use | **Medium** | Compliance | P6 |
| **G-18** | Cost and work are measured but not capped | **High** | Design decision | D1, D2, D3 |
| **G-19** | No degradation behaviour defined for the 6-second budget | **High** | Design decision | D4, D5, R5 |
| **G-20** | No single identity authority across the two entry points | **High** | Design decision | S2, S3, S5 |
| **G-21** | Insecure workspace defaults and no storage-layer partitioning | **High** | Hardening | E3, E4 |
| **G-22** | No change control on security-relevant configuration | **High** | Assurance | T1 |
| **G-23** | Structural hazards unaddressed; model robustness is currently load-bearing | **High\*** | Residual | AI18, AI19, AI20 |
| **G-24** | No provenance surfaced to the person or to the recipient | **High** | Design decision | AI23, AI14, AI17, S1 |
| **G-25** | No kill switch, no circuit breaker and no compensating actions | **High** | Design decision | RR1, RR2, AI9 |
| **G-26** | Pilot-to-general rollout has no security admission gate | **Medium** | Roadmap | O3 |
| **G-27** | No security, privacy or compliance acceptance criteria in the epic | **High** | Doc drift | O4 |
| **G-28** | Document and attachment ingestion has no validation | **High** | Hardening | T4 |
| **G-29** | Transport security, secret handling and error handling all unspecified | **Medium** | Hardening | T5, I4, I5 |
| **G-30** | Conversation store integrity, poisoning and disclosure unaddressed | **Medium** | Latent | T3, AI5, AI13, AI15, P8 |

\* **G-23 conditional severity.** High while the deterministic controls in G-01 to G-06 do not exist, because the model's own robustness is then the only thing between an injected instruction and a write tool. Medium once they do, at which point the model is a backstop and per-workspace tiering becomes an ordinary cost decision. This is the sequencing argument, and it is why G-23 is not a fix on its own.

### 3.2 Security gaps in detail

The seven Critical gaps are one story told seven ways, and the story is the lethal trifecta. **G-01** supplies the untrusted content: four connectors carry attacker-authored text that the design classifies as trusted. **G-03** and **G-04** supply the private data: nothing restricts what the assistant can reach, so a compromised task reaches whatever the connector credentials reach. **G-05** and **G-06** supply the outward channel: an egress destination the model chooses, a renderer that fetches remote content, and no filter at any sink. **G-02** removes the human from the loop. **G-07** extends the same path into the build system.

The consequence is that the seven cannot be fixed independently, and the ordering matters. **G-01 without G-02 produces telemetry rather than protection** — you learn that a task was tainted, and the send happens anyway. **G-02 without G-01 produces a confirmation dialog on every action**, which reproduces exactly the usability failure the pilot group correctly objected to and which will be switched off within a month. They are one change and must be sequenced as one, which is why they are a single launch gate in §5.

### 3.3 Privacy gaps in detail

**G-11 to G-17 have not started rather than been done badly**, and that distinction matters for sequencing: none of them is a build problem and several have external lead time measured in weeks. The processor agreement in **G-14** and the DPIA in **G-13** should begin now, in parallel with engineering, because neither is on the critical path of any code change and both are on the critical path of the rollout.

The one that is a build problem is **G-12**. Per-subject indexing at write time is cheap now and expensive later: finding one individual's data in free-form conversation text that was never indexed for it is a materially harder engineering problem than adding the index before the first record is written. Every week the pilot runs without it adds records that a future erasure request cannot cleanly reach.

### 3.4 Performance gaps

**G-19** is where security and performance actually collide, and the collision is productive rather than adversarial. A 6-second budget over a fan-out to six external services will sometimes fail to be met, and the design does not say what happens then. The honest answer — return a visibly partial answer naming the sources that did not respond — is both the security fix and the better product behaviour, because an answer that silently omits the source the user asked about is worse than one that says so.

**G-18** is the other collision, and it resolves the same way. PLAT-2822 already computes every number a cap needs; turning tracking into limiting is a comparison and a refusal, not a new subsystem.

---

## 4. Regulatory compliance assessment

| Framework | Applicability | Position | Gaps | COMP requirements generated |
|---|---|---|---|---|
| **UK and EU GDPR** | **Applies.** Employee and third-party personal data; special-category data reachable; third-country transfer on every turn | The framework with the most exposure and the least coverage. No basis, no record of processing, no DPIA, no retention, no executable rights, no processor agreement | G-11 to G-17, G-12 | COMP-01, COMP-02, COMP-03, COMP-04, COMP-05, COMP-08 |
| **EU AI Act** | **Applies conditionally** on deployment to EU-based staff. Not prohibited; not high-risk on the facts given, since it makes no employment decision. Article 50 transparency applies | Staff must be told they are interacting with an AI system. If the assistant is later used to inform performance or capacity decisions about workers — which the metering in G-17 makes tempting — it must be reassessed as high-risk **before** that use begins, not after | G-17, G-24 | COMP-06 |
| **NIS2** | **Applies conditionally** on whether the organisation is an essential or important entity, which the input does not establish | Where it applies: risk management, incident detection and 24-hour reporting, supply-chain security for the MCP servers and the model provider, encryption, and access control all have open gaps | G-08, G-10, G-14, G-29, G-25 | COMP-07 |
| **CRA** | **Assessed — out of scope.** Internal service, no product with digital elements placed on the EU market, no downloadable or embedded component | Reassess if any part is packaged, sold or offered to customers. The AI bill of materials in G-10 is the head start on the SBOM obligation, and the coordinated vulnerability disclosure process would become mandatory | — | — |
| **PSTI** | **Assessed — out of scope.** No consumer connectable product and no hardware | Nothing further unless a device is introduced | — | — |
| **PCI-DSS** | **Assessed — out of scope on the facts given, with a live caveat** | Mailboxes receive card numbers from customers despite policy, and the assistant reads mailbox content and copies it into the conversation store. Confirm at pilot expansion whether any connected mailbox sits in a cardholder data environment, because that would pull the conversation store into scope | G-12 | — |
| **HIPAA** | **Assessed — out of scope.** No protected health information and no covered entity or business associate relationship established | Occupational health correspondence in mailboxes is Article 9 employee health data under GDPR rather than HIPAA, and is carried at G-15 | — | — |
| **SOC 2 and ISO 27001** | **Applies** as the internal control framework, assuming one is held | Logical access, encryption, monitoring, change management and availability all have open gaps. An autonomous system with write access to production repositories will be in scope at the next audit | G-03, G-04, G-08, G-22, G-29 | COMP-07 |

---

## 5. Refined requirements

A strict superset: every original requirement above is retained, and the following are added. Provenance is marked so each can be traced to the analysis that produced it.

### 5.1 Security (SEC)

- **SEC-01** `[NEW — from G-01/AI1]` Every retrieved chunk carries an author-provenance label assigned by the connector at ingest, from facts the connector holds.
- **SEC-02** `[NEW — from G-01/AI1]` A connector return that omits the provenance label fails schema validation rather than defaulting to trusted.
- **SEC-03** `[NEW — from G-01/AI1]` Externally-authorable content is placed in a structurally delimited untrusted region of the context, separate from the system framing and the user's own prompt.
- **SEC-04** `[NEW — from G-02/AI21]` No tool of class external-write or code-integrity-write executes on a task carrying externally-authorable content without out-of-band human confirmation.
- **SEC-05** `[NEW — from G-02/AI21]` Confirmation renders the arguments the orchestrator will execute, not the model's description of them.
- **SEC-06** `[NEW — from G-03/I2]` Retrieval authorisation is enforced by the system of record against the requesting user; the assistant does not filter after retrieval.
- **SEC-07** `[NEW — from G-04/AI8]` Tool calls execute under a short-lived credential minted per user, per task, per tool; no connector is configured with application-level scopes.
- **SEC-08** `[NEW — from G-04/E2]` The assistant's capability is intersected with the requesting user's own entitlement at dispatch, evaluated against the source system, failing closed.
- **SEC-09** `[NEW — from G-05/I3]` Outbound destinations for the assistant and every connector are allow-listed, deny by default, with denials alerted.
- **SEC-10** `[NEW — from G-05/AI11]` A default-deny data-flow policy governs which MCP server's output may become which server's input.
- **SEC-11** `[NEW — from G-06/AI25]` Each output sink applies a filter in its own grammar: markdown subset and content-security policy at the renderers, schema validation at tool arguments, a scrubber at logs.
- **SEC-12** `[NEW — from G-07/T2]` The assistant cannot push to a protected branch; changes reach a feature branch and a pull request a human approves, and assistant-authored commits do not reach credential-holding pipelines before that approval.
- **SEC-13** `[NEW — from G-09/E5]` Every tool carries a class by reversibility and blast radius; an unclassified tool is not dispatchable.
- **SEC-14** `[NEW — from G-09/AI7]` The tool set presented to the model is the minimum derived from the task, and a call to a tool outside it is refused.
- **SEC-15** `[NEW — from G-10/AI3]` An AI bill of materials records every model, tier, prompt template, MCP server and tool-description hash, each pinned and versioned.
- **SEC-16** `[NEW — from G-10/AI4]` Tool definitions are hashed at approval and verified at every connection, failing closed and raising a review on mismatch; tool names are namespaced per server.
- **SEC-17** `[NEW — from G-18/D1]` Enforced ceilings apply to tokens per user per window, spend per workspace per day, loop iterations per task and tool calls per turn; the task stops at the cap.
- **SEC-18** `[NEW — from G-20/S2]` Both entry points resolve to one corporate identity through the identity provider, with Slack identity bound by an explicit account-linking step; unbound principals are refused.
- **SEC-19** `[NEW — from G-21/E3]` A new workspace defaults to read-only connectors with every write tool disabled; each write capability requires explicit, recorded enablement.
- **SEC-20** `[NEW — from ARCH-1]` Every retrieved chunk's provenance label is persisted with the chunk.
- **SEC-21** `[NEW — from ARCH-1]` The orchestrator maintains a per-task taint flag, set when any externally-authorable chunk enters the context, and it is an input to the action gate.
- **SEC-22** `[NEW — from ARCH-2]` Tool classification is a property of the tool registry, not of the prompt.
- **SEC-23** `[NEW — from ARCH-2]` Gated confirmations are obtained out of band from the model's own output.
- **SEC-24** `[NEW — from ARCH-3]` The assistant holds no standing access; credentials are minted per user per task per tool.
- **SEC-25** `[NEW — from ARCH-3]` Retrieval authorisation is evaluated by the system of record, not applied as a post-retrieval filter.
- **SEC-26** `[NEW — from ARCH-4]` An append-only action log records actor, workspace, tool, arguments, context provenance, model and tier, tool-description version, decision and outcome, in storage the assistant's identity cannot modify or delete.
- **SEC-27** `[NEW — from G-23/AI20]` A minimum model tier applies to any task in which a write tool is reachable.
- **SEC-28** `[NEW — from G-22/T1]` Model tier, connector enablement, tool classification and the egress allow-list are version-controlled configuration changed through review, with every change written to the action log.
- **SEC-29** `[NEW — from G-25/RR2]` A kill switch operates at three scopes — global, per connector and per tool class — checked by the dispatcher before every call so it takes effect within one step.
- **SEC-30** `[NEW — from G-25/RR1]` Each write tool has a defined compensating action, and the action log yields the exact set of affected recipients or artefacts.
- **SEC-31** `[NEW — from G-28/T4]` Document and attachment parsing is restricted to an allow-listed set of formats under size bounds, and runs in a process holding no credentials and no network egress.
- **SEC-32** `[NEW — from G-29/T5]` Every hop uses authenticated TLS; plaintext transports are refused in configuration rather than by default.
- **SEC-33** `[NEW — from G-29/I5]` Connector faults are mapped to internal codes before entering the context, with not-found and not-permitted normalised into one response.
- **SEC-34** `[NEW — from G-19/D4]` Per-connector deadlines and bounded retries apply within the task budget, and an answer produced from a partial source set is rendered as visibly partial, naming the sources that failed.
- **SEC-35** `[NEW — from G-30/AI5]` Persisted conversation content carries an origin discriminator, is partitioned per user, and is treated as untrusted when read back into a context.
- **SEC-36** `[NEW — from G-08/O2]` Action-log events are shipped to the security monitoring platform, with detections defined for write tools dispatched on tainted tasks, first-seen external recipients, tool-description hash changes and abnormal iteration counts.
- **SEC-37** `[NEW — from G-24/S1]` Outward actions carry an agent-origin marker applied at the tool boundary, on mail headers and body, Slack posts and issue comments.
- **SEC-38** `[NEW — from G-26/O3]` General availability is gated on written entry criteria that include the launch gates in §6, a signed DPIA, and a named owner per workspace who has approved that workspace's connector set.

### 5.2 Privacy (PRV)

- **PRV-01** `[NEW — from G-11/P1]` A lawful basis is identified and documented for each category of personal data, with a balancing test where legitimate interests is relied on.
- **PRV-02** `[NEW — from G-11/P1]` A per-user exclusion path exists so an objection is executable, checked by the orchestrator before any connector call for that principal.
- **PRV-03** `[NEW — from G-16/P2]` The Article 14 duty for personal data obtained other than from the data subject is discharged, or the exemption relied on is recorded as a decision.
- **PRV-04** `[NEW — from G-12/P3]` Every store the assistant creates has an enforced retention period with automated deletion that reaches replicas and backups.
- **PRV-05** `[NEW — from G-12/P4]` Personal data is indexed per subject at write time, so access, rectification and erasure resolve across conversations, chunks, generated content and the action log.
- **PRV-06** `[NEW — from G-15/P5]` Sources that predictably carry Article 9 data are excluded at the connector, or brought under an identified condition with a narrower purpose and shorter retention.
- **PRV-07** `[NEW — from G-17/P6]` Token metering is aggregated to team level at write time; per-person consumption is not retained beyond the aggregation window and is not available for performance management.
- **PRV-08** `[NEW — from G-24/AI17]` Generated content is marked as generated wherever it is transferred outward or persisted, and unsourced claims about identifiable people require confirmation before an outward send.
- **PRV-09** `[NEW — from G-30/P8]` The empty-result and not-entitled paths are normalised into one response before the model sees either.
- **PRV-10** `[NEW — from ARCH-4]` The conversation store is enumerable and deletable per data subject, including retrieved chunks and generated content.
- **PRV-11** `[NEW — from ARCH-4]` Stored records carry algorithm and key-version metadata so re-encryption is reconfiguration rather than re-architecture.

### 5.3 Compliance (COMP)

- **COMP-01** `[NEW — from G-11]` A record of processing covering the assistant is completed and maintained.
- **COMP-02** `[NEW — from G-14]` The model provider is named, a processor agreement is executed, the region is pinned, and the retention and training-use position is recorded.
- **COMP-03** `[NEW — from G-14]` The model provider is added to the sub-processor register and the privacy notice.
- **COMP-04** `[NEW — from G-16]` The internal privacy notice describes assistant processing, and an external-facing statement covers correspondence processing.
- **COMP-05** `[NEW — from G-12]` A retention schedule for assistant-created stores is published and enforced.
- **COMP-06** `[NEW — from EU AI Act Art. 50]` Users are told they are interacting with an AI system at the point of interaction, and the classification is reassessed before any use that informs decisions about workers.
- **COMP-07** `[NEW — from NIS2 and SOC 2]` Incident detection and reporting for assistant-specific incident types is defined, including prompt injection confirmed, tool misuse detected, and MCP server compromise.
- **COMP-08** `[NEW — from ARCH and G-13]` A DPIA is completed and signed before the pilot expands beyond Platform and Support.

---

## 6. Recommended sequence

**Before the pilot expands beyond Platform and Support — launch gates**

1. **G-01 and G-02 together, as one change.** Provenance labelling at ingest, a per-task taint flag, tool classification, and a deterministic out-of-band gate on external-write and code-integrity-write. *This is the single most important item in the pack.* Sequenced together because either alone fails: labelling without a gate is telemetry, and a gate without labelling reproduces the usability failure the pilot correctly objected to. (SEC-01 to SEC-05, SEC-13, SEC-20 to SEC-23)
2. **G-03 and G-04.** Answer question Q1 first — it is one configuration fact — then enforce authorisation at the data layer under per-user, per-task credentials. Until this is answered, six findings are rated on an unknown. (SEC-06, SEC-07, SEC-08, SEC-24, SEC-25)
3. **G-07.** Branch protection, pull request, and assistant commits excluded from credential-holding pipelines. (SEC-12)
4. **G-05.** Egress allow-list and cross-server data-flow policy. Needed even after the send tool is gated, because a search query is also a channel. (SEC-09, SEC-10)
5. **G-08.** Append-only action log shipped to the monitoring platform with the first detection rule live. Without it none of the attack paths is observable. (SEC-26, SEC-36)
6. **G-13, and start G-14 today.** The DPIA is a release gate; the processor agreement has contract lead time and is not on any code path, so it should start in parallel now. (COMP-02, COMP-08)

**Fast hygiene — days, cheap, do not wait for the above**

7. **G-21** — read-only workspace defaults. A configuration change. (SEC-19)
8. **G-18** — hard caps. PLAT-2822 already computes the numbers; this is a comparison and a refusal. (SEC-17)
9. **G-06 renderers** — content-security policy on the console, Block Kit rather than markdown pass-through in Slack, unfurling disabled. (SEC-11)
10. **G-24 marking** — agent-origin marker at the tool boundary. (SEC-37)
11. **G-10 pinning** — pin MCP versions and hash tool definitions, failing closed. (SEC-15, SEC-16)
12. **G-25 kill switch** — three dispatcher-checked flags. (SEC-29)

**Near-term**

13. **G-12** — per-subject indexing and retention. Cheap now, materially harder after the store has grown. (PRV-04, PRV-05, PRV-10, COMP-05)
14. **G-15, G-16, G-17** — Article 9 source exclusion, third-party notice, metering aggregation. (PRV-03, PRV-06, PRV-07)
15. **G-19, G-28, G-29, G-30** — degradation behaviour, ingestion validation, transport and secret handling, conversation-store integrity. (SEC-31 to SEC-35, PRV-09)
16. **G-22, G-26, G-27** — configuration change control, rollout entry criteria, and security acceptance criteria written into the epic so the next story does not repeat this. (SEC-28, SEC-38)

**Decisions to ratify, not fixes — record each in an architecture decision record**

17. **G-23** — per-workspace model tiering as a cost lever, with a minimum tier where write tools are reachable. Acceptable once items 1 to 5 exist; not acceptable before. (SEC-27)
18. **G-07 residual** — the commit capability itself, behind a pull request. Accept the residual that an assistant authors changes a human approves, and be explicit that the human approval is the control.
19. **G-21 residual** — the connector breadth per workspace, decided per business function rather than by a global default, with the owner named.
20. **PCI-DSS caveat** — confirm at expansion whether any connected mailbox sits in a cardholder data environment, and record the answer either way.

---

## Appendix A — Privacy by Design scorecard

| PbD principle | PLAT-2810 posture |
|---|---|
| **Proactive not reactive** | **Fails.** No privacy work has started: no basis, no record of processing, no DPIA, and expansion planned. The one thing in its favour is timing — this review arrives at design time, so nothing here is a retrofit yet |
| **Privacy as the default** | **Fails.** A new workspace inherits the full connector set; staff are enrolled into mailbox reading with no opt-in; metering collects per-person data by default. G-21, PRV-02, G-17 |
| **Privacy embedded into design** | **Fails.** Eighteen acceptance criteria, none of them privacy. Personal data flows are not modelled anywhere in the input, and the supplied diagram omits the third-party transfer entirely. G-27, O1 |
| **Full functionality, positive-sum** | **Partially strong, and this is the one to build on.** The controls in §5 cost very little functionality: gating applies to a small subset of actions, source exclusion applies to specific folders, and per-user authorisation returns what the user could see anyway. The design does not have to be made worse to be made lawful |
| **End-to-end security** | **Fails.** **No encryption requirement, no transport requirement, no retention, no deletion, and an unnamed processor receiving corporate personal data on every turn.** G-12, G-14, G-29 |
| **Visibility and transparency** | **Mixed, and the good half is real.** PLAT-2825 gives users visibility of actions, which is genuinely more than most comparable designs offer. But third-party data subjects have no notice at all, claim provenance is absent, and no privacy notice covers the processing. G-16, G-24 |
| **Respect for user privacy** | **Fails, in a specific and fixable way.** Subject rights are unexecutable, special-category data is reachable, and the metering built for cost control is a ready-made employee-monitoring dataset. Each has a named control in §5 and none requires the product to change what it does for users |

---

*This document reflects the inputs as supplied on 2026-09-09; statuses tied to ticket references are point-in-time. Nothing here is legal advice; the GDPR, EU AI Act and NIS2 positions should be confirmed with counsel and the Data Protection Officer.*
