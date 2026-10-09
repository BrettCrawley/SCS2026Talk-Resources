# Internal AI Assistant (PLAT-2810) — Context, Sources & Open Questions

**Version:** 1.0 (first pass against the supplied epic and trust-boundary sketch) · **Date:** 2026-09-09
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this document; produced with AI assistance.
**Model:** Claude Opus 5
**Companion documents:** `01-security-review.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md` · `06-threat-model-candidates.md`
**Method:** Source inventory and evidence audit, run before the analysis so that every downstream finding can be traced to something that was actually read.

> This document exists because the review was asked to draw on Confluence design pages, a Jira PMO/PMI ticket tree and extracted git repositories, and **only one of those three source classes was present**. It records exactly what was supplied, exactly what was not, what each absence costs the analysis, and what would be needed to close it. Read it before the other five documents: it is the calibration for how much weight each finding can carry.

---

## 1. What I was given

Three files, 160 KB in total, in `./input`.

| # | File | Size | What it is |
|---|---|---|---|
| 1 | `plat-2810-epic.md` | 2,550 bytes | A Jira epic and its four child stories, as markdown. Descriptions and acceptance criteria only. |
| 2 | `diagram1-assumed.svg` | 4,065 bytes | A trust-boundary sketch titled *"What most engineers assume"*, subtitled *"A tidy boundary at every connection; the internet is the only untrusted zone"*. |
| 3 | `diagram1-assumed.png` | 151,704 bytes | A raster render of file 2. Same content. |

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
- **Any evidence that a control exists.** Nothing in the input describes a control that has been built.

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

---

## 5. Questions I could not answer, and what I would need

Grouped by what unblocks them. These are the intake questions from house style §7 that the input does not answer.

### 5.1 Identity — six findings' severity depends on these

| # | Question | What I need to answer it |
|---|---|---|
| Q1 | When the assistant calls the Office 365 connector for user A, does it present a token scoped to user A, or a shared application credential? | The OAuth application registrations and granted scopes per connector, or the connector configuration. |
| Q2 | Is the Slack identity of a user bound to the same corporate identity as their web-console session, and by what? | The IdP configuration and the Slack app's installation and authentication design. |
| Q3 | What revokes the assistant's access when someone leaves or changes role? | The joiner-mover-leaver process as it applies to connector grants. |
| Q4 | Can a user reach the assistant's history for a conversation they did not start? | The conversation and history data model, and the authorisation check on the history read path. |

### 5.2 Data — the whole privacy assessment rests on these

| # | Question | What I need to answer it |
|---|---|---|
| Q5 | What is persisted from a conversation, where, for how long, and what deletes it? | The schema for the conversation and history stores, plus a retention schedule. |
| Q6 | Which model provider, under what contract, in which region, and are prompts retained or used for training? | The vendor contract, DPA and the model-provider configuration. |
| Q7 | Is a retrieval index or vector store built over connector content, and if so how is it partitioned and when is authorisation evaluated? | The retrieval design, or a statement that retrieval is live-query-only. |
| Q8 | What is the lawful basis for processing employee communications through the assistant, and has a DPIA been started? | The record of processing and any DPIA in progress. |
| Q9 | Are third parties' personal data — external correspondents in email, external attendees in calendar entries — in scope, and what notice do they get? | The privacy notice and the data-mapping for the Email and Calendar connectors. |

### 5.3 Execution and infrastructure — two whole threat surfaces

| # | Question | What I need to answer it |
|---|---|---|
| Q10 | Where does the assistant run, on what platform, in which regions and accounts? | The Terraform or Helm that was named in the request but not supplied. |
| Q11 | Does the assistant execute code, run tests, or only produce a commit? | The GitHub connector's tool definitions and the commit workflow. |
| Q12 | What runs in CI when the assistant's commit lands, and what credentials does that CI job hold? | The CI pipeline definitions and their secret bindings. |
| Q13 | Which MCP servers are these — first-party, vendor, or community — at which versions, and who may add one? | An AI-BOM, or the MCP client configuration. |

### 5.4 Behaviour and controls

| # | Question | What I need to answer it |
|---|---|---|
| Q14 | What does "cleaned" mean in PLAT-2814, and what component does it? | The design page or implementation for the web-search sanitisation step. |
| Q15 | Which model tiers are selectable per workspace, and is there a floor below which a workspace cannot go? | The tier configuration surface from PLAT-2822. |
| Q16 | What is the maximum session or thread length before context is reset? | The context-management design. |
| Q17 | What is logged for each tool call, to where, readable by whom, retained how long? | The logging design. |
| Q18 | What stops the assistant mid-task, and who can press it? | An operational runbook or a kill-switch design. |
| Q19 | Are there hard caps on tokens, tool calls and loop iterations per user and per session, or only tracking? | The rate-limiting and budget configuration behind PLAT-2822. |
| Q20 | What is the gate between the Platform and Support pilot and general availability? | The rollout plan referenced by "then open up" in PLAT-2810. |

**Asked but not blocking.** The analysis proceeds under stated assumptions rather than waiting, because at design time a threat model that arrives after the build is worth less than one that arrives with caveats. Every assumption is listed in `06-threat-model.md` §12 and in `03-security-architecture.md` §1, and each is flagged so the team can correct it in one line.

---

## 6. Sources read

- `input/plat-2810-epic.md` — read in full.
- `input/diagram1-assumed.svg` — read in full, as source text.
- `input/diagram1-assumed.png` — viewed as an image and reconciled against the SVG.

Nothing else was available to read. No source repository, no infrastructure definition, no design page and no schema was present in the working directory or referenced by a resolvable path.

---

## 7. Session participants

| Participant | Role in this session |
|---|---|
| Brett Crawley, Principal Application Security Engineer | Reviewer of record; author of the analysis; recipient of the deliverables. |
| Claude Opus 5 | AI assistance: source reading, instrument walking, drafting of the six deliverables. |

**No validation session with the solution owners has taken place.** These documents are the pre-session pack. The next step in the process is to share them with the PLAT-2810 owners, walk them live, and feed the transcript back — at which point Appendix G of the threat model becomes a session log rather than the note it currently is. Nothing in this pack should be treated as agreed until that happens.

---

*This document reflects the inputs as supplied on 2026-09-09. Nothing here is legal advice; the GDPR, DPIA and EU AI Act items raised in the companion documents should be confirmed with counsel and the Data Protection Officer.*
