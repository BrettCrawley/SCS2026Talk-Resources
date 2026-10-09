# Internal AI Assistant — Candidate Register (phase 1)

**Version:** 1.0 · **Date:** 2026-09-09 · **Model:** Claude Opus 5
**Surfaces in scope:** STRIPED · privacy · AI/ML · cloud · containers · third-party dependencies
**Instruments walked:** STRIPED 57 · PRV·L 9 · PRV·DP+H 16 · EoA 30 · AIX 20 · Cumulus 60 · CN 25

This is the elicitation record. Every prompt of every in-scope instrument has a row, written before any finding was written up, so that what the write-up covers is decided by the walk rather than by the budget. Finding IDs are assigned here and are final: `06-threat-model.md` writes them up under these IDs and its coverage tables and risk register resolve against them.

Elements are named specifically. Where a prompt was walked against two elements that reached different outcomes, it has two rows. Where two prompts reach the same weakness, both rows carry the same finding ID rather than a second ID pointing at the first.

---

## Candidates

| Prompt | Element | Outcome | ID | Title | Category | Severity | Note |
|---|---|---|---|---|---|---|---|
| STR·S1 | web console entry point, PLAT-2831-2 | finding | S1 | Web console is authenticated by a shared password rather than the identity provider | STRIPED-S | High | |
| STR·S2 | shared app registration client credential, PLAT-2820-3 | finding | S2 | Connectors present one shared app registration instead of per-user credentials | STRIPED-S | Critical | |
| STR·S3 | Redis conversation record TTL and offboarding | finding | E5 | Authorisation is evaluated at conversation start, never at resumption | STRIPED-E | Medium | credential outlives the event that should end it |
| STR·S4 | assistant-svc to assistant-connectors call | finding | S5 | Connector processes are trusted by shared namespace rather than by authentication | STRIPED-S | Medium | |
| STR·S5 | conversation_id used by the PLAT-2825-2 history view | finding | S3 | Possession of a conversation identifier resumes a session and its context | STRIPED-S | Medium | |
| STR·S6 | VPN authentication fronting the web console | no exposure | — | — | — | — | VPN enforces MFA per the platform controls page and the assistant exposes no authentication endpoint of its own; the shared-credential weakness is S1 |
| STR·S7 | OAuth legs named in PLAT-2820-1 | finding | S2 | — | STRIPED-S | Critical | delegated flows are not built; the prototype uses client credentials |
| STR·S8 | Slack post and Mail.Send write tools | finding | S4 | Recipients cannot tell an assistant-sent message from a human-sent one | STRIPED-S | Medium | |
| STR·T1 | orchestrator to Redis and to connector pods | no exposure | — | — | — | — | platform controls page states TLS is re-established internally and traffic to managed datastores is encrypted in transit |
| STR·T2 | model context assembly in assistant-svc | finding | AI1 | Externally-authored content reaches the model as trusted instructions | AI | Critical | the model is the interpreter; prompt injection is AI-bucket per house style |
| STR·T3 | write tool argument validation at dispatch | finding | AI3 | Tool arguments are taken from model output with no allowlist or schema | AI | Critical | |
| STR·T4 | Redis conversation store | finding | T4 | Redis conversation state can be written by anything reaching the namespace | STRIPED-T | High | |
| STR·T4 | GitHub commit tool writing to working branches, PLAT-2817-3 | finding | T3 | Assistant holds commit rights across every repository in the organisation | STRIPED-T | High | second element, different outcome |
| STR·T5 | per-workspace model configuration, PLAT-2822-2 | finding | T1 | Per-workspace model selection changes security behaviour outside review | STRIPED-T | Medium | |
| STR·T5 | debug log-level flag named in the architecture page Logging section | finding | T2 | Debug logging of tool arguments is a flag away from a Confidential spill | STRIPED-T | High | second element, different outcome |
| STR·T6 | file upload and import paths | no exposure | — | — | — | — | no upload or import path exists; documents are read from O365 at request time and not written to disk |
| STR·T7 | message queues and event streams | no exposure | — | — | — | — | no queue or stream in the design; assistant-svc dispatches tool calls synchronously within the turn |
| STR·T8 | container image build inputs for assistant-svc and the web-search connector | finding | C3 | Container images are not digest-pinned or signature-verified at admission | Container | High | |
| STR·R1 | tool dispatch record in production | finding | R1 | Tool arguments are not recorded, so actions cannot be reconstructed | STRIPED-R | High | |
| STR·R2 | request-level log fields listed in the architecture page Logging section | finding | R1 | — | STRIPED-R | High | same weakness: actor is present, arguments are not |
| STR·R3 | O365, Slack and GitHub audit logs receiving assistant actions | finding | R2 | Target systems attribute every action to the shared app registration | STRIPED-R | High | |
| STR·R4 | PLAT-2825-2 user-initiated conversation deletion | finding | R5 | Conversation deletion removes the only record of what the assistant did | STRIPED-R | Medium | |
| STR·R5 | refused and failed tool calls in the request log | finding | R1 | — | STRIPED-R | High | same weakness: the decision and its arguments are absent for both outcomes |
| STR·R6 | trace identity across assistant-svc, assistant-connectors and the target SaaS | finding | R4 | No correlation identifier spans orchestrator, connector and target system | STRIPED-R | Medium | |
| STR·R7 | platform log retention of 90 days hot and 12 months cold | no exposure | — | — | — | — | retention exceeds plausible detection lag; the gap is what is recorded, which is R1 |
| STR·I1 | assembled_context passed to the model provider | finding | P5 | Session context is neither minimised nor bounded to one purpose | STRIPED-P | Medium | |
| STR·I2 | error and diagnostic surfaces of assistant-svc | no exposure | — | — | — | — | platform controls page states debug and diagnostic endpoints are disabled in production builds by configuration before promotion |
| STR·I3 | undocumented routes on assistant-svc and assistant-connectors | no exposure | — | — | — | — | both services are cluster-internal with no ingress route per the architecture page Deployment section |
| STR·I4 | O365, Slack and GitHub read tool calls | finding | E1 | Application permissions let the assistant read anything in the tenant | STRIPED-E | Critical | object-level authorisation is not evaluated at all |
| STR·I4 | PLAT-2825-2 history view on the web console | finding | I1 | Console history view exposes other users' retrieved content | STRIPED-I | High | second element, different outcome |
| STR·I5 | Redis conversation store | finding | I2 | Conversation store aggregates Confidential data with no stated protection | STRIPED-I | High | |
| STR·I5 | analytics warehouse telemetry partition | finding | CL5 | Access control on the telemetry warehouse partition is unstated | Cloud | Medium | second element, different outcome |
| STR·I6 | Secrets Manager values mounted into the connector namespace at pod start | finding | I4 | Connector credentials are mounted into pods running third-party code | STRIPED-I | High | |
| STR·I7 | egress proxy allowlist entries for the search API and github.com | finding | I3 | Egress allowlist includes hosts that accept attacker-chosen content | STRIPED-I | High | |
| STR·I7 | markdown rendering in the web console and the Slack client | finding | AI2 | Markdown image and link rendering exfiltrates context from the user's client | AI | Critical | second element: an outbound channel the egress proxy cannot see |
| STR·I8 | Redis keyspace holding every user's conversation | finding | I2 | — | STRIPED-I | High | co-mingled at ingest, separated only by conversation identifier at read |
| STR·P1 | Support shared mailbox content, S2 pilot scope | finding | P1 | Support shared mailbox processes customer data with no basis or DPIA | STRIPED-P | Critical | |
| STR·P2 | telemetry user dimension, PLAT-2822-1 | finding | P2 | Per-user telemetry retained thirteen months for a team-level dashboard | STRIPED-P | High | |
| STR·P2 | assembled_context field sent to the model provider | finding | P5 | — | STRIPED-P | Medium | second element: collected broadly, narrowed only at answer time |
| STR·P3 | external correspondents named in mail read from the Support mailbox | finding | P1 | — | STRIPED-P | Critical | third parties with no relationship to the assistant |
| STR·P4 | Redis, telemetry warehouse, platform logs and provider retention | finding | P3 | No deletion path spans conversation state, telemetry and platform logs | STRIPED-P | High | |
| STR·P5 | subject access, rectification and erasure for employees and customers | finding | P3 | — | STRIPED-P | High | rights documented nowhere and implemented nowhere |
| STR·P6 | calendar entry bodies and mail subjects reaching context | finding | P7 | Calendar and mail access allows special-category inference about colleagues | STRIPED-P | High | |
| STR·P7 | hosted model provider under the Data Platform agreement, D-01 | finding | P4 | Prompts are sent to a sub-processor under another team's agreement | STRIPED-P | High | |
| STR·P8 | 24-hour session context reused across unrelated questions | finding | P5 | — | STRIPED-P | Medium | no technical boundary between purposes inside a session |
| STR·P9 | privacy notice for employees and external correspondents | finding | P6 | No privacy notice reaches employees, colleagues or external correspondents | STRIPED-P | High | |
| STR·P9 | DPIA register entry for the assistant | finding | P1 | — | STRIPED-P | Critical | second element: high-risk processing with no assessment |
| STR·E1 | connector read and write paths from assistant-connectors | finding | E1 | — | STRIPED-E | Critical | no authorisation decision is made on any path |
| STR·E2 | inputs to the authorisation decision at the connector | finding | E1 | — | STRIPED-E | Critical | there is no decision, so there is nothing to influence |
| STR·E3 | one pilot user reaching another user's mailbox through the assistant | finding | E1 | — | STRIPED-E | Critical | ownership is not checked on any read path |
| STR·E4 | administrative functions exposed by assistant-svc | no exposure | — | — | — | — | the assistant exposes no privileged administrative function of its own; the elevation risk is connector scope, E1 to E3 |
| STR·E5 | model-composed tool call arguments binding to connector parameters | finding | AI3 | — | AI | Critical | no explicit allowlist on writable fields |
| STR·E6 | shared app registration application permissions, PLAT-2820-3 | finding | E1 | — | STRIPED-E | Critical | standing privilege far exceeds task need |
| STR·E6 | Slack app full scope set, PLAT-2814-3 | finding | E2 | Slack app holds the full scope set granted for prototype convenience | STRIPED-E | High | second element, distinct grant |
| STR·E7 | newly enabled workspace under PLAT-2831 | finding | E4 | A new workspace inherits the widest connector configuration by default | STRIPED-E | Medium | |
| STR·E8 | tool call resumed inside a 20-hour-old conversation | finding | E5 | — | STRIPED-E | Medium | authorisation evaluated at creation only |
| STR·E9 | org-level GitHub app with commit rights, PLAT-2814-4 | finding | E3 | GitHub app is installed at organisation scope with write access | STRIPED-E | High | |
| STR·D1 | Slack and console turn entry points | finding | D4 | Shared conversation store and connector pool have no per-user quota | STRIPED-D | Medium | |
| STR·D2 | model provider token consumption, PLAT-2822-4 | finding | D1 | No hard cap bounds token spend per user, team or conversation | STRIPED-D | High | |
| STR·D3 | tool-call loop inside one turn in assistant-svc | finding | D3 | Tool-call fan-out per turn has no iteration ceiling | STRIPED-D | High | |
| STR·D4 | untrimmed context growth over a 24-hour session, S2 rough edges | finding | D3 | — | STRIPED-D | High | work per turn grows without bound |
| STR·D5 | Redis keyspace and the shared connector process pool | finding | D4 | — | STRIPED-D | Medium | one principal can exhaust a resource others depend on |
| STR·D6 | client-side handling of provider rate limiting, S2 rough edges | finding | D2 | Provider rate limiting is absorbed by retry rather than a circuit breaker | STRIPED-D | Medium | |
| STR·D7 | poison-message handling in a worker pipeline | no exposure | — | — | — | — | no queue or worker pipeline exists; a failed tool call terminates within the turn |
| STR·D8 | answer produced after a connector call fails | finding | D5 | A failed connector call still yields an answer the user cannot distinguish | STRIPED-D | Medium | |
| PRV·L | telemetry user and team dimensions joined across systems | finding | P2 | — | STRIPED-P | High | activity in one context correlated with another by a single user key |
| PRV·I | telemetry rows described as aggregated to team level | finding | P2 | — | STRIPED-P | High | the store retains the per-user dimension the dashboard hides |
| PRV·Nr | 13 months of per-request records of an employee's tool use | finding | P2 | — | STRIPED-P | High | undeniable record of employee activity with no identified basis |
| PRV·D | assistant answers revealing that a document or mailbox record exists | finding | E1 | — | STRIPED-E | Critical | existence disclosed to users who cannot reach the record directly |
| PRV·Dd | customer correspondence reaching model context and telemetry | finding | P1 | — | STRIPED-P | Critical | |
| PRV·U | employees, colleagues and external correspondents | finding | P6 | — | STRIPED-P | High | |
| PRV·Nc | subject rights, DPIA, transfers and retention obligations | finding | P3 | — | STRIPED-P | High | obligations unmet and unassessed |
| PRV·Di | assistant outputs about individuals | no exposure | — | — | — | — | no ranking, scoring or selection of people is in scope; PROD-1131 Phase 1 is read-and-act with a human present |
| PRV·Ad | assistant actions affecting a person | no exposure | — | — | — | — | no decision with legal or similarly significant effect; Phase 3 unattended operation is out of scope for this release |
| PRV·DP1 | consent interface in the web console and Slack app | no exposure | — | — | — | — | there is no consent interface to weight unequally; the absence of any notice is recorded as P6 |
| PRV·DP2 | pilot enrolment and telemetry collection defaults | finding | P6 | — | STRIPED-P | High | users enrolled with no opt-in, notice or opt-out |
| PRV·DP3 | withdrawal and deletion routes for employees and customers | finding | P3 | — | STRIPED-P | High | withdrawing takes effort that granting never required, because granting never happened |
| PRV·DP4 | staged disclosure of processing practices | no exposure | — | — | — | — | no staged disclosure exists because no disclosure exists at any stage; recorded as P6 |
| PRV·DP5 | wording of decline options in either surface | no exposure | — | — | — | — | no decline option is presented anywhere, so no shaming language exists |
| PRV·DP6 | advertising, tracking and personalisation features | no exposure | — | — | — | — | the assistant carries no advertising, tracking or personalisation product |
| PRV·DP7 | account or registration requirements for core function | no exposure | — | — | — | — | the assistant is optional and the systems of record remain directly usable without it |
| PRV·DP8 | consent modals and preference interfaces | no exposure | — | — | — | — | neither surface presents a consent modal or a preference centre |
| PRV·H1 | web console default authentication posture | finding | S1 | — | STRIPED-S | High | security depends on a shared credential rather than the default identity provider |
| PRV·H2 | confirmation step removed from write actions, PLAT-2817 | finding | AI4 | Irreversible actions execute with no confirmation by product decision | AI | High | the secure path cost more effort, so it was removed |
| PRV·H3 | friction placement across read and write actions | finding | AI4 | — | AI | High | friction removed from everything rather than placed on risk |
| PRV·H4 | error text surfaced to the user by assistant-svc | no exposure | — | — | — | — | the surfaces render model prose rather than system error text, and production builds suppress diagnostic detail |
| PRV·H5 | information the user has when judging what the assistant did | finding | R3 | Action display is rendered from the model's narration, not the dispatch record | STRIPED-R | High | |
| PRV·H6 | account recovery for the assistant | no exposure | — | — | — | — | the assistant has no recovery path of its own; access follows the corporate identity provider and the VPN |
| PRV·H7 | out-of-band notification of security-relevant account events | no exposure | — | — | — | — | the assistant grants no per-account permission of its own to notify about; connector consent is the shared registration, E1 |
| PRV·H8 | user view of what the assistant has been granted on their behalf | finding | E1 | — | STRIPED-E | Critical | nobody granted anything and nothing can be revoked per person |
| EoA·SA | mail bodies, GitHub issue bodies, Slack messages and web results in context | finding | AI1 | — | AI | Critical | |
| EoA·SK | Mail.Send, Slack post, GitHub comment and GitHub commit tools | finding | AI3 | — | AI | Critical | |
| EoA·SQ | community web-search MCP server, PLAT-2814-5 | finding | AI10 | Community web-search MCP server is unvetted, unpinned and uninventoried | AI | High | |
| EoA·SJ | Redis conversation state read back as context on later turns | finding | AI14 | Conversation state acts as memory with no provenance or partitioning | AI | High | |
| EoA·S10 | markdown renderer in the web console and Slack client | finding | AI2 | — | AI | Critical | |
| EoA·S9 | tool descriptions and parameter schemas from the four MCP servers | finding | AI9 | Tool descriptions arrive as instructions and change without review | AI | High | |
| EoA·HA | Slack app scope set, PLAT-2814-3 | finding | E2 | — | STRIPED-E | High | capability far beyond task need |
| EoA·HA | org-level GitHub app commit rights, PLAT-2814-4 | finding | E3 | — | STRIPED-E | High | second element, distinct grant |
| EoA·HK | shared app registration used by every connector | finding | E1 | — | STRIPED-E | Critical | one identity shared across all agent tool use |
| EoA·HQ | peer agents exchanging messages | no exposure | — | — | — | — | a single orchestrator holds the loop and there are no peer agents; the cross-server case is AI8 |
| EoA·HJ | retry behaviour on provider rate limiting | finding | D2 | — | STRIPED-D | Medium | retry propagates the failure faster |
| EoA·H10 | agent inventory and stop mechanism, S2 open questions | finding | AI11 | No agent inventory, behavioural baseline or kill switch exists | AI | High | |
| EoA·H9 | MCP client holding O365, Slack, GitHub and web-search servers concurrently | finding | AI8 | One MCP client lets data from one server become another server's argument | AI | High | |
| EoA·DA | model answering from context the requesting user cannot reach | finding | E1 | — | STRIPED-E | Critical | authorisation is not enforced at the data layer |
| EoA·DK | vector store or RAG corpus | not in scope | — | — | — | — | PLAT-2810 has no vector store; search indexing is sibling epic PLAT-2790 and its tickets were not supplied |
| EoA·DQ | assistant statements about named colleagues and customers | finding | AI13 | Hallucinated statements about people are published outward as the user | AI | High | |
| EoA·DJ | token and tool-call consumption per turn | finding | D1 | — | STRIPED-D | High | |
| EoA·D10 | system prompt used by assistant-svc | finding | AI15 | System prompt contents are undocumented and its leakage unassessed | AI | Medium | |
| EoA·D9 | identification of the four MCP servers at connect time | finding | AI10 | — | AI | High | servers identified by name and registry position rather than by pinned digest |
| EoA·CA | model-composed content posted to Slack or sent by mail | finding | AI13 | — | AI | High | generated personal data transferred downstream with no provenance tag |
| EoA·CK | Redis, telemetry warehouse, platform logs, provider retention | finding | P3 | — | STRIPED-P | High | |
| EoA·CQ | calendar entries and mail threads about colleagues | finding | P7 | — | STRIPED-P | High | |
| EoA·CJ | assembled_context volume and unconstrained output shape | finding | P5 | — | STRIPED-P | Medium | |
| EoA·C10 | route for a person to discover and correct what the assistant asserts | finding | P6 | — | STRIPED-P | High | no disclosure, so no route to discovery or rectification |
| EoA·T7 | the web-search sanitiser as a defence against injected instructions | finding | AI6 | Adversarial subspace makes the web-search sanitiser structurally insufficient | AI | High | |
| EoA·T6 | classifier verdicts gating a security decision | no exposure | — | — | — | — | no classifier verdict gates a security decision; the sanitiser is a content transform and its enumerability weakness is AI6 |
| EoA·T5 | 24-hour session with untrimmed context, S2 rough edges | finding | AI5 | Context rot over untrimmed twenty-four-hour sessions degrades safety instructions | AI | High | |
| EoA·T4 | offline development of injections against a comparable model | finding | AI7 | Decision boundary transfer removes the observable part of attack development | AI | Medium | |
| EoA·T3 | PLAT-2817 acceptance criterion removing the confirmation step | finding | AI4 | — | AI | High | |
| EoA·T2 | model version, prompt templates and tool descriptions in use | finding | AI12 | Model versions, prompt templates and tool descriptions are not inventoried | AI | Medium | |
| EoA·T1 | PLAT-2825-1 action display rendered from the model's account | finding | R3 | — | STRIPED-R | High | model output treated as authoritative by the transparency control |
| AIX·CE | files committed by the GitHub connector and executed by CI on push | finding | T3 | — | STRIPED-T | High | model-selected content reaches an execution context through the build |
| AIX·HT | in-conversation action display and provenance surfacing | finding | R3 | — | STRIPED-R | High | |
| AIX·SK1 | markdown image tags in console and Slack output | finding | AI2 | — | AI | Critical | |
| AIX·SK2 | HTML rendering path in the web console | finding | AI2 | — | AI | Critical | same renderer weakness, same finding |
| AIX·SK3 | arguments passed to Mail.Send, Slack post and GitHub commit | finding | AI3 | — | AI | Critical | |
| AIX·SK4 | shell or code execution sink | no exposure | — | — | — | — | no shell or interpreter sink exists; tool dispatch is structured MCP calls |
| AIX·SK5 | database query constructed from model output | no exposure | — | — | — | — | no query is built from model output; Redis is accessed by conversation identifier only |
| AIX·SK6 | tool arguments and results written to platform logs at debug level | finding | T2 | — | STRIPED-T | High | |
| AIX·SK7 | agent-to-agent message sink | no exposure | — | — | — | — | there is no agent-to-agent messaging; a single orchestrator holds the loop |
| AIX·SK8 | content the assistant posts to Slack or sends by mail | finding | AI2 | — | AI | Critical | image and link tags are not stripped from outbound generated content either |
| AIX·SK9 | file path arguments on the GitHub commit tool | finding | T3 | — | STRIPED-T | High | a generated path is not canonicalised against an allowed root |
| AIX·SK10 | conversation state written and read back across turns | finding | AI14 | — | AI | High | |
| AIX·SK11 | vector store write path | not in scope | — | — | — | — | no vector store exists in PLAT-2810; see EoA·DK |
| AIX·ML1 | inference endpoint owned by this system | not in scope | — | — | — | — | the model is hosted by a third party; no self-hosted inference endpoint is in scope |
| AIX·ML2 | training set membership | not in scope | — | — | — | — | no training or fine-tuning pipeline; fine-tuning on organisational data is explicitly out of scope for this release |
| AIX·ML3 | model inversion against a hosted model | not in scope | — | — | — | — | no model owned by this system to invert |
| AIX·ML4 | training, fine-tuning or evaluation corpus | not in scope | — | — | — | — | no corpus is curated or contributed to by this system |
| AIX·ML5 | inference feature vector | not in scope | — | — | — | — | no feature-based classifier is in scope |
| AIX·ML6 | pretrained weights and adapters | not in scope | — | — | — | — | no weights are pulled or loaded by this system |
| AIX·ML7 | model serialisation format loaded at runtime | not in scope | — | — | — | — | no model artefact is deserialised by this system |
| CU·AS2 | Slack app scope grant reviewed since 2026-05-19, PLAT-2814-6 | finding | E2 | — | STRIPED-E | High | granted for the prototype and never reviewed |
| CU·AS3 | app registration client secret and model provider API key | finding | CL1 | Connector and provider credentials are long-lived with no stated rotation | Cloud | High | |
| CU·AS4 | web console shared password | finding | S1 | — | STRIPED-S | High | |
| CU·AS5 | developer access to technical credentials | no exposure | — | — | — | — | secrets are held in AWS Secrets Manager with workload-identity-scoped access per the platform controls page |
| CU·AS6 | propagation of a permission change to the shared registration | finding | CL1 | — | Cloud | High | no rotation cadence stated for the credential every connector depends on |
| CU·AS7 | traceability of self-granted IAM permissions | no exposure | — | — | — | — | workload identity requests are reviewed by Platform Security and recorded in the platform audit trail |
| CU·AS8 | permissions held by the shared app registration | finding | E1 | — | STRIPED-E | Critical | |
| CU·AS9 | node instance role reachable from connector pods | finding | CL6 | Node identity reachability from connector pods is unverified | Cloud | High | |
| CU·AS10 | MFA on the path to the web console | finding | S1 | — | STRIPED-S | High | the console sits behind a shared credential rather than the MFA-enforced identity provider |
| CU·ASJ | secrets present in deployment artefacts | no exposure | — | — | — | — | secrets are mounted at pod start from Secrets Manager and org-wide secret scanning with push protection covers the repositories |
| CU·ASQ | IAM surface for assistant-svc and assistant-connectors | no exposure | — | — | — | — | the workload IAM surface is two services, provisioned per service by Platform Security |
| CU·ASK | credential management solution in use | no exposure | — | — | — | — | AWS Secrets Manager is the established solution named in the platform controls page |
| CU·ASA | secrets committed to the assistant repositories | no exposure | — | — | — | — | organisation-wide secret scanning with push protection is enabled per the platform controls page |
| CU·DL2 | bill of materials for the assistant images and the MCP servers | finding | C3 | — | Container | High | no SBOM per image is evidenced for this workload |
| CU·DL3 | build-time dependencies bundled into runtime images | not in scope | — | — | — | — | no Dockerfiles or build manifests were supplied, so this cannot be walked against a real artefact |
| CU·DL4 | source registry for application dependencies | not in scope | — | — | — | — | no dependency manifests or lock files were supplied |
| CU·DL5 | behaviour change introduced by a new MCP server version | finding | AI9 | — | AI | High | a description diff is a behaviour change and nothing reviews it |
| CU·DL6 | redeployment triggered by an upstream MCP server release | finding | AI9 | — | AI | High | |
| CU·DL7 | dependency vulnerability scanning for the assistant repositories | no exposure | — | — | — | — | dependency scanning is enabled on all repositories through the shared CI template and Critical findings block the build |
| CU·DL8 | base image currency for assistant-svc | no exposure | — | — | — | — | base images are scanned on push and rebuilt weekly per the platform controls page |
| CU·DL9 | trustworthiness of the community web-search MCP server | finding | AI10 | — | AI | High | |
| CU·DL10 | network controls on CI pipeline runs | not in scope | — | — | — | — | no pipeline definitions were supplied |
| CU·DLJ | detection of code injected into the assistant repositories | no exposure | — | — | — | — | branch protection with required review, signed commits on protected branches and org-wide secret scanning are in place |
| CU·DLQ | certainty about which artefact is deployed | finding | C3 | — | Container | High | |
| CU·DLK | visibility of a deployment started from a developer account | not in scope | — | — | — | — | no pipeline definitions were supplied |
| CU·DLA | visibility of a change to the deploy pipeline | not in scope | — | — | — | — | no pipeline definitions were supplied |
| CU·RC3 | restore verification for conversation state and configuration | finding | RR1 | No tested rollback exists for model configuration or connector scope | Recovery & Resilience | Medium | |
| CU·RC4 | infrastructure-as-code state for the assistant deployment | finding | CL3 | No backup, restore drill or disaster recovery plan covers the assistant | Cloud | Medium | |
| CU·RC5 | backup of the telemetry warehouse partition | finding | CL3 | — | Cloud | Medium | |
| CU·RC6 | backup of the assistant's Secrets Manager entries | finding | CL3 | — | Cloud | Medium | |
| CU·RC7 | infrastructure rollback for the EKS deployment | finding | RR1 | — | Recovery & Resilience | Medium | |
| CU·RC8 | application rollback for assistant-svc | finding | RR1 | — | Recovery & Resilience | Medium | |
| CU·RC9 | whole-environment restoration | finding | RR1 | — | Recovery & Resilience | Medium | |
| CU·RC10 | user-initiated conversation deletion, PLAT-2825-2 | finding | R5 | — | STRIPED-R | Medium | deletion with no prior copy of the only action record |
| CU·RCJ | redundancy of backups for the assistant's stores | finding | CL3 | — | Cloud | Medium | |
| CU·RCQ | integrity verification of any backup taken | finding | CL3 | — | Cloud | Medium | |
| CU·RCK | principal able to delete both a store and its backup | finding | R5 | — | STRIPED-R | Medium | |
| CU·RCA | disaster recovery plan for a single-region EKS deployment | finding | CL3 | — | Cloud | Medium | |
| CU·MO4 | alert volume from assistant monitoring | no exposure | — | — | — | — | no alerting on the assistant exists yet to be desensitised by; the absence is CL2 |
| CU·MO5 | access to the sensitive partition of logs and telemetry | finding | CL5 | — | Cloud | Medium | |
| CU·MO6 | identifying a single action across service logs | finding | R4 | — | STRIPED-R | Medium | |
| CU·MO7 | alerting on anomalous model spend, PLAT-2822-4 | finding | CL2 | No cost or spend anomaly alerting exists on model consumption | Cloud | Medium | |
| CU·MO8 | integrity of the assistant's own action record | finding | R5 | — | STRIPED-R | Medium | |
| CU·MO9 | audit of production access by an authenticated operator | no exposure | — | — | — | — | Platform Security holds read access to platform and corporate SaaS audit logs for investigation |
| CU·MO10 | monitoring blind spots on assistant tool dispatch | finding | R1 | — | STRIPED-R | High | |
| CU·MOJ | interpretability of an alert on the assistant | finding | CL2 | — | Cloud | Medium | |
| CU·MOK | log access during a production outage | no exposure | — | — | — | — | platform logs are centralised outside the workload namespace with 90-day hot retention |
| CU·MOQ | incident response plan for assistant incidents | finding | O5 | No incident response process covers AI-specific incidents | Cross-cutting | Medium | |
| CU·MOA | secrets and personal data written to logs | finding | T2 | — | STRIPED-T | High | |
| CU·RS4 | cloud provider emergency contact records | no exposure | — | — | — | — | account contact management sits with the platform team and is outside this workload's design |
| CU·RS5 | compliance check of this workload against internal cloud policy | finding | O4 | Pilot expanded into a new data class without the scheduled security review | Cross-cutting | Medium | |
| CU·RS6 | rate limits on the Slack and console turn entry points | finding | D4 | — | STRIPED-D | Medium | |
| CU·RS7 | CPU and memory limits on orchestrator and connector pods | finding | C4 | No resource limits are stated on orchestrator or connector workloads | Container | Medium | |
| CU·RS8 | capabilities available to deployed assistant workloads | finding | C2 | No admission control enforces pod security, limits or image provenance | Container | High | |
| CU·RS9 | blast radius of one compromised connector process | finding | C1 | Connectors share the orchestrator namespace, so segmentation does not apply | Container | High | |
| CU·RS10 | ingress reaching assistant-svc and assistant-connectors | no exposure | — | — | — | — | public ingress reaches the surfaces only and internal services carry no ingress route |
| CU·RSJ | egress from the connector pods to the internet | finding | I3 | — | STRIPED-I | High | |
| CU·RSQ | separation between pilot and production environments | finding | CL4 | Environment separation between pilot and production is unstated | Cloud | Medium | |
| CU·RSK | publicly exposed cloud resources for this workload | no exposure | — | — | — | — | the only public surface is ingress to the Slack app and web console; internal services carry no public route |
| CU·RSA | published policy this workload can be held to | finding | O4 | — | Cross-cutting | Medium | the platform controls page covers platform controls only and excludes application-layer controls |
| CN·IM1 | base image references for assistant-svc and the web-search connector | finding | C3 | — | Container | High | |
| CN·IM2 | layer inspection of the assistant images | not in scope | — | — | — | — | no Dockerfiles or images were supplied |
| CN·IM3 | user directive and final stage of the assistant images | not in scope | — | — | — | — | no Dockerfiles were supplied |
| CN·IM4 | SBOM and scan gate on image promotion | finding | C3 | — | Container | High | |
| CN·IM5 | untrusted code executed during the image build | not in scope | — | — | — | — | no pipeline or build definitions were supplied |
| CN·IM6 | builder host and build cache provenance | not in scope | — | — | — | — | no build configuration was supplied |
| CN·RG1 | tag mutability for the assistant and MCP server images | finding | C3 | — | Container | High | |
| CN·RG2 | breadth of registry push credentials | not in scope | — | — | — | — | no registry configuration was supplied |
| CN·RG3 | signature verification at admission | finding | C3 | — | Container | High | |
| CN·RG4 | allowlisting of public images pulled into the cluster | finding | C3 | — | Container | High | |
| CN·RG5 | authentication required for registry pull | not in scope | — | — | — | — | no registry configuration was supplied |
| CN·RT1 | privileged flag and host namespaces on assistant workloads | finding | C2 | — | Container | High | |
| CN·RT2 | host path mounts on assistant workloads | finding | C2 | — | Container | High | nothing enforces their absence |
| CN·RT3 | capabilities and privilege escalation on assistant workloads | finding | C2 | — | Container | High | |
| CN·RT4 | seccomp profile and read-only root filesystem | finding | C2 | — | Container | High | |
| CN·RT5 | CPU, memory and PID limits on assistant workloads | finding | C4 | — | Container | Medium | |
| CN·RT6 | web-search connector processing attacker-authored content | finding | C6 | Web-search connector processes hostile input with no isolation boundary | Container | High | |
| CN·OR1 | API server reachability from connector pods | finding | C5 | Cluster RBAC and service-account token mounting for the assistant are unstated | Container | Medium | |
| CN·OR2 | human and CI authentication to the cluster | not in scope | — | — | — | — | no cluster authentication configuration was supplied |
| CN·OR3 | RBAC verbs held by the assistant service accounts | finding | C5 | — | Container | Medium | |
| CN·OR4 | automount of the default service-account token into assistant pods | finding | C5 | — | Container | Medium | |
| CN·OR5 | NetworkPolicy inside the assistant namespace | finding | C1 | — | Container | High | |
| CN·OR6 | admission controller enforcing workload policy | finding | C2 | — | Container | High | |
| CN·OR7 | secret sourcing and etcd encryption for the assistant | finding | I4 | — | STRIPED-I | High | |
| CN·OR8 | Kubernetes API audit logging for the assistant namespace | not in scope | — | — | — | — | no cluster audit configuration was supplied; the application-level recording gap is R1 |
| beyond the instrument — documentation drift | architecture page Authorisation section against PLAT-2820 ticket state | finding | O1 | Approved architecture page documents an authorisation control that does not exist | Cross-cutting | Critical | the prompts are a floor; doc-versus-delivery drift belongs in the O bucket |
| beyond the instrument — documentation drift | web console against the Identity section of the standing platform controls page | finding | O2 | Web console sits outside the organisation's own SSO and MFA standard | Cross-cutting | High | |
| beyond the instrument — governance | PR-03 group AI governance workstream at portfolio level | finding | O3 | No AI governance gate exists and the workstream has not started | Cross-cutting | High | |

---

## Roll-up

| Instrument | Prompts | Findings | No exposure | Not in scope |
|---|---|---|---|---|
| STRIPED (STR·) | 57 | 48 | 9 | 0 |
| Privacy (PRV·L) | 9 | 7 | 2 | 0 |
| Dark patterns / HCS (PRV·DP, PRV·H) | 16 | 6 | 10 | 0 |
| Elevation of Autonomy (EoA·) | 30 | 28 | 2 | 1 |
| AI extension (AIX·) | 20 | 9 | 4 | 8 |
| Cumulus (CU·) | 60 | 33 | 13 | 7 |
| Container (CN·) | 25 | 15 | 0 | 10 |
| Beyond the instrument | 3 | 3 | 0 | 0 |
| **Total** | **220** | **149** | **40** | **26** |

Row counts exceed prompt counts where a prompt was walked against two elements that reached different outcomes; 149 finding *rows* resolve to 68 distinct finding IDs.

**Findings by bucket:** S 5 · T 4 · R 5 · I 4 · P 7 · E 5 · D 5 · O 5 · AI 15 · CL 6 · C 6 · RR 1 — 68 in total.

---

## Notes for phase 2

- **P1, E1, AI1, AI2, AI3 and O1 are the load-bearing six.** O1 is the mechanism that hides E1 from every reader of the approved page; E1 is why AI1 escalates from nuisance to tenant-wide read; AI2 is the exfiltration path that completes without a credential; AI3 is what turns a read into a write.
- **Severity conditionality.** P1 is rated Critical on the basis that Support's shared mailbox is in active pilot use with real customer correspondence. If the mailbox is removed from connector scope, it falls to Medium as a design risk against future expansion. Footnote this in the register rather than softening the rating.
- **"If present" tagging.** I2, CL4, CL5, CL6, C2, C4, C5 and parts of C3 rest on the absence of a statement in documentation, not on an observed absence in code. Every one must carry the "if present" tag and name the artefact that would confirm it.
- **Do not merge R3 into R1.** They are separate weaknesses at the same place: R1 is that no independent record exists; R3 is that the record the user is shown comes from the model. Fixing R1 alone leaves R3 standing, and fixing R3 without R1 gives the display nothing truthful to read from.
- **D1 and CL2 are deliberately separate.** D1 is the absence of enforcement, CL2 the absence of detection. The Cumulus reference is explicit that an alert is not a limit, and PLAT-2822-4 delivers only the alert.
- **Credit due in the write-up.** AI4, AI5, AI2 and P1 were all observed by the team first, in the pilot operations page. Say so in each finding rather than presenting them as discoveries.
