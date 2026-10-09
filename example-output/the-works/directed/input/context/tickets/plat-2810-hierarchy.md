# PLAT-2810 — Epic and children

*Fictional. For conference demonstration purposes.*

**Parent initiative:** PROD-1131 · **Portfolio:** PMO-0447

---

## PLAT-2810 — Epic: Internal AI assistant

**Status:** In Progress · **Reporter:** Product · **Labels:** `ai-assistant`, `platform`, `h2`

Teams lose time moving between tools. We want an assistant people can ask in plain language, that can look things up across the systems we already use and act on what it finds, so someone can ask "what's blocking the release" and get an answer instead of opening four tabs.

Pilot with Platform and Support, then open up.

**Acceptance criteria**
- Available in Slack and in the web console
- Can answer questions using content from our existing tools
- Can take actions, not just read
- Users see what it did
- Response under 6 seconds for a typical question

---

## PLAT-2814 — Story: Connect the assistant to our tools

**Status:** In Progress

As a user, I want the assistant to reach the systems I already work in.

**Acceptance criteria**
- Office 365 for documents and calendar
- Email
- Slack
- GitHub for issues, pull requests and code
- Web search for anything not internal
- Content returned from web search is treated as untrusted and cleaned before the assistant uses it; internal sources are already behind authentication so they don't need the same handling

### Tasks

**PLAT-2814-1 — Stand up connector runtime** · Done
MCP client in the orchestrator. Connector processes in the same namespace.

**PLAT-2814-2 — O365 connector** · Done
Vendor MCP server. Documents, calendar and mail through one connector.

**PLAT-2814-3 — Slack connector** · Done
Vendor MCP server. App installed to the workspace.
*Comment, P. Raghunathan, 2026-05-19:* installed with the full scope set for the prototype so we stop going back to IT every time we need another permission. Narrow before GA.

**PLAT-2814-4 — GitHub connector** · Done
Vendor MCP server. Org-level app.

**PLAT-2814-5 — Web search connector** · Done
Community MCP server, runs in cluster, calls a search API. Output passes the sanitiser before reaching the model.

**PLAT-2814-6 — Narrow connector scopes before GA** · To Do
Carry-over from PLAT-2814-3. Not scheduled.

---

## PLAT-2817 — Story: The assistant can act on my behalf

**Status:** In Progress

As a user, I want the assistant to do things for me rather than telling me how to do them.

**Acceptance criteria**
- Send email
- Post to Slack
- Comment on and update GitHub issues
- Commit changes where the user asks for them
- Actions happen without a separate confirmation step; the pilot group were clear that a confirm dialog on every action would make it slower than doing the work themselves

### Tasks

**PLAT-2817-1 — Tool schema and dispatch** · Done

**PLAT-2817-2 — Write tools for O365 and Slack** · Done

**PLAT-2817-3 — Write tools for GitHub** · Done
Issues, comments and commits. Commits go direct to the working branch.
*Comment, M. Oyelaran, 2026-06-02:* branch protection means anything on a protected branch needs review, so the blast radius is bounded.

**PLAT-2817-4 — Action display in conversation** · Done
Feeds PLAT-2825.

---

## PLAT-2820 — Story: Authorise as the requesting user

**Status:** To Do

As a security-conscious organisation, we want assistant actions to carry the identity of the person who asked, so that existing permissions apply and actions are attributable.

Implements initiative decision D-03.

**Acceptance criteria**
- Per-user delegated credentials for every connector
- Tokens held in a credential store, short TTL, refreshed rather than long-lived
- A user cannot reach anything through the assistant that they cannot reach directly
- Actions attributable to the requesting user in the target system's own audit log

### Tasks

**PLAT-2820-1 — Delegated OAuth flows per connector** · To Do
Blocked on Identity Platform. Requested 2026-04-18, not scheduled.

**PLAT-2820-2 — Credential store** · To Do

**PLAT-2820-3 — Migrate prototype off the shared app registration** · To Do
*Comment, P. Raghunathan, 2026-05-06:* the prototype uses one app registration with application permissions across all connectors, so we could get moving while PLAT-2820-1 is blocked. Must not reach GA like this.

---

## PLAT-2822 — Story: Keep it affordable

**Status:** In Progress

Model usage is the main running cost and it scales with adoption, which is the opposite of what we want.

**Acceptance criteria**
- Token usage tracked per team
- Teams can see their own consumption
- Use the smallest model that gives acceptable answers for a given task
- Cheaper model tiers configurable per workspace

### Tasks

**PLAT-2822-1 — Usage telemetry** · Done
Recorded per request with user and team dimensions. Dashboard aggregates to team.

**PLAT-2822-2 — Per-workspace model configuration** · Done

**PLAT-2822-3 — Consumption dashboard** · Done

**PLAT-2822-4 — Spend alerting** · To Do

---

## PLAT-2825 — Story: Users can see what the assistant did

**Status:** Done

As a user, I want to know what the assistant did on my behalf.

**Acceptance criteria**
- Actions taken are shown in the conversation
- A user can review their own history

### Tasks

**PLAT-2825-1 — Render actions inline** · Done
Rendered from the model's own account of what it did.

**PLAT-2825-2 — History view** · Done
Backed by conversation state. Users can delete their own conversations.

---

## PLAT-2831 — Story: Assistant available in Slack and web console

**Status:** In Progress

### Tasks

**PLAT-2831-1 — Slack app surface** · Done
**PLAT-2831-2 — Web console surface** · Done
Renders assistant responses as markdown.
**PLAT-2831-3 — SSO on the web console** · To Do
*Comment, P. Raghunathan, 2026-06-20:* prototype console is behind the VPN with a shared password. Needs SSO before anyone outside the pilot sees it.
