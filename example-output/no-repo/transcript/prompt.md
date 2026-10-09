# Transcript synthesis prompt (phase A′)

Runs between phase A and phase B. A separate invocation with no shared state: it
receives the pack and the session specification, and nothing else. It has no memory
of producing the pack, which is the point — it reads the pack as the room would.

Nothing in this phase touches the pack. It writes a transcript about it.

---

/validation-session A validation session has been held about the review pack in ./input/pack. The cast, the facts they hold that are written down nowhere, the beliefs they hold that are wrong, and the rules governing which of those surface are in ./input/session-spec.md.

Record the transcript of that session.

Read the pack first and take its measure: how many documents, how many findings, how findings are identified, and which of them carry evidence rather than assertion. The session must be specific to this pack — every finding discussed must exist in it, every quotation must be accurate, and every count must be right.

Then apply the rules in section 4 of the specification to decide what the room supplies, where the room reaches a wrong conclusion, and where the room corrects the pack. Meet the per-cell requirements in section 5 for cell run5.

Write ./output/transcript.md (the room only), ./output/facilitator-notes.md (everything written afterwards), and ./output/session-manifest.json.

The facilitator is Brett Crawley, Principal Application Security Engineer.
