# Security Analysis: Internal AI Assistant Pilot

**Complete security review and threat model for PLAT-2810 initiative**

Generated: 2026-09-09  
Attribution: Brett Crawley, Principal Application Security Engineer  
Model: Claude Haiku 4.5  
Status: Pilot analysis complete. Ready for team review.

---

## Document Map

Read these in order:

### 1. **00-context-sources-and-open-questions.md** — START HERE
   - What context was provided vs. what's missing
   - Assumptions made for the analysis
   - Open questions requiring escalation
   - **Time to read:** 10 min

### 2. **01-security-review.md** — EXECUTIVE SUMMARY
   - 3-4 paragraph security posture assessment
   - Key findings by category (planned, partial, unmitigated)
   - Immediate actions and risk assessment
   - **Read this if:** You have 5 minutes or are not technical
   - **Time to read:** 5 min

### 3. **02-use-abuse-and-security-privacy-use-cases.md** — REQUIREMENTS
   - 5 primary use cases (UC-001 to UC-005)
   - 5 security abuse cases (SAC-001 to SAC-005)
   - 4 privacy abuse cases (PAC-001 to PAC-004)
   - 11 counter-use cases (mitigation strategies)
   - **Read this if:** You want to understand what the system does and what could go wrong
   - **Time to read:** 20 min

### 4. **03-security-architecture.md** — SYSTEM DESIGN
   - System context diagram (C4 L1)
   - Component decomposition (C4 L2-3)
   - Data flows with trust zones
   - Control architecture (identity, encryption, network, logging)
   - Data model (Redis schema, warehouse telemetry)
   - Security implications of each ADR
   - Assessment against security principles
   - Architecture gaps and required changes
   - **Read this if:** You want to understand the system design and trust boundaries
   - **Time to read:** 30 min

### 5. **04-gap-analysis.md** — WHAT'S MISSING
   - 4 architecture gaps (blocking GA)
   - 6 design gaps (must resolve before GA)
   - 8 operational gaps (before GA or Phase 2)
   - 8 compliance gaps (GDPR, CRA, NIS2, PSTI assessment)
   - Remediation roadmap (immediate, before GA, before Phase 2)
   - **Read this if:** You're planning the work to close security gaps
   - **Time to read:** 15 min

### 6. **05-srtm-and-test-artefacts.md** — TESTING & COMPLIANCE
   - Security Requirements Traceability Matrix (35 requirements)
   - 24 test artifacts (functional, attack, privacy, pen test)
   - Coverage: every requirement links to tests
   - **Read this if:** You're building the test plan or tracking compliance
   - **Time to read:** 20 min

### 7. **06-threat-model.md** — DETAILED THREATS
   - 11 STRIDE threats (detailed with examples, mitigations, residual risk)
   - 8 LINDDUN privacy threats
   - Elevation of Autonomy analysis (AI-specific threats)
   - Full risk register with 20 findings
   - Design flaws requiring architectural change
   - **Read this if:** You want deep threat analysis
   - **Time to read:** 30 min

---

## Quick Reference: Key Findings

### Blocking Gaps for GA (Must Fix)

| Gap | Impact | Owner | Status |
|-----|--------|-------|--------|
| **PLAT-2820** Per-user OAuth | Over-provisioned access; no attribution | Identity Platform | Not scheduled |
| **ADR-0006 Revert** Provider fallback | DPA violation; data sent to public endpoint | Finance/Eng | Quota pending |
| **GAP-D2** GDPR Data Rights | Users can't access/delete their data | Product/Eng | [NEW] |
| **ST-005** Redis encryption | Conversation state readable in-cluster | Eng | Plan for GA |
| **ST-001** Prompt injection mitigation | Tool argument validation | Eng | Plan for GA |

### Critical Findings (Severity: Critical)

| Finding | Threat | Current Status | Mitigation | ETA |
|---------|--------|----------------|-----------|-----|
| ST-002 | Over-provisioned access | Partial (pilot only) | PLAT-2820 delegation | TBD |
| ST-003 | Shared credential compromise | Partial (limited scope) | PLAT-2820 + monitoring | TBD |
| ST-004 | Provider fallback outside DPA | Unmitigated | Quota increase or hard fail | TBD |
| PT-007 | GDPR non-compliance | Unmitigated | Data subject rights flow | GA |

### High Findings (Severity: High) — 7 total

- ST-001: Prompt injection (human present mitigates pilot)
- ST-005: Redis compromise (network policy mitigates)
- ST-006: MCP server compromise (pinning required)
- ST-007: Model generates PII (output filtering required)
- PT-005: Data disclosure to provider (DPA required)
- PT-006: User unawareness (privacy notice required)
- EoA·SA, EoA·SK, EoA·T3: AI-specific threats (human presence mitigates pilot)

---

## Readiness Assessment

### ✅ Acceptable for Pilot (21 Users, Human Present)

- Shared app registration (instead of per-user OAuth)
- Actions without pre-confirmation
- Web console behind VPN with shared password
- No pre-action confirmation

**Justification:** Limited user group (trusted employees), human present for every turn, post-hoc visibility of actions. Risk is bounded by scope and process.

### ⏳ Planned Mitigations (In Tickets, Scheduled for GA)

- PLAT-2820: Per-user delegated OAuth (blocked on Identity Platform, not scheduled)
- PLAT-2814-6: Narrow Slack scopes (not scheduled)
- PLAT-2831-3: Web console SSO (not scheduled)
- PLAT-2822-4: Spend alerting (not scheduled)
- ADR-0006 revert: Provider quota increase (no owner, pending)

### ❌ Unmitigated Design Flaws (Block GA)

1. **Shared credentials:** All pilot users reach everything any user can reach
   - Fix: PLAT-2820 per-user delegation
   - Impact: High (elevation of privilege)
   - Owner: Identity Platform
   - Status: Blocked (no schedule)

2. **Provider fallback:** Sends data to public endpoint outside DPA during peak load
   - Fix: Increase quota or fail closed on rate limit
   - Impact: Critical (data protection violation)
   - Owner: Unassigned
   - Status: Pending (no ETA)

3. **No GDPR data subject rights:** Cannot comply with access/erasure/portability
   - Fix: Design and implement flows
   - Impact: Critical (legal/compliance)
   - Owner: Product/Eng
   - Status: [NEW] Not yet scheduled

---

## Compliance Summary

### GDPR Compliance: ❌ Not Yet Compliant

| Requirement | Status | Action |
|-------------|--------|--------|
| Lawful basis documented | ⏳ Planned | Legal review of "legitimate interest" |
| Data subject access (Art. 15) | ❌ Missing | Implement access API (GAP-D2) |
| Right to erasure (Art. 17) | ❌ Missing | Implement deletion + backup purge (GAP-D2) |
| Right to portability (Art. 20) | ❌ Missing | Implement export API (GAP-D2) |
| Data minimisation (Art. 5(1)(c)) | ⚠️ Partial | Output filtering required |
| Transparency (Art. 13/14) | ❌ Missing | Publish privacy notice |
| DPA with processor (Art. 28) | ⚠️ Partial | Verify DPA covers fallback endpoint |

**Summary:** System is not GDPR-compliant as-is. Requires lawful basis review, data subject rights implementation, and privacy notice before processing real data.

### CRA (EU Cyber Resilience Act): ✅ Out of Scope
- This is pure SaaS (no downloadable/embedded software)
- Not subject to CRA as currently deployed
- Re-assess if client-side component is added

### NIS2: ❓ Requires Organisational Assessment
- Applies only if organisation is "essential" or "important" entity
- Not assessed here; requires legal/compliance input

### UK PSTI: ✅ Out of Scope
- Not a consumer connectable device

---

## Recommended Reading by Role

### Product Owner / Stakeholder
1. 01-security-review.md (executive summary)
2. 04-gap-analysis.md (what needs to be built)
3. Sections on "Compliance Summary" and "Readiness Assessment" above

**Time:** 20 minutes

### Engineering Lead
1. 00-context-sources-and-open-questions.md (scope)
2. 03-security-architecture.md (system design, gaps)
3. 04-gap-analysis.md (prioritized work)
4. 05-srtm-and-test-artefacts.md (testing strategy)

**Time:** 60 minutes

### Security Architect / CISO
1. All documents in order
2. Special attention to: 03-security-architecture.md (design), 06-threat-model.md (detailed threats)
3. Design Flaws section in 06-threat-model.md

**Time:** 90 minutes

### Compliance / Legal
1. 04-gap-analysis.md (Compliance Gaps section)
2. 06-threat-model.md (Privacy threats PT-001 to PT-008)
3. 05-srtm-and-test-artefacts.md (COMP requirements)
4. Sections on "Compliance Summary" above

**Time:** 45 minutes

---

## Next Steps

### Immediate (This Week)

1. **Assign Owner to ADR-0006:** Finance + Platform Engineering to chase provider quota increase
2. **Triage Blockers:** Confirm PLAT-2820 and GAP-D2 are on engineering roadmap
3. **Legal Review:** Confirm lawful basis for processing (legitimate interest vs. consent)

### Before GA (Next 4-8 Weeks)

1. **Complete PLAT-2820:** Per-user delegated OAuth for all connectors
2. **Implement SUC-001:** Tool argument validation to prevent prompt injection
3. **Close ADR-0006:** Either increase provider quota or remove fallback
4. **Implement GAP-D2:** GDPR data subject rights flows (access, erasure, portability)
5. **Enable Encryption:** Redis transit encryption or network policy
6. **Publish Privacy Notice:** Legal review + transparency documentation

### Before Phase 2 Expansion (Before Unattended Operation)

1. Strengthen prompt injection defenses (SUC-001 + confirmation gates)
2. Implement monitoring and alerting for security signals
3. Create incident response playbook
4. Assess AI governance requirements (PR-03 at portfolio level)

---

## Scope and Limitations

**Analysis Scope:**
- Covered: Architecture, design decisions, documented controls, code/IaC
- Covered: STRIDE threats, LINDDUN privacy threats, Elevation of Autonomy
- Covered: Compliance (GDPR, CRA, NIS2, PSTI applicability)
- Not Covered: Source code line-by-line review (architecture and design-level only)
- Not Covered: Formal proof of security properties
- Not Covered: Runtime penetration testing

**Limitations:**
- Token limits required condensing SRTM and threat model
- Full source code not reviewed (assumptions based on architecture and ADRs)
- Compliance assessment is preliminary (requires legal input)
- Some evidence is from documentation (may diverge from runtime behavior)

**Assumptions:**
- Pilot users are trusted corporate employees
- Platform controls (perimeter, egress proxy, SSO) are functioning as documented
- ADRs represent actual implementation decisions
- IaC (Terraform, Helm) is current

---

## Metrics

**Coverage:**
- 5 primary use cases documented
- 5 security abuse cases (SAC-001 to SAC-005)
- 4 privacy abuse cases (PAC-001 to PAC-004)
- 11 counter-use cases (mitigation strategies)
- 20 total findings (11 STRIDE + 8 LINDDUN + 1 multi-category)
- 35 security/privacy requirements (FR, SEC, PRV, COMP)
- 24 test artifacts
- 18 gaps identified (4 architecture, 6 design, 8 operational)

**Findings Breakdown:**
- Critical: 3 (ST-002, ST-003, ST-004 + PT-007)
- High: 7 (ST-001, ST-005, ST-006, ST-007, PT-005, PT-006, + AI-specific)
- Medium: 8 (ST-008, ST-009, ST-010, ST-011, PT-001, PT-002, PT-008, + context growth)
- Low: 2 (ST-011 debug routes, PT-003 non-repudiation)

**Mitigations:**
- 3 Critical findings unmitigated
- 7 High findings partially mitigated (6 require design work, 1 in tickets)
- 8 Medium findings mitigated or acceptable
- 2 Low findings acceptable

---

## Contact & Questions

**Review Prepared By:**  
Brett Crawley, Principal Application Security Engineer

**Date:** 2026-09-09

**For Questions:**
- Security & Architecture: See 03-security-architecture.md
- Threats & Mitigations: See 06-threat-model.md
- Compliance: See 04-gap-analysis.md (Compliance section)
- Testing & Traceability: See 05-srtm-and-test-artefacts.md

---

## Session Participants & Attribution

**Analysis Conducted By:**
- Claude Haiku 4.5 (Security Architect, Threat Modeler)

**Skills & Frameworks Used:**
- /secure-privacy-by-design (STRIDE, LINDDUN, GDPR, CRA, NIS2, PSTI)
- /security-architect (Architecture design, SOLID, security principles)
- /threat-modeling (STRIDE/LINDDUN analysis, risk register, design flaws)
- Elevation of Autonomy deck (AI-specific threats)
- OWASP Top 10 / ASVS (web security baseline)

**Sessions:**
- Single integrated review session (2026-09-09)
- All documents cross-referenced with finding IDs and ticket references

---

**END OF ANALYSIS PACKAGE**

All documents are production-ready. Ready for team review and decision-making on GA readiness.

