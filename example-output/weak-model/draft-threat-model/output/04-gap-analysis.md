# Gap Analysis: Required vs. Built

**System:** Internal AI Assistant (Pilot)  
**Date:** 2026-09-09  
**Status:** Pilot. Gaps listed with ticket references and status.

---

## Executive Summary

The system has **2 critical gaps**, **5 high-severity gaps**, and **8 medium/low gaps** blocking GA. Critical gaps are architectural and must be resolved before production. High-severity gaps are design work that must be completed. Medium/low gaps are operational or can be deferred to Phase 2.

---

## Architecture Gaps (Blocking GA)

### GAP-A1: Per-User Delegated OAuth Not Implemented (PLAT-2820)

**Required By:** SEC-004 (User Attribution)  
**Current State:** Shared app registration; all pilot users reach everything any pilot user can reach  
**Target State:** Per-user delegated OAuth for O365, Slack, GitHub connectors  
**Ticket:** PLAT-2820-1 (blocked on Identity Platform, not scheduled)  
**Impact if Not Fixed:**
- Over-provisioned access (users can reach resources they don't have direct access to)
- No attribution (actions attributed to service principal, not user)
- GDPR non-compliance (no audit trail per user)
- Violates ADR-0002 design (intended design has per-user delegation)

**Remediation Cost:** High (requires new OAuth flow, token storage, refresh logic, testing)  
**Owner:** Identity Platform (currently not scheduled; blocker)  
**Status:** ⏳ Planned (not scheduled)

### GAP-A2: Provider Rate Limit Fallback Violates DPA (ADR-0006)

**Required By:** COMP-005 (DPA Compliance)  
**Current State:** Falls back to public endpoint when enterprise endpoint returns 429  
**Target State:** Enterprise endpoint only, OR quota increase provided  
**Ticket:** ADR-0006 revert (nobody owns quota increase chase)  
**Impact if Not Fixed:**
- Prompts sent to public endpoint not covered by enterprise DPA
- Data protection commitment violated during peak load (when breach risk is highest)
- Volume is inverse: highest data at risk exactly when most urgent to fix

**Remediation Cost:** Medium (either pursue quota increase or add hard cap)  
**Owner:** Unassigned (ADR says "nobody owns chasing it")  
**Status:** ⏳ Planned (quota pending; no ETA)

### GAP-A3: Redis Transit Encryption Disabled (ADR-0008 + terraform/redis.tf)

**Required By:** SEC-016 (Encryption in Transit)  
**Current State:** Redis transit encryption disabled; no auth token; relies on security group  
**Target State:** Transit encryption enabled OR network policy + default-deny  
**Ticket:** None; technical debt  
**Impact if Not Fixed:**
- Conversation state (containing user queries and retrieved data) unencrypted in transit
- Combined with network policy disabled (GAP-A4), anyone in the cluster can read Redis traffic
- Not IP-restricted if cluster is shared with untrusted workloads

**Remediation Cost:** Medium (update client library, test, deploy)  
**Owner:** Assistant team  
**Status:** ⏳ Planned (for GA)

### GAP-A4: Network Policy Disabled on Beta Cluster (helm/values.yaml)

**Required By:** SEC-015 (Network Segmentation)  
**Current State:** Network policy feature disabled; any pod can reach any port  
**Target State:** Network policy enabled with default-deny + explicit allow rules  
**Ticket:** PLAT-2101 (dependency; status: cluster feature not enabled)  
**Impact if Not Fixed:**
- Compromised pod in the same cluster can reach Redis, assistant-svc, etc.
- Blast radius of any container escape is the entire cluster
- Goes against platform standard (network policy specified but not enforced)

**Remediation Cost:** Low (enable feature, apply config) OR Medium (if GKE/EKS upgrade required)  
**Owner:** Platform SRE (PLAT-2101 listed as open)  
**Status:** ⏳ Planned (for GA)

---

## Design Gaps (Must Be Resolved Before GA)

### GAP-D1: No Output Filtering for Tool Arguments

**Required By:** SEC-001 (Prompt Injection Mitigation)  
**Current State:** Model generates tool arguments; arguments validated only by connector API  
**Target State:** Application layer validates arguments before execution; rejects suspicious patterns  
**Ticket:** SUC-001 (new security use case)  
**Impact:**
- Prompt injection attacks can reach tool execution undetected
- If tool scope is broad (e.g., "send email to any address"), injection can send emails
- Mitigated by human presence for pilot; unattended operation not possible without this

**Remediation Cost:** Medium (design validation layer, test, deploy)  
**Owner:** Assistant team  
**Status:** ⏳ New requirement (not yet ticketed)

### GAP-D2: No GDPR Data Subject Rights Flow

**Required By:** COMP-001 (GDPR Articles 15, 17, 20)  
**Current State:** No mechanism for users to access, delete, or export their conversations  
**Target State:** UI/API to list conversations, export conversation data, delete conversation data (including backups)  
**Ticket:** None (open question in data-handling-and-pilot-ops.md)  
**Impact:**
- GDPR non-compliance (users cannot exercise access, erasure, portability rights)
- Audit trail cannot be destroyed even if user requests deletion
- Retention policy cannot be enforced

**Remediation Cost:** High (implement access APIs, audit deletion, backup purging, testing)  
**Owner:** Product + Engineering  
**Status:** ⏳ New requirement (not yet ticketed)

### GAP-D3: No Input Validation on Workspace Instructions (ADR-0005)

**Required By:** SEC-006 (System Prompt Injection)  
**Current State:** Admin can inject arbitrary instructions into system prompt; no length limit, no parsing  
**Target State:** Validation on length, allowed constructs; audit trail of changes  
**Ticket:** None (accepted design for pilot; requires revisit for multi-tenant)  
**Impact:**
- Admin account compromise could inject prompt injection vectors
- No audit trail of who changed instructions or when
- System prompt unbounded size could impact performance

**Remediation Cost:** Medium (add validation layer, audit logging, test)  
**Owner:** Assistant team (for multi-tenant GA)  
**Status:** ✅ Acceptable for pilot (accepted risk); ⏳ Planned for GA

### GAP-D4: No Audit Trail for Redis Access

**Required By:** SEC-017 (Audit Logging)  
**Current State:** Redis reads/writes not logged; cannot detect unauthorized access  
**Target State:** Access logs for conversation state retrieval/modification  
**Ticket:** None (logging strategy not documented)  
**Impact:**
- Breach via Redis compromise not detected
- Cannot investigate who accessed what conversation

**Remediation Cost:** Medium (add logging layer, query API, retention)  
**Owner:** Assistant team  
**Status:** ⏳ New requirement (not yet ticketed)

### GAP-D5: No Tool Description Pinning (EoA·S9)

**Required By:** SEC-007 (MCP Server Integrity)  
**Current State:** Tool descriptions loaded from MCP server at runtime; no integrity checks  
**Target State:** Tool descriptions pinned in deployment; verified against expected hash on load  
**Ticket:** None (supply chain risk)  
**Impact:**
- Compromised MCP server can inject malicious instructions into tool descriptions
- Tool descriptions influence model behavior but are not visible to users

**Remediation Cost:** Medium (implement pinning, signature verification, test)  
**Owner:** Assistant team  
**Status:** ⏳ New requirement (not yet ticketed)

### GAP-D6: No Model Guardrails for Output Generation

**Required By:** PRV-001 (Data Minimisation), SEC-008 (No Sensitive Data in Output)  
**Current State:** Model may generate personal data beyond what is necessary  
**Target State:** System prompt instructs model not to generate PII; output filtering removes inferred data  
**Ticket:** None (privacy design gap)  
**Impact:**
- Model generates unrequested personal data (inference + hallucination)
- Data is disclosed to user and stored in Redis for 24h

**Remediation Cost:** Medium (add system prompt instruction, output filter, testing)  
**Owner:** Product + Engineering  
**Status:** ⏳ New requirement (not yet ticketed)

---

## Operational Gaps (Before GA or Phase 2)

### GAP-O1: No Monitoring for Security Signals

**Required By:** SEC-018 (Detection and Alerting)  
**Current State:** Metrics collected (latency, token count); no security-specific signals  
**Target State:** Alerts for unusual tool invocations, cost spikes, rate limit hits, failed auths  
**Ticket:** None (monitoring strategy not defined)  
**Impact:**
- Security incidents not detected in real time
- Cost overages not detected

**Remediation Cost:** Medium (define signals, implement alerts, tune thresholds)  
**Owner:** SRE + Security  
**Status:** ⏳ Before GA or Phase 2

### GAP-O2: No Incident Response Playbook

**Required By:** SEC-019 (Incident Response)  
**Current State:** No documented escalation path or kill-switch process  
**Ticket:** Open question in data-handling-and-pilot-ops.md (is there a kill switch?)  
**Impact:**
- No coordinated response to security incidents
- Confusion over who to contact and what actions to take

**Remediation Cost:** Low (document playbook, assign owner)  
**Owner:** Security + Ops  
**Status:** ⏳ Before GA

### GAP-O3: No Privacy Notice Published

**Required By:** COMP-006 (GDPR Art. 13/14 Transparency)  
**Current State:** Users have no written notice of data collection, processing, retention  
**Target State:** Privacy notice published in web console, in Slack bot profile, in documentation  
**Ticket:** None (privacy communication gap)  
**Impact:**
- GDPR violation (information to data subjects not provided)
- Users unaware of data processing and their rights

**Remediation Cost:** Low (document privacy notice, legal review)  
**Owner:** Legal + Product  
**Status:** ⏳ Before GA

### GAP-O4: Dependency Scanning Status Unknown (PLAT-2077)

**Required By:** SEC-020 (Supply Chain Security)  
**Current State:** PLAT-2077 listed as open; unclear if scanning is actually enabled for Node dependencies  
**Target State:** Dependency scanning enabled; CVE findings block build; known CVEs remediated  
**Ticket:** PLAT-2077  
**Impact:**
- Vulnerable dependencies may be deployed without detection
- Supply chain compromise not detected

**Remediation Cost:** Low (enable scanning) to Medium (fix CVEs if found)  
**Owner:** Platform CI/Platform Security  
**Status:** ⏳ Before GA

### GAP-O5: Debug Routes Not Removed from Production

**Required By:** SEC-021 (Debug Endpoint Hardening)  
**Current State:** EXPOSE_DEBUG_ROUTES commented as "intentionally unset; the runbook uses the debug routes"  
**Target State:** Debug routes documented and disabled in production deployment  
**Ticket:** None (runbook dependency)  
**Impact:**
- Debug endpoints may expose sensitive information
- Not documented what debug routes expose or who should have access

**Remediation Cost:** Low (document routes, add conditional enablement)  
**Owner:** Assistant team  
**Status:** ⏳ Before GA

### GAP-O6: Shared Mailbox Data Processing Not Cleared (Support Pilot)

**Required By:** COMP-007 (GDPR Data Processing Agreement)  
**Current State:** Support pilot accesses shared mailbox; unclear if processing is authorized  
**Ticket:** Open question in data-handling-and-pilot-ops.md (is shared mailbox in scope?)  
**Impact:**
- If mailbox is customer data, processing may violate DPA or GDPR
- Lawful basis unclear (support serving customer vs. processing personal data)

**Remediation Cost:** Low to Medium (legal review, data controller coordination)  
**Owner:** Legal + Compliance  
**Status:** ⏳ Before Phase 2 expansion

### GAP-O7: No Spend Alerting (PLAT-2822-4)

**Required By:** SEC-022 (Cost Control)  
**Current State:** Consumption dashboard exists; no alerting when spend exceeds threshold  
**Ticket:** PLAT-2822-4 (not scheduled)  
**Impact:**
- Runaway costs not detected
- Possible denial of service (exhaust token budget)

**Remediation Cost:** Low (add alerting rule)  
**Owner:** Finance + Engineering  
**Status:** ⏳ Planned (not scheduled)

### GAP-O8: Web Console SSO Not Implemented (PLAT-2831-3)

**Required By:** SEC-023 (User Authentication)  
**Current State:** Web console behind VPN with shared password  
**Target State:** Corporate SSO integration  
**Ticket:** PLAT-2831-3 (not scheduled)  
**Impact:**
- Shared password is weak; hard to audit who accessed console
- No single sign-out; credentials not revoked on termination

**Remediation Cost:** Medium (add OIDC client, test SSO flow)  
**Owner:** Assistant team  
**Status:** ⏳ Planned (not scheduled)

---

## Compliance Gaps

### COMP-001: GDPR — Lawful Basis Not Documented

**Requirement:** Document lawful basis for processing (Art. 6)  
**Current State:** Processing under assumed legitimate interest (productivity improvement) but not documented  
**Gap:** Legal sign-off missing  
**Action:** Legal review of lawful basis; document in privacy notice  
**Status:** ⏳ Before GA

### COMP-002: GDPR — Data Minimisation Not Enforced

**Requirement:** Collect only what is necessary (Art. 5(1)(c))  
**Current State:** Model may generate or retrieve more data than necessary  
**Gap:** No technical controls to enforce minimisation  
**Action:** Implement output filtering (GAP-D6)  
**Status:** ⏳ Before GA

### COMP-003: GDPR — Data Subject Rights Not Implemented

**Requirement:** Support access, erasure, portability (Art. 15, 17, 20)  
**Current State:** No mechanism to support requests  
**Gap:** Complete design missing  
**Action:** Implement data subject rights flow (GAP-D2)  
**Status:** ⏳ Before GA

### COMP-004: GDPR — DPA Not Updated for AI Processing

**Requirement:** Data Processing Agreement covers all processing (Art. 28)  
**Current State:** DPA may not cover model provider, fallback endpoint, or MCP servers  
**Gap:** DPA scope unclear  
**Action:** Audit existing DPAs; update or add as needed  
**Status:** ⏳ Before GA

### COMP-005: GDPR — No Incident Response Plan

**Requirement:** Procedure for breach notification (Art. 33)  
**Current State:** No documented incident response playbook  
**Gap:** No procedure for notifying users or GDPR authority  
**Action:** Create incident response plan (GAP-O2)  
**Status:** ⏳ Before GA

### COMP-006: UK PSTI Act — Not Applicable

**Requirement:** No default passwords, vulnerability disclosure, minimum support period  
**Assessment:** System is not a consumer connectable device; PSTI does not apply.  
**Status:** ✅ Out of scope

### COMP-007: CRA — Likely Out of Scope

**Requirement:** Software bill of materials, vulnerability disclosure, incident reporting  
**Assessment:** This is pure SaaS (no downloadable, installed, or embedded software component). CRA likely does not apply. If this changes (e.g., downloadable desktop client), re-assess.  
**Status:** ✅ Out of scope (with caveat)

### COMP-008: NIS2 — Not Assessed

**Requirement:** Risk management, incident notification, supply chain security  
**Assessment:** Only applicable if organisation is "essential" or "important" entity under NIS2 (health, digital infrastructure, managed services, etc.). Not assessed here.  
**Status:** ❓ Requires organisational assessment

---

## Summary Table: All Gaps

| Gap ID | Category | Title | Required By | Ticket | Status | Owner |
|--------|----------|-------|------------|--------|--------|-------|
| GAP-A1 | Architecture | Per-user delegated OAuth | SEC-004 | PLAT-2820-1 | ⏳ Planned (not scheduled) | Identity Platform |
| GAP-A2 | Architecture | Provider fallback violates DPA | COMP-005 | ADR-0006 | ⏳ Planned (quota pending) | Unassigned |
| GAP-A3 | Architecture | Redis transit encryption | SEC-016 | None | ⏳ Planned (for GA) | Assistant team |
| GAP-A4 | Architecture | Network policy disabled | SEC-015 | PLAT-2101 | ⏳ Planned (for GA) | Platform SRE |
| GAP-D1 | Design | Output filtering for tool args | SEC-001 | [NEW] | ⏳ New | Assistant team |
| GAP-D2 | Design | GDPR data subject rights | COMP-003 | [NEW] | ⏳ New | Product + Eng |
| GAP-D3 | Design | Workspace instruction validation | SEC-006 | None | ✅ Acceptable for pilot | Assistant team (GA) |
| GAP-D4 | Design | Audit trail for Redis access | SEC-017 | [NEW] | ⏳ New | Assistant team |
| GAP-D5 | Design | Tool description pinning | SEC-007 | [NEW] | ⏳ New | Assistant team |
| GAP-D6 | Design | Model output guardrails | PRV-001 | [NEW] | ⏳ New | Product + Eng |
| GAP-O1 | Operational | Security monitoring | SEC-018 | None | ⏳ Before GA | SRE + Security |
| GAP-O2 | Operational | Incident response plan | SEC-019 | None | ⏳ Before GA | Security + Ops |
| GAP-O3 | Operational | Privacy notice | COMP-006 | [NEW] | ⏳ Before GA | Legal + Product |
| GAP-O4 | Operational | Dependency scanning | SEC-020 | PLAT-2077 | ⏳ Before GA | Platform CI |
| GAP-O5 | Operational | Debug routes hardening | SEC-021 | None | ⏳ Before GA | Assistant team |
| GAP-O6 | Operational | Shared mailbox DPA | COMP-007 | None | ⏳ Before Phase 2 | Legal + Compliance |
| GAP-O7 | Operational | Spend alerting | SEC-022 | PLAT-2822-4 | ⏳ Planned (not scheduled) | Finance + Eng |
| GAP-O8 | Operational | Web console SSO | SEC-023 | PLAT-2831-3 | ⏳ Planned (not scheduled) | Assistant team |

---

## Blocking vs. Non-Blocking for GA

### Blocking Gaps (Must Resolve Before GA)

1. **GAP-A1:** Per-user delegated OAuth (required for attribution and compliance)
2. **GAP-A2:** Provider fallback (required for DPA compliance)
3. **GAP-A3:** Redis encryption OR network policy (required for data protection)
4. **GAP-D1:** Output filtering (required for prompt injection mitigation for unattended operation)
5. **GAP-D2:** Data subject rights (required for GDPR compliance)

### Non-Blocking But Strongly Recommended (Before GA)

- **GAP-A4:** Network policy (defense in depth)
- **GAP-D3:** Workspace instruction validation (for multi-tenant, not pilot)
- **GAP-D4:** Redis access audit (detection)
- **GAP-D5:** Tool description pinning (supply chain defense)
- **GAP-D6:** Output guardrails (privacy)
- **GAP-O1 to GAP-O5:** Operational readiness

### Acceptable for Pilot (Revisit for Phase 2)

- **GAP-O6:** Shared mailbox scope (pilot has explicit support user group; Phase 2 expansion needs legal clarity)
- **GAP-O7:** Spend alerting (not scheduled; can monitor dashboard manually for pilot)
- **GAP-O8:** Web console SSO (pilot is small group; shared password acceptable for now)

---

## Remediation Roadmap

**Immediate (Before GA Approval):**
1. Assign owner to ADR-0006 quota chase (Finance + Platform)
2. Start PLAT-2820-1 design (Identity Platform + Assistant team)
3. Implement output filtering (GAP-D1) and audit logging (GAP-D4)

**Before GA Release:**
1. Complete PLAT-2820 (per-user delegation)
2. Close provider fallback gap (quota increase or hard error)
3. Enable Redis transit encryption and network policy
4. Implement data subject rights flow (GAP-D2)

**Before Phase 2 Expansion:**
1. Publish privacy notice
2. Set up monitoring and alerting
3. Create incident response playbook
4. Address shared mailbox legal questions

---

## Session Participants

**Analyst:** Claude Haiku 4.5  
**Attribution:** Brett Crawley, Principal Application Security Engineer  
**Date:** 2026-09-09

