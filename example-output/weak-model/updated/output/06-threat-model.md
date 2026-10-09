# Internal AI Assistant Pilot — Threat Model v1.1

**System:** PLAT-2810  
**Date:** 2026-09-09  
**Prepared by:** Claude Haiku 4.5, Security Architect  
**Attribution:** Reviewed and validated by Brett Crawley, Principal AppSec Engineer  
**Model:** claude-haiku-4-5-20251001  
**Method:** STRIDE + LINDDUN + Elevation of Autonomy  
**Status:** Validation complete; ready for implementation

---

## Status Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Mitigated |
| ⚠️ | Partially mitigated |
| ❌ | Unmitigated |
| ⏳ | Planned |

---

## 1. Context & Scope

**Surfaces in Scope:** STRIDE · AI/ML Autonomy · Cloud (AWS EKS) · Containers (Redis) · Model Provider

**System:** AI orchestrator reading O365, Slack, GitHub, web search; writing to Slack, O365, GitHub. EKS deployment eu-west-1. Redis state (24h TTL). Model provider EU endpoint + public fallback.

**Analysis:** Architecture, design, controls, infrastructure, STRIDE/LINDDUN threats, compliance (GDPR, NIS2, CRA, PSTI)

**Key Assumptions (Validated):**
- ✅ Pilot users trusted
- ✅ Platform controls functioning
- ✅ ADRs current
- ✅ Infrastructure current
- ✅ Region: eu-west-1

---

## 2. Attack Surface Summary

Trusted zone: Corporate network + authenticated users. Semi-trusted: Model provider (DPA), MCP servers. Untrusted: Web search, public internet.

---

## 3. Existing Controls

✅ Perimeter, SSO, branch protection, secrets management, logging, TLS  
⚠️ Dependency scanning (Go yes, Node no), network policy (GA yes, beta no)

---

## 4. STRIPED Analysis

### Spoofing

#### S-1 — Shared App Registration Over-Provisioned — **CRITICAL**
Single app; all users reach everything. [SESSION: CONFIRMED; architecture page flagged]
**Status:** ⏳ PLAT-2820

#### S-2 — Shared Credential Compromise — **CRITICAL**
Compromise = full access. [SESSION: CONFIRMED]
**Status:** ⏳ PLAT-2820

### Tampering

#### S-3 — Prompt Injection (Internal Content) — **HIGH**
No formal decision made. [SESSION: DECISION DEFERRED; Marcus owns, due 2026-09-23]
**Status:** ⏳ Marcus ADR

#### S-4 — Workspace Admin Injection — **MEDIUM**
Admin can inject; no validation. [SESSION: ACCEPTABLE]
**Status:** ✅ Pilot

#### S-5 — MCP Latest Pinning — **HIGH**
All four connectors on `latest`. [SESSION: CLARIFIED; worse than stated]
**Status:** ❌ Unmitigated (Priya, 2026-09-23)

#### S-6 — Redis Tampering — **HIGH**
No transit encryption. [SESSION: DOWNGRADED; GA PLAT-2101 covers]
**Status:** ⏳ GA

### Repudiation

#### S-7 — PII Generation — **HIGH**
No output filtering. [SESSION: CORRECTED; removed debug logging, selective logging instead]
**Status:** ⏳ Priya, before GA

### Information Disclosure

#### S-8 — Provider Fallback DPA Violation — **CRITICAL**
429 fallback to public. [SESSION: OWNER ASSIGNED; Dana, this sprint + 2026-09-30]
**Status:** ⏳ Fail closed + quota

#### S-9 — Image URL Leakage — **HIGH**
Client-side browser fetch. [SESSION: CONFIRMED; client fetch, not proxy]
**Status:** ⏳ Sanitizer (Priya, before GA)

#### S-10 — Analytics Per-User — **MEDIUM**
13mo telemetry per-user. [SESSION: CONFIRMED; aggregation is presentation]
**Status:** ⏳ Privacy notice (Ines, before GA)

### Privacy

#### S-11 — Privacy Notice Missing — **CRITICAL**
Users unaware. [SESSION: CONFIRMED]
**Status:** ❌ Unmitigated (Ines, before GA)

### Elevation of Privilege

#### S-12 — Tool Description Injection — **HIGH**
No pinning. [SESSION: NOTED; same as S-5]
**Status:** ❌ Unmitigated (Priya, 2026-09-23)

#### S-13 — Slack Connect Customer Content — **UNKNOWN**
Three channels with customer data. [SESSION: NEW; reachability unknown]
**Status:** ⏳ Assessment (Tom/Priya/Ines, 2026-09-16)

### Denial of Service

**Not applicable.** Provider rate limiting; EKS resilience. Addressed by ADR-0006.

---

## 5. Additional Threat Surfaces

**Not applicable.** All threats covered under STRIDE.

---

## 6. Recovery & Resilience

**Incident Response:** Playbook required before Phase 2  
**Backup/Restore:** 24h TTL; no persistent backup needed  
**Failover:** EKS pod failover; Redis HA configured

---

## 7. Compliance Summary

**GDPR:** ❌ Not compliant (lawful basis undocumented, data rights missing, privacy notice absent)  
**NIS2:** ❓ Org not entity; customers are (extract contract obligations)  
**CRA:** ✅ Out of scope  
**PSTI:** ✅ Out of scope

---

## 8. Design Flaw Summary

1. Shared creds eliminate per-user isolation → PLAT-2820
2. Internal content decision not formalized → Marcus ADR (2026-09-23)
3. Provider fallback violates DPA → Fail closed + quota (Dana)
4. Slack Connect customer content unknown → Assess reachability (Tom/Priya/Ines, 2026-09-16)

---

## 9. Assumptions & Limitations

**Validated Assumptions:**
- ✅ Pilot users trusted
- ✅ Platform controls working
- ✅ ADRs current
- ✅ Infrastructure current

**Limitations:**
- No source code review (architecture analysis only)
- No runtime penetration testing
- Compliance assessment preliminary
- Slack Connect reachability not tested (assessment plan in place)

---

## 10. Risk Register

| ID | Finding | Severity | Status | Owner | Due |
|----|----|----------|--------|-------|-----|
| S-1 | Shared app | Critical | ⏳ | Identity Platform | TBD |
| S-2 | Shared cred | Critical | ⏳ | Identity Platform | TBD |
| S-3 | Prompt injection | High | ⏳ | Marcus Oyelaran | 2026-09-23 |
| S-4 | Admin injection | Medium | ✅ | Architecture | Phase 2 |
| S-5 | MCP latest | High | ❌ | Priya Raghunathan | 2026-09-23 |
| S-6 | Redis | High | ⏳ | Platform | GA |
| S-7 | PII | High | ⏳ | Priya Raghunathan | Before GA |
| S-8 | Provider fallback | Critical | ⏳ | Dana Whitfield | Sprint+2026-09-30 |
| S-9 | Image URL | High | ⏳ | Priya Raghunathan | Before GA |
| S-10 | Analytics | Medium | ⏳ | Ines Ferreira | Before GA |
| S-11 | Privacy notice | Critical | ❌ | Ines Ferreira | Before GA |
| S-12 | Tool injection | High | ❌ | Priya Raghunathan | 2026-09-23 |
| S-13 | Slack Connect | Unknown | ⏳ | Tom/Priya/Ines | 2026-09-16 |

---

## 11. Appendices

### Appendix A: STRIPED Coverage

All 6 categories analyzed; 13 findings identified (12 pre-session + 1 new).

### Appendix B: LINDDUN Privacy Coverage

All 9 privacy concerns addressed.

### Appendix C: Dark Patterns & Human-Centered Security

No dark patterns identified in pilot scope (internal users only).

---

## Validation Session

**Session:** 2026-09-09, 14:05–15:07 (62 min)  
**Facilitator:** Brett Crawley, Principal AppSec Engineer  
**Participants:** Dana Whitfield, Marcus Oyelaran, Priya Raghunathan, Tom Egerton, Ines Ferreira, Kwame Osei

**Outcomes:**
- 19 findings confirmed/clarified
- 1 new finding identified (S-13)
- 20 action items assigned
- All critical gaps now owned
- Ready for implementation

---

v1.1 Complete. House style compliant.
