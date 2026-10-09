
/secure-privacy-by-design /security-architect /threat-modeling A threat model review pack already exists in ./input/pack. The material it was built from is in ./input/context. The reviewer has written a directed brief for a second pass, below.

Two scenarios. Test each against the pack in ./input/pack and the repository in ./input/context, and return a verdict per scenario: covered, refuted, or new.

**Scenario 1 — the afternoon draft carries the morning's incident.**

A Support agent starts a conversation at 09:30 about an ongoing incident: the assistant retrieves GitHub issue threads on an unreleased security fix, internal Slack discussion of which customers are affected, and mail about the remediation timeline. The incident quietens. At 15:00, in the **same conversation** — because conversations last 24 hours and picking the thread back up is the designed behaviour, per ADR-0008 — the agent asks the assistant to draft a reply to a customer about an unrelated billing question. The workspace instructions say to be warm, concise, and sign off as Meridian Support.

The draft is composed against a context that still carries the morning: the unreleased fix, the affected-customer list, the remediation dates. `tool-guidance.md` tells the model retrieved content is authoritative. Nothing in `turnLoop.ts`, `history.ts` or `promptAssembly.ts` distinguishes the morning's purpose from the afternoon's.

There is no attacker in this scenario. The question is what crosses the purpose boundary and reaches the customer.

Answer specifically: which existing finding, if any, covers harm from accumulation **without** an injected instruction — check whether the injection-persistence and context-rot findings actually cover it, or only share its mechanism. Whether anything in the code partitions context by task or purpose. What the mitigation is if the finding is real — a purpose boundary needs a deterministic form: fresh session per task type, context partition, or composition restricted to cited sources — and which the pilot could actually ship. And the privacy half: personal data retrieved for the incident is being processed again for an unrelated purpose; say what that is under GDPR and who needs to know.

**Scenario 2 — whoever writes the most decides what the model reads.**

`/search` fans out to every connector and returns the first eight chunks after a flat merge (`mcp/server.ts`, `retrieval.ts`, limit 8). Four of the five sources accept externally authored text. An attacker who wants to steer the assistant does not need an instruction payload that survives sanitisation — they write **volume**: a dozen plausible pages, comments and messages matching the phrases a target team will predictably ask about ("release readiness", the incident number, a customer name). The merge has no per-source cap, no provenance weighting, no dedupe. Their prose becomes six of the eight chunks, and the model — told retrieved content is authoritative — answers from it.

This is share-of-voice as an attack, distinct from injection: every individual chunk can be entirely instruction-free and still control the answer.

Answer specifically: whether any existing finding treats the merge and its ranking as a security control point, rather than as a delivery mechanism for injected instructions. What bounds one author's share of the eight slots — trace it in the code, or show that nothing does. What the deterministic mitigation is at the merge: per-source caps, provenance-weighted ranking, authored-recency limits, dedupe by author. And whether the eight-chunk limit makes this easier or harder for the attacker than an unbounded merge would be — answer it, don't wave at it.

For both scenarios: if the pack already covers it, name the finding and stop. Do not stretch an injection finding to cover Scenario 1 — it has no injection — and do not stretch a sanitiser finding to cover Scenario 2 — it has nothing to sanitise.

Work on the copy of the pack already in ./output. Every document must still be present and complete when you finish, and unchanged documents must stay as they are rather than being rewritten.

For a scenario: test it against the pack and the code, and return one of three verdicts, stated plainly. **Covered** — name the finding that already carries it and what, if anything, the scenario adds. **Refuted** — show the mechanism that prevents it, with file and line. **New** — add the finding with the full heading, example threat, mitigation and register row. Do not stretch an existing finding to claim coverage it does not have; an injection finding does not cover a harm that needs no attacker.

For a demonstration: walk the chain step by step against the repository. Each step is either shown feasible, with the code or configuration that makes it so, or is the point where the chain breaks — in which case say so and stop claiming the chain. Adjust the register to whatever the demonstration establishes, in either direction.

Where this pass extends an existing entry, amend that entry and keep its identifier. Where it finds something genuinely new, add a new entry. Where it confirms an existing entry without adding anything, say so rather than restating it.

**If this pass finds nothing beyond what the pack already contained, say that plainly and do not manufacture findings to justify the exercise.** A scenario the pack already covers is a good result for the pack and an honest one for the pass, and reporting it that way is what makes the verdicts worth believing.

Record what you examined, what you found, and what you looked at and dismissed, in a short section at the top of the threat model. Tag every claim from this pass so its provenance survives.

Keep all markdown and all mermaid diagrams render safe.

The reviewer is Brett Crawley, Principal Application Security Engineer.
