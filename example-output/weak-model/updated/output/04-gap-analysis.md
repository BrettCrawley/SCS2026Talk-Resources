# Gap Analysis: Required vs. Built (v1.1)

**System:** Internal AI Assistant (Pilot)  
**Date:** 2026-09-09  
**Version:** 1.1 (post-validation session)  
**Status:** Pilot gaps reassessed; critical gaps now owned; severity corrections applied.

---

## Executive Summary

The system has **4 critical gaps**, **5 high-severity design gaps**, and **8 medium/low operational gaps** blocking GA. Session corrections: GAP-A1 impact rewritten (doesn't violate ADR-0002), GAP-A3 downgraded (PLAT-2101 covers it), GAP-A2 ownership assigned (Dana Whitfield), new findings identified (S-13 Slack Connect; S-3 decision formalization required).

---

## Architecture Gaps (Blocking GA)

### GAP-A1: Per-User Delegated OAuth (PLAT-2820)

**[SESSION: IMPACT CORRECTED]** Current state implements ADR-0002 (shared app); diverges from architecture page, not ADR

**Current State:** Shared app registration; all pilot users reach everything any pilot user can reach  
**Target State:** Per-user delegated OAuth for O365, Slack, GitHub  
**Ticket:** PLAT-2820 (blocked on Identity Platform, not scheduled)  

**Impact if Not Fixed:**
- Over-provisioned access (users reach resources they lack direct permission for)
- No attribution (actions attributed to service principal, not user)  
- GDPR non-compliance (no audit trail per user)

**Note:** ADR-0002 (March 2026) explicitly decided on shared app for pilot expedience. Current state does not violate the ADR. What it diverges from is Marcus's architecture page, which states "delegates via OAuth" in present tense, causing three people to believe per-user delegation was already implemented.

**Remediation Cost:** High | **Owner:** Identity Platform | **Status:** ⏳ Planned (not scheduled) | **Session Note:** [Confirmed critical; corrects documentation misalignment]

---

### GAP-A2: Provider Rate Limit Fallback Violates DPA (ADR-0006)

**[SESSION: OWNER ASSIGNED]** Previously unassigned ("nobody owns chasing it"); Dana Whitfield now owns

**Current State:** Falls back to public endpoint when enterprise returns 429  
**Target State:** Enterprise endpoint only OR quota increase provided  
**Ticket:** ADR-0006 revert (nobody owned quota increase chase)  

**Impact if Not Fixed:**
- Prompts sent to public endpoint without DPA coverage
- Data protection violation during peak load (exactly when breach risk highest)
- Volume inverse: maximum data at risk exactly when urgent to fix

**Mitigation Plan (Session):**
1. Fail closed on 429 (this sprint) — Priya implements  
2. Chase vendor quota increase (by 2026-09-30) — Dana owns

**Remediation Cost:** Medium | **Owner:** Dana Whitfield | **Status:** ⏳ Fail-closed implementation this sprint; quota pursuit by 2026-09-30 | **Session Note:** [Owner assigned; removes unmitigated DPA breach vector]

---

### GAP-A3: Redis Transit Encryption (ADR-0008)

**[SESSION: SEVERITY DOWNGRADED]** GA cluster has PLAT-2101 (network policy); not blocking

**Current State:** Transit encryption disabled; no auth token; relies on security group  
**Target State:** Transit encryption enabled OR network policy + default-deny  
**Ticket:** None (technical debt; covered by PLAT-2101 on GA)  

**Impact if Not Fixed (Beta):**
- Conversation state unencrypted in transit
- Anyone in cluster can read Redis traffic
- Not IP-restricted if cluster shared with untrusted workloads

**Impact (GA):** Mitigated by PLAT-2101 network policy enabled on GA cluster

**Status:** ⏳ Planned for GA | **Owner:** Platform | **Due:** GA | **Session Note:** [Downgraded from blocking; GA platform standard covers it. Beta remains unmitigated; acceptable for pilot scope.]

---

### GAP-A4: Network Policy Disabled on Beta Cluster

**Current State:** Feature disabled on beta; any pod can reach any port  
**Target State:** Network policy enabled with default-deny + explicit allows  
**Ticket:** PLAT-2101 (platform standard; status: cluster feature not enabled)  

**Impact if Not Fixed:**
- Compromised pod can reach Redis, assistant-svc, etc.
- Blast radius: entire cluster
- Violates platform standard

**Status:** ⏳ Planned for GA | **Owner:** Platform SRE | **Due:** GA | **Note:** GA cluster has feature; beta does not.

---

## Design Gaps (Must Resolve Before GA)

### GAP-D1: No Output Filtering for Tool Arguments (SUC-001)

**[SESSION: SCOPED]** Phase 1: `post_message` + `send_email`; Phase 2: `commit_code`

**Current State:** Model generates arguments; connector API validates only  
**Target State:** Application layer validates before execution; rejects suspicious patterns  
**Ticket:** SUC-001

**Phase 1 Scope (Before GA):** post_message, send_email (high volume, external reach)  
**Phase 2 Scope:** commit_code (branch protection provides safety; lower priority)

**Remediation Cost:** Medium | **Owner:** Priya Raghunathan | **Status:** ⏳ Before GA

---

### GAP-D2: No GDPR Data Subject Rights Flow

**Current State:** No mechanism for users to access, delete, or export conversations  
**Target State:** UI/API to list, export, and delete conversations (including backup purge)  
**Ticket:** None (open question)

**GDPR Articles:** 15 (access), 17 (erasure), 20 (portability)

**Remediation Cost:** High | **Owner:** Product + Engineering | **Status:** ⏳ Not yet scheduled

---

### GAP-D3: No Input Validation on Workspace Instructions

**Current State:** Admin injects arbitrary text into system prompt; no length limit  
**Target State:** Validation on length and allowed constructs; audit trail  
**Ticket:** None (accepted for pilot; revisit for multi-tenant)

**Status:** ✅ Acceptable (pilot); ⏳ Planned (for Phase 2 multi-tenant)

---

### GAP-D4: No Audit Trail for Redis Access

**Current State:** Reads/writes not logged; cannot detect unauthorized access  
**Target State:** Access logs for conversation retrieval/modification  
**Ticket:** None (logging strategy not documented)

**Status:** ⏳ Before GA

---

### GAP-D5: No Tool Description Pinning

**Current State:** Tool descriptions loaded from MCP servers at runtime  
**Target State:** Tool descriptions pinned; verified against expected hash on load  
**Ticket:** None (supply chain risk)

**Status:** ⏳ Before GA (same action as S-5 pinning)

---

## Operational Gaps (Before GA or Phase 2)

### GAP-O1: Incident Response Plan

**Status:** ⏳ Before Phase 2 expansion (unattended operation)

---

### GAP-O2: Monitoring & Alerting

**Status:** ⏳ Before GA (security signals)

---

### GAP-O3: Compliance Test Plan

**Status:** ⏳ Before GA (TA-001 to TA-032; QA to pickup per document 05)

---

### GAP-O4: Dependency Scanning for Node

**[SESSION: CORRECTED]** Go scanned; Node not covered (PLAT-2077 open)

**Current State:** Shared CI templates scan Go only; Node not covered  
**Ticket:** PLAT-2077

**Status:** ⏳ Open | **Owner:** Kwame Osei | **Due:** 2026-09-30

---

### GAP-O5: Debug Routes Undocumented

**[SESSION: ESCALATED]** No one can describe what routes return; runbook depends on them

**Current State:** `EXPOSE_DEBUG_ROUTES` intentionally unset; runbook uses them; functionality unknown  
**Target State:** Enumerate routes; document or remove runbook dependency  
**Ticket:** None

**Status:** ⏳ Urgent | **Owner:** Priya Raghunathan | **Due:** 2026-09-30

---

### GAP-O6: Shared Mailbox Data Processing Not Cleared

**[SESSION: DEADLINE MOVED]** From Phase 2 to pilot renewal (2026-10-31)

**Current State:** Support reads shared mailbox; GDPR lawful basis not settled  
**Ticket:** GAP-O6 (legal clearance required)

**Status:** ⏳ Deferred | **Owner:** Ines Ferreira | **Due:** 2026-10-31 (pilot renewal) | **Note:** Processing is happening now, not before Phase 2. Deadline accelerated.

---

## Compliance Gaps

### GDPR (Data Subject Rights, Consent, Transparency)

**Status:** ❌ Not compliant; requires lawful basis review, data subject rights implementation, privacy notice

---

### NIS2 (Applicability & Obligations)

**[SESSION: REVISED]** Not org-level assessment; customer contract obligations apply

**Current State:** Org not NIS2 entity; two customers are and flow obligations down  
**Ticket:** COMP-008 (reopened with different scope)

**Status:** ⏳ Contract review | **Owner:** Ines Ferreira | **Due:** 2026-09-30

---

### CRA (EU Cyber Resilience Act)

**Status:** ✅ Out of scope (pure SaaS deployment)

---

## Remediation Roadmap

### This Sprint
- Fail closed on 429 (ADR-0006 mitigation)
- List Slack Connect channels and test reachability

### Before GA (Next 4-8 Weeks)
- PLAT-2820: Per-user delegated OAuth
- SUC-001: Tool argument validation (`post_message`, `send_email`)
- Image URL sanitization (extend web-search sanitizer)
- Pin all connectors to explicit versions (remove `latest`)
- PLAT-2101: Network policy on GA cluster
- GAP-D2: GDPR data subject rights flows
- Privacy notice (S-11)
- Test plan pickup by QA

### Before Phase 2 (Unattended Operation)
- Monitoring & alerting for security signals
- Incident response playbook
- Strengthen prompt injection defenses
- Phase 2 of tool argument validation (`commit_code`)

---

v1.1 Complete. Critical gaps now owned. Severity corrections applied. Ready for execution.
