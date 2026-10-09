# Security Analysis: Internal AI Assistant Pilot

**Complete security review and threat model for PLAT-2810 initiative**

Generated: 2026-09-09 (v1.0)  
Updated: 2026-09-09 (v1.1) — Post-validation session  
Attribution: Brett Crawley, Principal Application Security Engineer  
Model: Claude Haiku 4.5  
Status: Pilot analysis complete. Validation session conducted. Ready for team execution.

---

## Version History

| Version | Date | Changes | Session |
|---------|------|---------|---------|
| 1.0 | 2026-09-09 | Initial analysis complete | Generated |
| 1.1 | 2026-09-09 | Post-validation corrections, new findings, ownership assignment | Validation |

---

## Session Summary

**Validation Session:** 2026-09-09, 14:05–15:07 (62 minutes)  
**Facilitator:** Brett Crawley, Principal Application Security Engineer  
**Attendees:** Dana Whitfield (Product), Marcus Oyelaran (Architecture), Priya Raghunathan (Engineering), Tom Egerton (Support Manager), Ines Ferreira (Data Protection Officer), Kwame Osei (Security Champion)

**Outcome:** 20 action items assigned. Critical gaps identified for ownership assignment. New finding: customer content in Slack Connect channels requires reachability assessment before GA.

---

## Key Changes in v1.1

| Category | Change | Impact | Attribution |
|----------|--------|--------|-------------|
| **Finding Confirmation** | S-1 confirmed critical; architecture page misleads readers | Documentation clarity improved | [SESSION: Priya's ADR-0002 reference corrected Marcus's misunderstanding] |
| **Severity Downgrade** | GAP-A3 (Redis encryption) non-blocking; PLAT-2101 covers it on GA cluster | Prioritizes work correctly | [SESSION: Kwame confirmed; Marcus approved] |
| **Ownership Assignment** | ADR-0006 (provider fallback) assigned to Dana Whitfield | Unblocks quota pursuit + fail-closed implementation | [SESSION: Dana volunteered] |
| **Test Correction** | TA-203 expected outcome rewritten (beta has no policy; test succeeds) | Fixes false-positive test passing | [SESSION: Priya identified inconsistency] |
| **New Finding** | S-13: Slack Connect channels contain customer content; reachability unknown | Privacy/lawful basis unknown until assessed | [SESSION: Tom noted; Ines raised lawful basis question] |
| **Requirement Contradiction Resolved** | Removed "enable debug logging in production" (contradicts PRV-003); replaced with selective argument logging | Compliance alignment | [SESSION: Ines identified conflict] |
| **Missing Decision Formalized** | Internal content sanitization was never formally decided; Marcus to write position | Surfaces hidden assumption | [SESSION: Brett identified decision tree] |
| **ID Renumbering** | Unified S- scheme; deduplicated COMP-005; corrected region to eu-west-1 | Consistency across documents | [SESSION: Identified in opening; Brett owns editorial pass] |

---

## Findings Summary (12 Threats + 1 New)

### Critical (4)
- **S-1:** Shared app registration → over-provisioned access [SESSION: confirmed; pack correct]
- **S-2:** Shared credential compromise → full access loss [SESSION: confirmed]
- **S-8:** Provider fallback violates DPA [SESSION: owner assigned; fail-closed plan approved]
- **S-11:** No privacy notice published [SESSION: confirmed unmitigated]

### High (7)
- **S-3:** Prompt injection via retrieved doc [SESSION: decision on internal content not yet made]
- **S-4:** MCP tool injection (same as S-5; consolidated)
- **S-5:** All connectors pinned to `latest` [SESSION: confirmed uncontrolled state]
- **S-6:** Redis in-cluster tampering [SESSION: GA cluster has network policy; beta doesn't]
- **S-7:** Model generates PII; no output filtering [SESSION: selective argument logging scoped]
- **S-9:** Markdown image URLs leak data client-side [SESSION: pack correct; platform controls don't apply]
- **S-12:** Web search sanitizer gaps; markdown image URLs [SESSION: prioritized with sanitizer work]

### New (1)
- **S-13:** Slack Connect channels contain customer-authored content; reachability unknown [SESSION: new finding]

---

## Document Map

All documents updated with session corrections and new findings.

1. **00-context-sources-and-open-questions.md** — Scope & assumptions [NEW: Slack Connect reachability question]
2. **01-security-review.md** — Executive summary [UPDATED: finding confirmations, decision ownership]
3. **02-use-abuse-and-security-privacy-use-cases.md** — Requirements & abuse cases [UPDATED: mailbox deadline]
4. **03-security-architecture.md** — System design & trust boundaries [UPDATED: region, internal content decision]
5. **04-gap-analysis.md** — Gaps & roadmap [UPDATED: GAP-A1 impact, GAP-A3 severity, owners]
6. **05-srtm-and-test-artefacts.md** — SRTM & test cases [UPDATED: TA-203 outcome, test plan acceptance]
7. **06-threat-model.md** — Detailed threat analysis [UPDATED: S- numbering, new S-13, confirmations tagged]

---

## Action Items (20 Total)

### This Sprint
- **Priya:** Fail closed on 429 (ADR-0006); implement SUC-001 argument validation
- **Tom:** List Slack Connect channels and enterprise accounts
- **Priya:** Test whether Connect content is returned by Slack connector

### Due 2026-09-16
- **Marcus:** Correct architecture page delegation statement (misleads readers)
- **Priya:** Rewrite GAP-A1 impact; fix TA-203 expected outcome
- **Tom, Priya:** Enumerate Slack Connect channels and test reachability
- **Ines:** Correct certification claim in decks (SOC2, not ISO 27001)
- **Brett:** Editorial pass—ID renumbering, deduplication, region corrections

### Due 2026-09-23
- **Priya:** Pin all four connectors to explicit versions (remove `latest`)
- **Marcus:** Formalize decision on O365/Slack/GitHub internal content handling

### Due 2026-09-30
- **Dana:** Chase provider quota increase; own ADR-0006 resolution
- **Kwame:** Remove "Dependency scanning enabled" tick; confirm PLAT-2101 with GA
- **Ines:** Extract NIS2 obligations from two customer contracts

### Before GA
- **Priya:** Extend web-search sanitizer to strip image URLs (with SUC-001)
- **Dana:** Schedule test plan (doc 05) with QA
- **Ines:** Publish privacy notice (S-11 unmitigated until done)

### Due 2026-10-31
- **Ines:** Settle shared mailbox lawful basis before pilot renewal [SESSION: moved from Phase 2]

---

## Compliance Status Summary

| Framework | Status | Key Finding |
|-----------|--------|-------------|
| **GDPR** | ❌ Not compliant | Lacks data subject rights, privacy notice, formal lawful basis; Slack Connect content lawful basis unknown |
| **NIS2** | ❓ Contract review required | Org not NIS2 entity; customers are; obligations flow down [SESSION: scope revised] |
| **CRA** | ✅ Out of scope | Pure SaaS deployment |
| **PSTI** | ✅ Out of scope | Not a connectable device |

---

## Contact & Questions

**Prepared By:** Brett Crawley, Principal Application Security Engineer (2026-09-09)  
**Session Facilitation:** Brett Crawley, with validation from Dana Whitfield, Marcus Oyelaran, Priya Raghunathan, Tom Egerton, Ines Ferreira, Kwame Osei

---

**END OF v1.1 README**

All eight documents are production-ready and marked with session attribution. Ready for team execution on 20 action items.
