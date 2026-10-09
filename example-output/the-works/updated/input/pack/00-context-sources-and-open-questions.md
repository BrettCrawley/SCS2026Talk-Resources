# Internal AI Assistant — Context, Sources and Open Questions

**Version:** 1.0 (first pass over the supplied Confluence, Jira and repository material) · **Date:** 2026-09-08
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this context note. Produced with AI assistance using the security-review skill set authored by **Brett Crawley, Principal Application Security Engineer**.
**Model:** Claude Opus 5
**Companion documents:** `01-security-review.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model-candidates.md` · `06-threat-model.md`

> This note exists so that every other document in the pack can be read against a known input set. It records exactly what was supplied, what was not, what had to be inferred, and what a second pass would need in order to close the questions this pass could not answer. Nothing in the pack rests on material that is not listed here.

---

## 1. What the system is

An internal AI assistant for an organisation that appears in the workspace configuration as **Meridian** (`config/workspaces.json`, the Support workspace sign-off string). It is reachable from a Slack app and a web console, reads across Office 365, Slack, GitHub, Confluence and the public web, and takes write actions — send mail, post to Slack, comment on and update GitHub issues, and commit code. It is delivered under epic **PLAT-2810**, initiative **PROD-1131**, portfolio **PMO-0447**, and is running as a pilot with two groups: Platform (12 users, since 2026-05-04) and Support (9 users, since 2026-06-09).

The organisation name is an inference from one configuration string. Everything else about the system is taken from the supplied material directly.

---

## 2. What I was given

### 2.1 Confluence design pages

| Page | Status on the page | What it settles |
|---|---|---|
| `input/confluence/architecture.md` — *Internal AI Assistant, Architecture* | **Approved**, reviewed at the Platform architecture forum 2026-05-20, last updated 2026-05-22 | Components, four connectors, authorisation model, model provider, data handling, trust model, deployment, audit, logging |
| `input/confluence/data-handling-and-pilot-ops.md` — *Data Handling and Pilot Operations* | **Draft**, written during the pilot, not reviewed, last updated 2026-06-30 | Data inventory and classification, telemetry, pilot scope, known rough edges, operational contacts, three unresolved questions |
| `input/confluence/platform-security-controls.md` — *Platform Security Controls, Standing Reference* | **Approved**, last updated 2025-11-14 | The inherited platform baseline that designs are told to cite rather than restate |
| `input/confluence/diagram1-assumed.svg` | Illustration | A hub-and-spoke trust-boundary picture titled *What most engineers assume*, showing four MCP tools inside one corporate trust zone with the internet as the only untrusted zone |

### 2.2 Jira

| Ticket | Level | Read |
|---|---|---|
| PMO-0447 | Portfolio | Objective, success measures, four delivery constraints, three portfolio risks including PR-03 |
| PROD-1131 | Initiative | Problem, three-phase approach, decisions D-01 to D-05, open items, three team dependencies |
| PLAT-2810 | Epic | Acceptance criteria for the assistant |
| PLAT-2814 (+ children 1 to 6) | Story | Connector work, including the full-scope Slack install and the unscheduled narrowing task |
| PLAT-2817 (+ children 1 to 4) | Story | Write actions, including the no-confirmation acceptance criterion and the commit-to-working-branch task |
| PLAT-2820 (+ children 1 to 3) | Story | Per-user delegated authorisation. **Status: To Do.** All three children To Do |
| PLAT-2822 (+ children 1 to 4) | Story | Cost control; spend alerting To Do |
| PLAT-2825 (+ children 1 to 2) | Story | Action visibility. Status Done |
| PLAT-2831 (+ children 1 to 3) | Story | Slack and web console surfaces; SSO To Do |

Children were followed to leaf level. Ticket comments were read and are cited where they change the security picture — in particular P. Raghunathan on PLAT-2814-3 (full Slack scope set), P. Raghunathan on PLAT-2820-3 (shared app registration), M. Oyelaran on PLAT-2817-3 (branch protection bounds the blast radius), and P. Raghunathan on PLAT-2831-3 (shared console password).

### 2.3 Repository

`input/repo`, the `assistant-platform` monorepo, version 0.4.1. Read in full: 46 files across two TypeScript services, configuration, Helm chart, two Terraform files, one GitHub Actions workflow, eight architecture decision records, three runbooks and three test files. The full file map is Appendix B of the threat model.

The README states plainly that this is a deliberately incomplete pilot written to be threat modelled, that it has not been hardened, and that where the documentation left something open the pilot picked something and recorded the choice in an ADR — and that some of those choices were never written back to Confluence. That statement is the single most useful piece of context in the pack, and it is confirmed by the material: the divergences are real and several of them are load-bearing.

### 2.4 Terraform and Helm read for organisational controls

`deploy/terraform/iam.tf`, `deploy/terraform/redis.tf`, `deploy/helm/assistant/values.yaml`, `.github/workflows/ci.yml` and `.github/branch-protection-exemptions.yml` were read specifically for controls the Confluence pages claim exist. Three of those claims are contradicted by the infrastructure as committed, and one of the contradictions is recorded in the chart itself as a deferred item against PLAT-2101.

---

## 3. What I was not given

| Missing input | Why it matters | Consequence for this pack |
|---|---|---|
| Dockerfiles and the image build definition | The image layer of the container surface cannot be assessed from the chart alone | Findings C1 and C5 rest on the chart and the platform page; both are tagged as needing a build-file pass |
| `package-lock.json` | The CI workflow runs `npm ci`, which requires a lockfile, but no lockfile is committed in the supplied tree | Dependency versions resolve from `^` ranges in the manifests. Recorded as part of O3 |
| Kubernetes manifests other than the Helm values file | Pod security context, resource limits, probes and the service account token mount are not visible | C2, C4 and C6 rest on the absence of the settings in `values.yaml` and are tagged accordingly |
| The rest of the Terraform (EKS, VPC, subnets, KMS keys, egress proxy, warehouse) | Cluster hardening, key management and the analytics warehouse cannot be assessed | The Cumulus walk records several rows as resting on the platform page rather than on code |
| Schemas for the analytics warehouse | Privacy classification of the telemetry table is taken from prose, not from DDL | P3 is tagged as resting on documentation |
| The platform gateway that `turns.ts` says authenticates callers | The strength of the outermost identity control is unknown | S1 is written as a boundary finding rather than a defect in a component I can read |
| The vendor MCP servers' code and tool schemas | Tool descriptions, parameter schemas and their update path are opaque | AI11 rests on the integration pattern, not on a specific server |
| The enterprise agreement, the DPA and the sub-processor list for the model provider | Retention, region and transfer terms cannot be verified | I4 and I5 are written from the code comments and the ADR, which contradict each other |
| Any privacy notice, record of processing, or DPIA | The lawful basis for reading correspondence cannot be checked | P1, P2 and P6 are written as gaps, not as breaches |
| The parent or programme threat model | There is no baseline to reconcile against | The threat model's Merge Reconciliation section says so explicitly |
| A previous version of this review | Nothing to diff against | The threat model carries no delta section |

---

## 4. Questions this pass could not answer, and what would answer them

1. **Is Meridian an essential or important entity under NIS2?** Needs the entity classification from Legal or the group risk function. If it is, the shared web-console password fails the MFA requirement directly and the 24-hour incident notification duty attaches to a system with no kill switch.
2. **What does the model provider's enterprise agreement actually say about retention and region?** `hosted.ts` claims zero retention under the DPA; `config.ts` records a 30-day provider retention. Needs the signed agreement and the sub-processor list.
3. **Is the public fallback endpoint covered by any contract at all?** ADR-0006 says it uses a pay-as-you-go key that predates the enterprise agreement. Needs procurement to confirm whether a DPA exists for that account and in which region it runs.
4. **Whose personal data is in Support's shared mailbox, and under what basis is it read?** The Confluence draft asks this question and does not answer it. Needs the Support data map and a DPIA decision.
5. **Has a DPIA been triggered?** Large-scale processing of employee and customer correspondence by an automated system is a strong Article 35 candidate. Needs the DPO's assessment.
6. **What happens to a conversation when the person who started it leaves?** The Confluence draft records this as unresolved. Needs a joiners-movers-leavers decision and a deletion path.
7. **Which repositories can the org-level GitHub app actually commit to?** The installation scope is not in the supplied material. Needs the app installation settings and the repository list, read against `branch-protection-exemptions.yml`.
8. **What Slack scopes were actually granted?** PLAT-2814-3 says "the full scope set". Needs the Slack app manifest and the granted scope list.
9. **Does the egress proxy allowlist include the public provider endpoint and the search API?** Needs the current allowlist from Platform Security.
10. **Is `package-lock.json` present in the real repository?** If it is, dependency pinning is better than the supplied tree suggests. Needs the actual repository head.
11. **Is there an admission controller, and does the beta cluster differ from production?** The chart disables network policy and notes the beta cluster has none. Needs the cluster configuration for the environment the pilot actually runs in.
12. **Who is allowed to stop the assistant?** The Confluence draft asks whether a kill switch is needed and who could use it. Needs a product and security decision.

---

## 5. People recorded against this work

No validation session has been held. The pack has been produced from documents and code only, and every finding in it is unvalidated until the team walks it.

**Recorded for this pass:** Brett Crawley, Principal Application Security Engineer — reviewer and author. AI assistance: Claude Opus 5.

**People the walkthrough should convene**, taken from the operational contacts table on the Confluence data-handling page and from the ticket owners:

| Area | Person | Why they are needed |
|---|---|---|
| Orchestrator and connectors | P. Raghunathan | Owns the code carrying most of the findings, and wrote the three ticket comments that record the accepted shortcuts |
| Architecture | M. Oyelaran | Owns the approved Confluence page that the implementation diverges from, and the engineering side of PROD-1131 |
| Product decisions | D. Whitfield | Owns ADR-0003 no-confirmation and the pilot-group trade-off behind it |
| Pilot coordination, Support | T. Egerton | Owns the Support use case, the shared mailbox question and the customer-data exposure |
| Platform Security | Platform Security | Owns the baseline the design cites, and the three claims the implementation contradicts |
| Identity Platform | Identity Platform | Blocks PLAT-2820, which is the root of the largest cluster of findings |
| Data Platform | Data Platform | Holds the model provider agreement and the key management for it |
| Legal and privacy | Named DPO, not supplied | Owns the NIS2 classification, the Article 35 decision and the lawful basis for reading correspondence |

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

---

*This note reflects the material as supplied on 2026-09-08. Ticket statuses are point-in-time. Nothing here is legal advice.*
