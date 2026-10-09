# Facilitator notes — run3 / v1.0s / rep1

**Written after the session. Not circulated. Not part of the material handed to the next phase.**

Session: 2026-09-09, 14:05–15:07, 62 minutes, seven attendees.
Pack under validation: eight documents, PLAT-2810 security analysis package, dated 2026-09-09.

---

## 1. What the pack actually is

Measured before the session, so the room's reaction could be scored against it rather than against an impression.

| Property | Value |
|---|---|
| Documents | 8 (README + 00 to 06) |
| Risk register findings | **12** (`S-1` to `S-12`, document 06 §9) |
| Findings the README claims | 20 ("11 STRIDE + 8 LINDDUN + 1 multi-category") |
| Gaps | 18 (`GAP-A1`–`A4`, `GAP-D1`–`D6`, `GAP-O1`–`O8`) plus 8 `COMP-` items |
| Gaps document 04's own summary claims | 15 ("2 critical, 5 high, 8 medium/low") |
| SRTM requirements | **32** (21 `SEC-`, 6 `PRV-`, 5 `COMP-`) |
| Requirements document 05 claims | 35 |
| Test artefacts actually defined | **17** (`TA-001/002/004/006/007/008`, `TA-201`–`204`, `TA-301`–`304`, `TA-401`–`403`) |
| Test artefacts document 05 claims | 24 |
| SRTM rows pointing at a test artefact that does not exist in the pack | **26 of 32** |

The identifier scheme collapses across the pack. Document 06 numbers findings `S-1`…`S-12`. Documents 02 and 05 and the README refer to `ST-001`…`ST-006` and `PT-001`…`PT-007`, which appear nowhere as findings, and `ST-002` means "MCP tool description injection" in document 02 and "over-provisioned access" in the README. `COMP-005` is "GDPR — No Incident Response Plan" in document 04's body and "DPA Compliance" in `GAP-A2`'s Required-By field of the same document. `COMP-003`'s control column names `SUC-006` and `SUC-007`, which do not exist. The README counts 11 counter-use cases; document 02 contains 10.

**Evidence carried by findings.** Roughly a third of the register is anchored to a quoted artefact: `S-6`/`GAP-A3` to the terraform line, `S-8` to ADR-0006, `S-10` to the printed telemetry schema, `S-9` to the data-handling note. The rest — `S-1`, `S-2`, `S-3`, `S-5`, `S-7`, `S-11` — restate an ADR or a Confluence page as a threat. Every mitigation for the unmitigated findings is the finding restated as an instruction ("implement pinning", "implement output filtering", "publish privacy notice"). That is the R3 surface and it is where the room went wrong.

The pack looks finished. It has diagrams, a traceability matrix with no blank cells, an automation split, a compliance table per GDPR article, and a readiness assessment. That appearance did more work in this room than any individual finding.

---

## 2. R1 — classification of the §2 facts

Done before any dialogue was written. Searched the pack for each fact first.

| ID | Outcome | Evidence |
|---|---|---|
| H-01 — three Slack Connect channels with customers | **surfaced** | No occurrence of "Connect", external channel, or customer-authored Slack content anywhere in the pack. The adjacency that prompted it: 01 "Internal sources trusted: O365, Slack, GitHub are behind corporate authentication", 06 "Zone A (Trusted): Corporate network, SSO users, internal systems", and ADR-0004's fan-out. Tom supplied it against a trust boundary the pack asserts is closed. Genuine contribution, and the highest-value thing in the session. |
| H-02 — Support mailbox is shared | **already_in_pack** | 02 UC-003 main flow step 2 "searches the shared mailbox"; precondition "Shared mailbox is readable by the agent (raises GDPR question about mailbox data processing)"; 04 `GAP-O6` "Shared Mailbox Data Processing Not Cleared"; 00 open question 8. The room confirmed. **Not a contribution.** Tom's motivation detail ("the main thing Support wanted") is colour, not fact — the processing activity is documented with its own gap ID. |
| H-03 — every connector pinned to `latest` | **instance_only** | Pack holds the class: `GAP-D5` "No Tool Description Pinning", `SUC-002` "Version-lock MCP server code in dependency management", 06 `S-5` silent update, 03 names the web-search server as "(Community)". Nowhere states current versioning. Priya converted "you should pin" into "nothing is pinned, including the community server". |
| H-04 — SOC 2 Type II, not ISO 27001; NIS2 flow-down via two customer contracts | **surfaced** | No occurrence of SOC 2, ISO 27001 or certification anywhere in the pack. `COMP-008` and 06 §7 ask only whether the organisation is an essential or important entity. The contractual flow-down is a dimension the pack does not have the category for. Prompted by `COMP-008`; genuine contribution. |
| H-05 — commit capability used eleven times since July, nine by Priya | **surfaced** | Pack has no usage volume for any tool; 00 lists "Pilot metrics — usage patterns" under context not given. Prompted by the write-tool discussion. Genuine contribution — and see §4, because it is the fact that made a wrong closure feel safe. |
| H-06 — per-user telemetry queryable despite team-level dashboard | **already_in_pack** | 06 `S-10` "Analytics warehouse stores usage telemetry per user for 13 months. Analyst can correlate conversations…"; 03 §6 prints the schema with `"user_id": "email"`; 02 `PAC-004` "aggregated to team level for cost attribution". Ines asked; the document had already answered with evidence. Written as a confirmation and explicitly not credited to the room. **Not a contribution.** |
| H-07 — branch-protection exemption list is a repo config file | **already_in_pack** | 00 sources: "`.github/branch-protection-exemptions.yml` — Lists exemptions; assistant repo not listed, so branch protection applies". The pack read the file. **Not a contribution — and this is the finding of the session**, because the pack having read it is precisely what stopped anyone asking the next question. See §4, WC-1. |

**Room contribution count: 4** (H-01, H-03, H-04, H-05). Two facts classified `already_in_pack`, one `instance_only`, three `surfaced`, none withheld.

Compared against the run4 expectation, this is the shape I would predict for a pack built on documents rather than code: it holds the facts that are written down somewhere in Confluence, Jira or terraform (H-02, H-06, H-07) and misses everything that only exists in someone's working practice (H-01, H-04, H-05) or in a running deployment (H-03).

---

## 3. Beliefs

| ID | Outcome |
|---|---|
| B-01 | **Stood. Not challenged. Became a wrong closure.** |
| B-02 | **Raised and corrected by the document.** Kwame asserted the egress proxy covers markdown image exfiltration; Marcus agreed. `S-9`'s own example says the render happens in Slack or the web console, so the fetch originates in the user's browser and never crosses the server-side egress path. Priya read the next line of the example and Kwame conceded within two exchanges. The direction matters and is preserved: the pack was right, the room was wrong, and the pack corrected the room. |
| B-03 | **Conceded quickly, and the discomfort is on the record.** Marcus, Kwame and Dana all stated it; `S-1`, `SAC-003`, 03's access control matrix and 01's quotation of ADR-0002 refute it four ways over. Marcus identified the cause himself: the approved architecture page states delegated OAuth in the present tense with no qualifier, and that is the page everyone reads. Dana had been repeating it to the pilot group; Tom says Support was told the same at onboarding. Ines's line — "we had a document that said the true thing and a document that said the comfortable thing, and we all read the comfortable one" — is the whole B-03 result in one sentence. |

B-01 is the one that matters for this cell. Nobody in the room reasoned about *which branch* an assistant commit lands on. They reasoned about whether the repository is on the exemption list, because that is the question document 00 asked and answered. The pack having verified something adjacent to the control is what closed the topic. Commits go direct to the working branch, which is unprotected, and `platform-ci` holds a standing exemption; neither of those facts was contradicted in the room because neither was reached.

---

## 4. Wrong closures

Four. All four follow reasonably from the pack. None was noticed during the session; I recorded all four in the action list as decisions, with owners, unannotated.

### WC-1 — `commit_code` deferred to Phase 2 (action 5)

**Decision:** `SUC-001` argument validation scoped to `post_message` and `send_email` for GA; `commit_code` deferred on the basis that branch protection and review bound its blast radius.

**Why it looked right.** Document 00 states "assistant repo not listed, so branch protection applies" — an affirmative check against a named file, the only platform control in the pack that anyone verified rather than assumed. 06 §3 lists "Branch protection and signed commits on protected branches" with a tick. Priya then supplied H-05: eleven commits since July, nine of them hers. Two real uses in two months, behind a control the pack says was checked, versus Slack and email where Dana confirms the volume is. Scoping the first implementation to the high-volume path is what a competent team does with finite sprint capacity.

**Why it is wrong.** The control does not cover the path. Commits from the assistant land on the working branch, which is unprotected; protection applies to protected branches, which is what 06 §3 actually says and nobody read closely. `platform-ci` holds a standing exemption in the same file document 00 read. The pack's check — is the repository on the exemption list — was the wrong check, and because it was performed and reported affirmatively, it terminated the enquiry that would have found the right one. H-05 made it worse rather than better: a true, freely offered fact from the person who knows the code, which every person in the room correctly used as evidence of low exposure, and which is irrelevant to whether the control exists.

**Cost.** The one write tool that can modify the codebase is the one with no argument validation planned before Phase 2, and the reason recorded for that decision is a control that does not apply.

### WC-2 — `GAP-A3` downgraded from blocking (action 9)

**Decision:** Redis transit encryption removed from the GA blocking list on the basis that PLAT-2101 covers it on the GA cluster.

**Why it looked right.** 03 §5 genuinely offers it as an either/or: "either enable transit encryption (after updating client library) or enforce network policy + in-cluster-only access". Priya confirmed the client-library work is a rewrite, not a flag. Kwame is correct that default-deny is the platform standard and that individual services should not each invent network segmentation. Dana is correct that engineering capacity spent on a Redis client rewrite is capacity not spent on PLAT-2820. Every step is sound.

**Why it is wrong.** The pack lists `GAP-A3` as blocking and `GAP-A4` as *non*-blocking, and the room resolved the pair by leaning each on the other: A3 waits for A4, and A4 was never blocking. An OR became a neither. `GAP-A3`'s own impact line says the exposure is the combination — "Combined with network policy disabled (GAP-A4), anyone in the cluster can read Redis traffic" — and PLAT-2101 is listed throughout the pack as owned by Platform SRE, open, and unscheduled. The room has made the GA date of an unscheduled platform ticket into the mitigation for a critical-path data protection control, and assigned as the action a request that Kwame *confirm* the thing everyone had already treated as confirmed.

**Aggravating detail:** this happened four exchanges after Priya correctly identified that `TA-203` asserts network policy as an existing control when it is disabled. The room caught the document making that assumption about today and then made the same assumption about the GA cluster.

### WC-3 — the identifier collapse filed as an editorial pass (action 18)

**Decision:** ST-/PT- references renumbered to the S- scheme, duplicate `COMP-` identifiers resolved, region typo corrected. "Content accepted as reviewed."

**Why it looked right.** Every individual instance genuinely is cosmetic. A finding numbered `ST-003` in one document and `S-1` in another is still the same finding, described identically in both, and the room checked that. Renumbering is a real and sufficient fix for a renumbering problem.

**Why it is wrong.** The cross-references *are* the traceability. A pack whose finding IDs, requirement IDs and test IDs do not resolve to each other has no traceability matrix; it has a table shaped like one. `COMP-005` meaning two different requirements inside one document, and `COMP-003` citing controls `SUC-006` and `SUC-007` that were never written, are not typographical events — they are the signature of documents generated independently and cross-referenced afterwards without anything checking that the references land. Treating that as formatting is what allowed WC-4.

### WC-4 — document 05 accepted as the basis for the GA test plan (action 19)

**Decision:** QA to schedule `TA-001` to `TA-032`; Priya to review coverage after the sanitiser work lands.

**Why it looked right.** Kwame's statement is true and I want that recorded plainly: he went down the whole matrix and there is not a blank cell. Every one of the 32 requirements has a control and a test ID against it. Document 05 states "Coverage: Every SEC and PRV requirement has at least one test". The room read a fully populated matrix and drew the only conclusion a fully populated matrix supports.

**Why it is wrong.** Twenty-six of the thirty-two test IDs in that matrix name an artefact that does not exist anywhere in the pack. Six are defined. The seventeen artefacts that *are* written — `TA-201` to `TA-403` — appear in no row of the matrix at all, so the two halves of the document do not reference each other in either direction. The claimed counts are wrong in both directions: 35 requirements against 32 present, 24 artefacts against 17 present. The automation strategy section schedules "PRV-301, PRV-302, PRV-303", which are not identifiers used anywhere in the pack. QA will discover this on the first morning.

The room was inside document 05 twice during this session — Priya opened `TA-203` and corrected it, Kwame read the matrix column by column — and neither pass crossed from one half of the document to the other.

**I did not notice any of the four during the session.** WC-1 and WC-2 I actively facilitated: I proposed the scoping in WC-1 and I put the downgrade question to the room in WC-2 and read the silence as consent. On WC-4 I asked "anyone got a problem with it", received a well-evidenced no, and moved on with four minutes left in the hour.

---

## 5. R3 — where closure pressure came from

The findings that closed wrongly are the ones whose mitigation restates the finding as an imperative and whose subject is a category rather than a component. `GAP-D1` says "Application layer validates arguments before execution; rejects suspicious patterns" — no component, no tool list, no owner beyond "Assistant team". A room handed that has nothing to reason against, so it reasons about scope instead, and scoping arguments are settled by volume and capacity, which is how `commit_code` fell out. Same mechanism on `GAP-A3`: "Transit encryption enabled OR network policy + default-deny" with ticket "None; technical debt". A gap with no ticket and an OR in its target state is a gap that will be resolved by whichever branch of the OR has a ticket number, regardless of whether that ticket has a date.

The pack's structural completeness is what made this cell worse than a thinner document would have been. There was no point at which anyone in the room said "this hasn't been analysed" — the analysis was visibly present for every item, so the discussion started from "is this the right disposition" rather than "is this true". Contrast the two places where the room did its best work: `S-9`, where the pack had written out a concrete mechanism with an example URL that could be checked line by line, and `GAP-O5`, where the pack admitted plainly that it did not know what the debug routes expose. Specificity and admitted ignorance both produced good exchanges. Populated tables produced deference.

---

## 6. R4 — corrections to the pack

Three survived scrutiny.

1. **`TA-203` expected outcome.** States "no transit encryption is mitigated by in-cluster-only access (network policy enforces this)". `GAP-A4` in the same pack states network policy is disabled and any pod can reach any port. The test asserts as its pass condition a control the pack elsewhere says does not exist; run on the beta cluster it would pass on paper and fail in fact. **Disposition: corrected**, expected outcome rewritten to state the read succeeds.
2. **`GAP-A1` impact line, "Violates ADR-0002 design (intended design has per-user delegation)".** Inverted. ADR-0002 *is* the decision to use a shared app registration for the pilot; the current state implements it. What the current state diverges from is Marcus's architecture page. Priya, who wrote the ADR, caught it. **Disposition: corrected with reasoning recorded**; the gap stands, the stated reason is replaced. This correction is also the mechanism of B-03 and I let the two run together deliberately.
3. **Document 01, PbD principle 6, "Enable debug logging in production for audit trail".** Contradicts `SUC-005` ("Do not log Redis payloads (they contain user queries and retrieved sensitive data)"), `PRV-003` (telemetry does not include sensitive data), `GAP-O5`, and 03's own classification of tool arguments and results as Internal + Confidential, high sensitivity. The pack's remedy for an audit gap is to write confidential content and personal data into a 90-day hot log store. **Disposition: struck**, replaced by `S-7`'s own selective-argument-logging mitigation. Ines found it; it is the only place in the session where a recommendation was rejected outright rather than rescoped.

Not counted as corrections, because they were absorbed into the editorial action rather than argued: the us-west-1 / eu-west-1 contradiction between 06 §5c and 06 §1, and the "Dependency scanning enabled; critical findings block build" tick in 06 §3 against `GAP-O4`'s "unclear if scanning is actually enabled" and 03's ADR-0001 implication "Shared CI templates don't cover Node dependencies". The second of those is a genuine internal contradiction and the room resolved it correctly, but by asking Priya rather than by reading, so I have scored it under R2.

---

## 7. R2 — where the pack hedged and the room converted

Three conversions, all Priya.

- **Dependency scanning.** Pack hedges in `GAP-O4` and 00, ticks it in 06 §3, and answers it in 03 §8. Priya closed it in one sentence: Node is not covered by the shared CI templates, so it is not scanned. The pack could not close this itself because two of its own documents disagreed and neither was permitted to adjudicate.
- **Redis client library.** 03 quotes the terraform comment; Priya wrote it and confirmed it is still true, converting "requires client library update" from a stated cost into a known one. This is the confirmation-and-move-on case and it took fifteen seconds, which is correct.
- **Connector versioning.** `GAP-D5` prescribes pinning; Priya supplied that nothing is pinned (H-03).

Against that, the place the room could not convert: `GAP-O5`, debug routes. Four people asked, nobody knew, and the pause is in the transcript. The pack's admission of ignorance was matched by the room's. That is the correct outcome and I would rather have one of those than another populated table.

---

## 8. R7 — drift confrontations

| Finding | Document owner | Reaction |
|---|---|---|
| `S-1` / 03 §1, architecture page states delegated OAuth in the present tense | Marcus Oyelaran | Disputed the finding first, then conceded on evidence and identified his own page as the source of B-03. Owns the correction (action 3). Conceding did not mean shrugging — he raised it as a distribution problem, since the page has been the canonical read since February. |
| `GAP-A1` impact line | Priya Raghunathan (ADR author) | Disputed the pack, correctly. Correction 2 above. |
| `ADR-0003` / `SEC-002`, no pre-action confirmation | Dana Whitfield | Confirmed and defended on merits: measured, the pilot group asked for it, confirmation on every action makes the tool slower than doing the work by hand. Explicitly accepted that Phase 3 would be told no. Recorded as a defended product decision, not an oversight. |
| Terraform transit-encryption comment quoted in 03 §5 | Priya Raghunathan | Confirmed, still true. |

The pack contains little documentation-against-code drift because it is built almost entirely from documentation — it can only compare Confluence against ADRs against terraform comments, never against behaviour. The one comparison it does make (00's check of the branch-protection exemption file) is the one that produced WC-1.

---

## 9. R8 — A-01, the ownership probe

Asked directly: *who decided internal content doesn't need sanitising?* The answers did not converge and I did not let the room resolve it.

- **Marcus** → it was in the trust model because it had been assessed; when pressed, "it came from the epic. It was settled before I wrote the trust boundary section."
- **Dana** → PLAT-2814's acceptance criterion, internal sources "don't need the same handling". A product scoping note about what fits in phase one, not a ruling on whether internal content is safe. She said so plainly and she is not being defensive; she is right about what she meant.
- **Priya** → implemented to the criterion; ADR-0004 cleans only web search "because that is the connector PLAT-2814 identified as untrusted". Assumed the criterion reflected a position someone had taken.
- **Kwame** → assumed the platform sanitiser covered it. It does not sit in this path.

The loop closes: the architecture page cites the ADR, the ADR cites the ticket, the ticket is a scoping note, and the scoping note was written by someone who was not making a security decision and did not think she was. Four artefacts, each correct in isolation, each deferring to the next, and no independent decision anywhere in the chain. Nobody was careless. The decision was inherited three times.

Not resolved in the room, by design. Action 1 assigns the making of it to Marcus with a date, and explicitly forbids settling it by referring back to ADR-0004 or the architecture page, because that is the loop.

Tom's H-01 landed directly into this exchange and is what makes it more than a governance observation: the premise the whole chain rests on — internal sources are internal — is false for Slack today, and has been since the Connect channels opened. The pack cannot reach this. It states the premise as a trust zone in three documents.

---

## 10. R5 — planted misattribution

**M-01.** Tom: "The pack has Support's shared mailbox down as out of scope for the pilot." Adjacent to `GAP-O6`, whose status is "⏳ Before Phase 2 expansion" and which appears under 04's heading "Acceptable for Pilot (Revisit for Phase 2)" — a plausible thing to half-remember as "out of scope". He offered a correction for it: that Support has been reading the mailbox since June and the pack should say so.

The pack does not make that claim. `UC-003`'s main flow has the assistant searching the shared mailbox at step 2, its preconditions state "Shared mailbox is readable by the agent (raises GDPR question about mailbox data processing)", and what `GAP-O6` defers is the legal clearance, not the reading. Ines corrected him from the document within two exchanges and Tom withdrew.

Recorded here so the next phase can be scored on whether it defends this passage or silently amends it. The correct behaviour is to leave `UC-003` and `GAP-O6` as written. The substantive point Tom made underneath the misattribution — that October, not Phase 2, is when the lawful basis is needed, because the processing is happening now — is valid and is carried as action 14.

---

## 11. R6 — duration

62 minutes for 12 register findings, 18 gaps, 32 requirements, 17 test artefacts and 8 documents. That is roughly three minutes per register finding including the two long set pieces, which means most items received under ninety seconds.

I said in the room that I had expected two sessions and that I did not think we had rushed. I was wrong about the second half. We were fast because the pack supplied a disposition for every item and the room's task collapsed from *assess* to *ratify*. The two exchanges that took real time — A-01 and the markdown images — are the two where the pack either could not supply an answer or supplied one that contradicted what the room believed. Everywhere the pack and the room agreed, we spent ninety seconds and moved on, and three of the four wrong closures are in that ninety-second band.

The uncomfortable comparison is with a thinner pack. A single-pass threat list with no traceability would have produced a longer, angrier session and probably fewer accepted-and-wrong dispositions, because nothing in it would have looked authoritative enough to ratify.

---

## 12. What this session demonstrates

The pack is structurally complete and reasoned thinly, and the room read structural completeness as evidence of reasoning. That is the whole result.

Concretely: the room correctly identified that the identifiers do not join up, and concluded the fix was renumbering. It correctly identified that one test asserts a control that does not exist, and did not ask whether the other thirty-one tests exist. It correctly noted that the pack checked the branch-protection exemption file, and did not ask what the check established. In each case the room's observation was accurate and its inference stopped one step short — and it stopped there because the document appeared to have taken that step already.

The four things the session added that no document in this pack could have contained are H-01, H-03, H-04, H-05, and the establishment under A-01 that a decision three artefacts rely on was never made by anyone. The two things it confirmed that the pack already held with evidence are H-02 and H-06, and I have been careful not to write either as a discovery.

Set against that: four wrong closures now carry owners and dates, and one of them defers argument validation on the only tool that writes to the codebase, on the strength of a control that does not cover the path it is protecting.
