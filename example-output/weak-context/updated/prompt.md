# Validation feedback prompt

Run after the validation session. A separate invocation with no shared state: it
receives only the v1 pack and the transcript.

---

/secure-privacy-by-design /security-architect /threat-modeling A validation session has taken place against the review pack in ./input/pack. The transcript is in ./input/transcript.

Update the pack from the discussion in that transcript. Merge corrections, record confirmations, severity changes with their rationale, accepted risks with owners, and any new findings raised in the session. Where the session contradicts an assumption the pack made, say so explicitly rather than quietly editing it.

Bump the version, include a delta table, and tag every claim derived from the session so its provenance survives.

Keep all markdown and all mermaid diagrams render safe.

The reviewer and facilitator is Brett Crawley, Principal Application Security Engineer.

Write the updated documents into ./output as markdown files.
