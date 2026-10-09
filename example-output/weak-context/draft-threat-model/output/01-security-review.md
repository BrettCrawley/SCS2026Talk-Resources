# Internal AI Assistant (PLAT-2810) — Security Review

**Version:** 1.0 (first pass against the supplied epic and trust-boundary sketch) · **Date:** 2026-09-09
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this security review; produced with AI assistance.
**Model:** Claude Opus 5
**Frameworks:** STRIPED · LINDDUN · OWASP Top 10 (2021) · OWASP LLM and Agentic Top 10 · Elevation of Autonomy · MITRE ATLAS · GDPR and Privacy by Design · EU AI Act · NIS2
**Companion documents:** `00-context-sources-and-open-questions.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `03-security-architecture.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md` · `06-threat-model-candidates.md`
**Method:** Design-stage review of PLAT-2810 and its four child stories, with 132 elicitation prompts walked across five instruments and 72 findings recorded. This is the executive summary; the detail is in the companion documents.

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted. Severities: Critical / High / Medium / Low / Info.

---

## 1. Executive summary

**The assistant, as specified, can be made to send corporate data to a stranger who has done nothing more than email a member of staff.** No credential, no click, no compromise. That path exists because of two acceptance criteria the team wrote deliberately, and closing it is one change, not a programme.

The first is **PLAT-2814**, which states that internal sources need no untrusted-content handling because they are already behind authentication. Authentication decides who may *read* a mailbox. It says nothing about who *wrote* the message sitting in it. Four of the five connectors carry text authored by people outside the organisation: email bodies from anyone with the address, issue and pull-request bodies on public repositories, Slack messages from guests and webhooks, and externally shared documents and calendar invitations. All four sit inside the box the design labels trusted, and the supplied diagram has no node at all for the person who writes that text.

The second is **PLAT-2817**, which removes the confirmation step from every action — including sending mail and committing code — on pilot feedback that a confirm dialog on every action is slower than doing the work by hand. That feedback is correct, and this review keeps it. The conclusion drawn from it is the problem: it applies the same policy to reading a calendar entry and to mailing four hundred people, and it removes the one control that holds when the model does not.

Together with the outbound channel the web-search connector provides, those two give the system all three parts of the lethal trifecta — access to private data, exposure to attacker-authored content, and a way out — with no human in the loop and, under PLAT-2825's user-facing history, no record a defender could search. **Fourteen findings are rated Critical. Eleven of them collapse into that pair of decisions.** Reclassify the connectors as capable of carrying attacker-authored text, put a deterministic gate on the write tools, and the Critical count falls to three.

**This is a good design to be reviewing now.** It is at the epic stage, nothing is built, and the fixes are specification changes rather than rewrites. The team already identified untrusted content as a category and already wrote action visibility into the epic — two instincts that most comparable designs lack entirely. What is missing is not care; it is that the boundary was drawn where the network changes rather than where the authorship of the data changes, and every other gap follows from that one error.

**The top five priorities, in order.** (1) Provenance labelling at ingest plus a risk-proportionate action gate, as one change. (2) Answer who the assistant acts as — one configuration fact that re-rates six findings. (3) Keep assistant commits behind a pull request. (4) An egress allow-list and a cross-server data-flow policy. (5) An append-only action record shipped to monitoring. Start the DPIA and the model-provider contract today in parallel, because both have external lead time and neither is on any code path.

**The gate is the pilot expansion, not the pilot.** Platform and Support mailboxes are not Legal, HR and Finance mailboxes. The population change is the risk change.

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

**What was done.** Five elicitation instruments walked exhaustively — STRIPED (57 prompts), LINDDUN and the AI-specific privacy categories (9), privacy dark patterns and human-centered security (16), the Elevation of Autonomy deck (30 cards) and the AI extension instrument (20) — 132 prompts, each recorded with an outcome in `06-threat-model-candidates.md` before any write-up began. Seventy-two findings, three MITRE ATLAS attack paths, ten use cases, fifteen security abuse cases, seven privacy abuse cases, twenty-one security counter-use cases, nine privacy counter-use cases, thirty gaps, forty-nine new requirements and fifty-eight test artefact definitions.

**What was not done.** The Cumulus cloud instrument (60 prompts) and the container instrument (25) were not walked, because no infrastructure information exists in the input to walk them against. A system of this shape almost certainly has both surfaces. Command execution was disabled in this session, so the deterministic house-style gate was left to an external checker.

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
| **Cross-cutting (O)** | 4 | 0 | 3 | 1 | 0 | The trust model omits six required components; nothing emits security telemetry |
| **Recovery and resilience (RR)** | 3 | 0 | 2 | 1 | 0 | No kill switch and no compensating action for anything irreversible |
| **Total** | **72** | **14** | **41** | **16** | **1** | All 🔴 Open |

**Every finding is Open, and that is a property of the input rather than a judgement about the team.** Nothing supplied asserts that any control has been built, so no mitigation can honestly be credited and no status can be advanced. Where a ticket is cited against a finding, it is in every case a ticket that *creates* the exposure — PLAT-2814 and PLAT-2817 in particular — and the register labels it as such. At the validation session, several of these will move: work already under way should be recorded with its ticket reference, and several severities will drop as a result.

**The severity distribution is not what it looks like.** Fourteen Critical findings reads as a system in trouble. It is more accurately one design decision counted from eleven directions, plus three independent Criticals — no authorisation on retrieval (I2), an unrestricted egress channel (I3), and commits reaching the build unreviewed (T2). Fix the pair in §1 and the picture changes shape entirely.

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

**What a repository pass would add.** It would confirm or retire the eight findings currently tagged as resting on documentation — the credential model (AI8), transport (T5), secret handling (I4), retrieval indexing (AI13), parsing (T4), error handling (I5), storage partitioning (E4) and backup separation (RR3) — and it would open the two threat surfaces this review could not walk.

---

## 5. Regulatory posture

| Framework | Position | Status |
|---|---|---|
| **UK and EU GDPR** | **Applies, and has the most exposure with the least coverage.** No lawful basis, no record of processing, no DPIA, no retention, no deletion path, no executable subject rights, and an unnamed processor receiving corporate personal data on every turn. Third-party data subjects in mailboxes and calendars have no notice at all, and special-category data is reachable through calendar and occupational-health content | 🔴 Open |
| **EU AI Act** | **Applies conditionally** on EU deployment. Not prohibited and not high-risk on the facts given, since it makes no employment decision; the Article 50 transparency duty applies. **Watch item:** the per-person metering in PLAT-2822 makes worker-evaluation use tempting, and that use would reclassify the system as high-risk — reassess before it happens, not after | 🔵 Planned |
| **NIS2** | **Applies conditionally** on the organisation's entity classification, which the input does not establish. Where it applies, risk management, incident detection and reporting, supply-chain security for the MCP servers and the model provider, encryption and access control all have open findings | 🔴 Open |
| **CRA** | **Assessed — out of scope.** Internal service, no product with digital elements placed on the EU market, no downloadable or embedded component. Reassess if any part is packaged or offered to customers; the AI bill of materials this review recommends would then become the SBOM obligation | ⚪ Accepted |
| **PSTI** | **Assessed — out of scope.** No consumer connectable product and no hardware | ⚪ Accepted |
| **PCI-DSS** | **Assessed — out of scope on the facts given, with a live caveat.** Mailboxes receive card numbers from customers despite policy, and the assistant copies mailbox content into the conversation store. Confirm at pilot expansion whether any connected mailbox sits in a cardholder data environment | 🔵 Planned |
| **HIPAA** | **Assessed — out of scope.** No protected health information and no covered entity relationship. Occupational-health correspondence is Article 9 employee data under GDPR, carried at finding P5 | ⚪ Accepted |
| **SOC 2 and ISO 27001** | **Applies** as the internal control framework. Logical access, encryption, monitoring, change management and availability all have open findings. Auditors will treat an autonomous system with write access to production repositories as in scope | 🔴 Open |

**The privacy work has not started rather than been done badly**, and that distinction matters for sequencing. None of it is a build problem, and two items — the DPIA and the model-provider processor agreement — have external lead time and sit on no code path. They should start now, in parallel with engineering. The one privacy item that *is* a build problem is per-subject indexing: finding one individual's data in free-form conversation text that was never indexed for it is materially harder later than adding the index before the first record is written.

---

## 6. Prioritised recommendations and gate readiness

**Gate readiness verdict: not ready to expand beyond Platform and Support.** Ready to continue the pilot with the two current teams while the launch gates are built, provided the fast hygiene items below land in the next sprint.

**Launch gates — before the pilot opens up**

1. **Provenance labelling at ingest plus a risk-proportionate action gate, sequenced as one change.** *This is the single most important item in the pack.* Each alone fails: labelling without a gate is telemetry, and a gate without labelling confirms on everything and reproduces exactly the usability failure the pilot correctly objected to. Together they answer PLAT-2817's evidence instead of overruling it — most turns in a "what's blocking the release" workload are reads and stay untouched.
2. **Answer who the assistant acts as, then enforce it.** Per-user, per-task short-lived credentials with the source system deciding what is returned. This is question Q1, it is one configuration fact, and six findings are currently rated on the unknown.
3. **Keep assistant commits behind a pull request**, and out of credential-holding pipelines until a human approves them.
4. **Egress allow-list and cross-server data-flow policy.** Needed even after the send tool is gated, because a search query is also a channel.
5. **Append-only action record, shipped to monitoring, with the first detection rule live.** Without it, none of the three ATLAS attack paths in the threat model is observable.
6. **DPIA signed; model-provider contract in place.** Start both today — they are not on any code path and they have the longest lead time on this list.

**Fast, cheap hardening that should not wait** — read-only workspace defaults; enforced token, spend and loop caps (PLAT-2822 already computes every number a cap needs, so this is a comparison and a refusal); content-security policy on the console and Block Kit rather than markdown pass-through in Slack; agent-origin marking at the tool boundary; pinned MCP versions with hashed tool definitions failing closed; and a dispatcher-checked kill switch.

**Decisions to ratify rather than fix** — three residuals, each belonging in an architecture decision record so it is carried knowingly: per-workspace model tiering with a minimum tier where write tools are reachable; the commit capability itself, behind a pull request, with the human approval named as the control; and connector breadth per workspace, decided per business function with a named owner rather than by a global default.

---

## 7. What is done well, and should be kept

**PLAT-2825 exists, and it was not a security team's idea.** A great many agentic assistants ship with no action visibility at all, discover nobody can tell what the thing did, and retrofit it badly. This team wrote "users see what it did" into the epic as an acceptance criterion and then wrote a story to deliver it. The recommendation in this review is to keep it exactly as designed and add a defender-readable record behind it — not to replace it.

**PLAT-2814 identifies untrusted content as a category and commits to handling it.** The boundary is in the wrong place, and that is the most serious finding here — but the team was reasoning about the right problem, which is a much better starting position than not having considered content trust at all. The correction is to widen an existing concept, not to introduce a missing one.

**The 6-second target is a number.** Latency budgets are usually aspirational, and an aspirational one makes every security trade-off unarguable. Because this one is written down, the cost of the action gate — a human decision on a small subset of actions — can be measured against it rather than debated.

**The pilot produced real evidence and the team acted on it.** PLAT-2817 records that the pilot group found a confirm dialog on every action slower than doing the work by hand. That is a genuine human-factors finding, correctly gathered. This review agrees with the evidence and disagrees only with the inference: the answer to undifferentiated friction is proportionate friction, not none.

**PLAT-2822 already computes the numbers a cap needs.** The story measures rather than limits, which is finding D1 — but turning tracking into limiting is a comparison and a refusal, not a new subsystem. The expensive half is already specified.

---

## 8. Next steps

1. **Circulate this pack** to the PLAT-2810 owners before the validation session. Nothing here is agreed until they have walked it.
2. **Answer four questions** — Q1 (whose credentials the assistant acts under), Q6 (which model provider, under what contract), Q7 (whether a retrieval index exists) and Q11 (whether the assistant executes code). Between them they re-rate ten findings, and each is a fact somebody already knows.
3. **Raise remediation tickets** from the six launch gates, so the validation session assigns owners rather than discovers the list.
4. **Run the validation session**, record it, and feed the transcript back into the threat model and its companions. Appendix G of `06-threat-model.md` becomes a session log at that point.
5. **Start the DPIA and the processor agreement now**, in parallel with engineering.
6. **Re-run this review** when the repository and its infrastructure-as-code exist — that unlocks the two threat surfaces this pass could not walk and converts eight inferred findings into evidence — and in any case before the pilot opens beyond Platform and Support.

---

*This review reflects the inputs as supplied on 2026-09-09: five Jira issues and one diagram, with no repository, no design pages and no schemas. Statuses tied to ticket references are point-in-time. No validation session has been held. Nothing here is legal advice; the GDPR, EU AI Act and NIS2 positions should be confirmed with counsel and the Data Protection Officer.*
