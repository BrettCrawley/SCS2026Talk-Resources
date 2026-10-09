# Internal AI Assistant (PLAT-2810) — Candidate Register (phase 1)

**Version:** 1.0 · **Date:** 2026-09-09 · **Model:** Claude Opus 5
**Surfaces in scope:** STRIPED · privacy and human factors · AI/ML and agentic · third-party dependencies
**Instruments walked:** STRIPED 57 · PRV·L 9 · PRV·DP and PRV·H 16 · EoA 30 · AIX 20 — 132 prompts
**Surfaces not walked:** the Cumulus cloud instrument and the container instrument. No infrastructure-as-code, deployment topology, cluster, registry or platform information was supplied, so there is nothing to walk them against. See `00-context-sources-and-open-questions.md` §2 and §3.
**Prepared by:** Brett Crawley, Principal Application Security Engineer — produced with AI assistance.
**Companion:** `06-threat-model.md` (phase 2 write-up)

---

## Why this file exists

Discovery and write-up compete for the same budget. A finding costs roughly 250 words to write up properly, so in a single pass the marginal finding is dropped because the budget ran out rather than because the analysis cleared it. This file is the cheap, exhaustive pass: one row per prompt, before any prose exists. Phase 2 writes up the rows marked `finding` under the IDs assigned here, and the threat model's coverage tables are transcribed from here rather than re-derived.

---

## Candidates

| Prompt | Element | Outcome | ID | Title | Category | Severity | Note |
|---|---|---|---|---|---|---|---|
| STR·S1 | Slack app surface and web console | finding | S2 | Two entry points assert identity independently with no named single authority | STRIPED-S | High | |
| STR·S2 | web console session tokens | finding | S2 | — | STRIPED-S | High | Same weakness reached from token verification |
| STR·S3 | Office 365 and GitHub connector authorisation grants | finding | S4 | Connector grants have no revocation trigger on leaver, role change or compromise | STRIPED-S | High | |
| STR·S4 | MCP client to Email MCP server | finding | S5 | Service identity between assistant and each MCP server rests on reachability | STRIPED-S | Medium | |
| STR·S5 | conversation and history identifiers in PLAT-2825 | finding | S3 | Conversation and history identifiers may act as resumption capabilities | STRIPED-S | Medium | |
| STR·S6 | web console authentication path | no exposure | — | — | — | — | PLAT-2810 describes no credential-verification endpoint of its own; both surfaces delegate to Slack and to the corporate session. Re-walk when the console session design lands |
| STR·S7 | Slack app installation and web console federation | finding | S2 | — | STRIPED-S | High | Federated legs are the same unpinned identity weakness |
| STR·S8 | Email MCP server send tool | finding | S1 | Agent-sent mail and posts carry no marker distinguishing them from the user's own | STRIPED-S | High | |
| STR·T1 | MCP client to hosted inference API | finding | T5 | No transport security requirement exists for any hop in the system | STRIPED-T | Medium | |
| STR·T2 | reasoning loop context assembly | finding | AI1 | Internal connector content is classified trusted so attacker-authored text reaches the model as instruction | AI | Critical | The interpreter here is the model; finding sits in the AI bucket per house style |
| STR·T3 | Slack app surface and web console input handling | no exposure | — | — | — | — | Neither surface performs client-side validation that a server-side check duplicates; both submit free text. Re-walk if the console adds client-side policy |
| STR·T4 | conversation and history store | finding | T3 | A write to the conversation store changes what a later turn acts on | STRIPED-T | Medium | |
| STR·T5 | workspace configuration surface PLAT-2822 | finding | T1 | Model tier, connector set and prompt templates are runtime-editable with no change control | STRIPED-T | High | |
| STR·T6 | Office 365 documents connector and email attachments | finding | T4 | Documents and attachments are ingested with no type, size or content validation | STRIPED-T | High | |
| STR·T7 | reasoning loop execution path | no exposure | — | — | — | — | No queue or event stream appears in PLAT-2810 or the supplied diagram; the loop is synchronous inside the 6-second budget. Re-walk when asynchronous execution is designed |
| STR·T8 | GitHub MCP server commit tool | finding | T2 | Agent commits enter the build pipeline with no review or provenance gate | STRIPED-T | Critical | |
| STR·R1 | PLAT-2825 in-conversation action display | finding | R1 | The only action record is user-facing and lives where the acting component can rewrite it | STRIPED-R | High | |
| STR·R2 | PLAT-2825 action record fields | finding | R2 | No required content for an action record: actor, tool, arguments and decision are unspecified | STRIPED-R | High | |
| STR·R3 | Email MCP server send tool downstream attribution | finding | R3 | Downstream systems attribute agent actions to the connector principal, not the human | STRIPED-R | High | |
| STR·R4 | conversation and history store write path | finding | R1 | — | STRIPED-R | High | The audit store and the acting component share an identity |
| STR·R5 | tool call dispatch path | finding | R5 | Refusals, tool failures and partial completions are not distinguished from successes | STRIPED-R | Medium | |
| STR·R6 | orchestrator to MCP client to hosted inference API | finding | R4 | No correlation identifier spans the entry point, orchestrator, connectors and provider | STRIPED-R | Medium | |
| STR·R7 | conversation and history store retention | finding | R4 | — | STRIPED-R | Medium | Retention is unset, so it cannot cover an investigation window |
| STR·I1 | reasoning loop context assembly | finding | I1 | Context is assembled by relevance across every connector with no per-query minimisation | STRIPED-I | High | |
| STR·I2 | connector tool error returns | finding | I5 | Tool and connector error text is returned into the conversation unfiltered | STRIPED-I | Medium | |
| STR·I3 | web console route surface | no exposure | — | — | — | — | PLAT-2810 defines two entry surfaces and no diagnostic or metrics route; the PLAT-2822 configuration surface is walked at STR·E4. Re-walk against the deployed service |
| STR·I4 | Office 365 documents connector retrieval path | finding | I2 | No authorisation decision is described on any retrieval path | STRIPED-I | Critical | |
| STR·I5 | hosted inference API at TB2 | finding | I6 | Corporate content crosses to an unnamed third-party inference service on every turn | STRIPED-I | High | |
| STR·I6 | MCP server credential storage | finding | I4 | Connector and provider credentials have no described storage or echo controls | STRIPED-I | Medium | |
| STR·I7 | Web search MCP server egress | finding | I3 | Web search gives the assistant an attacker-choosable outbound destination | STRIPED-I | Critical | |
| STR·I8 | conversation and history store workspace scoping | finding | E4 | Content is reachable across user and workspace boundaries through shared retrieval | STRIPED-E | High | Storage-layer co-mingling; the privilege consequence carries the ID |
| STR·P1 | Email MCP server read path | finding | P1 | No lawful basis is identified for any category of personal data the assistant processes | STRIPED-P | High | |
| STR·P2 | reasoning loop context assembly | finding | I1 | — | STRIPED-I | High | Necessity fails for the same reason minimisation does |
| STR·P3 | Office 365 calendar connector | finding | P2 | Third parties in mail, calendar and documents are processed with no notice | STRIPED-P | High | |
| STR·P4 | conversation and history store | finding | P3 | No retention period or deletion path exists for any store the assistant creates | STRIPED-P | High | |
| STR·P5 | conversation and history store subject-rights path | finding | P4 | Data subject rights cannot be executed against the conversation store | STRIPED-P | High | |
| STR·P6 | Office 365 calendar connector | finding | P5 | Special-category data is reachable and inferable from calendar and mail content | STRIPED-P | High | |
| STR·P7 | hosted inference API at TB2 | finding | I6 | — | STRIPED-I | High | Transfer path and region are the same unassessed flow |
| STR·P8 | per-team token usage store | finding | P6 | Per-team token metering is a per-person behavioural record open to secondary use | STRIPED-P | Medium | |
| STR·P9 | PLAT-2810 processing as a whole | finding | P7 | No DPIA for autonomous processing of staff communications at organisational scale | STRIPED-P | High | |
| STR·E1 | tool call dispatch path | finding | E2 | No authorisation decision sits between the user's entitlements and the tools called for them | STRIPED-E | Critical | |
| STR·E2 | tool call dispatch path | finding | E2 | — | STRIPED-E | Critical | The decision has no described input, because it has no described existence |
| STR·E3 | conversation and history store | finding | E4 | — | STRIPED-E | High | Peer-level reach across users |
| STR·E4 | workspace configuration surface PLAT-2822 | finding | E3 | A new workspace receives the full connector set and no confirmation by default | STRIPED-E | High | |
| STR·E5 | tool argument binding | no exposure | — | — | — | — | The assistant exposes no request-body binding to a domain model; the equivalent surface is tool arguments, walked at AIX·SK3 and carried by AI2 |
| STR·E6 | MCP client service identity | finding | E1 | The agent holds every connector's full capability on every request | STRIPED-E | Critical | |
| STR·E7 | workspace provisioning default | finding | E3 | — | STRIPED-E | High | The default grants and expects configuration to restrict it |
| STR·E8 | conversation resumption path | finding | S3 | — | STRIPED-S | Medium | Authorisation evaluated at creation, not at resumption |
| STR·E9 | GitHub MCP server commit tool | finding | AI7 | The agent's tool set is the union of every connector regardless of the task | AI | Critical | Capability beyond the stated blast radius |
| STR·D1 | Slack app surface and web console | finding | D2 | Reasoning-loop iterations and tool fan-out are unbounded | STRIPED-D | High | |
| STR·D2 | model tier router PLAT-2822 | finding | D1 | Model spend is tracked per team and capped nowhere | STRIPED-D | High | |
| STR·D3 | reasoning loop tool dispatch | finding | D2 | — | STRIPED-D | High | One prompt fans out into many retrievals |
| STR·D4 | Office 365 documents connector ingestion | finding | D2 | — | STRIPED-D | High | Whole-document reads drive unbounded token work |
| STR·D5 | hosted inference API rate budget | finding | D3 | One shared provider rate budget across teams lets one workload degrade all | STRIPED-D | Medium | |
| STR·D6 | Email MCP server dependency path | finding | D4 | The 6-second budget has no described behaviour when a connector is slow or down | STRIPED-D | High | |
| STR·D7 | Office 365 documents connector ingestion | finding | D5 | A document that always fails parsing can block the ingestion path repeatedly | STRIPED-D | Low | |
| STR·D8 | reasoning loop partial-failure path | finding | D4 | — | STRIPED-D | High | Degraded output is indistinguishable from complete output |
| PRV·L | per-team token usage store | finding | P6 | — | STRIPED-P | Medium | Linking activity across contexts to one person |
| PRV·I | Office 365 calendar connector | finding | P5 | — | STRIPED-P | High | Singling out an individual from calendar and mail content |
| PRV·Nr | conversation and history store | finding | P6 | — | STRIPED-P | Medium | An undeniable per-person record of what was asked |
| PRV·D | Office 365 documents connector retrieval path | finding | P8 | Differential responses reveal that a record exists to a requester not entitled to read it | STRIPED-P | Medium | |
| PRV·Dd | reasoning loop response path | finding | AI12 | The model can disclose assembled cross-system context to a requester not entitled to it | AI | High | |
| PRV·U | Email MCP server read path | finding | P2 | — | STRIPED-P | High | Data subjects unaware the processing happens |
| PRV·Nc | PLAT-2810 processing as a whole | finding | P7 | — | STRIPED-P | High | Basis, DPIA, transfers and rights all unmet or unassessed |
| PRV·Di | reasoning loop response path | finding | P5 | — | STRIPED-P | High | Proxy inference over health, belief and union signals in calendar content |
| PRV·Ad | tool call dispatch path | finding | AI21 | Excessive autonomy by design: confirmation was removed from every action | AI | Critical | Consequential action with no human involvement |
| PRV·DP1 | web console consent surface | no exposure | — | — | — | — | PLAT-2810 has no consent or preference interface, so there is no accept and decline pairing to weight unequally. Re-walk when the rollout adds a user opt-in |
| PRV·DP2 | staff enrolment into the pilot | finding | P1 | — | STRIPED-P | High | Enrolment reads a person's mailbox with no opt-in and no unbundled basis |
| PRV·DP3 | conversation and history store deletion path | finding | P4 | — | STRIPED-P | High | Withdrawing is not merely harder than granting, it is absent |
| PRV·DP4 | PLAT-2825 history feature | finding | P2 | — | STRIPED-P | High | Material practices are not disclosed before use |
| PRV·DP5 | tool call confirmation path | no exposure | — | — | — | — | PLAT-2817 removed confirmation entirely, so there is no decline option whose wording could shame. Re-walk when the SUC-02 action gate introduces approve and reject wording |
| PRV·DP6 | reasoning loop response path | no exposure | — | — | — | — | The assistant carries no advertising and no personalisation product; PLAT-2822 meters cost only |
| PRV·DP7 | Slack app surface and web console | no exposure | — | — | — | — | The assistant is offered to staff who already hold corporate accounts; PLAT-2810 requires no additional registration |
| PRV·DP8 | web console consent surface | no exposure | — | — | — | — | There is no consent modal or preference surface in PLAT-2810 to interfere with. Re-walk once notice and opt-in are added under PUC-02 |
| PRV·H1 | workspace provisioning default | finding | E3 | — | STRIPED-E | High | Security depends on an administrator opting in to restriction |
| PRV·H2 | tool call confirmation path | finding | AI21 | — | AI | Critical | The insecure path was chosen because the secure one cost the user more |
| PRV·H3 | tool call dispatch path | finding | E5 | Irreversible and externally visible actions are not separated from routine ones | STRIPED-E | High | Friction was removed from everything rather than applied to the risky subset |
| PRV·H4 | connector tool error returns | finding | I5 | — | STRIPED-I | Medium | Errors help the requester enumerate rather than act |
| PRV·H5 | PLAT-2825 in-conversation action display | finding | AI23 | The interface presents agent output as authoritative with no provenance at the point of decision | AI | High | |
| PRV·H6 | web console recovery path | no exposure | — | — | — | — | PLAT-2810 has no credential or account-recovery path of its own; recovery belongs to the corporate identity provider, outside this scope. Re-walk if the console adds one |
| PRV·H7 | PLAT-2825 in-conversation action display | finding | R1 | — | STRIPED-R | High | The user is told inside the channel the agent controls and never out of band |
| PRV·H8 | Office 365 and GitHub connector authorisation grants | finding | S4 | — | STRIPED-S | High | Users cannot see or revoke what the assistant may reach on their behalf |
| EoA·SA | reasoning loop context assembly | finding | AI1 | — | AI | Critical | Prompt injection through the four connectors the design calls trusted |
| EoA·SK | GitHub MCP server commit tool | finding | AI2 | Tool arguments are model-generated and constrained by no allow-list | AI | Critical | |
| EoA·SQ | MCP client server inventory | finding | AI3 | MCP servers are not inventoried, pinned or signature-verified | AI | High | |
| EoA·SJ | conversation and history store | finding | AI5 | Persisted conversation content is re-read as trusted context in later turns | AI | High | |
| EoA·S10 | reasoning loop response path | finding | AI6 | Model output is consumed as trusted at every downstream sink | AI | Critical | |
| EoA·S9 | MCP client tool definition intake | finding | AI4 | Tool descriptions are not integrity-checked between approval and use | AI | High | |
| EoA·HA | tool call dispatch path | finding | AI7 | — | AI | Critical | Capability held exceeds what any single task requires |
| EoA·HK | MCP client service identity | finding | AI8 | No per-user, per-task scoped credential is described for any tool call | AI | Critical | |
| EoA·HQ | reasoning loop execution path | no exposure | — | — | — | — | PLAT-2810 describes a single reasoning loop with no peer agents, no orchestrator hierarchy and no agent-to-agent messaging. Re-walk when sub-agents or a planner and executor split is introduced |
| EoA·HJ | reasoning loop tool dispatch | finding | AI9 | No circuit breaker bounds a task once one step has been hijacked | AI | High | |
| EoA·H10 | MCP client server inventory | finding | AI10 | No agent inventory, admission gate or behavioural baseline exists | AI | Medium | |
| EoA·H9 | MCP client | finding | AI11 | Five MCP servers share one client with no cross-server data-flow policy | AI | Critical | |
| EoA·DA | reasoning loop response path | finding | AI12 | — | AI | High | The model emits context the requester was not entitled to |
| EoA·DK | retrieval corpus if one is built | finding | AI13 | Retrieval corpus partitioning and query-time authorisation are unspecified | AI | High | Tagged if present; no retrieval index is described in the input |
| EoA·DQ | reasoning loop response path | finding | AI14 | Fluent unsourced claims are treated as ground truth by users and by tools | AI | High | |
| EoA·DJ | model tier router PLAT-2822 | finding | D1 | — | STRIPED-D | High | Cost tracked, not capped; the loop bound is carried by D2 |
| EoA·D10 | system prompt and tool definitions | finding | AI15 | The system prompt discloses the connector set and workspace configuration | AI | Medium | |
| EoA·D9 | MCP client server registry | finding | AI16 | MCP servers are identified by name rather than by pinned signature | AI | High | |
| EoA·CA | Email MCP server send tool | finding | AI17 | Model-generated claims about identifiable people are sent outward unmarked | AI | High | |
| EoA·CK | conversation and history store | finding | P3 | — | STRIPED-P | High | No surgical removal path across conversations, chunks and usage records |
| EoA·CQ | Office 365 calendar connector | finding | P5 | — | STRIPED-P | High | Inference of special-category data from ordinary content |
| EoA·CJ | reasoning loop context assembly | finding | I1 | — | STRIPED-I | High | Neither input nor output is minimised to the task |
| EoA·C10 | conversation and history store subject-rights path | finding | P4 | — | STRIPED-P | High | No route for a subject to discover, correct or persist a correction |
| EoA·T7 | tool call dispatch path | finding | AI18 | Adversarial subspace: no deterministic enforcement stands behind the action boundary | AI | Critical | |
| EoA·T6 | model tier router PLAT-2822 | no exposure | — | — | — | — | No classifier gates a security decision in PLAT-2810; the tier router routes on task type and cost, not on a security verdict. Re-walk if an injection classifier is introduced, because its verdict would then be probeable |
| EoA·T5 | reasoning loop context assembly | finding | AI19 | Context rot: no context budget or instruction re-injection over long threads | AI | High | |
| EoA·T4 | model tier router PLAT-2822 | finding | AI20 | Decision boundary transfer: attacks are developed offline and cheaper tiers widen the target | AI | High | |
| EoA·T3 | tool call confirmation path | finding | AI21 | — | AI | Critical | Autonomy granted for usability reasons the risk model does not justify |
| EoA·T2 | model tier router and prompt templates | finding | AI22 | Behaviour-determining artefacts are not inventoried or versioned | AI | High | |
| EoA·T1 | PLAT-2825 in-conversation action display | finding | AI23 | — | AI | High | Output treated as authoritative by the interface and by downstream tools |
| AIX·CE | GitHub MCP server commit tool | finding | AI24 | Model-selected code reaches CI with no sandbox and no review gate | AI | High | |
| AIX·HT | PLAT-2825 in-conversation action display | finding | AI23 | — | AI | High | Provenance absent at the point the person decides whether to act on it |
| AIX·SK1 | Slack app surface markdown rendering | finding | AI25 | Renderers in Slack and the web console fetch remote content from model output | AI | Critical | |
| AIX·SK2 | web console output rendering | finding | AI25 | — | AI | Critical | Second renderer, same missing sink control |
| AIX·SK3 | tool argument binding | finding | AI2 | — | AI | Critical | Arguments are not constrained to an allowed set |
| AIX·SK4 | GitHub MCP server commit tool | finding | AI24 | — | AI | High | Generated code becomes an executed build artefact |
| AIX·SK5 | conversation and history store queries | no exposure | — | — | — | — | No store in PLAT-2810 accepts a model-generated query fragment; the five MCP servers expose typed operations. Re-walk if a SQL, GraphQL or search-DSL tool is added |
| AIX·SK6 | per-team token usage store and application logs | finding | AI26 | Conversation content and tool arguments reach logs and usage records unscrubbed | AI | Medium | |
| AIX·SK7 | reasoning loop execution path | no exposure | — | — | — | — | Single reasoning loop with no agent-to-agent messaging in PLAT-2810; the same structural condition recorded at EoA·HQ |
| AIX·SK8 | Email MCP server send tool | finding | AI25 | — | AI | Critical | Generated content is sent outward with active markup intact |
| AIX·SK9 | GitHub MCP server commit tool | finding | AI24 | — | AI | High | A generated path can escape its intended root in the repository |
| AIX·SK10 | conversation and history store | finding | AI5 | — | AI | High | Writes persist without provenance or partition |
| AIX·SK11 | retrieval corpus if one is built | finding | AI13 | — | AI | High | Corpus writes would carry no provenance or integrity check |
| AIX·ML1 | hosted inference API at TB2 | not in scope | — | — | — | — | PLAT-2810 hosts no model of its own; the model is a metered third-party service per PLAT-2822, so extraction targets the vendor's asset and not this system |
| AIX·ML2 | hosted inference API at TB2 | not in scope | — | — | — | — | No training set belongs to this system, so membership in one cannot be inferred from it |
| AIX·ML3 | hosted inference API at TB2 | not in scope | — | — | — | — | No model is trained or fine-tuned here, so there is no training data of ours to reconstruct |
| AIX·ML4 | hosted inference API at TB2 | not in scope | — | — | — | — | No training, fine-tuning or evaluation corpus exists in PLAT-2810; corpus poisoning of retrieval is carried at EoA·DK |
| AIX·ML5 | hosted inference API at TB2 | not in scope | — | — | — | — | No feature vector is supplied at inference; the interface is natural language and is walked at EoA·SA |
| AIX·ML6 | hosted inference API at TB2 | not in scope | — | — | — | — | No pretrained weights or adapters are downloaded; MCP server provenance is the equivalent supply-chain surface and is carried at AI3 |
| AIX·ML7 | hosted inference API at TB2 | not in scope | — | — | — | — | No model file is loaded or deserialised in this system, so there is no pickle or checkpoint path to exploit |
| beyond the instrument | diagram1-assumed.svg against PLAT-2810 and PLAT-2825 | finding | O1 | The supplied trust model omits six required components and places every boundary at the network | Cross-cutting | High | Doc-versus-doc drift; the only reconciliation available without a repository |
| beyond the instrument | PLAT-2810 acceptance criteria as a set | finding | O2 | No requirement in the epic produces telemetry a defender could alert on | Cross-cutting | High | |
| beyond the instrument | PLAT-2810 pilot-to-general rollout | finding | O3 | The pilot-to-general rollout has no security admission gate | Cross-cutting | Medium | |
| beyond the instrument | PLAT-2810 acceptance criteria as a set | finding | O4 | The epic carries no security, privacy or compliance acceptance criterion | Cross-cutting | High | Only latency and cost are constrained |
| beyond the instrument | Email MCP server send tool and GitHub commit tool | finding | RR1 | No compensating path exists for an action the assistant should not have taken | Recovery and Resilience | High | |
| beyond the instrument | reasoning loop and MCP client | finding | RR2 | No kill switch stops the assistant globally or per connector | Recovery and Resilience | High | |
| beyond the instrument | conversation and history store | finding | RR3 | Backup and restore of the conversation store is unspecified | Recovery and Resilience | Medium | |

---

## Roll-up

| Instrument | Prompts | Findings | No exposure | Not in scope |
|---|---|---|---|---|
| STRIPED (STR·) | 57 | 52 | 5 | 0 |
| Privacy (PRV·L) | 9 | 9 | 0 | 0 |
| Dark patterns and human-centered security (PRV·DP, PRV·H) | 16 | 10 | 6 | 0 |
| Elevation of Autonomy (EoA·) | 30 | 28 | 2 | 0 |
| AI extension (AIX·) | 20 | 11 | 2 | 7 |
| Beyond the instrument | 7 | 7 | 0 | 0 |
| **Total** | **139** | **117** | **15** | **7** |

The Findings column counts *rows*, not distinct findings: several prompts legitimately reach the same weakness, and those rows repeat the finding ID rather than opening a second one.

**Distinct findings: 72.** By bucket: S 5 · T 5 · R 5 · I 6 · P 8 · E 5 · D 5 · O 4 · AI 26 · RR 3.

**By severity:** Critical 14 · High 41 · Medium 16 · Low 1.

---

## Notes for phase 2

- **AI13** rests on an assumption, not a statement: no retrieval index or vector store is described anywhere in the input. Write it up tagged "if present" and name the check — asking whether retrieval is live query or indexed — that would confirm or retire it.
- **AI20 severity is conditional.** It is High while the model is the only thing standing between an injected instruction and a sent email. Once the action gate in SUC-02 exists, the tier becomes a backstop and the finding drops to Medium. Say so in the write-up rather than rating it twice.
- **Six findings are carried in a bucket other than the one their prompt sits in** — AI1 from STR·T2, E4 from STR·I8, AI7 from STR·E9, AI12 from PRV·Dd, AI21 from PRV·Ad, AI23 from PRV·H5. This is correct: house style puts prompt-injection and agentic findings in the AI bucket regardless of which instrument surfaced them.
- **No finding can be recorded as mitigated.** Nothing in the input asserts that any control has been built, so every status in the register is Open or Planned. Where a ticket is cited in the Mitigation column it is a ticket that *creates* the exposure, not one that closes it, and the write-up must say which.
- **The cloud and container instruments were not walked at all**, rather than walked and dismissed. The threat model's §2 must record that as an input gap with a next-iteration pointer, and must not present the resulting document as covering those surfaces.
