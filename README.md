# Security Champion Summit 2026

Talk materials, evaluation harness and demonstration assets.

**System under test:** PLAT-2810, a fictional internal AI assistant with connectors to Office 365, Slack, GitHub, Confluence and web search. Documentation, tickets and a pilot implementation, written so that they disagree with each other in specific, findable ways.

## Layout

```
talk/            what goes in front of the audience
  diagrams/        the four trust-boundary diagrams
eval/            the evaluation, and everything needed to reproduce it
  README.md        how to run it
  contexts/        thin, rich, rich-no-repo. The repo lives under rich/
  prompts/         the four prompts, written to be shown to attendees
  skills/weak/     the single-pass comparison skill
  validation/      session transcripts, one per run
  bin/, config/    harness
  results/         output lands here
facilitator/     answer keys. Not for distribution
```

## The argument

A good threat model needs four ingredients: **context**, **method**, **reasoning** and **the room**. Remove any one and you still get a document that looks finished. Each run removes exactly one.

| Run | Missing | What it costs |
|---|---|---|
| 1 | Context | Correct but uncalibrated. Cannot tell an absent control from an undocumented one |
| 2 | Method | Threats with nothing to trace to. The review argues from belief |
| 3 | Reasoning | The shape survives, the depth goes, and nobody can see it |
| 4 | Nothing | The target state |
| 5 | The repository only | Optional. Isolates what code contributes |

## Order of work

1. Run phase v1 for every cell. See `eval/README.md`.
2. Hold the validation sessions. `eval/validation/` has the cast, the method and four drafted transcripts to reconcile against real output.
3. Run phase v1.1 with the transcripts fed back.
4. Build the scorecard, complete the evaluation reports in `facilitator/evaluations/`, update the numbers on slides 3 to 7.

## Before presenting

- `eval/README.md` opens with flag verification. Do that first.
- The prompts in `eval/prompts/` are handout material. They are written to be read.
- `facilitator/facilitator-code-map.md` is the answer key for the repository. Do not put it in the repository.
