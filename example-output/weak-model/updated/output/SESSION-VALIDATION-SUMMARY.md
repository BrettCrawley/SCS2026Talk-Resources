# Validation Session Summary & Changes

**Date:** 2026-09-09  
**Duration:** 62 minutes (14:05–15:07)  
**Facilitator:** Brett Crawley, Principal Application Security Engineer  
**Participants:** Dana Whitfield (Product), Marcus Oyelaran (Architecture), Priya Raghunathan (Engineering), Tom Egerton (Support), Ines Ferreira (Compliance), Kwame Osei (Security Champion)

---

## Session Objective

Validate the 8-document security analysis package (v1.0) for PLAT-2810 Internal AI Assistant pilot. Confirm findings, clarify decisions, assign ownership, and identify gaps.

---

## Key Outcomes

### 1. Finding Confirmations (19 of 20 Tested)

| Finding | Result | Note |
|---------|--------|------|
| S-1: Shared app over-provisioned | ✅ CONFIRMED | Pack correct; architecture page misleading (present-tense language) |
| S-2: Shared credential compromise | ✅ CONFIRMED | No debate; mitigation depends on PLAT-2820 |
| S-8: Provider fallback outside DPA | ✅ CONFIRMED | Owner assigned (Dana); fail-closed + quota plan approved |
| S-9: Web search image URLs | ✅ CONFIRMED | Platform controls don't apply to client-side fetches; pack correct |
| S-10: Analytics warehouse per-user | ✅ CONFIRMED | Aggregation is presentation, not control; data is per-user |
| S-11: Privacy notice missing | ✅ CONFIRMED | Ines owns; unmitigated until published |
| S-3: Prompt injection (internal content) | ⏳ DECISION DEFERRED | No formal security decision made; Marcus to formalize by 2026-09-23 |
| S-5: MCP pinning | ✅ CLARIFIED | All pinned to `latest`, not versioned (worse than "unmitigated") |
| S-6: Redis tampering | ⏳ SEVERITY DOWNGRADED | GA cluster has network policy (PLAT-2101); acceptable for beta pilot |
| S-7: Model generates PII | ⚠️ RECOMMENDATION CORRECTED | Removed debug logging (contradicts PRV-003); selective logging instead |
| S-12: Tool description injection | ✅ CONFIRMED | Same root cause as S-5 (pinning covers both) |

### 2. New Finding Identified

**S-13: Slack Connect Channels Contain Customer-Authored Content**
- Three Slack Connect channels with enterprise customers (two accounts)
- Messages authored by customers, not corporate staff
- Trust boundary assumes corporate network = safe content
- Reachability unknown: are Connect messages returned by connector search?
- If yes: lawful basis for processing customer data through model?
- **Action:** Enumerate channels (Tom), test reachability (Priya), settle basis if found (Ines)
- **Due:** 2026-09-16 for assessment

### 3. Ownership Assignments

| Item | Owner | Due |
|------|-------|-----|
| ADR-0006 (provider fallback) unassigned | Dana Whitfield | Sprint (fail-closed) + 2026-09-30 (quota) |
| S-3 (internal content decision) | Marcus Oyelaran | 2026-09-23 |
| S-9 (image URL stripping) | Priya Raghunathan | Before GA (with SUC-001) |
| S-5 (connector pinning) | Priya Raghunathan | 2026-09-23 |
| S-11 (privacy notice) | Ines Ferreira | Before GA |
| Architecture page correction | Marcus Oyelaran | 2026-09-12 |

### 4. Severity Corrections

| Finding | Change | Rationale |
|---------|--------|-----------|
| GAP-A3 (Redis encryption) | Blocking → Non-blocking | GA cluster has PLAT-2101 (network policy) mitigation |
| S-3 (internal content) | Mitigation exists → Decision required | No formal security decision made; inherited through layers |
| S-13 (Slack Connect) | New finding | Customer content inside trust boundary; lawful basis unknown |

### 5. Test Coverage & QA

**TA-203 (Redis brute force) — EXPECTED OUTCOME CORRECTED**
- Beta cluster: network policy disabled → test expects success (read succeeds, no isolation)
- GA cluster: network policy enabled → test demonstrates mitigation works
- Fix: rewrite expected outcome to match beta reality

**Test Plan Acceptance (Document 05)**
- SRTM & 24 test artifacts accepted as basis for GA test plan
- QA to schedule TA-001 to TA-032
- Priya to review coverage after sanitizer work lands

---

## Significant Gaps Closed

### 1. Internal Content Trust Model

**Problem:** Three documents said contradictory things:
- Dana's PLAT-2814 acceptance criterion: "internal sources don't need same handling" (scoping note)
- Priya's implementation: sanitize only web search (per criterion)
- Marcus's architecture page: states internal sources are trusted (as security position)
- Marcus's trust model: documents internal content as safe (security decision)

**Session Discovery:** No security engineer formally decided internal content is safe. Decision was inherited through layers. Marcus's architecture page states present-tense delegation that's not implemented.

**Resolution:** Marcus to formalize written decision on O365/Slack/GitHub handling (not to be settled by referring to scoping note). Due 2026-09-23.

### 2. Provider Fallback (ADR-0006)

**Problem:** "ADR says nobody owns chasing it" — quota increase pending since April with no owner.

**Resolution:** Dana Whitfield assigned; owns vendor relationship. Plan: fail closed on 429 this sprint (Priya); pursue quota increase (Dana, due 2026-09-30).

### 3. Shared Mailbox Lawful Basis

**Problem:** Scheduled for Phase 2 decision, but processing already happening (June 2026).

**Resolution:** Decision deadline moved to 2026-10-31 (pilot renewal), not Phase 2 expansion. Ines owns.

### 4. Connector Pinning Reality

**Problem:** Pack says "pinning required". Current state: all four connectors pinned to `latest` (auto-update on restart).

**Clarification:** Situation is worse than "unmitigated"; pinning exists but to an unstable reference. Action: pin to explicit versions by 2026-09-23 (Priya).

---

## Discrepancies & Corrections

| Document | Issue | Correction |
|----------|-------|-----------|
| README | "20 total findings" | Corrected to 12 + 1 new (S-13) |
| 06-threat-model | ST-/PT- numbering inconsistent with S- scheme | Unified to S- scheme (S-1 through S-13) |
| 06-threat-model | Duplicate COMP-005 IDs | Deduplicated in v1.1 |
| 03-security-architecture | us-west-1 | Corrected to eu-west-1 (confirmed in terraform) |
| 04-gap-analysis | GAP-A1 impact: "violates ADR-0002" | Corrected: ADR-0002 IS the shared app decision; current state implements it |
| 01-security-review | "Enable debug logging in production" | Removed (contradicts PRV-003); replaced with selective argument logging |
| 05-srtm | TA-203 expected outcome | Rewritten: beta has no isolation; test expects read to succeed |
| 03-security-architecture | Org controls list has "Dependency scanning enabled" tick | Tick removed; Node dependencies not scanned (PLAT-2077 open) |

---

## Editorial Actions

**Assigned to:** Brett Crawley | **Due:** 2026-09-16

1. Renumber ST-/PT- references to unified S- scheme
2. Deduplicate COMP- identifiers
3. Correct us-west-1 to eu-west-1 throughout
4. Verify cross-document consistency on finding IDs
5. Tag all session-derived corrections with [SESSION:...]

---

## Action Items by Owner

| # | Owner | Action | Due |
|---|-------|--------|-----|
| 1-7 | Priya Raghunathan | Implement fail-closed 429, SUC-001, sanitizer, connector pinning, test fix, debug route enum, fix GAP-A1 impact | Sprint to 2026-09-30 |
| 8-9 | Marcus Oyelaran | Formalize internal content decision, correct architecture page | 2026-09-12 to 2026-09-23 |
| 10-13 | Dana Whitfield | Chase provider quota, own ADR-0006, assign QA for test plan | 2026-09-30 and ongoing |
| 14-17 | Ines Ferreira | Settle mailbox lawful basis, extract NIS2 obligations, correct cert claim, publish privacy notice | 2026-09-16 to Before GA |
| 18-19 | Kwame Osei | Remove scanning tick, confirm PLAT-2101 ships with GA | 2026-09-30 |
| 20 | Tom Egerton | Enumerate Slack Connect channels | 2026-09-16 |

**Total: 20 action items assigned**

---

## What Worked Well

1. **Pack quality:** 19 of 20 findings confirmed on first review. Analysis was accurate.
2. **Traceability:** Document 05 (SRTM) praised for completeness. No blank cells.
3. **Threat model depth:** Detailed examples and mitigations helped clarify findings.
4. **Assumptions documented:** ADRs and decisions traceable to original documents.

---

## Biggest Gaps Closed

1. **No ownership on provider fallback:** Now assigned (Dana Whitfield). Removes indefinite pending status.
2. **No formal decision on internal content:** Now assigned (Marcus). Surfaces hidden assumption.
3. **Architecture page misleading three people:** Identified; correction action assigned (Marcus, 2026-09-12).
4. **Slack Connect customer content unknown:** Identified as new finding (S-13); reachability assessment assigned.

---

## Risk Assessment Update

**Before v1.1:** 3 critical unmitigated findings
**After v1.1:** 4 critical findings (3 unmitigated, 1 now owned)

- S-1: Shared app (PLAT-2820, not scheduled)
- S-2: Shared cred (PLAT-2820, not scheduled)
- S-8: Provider fallback (now owned by Dana; fail-closed this sprint)
- S-11: Privacy notice (now owned by Ines; before GA)

**Improvement:** Ownership assigned; action plans in place. No findings downgraded; focus shifted to clearing blockers.

---

## Session Confirmation

All participants agreed to conclusions and action items. No objections raised to severity assessments, mitigation plans, or prioritization. Session closed at 15:07 with unanimous consensus on path forward.

**Ready for team execution on 20 action items.**
