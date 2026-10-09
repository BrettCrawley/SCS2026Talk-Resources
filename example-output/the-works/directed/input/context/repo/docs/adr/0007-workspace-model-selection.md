# ADR-0007: Workspaces choose their own model

**Status:** Accepted · **Date:** 2026-07-02

## Context
PLAT-2822 requires the smallest model that gives acceptable answers, and model
spend is billed through above the plan allowance. Teams asked to control it.

## Decision
`model` is a per-workspace configuration value, selected from the supported list.

## Consequences
A workspace can select a cheaper model at any time with no review. Answer quality
and the model's handling of unusual content both vary across the list. We do not
measure either. Support is currently on `aurora-1-mini`.
