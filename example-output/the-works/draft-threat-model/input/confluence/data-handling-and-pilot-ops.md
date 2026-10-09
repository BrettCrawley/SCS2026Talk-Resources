# Internal AI Assistant — Data Handling and Pilot Operations

*Confluence space: Platform Engineering · Last updated 2026-06-30 by P. Raghunathan · Fictional, for conference demonstration purposes.*

> **Page status:** Draft. Written during the pilot, not yet reviewed.

---

## Data the assistant touches

| Data | Where it comes from | Classification | Retained by us |
|---|---|---|---|
| Document content | O365 | Internal, some Confidential | No |
| Calendar entries | O365 | Internal | No |
| Mail content | O365 | Internal, may contain personal data | No |
| Slack messages | Slack | Internal | No |
| Issue and PR content | GitHub | Internal | No |
| Source code | GitHub | Confidential | No |
| Web results | Public web | Public | No |
| Conversation state | Us | Internal, may contain any of the above | 24 hours, Redis |
| Usage telemetry | Us | Internal | 13 months, warehouse |

Nothing is copied into a new store of record. Conversation state is transient. This follows initiative decision D-05.

## Usage telemetry

Recorded per request: timestamp, user, team, model, input and output token counts, tool names invoked, latency. Written to the analytics warehouse.

The consumption dashboard aggregates to team level so that cost is attributable to a cost centre, which is the PMO-0447 requirement.

## Pilot scope

**Platform**, since 2026-05-04. Twelve users.
**Support**, since 2026-06-09. Nine users.

Support's use case is different from Platform's. Support wanted the assistant reading the ticket queue and the shared mailbox so it can summarise a customer's history before an agent picks up a call.

## Known rough edges during pilot

These are things the pilot group have hit. Recorded here so we do not rediscover them.

- Long conversations get slow. Context grows and we do not trim it. Session TTL is 24 hours, so a conversation left open all day carries everything.
- The web console is behind the VPN with a shared password. SSO is PLAT-2831-3, not scheduled.
- When the model is uncertain it sometimes takes an action anyway rather than asking. The pilot group prefer this to being asked, but it has caused two mistaken Slack posts.
- Model responses occasionally include markdown images referencing external URLs from web results. Renders fine, looks odd. Not investigated.
- Rate limiting from the provider during the afternoon peak. Handled in the client.

## Operational contacts

| Area | Owner |
|---|---|
| Orchestrator and connectors | P. Raghunathan |
| Architecture | M. Oyelaran |
| Product decisions | D. Whitfield |
| Pilot coordination, Support | T. Egerton |

## Open questions we have not resolved

- What happens to a conversation when the person who started it leaves.
- Whether Support's shared mailbox should be in scope at all, given whose data is in it.
- Whether we need a kill switch, and who would be allowed to use it.
