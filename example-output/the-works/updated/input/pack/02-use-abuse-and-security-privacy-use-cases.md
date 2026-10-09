# Internal AI Assistant — Use, Abuse and Security / Privacy Use Cases

**Version:** 1.0 (first pass; use cases and abuse cases authored before the threat model, counter-use cases after it) · **Date:** 2026-09-08
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this use and abuse case document. Produced with AI assistance using the security-review skill set authored by **Brett Crawley, Principal Application Security Engineer**.
**Model:** Claude Opus 5
**Companion documents:** `03-security-architecture.md` · `06-threat-model.md` · `05-srtm-and-test-artefacts.md`

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted.

> This document carries the attacker's side of the analysis. Use cases come from the epic's acceptance criteria and the runbooks, so they describe what the system is actually for. Every abuse case is a story of someone succeeding against the pilot as it is built, links forward to the finding in `06-threat-model.md` that carries the technical detail, and links to at least one counter-use case in section 5 or 6.

---

## 1. Actors and adversaries

| Actor | Description | Trust |
|---|---|---|
| **Pilot user** | One of 21 people in Platform or Support. Authenticated at the perimeter, uses Slack or the web console | Trusted to their own permissions, not to the assistant's |
| **Workspace admin** | Whoever edits `config/workspaces.json` and `config/workspace-tools.json` and restarts the connector service | Trusted staff, unbounded input into the system prompt |
| **Platform on-call engineer** | Runs the runbooks, uses the debug routes | Trusted, holds cluster exec |
| **Content author, internal** | Anyone who can write a Confluence page, a GitHub issue comment, a Slack message or an email that lands in a pilot user's reach | Not vetted. Includes every employee, and every contractor with a corporate account |
| **Content author, external** | Anyone who can send mail to a pilot user, open a GitHub issue on a public repository, post in a Slack Connect channel, or publish a web page the search connector returns | Hostile by default |
| **Cluster neighbour** | Any workload in the beta EKS cluster or any host in the platform VPC | Untrusted for this system's purposes, because network policy is disabled |
| **Model provider** | The hosted provider on the enterprise endpoint, and the separate pay-as-you-go account behind the fallback | Sub-processor under contract; the fallback account's terms are unknown |
| **Vendor MCP server** | Office 365, Slack, GitHub and Confluence servers supplied by vendors under D-02 | Trusted implicitly today; supplies tool descriptions into the model's context |
| **Community MCP server** | The web-search server, community-maintained, running in cluster | Not vetted, not pinned |
| **Customer** | A person whose correspondence sits in Support's shared mailbox or ticket queue | Data subject with no relationship to this system and no notice of it |

---

## 2. Use cases

### UC-01 — Ask a question answered from across the connected systems

```
UC-01: Cross-system question answering
Actor: Pilot user
Goal: Get an answer without opening four tabs
Preconditions: User authenticated at the perimeter; workspace resolves; connectors reachable
Main flow:
  1. User types a question in Slack or the web console
  2. Surface posts to POST /turns with identity headers
  3. assistant-svc resolves or creates conversation state in Redis
  4. gather() fans out to POST /search on the connector service
  5. Every connector that supports search returns bodies as authored
  6. Results are merged, capped at eight chunks, and appended to the user message
  7. The system message is base prompt plus tool guidance plus workspace custom instructions
  8. The provider is called; up to eight iterations
  9. Final text is returned and appended to conversation state
Data: Document bodies, calendar entries, mail bodies, Slack channel and DM text,
      GitHub issue and code content, Confluence pages, web results
Trust boundaries crossed: TB1, TB2, TB3, TB4, TB6, TB7, TB8, TB9
```

### UC-02 — Resume a conversation after a break

```
UC-02: Conversation resumption
Actor: Pilot user
Goal: Pick a thread back up after a meeting
Preconditions: The conversation ID is known and within its 24-hour TTL
Main flow:
  1. Surface posts to POST /turns carrying the conversation ID
  2. history.resolve() returns the stored state from Redis
  3. The turn proceeds using the stored workspace and user, not the request headers
  4. Full prior history is rendered into the user message
Data: Everything the conversation has accumulated
Trust boundaries crossed: TB2, TB4
```

### UC-03 — Send mail on the user's behalf

```
UC-03: Send mail
Actor: Pilot user, via the model
Goal: A mail goes out without the user composing it
Preconditions: send_mail enabled for the workspace, or the workspace is unconfigured
Main flow:
  1. The model emits a send_mail tool call with recipient, subject and body
  2. dispatch() logs the tool name, forwards to the connector service
  3. The connector service checks the tool is enabled for the workspace
  4. The O365 connector calls the vendor server with the shared application credential
  5. Mail is sent with send-as so it appears to come from the user
  6. The tool name is appended to the action list shown in the conversation
Data: Mail body and recipients; whatever context informed them
Trust boundaries crossed: TB3, TB6, TB10
```

### UC-04 — Post to Slack on the user's behalf

```
UC-04: Post message
Actor: Pilot user, via the model
Goal: A message appears in a channel
Preconditions: post_message enabled, or the workspace is unconfigured
Main flow:
  1. The model emits post_message with a channel and text
  2. The connector posts with the shared bot token
  3. The action name is shown in the conversation afterwards
Data: Message text, channel identity
Trust boundaries crossed: TB3, TB6, TB10
```

### UC-05 — Comment on or update a GitHub issue

```
UC-05: Issue write
Actor: Pilot user, via the model
Goal: An issue is updated without leaving the conversation
Preconditions: comment_issue or update_issue enabled
Main flow:
  1. The model emits the tool call with issue reference and body
  2. The connector calls the org-level GitHub app
  3. The change lands attributed to the app installation
Data: Issue fields and comment bodies
Trust boundaries crossed: TB3, TB6, TB10
```

### UC-06 — Commit a change to a branch

```
UC-06: Commit
Actor: Pilot user, via the model
Goal: A code change lands without the user opening an editor
Preconditions: commit enabled. Enabled for ws-platform and for any unconfigured workspace
Main flow:
  1. The model emits commit with a repository, branch, path and content
  2. The connector calls the org-level GitHub app
  3. The commit lands on the working branch directly, per PLAT-2817-3
Data: Source code, which the data-handling page classifies Confidential
Trust boundaries crossed: TB3, TB6, TB10
```

### UC-07 — Summarise a customer's history before a support call

```
UC-07: Customer history summary
Actor: Support agent
Goal: Know the customer's history before picking up the call
Preconditions: Support workspace; ticket queue and shared mailbox reachable
Main flow:
  1. Agent asks for the customer's history
  2. Retrieval fans out; mail and ticket content return as authored
  3. The model summarises, running on aurora-1-mini
  4. The agent may then ask for a reply to be drafted and sent
Data: Customer personal data, correspondence, possibly special category content
Trust boundaries crossed: TB1 to TB10
```

### UC-08 — Onboard a workspace

```
UC-08: Workspace onboarding
Actor: Platform engineer
Goal: A new group can use the assistant the same day
Preconditions: None
Main flow:
  1. Add the workspace to config/workspaces.json
  2. Add the workspace to config/workspace-tools.json
  3. Restart assistant-connectors
  4. Tell the team
Data: Workspace configuration, custom instructions, model choice
Trust boundaries crossed: TB2, TB3
```

### UC-09 — Investigate a bad assistant action

```
UC-09: Incident investigation
Actor: On-call engineer
Goal: Reconstruct what the model was working from
Preconditions: The conversation is still within its 24-hour TTL
Main flow:
  1. Get the conversation ID from the user
  2. kubectl exec into assistant-svc and curl the debug conversation route
  3. Read the full state including everything retrieved into context
  4. If a write went out, read the target system's own audit log
Data: The entire conversation, including anything retrieved into it
Trust boundaries crossed: TB2, TB4, TB12
```

### UC-10 — Rotate connector credentials

```
UC-10: Credential rotation
Actor: Platform engineer
Goal: Replace a connector credential
Preconditions: Access to Secrets Manager under the assistant path
Main flow:
  1. Rotate one secret per connector in Secrets Manager
  2. Restart assistant-connectors
Data: Application credentials for five connectors
Trust boundaries crossed: TB11
```

### UC-11 — Configure workspace instructions and model

```
UC-11: Workspace configuration
Actor: Workspace admin
Goal: Set local tone and policy, and control spend
Preconditions: Ability to edit the configuration file and restart
Main flow:
  1. Edit customInstructions, free text, no validation and no length limit
  2. Edit model, chosen freely from the supported list
  3. Restart; the instructions are appended to the system message on every turn
Data: The system prompt for every user in that workspace
Trust boundaries crossed: TB2, TB8
```

### UC-12 — See consumption by team

```
UC-12: Consumption reporting
Actor: Finance, team leads
Goal: Attribute model spend to a cost centre, per PMO-0447
Preconditions: Telemetry written to the analytics warehouse
Main flow:
  1. Each request writes timestamp, user, team, model, token counts, tool names, latency
  2. The dashboard aggregates to team level
Data: Per-user usage records retained 13 months
Trust boundaries crossed: TB2
```

---

## 3. Security abuse cases

### SAC-01 — A GitHub issue comment sends mail as an executive

*Attacker type:* External content author. *Linked findings:* AI1, AI3, AI5, E4, S4.
*Flow:* The attacker opens an issue on a repository the organisation runs, or comments on an existing one. The comment body contains an instruction addressed to an assistant rather than to a human. A Platform engineer later asks the assistant what is blocking the release. `gather()` fans out, the GitHub connector returns the comment body as authored, `renderRetrieved()` places it under a `## Supporting content` heading in the same user message as the engineer's own words, and nothing marks it as third-party text. The tool guidance in the system prompt tells the model to treat retrieved content as the answer to the question it asked. The model emits `send_mail`; `dispatch()` forwards it; the connector sends it with send-as.
*Impact:* A mail leaves the organisation appearing to come from a named employee, drafted by an attacker who never had an account. The recipient cannot tell. The engineer sees the string `send_mail` in the action list, with no recipient and no body.

### SAC-02 — A calendar invite exfiltrates a conversation

*Attacker type:* External content author. *Linked findings:* AI1, AI4, I5.
*Flow:* The attacker sends a meeting invite whose body carries text designed to be read by a model. The O365 connector's `read_calendar` tool is described as returning invite bodies. On a later turn the invite body reaches the context and induces the model to end its reply with a markdown image whose URL embeds a summary of the conversation. The web console renders assistant output as markdown. The browser fetches the image from the attacker's host.
*Impact:* Conversation content — which by then may include mail bodies, Slack DMs and source code — leaves in a URL. The cluster egress proxy does not see it, because the fetch happens in the user's browser. The pilot has already observed the behaviour and recorded it on the Confluence draft as "renders fine, looks odd. Not investigated."

### SAC-03 — A pilot user reads a colleague's direct messages

*Attacker type:* Legitimate but curious insider. *Linked findings:* I3, E4, E5, R3.
*Flow:* The Slack app was installed with the full scope set during the prototype and the narrowing task is unscheduled. The connector authenticates with a single bot token holding application permissions, and `credentialFor()` ignores the `userId` argument entirely. The user asks the assistant what a named colleague has been saying about a project. `search_messages` is described as searching channels and DMs. The results come back under one credential with no per-user filter anywhere in the path.
*Impact:* One pilot user reads another employee's private conversations, including any conversation about them. Slack's own audit log records the bot, not the person who asked.

### SAC-04 — An unconfigured workspace gets commit and send-mail on day one

*Attacker type:* Insider, or an honest mistake. *Linked findings:* E1, E2.
*Flow:* A workspace is added to `workspaces.json` during onboarding and step two of the runbook is skipped or deferred. `toolsForWorkspace()` finds no entry, logs a line, and returns every tool in the registry. `forWorkspace()` likewise returns defaults rather than refusing. The new group has `commit`, `send_mail`, `post_message`, `update_issue` and every read tool, against the organisation-wide credential set. `ws-beta` is in exactly this state deliberately.
*Impact:* A sandbox workspace has production write access to Office 365, Slack and every repository in the GitHub organisation. Nobody has to be malicious for this to hurt.

### SAC-05 — A cluster neighbour reads every live conversation

*Attacker type:* Any workload in the cluster or host in the VPC. *Linked findings:* T1, I1, S2, C3.
*Flow:* `networkPolicy.enabled` is `false` in the chart, and the chart records that the beta cluster does not have the platform's default-deny policies. The Redis security group admits the whole VPC CIDR on 6379, transit encryption is off and there is no auth token. Separately, the debug router is mounted whenever `EXPOSE_DEBUG_ROUTES` is anything other than the literal string `false`, and the chart deliberately does not set it. A compromised neighbouring pod either scans Redis directly or walks conversation IDs against `GET /internal/debug/conversations/:id`.
*Impact:* Every live conversation in the pilot, including mail bodies, Slack DMs, customer correspondence and source code, in plaintext, with no authentication and no record that it happened.

### SAC-06 — A conversation ID is used to act as its owner

*Attacker type:* Anyone who can reach the orchestrator and obtain or guess an identifier. *Linked findings:* S3, S1, E3.
*Flow:* Conversation IDs are generated by the surface, are not namespaced by workspace, and appear in the console URL — the runbook tells users to read them out of it. `turns.ts` resolves the conversation first and, when it resolves, the turn runs under the *stored* `userId` and `workspaceId`; the request's own identity headers are used only when creating a new conversation. Posting a turn with a known conversation ID therefore executes as the original user, in their workspace, with their tools.
*Impact:* Possession of an identifier is authorisation. The action lands in the victim's history and is attributed to them in the only record that exists.

### SAC-07 — A workspace admin rewrites the system prompt

*Attacker type:* Workspace admin, or anyone who can change the configuration file. *Linked findings:* T2, T4, AI15.
*Flow:* ADR-0005 places `customInstructions` in the system message so that smaller models do not ignore it. The field is free text with no validation and no length limit, and `promptAssembly.assemble()` concatenates it after the base prompt and the tool guidance. An admin — or anyone who can influence the file, including through the `WORKSPACES_PATH` environment variable — writes instructions that redirect the assistant for every user in the workspace.
*Impact:* Every turn for that workspace runs under attacker-chosen instructions, and the change is invisible to users because nothing surfaces the system prompt.

### SAC-08 — Model-authored code reaches a branch nobody reviews

*Attacker type:* External content author, chained. *Linked findings:* E6, AI17, O3.
*Flow:* The GitHub app is installed at organisation level and the `commit` tool writes directly to the working branch. The engineering comment on PLAT-2817-3 argues that branch protection bounds the blast radius, but `.github/branch-protection-exemptions.yml` exempts `platform-ci`, whose nightly jobs push tags to main, and `infra-bootstrap`, which provisions the reviewers' access. Content-driven instruction reaches the model, which commits to a repository in the exempt list.
*Impact:* A change lands in the shared CI template repository or in the repository that grants reviewer access, with no approving review, and is then consumed by every other repository in the estate.

### SAC-09 — Prompts overflow to an uncontracted endpoint at peak

*Attacker type:* Any user, and the calendar. *Linked findings:* I4, D2, D3.
*Flow:* `hostedProvider.complete()` retries against the public endpoint whenever the enterprise endpoint returns 429, using a pay-as-you-go key that predates the enterprise agreement. There is no rate limit at the front door, no per-user token budget and no spend cap, and one turn fans out to five connectors and up to eight model iterations with tool results appended cumulatively. Load at the afternoon peak is exactly when the 429 arrives.
*Impact:* The highest-volume prompts of the day — the ones most likely to carry customer correspondence — go to an endpoint with no contract, in an unpinned region, retained for 30 days. Cost is uncapped at the same time.

### SAC-10 — A community MCP server is replaced under the pilot

*Attacker type:* Upstream. *Linked findings:* AI10, AI11, O3.
*Flow:* The web-search connector is a community MCP server that runs in the cluster and calls a search API. Nothing in the supplied material pins its version, records its provenance, or reviews it on update. The CI workflow has no dependency scanning step because the template was inherited from `platform-ci`, which is exempt from the standard and so never had one to inherit, and no lockfile is committed against `npm ci`.
*Impact:* An upstream change reaches the process that holds the search API key, sits inside the network boundary, and returns content straight into the model's context.

### SAC-11 — A tool-name collision routes a call to the wrong system

*Attacker type:* Anyone who can add a connector. *Linked findings:* AI16, O2.
*Flow:* `ALL_TOOLS` flattens the tools of all five connectors into one namespace and `connectorFor()` returns the first connector whose tool list contains the name. Nothing namespaces by server and nothing detects a collision. The Confluence connector was added on 2026-07-14 as a configuration change with no ticket and no update to the architecture page, which shows how easily a sixth arrives.
*Impact:* A call intended for one system executes against another, under that system's credential, with arguments shaped for a different tool.

### SAC-12 — The sanitiser is walked around in one line

*Attacker type:* External content author. *Linked findings:* AI6, AI8.
*Flow:* `sanitiseWebContent()` strips script blocks, strips every HTML tag, then applies a two-phrase regular expression before collapsing whitespace. Because tag stripping runs first and replaces each tag with a space, `Ig<b>nore previous instructions</b>` becomes `Ig nore previous instructions`, which the word-boundary pattern no longer matches. Paraphrase, translation and encoding all reach the same behaviour without going near the two phrases at all.
*Impact:* The one control the design names as its answer to untrusted content stops the two literal strings it was written against and nothing else. Nothing observes the attempts, so there is no signal that anyone tried.

### SAC-13 — Retrieval failure produces a confident wrong answer

*Attacker type:* None required; a dependency outage will do. *Linked findings:* D5, AI14.
*Flow:* The connector service wraps each connector's search in `.catch(() => [])`, and `gather()` returns an empty array on any non-200. Nothing marks the answer as partial. The model answers from whatever came back, and the tool guidance tells it to prefer acting over describing.
*Impact:* A Support agent is told a customer has no prior complaint because the mailbox connector was down. The reply goes out under UC-03 with no confirmation step.

### SAC-14 — A long session drifts away from its own constraints

*Attacker type:* External content author, patient. *Linked findings:* AI7, D4.
*Flow:* Conversation state carries a 24-hour TTL and nothing trims it; the Confluence draft records that a conversation left open all day carries everything and gets slow. Every tool result is appended to the same growing user message. Safety-relevant text sits at the head of the system message and never repeats. An instruction planted early in the day, or content retrieved mid-session, sits close to the end of a very long context by the afternoon.
*Impact:* Behaviour late in a long session is governed by whatever is recent, which is where an attacker's content is.

---

## 4. Privacy abuse cases

### PAC-01 — Customer correspondence is read by a system nobody told the customer about

*Actor:* The system itself, in normal operation. *Linked findings:* P1, P2, P6.
*Scenario:* Support's use case is the assistant reading the ticket queue and the shared mailbox to summarise a customer's history. Customer mail bodies therefore enter the prompt, cross a sub-processor boundary and are retained by the provider for 30 days. The Confluence draft records "whether Support's shared mailbox should be in scope at all, given whose data is in it" as an unresolved question, and the portfolio has accepted that group AI governance will be retrofitted.
*Data subjects harmed:* Customers, and every third party named in their correspondence.
*Privacy by Design principle violated:* Privacy embedded into design — the processing was added and the question about it was written down afterwards.
*Regulatory exposure:* GDPR Articles 5(1)(a) and (b), 6, 13 and 14, 28, 35. A DPIA is a strong candidate and none exists.

### PAC-02 — Per-user telemetry outlives its purpose by a year

*Actor:* The platform. *Linked findings:* P3.
*Scenario:* PMO-0447 requires running cost to be attributable to a cost centre, and the dashboard aggregates to team. The telemetry table nonetheless records the individual user on every request and is retained for 13 months. What is kept is a 13-month record of which individual asked the assistant how many questions, when, and which tools ran.
*Data subjects harmed:* Every pilot user, and everyone in the groups the pilot expands to.
*Privacy by Design principle violated:* Privacy as the default, and data minimisation under Article 5(1)(c).
*Regulatory exposure:* GDPR Articles 5(1)(b) and (c), 6. Works council or employee-representation exposure where staff monitoring is in scope.

### PAC-03 — An erasure request cannot be honoured

*Actor:* The system. *Linked findings:* P4, I5, R5.
*Scenario:* A subject asks for their data to be erased. Conversation state expires on a TTL rather than being deleted on request, and `drop()` exists in `history.ts` but is not wired to any route in the supplied tree, despite PLAT-2825-2 being marked Done. Copies exist in the provider's 30-day abuse-monitoring store, in the analytics warehouse for 13 months, and in platform logs for 12 months. There is no inventory that would let anyone find a person's data across those copies, let alone remove it.
*Data subjects harmed:* Employees and customers alike.
*Privacy by Design principle violated:* Respect for user privacy, and end-to-end lifecycle protection.
*Regulatory exposure:* GDPR Articles 15, 17 and 5(1)(e).

### PAC-04 — A leaver's conversation keeps working

*Actor:* The system. *Linked findings:* P4, S3, E4.
*Scenario:* The Confluence draft asks what happens to a conversation when the person who started it leaves and does not answer. Because a turn runs under the identity stored in the conversation rather than the identity on the request, and because the connectors authenticate with an application credential rather than the person's, a resumed conversation continues to work after the account is disabled. The rotation runbook says plainly that there is no per-user credential to revoke.
*Data subjects harmed:* The leaver, and everyone whose data the conversation had already gathered.
*Privacy by Design principle violated:* Full lifecycle protection.
*Regulatory exposure:* GDPR Article 32; and Article 5(1)(f) integrity and confidentiality.

### PAC-05 — One context mixes every purpose the organisation has

*Actor:* The design. *Linked findings:* P5, I3.
*Scenario:* ADR-0004 fans retrieval out to every connector because users do not know which system holds the answer. A single question therefore assembles mail, direct messages, calendar entries, source code and Confluence pages into one prompt. Data gathered for HR correspondence and data gathered for release engineering are in the same context window, available to the same completion, with no boundary between them.
*Data subjects harmed:* Anyone whose data is in any connected system.
*Privacy by Design principle violated:* Purpose limitation, and the Separate strategy in privacy engineering.
*Regulatory exposure:* GDPR Article 5(1)(b).

### PAC-06 — The model states things about people that are not true, in writing

*Actor:* The model, amplified by the write tools. *Linked findings:* AI14, AI13.
*Scenario:* The assistant writes outward — mail, Slack posts, issue comments and commits — without a confirmation step, and the action list shown to the user is the model's own account of what it did rather than the dispatcher's record. A generated claim about a person becomes a durable record in a system that others read as authoritative. There is no mechanism for the person the claim is about to discover it, correct it, or make the correction persist.
*Data subjects harmed:* Employees and customers described in generated output.
*Privacy by Design principle violated:* Visibility and transparency; accuracy under Article 5(1)(d).
*Regulatory exposure:* GDPR Articles 5(1)(d), 16 and 22 where the output feeds a consequential decision.

### PAC-07 — Personal data leaves the contracted processor at peak

*Actor:* The fallback path. *Linked findings:* I4, I5.
*Scenario:* On a 429 the prompt is retried against a public endpoint using a key that predates the enterprise agreement. The Confluence architecture page tells the reader the provider is an EU-hosted endpoint under the existing enterprise agreement. ADR-0006 records that under peak load some prompts and completions go to an endpoint that is not covered by the enterprise data processing agreement, that volume is highest exactly when this happens, and that nobody owns reverting it.
*Data subjects harmed:* Everyone whose data was in the prompt, most often customers, because Support's peak is the afternoon.
*Privacy by Design principle violated:* End-to-end security, and proactive not reactive.
*Regulatory exposure:* GDPR Articles 28, 32 and 44 to 49.

---

## 5. Security use cases — countermeasures

Authored after the threat model, because a countermeasure counters an identified threat. Each names the control, its status, and what remains after it.

| ID | Countermeasure | Mitigates | Control | Status | Residual |
|---|---|---|---|---|---|
| SUC-01 | Verified gateway assertion | SAC-06, S1 | Signed OIDC assertion verified against the gateway JWKS; inbound identity headers deleted before the handler | 🔴 Open | The gateway itself is unreviewed; TB1 remains the weakest link while S5 stands |
| SUC-02 | Authenticate the connector service | SAC-05, S2, C3, O4 | Workload identity over mutual TLS with an authorisation policy naming only the orchestrator, plus a default-deny network policy as a second layer | 🔴 Open | Enforcement lives in the mesh; a mesh outage must fail closed |
| SUC-03 | Conversation ownership check | SAC-06, S3 | Workspace-namespaced Redis key; owner compared against the verified caller on every resume; 404 on mismatch | 🔴 Open | Shared-account use inside a workspace is still indistinguishable |
| SUC-04 | Mark assistant-originated mail | SAC-01, S4 | Message header and visible banner applied in the connector, plus a mail-flow rule for external recipients | 🔴 Open | Internal recipients may still skim past the banner |
| SUC-05 | Single sign-on with MFA on the console | SAC-06, S5 | OIDC proxy in front of the console; identity derived from a verified token | 🔵 Planned, PLAT-2831-3 | Session lifetime and device posture still to be set |
| SUC-06 | Protect conversation state | SAC-05, T1, AI9 | Transit encryption and auth token on ElastiCache; security group narrowed to the node group; per-turn HMAC verified on read | 🔴 Open | Key management for the HMAC becomes a new dependency |
| SUC-07 | Validate and freeze configuration | SAC-07, T2, T4 | Schema and length cap on custom instructions; fixed configuration paths; start-up hash logged | 🔴 Open | A compromised admin account can still change reviewed content through the repository |
| SUC-08 | Structured message transport | SAC-07, T3, AI5 | Provider-native role-tagged message array replacing the concatenated string | 🔴 Open | Provider-side handling of long structured contexts is unmeasured |
| SUC-09 | Assistant audit event | SAC-01, SAC-13, R1, R2, R4, R5 | Structured event per write with acting user, tool, full target, trace identifier and outcome, shipped to the platform sink | 🔴 Open | Retention of the event is the platform's, not the team's, to guarantee |
| SUC-10 | On-behalf-of markers downstream | SAC-03, R3 | Commit trailers, Slack username and message headers naming the requesting person | 🔴 Open | A marker is not delegation; only PLAT-2820 makes downstream audit authoritative |
| SUC-11 | Authorised support route | SAC-05, I1, I2, O5 | Debug flag default closed; a support route requiring an on-call group claim and writing an audit event; explicit field allowlist on configuration | 🔴 Open | Break-glass access remains powerful and must be reviewed periodically |
| SUC-12 | Delegated credentials and retrieval filter | SAC-03, I3, E3, E4, CL2 | Per-user delegated OAuth with a credential store; `userId` required on search and invoke; per-user authorisation evaluated at the connector | 🔵 Planned, PLAT-2820 | Blocked on Identity Platform; the retrieval filter can and should land first |
| SUC-13 | Remove the provider fallback | SAC-09, I4 | Fail the turn with a retryable error rather than switching processor; client-side queue and per-workspace concurrency while quota is chased | 🟡 revert agreed in ADR-0006, unowned | Availability during peak degrades until the quota increase lands |
| SUC-14 | Fail-closed workspace defaults | SAC-04, E1, E2, CL3 | Unknown workspace grants no tools and fails the turn; a read-only onboarding template preserves same-day setup | 🔴 Open | Onboarding friction returns unless the template is genuinely one step |
| SUC-15 | Narrow the Slack scopes | SAC-03, E5 | Reinstall without direct-message history scopes; split channel and DM search into separately grantable tools | 🔵 Planned, PLAT-2814-6 | Reinstall is disruptive and needs an IT change window |
| SUC-16 | Commit through a pull request | SAC-08, E6, AI17 | Installation scoped to named repositories excluding the exempt ones; the tool creates a branch and opens a pull request | 🔴 Open | The three branch-protection exemptions remain an estate-level risk under PLAT-1188 |
| SUC-17 | Enforced rate and spend limits | SAC-09, D1, D2, D3, C4 | Token-bucket limiter per user and workspace; hard token budget checked before the provider call; bounded connector concurrency; pod resource limits | 🔵 Planned in part, PLAT-2822-4 | A hard cap will occasionally refuse legitimate work; the threshold needs tuning |
| SUC-18 | Windowed context with re-anchoring | SAC-14, D4, AI7 | Last-N turns verbatim plus a rolling summary, a token ceiling, and the instruction block re-injected immediately before the question | 🔴 Open | Summarisation loses detail, which is the property ADR-0004 was protecting |
| SUC-19 | Visible degradation | SAC-13, D5 | Connector failures logged and returned as a degraded-source list rendered as a fixed banner; writes fail closed when a depended-on source was unavailable | 🔴 Open | Users may learn to ignore a banner that appears often |
| SUC-20 | Documentation drift gate | SAC-01, O1, O2 | Divergence table on the architecture page; pilot expansion blocked while an ADR marked not-written-back is open; ticket and review fields required per connector | 🔴 Open | A process control, so it decays unless the registry check enforces it |
| SUC-21 | Supply chain scanning and pinning | SAC-10, O3, AI10, C5 | Committed lockfile; audit and SBOM steps blocking on critical findings; connector pinned by digest; AI bill of materials compared at start-up | 🔴 Open | The root cause is the exempt CI template, which is PLAT-1188's problem |
| SUC-22 | Retrieval provenance | SAC-01, AI1, AI5 | Chunks and tool results carried as typed blocks with source and trust level, never concatenated into the user turn | 🔴 Open | Provenance informs the model; it does not constrain it — SUC-24 carries the guarantee |
| SUC-23 | Tool argument schemas | SAC-01, AI2 | Per-tool schema evaluated at invoke, with recipient domains, channels, repositories, branches and paths allowlisted from workspace configuration | 🔴 Open | Allowlists need maintenance as legitimate use widens |
| SUC-24 | Confirmation gate on irreversible tools | SAC-01, SAC-04, PAC-06, AI1, AI3 | Reversibility flag per tool; a single-use confirmation token minted by the surface after a human click, bound to the conversation and the argument hash, verified at invoke | 🔴 Open | Reversible writes remain unconfirmed by design, which is the accepted trade |
| SUC-25 | Output filter and content security policy | SAC-02, AI4 | Markdown subset with image and autolink extensions disabled; `img-src` and `connect-src` restricted to internal origins; same stripping on outbound mail and posts | 🔴 Open | Legitimate images in answers are lost; an internal image proxy would restore them |
| SUC-26 | Fix and instrument the content check | SAC-12, AI6, AI8 | Phrase match moved ahead of tag stripping; flags emitted as audit events; detection rule on repeated flags in one conversation | 🔴 Open | The denylist remains a signal, never a boundary; SUC-24 carries the guarantee |
| SUC-27 | Pin and namespace tool definitions | SAC-10, SAC-11, AI11, AI16 | Approved description and schema hashed at review and verified at refresh; tool identifiers namespaced by connector; duplicates fail at start-up | 🔴 Open | Vendor updates will break the hash by design, so a review path is needed |
| SUC-28 | Model selection bound to workspace risk | AI12 | Selectable models derived from workspace classification and tool grant; `selectModel` fails closed outside that set | ⚪ Accepted today under ADR-0007 | Cost control narrows, which is the trade PLAT-2822 must accept |
| SUC-29 | Dispatcher-record action list | SAC-01, PAC-06, AI13 | Action list built in dispatch with tool, target, preview and result link; shown before the action for irreversible tools | 🔴 Open | More detail on screen only helps if the surface presents it legibly |
| SUC-30 | Mark generated content | PAC-06, AI14 | Machine-readable marker on every written artefact; marked chunks excluded from retrieval unless explicitly requested | 🔴 Open | Markers can be stripped by a human editing the artefact afterwards |
| SUC-31 | Business rules from a policy source | SAC-07, AI15 | Refund window and similar rules served as retrieved data with provenance; outbound drafts validated against the authoritative value | 🔴 Open | Only rules that are modelled get validated |
| SUC-32 | Split the IAM roles | SAC-05, CL1 | One role per service, resources named explicitly rather than by wildcard, separate service accounts | 🔴 Open | Splitting is a Terraform change with a brief credential-rotation window |
| SUC-33 | Reconcile required egress | SAC-02, SAC-09, CL4 | Required destinations recorded in the repository and reconciled against the proxy allowlist at expansion | 🔴 Open | The allowlist is host-level, so a shared API host stays broad |
| SUC-34 | Sign and pin the image | SAC-10, C1, C5 | Digest reference in the chart, signature at build, admission-time verification of signature and SBOM attestation | 🔴 Open | Needs a policy controller the beta cluster may not run |
| SUC-35 | Pod hardening | SAC-05, C2, C6 | Restricted security context on both deployments, namespace enforcement label, service account token automount disabled | 🔴 Open | A read-only root filesystem needs writable temporary volumes declared |
| SUC-36 | Graded kill switch and response plan | SAC-01, SAC-13, RR1, RR3 | Global, per-workspace and per-tool write-disable flags read at dispatch, changeable without deployment, with a named owner and an assistant-specific runbook | 🔴 Open | A flag store is another dependency the dispatch path must fail closed on |
| SUC-37 | Backup and restore drill | SAC-05, RR2 | Versioned, object-locked Terraform state; configuration held in the repository; quarterly restore into an isolated account | 🔴 Open | Conversation state remains deliberately unbacked, which is the right trade |

## 6. Privacy use cases — privacy controls

| ID | Privacy control | Mitigates | Control | PbD principle | Status | GDPR |
|---|---|---|---|---|---|---|
| PUC-01 | Lawful basis and impact assessment | PAC-01, P1, O6 | Article 35 assessment for large-scale correspondence processing; lawful basis recorded per data category; `read_mail` removed from the Support workspace until both exist | Proactive not reactive | 🔴 Open | Art. 6, Art. 35 |
| PUC-02 | Third-party position and retrieval minimisation | PAC-01, P2 | Article 14 position agreed and published; connectors return subject, participants and a bounded snippet rather than whole bodies | Privacy embedded into design | 🔴 Open | Art. 14, Art. 5(1)(c) |
| PUC-03 | Processor retention on the record | PAC-03, PAC-07, I4, I5 | Provider added to the sub-processor register with actual retention, region and erasure route; the retention constant read from that register; the fallback path removed | End-to-end security | 🔴 Open | Art. 28, Art. 44 to 49 |
| PUC-04 | Telemetry pseudonymisation | PAC-02, P3 | Daily salted pseudonym replacing the user identifier; team retained for cost attribution; identified staging table expiring at 90 days | Privacy as the default | 🔴 Open | Art. 5(1)(c) |
| PUC-05 | Executable erasure | PAC-03, PAC-04, P4 | Authenticated delete route calling `history.drop`; leaver hook; per-subject locator across the four stores; deletion path recorded per store | Full lifecycle protection | 🔴 Open | Art. 17 |
| PUC-06 | Purpose-scoped retrieval | PAC-05, P5 | Per-workspace connector allowlist; chunks classified at retrieval and excluded where the workspace has no purpose for them | Purpose limitation | 🔴 Open | Art. 5(1)(b) |
| PUC-07 | Transparency and intervenability | PAC-01, PAC-06, P6, AI13, AI14 | Internal notice before expansion; in-product notice on first use; subject access extended to assistant activity, indexed by data subject; generated content marked and correctable | Visibility and transparency | 🔴 Open | Art. 13, Art. 16 |

Every abuse case in sections 3 and 4 now has at least one counter-use case, and every counter-use case names the threat-model finding it answers. Where the status is Planned or Accepted, the residual column says what is being carried knowingly.

---
