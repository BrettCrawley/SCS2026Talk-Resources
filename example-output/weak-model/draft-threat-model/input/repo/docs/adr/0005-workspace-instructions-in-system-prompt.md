# ADR-0005: Workspace instructions live in the system message

**Status:** Accepted · **Date:** 2026-06-11

## Context
Admins set tone and local policy per workspace. Placed in the user message they
were routinely ignored, particularly by the smaller models.

## Decision
Append the workspace `customInstructions` to the system message.

## Consequences
A workspace admin can write anything into the system prompt. The field is free
text with no validation and no length limit. In practice admins are trusted
staff, and the alternative is a feature that does not work.
