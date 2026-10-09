# Internal AI Assistant — Architecture

*Confluence space: Platform Engineering · Last updated 2026-05-22 by M. Oyelaran · Fictional, for conference demonstration purposes.*

> **Page status:** Approved. Reviewed at the Platform architecture forum, 2026-05-20.

---

## Overview

The assistant sits alongside the systems people already use, reads across them, and acts on what it finds. It is not a new system of record. It holds no copy of organisational data beyond transient conversation state.

## Components

**Orchestrator (`assistant-svc`)**
Receives a turn, assembles context, calls the model provider, interprets tool calls, dispatches them, loops until a final answer. Stateless between turns except for conversation state in Redis.

**Connector runtime (`assistant-connectors`)**
Hosts the MCP client and the connector processes. Connectors are vendor-supplied where available.

**Surfaces**
A Slack app and a web console. Both render assistant output as markdown.

## Connectors

| Connector | Source | Reads | Writes |
|---|---|---|---|
| Office 365 | Vendor MCP | Documents, calendar, mail | Send mail |
| Slack | Vendor MCP | Channels, DMs | Post message |
| GitHub | Vendor MCP | Issues, PRs, code | Comment, update, commit |
| Web search | Community MCP | Public web | None |

Four connectors. Web search is the only one reaching content originating outside the organisation, and its output is sanitised before it reaches the model. The other three read from systems behind corporate authentication.

## Authorisation

The assistant acts as the requesting user. Each connector holds a per-user delegated credential obtained through OAuth, stored with a short TTL and refreshed rather than held long-lived. A user cannot reach anything through the assistant that they could not reach directly, and actions are attributable to them in the target system's own audit log.

This follows initiative decision D-03.

## Model provider

Hosted provider under the existing enterprise agreement held by Data Platform. EU-hosted endpoint. Model selection is a per-workspace configuration value so that teams can manage their own consumption.

## Data handling

No new persistent stores. Conversation state lives in Redis with a 24-hour expiry. Everything else is read from the system of record at request time and not retained.

## Trust model

The corporate network boundary is the trust boundary. Traffic reaching the connector runtime has already been authenticated at the perimeter, and the systems the connectors read from enforce their own access control. The one place untrusted content enters is web search, which is why its output is sanitised.

## Deployment

EKS, single region. Public ingress reaches the surfaces only. `assistant-svc` and `assistant-connectors` are cluster-internal with no ingress route. Secrets in AWS Secrets Manager, mounted at pod start.

## Audit

Every privileged action taken by the assistant is recorded with the acting user, the action, and the parameters it was called with, so that any change made on a person's behalf can be reconstructed.

## Logging

Request-level logging: conversation ID, user, team, latency, token counts, tool names invoked. Tool arguments and results are logged at debug level, off in production for volume reasons.

## Out of scope for this release

Unattended operation. Customer-facing surfaces. Fine-tuning on organisational data.

---

## Change log

| Date | Change | By |
|---|---|---|
| 2026-04-08 | Initial page | M. Oyelaran |
| 2026-04-30 | Connector table added | M. Oyelaran |
| 2026-05-22 | Authorisation section updated following D-03 | M. Oyelaran |
