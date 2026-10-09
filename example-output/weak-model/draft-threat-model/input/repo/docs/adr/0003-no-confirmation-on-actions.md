# ADR-0003: Actions execute without confirmation

**Status:** Accepted · **Date:** 2026-05-21

## Context
The first build asked the user to confirm every write. The pilot group measured
themselves and found the assistant slower than doing the work by hand. Two of
them stopped using it.

## Decision
Write actions execute directly. The system prompt tells the model not to ask.
Actions are shown in the conversation afterwards, which is PLAT-2825.

## Consequences
Anything that can influence the model can cause a write. We accept this for the
pilot on the basis that a human is present and reads the action list.

## Alternatives considered
Confirm only on irreversible actions. Rejected as fiddly to define at the time.
Worth revisiting; the definition is not actually that hard.
