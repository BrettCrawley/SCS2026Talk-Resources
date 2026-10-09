# ADR-0004: Retrieval fans out to every connector

**Status:** Accepted · **Date:** 2026-06-03

## Context
Users do not know which system holds the answer. That is the problem the
assistant exists to solve, so asking them to pick a source defeats the point.

## Decision
`/search` fans out to every connector that supports search and merges the
results. Bodies are returned as authored. Summarising at the connector loses the
detail the user asked about, and we do not know at retrieval time which part
matters.

## Consequences
Content authored by different people, with different levels of trust, arrives in
one merged list and enters the same prompt. Only web search output is cleaned,
because that is the connector PLAT-2814 identified as untrusted.
