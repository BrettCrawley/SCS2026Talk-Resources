# ADR-0002: One app registration for the pilot

**Status:** Accepted · **Date:** 2026-05-06

## Context
PLAT-2820 specifies per-user delegated OAuth for every connector, and the
Confluence architecture page describes that as how the assistant works. Identity
Platform have not scheduled the work. We asked on 2026-04-18 and it is not in
their next two quarters.

Without credentials the pilot cannot read anything, and the pilot date is fixed.

## Decision
Use one app registration with application permissions across all connectors.
Calls carry the requesting user's ID as an argument so the call sites do not
change when delegation lands. Mail is sent with send-as so it appears to come
from the user.

## Consequences
The assistant can reach everything any pilot user could reach, and more. A user
can obtain content through the assistant that they could not open directly.
Attribution in the downstream systems shows the service principal, not the user.

PLAT-2820-3 tracks the migration. Do not take this to GA.

## Not written back
This contradicts the Confluence architecture page, which describes delegated
credentials in the present tense. Nobody has updated it.
