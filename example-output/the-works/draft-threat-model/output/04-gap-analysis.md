# Internal AI Assistant — Gap Analysis

**Version:** 1.0 (required-versus-built, authored after the threat model) · **Date:** 2026-09-08
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this gap analysis. Produced with AI assistance using the security-review skill set authored by **Brett Crawley, Principal Application Security Engineer**.
**Model:** Claude Opus 5
**Companion documents:** `06-threat-model.md` · `03-security-architecture.md` · `05-srtm-and-test-artefacts.md`

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted.

---

## 0. Headline

**What is genuinely strong here, by name.** The platform baseline is real and it is carrying this pilot further than its own code would. The **egress proxy with a domain allowlist**, in place since 2023, is the single best control in the estate for a system like this. **Organisation-wide secret scanning with push protection** means that after reading every file in the repository there is not one credential literal to report. **Server-side tool authorisation** at `mcp/server.ts:41` is in the right place — the allowlist is checked at the connector, not in the prompt, which is the distinction most teams get wrong. **AWS Secrets Manager with workload identity**, **at-rest encryption on ElastiCache** and **platform logging outside the cluster** are all correct choices made without being asked.

The engineering honesty is also worth naming. Eight ADRs record the pilot's shortcuts accurately, including one whose closing section is headed *Not written back*. Chart comments record the network-policy gap. The CI file records why the scanning step is missing. The rotation runbook states plainly that there is no per-user credential to revoke. **The team knew.** This review is largely the work of taking what they already wrote down and stating the combined consequence.

What remains clusters into six themes.

1. **One credential set for everybody.** ADR-0002 routed around a blocked dependency and produced a system where the assistant reaches more than any user can. Every High and Critical finding is either this or amplified by it. The team self-identified it and tracks it at PLAT-2820-3; I am agreeing, not discovering. **G-01, G-02, G-03.**
2. **Untrusted content reaches the model as instruction, and the model can write.** The trust model says web search is the only untrusted path. Four corporate connectors carry content any employee, contractor or outsider can author, and none of them is filtered — and writes execute with no confirmation. **G-04, G-05, G-06.**
3. **Defaults that widen capability.** Unconfigured workspaces get every tool; unknown workspaces get a working session; failed retrieval produces a confident answer; a rate-limited provider silently becomes a different processor. **G-07, G-08, G-09, G-10.**
4. **An audit trail that cannot answer an incident question.** No arguments, no acting user, no correlation identifier, and a 24-hour retention that is shorter than the time it takes to notice. **G-11, G-12, G-13.**
5. **Privacy obligations not yet started.** Customer correspondence is being processed with no lawful basis recorded, no notice, no assessment and no erasure route. **G-14 to G-19.**
6. **Documentation that would mislead a reviewer.** Five approved statements are contradicted by the committed code, and a decision to expand would be taken against controls that do not exist. **G-20 to G-24.**

There is also a small set of **residual design risks worth a decision rather than a fix**: the workspace instruction field (ADR-0005), free model selection (ADR-0007), and the deliberate absence of conversation backups. Each should be carried knowingly in an ADR with an owner, not quietly.

Nothing here is a reason to stop the pilot. Several are reasons not to expand it yet — and the shared mailbox question is a reason to narrow it today.

---

## 1. Assumptions and context

| Question | Answer from the inputs |
|---|---|
| What is being built | An internal AI assistant reading across Office 365, Slack, GitHub, Confluence and the public web and writing to four of them, delivered as two Node services on EKS with Redis conversation state and a hosted model provider |
| Actors | 21 pilot users; workspace admins; platform on-call; internal and external content authors; cluster neighbours; one contracted and one uncontracted model provider account; four vendor and one community MCP server; customers whose correspondence is read |
| Data | Documents, calendar, mail, Slack channels and direct messages, issues, source code, Confluence pages, public web, conversation state, per-user telemetry. Customer personal data enters through Support's shared mailbox; special-category content is possible and unassessed |
| Deployment | Single-region eu-west-1, beta EKS cluster, Helm, IRSA, two Terraform files supplied |
| Regulatory | GDPR and UK GDPR apply. NIS2 applicability unresolved. CRA, PSTI and HIPAA out of scope. PCI-DSS conditional. SOC 2 where a report covers the estate |
| Market or expansion triggers | PROD-1131 phase 3 contemplates customer-facing surfaces and unattended operation; either would change the CRA and Article 22 positions |
| Downloadable or embedded software | None. Hosted internal service only |

**Assumptions carried:** (a) the platform gateway authenticates users, although it was not supplied; (b) the platform controls page describes controls that are live estate-wide except where the repository contradicts it; (c) `package-lock.json` is genuinely absent rather than omitted from the extract; (d) the organisation is Meridian, inferred from one workspace configuration string.

---

## 2. Requirements classification

### 2.1 Functional (FR)

| ID | Requirement | Source | Status |
|---|---|---|---|
| FR-01 | Available in Slack and in the web console | PLAT-2810 | 🟢 Live (PLAT-2831) |
| FR-02 | Answer questions using content from existing tools | PLAT-2810, PLAT-2814 | 🟢 Live |
| FR-03 | Take actions, not just read | PLAT-2810, PLAT-2817 | 🟢 Live |
| FR-04 | Users see what the assistant did | PLAT-2810, PLAT-2825 | 🟡 names only, no targets (AI13) |
| FR-05 | Users can review and delete their own conversations | PLAT-2825-2 | 🔴 delete is unwired (P4) |
| FR-06 | Connect to O365, Slack, GitHub, web search | PLAT-2814 | 🟢 Live, plus an undocumented fifth connector (O2) |
| FR-07 | Token usage tracked per team and visible to teams | PLAT-2822 | 🟢 Live |
| FR-08 | Cheaper model tiers configurable per workspace | PLAT-2822, ADR-0007 | 🟢 Live |

### 2.2 Security (SEC)

| ID | Requirement | Source | Status | Gap |
|---|---|---|---|---|
| SEC-01 | Per-user delegated credentials for every connector | PLAT-2820, D-03 | 🔵 Planned | **G-01** |
| SEC-02 | Tokens short-lived and refreshed, held in a credential store | PLAT-2820-2 | 🔵 Planned | **G-02** |
| SEC-03 | A user cannot reach through the assistant what they cannot reach directly | PLAT-2820, architecture page | 🔴 Open | **G-03** |
| SEC-04 | Web search content treated as untrusted and cleaned | PLAT-2814 | 🟡 two-phrase denylist, defeated by its own ordering | **G-04** |
| SEC-05 | Internal content is behind authentication so needs no cleaning | PLAT-2814 acceptance criterion | 🔴 the premise is false | **G-05** |
| SEC-06 | Connector scopes narrowed before general availability | PLAT-2814-6 | 🔵 Planned | **G-06** |
| SEC-07 | Single sign-on on the web console | PLAT-2831-3 | 🔵 Planned | **G-07** |
| SEC-08 | Branch protection bounds the blast radius of commits | PLAT-2817-3 comment | 🔴 three repositories exempt | **G-08** |
| SEC-09 | Diagnostic routes disabled in production | Platform controls page | 🔴 default on, chart leaves unset | **G-09** |
| SEC-10 | Default-deny network policy between namespaces | Platform controls page | 🔴 disabled in the chart | **G-10** |
| SEC-11 | Dependency scanning blocks the build on critical findings | Platform controls page | 🔴 absent, template inherited from an exempt repository | **G-11** |
| SEC-12 | Every privileged action recorded with user, action and parameters | Architecture page | 🔴 tool name and time only | **G-12** |
| SEC-13 | Actions attributable in the target system's audit log | D-03 | 🔴 shared principal downstream | **G-13** |
| SEC-14 | Encryption in transit between services and to datastores | Platform controls page | 🔴 Redis is plaintext by decision | **G-15** |
| SEC-15 | Workload identities per service, least privilege | Platform controls page | 🔴 one role, both services, wildcard secret read | **G-16** |
| SEC-N1 to SEC-N7 | *New, from the architecture pass* — confirmation gate, provenance as a data type, workload identity per hop, fail-closed defaults, an audit plane, a kill switch, a behaviour inventory | `03-security-architecture.md` §10 | 🔴 Open | **G-04, G-05, G-14, G-17, G-24** |

### 2.3 Privacy (PRV)

| ID | Requirement | Source | Status | Gap |
|---|---|---|---|---|
| PRV-01 | No new persistent stores; read from systems of record in place | D-05 | 🟡 true of content, false of telemetry and processor retention | **G-18** |
| PRV-02 | Conversation state transient, 24-hour expiry | Architecture page, ADR-0008 | 🟢 Live — *exemplary as a minimisation choice* | — |
| PRV-03 | Telemetry aggregated to team for cost attribution | PMO-0447, PLAT-2822 | 🔴 stored per user for 13 months | **G-19** |
| PRV-04 | Users can delete their own conversations | PLAT-2825-2 | 🔴 unwired | **G-20** |
| PRV-05 | Lawful basis for each category of personal data | Not stated anywhere | 🔴 Open | **G-21** |
| PRV-06 | Notice to data subjects, including third parties | Not stated anywhere | 🔴 Open | **G-22** |
| PRV-07 | Data subject rights executable across all copies | Not stated anywhere | 🔴 Open | **G-20** |
| PRV-N1, PRV-N2 | *New* — deletion path and subject locator per store; retrieval minimisation | `03-security-architecture.md` §10 | 🔴 Open | **G-20, G-23** |

### 2.4 Performance (PERF)

| ID | Requirement | Source | Status | Gap |
|---|---|---|---|---|
| PERF-01 | Response under 6 seconds for a typical question | PLAT-2810 | 🟡 long conversations get slow, recorded on the data-handling page | **G-25** |
| PERF-02 | Running cost predictable and attributable | PMO-0447 | 🟡 attributable, not predictable — no enforced ceiling | **G-26** |
| PERF-03 | Graceful degradation when a dependency fails | Not stated | 🔴 degrades silently and answers anyway | **G-27** |

### 2.5 Compliance (COMP)

| ID | Requirement | Source | Status | Gap |
|---|---|---|---|---|
| COMP-01 | GDPR Article 6 lawful basis recorded per category | GDPR | 🔴 Open | **G-21** |
| COMP-02 | GDPR Article 35 assessment where risk warrants | GDPR | 🔴 Open | **G-21** |
| COMP-03 | GDPR Articles 13 and 14 notice | GDPR | 🔴 Open | **G-22** |
| COMP-04 | GDPR Article 17 erasure executable | GDPR | 🔴 Open | **G-20** |
| COMP-05 | GDPR Articles 28 and 44 to 49 — processors and transfers | GDPR | 🔴 fallback outside the DPA | **G-28** |
| COMP-06 | GDPR Article 33 breach assessment within 72 hours | GDPR | 🔴 not achievable with current evidence | **G-12** |
| COMP-07 | NIS2 applicability determined | NIS2 | 🔴 unresolved | **G-29** |
| COMP-08 | CRA applicability determined | CRA | ⚪ out of scope, recorded | — |
| COMP-09 | PSTI applicability determined | PSTI | ⚪ out of scope, recorded | — |
| COMP-10 | PCI-DSS applicability determined | PCI-DSS | 🔴 conditional, unresolved | **G-30** |
| COMP-11 | SOC 2 control coverage for this workload | SOC 2 | 🔴 multiple criteria with open findings | **G-09, G-12, G-16** |
| COMP-N1, COMP-N2 | *New* — data categories bounded by lawful basis; no prompt leaves the contracted processor set | `03-security-architecture.md` §10 | 🔴 Open | **G-21, G-28** |

---

## 3. Consolidated gap list

| Gap | Title | Severity | Type |
|---|---|---|---|
| **G-01** | Delegated per-user credentials specified, approved and never built | **Critical** | Design decision |
| **G-02** | No credential store and no per-user revocation path | **Medium** | Roadmap |
| **G-03** | Users can reach content through the assistant that they cannot open | **Critical** | Design decision |
| **G-04** | The only content control is a two-phrase denylist defeated by its own ordering | **High** | Design decision |
| **G-05** | Four corporate content paths are unfiltered on a false trust premise | **Critical** | Design decision |
| **G-06** | Connector scopes never narrowed after the prototype | **High** | Roadmap |
| **G-07** | No per-user authentication on the web console | **High** | Roadmap |
| **G-08** | Commit reach extends into repositories exempt from review | **High** | Latent |
| **G-09** | Diagnostic routes ship enabled against the platform standard | **Medium** | Doc-drift |
| **G-10** | Network policy disabled in the cluster the pilot runs in | **High** | Doc-drift |
| **G-11** | No dependency scanning, no lockfile | **High** | Assurance |
| **G-12** | Audit record cannot answer an incident question | **High** | Design decision |
| **G-13** | Downstream attribution is a shared principal | **High** | Design decision |
| **G-14** | No confirmation or irreversibility gate on write actions | **Critical** | Design decision |
| **G-15** | Conversation store is plaintext, unauthenticated and VPC-reachable | **High** | Hardening |
| **G-16** | One IAM role for both services with wildcard secret read | **High** | Hardening |
| **G-17** | Defaults widen capability in four places | **Critical** | Design decision |
| **G-18** | The no-new-stores claim omits telemetry and processor retention | **Medium** | Doc-drift |
| **G-19** | Per-user telemetry retained 13 months for a team-level purpose | **Medium** | Compliance |
| **G-20** | No executable erasure across four stores | **High** | Compliance |
| **G-21** | No lawful basis, record of processing or Article 35 assessment | **High\*** | Compliance |
| **G-22** | No notice to employees or third parties | **Medium** | Compliance |
| **G-23** | Retrieval returns whole bodies rather than the minimum | **Medium** | Design decision |
| **G-24** | No inventory of models, prompts, connectors and tool schemas | **Medium** | Assurance |
| **G-25** | Latency and cost grow without bound inside a session | **Medium** | Hardening |
| **G-26** | Spend has no enforced ceiling | **High** | Roadmap |
| **G-27** | Partial failure is indistinguishable from a complete answer | **Medium** | Design decision |
| **G-28** | Prompts leave the contracted processor set under load | **High** | Compliance |
| **G-29** | NIS2 applicability unresolved | **Medium** | Compliance |
| **G-30** | PCI-DSS applicability unresolved for Support correspondence | **Medium** | Compliance |
| **G-31** | No kill switch and no incident response plan | **High** | Hardening |
| **G-32** | Approved design pages contradict the implementation in five places | **High** | Doc-drift |
| **G-33** | Container and pod hardening absent across image, runtime and orchestrator | **Medium** | Hardening |
| **G-34** | No governance layer above the design | **Medium** | Residual |

\* **G-21 is conditional.** If Support's shared mailbox is confirmed in scope and carries special-category content, it becomes Critical and the sequencing changes: it moves ahead of everything except G-14.

---

## 4. Regulatory compliance assessment

| Framework | Applicability | Position | Gaps |
|---|---|---|---|
| **GDPR / UK GDPR** | Applies | The weakest area. Processing of employee and customer correspondence with no recorded basis, no notice, no assessment, no erasure route and an uncontracted transfer path | G-19 to G-23, G-28 |
| **NIS2** | Unresolved, material | If Meridian is an essential or important entity: the shared console password fails the Article 21 MFA requirement, supply-chain obligations bite on the connector chain, and the 24-hour early-warning duty attaches to a system with no detection and no kill switch | G-07, G-11, G-24, G-31, G-29 |
| **CRA** | Out of scope | Internal hosted service; no product with digital elements placed on the EU market and no downloadable component. Confirm before phase 3. The SBOM and vulnerability-disclosure obligations are worth adopting regardless and are already gaps | G-11, G-24 |
| **PSTI** | Out of scope | No consumer connectable product | — |
| **PCI-DSS** | Conditional | No cardholder data environment by design, but Support correspondence and refund discussions can carry card numbers typed by customers. If confirmed, requirements 3, 4, 7 and 10 apply to a system with no argument-level audit | G-30, G-12 |
| **HIPAA** | Out of scope | No protected health information and no covered-entity relationship | — |
| **SOC 2** | Applies where a report covers the estate | Logical access, encryption, monitoring and change management all carry open findings; the diagnostic routes and the exemption drift are the likeliest exceptions | G-09, G-12, G-15, G-16, G-32 |

---

## 5. Refined requirements

The refined set is a strict superset of the original: nothing above is dropped, and every addition is marked with its provenance.

**Security.** SEC-01 to SEC-15 as classified, plus:
- **SEC-16** `[NEW — from SAC-01/G-14]` Every irreversible tool call requires a confirmation token minted by the surface and verified server-side before dispatch.
- **SEC-17** `[NEW — from AI5/G-05]` Retrieved content and tool results carry source, trust level and classification as structured fields, and are never concatenated into the user turn.
- **SEC-18** `[NEW — from S2/G-17]` Every inter-service call is authenticated by workload identity, and the connector service derives the workspace from the authenticated principal.
- **SEC-19** `[NEW — from E1/E2/G-17]` Any unknown or unconfigured workspace, tool or credential resolves to no capability and fails the turn.
- **SEC-20** `[NEW — from R1/G-12]` An audit event exists for every write action, correlated across services and retained independently of the conversation TTL.
- **SEC-21** `[NEW — from RR1/G-31]` Write capability can be disabled globally, per workspace and per tool without a deployment, by a named owner.
- **SEC-22** `[NEW — from AI10/AI11/G-24]` Models, prompt files, connector versions and tool schemas are versioned, inventoried and verified at start-up.
- **SEC-23** `[NEW — from AI2/G-14]` Tool arguments are validated against a per-tool schema with allowlisted values for recipients, channels, repositories, branches and paths.
- **SEC-24** `[NEW — from AI4/G-05]` Model output passes an output filter before rendering or transmission, and the console enforces a content security policy.
- **SEC-25** `[NEW — from C2/C3/G-33]` Both workloads run under a restricted pod security context with default-deny network policy and resource limits.

**Privacy.** PRV-01 to PRV-07 as classified, plus:
- **PRV-08** `[NEW — from P4/G-20]` Every persisted copy of conversation content has a named deletion path and a per-subject locator.
- **PRV-09** `[NEW — from P2/G-23]` Retrieval returns the minimum content needed for the question rather than whole bodies.
- **PRV-10** `[NEW — from P3/G-19]` Telemetry is pseudonymised at write and the identified form expires on the finance cycle.

**Compliance.** COMP-01 to COMP-11 as classified, plus:
- **COMP-12** `[NEW — from G-21]` No workspace processes a data category outside its recorded lawful basis, enforced by the connector allowlist rather than by policy alone.
- **COMP-13** `[NEW — from I4/G-28]` No prompt leaves the contracted processor set under any load condition.

**Performance.** PERF-01 to PERF-03 as classified, plus:
- **PERF-04** `[NEW — from D4/G-25]` Assembled context is bounded by a token ceiling enforced before the provider call.

**Operational.** 
- **OPS-01** `[NEW — from O1/G-32]` Pilot expansion is blocked while any ADR marked as not written back is open against an approved page.

---

## 6. Recommended sequence

**Launch gates — before any expansion beyond Platform and Support**
1. **SEC-16, the confirmation gate on irreversible tools** (G-14). *The single most important item in the pack.* It is the one control that holds regardless of how content reaches the model.
2. **Narrow the reach** (G-03, G-06, G-08): Slack scopes without direct-message history, GitHub installation scoped to named repositories excluding the exempt ones, and a per-user filter at retrieval that does not wait for PLAT-2820.
3. **Close the four unauthenticated surfaces** (G-10, G-15, G-17): network policy on, connector service authenticated, Redis encrypted and authenticated, debug routes default closed.
4. **Invert the widening defaults** (G-17): unknown workspace and unconfigured tools both resolve to nothing.
5. **Answer the shared mailbox question and start the Article 35 assessment** (G-21). Until it is answered, remove `read_mail` from the Support workspace — one configuration line.
6. **Correct the approved architecture page** (G-32), so the expansion decision is not taken against controls that do not exist.

**Fast hygiene — days, cheap, no design debate**
7. Send `userId` from `gather()` (G-03, one line). Add `userId` to two log lines (G-12). Allowlist the debug configuration fields (G-09). `automountServiceAccountToken: false` and a pod security context (G-33). Namespace tool identifiers (G-24). Reorder the sanitiser so it measures what it claims (G-04). A rate limiter on `POST /turns` (G-26). Namespace the Redis key and compare the owner (G-17).

**Near-term**
8. The audit plane and correlation identifier (G-12, G-13). Structured provenance on retrieval (G-05). Output filter and content security policy (G-05). Enforced spend budgets (G-26). Lockfile, audit and SBOM steps (G-11). The graded kill switch and the response plan (G-31). Erasure path and subject locator (G-20). Telemetry pseudonymisation (G-19). Image digest pinning and signing (G-33).

**Decisions to ratify, not fixes**
9. Ratify or tighten, explicitly and in an ADR with an owner: the unvalidated workspace instruction field (ADR-0005); free model selection for a workspace holding customer data (ADR-0007); the deliberate absence of conversation backups; the three branch-protection exemptions (PLAT-1188); and the portfolio's acceptance that AI governance is retrofitted (PR-03). Each is defensible. None is currently carried knowingly by a named person.

---

## Appendix A — Privacy by Design scorecard

| PbD principle | Posture |
|---|---|
| Proactive not reactive | **Weak.** The privacy questions are written down as open questions on a draft page while the processing continues |
| Privacy as the default | **Weak.** Unconfigured workspaces read and write everything; telemetry defaults to identified; retention defaults to the storage decision rather than the purpose |
| Privacy embedded into design | **Mixed.** D-05, no new stores, is a genuinely good structural choice and it is honoured for content. It is undone by four uncontrolled copies nobody counted |
| Full functionality, positive-sum | **Strong intent.** ADR-0003 correctly refuses to make the tool unusable in the name of safety. The error is removing friction everywhere instead of placing it on irreversible actions |
| End-to-end security | **Weak.** Plaintext to Redis; **an uncontracted processor under load**; **no erasure across four stores**; **no output boundary at all** |
| Visibility and transparency | **Weak.** No notice to any data subject, and the action list shows tool names without targets |
| Respect for user privacy | **Mixed.** The 24-hour TTL and the read-in-place design respect it; the 13-month identified telemetry and the unanswerable erasure request do not |

---

*Reflects the material as supplied on 2026-09-08. Ticket statuses are point-in-time. Nothing here is legal advice; the NIS2, Article 35, Article 14 and PCI-DSS determinations should be confirmed with counsel and the DPO.*
