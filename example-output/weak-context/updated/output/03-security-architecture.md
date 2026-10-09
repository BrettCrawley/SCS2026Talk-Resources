# Internal AI Assistant (PLAT-2810) — Security Architecture

**Version:** 1.1 (validation-session merge) · **Date:** 2026-09-09
**Supersedes:** version 1.0 of 2026-09-09, the pre-session pack. Delta at §0.
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** — author of this security architecture document; produced with AI assistance.
**Model:** Claude Opus 5
**Validated:** validation session of 2026-09-09, 14:00 to 15:35, facilitated by Brett Crawley, with Dana Whitfield, Marcus Oyelaran, Priya Raghunathan, Tom Egerton, Ines Ferreira and Kwame Osei. Log at `06-threat-model.md` Appendix G.
**Frameworks:** C4 · STRIDE/STRIPED · LINDDUN · OWASP Top 10 (2021) · OWASP LLM and Agentic Top 10 · Privacy by Design · Hoepman privacy strategies
**Regulatory scope:** UK GDPR and EU GDPR (employee and third-party personal data); EU AI Act (limited-risk transparency, conditional on EU deployment); **NIS2 (applies contractually rather than directly — entity classification settled, obligations pushed down by two in-scope customers)**; CRA (assessed, out of scope); PSTI (assessed, out of scope); **SOC 2 Type II (held)**; **ISO 27001 (not held, not being pursued)**
**Companion documents:** `00-context-sources-and-open-questions.md` · `02-use-abuse-and-security-privacy-use-cases.md` · `04-gap-analysis.md` · `05-srtm-and-test-artefacts.md` · `06-threat-model.md`
**Method:** Architecture reconstructed from PLAT-2810, PLAT-2814, PLAT-2817, PLAT-2822 and PLAT-2825 acceptance criteria and from `diagram1-assumed.svg`, then re-drawn with trust boundaries placed where the data's authorship actually changes rather than where the network does. Version 1.1 merges the validation-session transcript.

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted. Severities: Critical / High / Medium / Low / Info.

**Session provenance.** Claims from the validation session are tagged **`[session 2026-09-09]`**, with the speaker named where they assert a fact about the running system. Contradictions of version 1.0 are marked **`[contradicts v1.0]`**.

> **This document was authored in two passes, deliberately.** Sections 1 to 6 are the *map*: what the design says exists, drawn honestly, written before the threat model so the threat model has components and boundaries to iterate over. Sections 7 to 10 are the *evaluation*: what to build instead, written after the threat model so the judgement is informed by the findings. The map does not judge; the evaluation does.

---

## 0. What changed from the previous pass

| Version 1.0 position | What the validation session established | Verdict |
|---|---|---|
| `diagram1-assumed.svg` is *"the supplied trust model"* | **Disputed by its author, and the dispute is upheld.** It was drawn in about four minutes for a stand-up, titled *"What most engineers assume"* as an invitation to argue. Nobody argued, it went onto the architecture page, and it has been the picture for four months `[session 2026-09-09 · Marcus Oyelaran]` | **Framing corrected. The finding stands** — a sketch that became a trust model by neglect is a different failure and arguably a worse one, because nothing noticed the promotion. **O1** unchanged, High |
| The six components the sketch omits | **All six confirmed against the list** — web console, conversation store, metering store, tier router, MCP client, provider `[session 2026-09-09 · Marcus Oyelaran]` | **Confirmed.** Redraw owned: Marcus Oyelaran, 2026-09-19, and `diagram1-assumed.svg` is retired from the architecture page |
| §8: PLAT-2814's trusted-internal-sources position is a decision to **reverse** | It is not a decision to reverse, because **it was never made.** A product scoping note, an ADR citing it, an architecture page citing the ADR, and an assumed platform sanitiser that is not in the path `[session 2026-09-09]` | **§8 row rewritten; net-new finding O5.** The remediation is an owner and a written decision, not only a reversal |
| §7.2's tool class list | Read as *"every action must be confirmed"* by a reader who stopped at the headline `[session 2026-09-09 · Dana Whitfield]`. **The class list is correct and was not the problem; its placement was.** It moves into the executive summary of `01-security-review.md` | **Unchanged, restated. One line reopened:** whether *org-visible write* belongs in the gated set, since posting to a channel is most of what Support does. Pilot numbers due 2026-09-16 |
| TB5, no control on the reasoning loop to write-capable tools | Confirmed, and the commit half is cheaper to gate than anyone assumed: eleven commits since July, nine of them the engineer testing `[session 2026-09-09 · Priya Raghunathan]` | **Confirmed.** ARCH-2 unchanged; the gate is close to free |
| Assumption (e), retrieval is live query, flagged as a guess | Correct for the running build and explicitly **not** settled for the target design once the six-second number is chased `[session 2026-09-09 · Priya Raghunathan]` | **Confirmed for today, open for the target.** AI13 stays tagged |
| ARCH-3 will narrow what the assistant can reach | True in general and **false for the Support mailbox** `[session 2026-09-09 · Tom Egerton]`: it is a shared mailbox, all seven of the team may read all of it, so per-user entitlement narrows nothing there | **ARCH-3 qualified in §7.3.** The privacy exposure is carried at **P2**, not reduced by the credential model |
| §6, the control architecture as designed, drawn against no inherited baseline | **A platform baseline exists** — deny-by-default egress proxy, org-wide branch protection, a controls page — and was not supplied. Two of its controls were examined and neither closed the finding it was offered against `[session 2026-09-09]` | **§6 annotated; net-new finding O6.** Nothing is credited to the baseline until it is mapped |
| NIS2 conditional; SOC 2 and ISO 27001 as one row | NIS2 applies contractually; SOC 2 Type II is held; ISO 27001 is not held and is not being pursued `[session 2026-09-09 · Ines Ferreira]` | **Regulatory scope line corrected** |

---

## 1. Architectural context and constraints

**What is being built.** An agentic LLM assistant for internal staff, reachable from Slack and from a web console. It answers questions in natural language by retrieving content from Office 365 documents and calendar, corporate email, Slack, GitHub issues, pull requests and code, and public web search; and it *acts* — sending email, posting to Slack, commenting on and updating GitHub issues, and committing code. It runs a reasoning loop over MCP tool connections. Cost is controlled by routing each task to the smallest acceptable model, with cheaper tiers configurable per workspace. It is piloting with the Platform and Support teams and is intended to open up to the whole organisation.

**The constraints the design has committed to, and what each one costs.**

| Constraint | Ticket | Architectural consequence |
|---|---|---|
| Response under 6 seconds for a typical question | PLAT-2810 | A hard latency budget that any synchronous security control must fit inside. It is the stated reason a confirmation step was rejected, so it is load-bearing on the system's whole risk posture, not a performance detail. |
| No separate confirmation step on actions | PLAT-2817 | Removes the one control that is reliable regardless of whether the model is behaving. Every irreversible action is reachable from a single reasoning step. |
| Internal sources are trusted because they are behind authentication | PLAT-2814 | Fixes the trust boundary at the network and identity layer rather than at the authorship layer. This is the central architectural error and §3 re-draws around it. |
| Cheapest acceptable model per task; cheaper tiers per workspace | PLAT-2822 | Makes model capability a per-workspace, cost-driven variable. Whatever robustness the model contributes is therefore not a constant of the architecture. |
| Actions shown in the conversation; user reviews own history | PLAT-2825 | Places the audit record in the user-facing channel and scopes it to the actor. There is no described record a defender or an investigator can read. |
| Available in Slack and in the web console | PLAT-2810 | Two entry points with different identity substrates and different rendering engines. Both must be modelled. |

**Assumptions carried, each flagged so the team can correct it in one line.** (a) The model is a hosted third-party inference service, because PLAT-2822 meters tokens and offers tiers, which is the shape of a metered vendor API; (b) MCP servers are separate processes reached over a transport, per the diagram's labelling of each connector as "(MCP)"; (c) there is a persistent conversation and history store, because PLAT-2825 requires history review; (d) the assistant runs as a hosted service inside the corporate estate rather than on each user's device; (e) no retrieval index or vector store has been decided on yet, and retrieval is live query against each connector. Assumptions (a) to (d) follow from the tickets. Assumption (e) was a guess, flagged as such, and it is why finding AI13 is tagged "if present".

**Assumption status after the validation session — the team did correct them, and one line each was enough** `[session 2026-09-09]`**.** (a) Confirmed indirectly and uncomfortably: hosted third-party, endpoint and billing account known to one engineer, **and no contract that anyone has seen, including the Data Protection Officer who would have signed it** (**I6**). (b) Confirmed and extended: five servers, **all resolving to `latest` on every restart**, one of them a community server, nothing gating a sixth (**AI3**). (c) Not reached. (d) Not directly confirmed. What was established is that a cluster exists with a deny-by-default egress proxy in front of it, and that **neither renderer path runs inside it** — the console renders in the user's browser and Slack unfurls on Slack's own infrastructure (**AI25**). (e) **Confirmed for the running build and explicitly left open for the target design** `[session 2026-09-09 · Priya Raghunathan]`: retrieval is live query today, and whether it stays live query when the six-second number is chased is a separate question that should not be recorded as settled. **AI13 stays tagged**, and retires on a design decision rather than on an observation of the current build.

**What is deliberately not asserted here.** There is no deployment topology, no cloud provider, no cluster, no network design, no CI definition and no schema in the input, so this document does not invent one. Where a section would require them, it says so. **The validation session did not change that** — it produced testimony about those artefacts, not the artefacts. Seven were named in the room and remain unread; they are listed in `00-context-sources-and-open-questions.md` §1.

**One thing this document asserts in the present tense that it has no evidence for, and it is worth flagging here rather than only at §7.3** `[session 2026-09-09]`**.** §7.3 and the trust-boundary table describe per-user delegated credentials as the design. Three people in the session stated that this is what the system does; nobody read the configuration; and the engineer who built it declined to confirm it from memory. **Until the app registration and granted scopes are produced (2026-09-10), that is an intent and not a fact**, and findings I2, E1, E2, E4, R3 and AI8 are rated accordingly.

---

## 2. System context (C4 level 1) with trust zones

```mermaid
flowchart TB
    subgraph PEOPLE ["People - Trust Zone: AUTHENTICATED STAFF"]
        U["Staff user in Platform or Support pilot"]
        ADM["Workspace administrator"]
    end

    subgraph EDGE ["Entry points - Trust Zone: CORPORATE APPLICATION"]
        SL["Slack app surface"]
        WC["Web console"]
    end

    subgraph CORE ["Assistant - Trust Zone: CORPORATE APPLICATION"]
        ORCH["Reasoning loop and orchestrator"]
        ROUTER["Model tier router - PLAT-2822"]
        MCPC["MCP client"]
        CONV[("Conversation and history store")]:::data
        METER[("Per-team token usage store")]:::data
    end

    subgraph VENDOR ["Model provider - Trust Zone: THIRD PARTY PROCESSOR"]
        LLM["Hosted inference API"]
    end

    subgraph CONN ["MCP servers - Trust Zone: MIXED, SEE TB4"]
        O365["Office 365 server - documents and calendar"]
        MAIL["Email server - read and send"]
        SLK["Slack server - read and post"]
        GH["GitHub server - issues, PRs, code, commit"]
        WEB["Web search server"]
    end

    subgraph SOR ["Systems of record - Trust Zone: CORPORATE DATA"]
        O365D[("Documents and calendar")]:::data
        MAILD[("Mailboxes")]:::data
        SLKD[("Slack workspaces and channels")]:::data
        GHD[("Repositories and issue tracker")]:::data
    end

    subgraph EXT ["Outside - Trust Zone: UNTRUSTED"]
        NET["Public internet and web search index"]
        EXTP["External correspondents, customers, contractors, anonymous issue authors"]
    end

    U -->|"TB1: prompt"| SL
    U -->|"TB1: prompt"| WC
    ADM -->|"TB7: tier and connector configuration"| ROUTER
    SL --> ORCH
    WC --> ORCH
    ORCH --> ROUTER
    ROUTER -->|"TB2: prompt plus assembled context leaves the estate"| LLM
    LLM -->|"TB2: completion and tool calls return"| ROUTER
    ORCH --> MCPC
    ORCH --> CONV
    ROUTER --> METER
    MCPC -->|"TB3 and TB5"| O365
    MCPC -->|"TB3 and TB5"| MAIL
    MCPC -->|"TB3 and TB5"| SLK
    MCPC -->|"TB3 and TB5"| GH
    MCPC -->|"TB3 and TB8"| WEB
    O365 --> O365D
    MAIL --> MAILD
    SLK --> SLKD
    GH --> GHD
    WEB -->|"TB8: egress with attacker-choosable destination"| NET
    EXTP -->|"TB4: writes content that the connectors later read as trusted"| MAILD
    EXTP -->|"TB4: writes content that the connectors later read as trusted"| GHD
    EXTP -->|"TB4: writes content that the connectors later read as trusted"| SLKD
    EXTP -->|"TB4: writes content that the connectors later read as trusted"| O365D

    classDef data fill:#fff2cc,stroke:#7f6000
```

**Read the diagram against the one in the input.** The supplied sketch has four nodes inside a dashed "Corporate trust zone" and one untrusted edge. This one has the same connectors, plus the six components the epic requires but the sketch omits — web console, conversation store, usage metering, model router, MCP client and the model provider itself — and it adds the actor the sketch has no node for at all: **the external party who authors the content those connectors read**. That actor is the reason TB4 exists and is the difference between the two models.

**How the sketch came to be the trust model, which matters for how it is replaced** `[session 2026-09-09 · Marcus Oyelaran]`**.** Its author drew it in about four minutes for a stand-up. The title — *"What most engineers assume"* — and the subtitle — *"a tidy boundary at every connection; the internet is the only untrusted zone"* — were the joke: he drew what people assume so the team could argue about it. **Nobody argued, it went onto the architecture page, and it has been the picture for four months.** All six missing components were checked against the list in the session and all six confirmed; the author named the model provider as the omission that bothers him most, and the Data Protection Officer noted that it bothers her considerably more. **Version 1.0 called it "the supplied trust model" and that phrasing is withdrawn**: it is a sketch that became a trust model by neglect, which is a different failure from a trust model drawn wrongly, and a worse one — nothing in the process noticed the promotion. **Finding O1 stands unchanged at High**, because a document with no node for the model provider is not made adequate by having been drawn quickly. The redraw and the retirement of `diagram1-assumed.svg` from the architecture page are owned by the same person who drew it: Marcus Oyelaran, 2026-09-19, deliberately the same owner and date as the content-trust ADR in **O5**.

---

## 3. Trust boundaries

Eight boundaries. TB4 is the one the supplied design does not have, and it carries most of the risk.

| ID | Boundary | What crosses | Control at the crossing, as designed | Confidence | Evidence / open question |
|----|----------|--------------|--------------------------------------|-----------|--------------------------|
| **TB1** | Person to assistant, at the Slack app and at the web console | The user's prompt; the user's asserted identity | Not stated. Two different identity substrates with no named single authority. | **Low** | PLAT-2810 acceptance criterion; Q1, Q2 in `00-context` §5.1. Finding S2. |
| **TB2** | Assistant to hosted model provider | Prompt, system prompt, tool definitions, and every retrieved excerpt assembled as context — the richest cross-system extract the organisation produces | Not stated. No contract, region, retention or training-use commitment in the input. | **Low** | Inferred from PLAT-2822 metering and tiering; Q6. Findings I6, P1, P3. |
| **TB3** | MCP client to each of five MCP servers | Tool definitions and descriptions inbound; tool arguments outbound; tool results inbound | Not stated. No pinning, signing, namespacing or per-server sandbox described. | **Low** | `diagram1-assumed.svg` labels each connector "(MCP)"; Q13. Findings AI3, AI4, AI15. |
| **TB4** | **Authorship boundary inside each connector** — between the party that may *read* a store and the party that may *write* its content | Attacker-authored text arriving as an email body, a GitHub issue or pull-request body, a Slack message from a guest or an integration, or a shared document or calendar invitation. **Named instances confirmed in the session** `[session 2026-09-09 · Tom Egerton, Priya Raghunathan]`**: the shared Support mailbox — one address the whole team works out of, connected as a shared mailbox, and the single connector the pilot most wants, in which every message is authored by a customer or a stranger; and three Slack Connect channels shared with two enterprise accounts whose staff type into them daily.** | **None. The design asserts this boundary does not exist**, in the PLAT-2814 acceptance criterion that internal sources need no untrusted-content handling — **and no owner ever made that assertion as a decision (O5)** `[session 2026-09-09]`. | **None — the control is absent by design, and absent by nobody's decision** | PLAT-2814 acceptance criterion, quoted in `00-context` §1.1; validation session of 2026-09-09. Findings O1, AI1, **O5**. |
| **TB5** | Reasoning loop to write-capable tools | Send email, post to Slack, comment on and update GitHub issues, commit code | **None. PLAT-2817 removes the confirmation step explicitly.** No allow-list of arguments, no separation of routine from irreversible, no per-action authorisation described. | **None — the control is absent by design** | PLAT-2817 acceptance criterion. Findings AI2, AI7, AI21, E5. |
| **TB6** | Between MCP servers, through the shared model context | Content retrieved by one server becoming an argument to another server's tool | Not stated. One MCP client is connected to five servers concurrently with no described data-flow policy between them. | **Low** | Inferred from the single-client, five-server topology in the diagram. Finding AI11. |
| **TB7** | Workspace to workspace, and pilot group to general population | Model tier configuration, connector enablement, and any content co-mingled across workspaces | Not stated. PLAT-2822 makes tier configurable per workspace; PLAT-2810 says "pilot then open up" with no gate described. | **Low** | PLAT-2822 and PLAT-2810 acceptance criteria; Q15, Q20. Findings E3, E4, O3. |
| **TB8** | Assistant to public internet, through the web search server | Search queries outbound; page content inbound; any URL the model chooses to fetch | Partial. PLAT-2814 says web content is "treated as untrusted and cleaned" but does not define what cleaning is, what performs it, or what it removes. No egress allow-list is described. | **Low** | PLAT-2814 acceptance criterion; Q14. Findings I3, AI1, AI25. |

**The load-bearing observation.** The supplied model draws its boundaries where the *network* changes. The data does not respect that. An email body crosses from an anonymous author on the internet into an authenticated corporate mailbox without ever crossing a network boundary the design can see, and arrives in the model's context wearing the mailbox's trust rating rather than its author's. TB4 is where that laundering happens, and it is the boundary the whole design is missing.

---

## 4. Component decomposition

Each component is reconstructed from an acceptance criterion. None is described in any design document, because none was supplied.

### 4.1 Entry surfaces

**Slack app surface** — *Responsibility:* accept prompts in Slack and render responses. *Interfaces:* Slack events and interactivity; renders Slack markdown including images and links. *Security boundary:* TB1. *Credentials needed:* a Slack app token and the identity mapping from Slack user to corporate user. *Failure mode:* unspecified; a failed identity mapping must fail closed, and nothing says it does.

**Web console** — *Responsibility:* the same, in a browser. *Interfaces:* HTTP; renders model output, presumably as markdown or HTML. *Security boundary:* TB1. *Failure mode:* unspecified. *Note:* absent from the supplied diagram entirely, though PLAT-2810 makes it an acceptance criterion.

### 4.2 Assistant core

**Reasoning loop and orchestrator** — *Responsibility:* assemble context, call the model, execute the tool calls the model emits, iterate until the task is done. *Data owned:* the working context for a turn. *Security boundary:* sits astride TB2, TB3, TB5 and TB6 simultaneously; it is the confluence point and therefore the highest-value component in the system. *Failure mode:* no bound on iterations, retries or fan-out is described.

**Model tier router (PLAT-2822)** — *Responsibility:* choose the smallest acceptable model for the task, honouring the workspace's configured tier. *Data owned:* tier configuration per workspace. *Security boundary:* TB2, TB7. *Note:* this component makes the model that processes a given prompt a function of the workspace's budget.

**MCP client** — *Responsibility:* maintain connections to five MCP servers, present their tool definitions to the model, dispatch tool calls. *Security boundary:* TB3, TB6. *Note:* a single client connected to five servers means five sets of tool descriptions arrive in one context and five sets of returned data are available to be passed as arguments to each other.

**Conversation and history store** — *Responsibility:* persist conversations and the action record PLAT-2825 requires. *Data owned:* the highest-concentration cross-system data set in the organisation; see §5. *Security boundary:* TB1 on read, TB7 on tenancy. *Retention:* not stated anywhere.

**Per-team token usage store (PLAT-2822)** — *Responsibility:* meter consumption per team and expose it to teams. *Data owned:* per-team, and by implication per-user, usage records. *Privacy note:* per-person interaction volume with an assistant that reaches email and calendar is employee-monitoring data whether or not it was intended as such.

### 4.3 Connectors

Five MCP servers: Office 365 (documents and calendar), Email (read and send), Slack (read and post), GitHub (issues, pull requests, code, commit) and Web search. Each is a distinct trust proposition and the design treats four of them as one. Their provenance, versions, transport, authentication and sandboxing are all unstated — question Q13.

**The read and write split matters and the design does not make it.** Four of the five connectors are both readers and writers. The GitHub connector reads code and *commits* code. The Email connector reads mailboxes and *sends* mail. That is a single component holding both halves of an exfiltration primitive.

---

## 5. Data model and data classification

No schema was supplied. This model is derived from what the acceptance criteria necessarily imply, and every classification is inferred rather than read from a column list. Findings that rest on it are tagged "if present" in the threat model.

```mermaid
erDiagram
    USER ||--o{ CONVERSATION : starts
    USER ||--o{ USAGE_RECORD : generates
    CONVERSATION ||--o{ TURN : contains
    TURN ||--o{ RETRIEVED_CHUNK : assembled_from
    TURN ||--o{ TOOL_CALL : emits
    WORKSPACE ||--o{ CONVERSATION : scopes
    WORKSPACE ||--o{ TIER_CONFIG : configures

    USER {
        uuid id PK
        string corporate_identity "PII - binding to IdP unspecified, see Q2"
        string slack_user_id "PII - second identity substrate, TB1"
        string team "PII in combination - used for metering"
    }
    WORKSPACE {
        uuid id PK
        string name
        string pilot_group "Platform or Support - expands to all staff"
    }
    TIER_CONFIG {
        uuid workspace_id FK
        string model_tier "security-relevant configuration, editable at runtime, no floor stated"
    }
    CONVERSATION {
        uuid id PK
        uuid user_id FK
        uuid workspace_id FK
        timestamp started_at
        string visibility "history readable by owner per PLAT-2825, cross-user check unspecified"
    }
    TURN {
        uuid id PK
        uuid conversation_id FK
        text user_prompt "may contain PII and special category data"
        text model_output "generated claims about real people are personal data"
        int tokens_in "metered per PLAT-2822"
        int tokens_out "metered per PLAT-2822"
    }
    RETRIEVED_CHUNK {
        uuid id PK
        uuid turn_id FK
        string source_connector "which of the five servers"
        text content "email bodies, documents, calendar entries, issue text, web pages"
        string author_provenance "NOT IN THE DESIGN - this column is the gap, see AI1"
        string classification "NOT IN THE DESIGN - no labelling described"
    }
    TOOL_CALL {
        uuid id PK
        uuid turn_id FK
        string tool_name "send_email, post_slack, commit, update_issue"
        text arguments "model-generated, not allow-listed, see AI2"
        string outcome "shown in conversation per PLAT-2825, not written to a defender-readable store"
    }
    USAGE_RECORD {
        uuid id PK
        uuid user_id FK
        string team "per-team aggregation is the stated requirement"
        int tokens "per-person interaction volume is employee monitoring data"
        timestamp window
    }
```

**Two attributes in that model do not exist in the design, and both are marked.** `RETRIEVED_CHUNK.author_provenance` and `RETRIEVED_CHUNK.classification` are drawn because their absence is the finding. Content arrives in the context with no record of who wrote it and no sensitivity label, which is precisely why an email body from an anonymous sender is indistinguishable, at the point the model reads it, from a document written by the CTO.

### 5.1 Per-store classification, protection and retention

| Store | Where it lives | Classification | Protection at rest | Retention | Deletion path |
|---|---|---|---|---|---|
| Conversation and history store | Corporate estate, location unstated | **Confidential.** Personal data of staff and of third parties; special-category data reachable via calendar, email and HR documents | **Unstated — no encryption requirement exists in any ticket** | **None stated** | **None — G-12, finding P3** |
| Retrieved-chunk content within conversations | Same store | Inherits the classification of the *most sensitive* source it drew from, per turn | **Unstated** | **None stated** | **None — P3, P4** |
| Per-team token usage store | Corporate estate | Internal; personal data by aggregation; employee-monitoring risk | **Unstated** | **None stated** | **None — P6** |
| Model provider context and provider-side logs | **Third country, unknown** | Whatever the turn assembled — potentially the organisation's most sensitive content | **Unknown — no DPA or contract in the input** | **Unknown** | **Unknown — I6, P1, P7** |
| Retrieval index or vector store | Existence unknown | Would inherit every source's classification in one co-mingled corpus | Unknown | Unknown | Unknown — AI13, tagged "if present" |
| Systems of record: mailboxes, documents, Slack, repositories | Existing corporate systems | Pre-existing classification, unchanged by this project | Existing controls | Existing | Existing — the assistant does not change these, but it does create a second copy of their content in the conversation store, which has none of their controls |

**The structural point in that table.** The conversation store becomes a shadow copy of selected content from every system of record, assembled by relevance rather than by permission, with none of the source systems' retention rules, deletion paths or access controls carried across. A subject access request against the assistant is answerable only if this store is enumerable per person, and nothing in the design says it is.

---

## 6. Control architecture as designed

> **Correction, version 1.1** `[contradicts v1.0]` `[session 2026-09-09 · Kwame Osei]`**.** This section was written against no inherited platform baseline, because none was supplied. **One exists** — a deny-by-default egress proxy that everything leaving the cluster routes through, org-wide branch protection, and a standing controls page covering transport, secret handling and log retention. It was not supplied to the review, which is a different problem from its not existing, and the architecture below was drawn on the wrong one of those two.
>
> **It still changes nothing here, and the reason is finding O6 rather than a judgement about the baseline.** Two of its controls were traced to two findings during the session, in good faith, by the person who owns them, and **neither reached the crossing the finding names**. The egress proxy does not touch **AI25**, because both renderer fetches happen outside the cluster. Org-wide branch protection does not touch **T2**, because the assistant commits to an unprotected working branch and `platform-ci` holds a standing exemption recorded in a config file the controls page does not reference. The proxy *is* in the path for **I3** and is still not credited, because nobody knows what is on its two-year-old shared allow-list.
>
> **The rule this section now applies:** a platform control is drawn into this architecture when someone has traced it to a specific crossing in §3, and not because it exists. The finding-by-finding mapping is owned by Kwame Osei, 2026-09-23, and six findings — S2, S5, T5, I4, R4, RR3 — are held until it lands.

This is the map, not the evaluation. It records what the input describes.

| Control domain | What the design describes | Gap |
|---|---|---|
| **Identity** | That users reach the assistant from Slack and from a web console. Nothing about how either asserts identity, nothing about how the assistant authenticates to connectors, nothing about token lifetime or revocation. | No identity model exists. S2, S4, S5, AI8. |
| **Authorisation** | Nothing. No statement that a retrieval respects the requesting user's entitlements in the source system, and no statement that a tool call is checked against what that user may do. | No authorisation model exists. E1, E2, I2. |
| **Cryptography** | Nothing. No TLS requirement, no encryption-at-rest requirement, no key management, no statement of algorithms. | No cryptographic requirements exist. T5, I4, and crypto agility is unaddressed. |
| **Network** | Nothing beyond the implied reachability of five MCP servers and a hosted model API. No egress control, no allow-list, no segmentation. | I3, TB8. |
| **Input handling** | One sentence: web-search content is "treated as untrusted and cleaned". Undefined, and scoped to one connector of five. | AI1, and the definition gap itself. |
| **Output handling** | Nothing. Model output is rendered in Slack and the web console and is sent outward as email, Slack posts, issue comments and commits, with no described filter at any sink. | AI6, AI25. |
| **Detective** | PLAT-2825: actions shown in the conversation; user reviews own history. That is a user-facing feature, not security telemetry. | No defender-readable record exists. R1, R2, O2. |
| **Provisioning and configuration** | PLAT-2822: model tiers configurable per workspace. No change control on that configuration, no floor, no review. | T1, AI20. |
| **Rate and cost** | PLAT-2822: usage *tracked* per team and visible to teams. Tracking is not capping. | D1, D2, and the "an alert is not a limit" rule. |
| **Human factors** | PLAT-2817 records that the pilot group rejected confirmation dialogs as too slow. That is a genuine and correct usability observation about *undifferentiated* confirmation, and the design's response was to remove confirmation entirely rather than to make it risk-proportionate. | AI21, and PRV·H3. |

### 6.1 Data lifecycle as designed

1. **Collection** — content is pulled from five connectors at query time, selected by relevance to a prompt. No purpose limitation is expressed, no minimisation step is described, and the selection criterion is the model's judgement of relevance rather than the user's entitlement.
2. **Processing** — assembled into a prompt and sent across TB2 to a third-party inference service. The model emits text and tool calls.
3. **Storage** — persisted in the conversation and history store to satisfy PLAT-2825. Nothing states what is stored, for how long, or with what protection.
4. **Sharing** — outward through four write-capable tools and one search egress. Content can leave the organisation as an email to any address, a post in any channel the connector can reach, an issue comment on a public repository, or a URL parameter in a web fetch.
5. **Retention** — no policy exists in the input.
6. **Destruction** — no deletion path exists in the input, in any store.

Stages 5 and 6 are empty, and stage 1 has no basis recorded. That is the shape of a system that will be difficult to make lawful after the fact and straightforward to make lawful now.

---
---

## 7. Evaluation — the target architecture

*Authored after `06-threat-model.md`. Everything above describes the system as designed. Everything below is the response to what the threat model found.*

The threat model's headline is that the design contains the lethal trifecta — access to private data, exposure to attacker-authored content, and an outward channel — with the human confirmation step explicitly removed. Four architectural changes address that; everything else in the gap analysis is a tactical fix that does not need the architecture to move.

### 7.1 ARCH-1 — Move the trust boundary from the network to the authorship of the content

**The change.** Every piece of content entering the model's context carries a provenance label assigned at ingest by the connector that fetched it, not by the network zone it came from. The label answers one question: *could a party outside the organisation have authored this text?* An email body: yes. A GitHub issue on a public repository: yes. A Slack message in a channel with guests or an incoming webhook: yes. A document with external sharing enabled: yes. A commit on a protected branch by a verified corporate identity: no.

**Why it must be architectural.** The label has to be attached where the content is fetched, because that is the only place the answer is knowable. Attaching it later means inferring authorship from text, which is exactly the guess the model cannot be trusted to make.

```mermaid
flowchart LR
    SRC["Connector fetch"] --> LBL{"Assign provenance at ingest"}
    LBL -->|"externally authorable"| UNT["Untrusted band of the context"]
    LBL -->|"corporate authored and verified"| TRU["Trusted band of the context"]
    UNT --> ASM["Context assembly with structural delimiters"]
    TRU --> ASM
    ASM --> POL{"Action policy: has untrusted content entered this task?"}
    POL -->|"yes"| GATE["Write tools require out-of-band confirmation"]
    POL -->|"no"| FAST["Write tools follow the standard path"]

    classDef data fill:#fff2cc,stroke:#7f6000
```

**What it buys.** It turns "did a prompt injection succeed?" — unanswerable — into "did untrusted content enter this task?" — a deterministic fact the orchestrator knows. That is the ATLAS `AML.M0030` control, and it is the single highest-value change in this document. Addresses AI1, AI11, AI18, O1.

### 7.2 ARCH-2 — Risk-proportionate confirmation, not undifferentiated confirmation

**The change.** Classify every tool by reversibility and by blast radius, and gate on the classification rather than on every call. **This is the paragraph the validation session showed can be missed, so the class list is now a table and it also appears in the executive summary of `01-security-review.md`** `[session 2026-09-09]`.

| Class | What is in it | Gated? |
|---|---|---|
| **Read** | Retrieve mail, search documents, read a calendar entry, read an issue, read a repository | **No gate.** The large majority of turns in a "what is blocking the release" workload |
| **User-scoped write** | A draft in the requesting user's own drafts folder; an update to their own task | **No gate.** The blast radius is the requester |
| **Org-visible write** | Post to a channel; comment on an issue | **Gated** — and this is the one line reopened in the session `[session 2026-09-09 · Dana Whitfield, Tom Egerton]`. Posting to a channel is most of what Support does. Whether this class belongs in the gated set comes back with pilot numbers by 2026-09-16; it was explicitly not decided in the room, because nobody had the numbers |
| **External write** | Send email outside the organisation | **Gated**, out of band |
| **Code-integrity write** | Commit code | **Gated**, out of band |

The gate is **out of band**, meaning the confirmation is rendered from the *arguments the orchestrator will actually execute*, not from the model's description of them.

**Why this answers the pilot group rather than overruling them.** PLAT-2817's finding was that a confirm dialog *on every action* is slower than doing the work by hand. That is correct, and it is an argument against undifferentiated friction, not against friction. Most turns are reads and will be untouched. The subset that sends mail to an external address is where the 6-second budget can afford to stop. Addresses AI2, AI7, AI21, E5, RR1.

> **What the session established about this section, and it is a lesson about the pack rather than about the design** `[session 2026-09-09 · Dana Whitfield]`**.** The recommendation was challenged on the ground that the pack demands *"every action must be confirmed before it executes"* — that the pilot built exactly that in week two, watched people stop using it, and that reversing the one thing the pilot taught them was unacceptable. **The pack does not say that.** This paragraph has always been class-based, and `01-security-review.md` §7 is a page arguing that the pilot's evidence is correct and should be kept. The objection was withdrawn as soon as the text was read out, with the reader's own diagnosis: she had read the headline and filled in the rest. **On a hundred-page pack that is not a reader's failure, it is a presentation defect**, and the correction is being made rather than argued — the class list moves into the executive summary so the misreading is not available (Brett Crawley, 2026-09-16). **The gating decision itself did not move**, and the *org-visible write* row is the only part still open.
>
> **The code-integrity-write gate is close to free** `[session 2026-09-09 · Priya Raghunathan, Dana Whitfield]`: eleven commits since July, nine of them the engineer testing the capability. The epic owner withdrew the defence of the commit feature as a headline capability on those numbers.

### 7.3 ARCH-3 — One identity per user per task, propagated to the data layer

**The change.** The assistant holds no standing access of its own. Each tool call carries a short-lived credential minted for the requesting user, scoped to the single tool being called and the single task in flight, and every connector evaluates authorisation against that identity in the system of record. Retrieval returns what *that user* may read, enforced by Office 365, Slack, GitHub and the mail server — not filtered afterwards by the assistant.

**Why it must be architectural.** It is the difference between "the assistant reaches everything and shows you your slice" and "the assistant reaches your slice". Only the second survives a compromise of the reasoning loop, and only the second makes the audit trail meaningful downstream. Addresses AI8, E1, E2, E4, I2, R3, S4.

> **Two qualifications from the validation session, and the second is the important one** `[session 2026-09-09]`**.**
>
> **This section is written in the present tense on this page, and nobody has verified it.** Three people stated that the design is already per-user delegated — *"it doesn't get to see anything you couldn't see"*, *"that's the standard pattern"*, *"it's on the architecture page in the present tense; it doesn't say will, it says does"*. The engineer who built the pilot declined to confirm it from the configuration, not having set all the scopes up herself. **Findings I2, E1, E2, E4, R3 and AI8 did not move**, and they move on the app registration and the granted scopes per connector (Priya Raghunathan, 2026-09-10), not on the room's recollection. Until then this section describes an intent, and the page should not read as though it describes a fact.
>
> **ARCH-3 does not reduce the privacy exposure on the Support mailbox, and that is not a defect in ARCH-3** `[session 2026-09-09 · Tom Egerton]`**.** The Support mailbox is *shared* — one address the whole team works out of, connected as a shared mailbox in the connector configuration. All seven of the team may read all of it. So "returns what *that user* may read" returns the whole mailbox for every one of them, and per-user credentials narrow nothing at all there. The exposure is real and it is carried at **P2** as a privacy finding with an Article 14 obligation, not at **I2** as an authorisation one. ARCH-3 remains correct and necessary; it simply is not the control that addresses this case.

### 7.4 ARCH-4 — A defender-readable action record, separate from the user-facing one

**The change.** Every tool call is written to an append-only store the assistant's own identity cannot rewrite, carrying: the human principal, the workspace, the tool, the full arguments, the provenance labels of every chunk in the context at the time, the model and tier that produced the call, the tool description version in force, the decision, and the outcome. PLAT-2825's in-conversation display stays exactly as designed — it is a good feature — and this sits behind it.

**Why both are needed.** The conversation view answers "what did it do for me?". It cannot answer "did anything in the estate get instructed by a document to email itself to an outside address last Tuesday?", because it is scoped to one user and stored where the acting component can change it. Addresses R1, R2, R4, O2, and it is the telemetry that makes the ATLAS attack path in the threat model observable.

### 7.5 Sequence: the target flow for a write action

```mermaid
sequenceDiagram
    participant U as Staff user
    participant O as Orchestrator
    participant C as MCP client
    participant M as Model provider
    participant A as Action gate
    participant L as Append-only action log

    U->>O: Ask what is blocking the release
    O->>C: Fetch from GitHub, Slack, Email
    C-->>O: Chunks, each labelled at ingest with author provenance
    O->>O: Mark task tainted because externally authorable content is present
    O->>M: System prompt, delimited trusted band, delimited untrusted band
    M-->>O: Answer plus a tool call to send email to an external address
    O->>A: Submit tool call with arguments and the taint flag
    A->>L: Record the proposed call before any decision
    alt Task is tainted or the tool leaves the organisation
        A->>U: Show the exact recipient, subject and body that will be sent
        U-->>A: Approve or reject out of band
    else Read-only or user-scoped write on an untainted task
        A->>A: Execute under the standard path
    end
    A->>L: Record actor, tool, arguments, provenance, model tier, decision, outcome
    A-->>U: Show the result in the conversation per PLAT-2825
```

---

## 8. Security implications of the design decisions already accepted

The team has made three decisions that function as accepted ADRs. Each should be written down as one, so the residual is carried knowingly rather than inherited silently.

| Decision, as recorded in the tickets | Security implication | Recommended disposition |
|---|---|---|
| **PLAT-2814**: internal sources need no untrusted-content handling because they are behind authentication. **Version 1.1: this was never an accepted decision — it was a product scoping note that four artefacts then treated as one** `[session 2026-09-09]` `[contradicts v1.0]` | Confuses read authorisation with content authorship. It is the precondition for every indirect-injection path in the threat model. **And there is a second implication version 1.0 missed: there is no decision here to reverse, because no decision was ever made.** The criterion was written to scope build effort and explicitly not as a security position; ADR-0004 cites the criterion; the trust model on this page cites the ADR; and the Security Champion assumed the platform ingestion sanitiser covered the assistant, which it does not, because the connectors call the MCP servers directly. Four artefacts, each correct alone, each citing another. | **Decide it, then reverse it.** ARCH-1 remains the technical answer, and it now has a prerequisite: the content-trust position written as an ADR of its own — not a scoping note, not an ADR deferring to a ticket — covering all five connectors, with the reasoning stated rather than cited, and recording that no such decision existed before. Finding **O5**; owner Marcus Oyelaran, 2026-09-19, reviewed by Ines Ferreira and Brett Crawley. |
| **PLAT-2817**: no confirmation step, on pilot-group usability feedback | Removes the only control that holds when the model does not. Makes every irreversible action reachable from one reasoning step over attacker-authored input. | **Reframe, do not simply reinstate.** ARCH-2 keeps the usability finding intact and applies friction only where the blast radius earns it. |
| **PLAT-2822**: cheaper model tiers configurable per workspace | Whatever injection resistance the model contributes becomes a per-workspace budget decision, and the cheapest tier is the weakest. Because the deterministic controls do not yet exist, the model is currently the only thing between an injected instruction and a sent email. | **Accept with a floor.** Tiering is a legitimate cost control once ARCH-1 to ARCH-4 exist, because then the model's robustness is a backstop rather than the guarantee. Set a minimum tier for any task that can reach a write tool, and record the residual in an ADR. |

---

## 9. Assessment against principles

| Principle | Posture | Note |
|---|---|---|
| **Defence in depth** | **Fails.** | There is one layer — the model's judgement — and the design's own cost lever makes that layer configurable downward per workspace. |
| **Least privilege** | **Fails.** | The agent holds every connector's full capability on every request regardless of the task. E1, AI7. |
| **Secure by default** | **Fails.** | The default for a new workspace is the full connector set with no confirmation. E3, AI7. |
| **Fail securely** | **Unknown, and probably fails.** | Under a 6-second budget with a slow connector, the described behaviour is nothing. D4 covers the likely fail-open. |
| **Complete mediation** | **Fails.** | No authorisation decision is described on any retrieval or any tool call. E2, I2. |
| **Separation of duties** | **Fails.** | One component reads mailboxes and sends mail; one component reads code and commits code. Both halves of an exfiltration primitive in a single trust context. |
| **Economy of mechanism** | **Mixed.** | The design is genuinely simple, which is a real virtue — but the simplicity comes from having omitted the controls, not from having found an elegant way to enforce them. |
| **Human-centered security** | **Partially strong.** | PLAT-2817's usability observation is correct and well-evidenced from the pilot. The response drew the wrong conclusion from good data. ARCH-2 keeps the data and changes the conclusion. |
| **Crypto agility and quantum readiness** | **Not addressed.** | No cryptography is specified at all, so there is nothing to be agile about yet. Raised now because the conversation store is a long-lived confidentiality asset and a harvest-now-decrypt-later target: specify algorithm and key-version metadata on stored records before the first record is written, not after. |
| **Proportionality** | **Fails in the direction that matters.** | The controls are proportionate to a read-only FAQ bot. The system is an autonomous actor with write access to email, chat and source code. |

**Credit where it is due, and it is due in three places.** The latency requirement is quantified rather than aspirational, which is rare and makes the security trade-off discussable instead of arguable. PLAT-2825 exists at all — a lot of agentic designs ship with no action visibility whatsoever, and this team wrote it in as an acceptance criterion before any security review asked. And PLAT-2814 *does* identify untrusted content as a category and *does* commit to handling it — the boundary is drawn in the wrong place, but the team was thinking about the right problem, which is a much better starting position than not having thought about it.

---

## 10. New requirements this architecture surfaces

Fed back into the requirements baseline in `04-gap-analysis.md` §4 and traced in `05-srtm-and-test-artefacts.md`.

- **SEC-20** — Every retrieved chunk carries an author-provenance label assigned by the connector at ingest, and the label is persisted with the chunk. *(from ARCH-1)*
- **SEC-21** — The orchestrator maintains a per-task taint flag set when any externally-authorable chunk enters the context, and the flag is an input to the action gate. *(from ARCH-1)*
- **SEC-22** — Tools are classified by reversibility and blast radius, and the classification is a property of the tool registry, not of the prompt. *(from ARCH-2)*
- **SEC-23** — Confirmation for gated actions renders the arguments the orchestrator will execute, obtained out of band from the model's own description of them. *(from ARCH-2)*
- **SEC-24** — Tool calls execute under a short-lived credential minted per user per task per tool; the assistant holds no standing access. *(from ARCH-3)*
- **SEC-25** — Authorisation for retrieval is evaluated by the system of record against the requesting user, not applied as a filter after retrieval. *(from ARCH-3)*
- **SEC-26** — An append-only action log records actor, workspace, tool, arguments, context provenance, model and tier, tool-description version, decision and outcome; the assistant's identity has append-only rights to it. *(from ARCH-4)*
- **SEC-27** — A minimum model tier applies to any task in which a write tool is reachable. *(from §8)*
- **PRV-10** — The conversation store is enumerable and deletable per data subject, including retrieved chunks and generated content. *(from §5.1)*
- **PRV-11** — Records in the conversation store carry the algorithm and key-version metadata needed to re-encrypt without re-architecting. *(from §9 crypto agility)*
- **COMP-08** — A DPIA is completed before the pilot expands beyond Platform and Support. *(from §6.1 and finding P7)*

**Added in version 1.1, from the validation session** `[session 2026-09-09]`**.** Two, and neither is a component — both are requirements about how decisions and controls are recorded, which is where this design actually failed.

- **PROC-01** — **The content-trust position is recorded as an architecture decision record of its own**, covering all five connectors, stating the reasoning rather than citing another artefact, with a named owner and named reviewers, and recording explicitly that no prior decision existed. Structurally: an ADR whose only stated reason is another artefact fails review. *(from **O5**. Owner Marcus Oyelaran, 2026-09-19, reviewed by Ines Ferreira and Brett Crawley.)*
- **PROC-02** — **A platform control is credited against a finding only on a written mapping that names the crossing it covers and the direction of the flow**, never on the control's existence; and every exemption or carve-out is held in the same artefact as the control it modifies, with a review date, so the documented position and the enforced position cannot diverge. *(from **O6**. Owner Kwame Osei, 2026-09-23.)*

These sit alongside SEC-20 to SEC-27 rather than inside them. The design changes in §7 are correct and were not the failure: **the failure was that nobody owned the position they rest on, and that a control set which appeared to cover two of them did not.**

---

*This document reflects the inputs as supplied on 2026-09-09, plus the validation-session transcript of the same date. The architecture in §2 to §6 is reconstructed from acceptance criteria and is still not validated against a design document or an implementation, because neither was supplied — the session produced testimony about those artefacts, not the artefacts. Claims tagged `[session 2026-09-09]` are attributed to their speaker and are testimony rather than configuration; §7.3 in particular describes an intended credential model that nobody has yet read from the configuration. Statuses tied to ticket references are point-in-time. Nothing here is legal advice; the GDPR, EU AI Act, NIS2 and SOC 2 items should be confirmed with counsel and the Data Protection Officer.*
