# Internal AI Assistant — Gap Analysis

**Version:** 1.1 (required-versus-built, authored after the threat model; validation session of 2026-09-08 merged) · **Date:** 2026-09-08
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this gap analysis and facilitator of the validation session. Produced with AI assistance using the security-review skill set authored by **Brett Crawley, Principal Application Security Engineer**.
**Model:** Claude Opus 5
**Companion documents:** `06-threat-model.md` · `03-security-architecture.md` · `05-srtm-and-test-artefacts.md`

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted.

**Provenance tags** — `[VS · confirmed]` · `[VS · corrected]` · `[VS · new]` · `[VS · contradicts]` · `[VS · accepted, owner: NAME]` · `[VS · moved]` mark material derived from the **validation session (VS) of 2026-09-08**, facilitated by Brett Crawley. `[RV · editorial]` marks a reviewer-applied correction made while merging that was **not** raised in the session. Full tag set in `README.md`.

---

## Delta, version 1.0 to version 1.1

| Section | Change | Tag |
|---|---|---|
| 0 | Theme 2 to theme 6 gap citations **corrected** — four of the six themes cited ranges that do not match the consolidated gap list. Same class of defect as the session's correction C-02, but found while merging and **not raised in the session** | `[RV · editorial]` |
| 0 | Theme 1 gains the fact that three of the seven session participants were describing the unbuilt authorisation model as the system's behaviour; theme 2 gains the fact that nobody decided the trust premise | `[VS · contradicts]` |
| 2.2 | SEC-05 status extended: the premise is false **and no one ever chose it**. SEC-08 extended with the exemptions file's invisibility from Confluence | `[VS · contradicts]` |
| 2.3 | PRV-04 gains the reopening of PLAT-2825-2; PRV-03 gains the confirmed warehouse fact | `[VS · confirmed]` |
| 3 | **G-35 added** from new finding O7. G-08, G-21 and G-24 extended with session facts. Gap count 34 → **35** | `[VS · new]` |
| 4 | **NIS2 row rewritten** — the determination exists and the obligation arrives contractually. **SOC 2 row rewritten** — not conditional. ISO 27001 line added | `[VS · contradicts]` |
| 5 | **SEC-39 added** from SEC-N8 and G-35 | `[VS · new]` |
| 6 | Sequence re-ordered against the 30-item action list; diagnostic routes re-sequenced; item 9 items now ratified with owners; item 10 added for the unmade decision | `[VS · corrected]`, `[VS · accepted]` |
| App. A | Privacy by Design scorecard annotated with what the session settled | `[VS · confirmed]` |
| 3, 5 | **Directed second pass, 2026-09-08.** `[DP2 · new]` **G-36 and G-37 added** from new findings AI18 and AI19. **SEC-40 and SEC-41 added.** Gap count 35 → **37**. No existing gap changed severity, category or status | `[DP2 · new]` |

---

## 0. Headline

**What is genuinely strong here, by name.** The platform baseline is real and it is carrying this pilot further than its own code would. The **egress proxy with a domain allowlist**, in place since 2023, is the single best control in the estate for a system like this. **Organisation-wide secret scanning with push protection** means that after reading every file in the repository there is not one credential literal to report. **Server-side tool authorisation** at `mcp/server.ts:41` is in the right place — the allowlist is checked at the connector, not in the prompt, which is the distinction most teams get wrong. **AWS Secrets Manager with workload identity**, **at-rest encryption on ElastiCache** and **platform logging outside the cluster** are all correct choices made without being asked.

The engineering honesty is also worth naming. Eight ADRs record the pilot's shortcuts accurately, including one whose closing section is headed *Not written back*. Chart comments record the network-policy gap. The CI file records why the scanning step is missing. The rotation runbook states plainly that there is no per-user credential to revoke. **The team knew.** This review is largely the work of taking what they already wrote down and stating the combined consequence.

What remains clusters into six themes.

1. **One credential set for everybody.** ADR-0002 routed around a blocked dependency and produced a system where the assistant reaches more than any user can. Every High and Critical finding is either this or amplified by it. The team self-identified it and tracks it at PLAT-2820-3; I am agreeing, not discovering. **G-01, G-02, G-03.** **`[VS · contradicts]` The session added the part the documents could not carry: three of the seven people present opened it describing the *approved page's* model — per-user delegated credentials — as the system's actual behaviour, including the architect who wrote the page and the epic owner who had told nine Support users that the assistant cannot see anything they cannot see. PLAT-2820 remains To Do and is not in Identity Platform's next two quarters.**
2. **Untrusted content reaches the model as instruction, and the model can write.** The trust model says web search is the only untrusted path. Four corporate connectors carry content any employee, contractor or outsider can author, and none of them is filtered — and writes execute with no confirmation. **G-04, G-05, G-14.** `[RV · editorial]` **`[VS · contradicts]` And nobody decided the premise.** The PLAT-2814 criterion behind G-05 was written as scoping, implemented as a position, written onto the approved page because the ticket and the code agreed, and assumed by Platform to be covered by a sanitiser that exists on the document-pipeline ingest path and not on this one. **The gap analysis found the missing control; it could not find that nobody chose it.** That is action 7.
3. **Defaults that widen capability.** Unconfigured workspaces get every tool; unknown workspaces get a working session; failed retrieval produces a confident answer; a rate-limited provider silently becomes a different processor. **G-17, G-27, G-28.** `[RV · editorial]`
4. **An audit trail that cannot answer an incident question.** No arguments, no acting user, no correlation identifier, and a 24-hour retention that is shorter than the time it takes to notice. **G-12, G-13.** `[RV · editorial]` **`[VS · confirmed]` Confirmed from the operational side: after two mistaken Slack posts during the pilot, Support could not tell what had been posted without asking the person who happened to see it.**
5. **Privacy obligations not yet started.** Customer correspondence is being processed with no lawful basis recorded, no notice, no assessment and no erasure route. **G-19, G-20, G-21, G-22, G-23**, with the uncontracted transfer at **G-28**. `[RV · editorial]` **`[VS · contradicts]` The Data Protection Officer's position, given in the room: not a weak basis — none. And the shared mailbox is the *primary* Support use case, not one of several, because the ticket queue does not carry the history.**
6. **Documentation that would mislead a reviewer.** Five approved statements are contradicted by the committed code, and a decision to expand would be taken against controls that do not exist. **G-32**, with the specific instances at **G-09, G-10, G-11** and **G-18**. `[RV · editorial]` **`[VS · new]` Version 1.1 adds G-35: the standing platform controls page states inherited controls without stating their coverage limits, which is how two senior people applied the egress proxy to a browser-side fetch it cannot see and how a platform sanitiser that does not cover this path was assumed to.**

**`[RV · editorial]` A note on the corrections in this section.** Four of the six theme citations above pointed at gap ranges that do not match the consolidated list in section 3 — theme 2 cited G-06 for the confirmation gate, theme 3 cited G-07 to G-10, theme 4 cited G-11, theme 5 cited G-14 to G-19 and theme 6 cited G-20 to G-24. They are repointed. This is the **same class of defect** as the session's correction C-02, which repointed four deletion-path cross-references in the architecture document, but it was found by the reviewer while merging and **was not raised in the session**. It is tagged separately so that the session record is not inflated with work the room did not do. No finding, severity or status is affected by any of it.

There is also a small set of **residual design risks worth a decision rather than a fix**: the workspace instruction field (ADR-0005), free model selection (ADR-0007), the deliberate absence of conversation backups, the three branch-protection exemptions and the portfolio's acceptance that governance is retrofitted. Each should be carried knowingly in an ADR with an owner, not quietly. **`[VS · accepted]` Four of the five were ratified with named owners in the validation session and are recorded in section 6 item 9; the exemptions were escalated to Platform Security under PLAT-1188 because they are not this team's to accept.**

Nothing here is a reason to stop the pilot. Several are reasons not to expand it yet — and the shared mailbox question was a reason to narrow it today, **which the team did: `read_mail` was set false for `ws-support` within ten minutes of the session, with the ticket queue kept in scope.** `[VS · new]`

---

## 1. Assumptions and context

| Question | Answer from the inputs |
|---|---|
| What is being built | An internal AI assistant reading across Office 365, Slack, GitHub, Confluence and the public web and writing to four of them, delivered as two Node services on EKS with Redis conversation state and a hosted model provider |
| Actors | 21 pilot users; workspace admins; platform on-call; internal and external content authors; cluster neighbours; one contracted and one uncontracted model provider account; four vendor and one community MCP server; customers whose correspondence is read |
| Data | Documents, calendar, mail, Slack channels and direct messages, issues, source code, Confluence pages, public web, conversation state, per-user telemetry. Customer personal data enters through Support's shared mailbox; special-category content is possible and unassessed |
| Deployment | Single-region eu-west-1, beta EKS cluster, Helm, IRSA, two Terraform files supplied |
| Regulatory | GDPR and UK GDPR apply. NIS2 applicability unresolved. CRA, PSTI and HIPAA out of scope. PCI-DSS conditional. SOC 2 where a report covers the estate |
| Market or expansion triggers | PROD-1131 phase 3 contemplates customer-facing surfaces and unattended operation; either would change the CRA and Article 22 positions |
| Downloadable or embedded software | None. Hosted internal service only |

**Assumptions carried:** (a) the platform gateway authenticates users, although it was not supplied; (b) the platform controls page describes controls that are live estate-wide except where the repository contradicts it; (c) `package-lock.json` is genuinely absent rather than omitted from the extract; (d) the organisation is Meridian, inferred from one workspace configuration string.

---

## 2. Requirements classification

### 2.1 Functional (FR)

| ID | Requirement | Source | Status |
|---|---|---|---|
| FR-01 | Available in Slack and in the web console | PLAT-2810 | 🟢 Live (PLAT-2831) |
| FR-02 | Answer questions using content from existing tools | PLAT-2810, PLAT-2814 | 🟢 Live |
| FR-03 | Take actions, not just read | PLAT-2810, PLAT-2817 | 🟢 Live |
| FR-04 | Users see what the assistant did | PLAT-2810, PLAT-2825 | 🟡 names only, no targets (AI13) |
| FR-05 | Users can review and delete their own conversations | PLAT-2825-2 | 🔴 delete is unwired (P4) |
| FR-06 | Connect to O365, Slack, GitHub, web search | PLAT-2814 | 🟢 Live, plus an undocumented fifth connector (O2) |
| FR-07 | Token usage tracked per team and visible to teams | PLAT-2822 | 🟢 Live |
| FR-08 | Cheaper model tiers configurable per workspace | PLAT-2822, ADR-0007 | 🟢 Live |

### 2.2 Security (SEC)

| ID | Requirement | Source | Status | Gap |
|---|---|---|---|---|
| SEC-01 | Per-user delegated credentials for every connector | PLAT-2820, D-03 | 🔵 Planned | **G-01** |
| SEC-02 | Tokens short-lived and refreshed, held in a credential store | PLAT-2820-2 | 🔵 Planned | **G-02** |
| SEC-03 | A user cannot reach through the assistant what they cannot reach directly | PLAT-2820, architecture page | 🔴 Open | **G-03** |
| SEC-04 | Web search content treated as untrusted and cleaned | PLAT-2814 | 🟡 two-phrase denylist, defeated by its own ordering | **G-04** |
| SEC-05 | Internal content is behind authentication so needs no cleaning | PLAT-2814 acceptance criterion | 🔴 the premise is false — **and `[VS · contradicts]` the premise was never anyone's decision. Written as scoping, implemented as a position, no approver** | **G-05** |
| SEC-06 | Connector scopes narrowed before general availability | PLAT-2814-6 | 🔵 Planned | **G-06** |
| SEC-07 | Single sign-on on the web console | PLAT-2831-3 | 🔵 Planned | **G-07** |
| SEC-08 | Branch protection bounds the blast radius of commits | PLAT-2817-3 comment | 🔴 three repositories exempt — **and `[VS · contradicts]` the exemptions file is not in Confluence, so a reader reasoning from the approved controls page cannot see it. `commit` removed from `ws-platform` on the day as interim containment** | **G-08** |
| SEC-09 | Diagnostic routes disabled in production | Platform controls page | 🔴 default on, chart leaves unset | **G-09** |
| SEC-10 | Default-deny network policy between namespaces | Platform controls page | 🔴 disabled in the chart | **G-10** |
| SEC-11 | Dependency scanning blocks the build on critical findings | Platform controls page | 🔴 absent, template inherited from an exempt repository | **G-11** |
| SEC-12 | Every privileged action recorded with user, action and parameters | Architecture page | 🔴 tool name and time only | **G-12** |
| SEC-13 | Actions attributable in the target system's audit log | D-03 | 🔴 shared principal downstream | **G-13** |
| SEC-14 | Encryption in transit between services and to datastores | Platform controls page | 🔴 Redis is plaintext by decision | **G-15** |
| SEC-15 | Workload identities per service, least privilege | Platform controls page | 🔴 one role, both services, wildcard secret read | **G-16** |
| SEC-N1 to SEC-N7 | *New, from the architecture pass* — confirmation gate, provenance as a data type, workload identity per hop, fail-closed defaults, an audit plane, a kill switch, a behaviour inventory | `03-security-architecture.md` §10 | 🔴 Open | **G-04, G-05, G-14, G-17, G-24** |

### 2.3 Privacy (PRV)

| ID | Requirement | Source | Status | Gap |
|---|---|---|---|---|
| PRV-01 | No new persistent stores; read from systems of record in place | D-05 | 🟡 true of content, false of telemetry and processor retention | **G-18** |
| PRV-02 | Conversation state transient, 24-hour expiry | Architecture page, ADR-0008 | 🟢 Live — *exemplary as a minimisation choice* | — |
| PRV-03 | Telemetry aggregated to team for cost attribution | PMO-0447, PLAT-2822 | 🔴 stored per user for 13 months — **`[VS · confirmed]` the row is written per request with the user identifier and anyone with warehouse access can group by user, so the purpose-limitation argument is dead** | **G-19** |
| PRV-04 | Users can delete their own conversations | PLAT-2825-2 | 🔴 unwired — **`[VS · confirmed]` `drop` was written and no route was ever wired to it; the ticket was closed on the read-back half. PLAT-2825-2 reopened by the epic owner** | **G-20** |
| PRV-05 | Lawful basis for each category of personal data | Not stated anywhere | 🔴 Open | **G-21** |
| PRV-06 | Notice to data subjects, including third parties | Not stated anywhere | 🔴 Open | **G-22** |
| PRV-07 | Data subject rights executable across all copies | Not stated anywhere | 🔴 Open | **G-20** |
| PRV-N1, PRV-N2 | *New* — deletion path and subject locator per store; retrieval minimisation | `03-security-architecture.md` §10 | 🔴 Open | **G-20, G-23** |

### 2.4 Performance (PERF)

| ID | Requirement | Source | Status | Gap |
|---|---|---|---|---|
| PERF-01 | Response under 6 seconds for a typical question | PLAT-2810 | 🟡 long conversations get slow, recorded on the data-handling page | **G-25** |
| PERF-02 | Running cost predictable and attributable | PMO-0447 | 🟡 attributable, not predictable — no enforced ceiling | **G-26** |
| PERF-03 | Graceful degradation when a dependency fails | Not stated | 🔴 degrades silently and answers anyway | **G-27** |

### 2.5 Compliance (COMP)

| ID | Requirement | Source | Status | Gap |
|---|---|---|---|---|
| COMP-01 | GDPR Article 6 lawful basis recorded per category | GDPR | 🔴 Open | **G-21** |
| COMP-02 | GDPR Article 35 assessment where risk warrants | GDPR | 🔴 Open | **G-21** |
| COMP-03 | GDPR Articles 13 and 14 notice | GDPR | 🔴 Open | **G-22** |
| COMP-04 | GDPR Article 17 erasure executable | GDPR | 🔴 Open | **G-20** |
| COMP-05 | GDPR Articles 28 and 44 to 49 — processors and transfers | GDPR | 🔴 fallback outside the DPA | **G-28** |
| COMP-06 | GDPR Article 33 breach assessment within 72 hours | GDPR | 🔴 not achievable with current evidence | **G-12** |
| COMP-07 | NIS2 applicability determined | NIS2 | 🔴 unresolved | **G-29** |
| COMP-08 | CRA applicability determined | CRA | ⚪ out of scope, recorded | — |
| COMP-09 | PSTI applicability determined | PSTI | ⚪ out of scope, recorded | — |
| COMP-10 | PCI-DSS applicability determined | PCI-DSS | 🔴 conditional, unresolved | **G-30** |
| COMP-11 | SOC 2 control coverage for this workload | SOC 2 | 🔴 multiple criteria with open findings | **G-09, G-12, G-16** |
| COMP-N1, COMP-N2 | *New* — data categories bounded by lawful basis; no prompt leaves the contracted processor set | `03-security-architecture.md` §10 | 🔴 Open | **G-21, G-28** |

---

## 3. Consolidated gap list

| Gap | Title | Severity | Type |
|---|---|---|---|
| **G-01** | Delegated per-user credentials specified, approved and never built | **Critical** | Design decision |
| **G-02** | No credential store and no per-user revocation path | **Medium** | Roadmap |
| **G-03** | Users can reach content through the assistant that they cannot open | **Critical** | Design decision |
| **G-04** | The only content control is a two-phrase denylist defeated by its own ordering | **High** | Design decision |
| **G-05** | Four corporate content paths are unfiltered on a false trust premise | **Critical** | Design decision |
| **G-06** | Connector scopes never narrowed after the prototype | **High** | Roadmap |
| **G-07** | No per-user authentication on the web console | **High** | Roadmap |
| **G-08** | Commit reach extends into repositories exempt from review — **the exemptions file is not visible from Confluence** `[VS · contradicts]` | **High** | Latent |
| **G-09** | Diagnostic routes ship enabled against the platform standard | **Medium** | Doc-drift |
| **G-10** | Network policy disabled in the cluster the pilot runs in | **High** | Doc-drift |
| **G-11** | No dependency scanning, no lockfile | **High** | Assurance |
| **G-12** | Audit record cannot answer an incident question | **High** | Design decision |
| **G-13** | Downstream attribution is a shared principal | **High** | Design decision |
| **G-14** | No confirmation or irreversibility gate on write actions | **Critical** | Design decision |
| **G-15** | Conversation store is plaintext, unauthenticated and VPC-reachable | **High** | Hardening |
| **G-16** | One IAM role for both services with wildcard secret read | **High** | Hardening |
| **G-17** | Defaults widen capability in four places | **Critical** | Design decision |
| **G-18** | The no-new-stores claim omits telemetry and processor retention | **Medium** | Doc-drift |
| **G-19** | Per-user telemetry retained 13 months for a team-level purpose | **Medium** | Compliance |
| **G-20** | No executable erasure across four stores | **High** | Compliance |
| **G-21** | No lawful basis, record of processing or Article 35 assessment | **High\*** | Compliance |
| **G-22** | No notice to employees or third parties | **Medium** | Compliance |
| **G-23** | Retrieval returns whole bodies rather than the minimum | **Medium** | Design decision |
| **G-24** | No inventory of models, prompts, connectors and tool schemas — **and all five connectors, not only the community one, are pinned to `latest`** `[VS · contradicts]` | **Medium** | Assurance |
| **G-25** | Latency and cost grow without bound inside a session | **Medium** | Hardening |
| **G-26** | Spend has no enforced ceiling | **High** | Roadmap |
| **G-27** | Partial failure is indistinguishable from a complete answer | **Medium** | Design decision |
| **G-28** | Prompts leave the contracted processor set under load | **High** | Compliance |
| **G-29** | NIS2 applicability unresolved | **Medium** | Compliance |
| **G-30** | PCI-DSS applicability unresolved for Support correspondence | **Medium** | Compliance |
| **G-31** | No kill switch and no incident response plan | **High** | Hardening |
| **G-32** | Approved design pages contradict the implementation in five places | **High** | Doc-drift |
| **G-33** | Container and pod hardening absent across image, runtime and orchestrator | **Medium** | Hardening |
| **G-34** | No governance layer above the design | **Medium** | Residual |
| **G-35** | **Inherited platform controls are published without their coverage limits** `[VS · new]` | **Medium** | Doc-drift |
| **G-36** | **No purpose boundary inside a conversation — context gathered for one task composes output for another** `[DP2 · new]` | **High** | Design decision |
| **G-37** | **The retrieval merge bounds no source and no author, and truncates silently** `[DP2 · new]` | **High** | Design decision |

\* **G-21 is conditional, and half the condition is now met.** `[VS · new]` If Support's shared mailbox is confirmed in scope **and** carries special-category content, it becomes Critical and the sequencing changes: it moves ahead of everything except G-14. The session confirmed the first half — the mailbox is in scope, it is shared, the whole team works out of it, and it is the *primary* Support use case rather than one source among several. The second half is unresolved: health information does come up in Support mail, because customers explain why they missed a delivery, but the Data Protection Officer declined to treat that as a determination from an anecdote in a meeting and the facilitator declined to move a severity on a maybe. **G-21 therefore stays High and stays conditional, and the Article 35 assessment decides.** Preliminary due 2026-09-22, owner I. Ferreira, gated on the Support data map.

**G-35 in full.** `[VS · new]` The approved platform controls page names inherited controls without stating what each one does not cover. Two live misreadings came out of the session. The **egress proxy** was applied by two senior people to a markdown-image fetch that happens in the user's browser, which no cluster egress control can see — the pack already said so in two places, and the challenge was withdrawn once the control table was read aloud. The **platform content sanitiser** was assumed to cover content arriving into a workload like this one; it exists on the document-pipeline ingest path and there is none for retrieval into a prompt, and nobody had checked, on the grounds that it is the sort of thing you assume the platform does. Neither misreading is careless and neither is specific to this workload, which is why the remedy is a coverage note on the standing page rather than a change to this design. Corresponds to finding **O7** and requirement **SEC-39**. Owner K. Osei, due 2026-09-15. The facilitator's assessment in the room was that this is worth more than the finding that surfaced it.

**G-36 and G-37 in full.** `[DP2 · new]` Both are **design decisions** rather than hardening or drift, because in each case a decision was taken, recorded in an ADR, and its consequence for this class of harm was never considered.

**G-36** is the absence of a purpose boundary inside a conversation. ADR-0008 chose a 24-hour resumable conversation so an agent can pick a thread back up after a meeting, which is a good decision for the problem it addressed. What it did not decide is what a resumed conversation may *compose from*. There is no task, purpose, subject or age field on a stored turn, the Redis key carries only the conversation identifier, the turn endpoint accepts no task identifier at all, and every stored turn — including verbatim connector results — is replayed at the head of every later prompt. Material gathered for one purpose is therefore available to write an output for another, with no attacker and no failed control anywhere in the chain. The remedy is a partition keyed on something that already exists in the work — the ticket a Support agent is on — rather than on an inferred purpose, so that it can be enforced deterministically. Corresponds to finding **AI18** and requirement **SEC-40**. It should be sequenced with, not after, the Article 35 assessment, because it changes that assessment's scope.

**G-37** is the absence of any allocation policy at the retrieval merge. ADR-0004 chose to fan out across every connector and return bodies as authored, and recorded honestly that content of differing trust would arrive in one merged list. What it did not decide is how much of that list any one source or author may occupy. The merge keeps the first eight chunks of a fixed-order concatenation; there is no score field anywhere in the path, no per-source or per-author cap, no dedupe, and no log of what the truncation discarded. The eight-chunk limit makes the problem worse rather than better, because it converts an attacker's additional content into the eviction of genuine content at a finite and small price. The remedy is not a larger limit but a fair allocation inside the existing one. Corresponds to finding **AI19** and requirement **SEC-41**. One prerequisite is worth calling out here as well as in the finding: `connectors.json` already carries a `contentIsExternal` field, nothing in the tree reads it, and it is recorded `false` for Slack while three Slack Connect channels shared with customers are covered by `search_messages`. A trust tier read from that field before it is corrected would be worse than no trust tier at all.

---

## 4. Regulatory compliance assessment

| Framework | Applicability | Position | Gaps |
|---|---|---|---|
| **GDPR / UK GDPR** | Applies | The weakest area. Processing of employee and customer correspondence with no recorded basis, no notice, no assessment, no erasure route and an uncontracted transfer path | G-19 to G-23, G-28 |
| **NIS2** | **Determined `[VS · contradicts]` — Meridian is neither an essential nor an important entity. The obligation arrives contractually instead** | Version 1.0 recorded this as unresolved and asked for a classification this week. **The classification already existed and is not new.** It does not close the obligation: two of Meridian's customers *are* in scope and the contracts with them carry it down, so supply-chain expectations bite on the connector chain and an incident notification duty attaches to a system with no detection and no kill switch — the same practical effect, by a different route. The shared console password (S5) is no longer a direct Article 21 MFA failure, but it sits inside the contractual scope and remains a High finding on its own merits. Mapping the specific clauses onto S5, RR1, RR3 and AI10 is **action 13**, owner I. Ferreira, due 2026-09-19 | G-07, G-11, G-24, G-29, G-31 |
| **CRA** | Out of scope | Internal hosted service; no product with digital elements placed on the EU market and no downloadable component. Confirm before phase 3. The SBOM and vulnerability-disclosure obligations are worth adopting regardless and are already gaps | G-11, G-24 |
| **PSTI** | Out of scope | No consumer connectable product | — |
| **PCI-DSS** | Conditional | No cardholder data environment by design, but Support correspondence and refund discussions can carry card numbers typed by customers. If confirmed, requirements 3, 4, 7 and 10 apply to a system with no argument-level audit | G-30, G-12 |
| **HIPAA** | Out of scope | No protected health information and no covered-entity relationship | — |
| **SOC 2** | **Applies. Not conditional** `[VS · contradicts]` | **Meridian is SOC 2 Type II and the report covers this estate.** Version 1.0's phrasing — "applies where a report covers the estate" — read as hedging and should not have. Logical access, encryption, monitoring and change management all carry open findings; the diagnostic routes and the exemption drift are the likeliest exceptions | G-09, G-12, G-15, G-16, G-32, G-35 |
| **ISO 27001** | **Not held** `[VS · new]` | Meridian is **not** ISO 27001 certified, and it is widely assumed internally that it is. Recorded because that assumption, left standing, would let a reader treat an ISO control set as an inherited baseline for this workload. It is not one — which is the same failure mode as G-35 | G-35 |

---

## 5. Refined requirements

The refined set is a strict superset of the original: nothing above is dropped, and every addition is marked with its provenance.

**Security.** SEC-01 to SEC-15 as classified, plus:
- **SEC-16** `[NEW — from SAC-01/G-14]` Every irreversible tool call requires a confirmation token minted by the surface and verified server-side before dispatch.
- **SEC-17** `[NEW — from AI5/G-05]` Retrieved content and tool results carry source, trust level and classification as structured fields, and are never concatenated into the user turn.
- **SEC-18** `[NEW — from S2/G-17]` Every inter-service call is authenticated by workload identity, and the connector service derives the workspace from the authenticated principal.
- **SEC-19** `[NEW — from E1/E2/G-17]` Any unknown or unconfigured workspace, tool or credential resolves to no capability and fails the turn.
- **SEC-20** `[NEW — from R1/G-12]` An audit event exists for every write action, correlated across services and retained independently of the conversation TTL.
- **SEC-21** `[NEW — from RR1/G-31]` Write capability can be disabled globally, per workspace and per tool without a deployment, by a named owner.
- **SEC-22** `[NEW — from AI10/AI11/G-24]` Models, prompt files, connector versions and tool schemas are versioned, inventoried and verified at start-up.
- **SEC-23** `[NEW — from AI2/G-14]` Tool arguments are validated against a per-tool schema with allowlisted values for recipients, channels, repositories, branches and paths.
- **SEC-24** `[NEW — from AI4/G-05]` Model output passes an output filter before rendering or transmission, and the console enforces a content security policy.
- **SEC-25** `[NEW — from C2/C3/G-33]` Both workloads run under a restricted pod security context with default-deny network policy and resource limits.
- **SEC-39** `[NEW — from O7/G-35, VS · new]` Every platform control this design relies on is cited with an explicit coverage statement naming what it does **not** cover, and no design may rest on an inherited control without one. Traced in the SRTM against SUC-38 and TA-60. Identifiers SEC-26 to SEC-38 are already in use in `05-srtm-and-test-artefacts.md`, which is why this one is SEC-39.
- **SEC-40** `[NEW — from AI18/G-36, DP2 · new]` Context assembled for a turn is bounded by the task it was gathered for. Stored turns carry a task segment identifier, the history replay includes only the current segment, and raw connector results are not replayed across segments at all. The boundary is enforced deterministically in the assembly path and does not depend on the model recognising that the purpose has changed. Traced in the SRTM against SUC-39, PUC-08 and TA-61.
- **SEC-41** `[NEW — from AI19/G-37, DP2 · new]` The retrieval set delivered to a turn has a stated and enforced allocation policy: no single connector and no single author may occupy more than a configured share of it, near-duplicate chunks from one author are collapsed, ordering is by declared source trust rather than by position in an array, and every truncation is logged with what it discarded. Traced in the SRTM against SUC-40 and TA-62.

**Privacy.** PRV-01 to PRV-07 as classified, plus:
- **PRV-08** `[NEW — from P4/G-20]` Every persisted copy of conversation content has a named deletion path and a per-subject locator.
- **PRV-09** `[NEW — from P2/G-23]` Retrieval returns the minimum content needed for the question rather than whole bodies.
- **PRV-10** `[NEW — from P3/G-19]` Telemetry is pseudonymised at write and the identified form expires on the finance cycle.

**Compliance.** COMP-01 to COMP-11 as classified, plus:
- **COMP-12** `[NEW — from G-21]` No workspace processes a data category outside its recorded lawful basis, enforced by the connector allowlist rather than by policy alone.
- **COMP-13** `[NEW — from I4/G-28]` No prompt leaves the contracted processor set under any load condition.

**Performance.** PERF-01 to PERF-03 as classified, plus:
- **PERF-04** `[NEW — from D4/G-25]` Assembled context is bounded by a token ceiling enforced before the provider call.

**Operational.** 
- **OPS-01** `[NEW — from O1/G-32]` Pilot expansion is blocked while any ADR marked as not written back is open against an approved page.

---

## 6. Recommended sequence

**Launch gates — before any expansion beyond Platform and Support**
1. **SEC-16, the confirmation gate on irreversible tools** (G-14). *The single most important item in the pack.* It is the one control that holds regardless of how content reaches the model.
2. **Narrow the reach** (G-03, G-06, G-08): Slack scopes without direct-message history, GitHub installation scoped to named repositories excluding the exempt ones, and a per-user filter at retrieval that does not wait for PLAT-2820.
3. **Close the four unauthenticated surfaces** (G-10, G-15, G-17): network policy on, connector service authenticated, Redis encrypted and authenticated, debug routes default closed. **`[VS · corrected]` The debug routes are sequenced, not flipped.** Version 1.0 listed the flag change as a same-day one-liner. It is not: the incident runbook uses those routes in production, and closing them first stops the on-call path for "the assistant did something wrong" working at all. **The authorised, audited support route is built first; the flag then defaults closed and is set explicitly in the chart.** Both parties agreed the end state in the room; the ordering is the correction. Route owner P. Raghunathan, standard owner K. Osei. **`[VS · confirmed]` The Redis transport objection recorded in `redis.tf` was confirmed by its own author as a client-library version problem, not a design constraint.** Network policy is Platform's under PLAT-2101 and carries an owner **without a date**, recorded as that rather than as a date nobody intends to meet.
4. **Invert the widening defaults** (G-17): unknown workspace and unconfigured tools both resolve to nothing.
5. **Answer the shared mailbox question and complete the Article 35 assessment** (G-21). **`[VS · new]` Done: `read_mail` was set false for `ws-support` on the day, ticket queue kept in scope, and its return is gated on the Article 35 outcome being recorded. Preliminary assessment 2026-09-22, owner I. Ferreira, gated on the Support data map from T. Egerton. The pause is two weeks and it is not a judgement on Support, who took it while saying plainly that they are not happy — both halves belong in the record.**
6. **Correct the approved architecture page** (G-32), so the expansion decision is not taken against controls that do not exist. **`[VS · new]` Requested in the room to land *before* anyone asks about a third pilot group. A divergence table covering ADR-0002, ADR-0003, ADR-0004 and ADR-0006, plus an expansion gate blocking pilot growth while an ADR marked not-written-back is open. Owner M. Oyelaran, due 2026-09-19.**

**Fast hygiene — days, cheap, no design debate**
7. Send `userId` from `gather()` (G-03, one line). Add `userId` to two log lines (G-12). Allowlist the debug configuration fields (G-09). `automountServiceAccountToken: false` and a pod security context (G-33). Namespace tool identifiers (G-24). Reorder the sanitiser so it measures what it claims (G-04). A rate limiter on `POST /turns` (G-26). Namespace the Redis key and compare the owner (G-17).

**Near-term**
8. The audit plane and correlation identifier (G-12, G-13). Structured provenance on retrieval (G-05). Output filter and content security policy (G-05). Enforced spend budgets (G-26). Lockfile, audit and SBOM steps (G-11). The graded kill switch and the response plan (G-31). Erasure path and subject locator (G-20). Telemetry pseudonymisation (G-19). Image digest pinning and signing (G-33).

**Decisions ratified, with owners** `[VS · accepted]`
9. Version 1.0 said each of these was defensible and that none was carried knowingly by a named person. **The ownership was the gap, and the session closed it.**

| Decision | Disposition | Owner | Gap |
|---|---|---|---|
| ADR-0005, unvalidated workspace instruction field | **Accepted**, with a length cap and character validation added, because the acceptance was made about tone-setting and the field now sits in front of a workspace holding `send_mail` | M. Oyelaran | — |
| ADR-0007, free model selection per workspace | **Mechanism accepted, instance rejected.** Free choice keeps cost attributable under PMO-0447; the workspace with customer data on the cheapest model is a bad instance of a reasonable rule, and it is also the workspace drafting text that goes to customers. `ws-support` moves off `aurora-1-mini`; model choice bounded by what the workspace reads | D. Whitfield | — |
| No enforced spend ceiling | **Accepted for the remainder of the pilot**, in favour of sequencing the confirmation gate first, and recorded on the ticket. Revisit at expansion. Status moves 🔵 Planned → ⚪ Accepted | D. Whitfield | G-26 |
| PR-03, AI governance retrofitted | **Accepted** — it is a portfolio decision and it stands. The local substitute recommended here, a decision register with named approvers, is the artefact that would have caught the content-trust question, and is opened with that decision as its first row | M. Oyelaran | G-34 |
| Deliberate absence of conversation backups | Unchanged; still the right trade for a 24-hour cache | — | — |
| The three branch-protection exemptions (PLAT-1188) | **Not this team's to accept.** Escalated to Platform Security's review with a specific sentence: an org-level app installed for an AI assistant can currently write to `platform-ci` on an unprotected branch, and the shared template propagates nightly | K. Osei | G-08 |

**The one item that is neither a fix nor a ratification**
10. **Own the decision that internal content does not require sanitising** (G-05). `[VS · new]` This is not remediation and it is not a risk acceptance, because there is nothing yet to accept: **the decision has never been made by anyone.** Assigned to M. Oyelaran, with data categories from I. Ferreira and pilot needs from D. Whitfield, to be written as an ADR with a named approver by 2026-09-26. It is explicitly **not** to be answered in flight, because the answer is a security position that needs the data categories in it and half the inputs are missing. It is the first row of the decision register opened under item 9.

---

## Appendix A — Privacy by Design scorecard

| PbD principle | Posture |
|---|---|
| Proactive not reactive | **Weak.** The privacy questions are written down as open questions on a draft page while the processing continues |
| Privacy as the default | **Weak.** Unconfigured workspaces read and write everything; telemetry defaults to identified; retention defaults to the storage decision rather than the purpose |
| Privacy embedded into design | **Mixed.** D-05, no new stores, is a genuinely good structural choice and it is honoured for content. It is undone by four uncontrolled copies nobody counted |
| Full functionality, positive-sum | **Strong intent.** ADR-0003 correctly refuses to make the tool unusable in the name of safety. The error is removing friction everywhere instead of placing it on irreversible actions |
| End-to-end security | **Weak.** Plaintext to Redis; **an uncontracted processor under load**; **no erasure across four stores**; **no output boundary at all** |
| Visibility and transparency | **Weak.** No notice to any data subject, and the action list shows tool names without targets |
| Respect for user privacy | **Mixed.** The 24-hour TTL and the read-in-place design respect it; the 13-month identified telemetry and the unanswerable erasure request do not |

**What the session settled against this scorecard.** `[VS · confirmed]` *Proactive not reactive* is now weaker than version 1.0 recorded, not stronger: the shared mailbox is the primary Support use case and the basis question was written down as an open item on a draft page while nine people processed customer correspondence daily. *Privacy embedded into design* is confirmed at Mixed with the reason sharpened — D-05 is genuinely good and the four uncontrolled copies are genuinely uncounted, and the deletion path for all four is one gap, G-20, not four. *Full functionality, positive-sum* is confirmed as **Strong intent, correctly identified**: the ADR-0003 measurement is real, it was defended in the room, and the recommendation was never friction everywhere — it is a token on `send_mail` and `commit` only. *Visibility and transparency* is worse than Weak in one respect: the action list is not merely thin, it is unread. The first two entries of a remedy now have owners and dates.

---

*Reflects the material as supplied on 2026-09-08 and the validation session of the same date. Ticket statuses are point-in-time. Nothing here is legal advice; the NIS2, Article 35, Article 14 and PCI-DSS determinations should be confirmed with counsel and the DPO.*
