# Directed pass prompt

Run after validation. A separate invocation with no shared state: it receives the
current pack, the original context bundle, and a brief written by the reviewer.

The brief is substituted in from `directed/<name>.md`, taking everything after
the `---` separator in that file. `./output` is pre-seeded with the pack, so an
untouched document stays complete.

Two kinds of brief run through this phase, and the deliverable differs:

**A scenario brief** gives concrete misuse stories — organisational usage fused
with mechanism — and asks whether the pack covers them. The stories come from a
person because they live where no document does: how the teams actually use the
system, joined to what the code actually does. The deliverable is a verdict per
scenario: covered (cite the finding), refuted (show why the mechanism prevents
it), or a new finding with the full treatment.

**A proof brief** names an asserted chain and asks for it to be demonstrated or
broken against the repository, step by step. The deliverable is the
demonstration — each step shown feasible with the evidence that makes it so — or
the specific step where the chain fails and why. A severity argument that turns
on feasibility is settled here, not in the register.

What no longer runs through this phase is a brief naming an *area* to look at
again. Measured result, 2026-09-05: five of the six questions in the original
area brief were phase-1 findings by the next generation, including its central
hypothesis, because everything an area brief teaches gets encoded upstream. See
the README, Phase 3.

---

/secure-privacy-by-design /security-architect /threat-modeling A threat model review pack already exists in ./input/pack. The material it was built from is in ./input/context. The reviewer has written a directed brief for a second pass, below.

{{FOCUS}}

Work on the copy of the pack already in ./output. Every document must still be present and complete when you finish, and unchanged documents must stay as they are rather than being rewritten.

For a scenario: test it against the pack and the code, and return one of three verdicts, stated plainly. **Covered** — name the finding that already carries it and what, if anything, the scenario adds. **Refuted** — show the mechanism that prevents it, with file and line. **New** — add the finding with the full heading, example threat, mitigation and register row. Do not stretch an existing finding to claim coverage it does not have; an injection finding does not cover a harm that needs no attacker.

For a demonstration: walk the chain step by step against the repository. Each step is either shown feasible, with the code or configuration that makes it so, or is the point where the chain breaks — in which case say so and stop claiming the chain. Adjust the register to whatever the demonstration establishes, in either direction.

Where this pass extends an existing entry, amend that entry and keep its identifier. Where it finds something genuinely new, add a new entry. Where it confirms an existing entry without adding anything, say so rather than restating it.

**If this pass finds nothing beyond what the pack already contained, say that plainly and do not manufacture findings to justify the exercise.** A scenario the pack already covers is a good result for the pack and an honest one for the pass, and reporting it that way is what makes the verdicts worth believing.

Record what you examined, what you found, and what you looked at and dismissed, in a short section at the top of the threat model. Tag every claim from this pass so its provenance survives.

Keep all markdown and all mermaid diagrams render safe.

The reviewer is Brett Crawley, Principal Application Security Engineer.
