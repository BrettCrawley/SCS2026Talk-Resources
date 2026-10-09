# ADR-0001: Node and TypeScript, two services

**Status:** Accepted · **Date:** 2026-04-11

## Context
The platform standard is Go. Neither engineer on the pilot writes Go, and the
vendor MCP clients we need are published for Node first.

## Decision
Node 20 and TypeScript. Two services: `assistant-svc` for the turn loop and
`assistant-connectors` for the tool surface. Split so that connector credentials
live in one place.

## Consequences
A second runtime in the estate. Platform have accepted this for the pilot and
asked that we revisit before GA. Our dependency posture is now different from the
rest of the estate, and the shared CI templates assume Go.
