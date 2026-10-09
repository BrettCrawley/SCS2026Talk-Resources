# Internal AI Assistant — Context, Sources and Open Questions

**Version:** 1.1 (validation session of 2026-09-08 merged into the 1.0 first pass) · **Date:** 2026-09-08
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this context note and facilitator of the validation session. Produced with AI assistance using the security-review skill set authored by **Brett Crawley, Principal Application Security Engineer**.
**Model:** Claude Opus 5
**Companion documents:** `01-security-review.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model-candidates.md` · `06-threat-model.md`

**Provenance tags** — `[VS · confirmed]` · `[VS · corrected]` · `[VS · new]` · `[VS · contradicts]` · `[VS · accepted, owner: NAME]` · `[VS · moved]` mark material derived from the **validation session (VS) of 2026-09-08**. `[RV · editorial]` marks a reviewer-applied correction made while merging that was **not** raised in the session. The full tag set is defined in `README.md`.

> This note exists so that every other document in the pack can be read against a known input set. It records exactly what was supplied, what was not, what had to be inferred, and what a second pass would need in order to close the questions this pass could not answer. Nothing in the pack rests on material that is not listed here. **Version 1.1 adds a third input class: the validation session itself, which supplied facts no document in the tree contained.**

---

## Delta, version 1.0 to version 1.1

| Section | Change | Tag |
|---|---|---|
| 2 | New subsection 2.5 recording the validation session as a source | `[VS · new]` |
| 3 | Two rows updated where the session narrowed a missing input; one row added for the Support data map | `[VS · new]` |
| 4 | Four of twelve open questions closed, three partially answered, five still open. Each carries its disposition, owner and date | `[VS · confirmed]`, `[VS · contradicts]` |
| 5 | "No validation session has been held" replaced by the session record and the attendee table | `[VS · new]` |
| 6 | Reading guidance unchanged; Appendix G of the threat model added as the session record | `[VS · new]` |

---

## 1. What the system is

An internal AI assistant for an organisation that appears in the workspace configuration as **Meridian** (`config/workspaces.json`, the Support workspace sign-off string). It is reachable from a Slack app and a web console, reads across Office 365, Slack, GitHub, Confluence and the public web, and takes write actions — send mail, post to Slack, comment on and update GitHub issues, and commit code. It is delivered under epic **PLAT-2810**, initiative **PROD-1131**, portfolio **PMO-0447**, and is running as a pilot with two groups: Platform (12 users, since 2026-05-04) and Support (9 users, since 2026-06-09).

The organisation name is an inference from one configuration string. Everything else about the system is taken from the supplied material directly.

**Confirmed and sharpened in the session.** Nine of Support's nine pilot users use the assistant every day, and its Support value rests principally on `read_mail`: the ticket queue on its own does not carry the history, which lives in the mail thread. `[VS · new · T. Egerton]` Two write tools have materially different usage from what the pack assumed: `commit` has been invoked eleven times since July, nine of them by its author testing it, and Support have never held it at all. `[VS · new · P. Raghunathan, T. Egerton]`

---

## 2. What I was given

### 2.1 Confluence design pages

| Page | Status on the page | What it settles |
|---|---|---|
| `input/confluence/architecture.md` — *Internal AI Assistant, Architecture* | **Approved**, reviewed at the Platform architecture forum 2026-05-20, last updated 2026-05-22 | Components, four connectors, authorisation model, model provider, data handling, trust model, deployment, audit, logging |
| `input/confluence/data-handling-and-pilot-ops.md` — *Data Handling and Pilot Operations* | **Draft**, written during the pilot, not reviewed, last updated 2026-06-30 | Data inventory and classification, telemetry, pilot scope, known rough edges, operational contacts, three unresolved questions |
| `input/confluence/platform-security-controls.md` — *Platform Security Controls, Standing Reference* | **Approved**, last updated 2025-11-14 | The inherited platform baseline that designs are told to cite rather than restate |
| `input/confluence/diagram1-assumed.svg` | Illustration | A hub-and-spoke trust-boundary picture titled *What most engineers assume*, showing four MCP tools inside one corporate trust zone with the internet as the only untrusted zone |

**Session note on how these pages are used.** The approved architecture page is where the lead architect goes when someone asks what the system does, and he signed it off after reading ADR-0002, which contradicts it under a heading reading *Not written back*. The Platform security champion has never opened the ADRs at all. The approved pages are therefore not one source among several; for two of the three most senior readers they are **the** source. `[VS · new]` The standing controls page has a further property the pack did not record: it states inherited controls without stating their coverage limits, which is finding **O7**. `[VS · new]`

### 2.2 Jira

| Ticket | Level | Read |
|---|---|---|
| PMO-0447 | Portfolio | Objective, success measures, four delivery constraints, three portfolio risks including PR-03 |
| PROD-1131 | Initiative | Problem, three-phase approach, decisions D-01 to D-05, open items, three team dependencies |
| PLAT-2810 | Epic | Acceptance criteria for the assistant |
| PLAT-2814 (+ children 1 to 6) | Story | Connector work, including the full-scope Slack install and the unscheduled narrowing task |
| PLAT-2817 (+ children 1 to 4) | Story | Write actions, including the no-confirmation acceptance criterion and the commit-to-working-branch task |
| PLAT-2820 (+ children 1 to 3) | Story | Per-user delegated authorisation. **Status: To Do.** All three children To Do. Confirmed in the session as still To Do, requested in April, and **not in Identity Platform's next two quarters** `[VS · confirmed · P. Raghunathan]` |
| PLAT-2822 (+ children 1 to 4) | Story | Cost control; spend alerting To Do |
| PLAT-2825 (+ children 1 to 2) | Story | Action visibility. Status Done. **PLAT-2825-2 should not have been closed**: the acceptance criterion said users can review and delete, and only review shipped. The product owner accepted this in the session and the ticket is reopened `[VS · corrected · D. Whitfield]` |
| PLAT-2831 (+ children 1 to 3) | Story | Slack and web console surfaces; SSO To Do |

Children were followed to leaf level. Ticket comments were read and are cited where they change the security picture — in particular P. Raghunathan on PLAT-2814-3 (full Slack scope set), P. Raghunathan on PLAT-2820-3 (shared app registration), M. Oyelaran on PLAT-2817-3 (branch protection bounds the blast radius), and P. Raghunathan on PLAT-2831-3 (shared console password).

**Session note on the PLAT-2814 acceptance criterion.** The criterion stating that internal sources do not need the same handling as web search — the premise behind gap G-05 — was written **as scoping, not as a security position**: it was naming which connector needed the cleaning work inside a fixed date. It was then implemented as though it were a decision, written into the approved trust model because the ticket and the code agreed, and assumed by Platform to be covered by a platform sanitiser that does not exist on this path. **Nobody made the decision.** `[VS · contradicts]`

### 2.3 Repository

`input/repo`, the `assistant-platform` monorepo, version 0.4.1. Read in full: 46 files across two TypeScript services, configuration, Helm chart, two Terraform files, one GitHub Actions workflow, eight architecture decision records, three runbooks and three test files. The full file map is Appendix B of the threat model.

The README states plainly that this is a deliberately incomplete pilot written to be threat modelled, that it has not been hardened, and that where the documentation left something open the pilot picked something and recorded the choice in an ADR — and that some of those choices were never written back to Confluence. That statement is the single most useful piece of context in the pack, and it is confirmed by the material: the divergences are real and several of them are load-bearing. **The session confirmed every code-level citation put to it without exception.** The engineer who built the pilot read the pack twice looking for something wrong and found two items, both recorded as corrections C-01 and C-02 in `README.md`; one of the two is the reviewer's own error. `[VS · confirmed]`

### 2.4 Terraform and Helm read for organisational controls

`deploy/terraform/iam.tf`, `deploy/terraform/redis.tf`, `deploy/helm/assistant/values.yaml`, `.github/workflows/ci.yml` and `.github/branch-protection-exemptions.yml` were read specifically for controls the Confluence pages claim exist. Three of those claims are contradicted by the infrastructure as committed, and one of the contradictions is recorded in the chart itself as a deferred item against PLAT-2101.

**Session note on the exemptions file.** `.github/branch-protection-exemptions.yml` is not referenced from Confluence anywhere. It is a configuration file in the org repository, and a reader reasoning from the approved controls page cannot see it. Neither the lead architect nor the Platform security champion knew it existed, and both had been citing the estate-wide statement in good faith. The file predates this pilot. `[VS · new · P. Raghunathan]`

### 2.5 The validation session — a third input class `[VS · new]`

A 74-minute walkthrough on **2026-09-08, 14:00 to 15:14**, meeting room 4C and dial-in, facilitated by Brett Crawley. Material reviewed: all eight documents of the 1.0 pack with the README index. Method: three dispositions per finding — confirmed, corrected, or accepted with a named owner — recorded aloud at the time so participants could object at the time rather than to the minutes. Nothing came down without evidence and nothing went up without evidence.

The session supplied four facts held by the room and absent from every document in the supplied tree: two counts, one version string and one contract. They are tabulated in `README.md` and each is carried into the finding it affects. The full record, including the per-finding disposition table and the 30-item action list, is **Appendix G of `06-threat-model.md`**.

---

## 3. What I was not given

| Missing input | Why it matters | Consequence for this pack |
|---|---|---|
| Dockerfiles and the image build definition | The image layer of the container surface cannot be assessed from the chart alone | Findings C1 and C5 rest on the chart and the platform page; both are tagged as needing a build-file pass. Not resolved in the session |
| `package-lock.json` | The CI workflow runs `npm ci`, which requires a lockfile, but no lockfile is committed in the supplied tree | **Confirmed absent in the real repository**, not an artefact of the extract: `npm ci` runs without one and the `^` ranges resolve fresh every build. Recorded as part of O3 `[VS · confirmed · P. Raghunathan]` |
| Kubernetes manifests other than the Helm values file | Pod security context, resource limits, probes and the service account token mount are not visible | C2, C4 and C6 rest on the absence of the settings in `values.yaml` and are tagged accordingly. Not resolved in the session |
| The rest of the Terraform (EKS, VPC, subnets, KMS keys, egress proxy, warehouse) | Cluster hardening, key management and the analytics warehouse cannot be assessed | The Cumulus walk records several rows as resting on the platform page rather than on code |
| Schemas for the analytics warehouse | Privacy classification of the telemetry table is taken from prose, not from DDL | **Narrowed in the session**: the per-request row carries the user identifier and anyone with warehouse access can group by user. P3's purpose-limitation argument is therefore settled on fact rather than on prose `[VS · confirmed · P. Raghunathan]` |
| The platform gateway that `turns.ts` says authenticates callers | The strength of the outermost identity control is unknown | S1 is written as a boundary finding rather than a defect in a component I can read. Not resolved in the session |
| The vendor MCP servers' code and tool schemas | Tool descriptions, parameter schemas and their update path are opaque | AI11 rests on the integration pattern, not on a specific server. **Confirmed in the session by the lead architect**, who had not considered that description text arrives from a vendor over the wire and functions as instruction `[VS · confirmed · M. Oyelaran]` |
| The enterprise agreement, the DPA and the sub-processor list for the model provider | Retention, region and transfer terms cannot be verified | I4 and I5 are written from the code comments and the ADR, which contradict each other. **Still missing.** Data Platform hold it; the DPO is requesting it and wants the answer regardless of this system (action 23) |
| Any privacy notice, record of processing, or DPIA | The lawful basis for reading correspondence cannot be checked | P1, P2 and P6 are written as gaps, not as breaches. **The DPO confirmed in the session that there is no basis recorded — not a weak basis, none** `[VS · confirmed · I. Ferreira]` |
| **The Support data map** `[VS · new]` | Needed before the Article 35 assessment can determine whether special-category content is present in the shared mailbox | Requested from T. Egerton in the session. Gates the conditional half of G-21 and the return of `read_mail` to `ws-support` |
| The parent or programme threat model | There is no baseline to reconcile against | The threat model's Merge Reconciliation section says so explicitly |
| A previous version of this review | Nothing to diff against | **Resolved for 1.1**: version 1.0 is the baseline, and every document now carries a delta table against it |

---

## 4. Questions this pass could not answer — and their disposition after the session

Four are closed, three are partially answered, five remain open. Each open question now carries an owner and a date rather than sitting as a question.

### Closed by the session

1. **Is Meridian an essential or important entity under NIS2?** **CLOSED. No.** The determination has been made and is not new. `[VS · contradicts · I. Ferreira]` **The obligation is not closed by that answer, which is the part that matters:** two of Meridian's customers *are* in scope, and the contracts with them carry the obligation down. It therefore arrives contractually rather than by direct applicability, and the practical effect on this system is the same — supply-chain expectations on the connector chain, and an incident notification duty that would be hard to meet with a system that has no detection and no kill switch. The pack's framing of "unresolved and material, pending a classification" is superseded. Mapping the contractual obligations onto S5, RR1, RR3 and AI10 is action 13, owner I. Ferreira, due 2026-09-19.

2. **Is `package-lock.json` present in the real repository?** **CLOSED. No.** `npm ci` runs without one and the ranges resolve fresh every build. O3 stands as written. `[VS · confirmed · P. Raghunathan]`

3. **Does the egress proxy allowlist include the public provider endpoint and the search API?** **CLOSED in effect, adversely.** The fallback entry was added during the June incident, and Platform's security champion would be surprised if it went through the weekly review. **CL4 stands as written.** `[VS · confirmed · K. Osei]`

4. **Who is allowed to stop the assistant?** **CLOSED in principle, with the design outstanding.** Support on-call may disable the Support workspace without paging Platform; that requirement is now in the design. Graded flags — global, per workspace, per tool, changeable without a deployment — are action 15: design M. Oyelaran, build P. Raghunathan, due 2026-10-03. `[VS · new]`

### Partially answered

5. **Whose personal data is in Support's shared mailbox, and under what basis is it read?** **The mailbox is confirmed shared** — one mailbox, the whole team works out of it — **and it is the primary use case, not one of several.** `[VS · contradicts · T. Egerton]` The basis question is unanswered: there is no lawful basis recorded, no record of processing, no Article 35 assessment, no notice to customers and no notice to the third parties named inside their mail. `read_mail` was set false for `ws-support` on the day, with the ticket queue kept in scope. Needs the Support data map. Owner I. Ferreira, preliminary assessment 2026-09-22.

6. **Has a DPIA been triggered?** **Not yet run, and a strong Article 35 candidate on the face of it** — large-scale automated processing of correspondence. Health information does come up in Support mail, because people explain why they missed a delivery; **the DPO declined to treat that as a determination of special-category content from an anecdote in a meeting, and the facilitator declined to move a severity on a maybe.** G-21 therefore stays conditional and the assessment decides. `[VS · new]` Owner I. Ferreira, preliminary 2026-09-22.

7. **What happens to a conversation when the person who started it leaves?** Still unanswered as a policy, but the mechanism is now owned: `history.drop()` wired to an authenticated delete route with the ownership check, plus a leaver hook and a per-subject locator across the four stores. PLAT-2825-2 reopened. Action 18: D. Whitfield (ticket), P. Raghunathan (build), due 2026-10-10.

### Still open

8. **What does the model provider's enterprise agreement actually say about retention and region?** `hosted.ts` claims zero retention under the DPA; `config.ts` records a 30-day provider retention. Data Platform hold the agreement. **I5 stays Open pending it.** `[VS · confirmed]` Owner I. Ferreira with Data Platform, action 23, due 2026-09-26.

9. **Is the public fallback endpoint covered by any contract at all?** ADR-0006 says it uses a pay-as-you-go key that predates the enterprise agreement. Needs procurement to confirm whether a DPA exists and in which region it runs. Same action and owner as question 8.

10. **Which repositories can the org-level GitHub app actually commit to?** Nobody in the room could answer; it needs the installation settings. **E6 keeps its evidence tag — it rests on a ticket comment, not on a scope list, and the pack is right to say so.** `[VS · confirmed]` The lead architect is pulling the installation settings and scoping it to a named list excluding `platform-ci`, `legacy-billing-adapter` and `infra-bootstrap`. Action 4, owner M. Oyelaran, due 2026-09-12.

11. **What Slack scopes were actually granted?** PLAT-2814-3 says "the full scope set", which is a phrase, not a list. The engineer who wrote that comment does not have the manifest either — **IT performed the install.** `[VS · new · P. Raghunathan]` **E5 keeps its evidence tag.** Action 24, owner M. Oyelaran, due 2026-09-26.

12. **Is there an admission controller, and does the beta cluster differ from production?** Still unanswered. Network policy is Platform's, tracked at PLAT-2101, and **no date could be given in the session** — recorded as an owner without a date rather than as a date nobody intends to meet. `[VS · confirmed · K. Osei]` Owner K. Osei, part of action 21.

---

## 5. People recorded against this work

**A validation session has been held.** It ran on **2026-09-08, 14:00 to 15:14**, facilitated by Brett Crawley, Principal Application Security Engineer. Every finding in the pack now carries a disposition from it. The full record is **Appendix G of `06-threat-model.md`**.

**Recorded for the 1.0 pass:** Brett Crawley, Principal Application Security Engineer — reviewer and author. AI assistance: Claude Opus 5.

**Attendees of the validation session** `[VS · new]`

| Name | Role | What they carried out of the session |
|---|---|---|
| **Brett Crawley** | Principal Application Security Engineer (facilitator) | Corrections C-01 and C-02 into the pack; the session record in Appendix G; the action list |
| **Dana Whitfield** | Epic owner, Product | AI3 acceptance withdrawn and the confirmation work co-owned; AI12 accepted with `ws-support` moved off `aurora-1-mini`; D2 accepted for the pilot; PLAT-2825-2 reopened |
| **Marcus Oyelaran** | Lead architect | The correction to the approved architecture page and its divergence table; the GitHub installation scope; the content-trust ADR; RR1 and RR3 design; T2 and O6 accepted with ownership |
| **Priya Raghunathan** | Senior engineer, built the pilot | The same-day configuration changes; the fast code fixes; the support route; connector pinning; the audit event; the erasure path |
| **Tom Egerton** | Engineering manager, Support | The shared-mailbox facts, the Slack Connect channels, the two-week `read_mail` pause, the Support data map |
| **Ines Ferreira** | Data Protection Officer | The Article 35 assessment and lawful basis; the NIS2 and SOC 2 corrections; the Article 14 position; telemetry pseudonymisation; the processor agreement |
| **Kwame Osei** | Security Champion, Platform | The branch-protection exemptions to Platform Security; the egress-proxy coverage note; PLAT-2101; the diagnostic-routes standard |

**Teams still needed and not in the room**

| Area | Who | Why |
|---|---|---|
| Identity Platform | Identity Platform | Blocks PLAT-2820, the root of the largest cluster of findings. Not in their next two quarters |
| Platform Security | Platform Security review board | Owns PLAT-1188, the three branch-protection exemptions. Escalation is action 5 |
| Data Platform | Data Platform | Holds the model provider agreement and the key management for it. Actions 19 and 23 |
| IT | IT service desk | Performed the Slack app install and holds the manifest. Action 24 |
| Legal | Legal | Not required for NIS2 after all — the determination already existed. Still relevant to the contractual mapping in action 13 |

---

## 6. How to read the rest of the pack

| File | What it is | Read it when |
|---|---|---|
| `01-security-review.md` | Executive verdict and gate readiness | First, if you have ten minutes |
| `02-use-abuse-and-security-privacy-use-cases.md` | Use cases, abuse cases, countermeasures | When you want the attacker's story before the finding list |
| `03-security-architecture.md` | The system as designed and as built, then the target design | When you want the shape of the system and what has to change structurally |
| `04-gap-analysis.md` | Required versus built, with a consolidated gap list | When you are planning the work |
| `05-srtm-and-test-artefacts.md` | Requirement to threat to control to test | When you are proving the work is done |
| `06-threat-model-candidates.md` | The elicitation record, one row per prompt | When you want to know whether a question was asked |
| `06-threat-model.md` | The findings themselves, with worked examples and the risk register | When you want the detail |
| `06-threat-model.md` **Appendix G** | The session validation log: attendees, per-finding dispositions, corrections, accepted risks, movements, actions | **When you want to know what the team said about a finding, and who owns it now** |

---

*This note reflects the material as supplied on 2026-09-08 and the validation session of the same date. Ticket statuses are point-in-time. Nothing here is legal advice.*
