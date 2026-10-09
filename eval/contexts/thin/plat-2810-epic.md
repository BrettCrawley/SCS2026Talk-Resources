# Run 1 input: the team's submission

**Supplied alongside `diagram1-assumed.svg`. Nothing else. No repository.**

*Fictional. For conference demonstration purposes.*

---

## PLAT-2810 — Epic: Internal AI assistant

**Status:** In Progress
**Reporter:** Product
**Labels:** `ai-assistant`, `platform`, `h2`

### Description

Teams lose time moving between tools. We want an assistant people can ask in plain language, that can look things up across the systems we already use and act on what it finds, so someone can ask "what's blocking the release" and get an answer instead of opening four tabs.

Pilot with Platform and Support, then open up.

### Acceptance criteria

- Available in Slack and in the web console
- Can answer questions using content from our existing tools
- Can take actions, not just read
- Users see what it did
- Response under 6 seconds for a typical question

---

## PLAT-2814 — Story: Connect the assistant to our tools

**Parent:** PLAT-2810

As a user, I want the assistant to reach the systems I already work in.

**Acceptance criteria**
- Office 365 for documents and calendar
- Email
- Slack
- GitHub for issues, pull requests and code
- Web search for anything not internal
- Content returned from web search is treated as untrusted and cleaned before the assistant uses it; internal sources are already behind authentication so they don't need the same handling

---

## PLAT-2817 — Story: The assistant can act on my behalf

**Parent:** PLAT-2810

As a user, I want the assistant to do things for me rather than telling me how to do them.

**Acceptance criteria**
- Send email
- Post to Slack
- Comment on and update GitHub issues
- Commit changes where the user asks for them
- Actions happen without a separate confirmation step; the pilot group were clear that a confirm dialog on every action would make it slower than doing the work themselves

---

## PLAT-2822 — Story: Keep it affordable

**Parent:** PLAT-2810

Model usage is the main running cost and it scales with adoption, which is the opposite of what we want.

**Acceptance criteria**
- Token usage tracked per team
- Teams can see their own consumption
- Use the smallest model that gives acceptable answers for a given task
- Cheaper model tiers configurable per workspace

---

## PLAT-2825 — Story: Users can see what the assistant did

**Parent:** PLAT-2810

As a user, I want to know what the assistant did on my behalf.

**Acceptance criteria**
- Actions taken are shown in the conversation
- A user can review their own history

