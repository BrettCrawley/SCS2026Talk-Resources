# Internal AI Assistant — Security Review

**Version:** 1.0 (executive verdict, authored last from the full pack) · **Date:** 2026-09-08
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this security review. Produced with AI assistance using the security-review skill set authored by **Brett Crawley, Principal Application Security Engineer**.
**Model:** Claude Opus 5
**Companion documents:** `00-context-sources-and-open-questions.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md` · `06-threat-model-candidates.md`

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted.

---

## 1. Executive summary

The internal AI assistant delivered under PLAT-2810 works, is genuinely useful, and is running with 21 people in two functions. It was built by two engineers inside a fixed board-committed date, with a blocked identity dependency and a procurement window that had closed. Given those constraints the engineering is good, and the team's own documentation is unusually honest: eight architecture decision records state their security consequences accurately, one of them under a heading reading *Not written back*, and the runbooks say plainly what does not exist. Most of this review is the work of taking what the team already wrote down and stating the combined consequence.

**That combined consequence is the headline.** Three individually reasonable decisions meet in one process. ADR-0002 gave the assistant one organisation-wide credential per connector because delegated authorisation was blocked. ADR-0004 fans retrieval out to every connector and returns content as authored. ADR-0003 removed the confirmation step because the pilot group measured it as slower than doing the work by hand. Together they mean that **anyone who can author content the assistant might read — a colleague, a contractor, or an outsider who sends a mail or opens an issue on a public repository — can cause the assistant to send mail as an employee, post to Slack, or commit code, with organisation-wide reach and no human decision in between.** The approved architecture page does not describe this system: it describes per-user delegated credentials, in the present tense, and states that web search is the only untrusted content path. Both statements are contradicted by the committed code.

**The privacy position is the second headline and it is more urgent than it looks.** Support's use case reads a shared customer mailbox. The Confluence draft records "whether Support's shared mailbox should be in scope at all, given whose data is in it" as an open question, and the portfolio has accepted that AI governance will be retrofitted. So customer correspondence is being processed now, with no recorded lawful basis, no notice, no impact assessment, no erasure route across four copies, and — under afternoon load — a transfer to a processor with no contract. That is not a future risk; it is happening on every Support turn.

The pack records **72 findings: 5 Critical, 28 High, 35 Medium and 4 Low.** Nothing is currently marked mitigated, which is the honest position for a pilot that has not had a security pass. The platform baseline does real work — the egress proxy, secret scanning with push protection, server-side tool authorisation, workload identity — but it closes none of these findings outright, and in two cases the design relies on baseline controls that do not apply to this workload at all.

**Nothing here is a reason to stop the pilot. Six things are reasons not to expand it yet, and one — the Support mailbox — is a reason to narrow it today.**

---

## 2. Scope and method

Three Confluence pages, the PMO-0447 portfolio item, the PROD-1131 initiative, epic PLAT-2810 and six stories with all children followed to leaf level, and the `assistant-platform` repository at 0.4.1 read in full, including Terraform, the Helm chart, the CI workflow, eight ADRs and three runbooks. Elicitation was exhaustive by construction: 217 prompts across seven instruments — STRIPED, LINDDUN and the AI-specific privacy categories, privacy dark patterns and human-centred security, the Elevation of Autonomy deck, the AI extension prompts, OWASP Cumulus and the container prompts — each recorded with an outcome in `06-threat-model-candidates.md` before any finding was written up. Findings map to OWASP Top 10 (2021), OWASP LLM and Agentic Top 10, MITRE ATLAS and ATT&CK, and to GDPR, NIS2, CRA, PSTI, PCI-DSS, HIPAA and SOC 2.

What was **not** supplied, and what it costs: no Dockerfile, so the image layer is unassessable; no cluster configuration beyond the Helm values, so three container findings rest on what the chart does not set; no lockfile against a `npm ci` build step; no model provider agreement, so two contradictory retention statements in the same repository cannot be resolved; no privacy notice, record of processing or DPIA. The full list, and what would answer each open question, is section 3 and 4 of `00-context-sources-and-open-questions.md`.

**No validation session has been held.** Every finding, severity and status in this pack is unvalidated until the team walks it, and severities are expected to move in both directions.

---

## 3. Risk posture at a glance

| Area | Posture | The one sentence that matters |
|---|---|---|
| **Agentic behaviour** | 🔴 Critical | Untrusted content reaches the model as instruction on four of five paths, and six write tools execute with no confirmation (AI1, AI3, AI5) |
| **Authorisation** | 🔴 Critical | One application credential per connector, unused user argument, and retrieval that sends no identity at all (E4, E3, I3) |
| **Defaults** | 🔴 Critical | Unconfigured workspace receives every tool including commit and send mail; three other paths also fail open (E1, E2, D5, I4) |
| **Identity** | 🔴 High | An unverified header at the orchestrator, no authentication at the connector service, a shared console password (S1, S2, S5) |
| **Audit** | 🔴 High | No arguments, no acting user, no correlation identifier, and 24-hour retention against a multi-day detection lag (R1, R2, R4, R5) |
| **Privacy** | 🔴 High | Customer data processed with no basis, no notice, no assessment and no erasure across four stores (P1, P4, P6) |
| **Transfers** | 🟡 High | Prompts move to an uncontracted endpoint under peak load, with the revert agreed and unowned (I4, ADR-0006) |
| **Cloud and container** | 🔴 High | Network policy disabled in the pilot cluster, one IAM role with wildcard secret read, no pod security context (C3, CL1, C2) |
| **Supply chain** | 🔴 High | No dependency scanning, no lockfile, an unpinned community connector, unverified tool descriptions (O3, AI10, AI11) |
| **Documentation integrity** | 🔴 High | Five approved statements contradicted by the code; an expansion decision would rest on controls that do not exist (O1 to O5) |
| **Resilience** | 🔴 High | No kill switch, no detection, no incident plan for a compromised assistant (RR1, RR3) |
| **Platform baseline** | 🟢 Live | Egress proxy, secret scanning, Secrets Manager with workload identity, at-rest encryption, external log retention — all doing real work |

---

## 4. Design versus implementation

Fourteen divergences are catalogued in `03-security-architecture.md` section 6. Five matter to a decision-maker:

1. **Delegated per-user credentials.** The approved page describes them in the present tense. The code uses one application registration. ADR-0002 says so, and says nobody has updated the page.
2. **Untrusted content.** The approved page says web search is the only untrusted path. Four corporate connectors carry content anyone can author, unfiltered.
3. **Audit.** The approved page says every privileged action is recorded with the acting user and the parameters. The code records the tool name and the workspace, and the runbook confirms it.
4. **Diagnostic routes and network policy.** The approved platform standard says both are handled. The chart deliberately leaves diagnostic routes on and network policy off.
5. **Model provider.** The approved page says EU-hosted under the enterprise agreement. Under any rate limit the same prompt is retried against a pay-as-you-go account.

**This is the finding behind the findings.** Twelve of the fourteen are recorded honestly somewhere in the repository. What is missing is a mechanism that carries a pilot-time decision back to the page a reviewer reads, and a gate that stops an accepted shortcut becoming the general-availability design by default. That mechanism is recommendation 6 below, and it is the one that prevents the next review finding the same class of problem.

---

## 5. Regulatory posture

**GDPR and UK GDPR — the weakest area.** No lawful basis recorded, no record of processing, no notice to employees or the third parties in their correspondence, no Article 35 assessment for what is plainly large-scale processing of correspondence, no executable erasure across four stores, and a transfer path outside the contracted processor under load. Article 33 is also compromised in practice: with 24-hour conversation retention and no argument-level audit, a breach discovered on day three cannot be scoped inside 72 hours.

**NIS2 — unresolved and material.** Applicability depends on an entity classification nobody supplied. If Meridian is in scope, the shared console password fails the Article 21 MFA requirement directly, supply-chain obligations bite on the connector chain, and a 24-hour early-warning duty attaches to a system with no detection and no kill switch. **This determination should be requested this week**; it changes the sequencing.

**CRA and PSTI — out of scope,** explicitly. No product with digital elements is placed on the EU market and there is no consumer connectable device. Both should be reassessed before PROD-1131 phase 3, which contemplates customer-facing surfaces. Two CRA-shaped obligations — a software bill of materials and a vulnerability disclosure process — are worth adopting regardless, because both are already gaps.

**PCI-DSS — conditional and unanswered.** There is no cardholder data environment by design, but Support correspondence and refund discussions can carry card numbers customers typed into mail. If confirmed, requirements 3, 4, 7 and 10 apply to a system with no argument-level audit.

**HIPAA — out of scope.** No protected health information, no covered-entity relationship.

**SOC 2 — applies where a report covers this estate.** Logical access, encryption, monitoring and change management all carry open findings; the diagnostic routes and the branch-protection exemption drift are the likeliest exceptions.

---

## 6. Prioritised recommendations and gate readiness

**Gate: expansion beyond Platform and Support.** Not general availability — the pilot already processes customer correspondence, so some of this is due now rather than later.

**Do today (one configuration line each)**
- Set `"read_mail": false` for `ws-support` until the shared-mailbox question is answered (P1). The connector service already enforces the allowlist.
- Set `EXPOSE_DEBUG_ROUTES: "false"` in the chart (I1, I2).

**Launch gates**
1. **A confirmation gate on irreversible actions** (AI3, AI1, AI2). *The single most important item in the pack.* A token minted by the surface after a human click and verified at the connector service. This holds regardless of how content reached the model, which nothing else in the design does. ADR-0003's own alternatives section already identifies it and says the definition is not hard.
2. **Narrow the reach** (I3, E5, E6, E3). Slack scopes without direct-message history; the GitHub installation scoped to named repositories excluding the three exempt ones; and a per-user filter at retrieval that does not wait for PLAT-2820 — starting with sending `userId` from `gather()`, which is one line and currently missing entirely.
3. **Close the four unauthenticated surfaces** (C3, S2, T1, I1). Network policy on and verified in the pilot cluster; workload identity on the connector service; Redis transport encryption and auth token; diagnostic routes default closed with an authorised support route for the runbook.
4. **Invert the widening defaults** (E1, E2). Unknown workspace and unconfigured tools resolve to no capability, with a read-only onboarding template so same-day setup survives.
5. **Answer the Support mailbox question and start the Article 35 assessment** (P1, P2, P6). Request the NIS2 classification in the same conversation.
6. **Correct the approved architecture page and add an expansion gate** (O1, O2). No expansion while an ADR marked not-written-back is open.

**Fast hygiene — days, cheap, no design debate**
Add `userId` to the two tool-call log lines (R2). Allowlist the debug configuration fields (I2). `automountServiceAccountToken: false` and a restricted pod security context (C6, C2). Namespace tool identifiers by connector (AI16). Reorder the sanitiser so it measures what it claims (AI6). A rate limiter on `POST /turns` (D1). Namespace the Redis key and compare the conversation owner (S3).

**Near-term**
The audit plane with correlation and independent retention (R1, R4, R5). Structured provenance on retrieval (AI5). Output filter and content security policy (AI4). Enforced spend budgets rather than alerts (D2). Lockfile, audit and SBOM steps (O3). The graded kill switch and an assistant-specific incident plan (RR1, RR3). Erasure path and subject locator (P4). Telemetry pseudonymisation (P3). Image digest pinning and admission verification (C1, C5).

**Decisions to ratify, not fix**
The unvalidated workspace instruction field (ADR-0005); free model selection for the workspace holding customer data (ADR-0007); the deliberate absence of conversation backups; the three branch-protection exemptions (PLAT-1188); and the portfolio's acceptance that AI governance is retrofitted (PR-03). Each is defensible. None is currently carried knowingly by a named person, which is the problem.

---

## 7. What is done well, and should be kept

- **Read in place, no new store of record (D-05).** The best structural privacy decision in the design, and it is honoured for content. Keep it, and extend the same discipline to telemetry and processor retention, which it currently does not cover.
- **Server-side tool authorisation at `mcp/server.ts:41`.** The allowlist is enforced at the connector, not in the prompt. That is the distinction most teams get wrong, and this team got it right. The defect is the fail-open default, not the placement.
- **The 24-hour conversation TTL.** A genuine minimisation choice made without being asked. Keep it and add a separate audit plane rather than lengthening it.
- **The ADRs.** Eight decisions, each stating its own security consequence honestly, including one that records its own contradiction of an approved page. This is better documentation discipline than most production systems have, and it is why this review could be specific rather than generic.
- **The pilot's own defect list.** The Confluence draft records the injection-shaped symptoms — markdown images pointing at external URLs, the model acting when uncertain, untrimmed context in long sessions — before anyone called them security findings. Where this review agrees with the team, it is agreeing, not discovering.
- **The platform baseline.** The egress proxy, secret scanning with push protection, Secrets Manager with workload identity, at-rest encryption and external log retention are all doing real work under this pilot.

---

## 8. Next steps

1. Walk this pack with the people named in `00-context-sources-and-open-questions.md` section 5; record corrections, confirmed mitigations, accepted risks and severity changes in Appendix G of the threat model.
2. Apply the two same-day configuration changes above.
3. Raise the remediation tickets listed in Appendix C of the threat model, and give ADR-0006's revert an owner and a date.
4. Request the NIS2 classification, the model provider agreement, and the DPO's Article 35 determination.
5. Re-run this model after PLAT-2820 lands, with the Dockerfile, the cluster configuration, the Slack app manifest, the GitHub installation scope, the warehouse schema and the provider agreement in hand. Those six inputs would convert roughly a dozen inferred findings into confirmed or closed ones.

---

*Reflects the material as supplied on 2026-09-08. Ticket statuses are point-in-time. Nothing here is legal advice; the NIS2, Article 35, Article 14 and PCI-DSS determinations should be confirmed with counsel and the DPO.*
