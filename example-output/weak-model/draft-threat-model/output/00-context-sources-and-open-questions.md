# Context, Sources, and Open Questions

**System Analysed:** Internal AI Assistant (Pilot)  
**Analysis Date:** 2026-09-09  
**Scope:** Platform (12 users) and Support (9 users) pilot deployment  
**Status:** Pilot. Not GA. Production deployment pending security review.

---

## What Context Was Given

### Sources Provided

1. **Confluence Design Documents**
   - `architecture.md` — High-level system design, components, connectors, data handling, trust model
   - `platform-security-controls.md` — Organisational platform controls (network, source control, identity, secrets, logging, vulnerability management, runtime)
   - `data-handling-and-pilot-ops.md` — Data classification, retention, usage telemetry, known rough edges during pilot

2. **Jira Portfolio, Initiative, and Epic**
   - `PMO-0447` — Workplace Productivity Programme, FY26 H2. Portfolio-level constraints (fixed delivery date, cost predictability, no net headcount) and portfolio-level risks (cost scales with adoption, AI governance not yet defined)
   - `PROD-1131` — Initiative: Conversational access to internal systems. Problem statement, approach, phase plan (phase 1: read/write, human present, pilot; phase 2: analytics; phase 3: unattended + customer-facing)
   - `PLAT-2810` — Epic: Internal AI assistant. Acceptance criteria, story breakdown (connectors, write actions, authorisation, cost control, action visibility), and detailed task status and blockers

3. **Architecture Decision Records (8 total)**
   - ADR-0001 — Node/TypeScript, two services (assistant-svc orchestrator, assistant-connectors MCP host)
   - ADR-0002 — Shared app registration for pilot (blocks per-user delegation, expected to migrate before GA)
   - ADR-0003 — Actions execute without confirmation (UX requirement; human present; actions shown post-hoc)
   - ADR-0004 — Retrieval fans out to all connectors; only web search sanitised
   - ADR-0005 — Workspace instructions in system prompt (no validation on field)
   - ADR-0006 — Fall back to public endpoint on enterprise rate limit (not covered by enterprise DPA)
   - ADR-0007 — Per-workspace model selection (quality, cost, and safety variance not measured)
   - ADR-0008 — Conversation state in Redis with 24-hour TTL; identity from stored state on resume

4. **Infrastructure as Code**
   - `iam.tf` — Single IAM role for both services; broad `assistant/*` secrets access
   - `redis.tf` — ElastiCache Redis 7.1, replication, at-rest encryption enabled, **transit encryption disabled**; security group restricts to VPC CIDR; no auth token
   - `deploy/helm/values.yaml` — Two replicas per service, LOG_LEVEL info, **network policy disabled on beta cluster**, Redis host in-cluster, EXPOSE_DEBUG_ROUTES commented as "intentionally unset; the runbook uses the debug routes"

5. **Repository Documentation**
   - `README.md` — Pilot status, not GA, incomplete before GA (per-user delegation, Slack scope narrowing, web console SSO, spend alerting, provider fallback revert, dependency scanning)
   - `docs/pilot-scope.md` — Pilot is Platform + Support only; unattended operation and customer-facing surfaces are Phase 2/3, not in scope
   - `.github/workflows/ci.yml` — Continuous integration pipeline (not fully examined; dependency scanning status unknown)
   - `.github/branch-protection-exemptions.yml` — Lists exemptions; assistant repo not listed, so branch protection applies

---

## What Context Was NOT Given

The following information would be needed to complete the analysis:

1. **Source Code**
   - Complete implementation of `assistant-svc` and `assistant-connectors`
   - Tool implementation details (how each connector read/write tool is coded)
   - Model prompt(s) — the exact system prompt and any workspace-level instructions in use
   - Error handling and sanitisation logic, especially for web search
   - Conversation state serialization and deserialisation logic
   - Input validation and output encoding strategies

2. **Threat Intelligence and Compliance Context**
   - Whether the system processes HIPAA, PCI-DSS, or other regulated data in practice (Confluence says internal, but "internal" is not a data classification)
   - Actual data classifications used in the organisation (Confluence mentions "Internal", "Confidential", "Personal data"; the mapping to data handling requirements is not clear)
   - Whether the system is in-scope for GDPR (likely yes if EU users are in Platform or Support pilots; not confirmed)
   - Whether CRA applies (SaaS with no client-side software, so likely out of scope; but not confirmed)
   - NIS2 applicability (not stated; depends on whether the organisation is "essential" or "important" under NIS2)

3. **Operational Details**
   - Incident response procedures (who owns security incident triage, how is severity classified, what is the SLA for response)
   - Monitoring and alerting (what signals are monitored for compromise or misuse — tool invocation patterns, cost spikes, unusual data access)
   - Runbook specifics (Confluence mentions `docs/runbooks/`; contents not examined)
   - Deployment and release process (CI/CD pipeline details, who has push access, approval workflows)
   - Support contacts and escalation paths for security issues

4. **Runtime Behavior**
   - What model(s) are actually in use (per-workspace configuration exists, but no list of available models or their safety properties)
   - What workspaces are configured and with what instructions (system prompt customization is per-workspace; the actual instances are not listed)
   - Which OAuth scopes are actually requested by each connector (Confluence lists "full scope set for the prototype"; the actual scopes are not enumerated)
   - Rate limiting configuration and enforcement (Confluence mentions rate limiting from provider; the client-side handling is mentioned but not detailed)
   - Logging configuration in production (LOG_LEVEL is "info"; what is actually logged at info, debug, and what is never logged)

5. **Dependencies and Supply Chain**
   - Complete `package.json` dependencies with version pinning (Node modules can be a significant attack surface)
   - MCP server/client versions and their security track record
   - Base container image and scanning results
   - Whether dependency scanning is actually enabled in CI and what the current CVE status is

6. **Historical Data**
   - Pilot metrics — usage patterns, token consumption, error rates, any unexpected behaviour observed
   - Known incidents or near-misses during the pilot (Confluence mentions "two mistaken Slack posts"; no detail on root cause)
   - Any prior security reviews or pen tests
   - Feedback from pilot users on security or privacy concerns

7. **Business and Organisational Context**
   - Who owns the pilot and who is accountable for security decisions
   - Funding and resourcing for security remediation before GA
   - Timeline for Phase 2 and Phase 3 (or whether they are still planned)
   - What "production" means in this context (is the pilot running on infrastructure called "beta" or "production"?)

---

## Assumptions Made for This Analysis

Given the gaps above, the following assumptions are stated explicitly:

1. **Data Classification:** "Internal" is treated as the baseline (not confidential, not public). "Confidential" and "Personal data" are treated as higher-sensitivity classifications requiring stronger controls. The organisational data classification policy itself is assumed to exist but is not specified here.

2. **Regulatory Scope:** 
   - GDPR applies (the system processes data of EU users who are part of the pilot; EU data protection applies)
   - CRA does not apply (this is pure SaaS, no downloadable or embedded software component; CRA is out of scope unless this changes)
   - NIS2 applicability depends on organisational status and is flagged as an open question for legal/compliance
   - No HIPAA, PCI-DSS, or other sector-specific regulations are assumed to apply; if any do, the analysis must be revisited

3. **Trust Boundary:** The corporate network boundary is the trust boundary, as stated in architecture.md. All systems inside the corporate perimeter (users, internal systems, corporate infrastructure) are within the trust boundary. Web search results are explicitly untrusted per the architecture.

4. **Pilot Status:** The pilot is genuinely limited to Platform and Support; unattended operation is not in scope; the human-present requirement is enforced by design and process; pilot users are corporate employees with corporate identities.

5. **Model Behavior:** Model outputs are treated as potentially untrustworthy (e.g., hallucinations, injection attacks); no security guarantee relies solely on "the model will refuse." This follows the Cox thesis from the threat-modeling skill.

6. **Security Controls:** Platform-provided controls (perimeter, egress proxy, branch protection, SSO, network segmentation, TLS, vulnerability scanning) are assumed to be in place and functioning as documented. Application-layer controls are the responsibility of the assistant team and are analysed in this review.

7. **Code Quality:** No code review was performed; the analysis is based on the documented architecture and decisions. Implementation bugs may exist beyond what the design review identifies.

---

## Session Participants

**Primary Analyst:** Claude Haiku 4.5 (Security Architect, Threat Modeler)  
**Attribution:** Brett Crawley, Principal Application Security Engineer  
**Date:** 2026-09-09  
**Frameworks:** STRIDE · LINDDUN · OWASP Top 10 / ASVS · GDPR Privacy by Design · Elevation of Autonomy

---

## Open Questions Requiring Escalation

Before this system reaches GA, the following open questions must be resolved by the team:

### Architecture & Design

1. **Per-User Delegation (PLAT-2820)** — Currently blocked on Identity Platform. What is the timeline? If it remains unscheduled, should the pilot continue using the shared app registration, or should it be paused?

2. **Conversation Lifecycle** — When a user who started a conversation leaves the organisation, what happens to the conversation, the stored state, and the ability to retrieve it or delete it? This is an open question in the Confluence data handling document.

3. **Slack Scope Narrowing (PLAT-2814-6)** — The Slack connector is installed with "full scope"; this must be narrowed before GA. What are the minimum scopes required, and when will this be done?

4. **Web Console SSO (PLAT-2831-3)** — Currently behind VPN with shared password. SSO is not scheduled. For GA, can users authenticate via corporate SSO?

### Compliance & Legal

5. **AI Governance (PR-03)** — The group AI governance workstream has not started. The initiative is proceeding on the basis that governance will be retrofitted. For GA, what is the governance framework, and what does compliance with it require?

6. **GDPR Lawful Basis** — What is the lawful basis for processing personal data (especially data from Support shared mailbox, which is mentioned as an open question)? Consent? Contract? Legitimate interest?

7. **Right to Erasure** — How will "right to be forgotten" requests be handled? Conversation state is stored in Redis; how is it deleted across backups and any downstream logs?

8. **Support Shared Mailbox** — Is a shared mailbox data controller's data? If the assistant accesses Support's shared mailbox, is that a data processing activity that requires a DPA with the mailbox owner?

### Operations & Security

9. **Kill Switch** — An open question in the data handling document: is there a kill switch that can disable the assistant across all workspaces, and who is authorized to use it?

10. **Incident Response** — Who owns security incidents? What is the escalation path if the assistant is compromised or misused?

11. **Monitoring & Alerting** — What signals indicate compromise (e.g., unexpected tool invocations, rate limit hits, unusual data access patterns)? How are they monitored?

12. **Model Fallback (ADR-0006)** — The fallback to the public endpoint on rate limit violates the enterprise DPA. What is the SLA for quota increase, and what is the mitigation in the meantime?

### Before Pilot Expansion

13. **Provider Fallback Revert (ADR-0006)** — The ADR says "revert when the quota increase lands. Nobody owns chasing it." Assign an owner and a timeline.

14. **Dependency Scanning** — PLAT-2077 is listed as open. Is dependency scanning actually enabled in CI? What is the current CVE status?

15. **Debug Routes** — The Helm values comment says EXPOSE_DEBUG_ROUTES is "intentionally unset; the runbook uses the debug routes." What are the debug routes, what do they expose, and can they be disabled in production?

16. **Network Policy (PLAT-2101)** — The Helm values say network policy is disabled on the beta cluster "because the platform standard says these exist; the beta cluster does not have them enabled." For GA, will network policy be enabled?

---

## Executive Summary for the Team

**The system is well-documented and the architectural decisions are sound for a pilot.** However, three categories of findings emerge:

1. **Known gaps documented in tickets (Planned mitigations):**
   - Per-user delegation (PLAT-2820) — currently shared app registration, expected to migrate
   - Slack scope narrowing (PLAT-2814-6) — currently full scope, expected to narrow
   - Web console SSO (PLAT-2831-3) — currently shared password, expected to add SSO
   - These are acceptable for the pilot; required before GA.

2. **Design decisions that raise risk (Partially mitigated):**
   - Actions execute without confirmation — acceptable for pilot with human present and post-hoc visibility; must be re-evaluated for production
   - Workspace instructions in system prompt with no validation — acceptable for pilot with trusted admin, requires validation and limits for GA
   - Model fallback to public endpoint — violates DPA, requires quota increase or architectural change
   - Conversation state in Redis with no transit encryption — acceptable for in-cluster, but audit logging should capture access
   - Network policy disabled — acceptable for beta, required before GA

3. **Threats requiring architectural or operational response (Unmitigated or mitigated by process):**
   - Prompt injection / tool misuse — mitigated by human presence, requires output sanitisation and tool scope limits for unattended operation
   - Shared credentials across pilot users — current design allows users to access anything any pilot user can access; per-user delegation required for GA
   - Attribution missing — actions attributed to service principal, not user; per-user delegation required to fix
   - Data subject rights (access, erasure, portability) — not yet designed; required for GDPR compliance

The pilot is **ready to proceed with the current user groups** provided that:
- The known gaps (delegation, scope narrowing, SSO) remain tracked and scheduled
- Monitoring and alerting for security signals are added
- An incident response playbook is created
- AI governance is resolved with Legal / Compliance

Before GA, the three planned-mitigation gaps must be closed, and the design-level findings must be addressed.

---

## This Document's Role

This is **Phase 1 of the security engineering workflow:** context and open questions. It is followed by:

1. Classified requirements and gap analysis
2. Use cases and abuse cases
3. Security architecture and component design
4. Threat model (STRIDE/LINDDUN) and risk register
5. Counter-use cases (security controls)
6. SRTM and test artifacts

All findings are cross-referenced across these documents. **Start with this document to understand the scope and the gaps; use the other documents to understand the threats and the required controls.**
