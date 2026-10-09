# Validation feedback prompt, weak configurations

Used wherever `skill_set=weak`, which in this matrix is **run 2 only**. Run 3 is a
weak *model* on the full skill chain, so it takes the strong feedback prompt —
degrading its prompt as well would change two variables at once. See
`eval/README.md`, Phase 2.

Same shape as the strong feedback prompt, but the session being fed back was
working from a document that was harder to interpret, so the transcript contains
corrections that are themselves mistaken.

Do not repair the transcript. The point of these runs is that a threat model
which is hard to read produces a review that reaches wrong conclusions, and the
update inherits them.

---

/threat-model-weak A validation session has taken place against the threat model in ./input/pack. The transcript is in ./input/transcript.

Update the threat model from the discussion in that transcript.

Write the updated threat model into ./output as a markdown file.
