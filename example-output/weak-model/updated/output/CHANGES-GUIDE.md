# What Changed Between v1.0 and v1.1

**All documents updated with session corrections and new findings**

---

## Finding Corrections

### S-1: Shared App Registration
- **Finding:** ✅ CORRECT (pack analysis accurate)
- **Problem:** Architecture page misleading (Marcus's doc says present-tense "delegates via OAuth")
- **Fix:** Marcus corrects page by 2026-09-12; notifies pilot group

### S-3: Internal Content Trust
- **Finding:** ✅ CORRECT (no mitigation formalized)
- **Problem:** No security decision made; inherited through 3 layers
- **Fix:** Marcus writes formal decision (ADR) by 2026-09-23

### S-5: MCP Servers
- **Finding:** Situation worse than stated (all pinned to `latest`)
- **Fix:** Priya pins to explicit versions by 2026-09-23

### S-7: Output Filtering
- **Finding:** Recommendation contradicts other requirements
- **Fix:** Removed debug logging recommendation; replaced with selective argument logging (Priya, before GA)

---

## Severity Changes

### GAP-A3 (Redis Encryption)
- **Was:** Blocking
- **Now:** Non-blocking (GA cluster has PLAT-2101 network policy mitigation)

---

## New Findings

### S-13: Slack Connect Customer Content
- **Discovery:** Three Slack Connect channels with enterprise customers
- **Risk:** Customer-authored content inside trust boundary; lawful basis unknown
- **Action:** Test reachability (Tom/Priya); settle basis if reachable (Ines)
- **Due:** 2026-09-16 for assessment

---

## Ownership Assignments

| Item | Owner | Due |
|------|-------|-----|
| ADR-0006 (provider fallback) | Dana Whitfield | Sprint + 2026-09-30 |
| S-3 (internal content decision) | Marcus Oyelaran | 2026-09-23 |
| Architecture page correction | Marcus Oyelaran | 2026-09-12 |
| Connector pinning | Priya Raghunathan | 2026-09-23 |

---

## Test Updates

**TA-203:** Expected outcome rewritten (network policy disabled on beta; test expects success)

---

## ID/Consistency Fixes

- ST-/PT- numbering unified to S- scheme
- COMP-005 duplicate resolved
- Region: us-west-1 → eu-west-1 (confirmed in terraform)

---

**Total Changes:** 20 action items assigned. 1 new finding. 0 findings overturned.

See README.md and SESSION-VALIDATION-SUMMARY.md for details.
