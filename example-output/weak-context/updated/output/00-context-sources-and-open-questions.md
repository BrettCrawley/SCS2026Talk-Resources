# Internal AI Assistant (PLAT-2810) — Context, Sources & Open Questions

**Version:** 1.1 (validation-session merge) · **Date:** 2026-09-09
**Supersedes:** version 1.0 of 2026-09-09, the pre-session pack. Delta at §0.
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this document; produced with AI assistance.
**Model:** Claude Opus 5
**Validated:** validation session of 2026-09-09, 14:00 to 15:35, facilitated by Brett Crawley, with Dana Whitfield, Marcus Oyelaran, Priya Raghunathan, Tom Egerton, Ines Ferreira and Kwame Osei. Log at `06-threat-model.md` Appendix G.
**Companion documents:** `01-security-review.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md` · `06-threat-model-candidates.md`
**Method:** Source inventory and evidence audit, run before the analysis so that every downstream finding can be traced to something that was actually read. Version 1.1 adds one source — the validation-session transcript — and records which of the twenty open questions it answered.

**Session provenance.** Claims added from the validation session are tagged **`[session 2026-09-09]`**, with the speaker named where they assert a fact about the running system. Contradictions of version 1.0 are marked **`[contradicts v1.0]`** and stated rather than edited away.

> This document exists because the review was asked to draw on Confluence design pages, a Jira PMO/PMI ticket tree and extracted git repositories, and **only one of those three source classes was present**. It records exactly what was supplied, exactly what was not, what each absence costs the analysis, and what would be needed to close it. Read it before the other five documents: it is the calibration for how much weight each finding can carry. **In version 1.1 it also records what the owners supplied verbally when they walked the pack, and — more usefully — what they still could not answer.**

---

## 0. What changed from the previous pass

| Version 1.0 position | What the validation session established | Verdict |
|---|---|---|
| Three files, 160 KB, in `./input` | A fourth source: `input/transcript/transcript.md`, the validation-session transcript `[session 2026-09-09]` | **Source list extended** — §1 and §6 |
| Twenty open questions, none answered | **Three answered in whole or part:** Q13 (which MCP servers, at what versions, who may add one) fully; Q12 (what CI does with an assistant commit) partly; Q8 (framework position) partly. **Q7 confirmed for today's build and left open for the target design** | **§5 annotated question by question** |
| Q1 — whose credentials — expected to be answered by the owners | Four statements of intent, no configuration read. **Still outstanding**, evidence due 2026-09-10 | **Still open**, and the six dependent findings did not move |
| Assumption (e): retrieval is live query, flagged as a guess | Correct for what runs today, and explicitly **not** settled for the target design once the six-second number is chased `[session 2026-09-09 · Priya Raghunathan]` | **Confirmed for today, open for the target** — AI13 stays tagged |
| *"No mitigation can be credited to a ticket, because no ticket claims one"* — with the implication that no baseline exists | **Contradicted.** A platform baseline exists — egress proxy, org-wide branch protection, controls page — and was not supplied to the review. Two of its controls were examined and neither closed the finding it was offered against `[session 2026-09-09]` | **§2 and §3 corrected; net-new finding O6** |
| §4's diagram-versus-tickets reconciliation was *"the one reconciliation available"* | A second became available: **artefact against decision.** Asking who decided each documented position produced the answer *nobody*, four times over | **New §4.1; net-new finding O5** |
| *"No validation session with the solution owners has taken place"* | It has. §7 is rewritten | **Superseded** |

---

---

## 1. What I was given

Three files, 160 KB in total, in `./input`.

| # | File | Size | What it is |
|---|---|---|---|
| 1 | `plat-2810-epic.md` | 2,550 bytes | A Jira epic and its four child stories, as markdown. Descriptions and acceptance criteria only. |
| 2 | `diagram1-assumed.svg` | 4,065 bytes | A trust-boundary sketch titled *"What most engineers assume"*, subtitled *"A tidy boundary at every connection; the internet is the only untrusted zone"*. |
| 3 | `diagram1-assumed.png` | 151,704 bytes | A raster render of file 2. Same content. |
| 4 | `transcript/transcript.md` `[session 2026-09-09]` | — | **Added for version 1.1.** The transcript of the validation session of 2026-09-09, 14:00 to 15:35: seven attendees, twelve sections, eighteen actions and a dispositions list. It is testimony, not configuration. |

**How the transcript is weighted, and why it matters.** A transcript records what people said, not what the system does. Version 1.1 therefore treats a statement about configuration as evidence of what somebody believes rather than as a configuration fact, and re-rates nothing on it unless the speaker was reading the configuration when they said it. **The worked example is question Q1 below**, where four people stated the same intent — per-user delegated credentials — confidently and consistently, and six findings did not move, because the one person who could read the app registration would not confirm it from memory. Where a statement *was* a direct read of the running system — that the five MCP servers resolve to `latest`, that the Support mailbox is connected as a shared mailbox, that per-user metering rows sit in the warehouse — it is treated as fact and named to its speaker.

**Artefacts named in the session and still not supplied.** Each of these was referred to as existing and none has been read: **ADR-0004** (web-content cleaning); the **standing platform controls page**; the **branch-protection exemption list**, held as a config file in the org repo; the **MCP client configuration**; the **OAuth app registrations and granted scopes per connector**; the **egress proxy allow-list**; and the **warehouse schema** for the metering events. They are listed by name so the next pass asks for them individually rather than as a category — which is how they were missed the first time.

### 1.1 The ticket tree, in full

The entire ticket corpus is five issues. There are no others in the input, and no export metadata, comments, attachments, linked issues, sub-tasks or status history.

| Ticket | Type | Parent | Substance |
|---|---|---|---|
| **PLAT-2810** | Epic | — | Internal AI assistant. Answers plain-language questions across existing tools and acts on what it finds. Pilot with Platform and Support, then open up. Acceptance criteria: available in Slack and web console; answers from existing tools; takes actions; users see what it did; under 6 seconds for a typical question. |
| **PLAT-2814** | Story | PLAT-2810 | Connectors: Office 365 documents and calendar, Email, Slack, GitHub issues/PRs/code, Web search. Acceptance criterion states web-search content is untrusted and cleaned, **and that internal sources are already behind authentication so they do not need the same handling**. |
| **PLAT-2817** | Story | PLAT-2810 | Actions: send email, post to Slack, comment on and update GitHub issues, commit changes. Acceptance criterion states actions happen **without a separate confirmation step**, on pilot-group feedback that a confirm dialog would make the assistant slower than doing the work by hand. |
| **PLAT-2822** | Story | PLAT-2810 | Cost control: token usage tracked per team, teams see their own consumption, smallest acceptable model per task, cheaper model tiers configurable per workspace. |
| **PLAT-2825** | Story | PLAT-2810 | Visibility: actions taken are shown in the conversation; a user can review their own history. |

The file's own opening line reads: *"Supplied alongside `diagram1-assumed.svg`. Nothing else. No repository."* It also carries the line *"Fictional. For conference demonstration purposes."* — the system is a scenario, and this review treats it as a real design submission, which is what a scenario is for.

### 1.2 The diagram, and what it asserts

The sketch places the **User** in a trusted box, an **AI agent / LLM** ("reasoning loop") in the middle, a dashed **"Corporate trust zone"** containing Office 365, Email, Slack and GitHub as MCP servers, and **Web search (MCP)** outside it labelled *"The one untrusted edge"*, connected onward to *"Internet (untrusted)"*. Two crossings are annotated `boundary`: user-to-agent, and agent-to-corporate-zone.

Its title says it is what engineers *assume*, not what is true. The analysis takes it at face value as the team's working trust model, because it is the only trust model supplied and it agrees exactly with the acceptance criterion in PLAT-2814. Where the model is wrong, that is finding **O1** in the threat model, not a note in the margin.

---

## 2. What I was not given

The engagement named three source classes. One was present.

| Source class named in the request | Present? | Consequence for the analysis |
|---|---|---|
| **Confluence design documents** | **No.** No design pages, ADRs, RFCs or architecture notes of any kind. | There is no stated architecture. The component decomposition in `03-security-architecture.md` is **reconstructed from the acceptance criteria**, not validated against a design. Every component in it is inferred. |
| **Jira PMO / PMI tickets, following children** | **Partially.** Five PLAT-* issues in one markdown file. **No PMO-* or PMI-* tickets exist in the input at all**, and no children beyond the four stories above. | No programme-level context, no delivery milestones, no existing remediation tickets to record mitigations against. Every mitigation status in the risk register is therefore 🔴 Open or 🔵 Planned; **none can be recorded as 🟢 Mitigated, because no ticket in the input asserts that any control has been built.** This is a property of the input, not a judgement about the team. |
| **Git repositories (source, Terraform, Helm)** | **No.** No repository, no source file, no infrastructure-as-code, no Helm chart, no Dockerfile, no CI definition, no dependency manifest. | The requested design-versus-implementation reconciliation **cannot be performed**. There is no implementation to compare the documentation against. §4 below records the one reconciliation that *is* possible. The cloud and container threat surfaces are unevidenced and are recorded out of scope in the threat model with this reason. |

Also absent, and material:

- **Data schemas** — no DDL, migrations, ORM models or ERDs. Personal-data classification in `03-security-architecture.md` §2.4 is derived from what the connectors necessarily carry, not from any column list. Every encryption-at-rest and retention finding is inferred and tagged accordingly.
- **Identity and access design** — no IdP, no OAuth scope definitions per connector, no statement of whether the assistant holds delegated per-user tokens or a shared service principal. This single unknown changes the severity of six findings.
- **Deployment topology** — no cloud provider, region, account structure, network design or tenancy model.
- **Model provider and contract** — the model is unnamed. No DPA, no data-handling terms, no residency commitment, no statement about whether prompts are retained or used for training.
- **Privacy artefacts** — no privacy notice, no record of processing, no DPIA, no retention schedule, no sub-processor list.
- **Non-functional requirements** other than latency (6 seconds) and cost. There is no security, availability, integrity or compliance acceptance criterion anywhere in the five tickets. That absence is itself finding **O4**.
- **Parent or programme threat model**, and **no previous version of this threat model**. The Merge Reconciliation section is therefore empty by fact, and the "What changed from the previous pass" section is correctly absent.
- **Logging, monitoring and incident-response design.**
- **Any evidence that a control exists.** Nothing in the *supplied* input describes a control that has been built. **This is corrected in version 1.1** `[contradicts v1.0]` `[session 2026-09-09 · Kwame Osei]`**: controls do exist — a deny-by-default platform egress proxy, org-wide branch protection, and a standing controls page covering transport, secret handling and log retention. None of it was supplied to the review.** The distinction is not academic. Version 1.0 rated the register as though no baseline existed; the correct statement is that a baseline exists and was not evidenced, which is a different failure and one the pack could have named more precisely. What the session then established is why nothing has been credited even now: two of those controls were offered against two findings and **neither closed the finding it was offered against** — the egress proxy does not reach **AI25**, whose fetches happen outside the cluster, and org-wide branch protection does not reach **T2**, because the assistant commits to an unprotected working branch and a standing exemption for `platform-ci` sits in a config file the controls page does not reference. That pattern is finding **O6**.

---

## 3. What this costs, stated plainly

1. **Every finding is a design-time finding.** None rests on a line of code. Where a finding asserts a property of an implementation, it is tagged *"if present"* and names the check that would confirm it.
2. **Two threat surfaces were not walked.** The Cumulus cloud instrument (60 prompts) and the container instrument (25 prompts) are recorded `not in scope` in the candidate register, with the reason: no infrastructure-as-code, deployment topology, cluster or registry information was supplied, so there is nothing to walk them against. This is a gap in the input, not a judgement that the surfaces are absent — a system of this shape almost certainly runs on cloud infrastructure in containers. The next-iteration pointer in `06-threat-model.md` §12 asks for exactly what is needed.
3. **The instruments that were walked, were walked in full.** STRIPED (57 prompts), LINDDUN and the AI-specific privacy categories (9), privacy dark patterns and human-centered security (16), the Elevation of Autonomy deck (30 cards) and the AI extension instrument (20 prompts) — 132 prompts, every one recorded with an outcome in `06-threat-model-candidates.md`.
4. **No mitigation can be credited to a ticket, because no ticket claims one.** The request asked for existing mitigations to be recorded against each threat with the relevant ticket ID and a status. Where a ticket *does* speak to a threat, it is recorded — but in this input every such reference is a ticket that **creates** the exposure (PLAT-2814 and PLAT-2817 in particular), not one that closes it. The register carries those references in the Mitigation column, honestly labelled.

---

## 4. The one reconciliation available: diagram versus tickets

With no repository, design-versus-implementation reconciliation is impossible. Design-versus-design reconciliation is not, and it is productive.

| Claim | Where it is made | What the other source shows | Verdict |
|---|---|---|---|
| The internet, reached through web search, is the only untrusted zone | `diagram1-assumed.svg`; PLAT-2814 acceptance criterion | PLAT-2814 also connects Email and GitHub. An email body is written by whoever sent it, including anyone on the internet. A GitHub issue or pull-request body on a public repository is written by whoever opened it. Both cross into the model's context. | **Contradiction.** The two connectors most exposed to attacker-authored text sit inside the box labelled trusted. Finding **AI1**, and the trust-model error itself is **O1**. |
| The corporate trust zone contains four MCP servers | `diagram1-assumed.svg` | PLAT-2814 lists five connectors. Web search is drawn outside the zone, which is consistent — but the diagram shows no web console, though PLAT-2810 requires one. | **Omission.** The diagram has no node for a second entry point that the epic makes an acceptance criterion. Finding **O1**. |
| Actions are visible to the user | PLAT-2825 | The diagram has no audit store, no history store and no conversation store, so there is no component to hold the history PLAT-2825 requires, and no boundary drawn around it. | **Omission.** Findings **O1**, **R1**. |
| Token usage is tracked per team | PLAT-2822 | The diagram has no metering component and no model provider node at all — the LLM is drawn as if it were inside the same box as the reasoning loop. | **Omission.** The single most sensitive data flow in the system — corporate content leaving for a third-party inference service — is not on the diagram. Findings **O1**, **I6**. |
| Content from web search is cleaned before use | PLAT-2814 | No ticket says what "cleaned" means, what performs the cleaning, or what it removes. Nothing states it applies to the other four connectors. | **Undefined control.** Recorded as such; a control with no definition cannot be credited. Finding **AI1**. |

### 4.1 A second reconciliation, available only after the session: artefact versus decision

**Version 1.0 called §4 "the one reconciliation available". The validation session made a second one possible** `[session 2026-09-09]`, and it is the one that produced the most uncomfortable finding in the pack. It is neither design-versus-implementation nor design-versus-design. It asks, of each documented position: **who decided this?** — and requires the answer to be a person rather than another document.

| Documented position | Where it is stated | Who decided it | Verdict |
|---|---|---|---|
| Internal sources need no untrusted-content handling because they are behind authentication | PLAT-2814 acceptance criterion | **Nobody.** Written as a scoping note about where to spend build effort: five connectors, one obviously needing a sanitiser, and the author did not want one built for five. Confirmed in the room as a product note and explicitly not a security position `[session 2026-09-09 · Dana Whitfield]` | **Unowned decision.** Finding **O5** |
| Web-search content is cleaned; the other four connectors are not | ADR-0004 | The ADR's stated reason is that web search is the connector PLAT-2814 identified as untrusted. **The ADR defers to the ticket** `[session 2026-09-09 · Priya Raghunathan]` | **Circular citation.** The implementing engineer read the criterion as a security position *because it gives a reason, and the reason sounds like an argument* |
| The trust model treats the four internal connectors as trusted | Architecture page | Written against two artefacts that agreed with each other, which was taken as evidence that the question had been assessed `[session 2026-09-09 · Marcus Oyelaran]` | **Inherited, not assessed.** Findings **O5**, **O1** |
| Content ingested by the assistant is covered by the platform sanitiser | Nowhere. Assumed | **Nobody.** The platform sanitiser sits on the ingestion services; the assistant's connectors call the MCP servers directly, so it is not in that path `[session 2026-09-09 · Kwame Osei, Priya Raghunathan]` | **Assumed control that does not exist on this path.** Findings **O5**, **O6** |
| Branch protection is enforced on every repository in the organisation | Standing controls page | True as written, and it carries a standing exemption list — `platform-ci`, no expiry — held as a config file in the org repo that the controls page does not reference `[session 2026-09-09 · Priya Raghunathan]` | **Documented control diverges from enforced control.** Finding **O6** |

**The finding is the pattern, not any one row.** Each artefact is correct read on its own, and each cites another. That is not a failure of care by any individual — it is a loop with no weak link, which is exactly why it survived four months and a design review. The facilitator declined to resolve the content-trust question in the room, on the ground that deciding it there would repeat the thing that went wrong; the remediation is therefore an owner and a written decision rather than an answer (**O5**, Marcus Oyelaran, 2026-09-19).

---

## 5. Questions I could not answer, and what I would need

Grouped by what unblocks them. These are the intake questions from house style §7 that the input does not answer.

**Status after the validation session** `[session 2026-09-09]`**: three of twenty answered in whole or part, and one confirmed for today's build only.** A **Session status** column has been added to each table. Seventeen remain open, and the two that matter most — Q1 on the credential model and Q6 on the model provider — are open for opposite reasons: Q1 because nobody read the configuration, Q6 because the artefact does not exist.

### 5.1 Identity — six findings' severity depends on these

| # | Question | What I need to answer it | Session status `[session 2026-09-09]` |
|---|---|---|---|
| Q1 | When the assistant calls the Office 365 connector for user A, does it present a token scoped to user A, or a shared application credential? | The OAuth application registrations and granted scopes per connector, or the connector configuration. | **Outstanding — and the record of why is the point.** Three people stated the intent independently and consistently: per-user delegated, the assistant acts as the requesting user, the source system decides, and it is written in the present tense on the architecture page. The engineer who built the pilot declined to confirm it from memory, not having set all the scopes up. **Four recollections of an intent are not a configuration fact, and I2, E1, E2, E4, R3 and AI8 did not move.** Evidence due 2026-09-10 (action 1). One qualification survives whatever the answer is: per-user entitlement narrows nothing on the shared Support mailbox, because the whole team may read all of it — recorded at **P2** |
| Q2 | Is the Slack identity of a user bound to the same corporate identity as their web-console session, and by what? | The IdP configuration and the Slack app's installation and authentication design. | **Outstanding.** Not reached; folded into the platform controls mapping in action 7 |
| Q3 | What revokes the assistant's access when someone leaves or changes role? | The joiner-mover-leaver process as it applies to connector grants. | **Outstanding.** Not reached |
| Q4 | Can a user reach the assistant's history for a conversation they did not start? | The conversation and history data model, and the authorisation check on the history read path. | **Outstanding.** Not reached |

### 5.2 Data — the whole privacy assessment rests on these

| # | Question | What I need to answer it | Session status `[session 2026-09-09]` |
|---|---|---|---|
| Q5 | What is persisted from a conversation, where, for how long, and what deletes it? | The schema for the conversation and history stores, plus a retention schedule. | **Outstanding.** Not reached. One adjacent fact did land: the metering events reach the warehouse **per user**, and the aggregation to team happens in the dashboard query rather than the pipeline — see **P6** |
| Q6 | Which model provider, under what contract, in which region, and are prompts retained or used for training? | The vendor contract, DPA and the model-provider configuration. | **Outstanding, and the reason is worse than "not stated".** Asked directly, the room could not name the provider — *"it's whatever the tier router is pointed at"*. The engineer knows the endpoint and the billing account and has never seen a contract; **the Data Protection Officer, who would have signed one, has never been shown one either.** The transfer has been running since the pilot started. **I6** carries the earliest date in the pack: endpoint and account named by 2026-09-10, agreement by 2026-10-17 |
| Q7 | Is a retrieval index or vector store built over connector content, and if so how is it partitioned and when is authorisation evaluated? | The retrieval design, or a statement that retrieval is live-query-only. | **Answered for today, open for the target design.** Retrieval is live query, which confirms assumption (e) for the running build `[session 2026-09-09 · Priya Raghunathan]`. Whether it stays live query when the six-second number is chased is explicitly **not** settled, and was flagged in the room as something that should not be written down as decided. **AI13 stays tagged "if present"** and retires only on a design decision, not on an observation of the current build |
| Q8 | What is the lawful basis for processing employee communications through the assistant, and has a DPIA been started? | The record of processing and any DPIA in progress. | **Partly answered, and the answers are negative.** No DPIA exists, none has been started, and none has been requested `[session 2026-09-09 · Ines Ferreira]`. The **framework** half is settled: the organisation is neither a NIS2 essential nor an important entity, but two in-scope customers push the obligations down contractually; SOC 2 Type II is held; ISO 27001 is not held and is not being pursued. **The lawful basis itself is still not identified** — P1 stands |
| Q9 | Are third parties' personal data — external correspondents in email, external attendees in calendar entries — in scope, and what notice do they get? | The privacy notice and the data-mapping for the Email and Calendar connectors. | **Partly answered, and the population is now named.** In scope, at scale, and identified: the **shared** Support mailbox is customer correspondence and is the connector the pilot most wants, plus three Slack Connect channels with two enterprise accounts `[session 2026-09-09 · Tom Egerton]`. Notice given: **none**, and there was no route by which any would have been given — the DPO had not been asked. **P2** confirmed and narrowed; Article 14 position due 2026-10-03 |

### 5.3 Execution and infrastructure — two whole threat surfaces

| # | Question | What I need to answer it | Session status `[session 2026-09-09]` |
|---|---|---|---|
| Q10 | Where does the assistant run, on what platform, in which regions and accounts? | The Terraform or Helm that was named in the request but not supplied. | **Outstanding, completely.** No infrastructure information at all, which is why two whole threat surfaces remain unwalked. The only infrastructure facts the session produced are that a cluster exists with a deny-by-default egress proxy in front of it, and that neither renderer path runs inside it |
| Q11 | Does the assistant execute code, run tests, or only produce a commit? | The GitHub connector's tool definitions and the commit workflow. | **Outstanding.** Not reached. The commit path alone guarantees execution, because CI runs against what lands — see Q12 |
| Q12 | What runs in CI when the assistant's commit lands, and what credentials does that CI job hold? | The CI pipeline definitions and their secret bindings. | **Partly answered.** Whatever CI is configured runs against what lands, and **what lands is a commit on the working branch, which is not protected** — protection is on `main` `[session 2026-09-09 · Priya Raghunathan]`. Also established: **`platform-ci` holds a standing branch-protection exemption with no expiry**, recorded in a config file rather than in any documentation. **What those jobs hold in credentials is still unknown**, so T2 does not move on this. Usage: eleven commits since July, nine of them the engineer testing |
| Q13 | Which MCP servers are these — first-party, vendor, or community — at which versions, and who may add one? | An AI-BOM, or the MCP client configuration. | **Answered in full, and the answer is worse than "not stated"** `[session 2026-09-09 · Priya Raghunathan]`**.** Five servers, **all pinned to `latest`** — which, as the room put it, is the opposite of pinned, because every connector re-resolves on restart. **The web-search server is a community server**: not first-party, not a vendor product, a repository somebody publishes. **Nothing gates adding a sixth** — it is the client configuration. **AI3's likelihood rose from Medium to High on this**, and AI3's example threat is not a hypothetical for one of the five. Digest pinning due 2026-09-17, estimated at a day |

### 5.4 Behaviour and controls

| # | Question | What I need to answer it | Session status `[session 2026-09-09]` |
|---|---|---|---|
| Q14 | What does "cleaned" mean in PLAT-2814, and what component does it? | The design page or implementation for the web-search sanitisation step. | **Outstanding, and now known to rest on nothing.** ADR-0004 records that web content is cleaned and gives as its reason that PLAT-2814 identified web search as the untrusted connector — so the ADR defers to the ticket and the ticket was a scoping note. What the cleaning *is* was still not established. Finding **O5** |
| Q15 | Which model tiers are selectable per workspace, and is there a floor below which a workspace cannot go? | The tier configuration surface from PLAT-2822. | **Outstanding.** Not reached |
| Q16 | What is the maximum session or thread length before context is reset? | The context-management design. | **Outstanding.** Not reached |
| Q17 | What is logged for each tool call, to where, readable by whom, retained how long? | The logging design. | **Outstanding.** Named as platform territory — log retention appears on the standing controls page — and folded into the finding-by-finding mapping in action 7. **Not credited on the page's existence.** R1 and O2 also gained an audit consequence: a SOC 2 Type II observation period with no action record in it cannot be back-filled |
| Q18 | What stops the assistant mid-task, and who can press it? | An operational runbook or a kill-switch design. | **Outstanding.** Not reached |
| Q19 | Are there hard caps on tokens, tool calls and loop iterations per user and per session, or only tracking? | The rate-limiting and budget configuration behind PLAT-2822. | **Outstanding.** Not reached. The adjacent metering fact that did land is at **P6** |
| Q20 | What is the gate between the Platform and Support pilot and general availability? | The rollout plan referenced by "then open up" in PLAT-2810. | **Outstanding as a written gate**, though the shape is now agreed: the launch gates in `06-threat-model.md` §9 with the DPIA running around them rather than ahead of them `[session 2026-09-09 · Ines Ferreira]`, and security acceptance criteria written into the epic by 2026-09-26 |

**Asked but not blocking.** The analysis proceeds under stated assumptions rather than waiting, because at design time a threat model that arrives after the build is worth less than one that arrives with caveats. Every assumption is listed in `06-threat-model.md` §12 and in `03-security-architecture.md` §1, and each is flagged so the team can correct it in one line.

**What the session's answer rate says, and it is the useful part of this section** `[session 2026-09-09]`**.** Twenty questions, seven people who own the system, ninety-five minutes — and three answers. The facilitator's expectation going in was that *most of them are things one of you already knows*, and that expectation was largely wrong. The reason is worth recording: most of these questions are not answerable from memory. They are answerable from an app registration, an allow-list, a pipeline definition or a contract, and the discipline the session applied was that a confident recollection does not substitute for reading one. **Thirteen of the seventy-four findings are now queued against three specific documents with dates, and none of the three requires anything to be built.** That is the whole of the next iteration.

---

## 6. Sources read

- `input/plat-2810-epic.md` — read in full.
- `input/diagram1-assumed.svg` — read in full, as source text.
- `input/diagram1-assumed.png` — viewed as an image and reconciled against the SVG.
- `input/transcript/transcript.md` — read in full for version 1.1 `[session 2026-09-09]`.

Nothing else was available to read. **No source repository, no infrastructure definition, no design page and no schema was present in the working directory or referenced by a resolvable path, and the validation session did not change that** — it produced testimony about those artefacts, not the artefacts. §1 lists the seven that were named in the room and are still unread.

---

## 7. Sessions

| # | Date | Participants | Role and outcome |
|---|---|---|---|
| 1 | 2026-09-09 | Brett Crawley, Principal Application Security Engineer; Claude Opus 5 | Document generation. Reviewer of record, author of the analysis, recipient of the deliverables; AI assistance for source reading, instrument walking and drafting. 132 prompts walked, 72 findings written up. **No solution owner participated.** |
| 2 | **2026-09-09, 14:00 to 15:35** | **Facilitator:** Brett Crawley, Principal Application Security Engineer. **Attending:** Dana Whitfield (epic owner, Product); Marcus Oyelaran (lead architect); Priya Raghunathan (senior engineer, built the pilot); Tom Egerton (engineering manager, Support); Ines Ferreira (Data Protection Officer); Kwame Osei (Security Champion, Platform) | **Validation walkthrough of version 1.0**, circulated 09:20 the same morning. Scope: the six launch gates, the regulatory section, and the four headline questions — the remainder of the register was not walked. Outcome: no finding closed, 2 added, 1 severity and 1 likelihood raised, 5 corrections to the pack, 3 questions answered in whole or part, 18 actions with owners. Merged into version 1.1. Full log: `06-threat-model.md` Appendix G |
| 3 | **Scheduled 2026-09-30** | Brett Crawley and the owners of actions 1, 6 and 7 | Reconvene on the fifty-odd findings not walked, once the three pieces of evidence have landed |

**What is agreed and what is not.** The findings named in Appendix G.3 and G.4 have been walked with their owners and are agreed, corrected or explicitly held pending named evidence. **Everything else in this pack carries its version 1.0 rating because nobody looked at it**, which is a weaker position than confirmation and should not be read as agreement. The mechanism that makes any of it trustworthy is narrow and worth stating: **only what reaches the transcript can be fed back.** Everything tagged `[session 2026-09-09]` was said out loud by a named person in a recorded room; nothing has been added from a corridor conversation or from an inference about what somebody meant.

---

*This document reflects the inputs as supplied on 2026-09-09, plus the validation-session transcript of the same date. Claims tagged `[session 2026-09-09]` are testimony rather than configuration and are attributed to their speaker; where a re-rating depends on configuration, it is held pending the evidence and the date is named. Nothing here is legal advice; the GDPR, DPIA, EU AI Act, NIS2 and SOC 2 items raised in the companion documents should be confirmed with counsel and the Data Protection Officer — and the NIS2 and SOC 2 positions in particular rest on statements made in the session and have not been separately verified against the contracts or the audit report.*
