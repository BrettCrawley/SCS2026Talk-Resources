# ADR-0006: Fall back to the public endpoint on rate limit

**Status:** Accepted · **Date:** 2026-06-24

## Context
During the June afternoon peak the enterprise endpoint began returning 429s.
Turns failed in the console and the pilot groups noticed. The enterprise quota
increase went to procurement and has not come back.

## Decision
On a 429, retry against the provider's public endpoint using the pay-as-you-go
key that predates the enterprise agreement.

## Consequences
Under peak load some prompts and completions go to an endpoint that is not
covered by the enterprise DPA. Volume is highest exactly when this happens.

Revert when the quota increase lands. Nobody owns chasing it.
