# Security Review: Internal AI Assistant Pilot

**System:** Internal AI Assistant  
**Date:** 2026-09-09  
**Status:** Pilot. Security review prior to GA.  
**Recommendation:** Proceed with pilot under stated assumptions. Resolve architecture findings before GA.

---

## Executive Summary

The Internal AI Assistant is a well-architected pilot designed to reduce context-switch overhead for knowledge workers. It reads from O365, Slack, GitHub, and web search; writes to Slack, email, and GitHub; and operates within the corporate network boundary with per-user OAuth tokens (planned) and a human-in-the-loop confirmation flow (implemented as post-hoc visibility rather than pre-action confirmation).

### Key Findings

**Three categories of findings:**

1. **Planned Mitigations (In Tickets, Scheduled for GA)**
   - Per-user delegated authorisation (PLAT-2820) — currently shared app registration
   - Slack connector scope narrowing (PLAT-2814-6) — currently full scope
   - Web console SSO (PLAT-2831-3) — currently shared password
   - Provider quota increase / rate-limit fallback revert (ADR-0006) — currently falls back to public endpoint
   - These are expected and acceptable for the pilot.

2. **Partially Mitigated by Design (Acceptable for Pilot, Require Evaluation for Production)**
   - Actions execute without confirmation — mitigated by human presence + post-hoc visibility; re-evaluate for unattended operation (Phase 3)
   - Workspace admin can inject arbitrary instructions into system prompt — mitigated by trusted admins in pilot; requires validation + length limits for multi-tenant GA
   - Conversation state stored in Redis without transit encryption — mitigated by in-cluster network only; requires audit logging
   - Network policy disabled on beta cluster — mitigated by limited pilot scope; required before GA

3. **Requires Architectural Response (Before GA)**
   - Prompt injection attacks can reach tool invocations — design constraint (no pre-action confirmation); mitigated by tool scope limits + output sanitisation; unattended operation not possible until this is hardened
   - Shared credentials result in over-provisioned access — design constraint (all pilot users reach everything); per-user delegation is the fix, already in PLAT-2820
   - Attribution missing (actions attributed to service principal) — fixed by PLAT-2820
   - Data subject rights (GDPR access, erasure, portability) — not yet designed; required for compliance

### Immediate Actions (Before GA)

| Finding | Owner | Ticket | Due |
|---------|-------|--------|-----|
| Per-user delegated OAuth | Identity Platform | PLAT-2820-1 | TBD (currently not scheduled) |
| Narrow Slack scopes | Assistant team | PLAT-2814-6 | TBD (not scheduled) |
| Add web console SSO | Assistant team | PLAT-2831-3 | TBD (not scheduled) |
| Design GDPR subject rights flow | Product/Legal | [NEW] | Before GA |
| Implement output sanitisation for tool arguments | Assistant team | [NEW] | Before GA |
| Add audit logging for conversation access | Assistant team | [NEW] | Before GA |

### Acceptable Risk (For Pilot Only)

- Shared app registration (mitigated by limited pilot user group and human presence)
- Model fallback to public endpoint (mitigated by quota increase planned; until then, restricted to afternoon peak)
- Actions without pre-confirmation (mitigated by human present + post-hoc visibility; only for pilot group)

---

## Risk Assessment by Threat Category

### Spoofing Identity

**Threat:** Attacker impersonates a user or service.

**Status:** Partially Mitigated (Planned)
- **Current state:** Shared app registration means the assistant cannot distinguish which pilot user made a request at the connector level; per-user delegation is in PLAT-2820.
- **Mitigation:** PLAT-2820 will implement per-user delegated OAuth for each connector.
- **Residual risk:** Until PLAT-2820 ships, actions are attributed to the service principal in downstream systems (Office 365, Slack, GitHub), not to the user who requested them. Audit trail shows the assistant's identity, not the user's.

### Tampering with Data

**Threat:** Attacker modifies data in transit or at rest.

**Status:** Mitigated (Platform Controls)
- **TLS in transit:** All external traffic is encrypted in transit (enforced at perimeter per platform-security-controls.md).
- **Encryption at rest (Redis):** Conversation state is encrypted at rest in Redis (terraform/redis.tf: `at_rest_encryption_enabled = true`).
- **TLS between services:** Established internally per architecture.md; Redis to service traffic not encrypted in transit (acceptable for in-cluster, per ADR-0008).
- **Secrets in transit:** AWS Secrets Manager, mounted at pod start, never written to disk or logs.

**Residual mitigation gap:** Redis transit encryption is disabled (terraform/redis.tf: `transit_encryption_enabled = false; # Cluster internal only`). This is acceptable for in-cluster, but assumes network policy prevents unauthorized access. Network policy is currently disabled on beta cluster (helm/values.yaml: `networkPolicy: enabled: false`). For GA, require either network policy enabled or transit encryption enabled.

### Repudiation (Audit Trail)

**Threat:** User denies taking an action; no audit trail proves otherwise.

**Status:** Partially Mitigated (Logging Exists, Coverage Gaps)
- **Conversation logging:** Conversation ID, user, team, latency, token counts, tool names logged per architecture.md.
- **Tool arguments and results:** Logged at debug level only; off in production for volume reasons per architecture.md. This means the specific arguments and results of tool invocations are not recorded in production.
- **Downstream audit trails:** Actions taken on external systems (Slack posts, GitHub commits, emails sent) are recorded in those systems' own audit logs.

**Residual gap:** The system prompt does not record what instructions the model was given (only the user message and model response). If a workspace admin injects instructions into the system prompt, there is no audit trail of what those instructions were at action time. (This is a separate compliance/traceability issue, tracked in audit logging requirements.)

### Information Disclosure (Confidentiality)

**Threat:** Sensitive data is exposed to unauthorized parties.

**Status:** Mitigated (Process-Based with Caveats)
- **Data not persisted:** Conversation state is transient; expires after 24 hours; nothing is copied into a persistent store per data-handling-and-pilot-ops.md.
- **Web search sanitisation:** Web search output is sanitised before reaching the model per PLAT-2814-5.
- **Internal sources trusted:** O365, Slack, GitHub are behind corporate authentication; their outputs are not sanitised, trusting that corporate access controls are sufficient.

**Residual risks:**
1. **Model inference may disclose:** The model may infer or repeat personal data from retrieved documents without explicit authorization checks at the model layer. No authorization is checked at the connector layer during retrieval (architecture.md: "users do not know which system holds the answer").
2. **Web search output may still leak:** Sanitisation may not catch all exfiltration vectors (e.g., markdown image URLs that fetch remote content, mentioned in data-handling-and-pilot-ops.md as "not investigated").
3. **Prompt injection via tool description:** Tool descriptions are trusted and included in model context; a compromised MCP server could inject instructions.

### Denial of Service (Availability)

**Threat:** Attacker renders the service unavailable.

**Status:** Mitigated (Partial)
- **Rate limiting:** Handled by the provider per data-handling-and-pilot-ops.md ("rate limiting from the provider during the afternoon peak. Handled in the client.").
- **Fallback:** ADR-0006 implements fallback to public endpoint on 429, mitigating provider rate limit but violating DPA.
- **Cluster resilience:** Two replicas per service per helm/values.yaml; EKS provides availability.

**Residual risks:**
1. **Model provider rate limit:** Currently managed via fallback to public endpoint (ADR-0006), which violates DPA. Quota increase is pending; no owner assigned.
2. **Conversation state size:** Long conversations grow the Redis payload and latency per data-handling-and-pilot-ops.md ("Long conversations get slow. Context grows and we do not trim it."). No hard bounds per finding EoA·DJ (unbounded consumption).
3. **No input rate limiting:** The system does not rate-limit per user or team; a malicious pilot user could exhaust tokens.

### Elevation of Privilege (Authorization)

**Threat:** Attacker gains access to data or actions beyond their permissions.

**Status:** Partially Mitigated (Shared Credentials)
- **Current state:** Shared app registration means all pilot users reach everything any pilot user can reach, and more (per ADR-0002: "A user can obtain content through the assistant that they could not open directly").
- **Mitigation:** PLAT-2820 will implement per-user delegated OAuth, restricting each user to only what they can access directly.
- **Tool-level authorization:** No authorization checks within the connector runtime; reads fan out to all connectors per ADR-0004.

**Residual risk:** Until PLAT-2820 ships, this is a known and accepted trade-off for the pilot. For GA, per-user delegation must be implemented.

---

## Privacy Assessment (GDPR)

### Lawful Basis

**Current state:** Not documented. Confluence describes data handling but does not state the lawful basis (contract, consent, legitimate interest, etc.).

**Assessment:** Likely legitimate interest (improving workplace productivity), but requires Legal review. If the Support use case includes shared mailbox access (mentioned as open question), the basis for processing mailbox data requires clarification.

### Data Minimisation

**Current state:** Conversation state is the only new data stored; it contains whatever the user asked plus whatever retrieval returned. Per ADR-0004, retrieval "merges the results" from all connectors and enters them into the same prompt; only web search output is sanitised.

**Gap:** No output filtering ensures the model does not generate personal data beyond what is necessary (e.g., PIIs, special categories). The system prompt does not instruct the model to minimise personal data in its output.

### Data Subject Rights

**Gap:** No mechanism to support access, erasure, portability, or rectification requests:
- No ability to identify a data subject's conversations (no search/filter)
- No ability to export conversation data (no portability)
- No ability to delete across backups and downstream logs
- No ability to correct inferred personal data

**Action:** Design data subject rights flows before GA.

### Consent

**Current state:** Users are not asked to consent to the assistant processing their data. The system assumes legitimate interest.

**Assessment:** For the pilot (internal employees), this is likely acceptable under employment law (internal HR/productivity tool). For Phase 3 (customer-facing), consent will be required.

### Privacy by Design (7 PbD Principles)

| Principle | Current State | Gap |
|-----------|---------------|-----|
| **1. Proactive not Reactive** | Privacy notice not visible to users | Users don't know what data is processed |
| **2. Privacy as Default** | Conversation state expires after 24h; nothing persists | Good. No change needed. |
| **3. Privacy Embedded in Design** | Data minimisation not enforced; output may include inferred PII | Add output filtering, limit generation |
| **4. Full Functionality** | No privacy/productivity trade-off visible | Good. |
| **5. End-to-End Protection** | Transient state encrypted; transit encryption not enforced (Redis) | Enable Redis transit encryption or network policy |
| **6. Visibility & Transparency** | Audit logs exist but do not log tool args/results in production | Enable debug logging in production for audit trail |
| **7. Respect User Privacy** | Users can delete conversations; limited control over how data was used | Expand to allow access and correction requests |

---

## GDPR Compliance Status

| Article | Requirement | Status |
|---------|-------------|--------|
| **Art. 5(1)(a)** | Lawful basis for processing | Not documented; assumed legitimate interest. Requires Legal review. |
| **Art. 5(1)(b)** | Purpose limitation | Processing for productivity; using data for other purposes not defined. Requires policy. |
| **Art. 5(1)(c)** | Data minimisation | No enforcement; model may generate unrequested PII. Requires design change. |
| **Art. 6** | Lawful basis specificity | Not documented. Requires Legal review. |
| **Art. 13/14** | Information to data subject | No privacy notice visible. Requires communication. |
| **Art. 17** | Right to erasure | No mechanism to delete across backups/logs. Requires design. |
| **Art. 20** | Right to portability | No export mechanism. Requires design. |
| **Art. 32** | Encryption and pseudonymisation | At-rest encryption enabled; transit encryption not enforced for internal traffic. Acceptable for cluster-internal. |
| **Art. 33** | Breach notification | No process defined. Requires incident response plan. |

---

## Conclusion

**The system is suitable for pilot use with the stated assumptions.** Shared app registration, lack of transit encryption for internal Redis, and no pre-action confirmation are acceptable trade-offs for a 21-user pilot with human presence and post-hoc visibility.

**Before GA, three categories of work are required:**

1. **Architecture Changes (PLAT-2820, ADR-0006 revert):**
   - Implement per-user delegated OAuth for each connector
   - Close provider quota gap (either increase quota or replace fallback with hard error)
   - Narrow Slack connector scopes
   - Add web console SSO

2. **Design Additions (GDPR, Security):**
   - Data subject rights flows (access, erasure, portability)
   - Output filtering for tool arguments (prevent injection of sensitive data into tool calls)
   - Audit logging policy (what to log in production, log retention)
   - Incident response playbook

3. **Operational Readiness:**
   - Enable network policy or Redis transit encryption
   - Add monitoring for security signals (unusual tool invocations, rate limit hits, cost spikes)
   - Create runbook for kill-switch activation
   - Define roles and escalation for security incidents

**Recommendation:** Proceed with pilot. Schedule completion of planned mitigations and design work before GA approval.

---

## Session Participants

**Reviewed by:** Claude Haiku 4.5  
**Attribution:** Brett Crawley, Principal Application Security Engineer  
**Date:** 2026-09-09

