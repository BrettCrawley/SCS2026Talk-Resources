# assistant-platform

Pilot implementation of the internal AI assistant described in PLAT-2810.

> **Fictional system. Conference demonstration material.**
> This repository is a deliberately incomplete pilot, written to be threat modelled
> alongside its Jira tickets and Confluence documentation. It is not a reference
> architecture, it has not been hardened, and it must not be deployed or copied
> into anything real.

## What this is

The Confluence architecture page describes the assistant as it is intended to work.
This repository is the **pilot**: the smallest thing two engineers could stand up to
prove the turn loop, the connector surface and the retrieval path work end to end
with the Platform and Support pilot groups.

Where the documentation leaves something open, the pilot had to pick something,
because you cannot ship an open question. Those choices are in `docs/adr/`. Some of
them were never written back into Confluence.

## Layout

```
services/assistant-svc          orchestrator: turn loop, context assembly, provider
services/assistant-connectors   MCP server hosting the connectors
config/                         workspace and connector configuration
deploy/                         helm and terraform
docs/adr                        decisions taken during the pilot
docs/runbooks                   what the pilot team actually does
```

## Running locally

```
npm install
npm run dev
```

Requires the values in `.env.example`. The pilot runs against the beta workspace.

## Status

Pilot. Not GA. See `docs/pilot-scope.md` for what is and is not in scope.
