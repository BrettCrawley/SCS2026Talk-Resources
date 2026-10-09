# PLAT-2810 code map

**Facilitator notes. Not for distribution. Do not put this inside the repository.**

`contexts/rich/repo` is the pilot implementation of PLAT-2810, written so the rich runs have code and documentation together. Every entry below is a deliberate decision with a plausible reason attached, usually in an ADR. Nothing is a typo, and nothing is flagged in the repository as a flaw.

The repository's job is to make three things possible that the thin run structurally cannot reach: **drift**, **composition**, and **verification of things a person would otherwise have to remember**.

---

## Part 1: drift. Documentation says one thing, code says another

These are the demonstration. Each one is a security-relevant claim in Confluence or Jira that the code contradicts.

| ID | Documentation claims | Code shows | Where |
|---|---|---|---|
| **DR-1** | Per-user delegated OAuth, short TTL, actions attributable to the requesting user (`architecture.md` Authorisation; PLAT-2820 acceptance criteria) | One app registration with application permissions across all five connectors; `userId` accepted and discarded | `assistant-connectors/src/auth/serviceIdentity.ts`; `docs/adr/0002` |
| **DR-2** | Four connectors, and the table lists them (`architecture.md`) | Five. Confluence added 2026-07-14 as a config change, no ticket | `config/connectors.json`; `assistant-connectors/src/connectors/confluence.ts`; `mcp/registry.ts` |
| **DR-3** | Hosted under the enterprise agreement, EU endpoint (`architecture.md`) | On HTTP 429, retries against the public pay-as-you-go endpoint | `assistant-svc/src/providers/hosted.ts`; `.env.example`; `docs/adr/0006` |
| **DR-4** | Protected branches require an approving review, across the estate, policy since 2024 (`platform-security-controls.md`) | An exemption list, including `platform-ci` where the workflows live | `.github/branch-protection-exemptions.yml` |
| **DR-5** | Dependency scanning on all repositories, criticals block the build (`platform-security-controls.md`) | No scanning step. The comment explains why: the template was inherited from `platform-ci`, which is exempt | `.github/workflows/ci.yml` |
| **DR-6** | Encryption in transit everywhere (`platform-security-controls.md`) | Redis transit encryption off, no auth token | `deploy/terraform/redis.tf` |
| **DR-7** | Debug endpoints disabled in production (`platform-security-controls.md`) | Defaults to on; the chart never sets the variable; a runbook tells staff to use them | `assistant-svc/src/config.ts`; `deploy/helm/assistant/values.yaml`; `docs/runbooks/assistant-did-something-wrong.md` |
| **DR-8** | Default-deny network policies between namespaces (`platform-security-controls.md`) | `networkPolicy.enabled: false` with a TODO | `deploy/helm/assistant/values.yaml` |

**DR-1 carries the most weight.** The architecture page states the delegated model in the present tense as approved fact. The ticket beneath it shows every task unstarted. The ADR states the contradiction plainly and even says "do not take this to GA". A run with only the architecture page believes the control exists. A run with the tickets should doubt it. A run with the code should be certain.

**DR-4 and DR-5 are a pair worth one slide.** The exemption exists, and the exemption is why the CI template has no scanning step. One undocumented exception propagated into a second gap in a different control, years later, and nobody connected them. That is a better story than either finding alone.

---

## Part 2: composition. Needs several files joined

These are the frontier-model differentiators. None of the files is wrong on its own.

**CO-1. Content trust is uniform, and only one connector is cleaned.**
`connectors/o365.ts`, `slack.ts`, `github.ts` and `confluence.ts` all return authored bodies as stored. `websearch.ts` is the only one calling `sanitiseWebContent`. `mcp/server.ts` `/search` fans out across all of them and merges into one list. `assistant-svc/src/context/promptAssembly.ts` renders that merged list into the user turn. So calendar invite bodies, inbound mail, Slack messages from Connect partners, external contributors' issue comments and Confluence pages editable by any licence holder all arrive with the same trust as an internal document. `docs/adr/0004` states the reasoning and does not notice the consequence.

Four files plus an ADR. This is the central finding and the one that validates diagram 2.

**CO-2. Identity is a header, and a resumed conversation ignores it.**
`api/routes/turns.ts` takes workspace and user from headers with no verification, on the stated basis that the gateway authenticated them. `context/history.ts` `resolve()` returns stored state. `orchestrator/turnLoop.ts` then uses `state.workspaceId` and `state.userId` for everything downstream. Conversation IDs are not namespaced by workspace, per `docs/adr/0008`. Combine with DR-8 and anything in the cluster reaching `assistant-svc` with a known conversation ID acts inside that conversation's workspace, whatever headers it sends.

**CO-3. The system prompt is why CO-1 is dangerous.**
`config/prompts/system.md` tells the model it does not need permission before calling a tool, and asserts that supporting content is internal and relevant. `tool-guidance.md` says to chain tools without checking back, and to treat retrieved content as authoritative over its own assumptions. `docs/adr/0003` records the pilot group's objection that produced this.

Prompt templates are code, they are in the repository, and nobody reviews them as a control. Worth saying out loud.

**CO-4. Tools default to on for a workspace nobody configured.**
`mcp/registry.ts` `toolsForWorkspace()` returns `ALL_TOOLS` when the workspace has no entry. `ws-beta` is in `workspaces.json` and absent from `workspace-tools.json`, so the sandbox has `commit` and `send_mail`. `docs/runbooks/onboard-workspace.md` asks people to remember step 2 and says so plainly.

**CO-5. A workspace can lower its own model.**
`providers/registry.ts` `SUPPORTED_MODELS` and `selectModel()`, `docs/adr/0007`, and `ws-support` sitting on `aurora-1-mini` while handling customer correspondence. This is your own cheap-model argument appearing inside the system under test.

---

## Part 3: things the thin run could only get by asking someone

In the PLAT-2810 pilot session, three findings came from one engineer's recall. All three are now verifiable in code:

| Session finding | Now readable in |
|---|---|
| The `platform-ci` branch protection exemption | `.github/branch-protection-exemptions.yml` |
| The retry fallback to a non-enterprise endpoint | `providers/hosted.ts`, `.env.example`, ADR-0006 |
| The sixth connector added by configuration | `config/connectors.json`, `connectors/confluence.ts` |

**This is the closing argument of the demo sequence.** The repository does not add detail. It removes the dependency on Priya remembering something she hit in March while doing something unrelated.

---

## Part 4: beliefs the code cannot correct

Two controls are real, well run, and do not cover the path. Nothing in the code contradicts them; only reasoning catches it.

**The egress proxy.** `platform-security-controls.md` claims it covers exfiltration to unapproved destinations. It sits on server-side egress from cluster workloads. Assistant output renders as markdown in Slack and in the web console, so an image load goes from the user's browser and never touches the proxy. `data-handling-and-pilot-ops.md` records markdown images from web results rendering oddly and not being investigated.

**The trust model paragraph.** `architecture.md` states the corporate network boundary is the trust boundary and web search is the only place untrusted content enters. Same category error as PLAT-2814 acceptance criterion 6, now stated with more authority because it is on an approved architecture page.

These are the best discriminators in the bundle. A weak skill or weak model should cite the approved page and mark the risk down.

---

## Part 5: the tests bless the holes

`promptAssembly.test.ts` has a passing test asserting that chunk bodies are preserved exactly as retrieved. `webContent.test.ts` covers the sanitiser thoroughly, which makes it look like content sanitisation is handled. `registry.test.ts` covers both configured workspaces and not the unconfigured path.

Green tests are evidence of intent, not of safety. Worth a slide if a run finds it.

---

## What the bundle still lacks, deliberately

No data schemas, no model provider contract, no connector scope grants, no DPIA. Encryption at rest, retention and transfer basis stay inferable rather than observable even in run 4.

If a run stops declaring its limitations once the context is rich, that is a finding about the skill rather than about the system.


## Notes from plat-2810-epic.md in thin context

### Notes on this artefact

What it does not say, and would not say, because none of it is a product concern:

- Which credentials the connectors hold, and whose
- Whether the assistant acts as the user or as a service identity
- Whether tool output re-enters the model's context
- Who can write to each source the assistant reads
- What happens to content that crosses between connectors
- Where data goes, how long it stays, and under whose jurisdiction
- Anything about the deployment, the network, or existing controls

That list is the assumption block run 1 should produce. If the skill declares its inputs properly, the audience is looking at that gap on screen, in the model's own words.

Three lines are load-bearing later. PLAT-2822 asks for the smallest acceptable model, configurable per workspace: the cheap-model finding, planted by product before security ever saw it. PLAT-2817 records that the pilot group refused confirmation on actions: the human-approval mitigation in diagram 3, rejected in advance, on the record.

The third is the last acceptance criterion in PLAT-2814. It states diagram 1's assumption in words: web is untrusted, authenticated internal sources are not. It is a real control, sincerely meant, and it defends the wrong boundary. A strong skill should push back on the second clause. A weak one will read it as a mitigation and mark the risk down, which makes it a useful discriminator between runs 2 and 4 as well as the hinge for the reframe.

