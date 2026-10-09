# Internal AI Assistant — Security Review

**Version:** 1.1 (executive verdict, authored last from the full pack; validation session of 2026-09-08 merged) · **Date:** 2026-09-08
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this security review and facilitator of the validation session. Produced with AI assistance using the security-review skill set authored by **Brett Crawley, Principal Application Security Engineer**.
**Model:** Claude Opus 5
**Companion documents:** `00-context-sources-and-open-questions.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md` · `06-threat-model-candidates.md`

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted.

**Provenance tags** — `[VS · confirmed]` · `[VS · corrected]` · `[VS · new]` · `[VS · contradicts]` · `[VS · accepted, owner: NAME]` · `[VS · moved]` mark material derived from the **validation session (VS) of 2026-09-08**. `[RV · editorial]` marks a reviewer-applied correction made while merging that was **not** raised in the session. Full tag set in `README.md`.

---

## 0. Delta, version 1.0 to version 1.1

| Section | Change | Tag |
|---|---|---|
| 1 | Executive summary gains the session outcome and the finding that the room's own mental model of the authorisation design was wrong. Counts move from 72 to 73 findings | `[VS · confirmed]`, `[VS · contradicts]` |
| 2 | "No validation session has been held" replaced by the session record and by what remains unvalidated | `[VS · new]` |
| 3 | Documentation-integrity row extended to cover O7; NIS2 no longer sits under Transfers as unresolved | `[VS · new]` |
| 4 | Divergence 1 gains the fact that three of seven people in the session were reasoning from the approved page | `[VS · new]` |
| 5 | **NIS2 rewritten** — determination exists, obligation arrives contractually. **SOC 2 rewritten** — not conditional, Type II report covers this estate. ISO 27001 note added | `[VS · contradicts]` |
| 6 | "Do today" reduced to what was actually done and **the diagnostic-routes recommendation re-sequenced**: the support route is built before the flag closes. Decisions-to-ratify now ratified with owners | `[VS · corrected]`, `[VS · accepted]` |
| 7 | Unchanged in substance; the ADRs entry gains the session's counter-observation | `[VS · new]` |
| 8 | Next steps rewritten against the 30-item action list | `[VS · new]` |
| Register | AI3 ⚪ → 🔴; D2 🔵 → ⚪; O7 added. No severity raised or lowered; no finding closed | `[VS · moved]`, `[VS · new]` |

---

## 1. Executive summary

The internal AI assistant delivered under PLAT-2810 works, is genuinely useful, and is running with 21 people in two functions. It was built by two engineers inside a fixed board-committed date, with a blocked identity dependency and a procurement window that had closed. Given those constraints the engineering is good, and the team's own documentation is unusually honest: eight architecture decision records state their security consequences accurately, one of them under a heading reading *Not written back*, and the runbooks say plainly what does not exist. Most of this review is the work of taking what the team already wrote down and stating the combined consequence.

**That combined consequence is the headline, and the room confirmed it.** `[VS · confirmed]` Three individually reasonable decisions meet in one process. ADR-0002 gave the assistant one organisation-wide credential per connector because delegated authorisation was blocked. ADR-0004 fans retrieval out to every connector and returns content as authored. ADR-0003 removed the confirmation step because the pilot group measured it as slower than doing the work by hand. Together they mean that **anyone who can author content the assistant might read — a colleague, a contractor, or an outsider who sends a mail or opens an issue on a public repository — can cause the assistant to send mail as an employee, post to Slack, or commit code, with organisation-wide reach and no human decision in between.**

**The most important thing the session added is not a finding. It is who believed what.** `[VS · contradicts]` The approved architecture page describes per-user delegated credentials in the present tense. The lead architect wrote that page, and signed it off after reading ADR-0002, which contradicts it. The Platform security champion had been describing the same model to Platform and had never opened the ADRs. The epic owner had told the Support group at onboarding that the assistant cannot see anything they cannot see. **All three descriptions were wrong, and one of them was wrong the day it was given to nine people who process customer correspondence.** The pack found the defect; the session found that the defect was invisible from where three of the four most senior readers were standing. That is the argument for recommendation 6 — the divergence table and the expansion gate — and it is stronger now than it was in version 1.0.

**The privacy position is the second headline and the session made it worse in one respect and no better in any.** `[VS · contradicts]` Support's use case reads a shared customer mailbox — and it is the *primary* use case, not one of several: the ticket queue does not carry the history, which lives in the mail thread. The Data Protection Officer's position, stated in the room, is that there is **no lawful basis recorded — not a weak basis, none** — no record of processing, no Article 35 assessment for what is plainly large-scale automated processing of correspondence, no notice to the customers and no notice to the third parties named inside their mail, no erasure route across four copies, and, under afternoon load, a transfer to a processor with no contract. `read_mail` was set false for `ws-support` within ten minutes of the session ending, with the ticket queue kept in scope. That is a two-week pause, not a judgement on Support, and Support's engineering manager took it while saying plainly that he is not happy about it. Both facts belong in the record.

**`[DP2 · new]` After the directed second pass of 2026-09-08 the pack records 75 findings: 5 Critical, 30 High, 36 Medium and 4 Low.** That pass tested two reviewer-supplied scenarios against the pack and the code and returned *new* on both, adding **AI18** — one conversation composes an output for a second purpose from a first purpose's context, with no attacker anywhere in the chain — and **AI19** — the retrieval merge bounds neither source nor author, so whoever writes the most into an early connector decides what the model reads without ever writing an instruction. Both are High and Open. No existing finding moved in severity or status, none was closed, and none was withdrawn. The reasoning, including the six existing findings considered as coverage and dismissed with the reason, is in section 0 of the threat model. Neither new finding has yet been put to the people who own the system, because the pass ran after the validation session; both need a disposition at the next one. The paragraph that follows records the position as it stood at the close of that session.

The pack records **73 findings: 5 Critical, 28 High, 36 Medium and 4 Low.** Nothing is currently marked mitigated, which remains the honest position. Two status movements came out of the session and no severity moved in either direction: AI3 from Accepted to Open, because the acceptance rested on a human reading an action list that carries nothing worth reading; and D2 from Planned to Accepted for the pilot, because the epic owner elected to carry the spend risk in order to sequence the confirmation gate first. **No finding was closed.** One finding was added: **O7**, the standing platform controls page states inherited controls without stating their coverage limits.

**Nothing here is a reason to stop the pilot. Six things are reasons not to expand it yet, and one — the Support mailbox — was a reason to narrow it on the day, which the team did.**

---

## 2. Scope and method

Three Confluence pages, the PMO-0447 portfolio item, the PROD-1131 initiative, epic PLAT-2810 and six stories with all children followed to leaf level, and the `assistant-platform` repository at 0.4.1 read in full, including Terraform, the Helm chart, the CI workflow, eight ADRs and three runbooks. Elicitation was exhaustive by construction: 217 prompts across seven instruments — STRIPED, LINDDUN and the AI-specific privacy categories, privacy dark patterns and human-centred security, the Elevation of Autonomy deck, the AI extension prompts, OWASP Cumulus and the container prompts — each recorded with an outcome in `06-threat-model-candidates.md` before any finding was written up. Findings map to OWASP Top 10 (2021), OWASP LLM and Agentic Top 10, MITRE ATLAS and ATT&CK, and to GDPR, NIS2, CRA, PSTI, PCI-DSS, HIPAA and SOC 2.

**A validation session has now been held.** `[VS · new]` On 2026-09-08, 14:00 to 15:14, with the epic owner, the lead architect, the engineer who built the pilot, Support's engineering manager, the Data Protection Officer and a Platform security champion. Three dispositions per finding — confirmed, corrected, or accepted with a named owner — recorded aloud so participants could object at the time. Every code-level citation put to the room was confirmed. Two corrections to the pack emerged, one of them the reviewer's own. The full record, with the per-finding disposition table and the 30-item action list, is **Appendix G of `06-threat-model.md`**.

What was **not** supplied, and what it costs: no Dockerfile, so the image layer is unassessable; no cluster configuration beyond the Helm values, so three container findings rest on what the chart does not set; no lockfile against a `npm ci` build step, now confirmed genuinely absent rather than omitted from the extract; no model provider agreement, so two contradictory retention statements in the same repository cannot be resolved; no privacy notice, record of processing or DPIA, now confirmed by the DPO as absent rather than unsupplied. The full list, and what would answer each open question, is sections 3 and 4 of `00-context-sources-and-open-questions.md`.

**What remains unvalidated is now narrow and named.** `[VS · confirmed]` Four questions nobody in the room could answer: which repositories the org-level GitHub app can actually commit to; what Slack scopes were granted, since IT performed the install and the engineer who wrote "the full scope set" has no manifest either; what the model provider's agreement says about retention and region; and whether the egress allowlist entries went through Platform Security's weekly review. **E5, E6, I5 and CL4 keep their evidence tags** — each rests on a ticket comment or a code comment rather than on the authoritative artefact, and the pack is right to say so rather than to imply more confidence than it has.

---

## 3. Risk posture at a glance

| Area | Posture | The one sentence that matters |
|---|---|---|
| **Agentic behaviour** | 🔴 Critical | Untrusted content reaches the model as instruction on four of five paths, and six write tools execute with no confirmation — and the acceptance that made this tolerable was withdrawn in the session (AI1, AI3, AI5) `[VS · moved]` |
| **Authorisation** | 🔴 Critical | One application credential per connector, unused user argument, and retrieval that sends no identity at all (E4, E3, I3) `[VS · confirmed]` |
| **Defaults** | 🔴 Critical | Unconfigured workspace receives every tool including commit and send mail; three other paths also fail open (E1, E2, D5, I4) `[VS · confirmed]` |
| **Identity** | 🔴 High | An unverified header at the orchestrator, no authentication at the connector service, a shared console password (S1, S2, S5) |
| **Audit** | 🔴 High | No arguments, no acting user, no correlation identifier, and 24-hour retention against a multi-day detection lag (R1, R2, R4, R5) — confirmed from the operational side by two mistaken Slack posts nobody could scope `[VS · confirmed · T. Egerton]` |
| **Privacy** | 🔴 High | Customer data processed with no basis, no notice, no assessment and no erasure across four stores, on what is the **primary** Support use case (P1, P4, P6) `[VS · contradicts]` |
| **Transfers** | 🟡 High | Prompts move to an uncontracted endpoint under peak load, carrying exactly the content with the least basis for processing, with the revert agreed and unowned (I4, ADR-0006) `[VS · confirmed · I. Ferreira]` |
| **Cloud and container** | 🔴 High | Network policy disabled in the pilot cluster, one IAM role with wildcard secret read, no pod security context (C3, CL1, C2) — PLAT-2101 is Platform's and carries an owner but no date `[VS · confirmed · K. Osei]` |
| **Supply chain** | 🔴 High | No dependency scanning, no lockfile, and **all five connectors pinned to `latest`, not only the community one**, with unverified tool descriptions (O3, AI10, AI11) `[VS · contradicts]` |
| **Documentation integrity** | 🔴 High | Five approved statements contradicted by the code; an expansion decision would rest on controls that do not exist; and the standing controls page states inherited controls without their coverage limits, which is how two senior people applied the egress proxy to a browser-side fetch (O1 to O5, **O7**) `[VS · new]` |
| **Resilience** | 🔴 High | No kill switch, no detection, no incident plan for a compromised assistant — and an incident notification duty now known to arrive contractually (RR1, RR3) `[VS · new]` |
| **Regulatory determinations** | 🟡 Mixed | NIS2 determined (not directly in scope, contractually obliged); SOC 2 Type II confirmed and unhedged; Article 35 assessment commissioned with a date; PCI-DSS still conditional and unanswered `[VS · contradicts]` |
| **Platform baseline** | 🟢 Live | Egress proxy, secret scanning, Secrets Manager with workload identity, at-rest encryption, external log retention — all doing real work, and the VPN's MFA is what invalidated one of my own example threats |

---

## 4. Design versus implementation

Fourteen divergences are catalogued in `03-security-architecture.md` section 6. Five matter to a decision-maker:

1. **Delegated per-user credentials.** The approved page describes them in the present tense. The code uses one application registration. ADR-0002 says so, and says nobody has updated the page. **Three of the seven people in the validation session were describing the approved page's model as the system's actual behaviour when the session opened.** `[VS · new]`
2. **Untrusted content.** The approved page says web search is the only untrusted path. Four corporate connectors carry content anyone can author, unfiltered. **And nobody decided that** — see recommendation 7. `[VS · contradicts]`
3. **Audit.** The approved page says every privileged action is recorded with the acting user and the parameters. The code records the tool name and the workspace, and the runbook confirms it. Support confirmed the operational consequence: after two mistaken Slack posts they could not tell what had been posted without asking the person who saw it. `[VS · confirmed · T. Egerton]`
4. **Diagnostic routes and network policy.** The approved platform standard says both are handled. The chart deliberately leaves diagnostic routes on and network policy off. **The conflict is live, not latent:** the incident runbook uses those routes in production, so closing them first would blind on-call. `[VS · confirmed · P. Raghunathan]`
5. **Model provider.** The approved page says EU-hosted under the enterprise agreement. Under any rate limit the same prompt is retried against a pay-as-you-go account — which the DPO characterised as a transfer to an uncontracted processor of exactly the content she has the least basis for processing, at the busiest time of day. `[VS · new · I. Ferreira]`

**This is the finding behind the findings.** Twelve of the fourteen are recorded honestly somewhere in the repository. What is missing is a mechanism that carries a pilot-time decision back to the page a reviewer reads, and a gate that stops an accepted shortcut becoming the general-availability design by default. That mechanism is recommendation 6, and the session gave it its strongest evidence: the divergence was invisible to the people who own the system until a document pointed at it, and the document was in their own repository. **O7 extends the same defect one layer up** — the standing platform controls page has the same property, and it is read by more workloads than this one. `[VS · new]`

---

## 5. Regulatory posture

**GDPR and UK GDPR — the weakest area, and confirmed as such by the DPO in the room.** `[VS · confirmed · I. Ferreira]` No lawful basis recorded, no record of processing, no notice to employees or the third parties in their correspondence, no Article 35 assessment for what is plainly large-scale processing of correspondence, no executable erasure across four stores, and a transfer path outside the contracted processor under load. Article 33 is also compromised in practice: with 24-hour conversation retention and no argument-level audit, a breach discovered on day three cannot be scoped inside 72 hours. Two positions were settled in the session: **Article 14 for third parties requires either a notice or a documented exemption, not silence** (P2, confirmed Medium); and **the purpose-limitation argument for per-user telemetry is dead**, because the per-request row carries the user identifier and anyone with warehouse access can group by user (P3, confirmed Medium). Preliminary Article 35 assessment due **2026-09-22**, owner I. Ferreira, gated on the Support data map.

**NIS2 — determined, and the route is not the one the pack assumed.** `[VS · contradicts · I. Ferreira]` **Meridian is neither an essential nor an important entity.** That determination has been made and it is not new; version 1.0's request for a classification "this week" is superseded. **The obligation is not closed by that answer.** Two of Meridian's customers *are* in scope, and the contracts with them carry the obligation down. It therefore arrives **contractually** rather than by direct applicability, and the practical effect on this system is the same: supply-chain expectations bite on the connector chain, and an incident notification duty attaches to a system with no detection and no kill switch. Mapping those contractual obligations onto S5 (shared console password), RR1 (no kill switch), RR3 (no incident plan) and AI10 (the unreviewed connector, if the supply-chain clause is worded as expected) is **action 13, owner I. Ferreira, due 2026-09-19**.

**CRA and PSTI — out of scope,** explicitly. No product with digital elements is placed on the EU market and there is no consumer connectable device. Both should be reassessed before PROD-1131 phase 3, which contemplates customer-facing surfaces. Two CRA-shaped obligations — a software bill of materials and a vulnerability disclosure process — are worth adopting regardless, because both are already gaps. Unchanged by the session.

**PCI-DSS — conditional and still unanswered.** There is no cardholder data environment by design, but Support correspondence and refund discussions can carry card numbers customers typed into mail. If confirmed, requirements 3, 4, 7 and 10 apply to a system with no argument-level audit. Not resolved in the session; folded into the Article 35 data-mapping work.

**SOC 2 — applies, and it is not conditional.** `[VS · contradicts · I. Ferreira]` **Meridian is SOC 2 Type II and the report covers this estate.** Version 1.0's phrasing — "applies where a report covers this estate" — read as hedging and should not have. Logical access, encryption, monitoring and change management all carry open findings; the diagnostic routes and the branch-protection exemption drift are the likeliest exceptions.

**ISO 27001 — not held.** `[VS · new · I. Ferreira]` Meridian is **not** ISO 27001 certified, and people in the building assume it is. Recorded here because that assumption, left standing, would let a reader treat an ISO control set as an inherited baseline for this workload. It is not one.

**HIPAA — out of scope.** No protected health information, no covered-entity relationship. Health information does appear incidentally in Support correspondence, because customers explain why they missed a delivery; that is a GDPR special-category question for the Article 35 assessment, **not** a HIPAA question, and the DPO declined to make a determination on it from an anecdote. `[VS · new]`

---

## 6. Prioritised recommendations and gate readiness

**Gate: expansion beyond Platform and Support.** Not general availability — the pilot already processes customer correspondence, so some of this is due now rather than later.

**Done on the day** `[VS · new]`
- `"read_mail": false` for `ws-support`, ticket queue kept in scope (P1, G-21). Applied within ten minutes of the session. Returns only when the Article 35 outcome is recorded.
- `commit` removed from `ws-platform` pending the branch-and-pull-request change (E6, AI17). Applied on the day. This is **cheaper than version 1.0's recommendation** and was possible only because the room supplied a fact the documents did not: the tool had been used eleven times since July, nine of them in testing, and both real uses were one-line config changes. `[VS · new]`

**Corrected recommendation — the diagnostic routes are sequenced, not flipped** `[VS · corrected]`
Version 1.0 listed `EXPOSE_DEBUG_ROUTES: "false"` as a same-day one-line change. It is not, and the session established why: the incident runbook uses those routes in production, and closing them first stops the on-call path for "the assistant did something wrong" working at all. **The authorised, audited support route is built first; the flag then defaults closed and is set explicitly in the chart.** Priya Raghunathan owns the route, Kwame Osei owns the conversation with the platform standard. Both agreed the end state; the ordering is the correction (I1, I2, O5).

**Launch gates**
1. **A confirmation gate on irreversible actions** (AI3, AI1, AI2). *The single most important item in the pack, and the one whose acceptance was withdrawn in the session.* A token minted by the surface after a human click and verified at the connector service. This holds regardless of how content reached the model, which nothing else in the design does. **Scope agreed in the room: `send_mail` and `commit` only — irreversible tools, not every write.** Reversible writes such as an issue comment stay unconfirmed, so the ADR-0003 speed argument survives intact; the epic owner undertook to take that scope to the pilot group herself. Owners: D. Whitfield and P. Raghunathan, design 2026-09-19. `[VS · moved]`
2. **Narrow the reach** (I3, E5, E6, E3). Slack scopes without direct-message history; the GitHub installation scoped to named repositories **explicitly excluding `platform-ci`, `legacy-billing-adapter` and `infra-bootstrap`**; and a per-user filter at retrieval that does not wait for PLAT-2820 — starting with sending `userId` from `gather()`, which is one line, is currently missing entirely, and which the engineer undertook to fix the same day. `[VS · confirmed]`
3. **Close the four unauthenticated surfaces** (C3, S2, T1, I1). Network policy on and verified in the pilot cluster; workload identity on the connector service; Redis transport encryption and auth token — **the client-library objection recorded in `redis.tf` is a version problem, not a design constraint, confirmed by its author** `[VS · confirmed · P. Raghunathan]`; diagnostic routes default closed behind the support route above.
4. **Invert the widening defaults** (E1, E2). Unknown workspace and unconfigured tools resolve to no capability, with a read-only onboarding template so same-day setup survives. The deliberateness of the current default was confirmed and the read-only template accepted as the answer without objection. `[VS · confirmed]`
5. **Answer the Support mailbox question and complete the Article 35 assessment** (P1, P2, P6). Preliminary 2026-09-22, gated on the Support data map. **The NIS2 classification no longer needs requesting** — it exists; what is needed instead is the mapping of the contractual obligations onto S5, RR1, RR3 and AI10.
6. **Correct the approved architecture page and add an expansion gate** (O1, O2). A divergence table covering ADR-0002, ADR-0003, ADR-0004 and ADR-0006, and a gate blocking pilot growth while an ADR marked not-written-back is open. The lead architect asked for this to be on the page **before anyone asks about a third pilot group**. Owner M. Oyelaran, 2026-09-19. `[VS · new]`
7. **Own the decision that internal content does not require sanitising** (AI1, AI5, G-05). `[VS · new]` This is not a fix and it is not a gate in the ordinary sense. It is a decision that **has never been made by anyone**: written as scoping on a story, implemented as though it were a position, written into the approved trust model because the ticket and the code agreed, and assumed by Platform to be covered by a sanitiser that exists on the document-pipeline ingest path and not on this one. It is assigned to M. Oyelaran, with data categories from I. Ferreira and pilot needs from D. Whitfield, to be written as an ADR with a named approver by 2026-09-26. **It is explicitly not to be answered in flight**, because the answer is a security position that needs the data categories in it and half the inputs are missing.

**Fast hygiene — days, cheap, no design debate**
Send `userId` from `gather()` and require it at `/search` (E3). Add `userId` to the two tool-call log lines (R2). Reorder the sanitiser so the phrase match runs before tag stripping, and flag rather than silently substitute (AI6) — worth doing even though the denylist is not a boundary, because right now it does not even measure what it claims. `[VS · confirmed · P. Raghunathan]` Allowlist the debug configuration fields (I2). `automountServiceAccountToken: false` and a restricted pod security context (C6, C2). Namespace tool identifiers by connector (AI16). A rate limiter on `POST /turns` (D1). Namespace the Redis key and compare the conversation owner (S3).

**Near-term**
The audit plane with correlation and independent retention (R1, R4, R5). Structured provenance on retrieval (AI5). Output filter and content security policy (AI4). Lockfile, audit and SBOM steps (O3). **Digest pinning across all five connectors, not only the community one** (AI10) — the same work either way. `[VS · contradicts]` The graded kill switch and an assistant-specific incident plan, with the notification criteria supplied by the DPO from the contractual mapping (RR1, RR3). Erasure path and subject locator, with PLAT-2825-2 reopened (P4). Telemetry pseudonymisation at write, identified form retained only to the finance cycle (P3). Image digest pinning and admission verification (C1, C5). Add a coverage note to the standing platform controls page recording that the egress proxy does not cover browser-side rendering fetches (O7, AI4).

**Decisions ratified in the session, with owners** `[VS · accepted]`
Each was defensible in version 1.0 and unowned. The ownership was the problem, and it is now closed.

| Decision | Disposition | Owner |
|---|---|---|
| ADR-0005, unvalidated workspace instruction field (T2) | **Accepted**, with a length cap and character validation added — because the acceptance was made about tone-setting and the field now sits in front of a workspace holding `send_mail` | M. Oyelaran |
| ADR-0007, free model selection per workspace (AI12) | **Accepted as a mechanism, rejected as an instance.** Free choice keeps cost attributable per PMO-0447; putting the workspace with customer data on the cheapest model to save money is a bad instance of a reasonable rule. `ws-support` moves off `aurora-1-mini`, and model choice becomes bounded by what the workspace reads | D. Whitfield |
| No enforced spend ceiling (D2) | **Accepted for the remainder of the pilot**, in favour of sequencing the confirmation gate first, and recorded on the ticket. Revisit at expansion. Status moves 🔵 Planned → ⚪ Accepted | D. Whitfield |
| PR-03, AI governance retrofitted (O6) | **Accepted** — it is a portfolio decision and it stands. The local substitute the pack recommends, a decision register with named approvers, is **the artefact that would have caught the content-trust question**, and is opened with that decision as its first row | M. Oyelaran |
| Deliberate absence of conversation backups (RR2) | Unchanged; still the right trade for a 24-hour cache | — |
| The three branch-protection exemptions (PLAT-1188) | **Not ours.** Escalated to Platform Security's review with a specific sentence: an org-level app installed for an AI assistant can currently write to `platform-ci` on an unprotected branch, and the shared template propagates nightly | K. Osei |

---

## 7. What is done well, and should be kept

- **Read in place, no new store of record (D-05).** The best structural privacy decision in the design, and it is honoured for content. Keep it, and extend the same discipline to telemetry and processor retention, which it currently does not cover.
- **Server-side tool authorisation at `mcp/server.ts:41`.** The allowlist is enforced at the connector, not in the prompt. That is the distinction most teams get wrong, and this team got it right. The defect is the fail-open default, not the placement — and inverting that default drew no objection in the room. `[VS · confirmed]`
- **The 24-hour conversation TTL.** A genuine minimisation choice made without being asked. Keep it and add a separate audit plane rather than lengthening it.
- **The ADRs.** Eight decisions, each stating its own security consequence honestly, including one that records its own contradiction of an approved page. This is better documentation discipline than most production systems have, and it is why this review could be specific rather than generic. **The session's counter-observation is that discipline in the ADRs is not sufficient on its own:** the lead architect had read ADR-0002 and signed the contradicting page anyway, and the security champion had never opened the ADRs. Honest records only work if something carries them to the page people actually read. `[VS · new]`
- **The pilot's own defect list.** The Confluence draft records the injection-shaped symptoms — markdown images pointing at external URLs, the model acting when uncertain, untrimmed context in long sessions — before anyone called them security findings. Where this review agrees with the team, it is agreeing, not discovering.
- **The platform baseline.** The egress proxy, secret scanning with push protection, Secrets Manager with workload identity, at-rest encryption and external log retention are all doing real work under this pilot. **The VPN's MFA in particular is what invalidated one of my own example threats** — correction C-01 — which is the baseline earning its place in the model rather than being cited in it. `[VS · corrected]`
- **The measurement behind ADR-0003.** The pilot group timed the confirmation step and two people stopped using the assistant. That is a real finding about human behaviour, it is credited in the human-centred security section, and **it should not be reversed by adding friction everywhere.** The recommendation was never confirmation on all six write tools; it is a token on irreversible tools only. Once that was read aloud in the room the objection to it was withdrawn and the scope was taken up voluntarily. `[VS · confirmed · D. Whitfield]`

---

## 8. Next steps

1. **Apply the 30-item action list in Appendix G of `06-threat-model.md`.** Every item has a named owner; twenty-six have a date, three are marked "today" and were done on the day, and one — PLAT-2101, the network policy — is recorded as an owner without a date rather than as a date nobody intends to meet. `[VS · new]`
2. **Complete the two items that gate everything else:** the confirmation token on irreversible tools (design 2026-09-19) and the content-trust ADR with a named approver (2026-09-26).
3. **Complete the Article 35 assessment** (preliminary 2026-09-22) and decide `read_mail` for `ws-support` on its outcome. Half the condition attached to G-21 is now met — the mailbox is confirmed in scope and is the primary use case — and the other half, whether special-category content is present, is a determination for the assessment and not for a meeting.
4. **Obtain the four artefacts nobody in the room could produce:** the GitHub app installation scope, the Slack app manifest and granted scope list, the model provider enterprise agreement, and confirmation of whether the egress allowlist entries went through review. E5, E6, I5 and CL4 keep their evidence tags until they arrive.
5. **Correct the approved architecture page before any conversation about a third pilot group**, and open the local decision register with the content-trust decision as its first row.
6. **Re-run this model** after PLAT-2820 lands, with the Dockerfile, the cluster configuration, the Slack app manifest, the GitHub installation scope, the warehouse schema and the provider agreement in hand. Those six inputs would convert roughly a dozen inferred findings into confirmed or closed ones. This version already converted the rest.

---

*Reflects the material as supplied on 2026-09-08 and the validation session of the same date. Ticket statuses are point-in-time. Nothing here is legal advice; the Article 35, Article 14 and PCI-DSS determinations should be confirmed with counsel and the DPO. The NIS2 determination has been made and is recorded above; the contractual mapping that follows from it is action 13.*
