# Internal AI Assistant — Candidate Register (phase 1)

**Version:** 1.0 · **Date:** 2026-09-08 · **Model:** Claude Opus 5
**Surfaces in scope:** STRIPED · privacy · AI/ML · cloud · containers
**Instruments walked:** STRIPED 57 · PRV·L 9 · PRV·DP and PRV·H 16 · EoA 30 · AIX 20 · Cumulus 60 · CN 25
**Companion:** `06-threat-model.md` writes up every row marked `finding` under the ID assigned here.

---

## Why this file exists

This is the elicitation pass, written before any finding was written up. Every prompt of every in-scope instrument has a row, so a reader can see which questions were asked as well as which produced answers. Finding IDs are assigned here and are final. Where several prompts reach the same weakness, the rows share one finding ID and the repeat rows carry an em dash in the Title column rather than a second ID — one weakness gets one ID however many prompts surfaced it.

---

## Candidates

| Prompt | Element | Outcome | ID | Title | Category | Severity | Note |
|---|---|---|---|---|---|---|---|
| STR·S1 | POST /turns in turns.ts:16-23 | finding | S1 | Caller identity arrives as an unverified x-assistant-user-id header | STRIPED-S | High | |
| STR·S1 | Web console surface, PLAT-2831-3 | finding | S5 | The web console is behind one shared password with no per-user authentication | STRIPED-S | High | |
| STR·S2 | x-assistant-user-id and x-assistant-workspace-id headers | finding | S1 | — | STRIPED-S | High | No token is verified because none is used |
| STR·S3 | credentialFor in serviceIdentity.ts:26 and the rotate-credentials runbook | finding | CL2 | Connector credentials are long-lived, shared, and have no per-user revocation path | Cloud | Medium | |
| STR·S4 | POST /invoke on assistant-connectors mcp/server.ts:36 | finding | S2 | The connector service authenticates no caller on invoke, search or tools | STRIPED-S | High | |
| STR·S5 | Redis key conv:{conversationId} in history.ts:9 | finding | S3 | Possession of a conversation ID resumes and acts as its owner | STRIPED-S | High | |
| STR·S6 | Web console shared VPN password | finding | S5 | — | STRIPED-S | High | |
| STR·S7 | PLAT-2820-1 delegated OAuth flows | no exposure | — | — | — | — | No delegated or federated flow exists to attack; the unbuilt state is carried by E4 and O1 |
| STR·S8 | send_mail with send-as in o365.ts:11 | finding | S4 | Mail sent with send-as is indistinguishable from mail the person wrote | STRIPED-S | Medium | |
| STR·T1 | assistant-svc to Redis on 6379, redis.tf:12 | finding | T1 | Redis conversation state has no transport encryption, no auth token and a VPC-wide security group | STRIPED-T | High | |
| STR·T2 | promptAssembly.renderHistory at promptAssembly.ts:17-21 | finding | T3 | Conversation history is flattened to role-prefixed text, allowing a user to forge turn roles | STRIPED-T | Medium | |
| STR·T2 | The hosted model as the interpreter of assembled context | finding | AI1 | Indirect prompt injection through internal retrieved content that is never sanitised | AI | Critical | |
| STR·T3 | The message field of the POST /turns body | no exposure | — | — | — | — | Only conversationId and message are client-supplied and both are consumed server-side; the identity weakness is S1 |
| STR·T4 | Redis key conv:{conversationId} write path in history.ts:21-26 | finding | T1 | — | STRIPED-T | High | A write changes the identity a later turn runs under |
| STR·T5 | customInstructions in config/workspaces.json | finding | T2 | Workspace customInstructions are concatenated into the system message unvalidated | STRIPED-T | High | |
| STR·T5 | WORKSPACES_PATH and WORKSPACE_TOOLS_PATH environment variables | finding | T4 | Workspace and tool configuration paths are overridable by environment variable at runtime | STRIPED-T | Low | |
| STR·T6 | Upload and import paths in assistant-svc | no exposure | — | — | — | — | No upload or import route exists; the only inbound content is the message field and connector results |
| STR·T7 | Queues and event streams in the turn loop | no exposure | — | — | — | — | The turn loop is synchronous with no queue, topic or stream |
| STR·T8 | .github/workflows/ci.yml | finding | O3 | CI has no dependency scanning or lockfile audit, inherited from an exempt template | Supply Chain | High | |
| STR·R1 | toolDispatch.dispatch at toolDispatch.ts:12-20 | finding | R1 | Tool arguments and results are not recorded in production, contradicting the approved audit claim | STRIPED-R | High | |
| STR·R2 | The log.info tool call line at toolDispatch.ts:13 | finding | R2 | The tool-call record omits the acting user | STRIPED-R | Medium | |
| STR·R3 | credentialFor returning scope application, serviceIdentity.ts:26-32 | finding | R3 | Downstream systems attribute every assistant action to the shared service principal | STRIPED-R | High | |
| STR·R4 | Platform logging retention under Platform Security | no exposure | — | — | — | — | The workload cannot rewrite platform logs; the gap is what is written, which is R1 |
| STR·R5 | The per-connector catch at mcp/server.ts:29 | finding | D5 | Connector search failures are swallowed and the turn answers from partial context | STRIPED-D | Medium | |
| STR·R6 | The invoke request body in mcpClient.ts:13-17 | finding | R4 | No correlation identifier spans the orchestrator and the connector service | STRIPED-R | Medium | |
| STR·R7 | conversationTtlSeconds at config.ts:36 | finding | R5 | Conversation retention of 24 hours is shorter than the realistic detection lag | STRIPED-R | Medium | |
| STR·I1 | POST /search response at mcp/server.ts:33 | finding | I3 | One application credential lets any pilot user retrieve content they cannot open directly, including Slack DMs | STRIPED-I | Critical | |
| STR·I2 | GET /internal/debug/config at debug.ts:16-23 | finding | I2 | The debug config route discloses runtime configuration and endpoint URLs | STRIPED-I | Medium | |
| STR·I3 | GET /internal/debug/conversations/:id at debug.ts:10-14 | finding | I1 | The debug conversation route returns full conversation state unauthenticated and is on by default | STRIPED-I | High | |
| STR·I4 | history.resolve called from debug.ts:11 and turns.ts:26 | finding | S3 | — | STRIPED-S | High | No ownership check on either read path |
| STR·I5 | The Redis conversation store | finding | T1 | — | STRIPED-T | High | |
| STR·I5 | The analytics warehouse telemetry table | finding | P3 | Per-user usage telemetry is retained 13 months for a team-level purpose | STRIPED-P | Medium | |
| STR·I6 | aws_iam_role_policy.assistant_secrets at iam.tf:7-22 | finding | CL1 | One IAM role serves both services and grants wildcard read over every assistant secret | Cloud | High | |
| STR·I6 | The environment dump at debug.ts:19-21 | finding | I2 | — | STRIPED-I | Medium | |
| STR·I7 | Markdown image rendering in the web console, PLAT-2831-2 | finding | AI4 | Model output is rendered as markdown with no output filter, giving an image exfiltration channel | AI | High | |
| STR·I7 | The platform egress proxy domain allowlist | finding | CL4 | Egress allowlisting is broadened by the fallback provider domain and the search API with no recorded review | Cloud | Medium | |
| STR·I8 | conv:{conversationId} keys, not namespaced by workspace | finding | S3 | — | STRIPED-S | High | |
| STR·P1 | Support shared mailbox content reaching read_mail | finding | P1 | Customer personal data enters scope through the Support shared mailbox with no lawful basis and no DPIA | STRIPED-P | High | |
| STR·P2 | The userId column of the telemetry record | finding | P3 | — | STRIPED-P | Medium | |
| STR·P3 | Invite bodies and message bodies returned by read_calendar and read_mail | finding | P2 | Third parties in mail, calendar and DMs are processed with no notice and no route to object | STRIPED-P | Medium | |
| STR·P4 | conv:{conversationId} and the provider 30-day store | finding | P4 | No deletion path spans conversation state, provider retention, telemetry and platform logs | STRIPED-P | High | |
| STR·P5 | history.drop at history.ts:28, referenced from nowhere | finding | P4 | — | STRIPED-P | High | PLAT-2825-2 is marked Done but no route calls it |
| STR·P6 | read_mail bodies summarised by aurora-1-mini in ws-support | finding | P1 | — | STRIPED-P | High | Special-category content can arrive in correspondence with no basis |
| STR·P7 | The 429 fallback in hosted.ts:32-35 | finding | I4 | Prompts and completions overflow to a public provider endpoint outside the enterprise DPA | STRIPED-I | High | |
| STR·P8 | gather fan-out at retrieval.ts:11-21 | finding | P5 | One retrieval merges every connector's content into a single context, mixing purposes | STRIPED-P | Medium | |
| STR·P9 | Privacy notice and DPIA for the pilot | finding | P6 | Employees and customers are unaware the assistant reads their correspondence | STRIPED-P | Medium | |
| STR·E1 | retrieval.gather omitting userId at retrieval.ts:12-16 | finding | E3 | Retrieval is dispatched with no user identity at all, so no authorisation decision is possible | STRIPED-E | High | |
| STR·E2 | state.workspaceId read from stored state in turnLoop.ts:13-16 | finding | S3 | — | STRIPED-S | High | |
| STR·E3 | search_messages over channels and DMs in slack.ts:11 | finding | I3 | — | STRIPED-I | Critical | |
| STR·E4 | The debug router mounted at server.ts:11 | finding | I1 | — | STRIPED-I | High | |
| STR·E5 | Field binding in the POST /turns handler | no exposure | — | — | — | — | The handler binds only conversationId and message; there is no entity or model binding to over-write |
| STR·E6 | The assistant_pilot IAM role at iam.tf:2-5 | finding | CL1 | — | Cloud | High | |
| STR·E6 | The appRegistration map at serviceIdentity.ts:18-24 | finding | E4 | The shared app registration holds application permissions exceeding any pilot user | STRIPED-E | Critical | |
| STR·E7 | toolsForWorkspace at registry.ts:31-40 | finding | E1 | An unconfigured workspace receives every tool including commit and send_mail | STRIPED-E | Critical | |
| STR·E7 | forWorkspace at workspaceConfig.ts:6-20 | finding | E2 | An unknown workspace resolves to defaults instead of being refused | STRIPED-E | Medium | |
| STR·E8 | history.resolve on conversation resumption, turns.ts:25-27 | finding | S3 | — | STRIPED-S | High | |
| STR·E9 | The commit tool at github.ts:12 against branch-protection-exemptions.yml | finding | E6 | The org-level GitHub app can commit to repositories exempt from branch protection | STRIPED-E | High | |
| STR·E9 | The Slack app full scope set, PLAT-2814-3 | finding | E5 | The Slack app holds the full scope set including direct message read | STRIPED-E | High | |
| STR·D1 | POST /turns entry point at server.ts:8-10 | finding | D1 | No rate limit, concurrency bound or per-user cap on POST /turns | STRIPED-D | Medium | |
| STR·D2 | Model spend against PLAT-2822-4 | finding | D2 | Model spend has no enforced ceiling and spend alerting is not built | STRIPED-D | High | |
| STR·D3 | POST /search fan-out to five connectors at mcp/server.ts:27-31 | finding | D3 | One turn fans out to five connectors and up to eight iterations with cumulative context growth | STRIPED-D | Medium | |
| STR·D4 | The cumulative user string at turnLoop.ts:46 | finding | D4 | Conversation context is never trimmed inside a 24-hour session | STRIPED-D | Medium | |
| STR·D5 | The shared enterprise endpoint quota across ws-platform and ws-support | finding | D2 | — | STRIPED-D | High | Exhaustion by one workspace pushes every workspace onto the fallback, which is I4 |
| STR·D6 | The single fallback attempt in hostedProvider.complete | no exposure | — | — | — | — | The provider call retries once and then throws; retries are bounded. The fallback's contractual problem is I4 |
| STR·D7 | Poison-message handling in the turn loop | not in scope | — | — | — | — | No queue, worker or pipeline exists that a message could block |
| STR·D8 | The catch at mcp/server.ts:29 and the empty return at retrieval.ts:18 | finding | D5 | — | STRIPED-D | Medium | |
| PRV·L | telemetry userId joined to conversation userId and downstream audit | finding | P3 | — | STRIPED-P | Medium | |
| PRV·I | The per-request user and team dimensions of the telemetry record | finding | P3 | — | STRIPED-P | Medium | |
| PRV·Nr | The provider 30-day prompt and completion store, config.ts:31 | finding | I5 | The provider retains prompts and completions for 30 days against a zero-retention claim | STRIPED-I | Medium | |
| PRV·D | POST /search results confirming a record exists that the asker cannot open | finding | I3 | — | STRIPED-I | Critical | |
| PRV·Dd | Customer correspondence reaching the model in ws-support | finding | P1 | — | STRIPED-P | High | |
| PRV·U | Privacy notice coverage for the assistant | finding | P6 | — | STRIPED-P | Medium | |
| PRV·Nc | DPIA and record of processing for PLAT-2810 | finding | P1 | — | STRIPED-P | High | |
| PRV·Di | Assistant output feeding an eligibility or ranking decision | no exposure | — | — | — | — | Output is prose for a human reader; the Support refund-policy instruction is a lookup, not a determination about a person |
| PRV·Ad | Unattended operation, PROD-1131 phase 3 | no exposure | — | — | — | — | Pilot scope requires a human present for every turn and no decision with legal or similar effect is automated; revisit if phase 3 proceeds |
| PRV·DP1 | Consent interface in the Slack app and web console | no exposure | — | — | — | — | There is no consent interface to weight unfairly; deployment is by workspace administrators |
| PRV·DP2 | Pilot enrolment of Platform and Support users | finding | P6 | — | STRIPED-P | Medium | Users are enrolled without individual notice and their mail is read by default |
| PRV·DP3 | Conversation deletion via history.drop | finding | P4 | — | STRIPED-P | High | |
| PRV·DP4 | Staged disclosure of data practices to pilot users | no exposure | — | — | — | — | There is no staged disclosure because there is no disclosure at all, which is P6 |
| PRV·DP5 | Decline wording in either surface | no exposure | — | — | — | — | There is no decline path to shame; the action-first wording addresses the model, not the user |
| PRV·DP6 | Advertising, tracking or personalisation paths | no exposure | — | — | — | — | An internal tool with no advertising, no tracking pixels and no personalisation revenue path |
| PRV·DP7 | Registration required to use the assistant | no exposure | — | — | — | — | Use is optional and declining costs a person nothing |
| PRV·DP8 | Consent modals in the web console | no exposure | — | — | — | — | Neither surface presents a consent modal or a repeated prompt |
| PRV·H1 | toolsForWorkspace default for an unconfigured workspace | finding | E1 | — | STRIPED-E | Critical | |
| PRV·H2 | The confirmation step removed by ADR-0003 | finding | AI3 | Write actions execute with no confirmation and no irreversibility gate | AI | Critical | |
| PRV·H3 | send_mail and commit invocation without confirmation | finding | AI3 | — | AI | Critical | |
| PRV·H4 | The step-limit reply at turnLoop.ts:50 and partial retrieval results | finding | D5 | — | STRIPED-D | Medium | A degraded answer is indistinguishable from a complete one |
| PRV·H5 | The action list rendered after the turn, PLAT-2825-1 | finding | AI13 | The action list is the model's own narration, without arguments, targets or authority | AI | Medium | |
| PRV·H6 | Web console access recovery over the shared VPN password | finding | S5 | — | STRIPED-S | High | |
| PRV·H7 | Notification when the assistant sends mail as a person | finding | AI13 | — | AI | Medium | The only notice is in the same conversation the actor controls |
| PRV·H8 | The rotate-credentials runbook statement that there is no per-user credential | finding | CL2 | — | Cloud | Medium | |
| EoA·SA | GitHub issue and comment bodies returned by github.ts:19 | finding | AI1 | — | AI | Critical | |
| EoA·SA | Stored turns replayed from conv:{conversationId} | finding | AI9 | Conversation state is cross-session memory any VPC principal can write and it is read back as trusted | AI | High | |
| EoA·SK | send_mail arguments chosen by the model at toolDispatch.ts:16 | finding | AI2 | Tool arguments are unconstrained, so the model chooses recipients, branches and bodies | AI | High | |
| EoA·SQ | The community web search MCP server, PLAT-2814-5 | finding | AI10 | The community web search MCP server is unpinned and there is no inventory of models, prompts and connectors | AI | Medium | |
| EoA·SJ | conv:{conversationId} state written by history.append | finding | AI9 | — | AI | High | |
| EoA·S10 | Markdown rendering of assistant output in the web console | finding | AI4 | — | AI | High | |
| EoA·S9 | Vendor MCP tool descriptions returned by GET /tools | finding | AI11 | Tool descriptions are not integrity checked between approval and use | AI | Medium | |
| EoA·HA | The write tools listed in tool-guidance.md | finding | AI3 | — | AI | Critical | |
| EoA·HK | credentialFor returning one application token per connector | finding | E4 | — | STRIPED-E | Critical | |
| EoA·HQ | Peer agents and orchestrator-to-agent messages | not in scope | — | — | — | — | A single agent; there are no peer agents and no agent-to-agent messages in the design |
| EoA·HJ | The per-connector catch at mcp/server.ts:29 | finding | D5 | — | STRIPED-D | Medium | |
| EoA·H10 | Stopping the assistant, per the incident runbook step 4 | finding | RR1 | There is no kill switch and stopping the assistant means scaling the deployment to zero | Recovery & Resilience | High | |
| EoA·H9 | connectorFor first-match resolution at registry.ts:42-44 | finding | AI16 | Tool names form one flat namespace across five servers with first-match routing | AI | Low | |
| EoA·DA | search_messages over channels and DMs | finding | I3 | — | STRIPED-I | Critical | |
| EoA·DK | Vector store or embedding index in the retrieval path | no exposure | — | — | — | — | ADR-0004 fans out to live connector search at query time; there is no vector store, embedding index or ingested corpus |
| EoA·DQ | Generated bodies passed to comment_issue and send_mail | finding | AI14 | Generated claims are written into systems of record without verification | AI | Medium | |
| EoA·DJ | Per-user and per-workspace token budgets | finding | D2 | — | STRIPED-D | High | |
| EoA·DJ | POST /turns request rate | finding | D1 | — | STRIPED-D | Medium | |
| EoA·D10 | The ws-support refund-policy instruction in workspaces.json:13 | finding | AI15 | Business rules are enforced only by system prompt text that is extractable | AI | Low | |
| EoA·D9 | The community web search MCP server running in cluster | finding | AI10 | — | AI | Medium | |
| EoA·CA | Generated mail bodies leaving through send_mail | finding | AI14 | — | AI | Medium | |
| EoA·CK | conv:{conversationId}, the provider store and the warehouse table | finding | P4 | — | STRIPED-P | High | |
| EoA·CQ | read_mail bodies summarised for a Support agent | finding | P1 | — | STRIPED-P | High | |
| EoA·CJ | renderRetrieved returning bodies as authored | finding | P5 | — | STRIPED-P | Medium | |
| EoA·C10 | Subject access covering assistant output | finding | P6 | — | STRIPED-P | Medium | |
| EoA·C10 | Correction of a generated claim about a person | finding | AI14 | — | AI | Medium | |
| EoA·T7 | sanitiseWebContent at webContent.ts:7-18 | finding | AI6 | Adversarial subspace means the web content sanitiser denylist covers a vanishing fraction of inputs | AI | High | |
| EoA·T6 | The sanitiser regular expression as a probeable boundary | finding | AI8 | Decision boundary transfer leaves the only content control reproducible offline and unobserved | AI | Medium | |
| EoA·T5 | The 24-hour conversation TTL at config.ts:36 with no trimming | finding | AI7 | Context rot leaves 24-hour sessions untrimmed with safety text never re-injected | AI | Medium | |
| EoA·T4 | sanitiseWebContent as the only content control | finding | AI8 | — | AI | Medium | |
| EoA·T3 | ADR-0003 and the PLAT-2817 acceptance criterion | finding | AI3 | — | AI | Critical | |
| EoA·T2 | Per-workspace model selection under ADR-0007 | finding | AI12 | Workspaces select their model with no review and the most sensitive workspace runs the weakest | AI | Medium | |
| EoA·T2 | Prompt files and connector versions outside any inventory | finding | AI10 | — | AI | Medium | |
| EoA·T1 | The action list rendered from the model's narration | finding | AI13 | — | AI | Medium | |
| AIX·CE | The commit tool writing to repositories that CI builds | finding | AI17 | The commit tool puts model-authored code on a path that CI builds and deploys | AI | High | |
| AIX·HT | The action list returned by POST /turns at turns.ts:43-47 | finding | AI13 | — | AI | Medium | |
| AIX·SK1 | The web console markdown renderer | finding | AI4 | — | AI | High | |
| AIX·SK2 | Slack rendering of assistant output | finding | AI4 | — | AI | High | |
| AIX·SK3 | The arguments object passed to connector.invoke | finding | AI2 | — | AI | High | |
| AIX·SK4 | Committed file content reaching the CI build | finding | AI17 | — | AI | High | |
| AIX·SK5 | Query construction in history.ts | no exposure | — | — | — | — | No SQL or query language is constructed; Redis access uses fixed GET, SET and DEL against a computed key |
| AIX·SK6 | The JSON logger at logger.ts:6-9 | no exposure | — | — | — | — | Fields are serialised through JSON.stringify, which escapes newlines and control characters, and no secret is in the logged fields |
| AIX·SK7 | Agent-to-agent message consumption | not in scope | — | — | — | — | A single model with no agent-to-agent messaging |
| AIX·SK8 | Generated body passed to send_mail and post_message | finding | AI4 | — | AI | High | |
| AIX·SK8 | Factual claims in generated mail and issue comments | finding | AI14 | — | AI | Medium | |
| AIX·SK9 | The path argument of the commit tool | finding | AI17 | — | AI | High | |
| AIX·SK10 | history.append writing turns to Redis | finding | AI9 | — | AI | High | |
| AIX·SK11 | Vector store write path | not in scope | — | — | — | — | No vector store or embedding corpus exists in the design |
| AIX·ML1 | Training or fine-tuning pipeline for the assistant | not in scope | — | — | — | — | The model is a hosted third-party service and PLAT-2810 excludes fine-tuning from this release |
| AIX·ML2 | Training set membership for the hosted model | not in scope | — | — | — | — | No organisational training set exists; the provider's corpus is outside this system |
| AIX·ML3 | Model inversion against the hosted model | not in scope | — | — | — | — | No model is trained or hosted by the organisation |
| AIX·ML4 | Training, fine-tuning or evaluation corpus | not in scope | — | — | — | — | No corpus is curated by the organisation for this system |
| AIX·ML5 | Feature vectors at inference | not in scope | — | — | — | — | The system passes natural-language prompts, not feature vectors, to a hosted endpoint |
| AIX·ML6 | Pretrained weights and adapters | not in scope | — | — | — | — | No weights or adapters are pulled; inference is a hosted API call |
| AIX·ML7 | Model loading format and source | not in scope | — | — | — | — | No model artefact is loaded into the process |
| CU·AS2 | The Slack app scope grant, PLAT-2814-3 | finding | E5 | — | STRIPED-E | High | Third-party grant never reviewed since the prototype |
| CU·AS3 | Static connector secrets in Secrets Manager | finding | CL2 | — | Cloud | Medium | |
| CU·AS4 | The shared web console password | finding | S5 | — | STRIPED-S | High | |
| CU·AS5 | assistant/* read granted to the workload role | finding | CL1 | — | Cloud | High | |
| CU·AS6 | The rotate-credentials runbook restart step | finding | CL2 | — | Cloud | Medium | |
| CU·AS7 | IAM permission self-grant by the workload role | no exposure | — | — | — | — | The role holds only secretsmanager:GetSecretValue and no iam or sts action that would let it widen itself |
| CU·AS8 | The inline policy at iam.tf:10-21 | finding | CL1 | — | Cloud | High | |
| CU·AS9 | Escalation paths from the assistant_pilot role | no exposure | — | — | — | — | No PassRole, CreatePolicyVersion, AttachRolePolicy or AssumeRole action is granted |
| CU·AS10 | MFA on the web console path | finding | S5 | — | STRIPED-S | High | |
| CU·ASJ | Secrets in the Helm chart and manifests | no exposure | — | — | — | — | The chart references Secrets Manager through the IRSA annotation and .env.example carries empty values |
| CU·ASQ | IAM complexity for this workload | no exposure | — | — | — | — | One role and one inline policy; the defect is breadth, CL1, not complexity |
| CU·ASK | Credential management solution in use | no exposure | — | — | — | — | AWS Secrets Manager with workload identity, which is the platform standard |
| CU·ASA | Credential literals in the assistant-platform tree | no exposure | — | — | — | — | Organisation-wide secret scanning with push protection is on and no credential literal appears in the supplied tree |
| CU·DL2 | SBOM for registry.internal/assistant:0.4.1 | finding | C5 | No SBOM, no image signing and no admission-time verification | Container | Medium | |
| CU·DL3 | devDependencies in the service manifests | no exposure | — | — | — | — | Build tooling sits in the root manifest and each service declares only express, ioredis and undici |
| CU·DL4 | npm ci without a committed lockfile | finding | O3 | — | Supply Chain | High | |
| CU·DL5 | Version ranges in services/assistant-svc/package.json | finding | O3 | — | Supply Chain | High | |
| CU·DL6 | Redeployment triggered by an external dependency | no exposure | — | — | — | — | Deployment is by chart with a pinned application version and no auto-update path from an external dependency |
| CU·DL7 | The build job in ci.yml:9-18 | finding | O3 | — | Supply Chain | High | |
| CU·DL8 | The base image behind registry.internal/assistant:0.4.1 | finding | C1 | The container image is referenced by a mutable tag rather than a digest | Container | Medium | |
| CU·DL9 | The community MCP web search dependency | finding | AI10 | — | AI | Medium | |
| CU·DL10 | Network control on the ci.yml runner | no exposure | — | — | — | — | The workflow runs checkout, setup-node, npm ci, build and test with no deploy credential and no cloud access |
| CU·DLJ | Code injection into repositories the assistant can commit to | finding | E6 | — | STRIPED-E | High | |
| CU·DLQ | Artefact identity for the deployed image | finding | C5 | — | Container | Medium | |
| CU·DLK | Deployment started from a developer account | no exposure | — | — | — | — | The workflow triggers only on push to main and on pull request, both visible in the repository action history |
| CU·DLA | Changes to the shared platform-ci template | finding | E6 | — | STRIPED-E | High | The exemption means such a change needs no approving review |
| CU·RC3 | Restore testing for conversation state and Terraform state | finding | RR2 | There is no backup or restore drill for conversation state, Terraform state or workspace configuration | Recovery & Resilience | Medium | |
| CU·RC4 | Terraform state backup for the assistant stack | finding | RR2 | — | Recovery & Resilience | Medium | |
| CU·RC5 | Backups of the Redis conversation store | finding | RR2 | — | Recovery & Resilience | Medium | |
| CU·RC6 | Secrets Manager version history for assistant secrets | no exposure | — | — | — | — | Secrets Manager retains prior versions and the rotation runbook rotates rather than replaces |
| CU·RC7 | Infrastructure rollback for the assistant stack | no exposure | — | — | — | — | Infrastructure is Terraform-managed and rollback is a revert and apply; the untested part is RR2 |
| CU·RC8 | Application rollback of the Helm release | no exposure | — | — | — | — | The chart pins an application version and Helm rollback is available |
| CU·RC9 | Whole-environment restore for the beta cluster | finding | RR2 | — | Recovery & Resilience | Medium | |
| CU·RC10 | Backup before deletion of conversation state | no exposure | — | — | — | — | The only store expires on a TTL and holds no system of record |
| CU·RCJ | Redundancy of assistant backups | no exposure | — | — | — | — | There is nothing backed up to lose redundantly, which is the point of RR2 |
| CU·RCQ | Integrity verification of assistant backups | no exposure | — | — | — | — | No backup exists to verify, which is RR2 |
| CU·RCK | Delete permissions held by the assistant_pilot role | no exposure | — | — | — | — | The role holds no delete action on any store |
| CU·RCA | Disaster recovery plan for the assistant | finding | RR3 | There is no incident response plan for a compromised assistant | Recovery & Resilience | Medium | |
| CU·MO4 | Alert volume for the assistant workload | no exposure | — | — | — | — | No alerting is defined for this workload at all, which is RR3 rather than fatigue |
| CU·MO5 | Access restriction on the debug config output | finding | I2 | — | STRIPED-I | Medium | |
| CU·MO6 | Correlating a turn across the two services | finding | R4 | — | STRIPED-R | Medium | |
| CU·MO7 | Cost alerting against PLAT-2822-4 | finding | D2 | — | STRIPED-D | High | |
| CU·MO8 | Log deletion by the workload role | no exposure | — | — | — | — | Logs ship to platform logging under Platform Security's control and the workload role cannot delete them |
| CU·MO9 | Records of debug route access in production | finding | I1 | — | STRIPED-I | High | |
| CU·MO10 | Detection coverage for assistant misbehaviour | finding | RR3 | — | Recovery & Resilience | Medium | |
| CU·MOJ | Alert interpretation for the assistant | no exposure | — | — | — | — | No alerts are defined to interpret, which is RR3 |
| CU·MOQ | Incident response for an assistant compromise | finding | RR3 | — | Recovery & Resilience | Medium | |
| CU·MOK | Log availability during a cluster outage | no exposure | — | — | — | — | Platform logging sits outside the cluster and survives a workload outage |
| CU·MOA | Personal data in the telemetry record | finding | P3 | — | STRIPED-P | Medium | |
| CU·RS4 | Provider emergency contact for the AWS account | no exposure | — | — | — | — | The account is platform-managed with the platform's own contact record |
| CU·RS5 | Compliance of this workload with the platform standard | finding | O4 | The chart disables the default-deny network policy the platform page claims exists | Cross-cutting | High | |
| CU·RS5 | Diagnostic route policy for this workload | finding | O5 | Diagnostic routes ship enabled against a platform standard that says they are off | Cross-cutting | Medium | |
| CU·RS6 | Rate limits on POST /turns | finding | D1 | — | STRIPED-D | Medium | |
| CU·RS7 | CPU and memory limits in values.yaml | finding | C4 | Neither deployment sets CPU, memory or PID limits | Container | Medium | |
| CU·RS8 | Pod capabilities and privilege settings in values.yaml | finding | C2 | Neither deployment sets a pod security context, so root and a writable root filesystem are the default | Container | Medium | |
| CU·RS9 | assistant-connectors as the single holder of all five credentials | finding | E4 | — | STRIPED-E | Critical | |
| CU·RS10 | Ingress routes for assistant-svc and assistant-connectors | no exposure | — | — | — | — | The platform terminates inbound at the edge and neither service declares an ingress route |
| CU·RSJ | Egress allowlist entries for the fallback endpoint and the search API | finding | CL4 | — | Cloud | Medium | |
| CU·RSQ | ws-beta sharing the pilot cluster and credentials | finding | CL3 | The beta sandbox workspace shares the pilot's cluster, credentials and tool set | Cloud | Medium | |
| CU·RSK | Public exposure of Redis and the two services | no exposure | — | — | — | — | Redis sits in private subnets, neither service declares an ingress route and the chart creates no public service |
| CU·RSA | Cloud and AI usage policy above this design | finding | O6 | Group AI governance is accepted as a retrofit, so no policy layer sits above this design | Cross-cutting | Medium | |
| CN·IM1 | image.tag 0.4.1 in values.yaml:1-3 | finding | C1 | — | Container | Medium | |
| CN·IM2 | Layer contents of registry.internal/assistant | not in scope | — | — | — | — | No Dockerfile or build definition was supplied; recorded as a missing input in the context note |
| CN·IM3 | USER directive and final stage of the assistant image | finding | C2 | — | Container | Medium | |
| CN·IM4 | Scan gate on promotion of the assistant image | finding | C5 | — | Container | Medium | |
| CN·IM5 | Build inputs to the assistant image | finding | O3 | — | Supply Chain | High | |
| CN·IM6 | Build provenance for registry.internal/assistant | finding | C5 | — | Container | Medium | |
| CN·RG1 | Tag mutability for registry.internal/assistant | finding | C1 | — | Container | Medium | |
| CN·RG2 | Push credentials for registry.internal | not in scope | — | — | — | — | Registry configuration for registry.internal was not supplied |
| CN·RG3 | Admission-time signature verification in the beta cluster | finding | C5 | — | Container | Medium | |
| CN·RG4 | Base image source allowlisting | not in scope | — | — | — | — | The base image source is not visible without the build definition |
| CN·RG5 | Anonymous pull from registry.internal | not in scope | — | — | — | — | Registry authentication configuration was not supplied |
| CN·RT1 | hostPID, hostNetwork and hostIPC in the assistant deployments | finding | C2 | — | Container | Medium | |
| CN·RT2 | Volume mounts declared in values.yaml | no exposure | — | — | — | — | The chart declares no volumes, so no host path and no Docker socket is mounted |
| CN·RT3 | Capabilities and allowPrivilegeEscalation for the assistant pods | finding | C2 | — | Container | Medium | |
| CN·RT4 | seccomp profile and root filesystem mode for the assistant pods | finding | C2 | — | Container | Medium | |
| CN·RT5 | Resource limits for assistantSvc and assistantConnectors | finding | C4 | — | Container | Medium | |
| CN·RT6 | assistant-connectors processing attacker-influenced retrieved content | finding | AI17 | — | AI | High | |
| CN·OR1 | API server and kubelet reachability from the assistant pods | not in scope | — | — | — | — | Cluster networking beyond the Helm values file was not supplied |
| CN·OR2 | kubectl exec used by the incident runbook | no exposure | — | — | — | — | Cluster access for engineers is the platform's own control and sits outside this repository |
| CN·OR3 | RBAC rules bound to the assistant service account | no exposure | — | — | — | — | The chart creates one service account with an IRSA annotation and binds no RBAC rules; cluster RBAC was not supplied |
| CN·OR4 | automountServiceAccountToken for the assistant pods | finding | C6 | The IRSA service account token is auto-mounted into both pods | Container | Low | |
| CN·OR5 | networkPolicy.enabled false at values.yaml:22-26 | finding | C3 | Default-deny NetworkPolicy is disabled, flattening the pod network | Container | High | |
| CN·OR6 | Admission control in the beta cluster | finding | C5 | — | Container | Medium | |
| CN·OR7 | Secret sourcing for the assistant pods | no exposure | — | — | — | — | Secrets are sourced from AWS Secrets Manager through IRSA rather than from Kubernetes Secrets or ConfigMaps |
| CN·OR8 | API audit logging and runtime detection for the beta cluster | finding | RR3 | — | Recovery & Resilience | Medium | |
| Beyond the instrument | The approved Confluence architecture page against serviceIdentity.ts | finding | O1 | The approved architecture page describes delegated credentials that were never built | Cross-cutting | High | Recorded in ADR-0002 under the heading Not written back |
| Beyond the instrument | The Confluence connector added 2026-07-14 | finding | O2 | A fifth connector was added by configuration with no ticket and no documentation update | Cross-cutting | Medium | Confluence page still says four connectors |
| Beyond the instrument | promptAssembly.assemble merging retrieved chunks into the user message | finding | AI5 | Tool results are appended into the user message with no provenance boundary | AI | High | |

---

## Roll-up

| Instrument | Prompts | Findings | No exposure | Not in scope |
|---|---|---|---|---|
| STRIPED (STR·) | 57 | 51 | 5 | 1 |
| Privacy (PRV·L) | 9 | 7 | 2 | 0 |
| Dark patterns and HCS (PRV·DP, PRV·H) | 16 | 9 | 7 | 0 |
| Elevation of Autonomy (EoA·) | 30 | 28 | 1 | 1 |
| AI extension (AIX·) | 20 | 9 | 2 | 9 |
| Cumulus (CU·) | 60 | 30 | 32 | 0 |
| Container (CN·) | 25 | 15 | 4 | 6 |
| Beyond the instrument | — | 3 | — | — |
| **Total** | **217** | **152 rows resolving to 72 distinct findings** | **53** | **17** |

**Findings by bucket:** S 5 · T 4 · R 5 · I 5 · P 6 · E 6 · D 5 · O 6 · AI 17 · CL 4 · C 6 · RR 3 — 72 in total.

**Severity distribution:** Critical 5 · High 28 · Medium 35 · Low 4.

---

## Notes for phase 2

- **S3 is the hinge of the spoofing cluster.** Four prompts reach it from different directions — identifier as authorisation, no ownership check on read, resumption carrying privilege, and the workspace not being part of the key. Write it once, and make the resumption path the worked example, because that is the one that lets an action land in someone else's history.
- **I3 and E4 are one root cause with two consequences.** E4 is the credential design; I3 is what a user can therefore reach. Keep them separate — the fix for E4 is PLAT-2820, the fix for I3 is a per-user filter that is needed even after delegation lands, because retrieval currently sends no identity at all, which is E3.
- **AI6, AI8 and AI7 are the three structural hazards** and must each carry their own numbered finding with the hazard named in the heading, not a paragraph.
- **The severity of P1 is conditional** on whether Support's shared mailbox is confirmed in scope. If it is confirmed and customer special-category content is present, it moves to Critical. Footnote it in the register rather than inflating it now.
- **O1 to O5 are the doc-versus-code divergences** and the architecture map's section 6 table is their evidence base; cite it rather than restating the table.
- **The Cumulus no-exposure rows are dense** because most of the AWS baseline is platform-managed and outside this repository. Say so once in Assumptions rather than on every row.
