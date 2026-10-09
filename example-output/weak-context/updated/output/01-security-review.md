# Internal AI Assistant (PLAT-2810) — Security Review

**Version:** 1.1 (validation-session merge) · **Date:** 2026-09-09
**Supersedes:** version 1.0 of 2026-09-09, the pre-session pack. Delta table at §0.
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this security review; produced with AI assistance.
**Model:** Claude Opus 5
**Validated:** validation session of 2026-09-09, 14:00 to 15:35, facilitated by Brett Crawley, Principal Application Security Engineer, with Dana Whitfield (epic owner, Product), Marcus Oyelaran (lead architect), Priya Raghunathan (senior engineer, built the pilot), Tom Egerton (engineering manager, Support), Ines Ferreira (Data Protection Officer) and Kwame Osei (Security Champion, Platform). Log at `06-threat-model.md` Appendix G.
**Frameworks:** STRIPED · LINDDUN · OWASP Top 10 (2021) · OWASP LLM and Agentic Top 10 · Elevation of Autonomy · MITRE ATLAS · GDPR and Privacy by Design · EU AI Act · NIS2 · SOC 2 Type II
**Companion documents:** `00-context-sources-and-open-questions.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md` · `06-threat-model-candidates.md`
**Method:** Design-stage review of PLAT-2810 and its four child stories, with 132 elicitation prompts walked across five instruments and 74 findings recorded. Version 1.1 merges the validation-session transcript. This is the executive summary; the detail is in the companion documents.

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted. Severities: Critical / High / Medium / Low / Info.

**Session provenance.** Claims that came from the validation session rather than from the supplied tickets are tagged **`[session 2026-09-09]`**, with the speaker named where the claim asserts a fact about the running system. Where the session contradicted an assumption version 1.0 made, it is marked **`[contradicts v1.0]`** and stated rather than edited away.

---

## 0. What changed from the previous pass

Version 1.1 supersedes version 1.0 after a 95-minute validation session with the seven people who own this system. **The honest summary: nothing was closed, two findings were added, two ratings moved and both moved up, and the pack itself was wrong in two places that this version corrects.** The full delta, finding by finding, is `06-threat-model.md` §1. What an executive reader needs is here.

| Version 1.0 said | The session established | Verdict |
|---|---|---|
| Fourteen Criticals, eleven collapsing into the PLAT-2814 and PLAT-2817 pair, and *"the Critical count falls to three"* once the pair is fixed | **Wrong, twice over, and the two sentences are two different counts wearing one number.** The pair closes seven Criticals. Seven survive it: I2, AI8, I3, AI11, E1, E2 and T2 `[session 2026-09-09 · Priya Raghunathan]` | **Corrected in §1 and §3.** This is the correction that matters most to a funding decision |
| Forty-nine refined requirements | **Fifty-seven** — thirty-eight SEC, eleven PRV, eight COMP. The count predates the compliance block `[session 2026-09-09 · Priya Raghunathan]` | **Corrected in §2** |
| NIS2 *"applies conditionally on the organisation's entity classification, which the input does not establish"* | **Contradicted, and the replacement is stronger.** We are neither an essential nor an important entity, settled for a year. Two customers are in scope and their contracts push supply-chain security and incident notification down to us `[session 2026-09-09 · Ines Ferreira]` | **Reason replaced; findings stand** |
| *"SOC 2 and ISO 27001"* as one row, assuming one is held | **SOC 2 Type II is held. ISO 27001 is not held and is not being pursued.** Type II tests operating effectiveness over a period, which puts R1 and O2 on an audit clock `[session 2026-09-09 · Ines Ferreira]` | **Row split in §5** |
| No inherited platform baseline was supplied, so findings are rated as though none exists | **Contradicted. A baseline exists** — egress proxy, org-wide branch protection, a controls page — and was simply not supplied. Two of its controls were examined and neither closed the finding it was offered against `[session 2026-09-09]` | **Net-new finding O6** |
| The trusted-internal-sources position is a security decision the team made | **Nobody made it.** A product scoping note, an ADR that defers to it, an architecture page that defers to the ADR, and an assumed platform sanitiser that is not in the path `[session 2026-09-09]` | **Net-new finding O5** |
| AI1's attacker-authored content is a category of risk | It is a named daily flow: a **shared** Support mailbox where every message is written by a customer or a stranger, and three Slack Connect channels with two enterprise accounts `[session 2026-09-09 · Tom Egerton]` | **AI1 firms up; Critical, unchanged** |
| P6, metering, Medium, resting on the inference that per-team aggregates imply per-person records | Not an inference. **Per-user rows are in the warehouse today** and anyone with warehouse access can select them `[session 2026-09-09 · Ines Ferreira]` | **Raised to High**, mitigation extended with a dated retrospective deletion |
| AI3, MCP servers "not stated" as to version and provenance | **All five resolve to `latest` on every restart and one is a community server** `[session 2026-09-09 · Priya Raghunathan]` | **Likelihood raised to High** |
| Q1 on the credential model would be answered at the session and six findings would drop | Four people stated the intent; nobody read the configuration. **The findings did not move** | **Held**, evidence due 2026-09-10 |

**Two net-new findings, both cross-cutting:** **O5**, the content-trust decision nobody made; **O6**, the gap between the documented control baseline and the enforced one. The register moves from 72 findings to **74**.

**What this version does not add.** No repository, no schema, no infrastructure definition. The design-versus-implementation reconciliation in §4 still cannot be performed, and the cloud and container surfaces are still unwalked.

---

## 1. Executive summary

**The assistant, as specified, can be made to send corporate data to a stranger who has done nothing more than email a member of staff.** No credential, no click, no compromise. That path exists because of two acceptance criteria the team wrote deliberately, and closing it is one change, not a programme.

The first is **PLAT-2814**, which states that internal sources need no untrusted-content handling because they are already behind authentication. Authentication decides who may *read* a mailbox. It says nothing about who *wrote* the message sitting in it. Four of the five connectors carry text authored by people outside the organisation: email bodies from anyone with the address, issue and pull-request bodies on public repositories, Slack messages from guests and webhooks, and externally shared documents and calendar invitations. All four sit inside the box the design labels trusted, and the supplied diagram has no node at all for the person who writes that text.

The second is **PLAT-2817**, which removes the confirmation step from every action — including sending mail and committing code — on pilot feedback that a confirm dialog on every action is slower than doing the work by hand. That feedback is correct, and this review keeps it. The conclusion drawn from it is the problem: it applies the same policy to reading a calendar entry and to mailing four hundred people, and it removes the one control that holds when the model does not.

Together with the outbound channel the web-search connector provides, those two give the system all three parts of the lethal trifecta — access to private data, exposure to attacker-authored content, and a way out — with no human in the loop and, under PLAT-2825's user-facing history, no record a defender could search.

**Fourteen findings are rated Critical, and fixing that pair closes seven of them: AI1, AI21, AI18, AI2, AI6, AI7 and AI25.** `[session 2026-09-09 · Priya Raghunathan]` `[contradicts v1.0]` **Seven survive it and need gates of their own — I2 and AI8 (nothing decides who may see what), I3 and AI11 (the egress channel and the cross-server flow), E1 and E2 (nothing intersects the assistant's reach with the user's), and T2 (the commit path).** Version 1.0 of this summary said the pair reduced the Critical count to three. That was wrong, and the error is worth naming precisely because of what it would have funded: it counted every Critical the pair makes *reachable* and then reported the number as every Critical the pair *closes*. If leadership funds two changes on a promise of three remaining Criticals and finds seven, the fix looks as though it failed when in fact the arithmetic did.

**What has not changed is the sequencing.** The pair is still the single highest-value change in this pack and still the only thing that closes the zero-click path. It is one of four gates rather than a substitute for them.

**Two things the validation session added to this summary** `[session 2026-09-09]`**.** The attacker-authored content is not a category — the connector the pilot most wants is a *shared* Support mailbox where every message is written by a customer or a stranger, plus three Slack Connect channels with two enterprise customers typing into them daily. And **the decision underneath all of it was never made by anybody**: the trusted-internal-sources position exists as a product scoping note, an ADR that cites the note, an architecture page that cites the ADR, and an assumption that a platform sanitiser covered ingestion, which it does not. Nobody was careless; each artefact is correct on its own, and that is how the loop closed. It is finding **O5**, and it is the finding most likely to produce the next one if it is not fixed as a process rather than as a document.

**This is a good design to be reviewing now.** It is at the epic stage, nothing is built, and the fixes are specification changes rather than rewrites. The team already identified untrusted content as a category and already wrote action visibility into the epic — two instincts that most comparable designs lack entirely. What is missing is not care; it is that the boundary was drawn where the network changes rather than where the authorship of the data changes, and every other gap follows from that one error.

**What is actually gated, stated here so it cannot be misread** `[session 2026-09-09]`**.** This review has been read as demanding confirmation on every action. **It does not, and the distinction is the whole recommendation.** Tools are classified by reversibility and blast radius, and only some classes are gated:

| Tool class | Examples | Gated? |
|---|---|---|
| **Read** | Retrieve mail, search documents, read a calendar, read an issue or a repository | **No gate.** This is the large majority of turns in a "what is blocking the release" workload |
| **User-scoped write** | Save a draft in the requesting user's own drafts folder, update their own task | **No gate.** The blast radius is the requester |
| **Org-visible write** | Post to a channel, comment on an issue | **Gated** — and this is the one line still under discussion. Posting to a channel is most of what Support does, so whether this class belongs in the gated set comes back with pilot numbers by 2026-09-16 `[session 2026-09-09 · Dana Whitfield, Tom Egerton]` |
| **External write** | Send email outside the organisation | **Gated**, out of band |
| **Code-integrity write** | Commit code | **Gated**, out of band. Eleven commits since July, nine of them one engineer testing, so this gate costs almost nothing `[session 2026-09-09 · Priya Raghunathan]` |

The pilot group's finding that a confirm dialog on *every* action is slower than doing the work by hand is correct, well evidenced, and kept — see §7. This review agrees with the evidence and disagrees only with the inference, which is that the answer to undifferentiated friction is no friction rather than proportionate friction.

**The top six priorities, in order.** (1) Provenance labelling at ingest plus the risk-proportionate action gate above, as one change. (2) Answer who the assistant acts as — one configuration fact that re-rates six findings, due 2026-09-10. (3) Keep assistant commits behind a pull request, on a feature branch, out of credential-holding pipelines; the working branch they currently reach is unprotected. (4) An egress allow-list and a cross-server data-flow policy. (5) An append-only action record shipped to monitoring — now also an audit item, because a SOC 2 Type II observation period with no action record in it is a finding in the next report. (6) **Make the content-trust decision, as a decision, with an owner** (O5). Start the DPIA and the model-provider contract today in parallel, because both have external lead time and neither is on any code path.

**The gate is the pilot expansion, not the pilot.** Platform and Support mailboxes are not Legal, HR and Finance mailboxes. The population change is the risk change.

**One thing is already live rather than prospective** `[session 2026-09-09 · Ines Ferreira]`**.** Corporate personal data, including a shared customer-facing Support mailbox, has been going to a model provider with no processor agreement, no region commitment and no retention terms on every turn since the pilot started. Nobody in the room could name the provider, and the Data Protection Officer who would have signed the contract has never been shown one. That is **I6**, it is not a design finding, and it carries the earliest date in the pack.

---

## 2. Scope and method

**What was reviewed.** PLAT-2810 and stories PLAT-2814, PLAT-2817, PLAT-2822 and PLAT-2825, read in full, plus `diagram1-assumed.svg`, the supplied trust-boundary sketch. That is the entire input: 2.5 KB of tickets and one diagram.

**What was requested but not supplied**, and this materially bounds the review:

| Named in the request | Present | Consequence |
|---|---|---|
| Confluence design pages | **No** | There is no stated architecture. The one in `03-security-architecture.md` is reconstructed from acceptance criteria |
| Jira PMO and PMI tickets, following children | **Partially** — five PLAT issues, no PMO or PMI tickets at all | No programme context and no remediation tickets, so **no mitigation can be credited to any ticket** |
| Git repositories, Terraform, Helm | **No** | The requested design-versus-implementation reconciliation **could not be performed**. Cloud and container threat surfaces were not walked |

Also absent: data schemas, the identity and access design, deployment topology, the model provider's identity and contract, every privacy artefact, and any evidence that a control has been built. `00-context-sources-and-open-questions.md` lists all of it, states what each absence costs, and sets out twenty questions with what would be needed to answer each.

**What was done.** Five elicitation instruments walked exhaustively — STRIPED (57 prompts), LINDDUN and the AI-specific privacy categories (9), privacy dark patterns and human-centered security (16), the Elevation of Autonomy deck (30 cards) and the AI extension instrument (20) — 132 prompts, each recorded with an outcome in `06-threat-model-candidates.md` before any write-up began. **Seventy-four findings** (72 from the instrument walk, 2 from the validation session), three MITRE ATLAS attack paths, ten use cases, fifteen security abuse cases, seven privacy abuse cases, twenty-one security counter-use cases, nine privacy counter-use cases, thirty gaps, **fifty-seven** new requirements and fifty-eight test artefact definitions.

> **Count correction, version 1.1** `[session 2026-09-09 · Priya Raghunathan]`**.** Version 1.0 of this paragraph and of the README said *forty-nine* refined requirements. **It is fifty-seven: thirty-eight SEC, eleven PRV and eight COMP**, all of them traced in `05-srtm-and-test-artefacts.md`. The count was taken before the compliance block was added to `04-gap-analysis.md` §5 and was never redone. Nothing hangs off the number except credibility, which the room judged reason enough to correct it in the record rather than quietly: *if two people check two numbers and both are wrong, nobody checks the third.*

**What was added in version 1.1.** One source: the transcript of the validation session of 2026-09-09 `[session 2026-09-09]`. **A transcript is testimony, not configuration, and it is treated that way** — a statement about how the system is configured is recorded with its speaker's name and does not re-rate a finding unless the speaker was reading the configuration. That distinction did real work: on the credential model, four people stated the same intent confidently and six findings did not move, because the one person who could read the app registration declined to confirm it from memory.

**What was not done.** The Cumulus cloud instrument (60 prompts) and the container instrument (25) were not walked, because no infrastructure information exists in the input to walk them against, and the session did not supply any. A system of this shape almost certainly has both surfaces. **The session did not walk the register either** — its scope was the six launch gates, the regulatory section and the four headline questions, so roughly fifty findings were not reached and carry their version 1.0 rating because nobody looked at them, which is not the same as their being confirmed. Command execution was disabled in the session that produced version 1.0, so the deterministic house-style gate was left to an external checker.

---

## 3. Risk posture at a glance

| Bucket | Findings | Critical | High | Medium | Low | Headline |
|---|---|---|---|---|---|---|
| **AI and agentic (AI)** | 26 | 9 | 14 | 3 | 0 | Injection through connectors the design calls trusted, reaching write tools with no gate |
| **Privacy (P)** | 8 | 0 | 6 | 2 | 0 | No basis, no retention, no deletion, no DPIA, no processor agreement |
| **Information disclosure (I)** | 6 | 2 | 2 | 2 | 0 | No authorisation on retrieval; an attacker-choosable egress channel |
| **Spoofing (S)** | 5 | 0 | 3 | 2 | 0 | No single identity authority; agent actions indistinguishable from the user's |
| **Tampering (T)** | 5 | 1 | 2 | 2 | 0 | Assistant commits reach CI with no review gate |
| **Repudiation (R)** | 5 | 0 | 3 | 2 | 0 | The only action record is user-facing and rewritable by the acting component |
| **Elevation of privilege (E)** | 5 | 2 | 3 | 0 | 0 | No check between what a user may do and what the assistant does for them |
| **Denial of service (D)** | 5 | 0 | 3 | 1 | 1 | Cost and work measured, capped nowhere |
| **Cross-cutting (O)** | **6** ↑ | 0 | **5** ↑ | 1 | 0 | The trust model omits six required components; **nobody ever made the content-trust decision (O5)**; **the documented control baseline is not the enforced one (O6)**; nothing emits security telemetry |
| **Recovery and resilience (RR)** | 3 | 0 | 2 | 1 | 0 | No kill switch and no compensating action for anything irreversible |
| **Total** | **74** | **14** | **44** | **15** | **1** | All 🔴 Open |

*Movement from version 1.0's 72 findings (Critical 14 · High 41 · Medium 16 · Low 1), all of it from the validation session* `[session 2026-09-09]`*:* **O5** and **O6** added, both High; **P6** raised from Medium to High; **AI3**'s likelihood raised from Medium to High with severity unchanged. **Nothing was downgraded and nothing was closed.**

**Every finding is Open, and the reason has changed between versions.** In version 1.0 it was that nothing supplied asserted a built control. **The session contradicted the premise underneath that** `[contradicts v1.0]`: a platform baseline does exist — an egress proxy, org-wide branch protection, a standing controls page — it was simply not supplied to the review. What the session then established is why nothing has been credited to it. Two of its controls were offered against two findings, in good faith, by the person who owns them, and **neither closed the finding it was offered against**: the egress proxy does not touch **AI25**, because both renderer fetches happen outside the cluster, and org-wide branch protection does not touch **T2**, because the assistant commits to an unprotected working branch and a standing exemption exists that the documentation does not record. That pattern is now finding **O6**, and six further findings (S2, S5, T5, I4, R4, RR3) are held pending a finding-by-finding mapping of the baseline rather than credited to its existence.

Version 1.0 predicted that several severities would drop at the validation session. **They did not. Two ratings moved and both moved up.** The prediction is left visible here rather than deleted, because the gap between it and the outcome is the useful part: a register moves on evidence, and the session produced evidence about the design rather than evidence that a control had been built.

**The severity distribution is not what it looks like, but it is worse than version 1.0 said** `[session 2026-09-09 · Priya Raghunathan]` `[contradicts v1.0]`**.** Version 1.0 described fourteen Criticals as *"one design decision counted from eleven directions, plus three independent Criticals"* and said fixing the pair took the count to three. **The arithmetic conflated two different sets.** The PLAT-2814 and PLAT-2817 pair closes **seven** — AI1, AI21, AI18, AI2, AI6, AI7, AI25 — and **seven survive it**: no authorisation on retrieval (**I2**) and the credential model behind it (**AI8**), the egress channel (**I3**) and the cross-server flow (**AI11**), the two authorisation findings (**E1**, **E2**), and commits reaching the build (**T2**). Provenance labelling and an action gate do not close an authorisation finding, and this document's own launch-gate list says so. The pair is still the highest-value change in the pack; it is one of four gates rather than a substitute for them.

---

## 4. Design-versus-implementation reconciliation

**This could not be performed as requested.** No repository, no infrastructure-as-code and no Helm chart was supplied, so there is no implementation to compare the documentation against.

What was possible is a design-versus-design reconciliation, and it was productive. The supplied diagram and the ticket acceptance criteria were compared against each other, and they disagree in four places — all of them omissions in the diagram, and all of them in the highest-risk parts of the system.

| Claim | Where made | What the other source shows | Verdict |
|---|---|---|---|
| The internet, via web search, is the only untrusted zone | Diagram and PLAT-2814 | PLAT-2814 also connects email and GitHub, both of which carry text written by anyone on the internet | **Contradiction** — findings AI1, O1 |
| Four connectors, one untrusted edge | Diagram | PLAT-2810 requires a web console; the diagram has no node for it | **Omission** — O1 |
| Actions are visible to the user | PLAT-2825 | The diagram has no conversation, history or audit store to hold that record | **Omission** — O1, R1 |
| Token usage is tracked per team | PLAT-2822 | The diagram has no metering component and no model provider node, so the organisation's largest transfer of personal data is not drawn at all | **Omission** — O1, I6 |
| Web content is cleaned before use | PLAT-2814 | No ticket defines what cleaning is, what performs it, or what it removes | **Undefined control** — AI1 |

A control with no definition cannot be credited, and a boundary that is not drawn cannot be argued about. Both are the reason O1 is a finding in its own right rather than a note.

**A third reconciliation became available at the validation session, and it is the one that matters most** `[session 2026-09-09]`**.** Not design against implementation, and not design against design, but **artefact against decision** — asking, of each documented position, who decided it.

| Claim | Where made | Who actually decided it | Verdict |
|---|---|---|---|
| Internal sources need no untrusted-content handling because they are behind authentication | PLAT-2814 acceptance criterion | **Nobody.** Written as a product scoping note about where to spend build effort, explicitly not a security position `[session 2026-09-09 · Dana Whitfield]` | **Unowned decision** — **O5** |
| Web search content is cleaned; the other four connectors are not | ADR-0004 | The ADR gives as its reason that web search is the connector PLAT-2814 identified as untrusted — so it defers to the ticket `[session 2026-09-09 · Priya Raghunathan]` | **Circular citation** — **O5** |
| The trust model treats the four internal connectors as trusted | Architecture page | Written against two artefacts that agreed with each other, which was taken as evidence that somebody had assessed it `[session 2026-09-09 · Marcus Oyelaran]` | **Inherited, not assessed** — **O5**, **O1** |
| Content ingested by the assistant is covered by the platform sanitiser | Assumed, nowhere written | Nobody. The connectors call the MCP servers directly and the sanitiser is not in that path `[session 2026-09-09 · Kwame Osei, Priya Raghunathan]` | **Assumed control that does not exist on this path** — **O5**, **O6** |
| Branch protection is enforced on every repository | Standing controls page | True, and it carries a standing exemption list held in a config file that the controls page does not reference `[session 2026-09-09 · Priya Raghunathan]` | **Documented control diverges from enforced control** — **O6** |

**The pattern is one finding, not five.** Each artefact is correct when read on its own and each cites another. Nobody in the room did anything careless, and that is precisely why it survived four months and a design review — the loop has no weak link to find. It is finding **O5**, and the remediation is a process change (an ADR whose only stated reason is another artefact fails review) rather than a document.

**What a repository pass would add.** It would confirm or retire the eight findings currently tagged as resting on documentation — the credential model (AI8), transport (T5), secret handling (I4), retrieval indexing (AI13), parsing (T4), error handling (I5), storage partitioning (E4) and backup separation (RR3) — and it would open the two threat surfaces this review could not walk.

---

## 5. Regulatory posture

| Framework | Position | Status |
|---|---|---|
| **UK and EU GDPR** | **Applies, and has the most exposure with the least coverage.** No lawful basis, no record of processing, no DPIA, no retention, no deletion path, no executable subject rights, and an unnamed processor receiving corporate personal data on every turn. Third-party data subjects in mailboxes and calendars have no notice at all, and special-category data is reachable through calendar and occupational-health content | 🔴 Open |
| **EU AI Act** | **Applies conditionally** on EU deployment. Not prohibited and not high-risk on the facts given, since it makes no employment decision; the Article 50 transparency duty applies. **Watch item:** the per-person metering in PLAT-2822 makes worker-evaluation use tempting, and that use would reclassify the system as high-risk — reassess before it happens, not after | 🔵 Planned |
| **NIS2** | **Applies contractually rather than directly** `[session 2026-09-09 · Ines Ferreira]` `[contradicts v1.0]`**.** Version 1.0 called this conditional on an entity classification the input did not establish. The classification is settled and has been for a year: **the organisation is neither an essential nor an important entity.** Two customers are in scope, and their contracts push the obligations down to us — supply-chain security, and incident notification inside their reporting window. **The findings stay and the reason gets stronger**, because a contractual obligation does not wait for a classification argument. Risk management, incident detection and reporting, supply-chain security for the MCP servers and the model provider, encryption and access control all have open findings; **AI3 is the sharpest**, a community MCP server resolving `latest` on every restart being precisely the supply-chain exposure the pushed-down clauses name | 🔴 Open |
| **CRA** | **Assessed — out of scope.** Internal service, no product with digital elements placed on the EU market, no downloadable or embedded component. Reassess if any part is packaged or offered to customers; the AI bill of materials this review recommends would then become the SBOM obligation | ⚪ Accepted |
| **PSTI** | **Assessed — out of scope.** No consumer connectable product and no hardware | ⚪ Accepted |
| **PCI-DSS** | **Assessed — out of scope on the facts given, with a live caveat.** Mailboxes receive card numbers from customers despite policy, and the assistant copies mailbox content into the conversation store. Confirm at pilot expansion whether any connected mailbox sits in a cardholder data environment | 🔵 Planned |
| **HIPAA** | **Assessed — out of scope.** No protected health information and no covered entity relationship. Occupational-health correspondence is Article 9 employee data under GDPR, carried at finding P5 | ⚪ Accepted |
| **SOC 2 Type II** | **Applies, and the organisation holds it** `[session 2026-09-09 · Ines Ferreira]` `[contradicts v1.0]` — version 1.0 recorded this as an assumption. Logical access, encryption, monitoring, change management and availability all have open findings, and auditors will treat an autonomous system with write access to production repositories as in scope. **The Type II part is the part with a deadline.** A Type II report tests operating effectiveness *over a period*: the auditor does not ask whether the control is designed, they ask for evidence it ran. An action record that does not exist for six months of a pilot is a finding in the next report, and **the gap cannot be back-filled** — every month the pilot runs without one is a month of observation period with nothing in it. **R1** and **O2** therefore carry an audit consequence on a clock as well as a security one | 🔴 Open |
| **ISO 27001** | **Assessed — not held and not being pursued** `[session 2026-09-09 · Ines Ferreira]` `[contradicts v1.0]`. Version 1.0 carried it in one row with SOC 2, which conflated a certification the organisation holds with one it has no intention of seeking. Reassess only if certification is pursued | ⚪ Accepted |

**The privacy work has not started rather than been done badly**, and that distinction matters for sequencing. None of it is a build problem, and two items — the DPIA and the model-provider processor agreement — have external lead time and sit on no code path. They should start now, in parallel with engineering. The one privacy item that *is* a build problem is per-subject indexing: finding one individual's data in free-form conversation text that was never indexed for it is materially harder later than adding the index before the first record is written.

---

## 6. Prioritised recommendations and gate readiness

**Gate readiness verdict: not ready to expand beyond Platform and Support.** Ready to continue the pilot with the two current teams while the launch gates are built, provided the fast hygiene items below land in the next sprint. **The validation session did not change this verdict and did not soften it** `[session 2026-09-09]`. It sharpened one thing: **I6 is not a gate item, it is a live exposure** — corporate personal data has been leaving for an unnamed processor with no agreement since the pilot began, and it does not wait for the expansion.

**Launch gates — before the pilot opens up**

1. **Provenance labelling at ingest plus a risk-proportionate action gate, sequenced as one change.** *This is the single most important item in the pack.* Each alone fails: labelling without a gate is telemetry, and a gate without labelling confirms on everything and reproduces exactly the usability failure the pilot correctly objected to. Together they answer PLAT-2817's evidence instead of overruling it — most turns in a "what's blocking the release" workload are reads and stay untouched.
2. **Answer who the assistant acts as, then enforce it.** Per-user, per-task short-lived credentials with the source system deciding what is returned. This is question Q1, it is one configuration fact, and six findings are currently rated on the unknown.
3. **Keep assistant commits behind a pull request**, and out of credential-holding pipelines until a human approves them.
4. **Egress allow-list and cross-server data-flow policy.** Needed even after the send tool is gated, because a search query is also a channel.
5. **Append-only action record, shipped to monitoring, with the first detection rule live.** Without it, none of the three ATLAS attack paths in the threat model is observable.
6. **DPIA signed; model-provider contract in place.** Start both today — they are not on any code path and they have the longest lead time on this list. The DPIA runs *around* the other gates rather than ahead of them `[session 2026-09-09 · Ines Ferreira]`: one that arrives with six of these still open does not get signed, it gets a set of conditions attached.
7. **Make the content-trust decision, as a decision** `[session 2026-09-09]`**.** New in version 1.1, and it belongs with the gates rather than below them. Gate 1 rests on a position — that four connectors carry externally authored text — which no owner has ever recorded as a decision. Until somebody does, the fix has no author and the next design closes the same loop. Finding **O5**; owner Marcus Oyelaran, 2026-09-19.

**Fast, cheap hardening that should not wait** — read-only workspace defaults; enforced token, spend and loop caps (PLAT-2822 already computes every number a cap needs, so this is a comparison and a refusal); content-security policy on the console and Block Kit rather than markdown pass-through in Slack; agent-origin marking at the tool boundary; **MCP servers pinned by digest with hashed tool definitions failing closed, replacing the `latest` resolution all five currently use** `[session 2026-09-09 · Priya Raghunathan]` (a day's work, and it closes the sharpest supply-chain exposure in the pack); and a dispatcher-checked kill switch.

**Two items the session moved onto this list** `[session 2026-09-09]`**.** A **dated retrospective deletion of the per-user metering rows already in the warehouse** — the forward-looking fix does nothing about them, and P6 is now High for that reason. And **the platform controls page mapped finding by finding** rather than cited: six findings are currently held on it, and the session produced two worked examples of a real control aimed at the wrong side of the boundary it was offered against (finding **O6**).

**Decisions to ratify rather than fix** — three residuals, each belonging in an architecture decision record so it is carried knowingly: per-workspace model tiering with a minimum tier where write tools are reachable; the commit capability itself, behind a pull request, with the human approval named as the control; and connector breadth per workspace, decided per business function with a named owner rather than by a global default. **None of the three was reached in the validation session and none carries an owner yet** `[session 2026-09-09]` — the time went on the gates. **No risk was formally accepted in that session**, and that is recorded rather than left to be inferred from an empty table.

---

## 7. What is done well, and should be kept

**PLAT-2825 exists, and it was not a security team's idea.** A great many agentic assistants ship with no action visibility at all, discover nobody can tell what the thing did, and retrofit it badly. This team wrote "users see what it did" into the epic as an acceptance criterion and then wrote a story to deliver it. The recommendation in this review is to keep it exactly as designed and add a defender-readable record behind it — not to replace it.

**PLAT-2814 identifies untrusted content as a category and commits to handling it.** The boundary is in the wrong place, and that is the most serious finding here — but the team was reasoning about the right problem, which is a much better starting position than not having considered content trust at all. The correction is to widen an existing concept, not to introduce a missing one.

**The 6-second target is a number.** Latency budgets are usually aspirational, and an aspirational one makes every security trade-off unarguable. Because this one is written down, the cost of the action gate — a human decision on a small subset of actions — can be measured against it rather than debated.

**The pilot produced real evidence and the team acted on it.** PLAT-2817 records that the pilot group found a confirm dialog on every action slower than doing the work by hand. That is a genuine human-factors finding, correctly gathered — **they built it, shipped it in week two, watched people stop using it, and changed it** `[session 2026-09-09 · Dana Whitfield]`. This review agrees with the evidence and disagrees only with the inference: the answer to undifferentiated friction is proportionate friction, not none. The class list in §1 is what proportionate means here, and reads stay untouched.

**The room corrected the pack, and two of the corrections were arithmetic** `[session 2026-09-09]`**.** The engineer who built the pilot brought two counting errors to the session — the Critical-collapse figure and the refined-requirement total — having checked both against the pack's own contents. Both were right, both are corrected here, and neither was found by the review that produced them. A validation session that returns errors in the reviewer's document is working; one where everybody nods is not.

**Three people said "I assumed" out loud** `[session 2026-09-09]`**, and that is why O5 exists rather than staying invisible.** The content-trust decision was made four times and never once — a scoping note, an ADR citing it, an architecture page citing the ADR, and an assumed platform sanitiser that is not in the path. Every one of those artefacts looks correct on its own, which is exactly why the loop closed and why nobody caught it for four months. It only became visible because people answered a direct question literally rather than helpfully.

**PLAT-2822 already computes the numbers a cap needs.** The story measures rather than limits, which is finding D1 — but turning tracking into limiting is a comparison and a refusal, not a new subsystem. The expensive half is already specified.

---

## 8. Next steps

*Version 1.0's steps 1 to 4 are complete: the pack was circulated at 09:20 on 2026-09-09, walked at 14:00, and this version is the transcript merged back. What follows replaces them, and every item carries the owner and date agreed in the room* `[session 2026-09-09]`*.*

1. **Collect three pieces of paper that move thirteen of seventy-four findings.** None requires anything to be built. The app registration and granted scopes per connector (Q1 — re-rates I2, E1, E2, E4, R3, AI8; Priya Raghunathan, 2026-09-10). The egress proxy's allow-list and default action (re-rates I3; Kwame Osei, 2026-09-16). The platform controls page mapped finding by finding (re-rates S2, S5, T5, I4, R4, RR3; Kwame Osei, 2026-09-23). **None of the three moves anything on the strength of the artefact existing** — the mapping is the evidence, not the page.
2. **Land the two cheapest gates.** MCP digest pinning replacing `latest` resolution (Priya Raghunathan, 2026-09-17, estimated at a day). The commit path onto a feature branch and a draft pull request, out of credential-holding pipelines (Priya Raghunathan, 2026-09-26 — two users, two real commits between them).
3. **Make the content-trust decision and redraw the trust model against it.** Marcus Oyelaran, both by 2026-09-19, deliberately the same owner.
4. **Start the DPIA and the processor agreement now**, in parallel with engineering. The provider's endpoint and billing account are due 2026-09-10 so the Data Protection Officer has something to write against; the agreement itself is due 2026-10-17. Both have external lead time and neither sits on a code path.
5. **Fix the metering, forwards and backwards.** Aggregate in the pipeline rather than the dashboard query, and delete the per-user rows already in the warehouse, with a date. Ines Ferreira and Priya Raghunathan, 2026-10-03.
6. **Write security acceptance criteria into PLAT-2810 and its children** from the launch gates, so the next story does not repeat this. Dana Whitfield, 2026-09-26.
7. **Reconvene on the fifty-odd findings not walked**, once step 1 has landed. Brett Crawley, 2026-09-30.
8. **Re-run this review** when the repository and its infrastructure-as-code exist — that unlocks the two threat surfaces this pass could not walk and converts eight inferred findings into evidence — and in any case before the pilot opens beyond Platform and Support.

The eighteen actions in full, with owners and dates, are at `06-threat-model.md` Appendix G.8. **No remediation ticket has been raised yet**, and until they are, that table is a list of intentions rather than a status.

---

*This review reflects the inputs as supplied on 2026-09-09 — five Jira issues and one diagram, with no repository, no design pages and no schemas — plus the transcript of the validation session held the same day. Statuses tied to ticket references are point-in-time. Claims sourced from the session are tagged `[session 2026-09-09]` and are testimony rather than configuration; where a re-rating depends on configuration, it is held pending the evidence and the date is named. Nothing here is legal advice; the GDPR, EU AI Act, NIS2 and SOC 2 positions should be confirmed with counsel and the Data Protection Officer — the NIS2 and SOC 2 positions in §5 rest on statements made in the session by the Data Protection Officer and have not been separately verified against the contracts or the audit report.*
