# PLAT-2810 — Security Review Pack Validation Session

**Date:** 2026-09-09 · **Time:** 14:00–15:35 · **Duration:** 95 minutes
**Location:** Meeting room 4 and dial-in
**Facilitator:** Brett Crawley, Principal Application Security Engineer

**Attendees**

| Name | Role |
|---|---|
| Brett Crawley | Principal AppSec Engineer (facilitator, author of the pack) |
| Dana Whitfield | Epic owner, Product |
| Marcus Oyelaran | Lead architect |
| Priya Raghunathan | Senior engineer, built the pilot |
| Tom Egerton | Engineering manager, Support |
| Ines Ferreira | Data Protection Officer |
| Kwame Osei | Security Champion, Platform |

**Material reviewed:** `PLAT-2810 Internal AI Assistant — Security Review Pack`, version 1.0, dated 2026-09-09. Eight documents plus the README index. 72 findings across ten buckets — 14 Critical, 41 High, 16 Medium, 1 Low, all recorded Open. 30 gaps, 58 test artefact definitions, and a candidate register of 139 rows. Circulated 09:20 this morning.

**Scope of this session:** the six launch gates in `06-threat-model.md` §9, the regulatory section, and the four questions the pack asks first. The remainder of the register was not walked.

---

## 1. Opening

**Brett:** Before anything else, the thing everyone should hold in their head while we do this. The pack was built from two files. `plat-2810-epic.md`, which is two and a half kilobytes, and one diagram. No repository, no Confluence, no schemas. It says so on the front of document 00 and it says so four more times after that. So a lot of what you're going to read is the pack telling you what it could not see.

**Marcus:** That's a fairly large caveat for something with seventy-two findings in it.

**Brett:** It is, and it's why we're in this room. What I want out of the next ninety minutes is three things. Corrections — where it's wrong, say so and say why. Facts — there are twenty open questions in document 00 and most of them are things one of you already knows. And owners. I'd rather leave with eight owned items than forty agreed ones.

**Dana:** Can I start with an objection, because I've had it since about ten past nine.

**Brett:** Go.

**Dana:** Page one of the review — "every action must be confirmed before it executes." We tested that. We put a confirm dialog on every action in week two of the pilot and people stopped using it. That's not a preference, it's the reason PLAT-2817 says what it says. If the answer is to undo the one thing we learned from the pilot, then the correction is: confirm on external sends, and nothing else.

**Brett:** It doesn't say that.

**Dana:** It says it somewhere.

**Brett:** It doesn't. AI21 — "Make friction proportionate rather than absent. Classify tools by reversibility and blast radius, gate only the classes that leave the organisation or are visible to others." And section 7 of the review is a page about how the pilot evidence is correct and should be kept. Quote: "This review agrees with the evidence and disagrees only with the inference."

**Dana:** *(pause)* Then I've read something else. Or I read the headline and filled in the rest.

**Brett:** Probably the second. It happens with a hundred-page pack. But it matters, so let's be precise: what's gated is a class list, not everything. Architecture document, section 7.2 — "Reads: no gate. Writes confined to the requesting user's own scope, such as a draft in their own drafts folder: no gate. Writes visible to others or leaving the organisation — send email, post to a channel, comment on an issue, push a commit: gate."

**Dana:** Posting to a channel is gated. That's most of what Support does.

**Tom:** It really is.

**Brett:** Then that's an argument to have properly rather than by half-memory. I'll take an action to put the class list in the executive summary so that reading isn't available, and we'll come back to whether org-visible posts belong in the gated set. I'm not moving it today on a number nobody has.

---

## 2. AI1 — the trusted-internal-sources criterion

**Brett:** Start where the pack starts. AI1, Critical. The acceptance criterion on PLAT-2814 states that "internal sources are already behind authentication so they don't need the same handling". The finding is that authentication governs who may *read* a mailbox and says nothing about who *wrote* the message in it. Dana, that's your criterion.

**Dana:** It is. I wrote it.

**Brett:** What was it for?

**Dana:** Scoping. We had five connectors and one of them obviously needed content cleaning, and I didn't want the team building a sanitiser for five when the requirement was one. It was a line about where to spend effort.

**Brett:** Was it a security position?

**Dana:** No. It was a product scoping note.

**Marcus:** It's in the trust model as a security position.

**Dana:** I know. I've just seen that.

**Brett:** Does anyone in this room dispute the finding itself? That an email body is authored by whoever sent it.

**Marcus:** No. Written down like that it's obviously right, which is slightly uncomfortable.

**Tom:** It's worse than obviously right, for us. Can I put something in?

**Brett:** Please.

**Tom:** The pack talks about Slack guests as a category. We have three Slack Connect channels shared with customers. Two enterprise accounts raise most of their issues through them rather than through the ticket queue, because we told them to. So "Slack messages from Connect guests" isn't a hypothetical channel, it's three named channels with customer staff typing into them every day.

**Brett:** Which customers?

**Tom:** The two big ones. I'd rather not put the names in the minutes but everyone here knows who they are.

**Brett:** Fine — three Connect channels, two enterprise accounts, in the record. Anything else on what the assistant is actually pointed at?

**Tom:** Yes, and this one is going to be annoying. The Support mailbox is shared. It's not individual mailboxes, it's one address the whole team works out of. And it is the single thing Support asked for. The pitch was "stop making us read six hundred messages a morning" — that mailbox is the reason we volunteered for the pilot.

**Priya:** That's connected as a shared mailbox in the connector config, yes.

**Brett:** So every message in the thing the pilot most wants read is authored by a customer or by a stranger.

**Tom:** Every message. That's the definition of it.

**Brett:** Then AI1 stands and I'd say it firms up rather than moves. Nobody's arguing severity down?

**Kwame:** Not on that one.

**Brett:** AI1 confirmed, Critical, no change.

---

## 3. Who decided that internal content was safe?

**Brett:** I want to ask a different kind of question, and I want people to answer it literally rather than helpfully. Who decided that internal content doesn't need sanitising?

**Dana:** I've just said — I wrote the criterion, but as a scoping note.

**Brett:** So not you.

**Dana:** Not as a decision, no. I wrote down where the work was.

**Brett:** Priya. You built it.

**Priya:** I implemented to the criterion. ADR-0004 says we clean web search content, and the reason it gives is that web search is the connector PLAT-2814 identified as untrusted. So the ADR points at the ticket.

**Brett:** Did you think the ticket reflected a security position?

**Priya:** Yes. Honestly, yes. It was written like one. It gives a reason — behind authentication — and the reason sounds like an argument, so I assumed somebody had made it.

**Brett:** Marcus. It's stated as settled in the architecture page.

**Marcus:** Because the ADR said it and the ticket said it. I wrote the trust model against two artefacts that agreed with each other. I took that as it having been assessed.

**Brett:** By whom?

**Marcus:** *(pause)* By whoever wrote the ADR. Which is Priya, who wrote it because of the ticket, which is Dana, who wrote it as a scoping note.

**Kwame:** I'll add the fourth corner. I assumed the platform sanitiser covered ingestion. That's what it's there for on the ingestion services, and I assumed the assistant sat behind it in the same way.

**Priya:** It doesn't. The connectors call the MCP servers directly.

**Kwame:** Right. I hadn't checked. I assumed.

**Brett:** So the decision was made four times and never once.

**Marcus:** That's not a comfortable sentence.

**Brett:** It isn't, and I'm not going to make it comfortable by resolving it now. Nobody in this room did anything careless. Each artefact cites another one and each of them looks correct on its own — that's how the loop closed. What I'm not going to do is decide it here, because deciding it here would repeat exactly the thing that went wrong.

**Dana:** So what's the action?

**Brett:** The action is that somebody owns the decision, in writing, as a decision. Not a criterion, not an ADR that defers to a criterion. Marcus, you own the trust model, so I'd like it to be you — write the content-trust position as an ADR of its own, with the reasoning, and put Ines and me on the review.

**Marcus:** I'll take it.

**Brett:** And it's recorded that no such decision exists today.

---

## 4. O1 — the diagram

**Brett:** O1. The supplied trust model omits six components and puts every boundary at the network. Marcus, that's your diagram.

**Marcus:** It's my diagram, drawn for a stand-up, in about four minutes. It was never a trust model.

**Brett:** It's titled "What most engineers assume".

**Marcus:** Which is what I meant by it. The subtitle is the joke — "a tidy boundary at every connection; the internet is the only untrusted zone". I drew what people assume so we could argue about it.

**Brett:** And then?

**Marcus:** And then nobody argued about it, and I put it on the architecture page, and it's been the picture for four months.

**Brett:** So the finding is right.

**Marcus:** The finding is right about what happened to it. I'd dispute "the supplied trust model" — it's a sketch that became one by neglect, which is a different failure. But I'm not going to argue that a document with no node for the model provider is fine because I drew it fast. The six missing components are missing. I've checked the list. Web console, conversation store, metering store, tier router, MCP client, provider — all six, and the provider one is the one that bothers me.

**Ines:** It bothers me a great deal more than it bothers you.

**Marcus:** I'd assume so.

**Brett:** O1 confirmed, High, and Marcus redraws against the eight boundaries in document 03. Same owner as the ADR, which is deliberate.

---

## 5. AI25 and the egress question

**Brett:** AI25, Critical. Both renderers fetch remote content from model output. The abuse case is SAC-04, "Markdown image exfiltration in the renderer".

**Kwame:** This one I think comes down. We have an egress proxy. It's the standing platform control — everything leaving the cluster goes through it and it's on the controls page.

**Marcus:** That's right. It's the reason I've never worried much about this class of thing.

**Kwame:** So the model can emit whatever URL it likes. The fetch doesn't leave the estate unless the proxy allows it.

**Brett:** Priya, does the assistant's server-side traffic route through it?

**Priya:** I'd expect so, it's cluster-wide. But that isn't the path in this finding.

**Kwame:** How is it not?

**Priya:** Read the flow. SAC-04 — "The Slack surface or the web console renders markdown and fetches the image." The console is a page in the user's browser. Nothing in that path is inside the cluster. The proxy is behind the fetch, not in front of it.

**Kwame:** *(pause)* The browser fetches it.

**Priya:** The browser fetches it. And on the Slack side it's Slack's own unfurling, which is also not us.

**Kwame:** Then the proxy doesn't touch it at all.

**Brett:** And that's why the pack gives it a different counter. SAC-04's counter is SUC-07, not SUC-09. SUC-07 is "Sink-specific output filtering at the renderers" — a markdown subset with image and link tags stripped, and a content-security policy whose `img-src` and `connect-src` exclude third-party origins. The egress proxy is SUC-09, and SUC-09 is the counter to I3, which is a different finding.

**Kwame:** I'd have closed this in a stand-up. I've got the control, the control is real, and it's aimed at the wrong side of the boundary.

**Brett:** Which is worth saying out loud, because it's the same shape as everything else on this list. The control exists and covers a path adjacent to the one in question.

**Marcus:** Does the proxy help with I3, then? The web search connector?

**Brett:** Possibly, and that's a real question rather than a rhetorical one. I3 is the assistant or a connector fetching a destination the task content chose. That's server-side, so the proxy is in the path. Kwame — does it deny by default?

**Kwame:** It denies by default, yes.

**Brett:** Is the allow-list narrow enough that a host registered this morning is refused?

**Kwame:** I don't know what's on it. It's a shared list, it's been added to for two years.

**Brett:** Then I'm not moving I3 today. Action on you to produce the current allow-list and the default action, and if it's deny-by-default with the search provider's host on it and not much else, I3 comes down at the next pass with the evidence attached. Not before.

**Kwame:** That's fair.

**Brett:** AI25 confirmed, Critical, no change. I3 confirmed, Critical, evidence requested.

---

## 6. T2 — commits into the build

**Brett:** T2, Critical. Agent commits enter the build pipeline with no review or provenance gate.

**Marcus:** This is the one I think overstates. We have branch protection. An LLM committing to a repository isn't at the top of the build trust hierarchy, it's at the bottom, same as any other author — it can't merge, so the blast radius is one pull request that a human declines.

**Kwame:** Branch protection is on every repository in the org. That's a platform baseline and it's on the controls page.

**Priya:** Can I take the wording first, because the wording is actually wrong.

**Brett:** Go on.

**Priya:** Section 3.2 says the pull request "is bypassed by construction". That's not established by anything. PLAT-2817 removes a confirmation step inside the assistant. It says nothing at all about repository policy. Whether a PR is bypassed depends on the repo configuration, and the same paragraph admits that — "What a code pass would confirm: whether the commit tool targets protected branches." You can't assert it in sentence four and ask about it in sentence six.

**Brett:** That's a fair hit. The finding's issue statement is careful — "Nothing states that commits go to a branch, open a pull request, or are excluded from pipelines that hold deployment credentials" — and the narrative in 3.2 goes further than the finding does. Wording corrected. Marcus, does that get you your downgrade?

**Marcus:** I'd say it does.

**Priya:** It doesn't, and this is the part I'd rather say now than in an incident. The assistant commits to the working branch. Not to a feature branch and not to `main` — to whatever branch the task is on, which for the pilot repos is the working branch, and the working branch isn't protected.

**Marcus:** Protection is on `main`.

**Priya:** Protection is on `main`. The working branch has nothing on it. And whatever CI is configured runs against what lands, which is the pack's point and it holds.

**Marcus:** Then it reaches CI.

**Priya:** It reaches CI. And there's a second thing. There's an exemption list on branch protection and `platform-ci` is on it, standing, no expiry. That's how the release automation pushes.

**Kwame:** That's not on the controls page.

**Priya:** It's not in Confluence anywhere. It's a config file in the org repo. So if you're reasoning from documentation you can't see it — the documentation says branch protection is enforced everywhere, and it is, apart from the list of things it isn't enforced on, which is in a different system.

**Brett:** *(pause)* Say the consequence.

**Priya:** The consequence is that "branch protection bounds the blast radius" is true of `main` and not true of the path the assistant actually uses. So T2 is right for a reason the pack couldn't have known, and the reason the pack gives is weaker than the real one.

**Brett:** T2 stays Critical. Wording in 3.2 corrected to remove "by construction", and the finding gains Priya's two facts as evidence. Marcus?

**Marcus:** Yes. I was wrong about this and I'd have argued it hard in a design review.

**Brett:** While we're here — how much is the commit capability actually used?

**Priya:** Eleven times since July. Nine of them are me testing it.

**Dana:** Eleven.

**Priya:** Eleven. Two that weren't me.

**Dana:** Then I'll stop defending it as a headline feature, because it isn't one yet. If the answer is a pull request instead of a direct commit, that costs us two users a small amount of friction on a thing they've done twice.

**Brett:** That's the cheapest gate on the list, then. T2 and AI24 — feature branch, draft PR, assistant commits excluded from credential-holding pipelines. Owner?

**Priya:** Mine. It's a change to the commit tool and a CI condition.

---

## 7. Q1 — whose credentials

**Brett:** Question Q1, and it's the one the pack says re-rates six findings. "When the assistant calls the Office 365 connector for user A, does it present a token scoped to user A, or a shared application credential?"

**Marcus:** Per-user. The assistant acts as the requesting user, so the user's existing permissions apply. That was the design from the start — it doesn't get to see anything you couldn't see.

**Kwame:** That's the standard pattern, yes. Delegated access, the source system decides.

**Dana:** And it's what we told the pilot group when we enrolled them. It's on the architecture page in the present tense — it doesn't say "will", it says "does".

**Brett:** Priya, confirm it from the configuration.

**Priya:** I can tell you what we intended. I'd want to look at the app registration before I told you what scopes are actually granted, because I didn't set all of them up.

**Brett:** So you can't confirm it.

**Priya:** Not from memory, no. I'm not going to say "delegated" in a document and be wrong about it.

**Marcus:** It's delegated. It has to be, or the whole thing is a different product.

**Brett:** It doesn't have to be anything. That's the point of the question. Three people have told me the intent and the only person who could tell me the configuration has said she'd need to look.

**Dana:** Is that not enough to take the six findings down a notch? Nobody in the room thinks it's a shared credential.

**Brett:** No, and I want to be blunt about why. AI8's issue statement is one sentence: "The input never says whether a tool call presents a token scoped to the requesting user or a shared application credential." What we have now is that the room doesn't say either. Four people's recollection of an intent is not a configuration fact, and it's a configuration fact that changes I2, E1, E2, E4, R3 and AI8. Nothing comes down without evidence.

**Marcus:** That feels pedantic.

**Brett:** It probably is. It's also the difference between a register that survives an audit and one that doesn't. Priya pulls the app registration and the granted scopes per connector, we attach it, and then six findings move in one go. That's a day's work at most.

**Priya:** I'll have it tomorrow.

**Brett:** Q1 remains unanswered. I2, E1, E2, AI8 stay as written.

**Tom:** One thing that might matter to that, from Support's side. If it is per-user — the shared mailbox is shared. All seven of us can read the whole thing. So "the user's own entitlement" doesn't narrow anything for us. Everyone's entitlement is the same and it's everything.

**Brett:** That's a good catch and it goes in P2 rather than I2. The privacy exposure on the Support mailbox doesn't reduce under per-user credentials, because the population who may read it is the whole team.

**Ines:** And the correspondents are customers. Hold that, I'll come back to it.

---

## 8. The MCP servers

**Brett:** AI3 and AI16 — servers not inventoried, pinned or signature-verified. Question Q13 asks which they are, at what versions, and who may add one.

**Priya:** I can answer that one properly. They're pinned to `latest`. All five.

**Kwame:** Pinned to `latest` isn't pinned.

**Priya:** No, it's the opposite of pinned, which is why I said it that way. Every connector resolves to `latest` on restart. And the web search one is a community server — it's not first-party and it's not a vendor product, it's a repository somebody publishes.

**Brett:** So AI3's example threat, which is a community server whose maintainer account is compromised shipping a version that copies tool arguments out — that's not a hypothetical for one of the five.

**Priya:** It's not a hypothetical for one of the five, no.

**Marcus:** Who may add a sixth?

**Priya:** Nothing gates it that I'm aware of. It's the client configuration.

**Brett:** Does that change severity? AI3 is High, Medium likelihood.

**Kwame:** I'd argue the likelihood goes up. "Not stated" and "resolves to latest from a community repository on every restart" are not the same risk.

**Brett:** Agreed, and it's an increase rather than a decrease so I'll take it in the room. AI3 High, likelihood Medium to High. AI16 unchanged. Pinning by digest goes on the fast-hygiene list with a name against it.

**Priya:** Mine, and it's a day.

---

## 9. Privacy and regulatory

**Brett:** Ines, section 8. Your part.

**Ines:** Several things, and the first is a correction to the framing rather than to a finding. The pack says NIS2 "applies conditionally on the organisation's entity classification, which the input does not establish". We are not an essential or important entity. That part is settled and it's been settled for a year.

**Brett:** So NIS2 comes out?

**Ines:** No, and this is the bit the pack couldn't have got to. Two of our customers are in scope, and their contracts push the obligations down to us. Supply-chain security, incident notification inside their reporting window — we carry those contractually whether or not the Directive reaches us directly. So the findings stay, the reason changes, and the reason is stronger than "conditional", because a contractual obligation doesn't wait for a classification argument.

**Brett:** And the other framework line?

**Ines:** The pack has "SOC 2 and ISO 27001" as one row. We're SOC 2 Type II. We do not hold ISO 27001 and we're not pursuing it. That matters because a Type II report is about operating effectiveness over a period — an auditor doesn't ask whether the control is designed, they ask for evidence it ran. An action record that doesn't exist for six months of a pilot is a finding in the next report.

**Brett:** So R1 and O2 have an audit consequence as well as a security one.

**Ines:** They do, and it's on a clock rather than on a wish. Every month the pilot runs without an action record is a month of the observation period with no evidence in it.

**Brett:** Noted, and the row gets split. Next — P6, the metering.

**Ines:** P6 is rated Medium and I think that's wrong, but not for the reason in the write-up. The pack says "per-team aggregates are computed from per-person activity, so per-person records exist". That's inference. I can tell you it's not an inference. Per-user usage is queryable in the warehouse today. The dashboard aggregates to team, but the underlying rows are per person and anyone with warehouse access can select them.

**Priya:** That's right. The aggregation is in the dashboard query, not in the pipeline. The raw events go to the warehouse per user with a user ID on them.

**Ines:** So the example threat in the write-up — a manager asking for the per-person figures for performance reviews — doesn't require anyone to build anything. It requires someone to write a query.

**Brett:** Does that change your view of the mitigation?

**Ines:** The mitigation is incomplete. "Aggregate at write time and discard per-person detail" is right going forward and does nothing about the rows that are already there. There needs to be a retrospective deletion, and it needs a date on it.

**Brett:** P6 to High. Mitigation extended with a retrospective delete. Owner?

**Ines:** Mine for the requirement. Priya's for the pipeline.

**Brett:** P2 — third parties in mail and calendar processed with no notice. Tom's shared mailbox lands here.

**Ines:** It makes P2 considerably worse, yes. A shared Support mailbox is customer correspondence — that's identified third-party data subjects, and it's the connector the pilot most wants. The pack's Article 14 point stands and it applies to a specific, large, named population rather than to "anyone who ever emailed a member of staff".

**Tom:** We didn't tell them anything about this.

**Ines:** No, and there was no route by which you would have. That's my job and I hadn't been asked.

**Brett:** P7, the DPIA.

**Ines:** There isn't one. I haven't been asked for one and I haven't started one. And I'd say the pack is right that it's a gate on the expansion rather than on the pilot — but I want the sequencing understood. A DPIA that arrives with six of these findings still open doesn't get signed, it gets a set of conditions attached. So the useful order is the launch gates first and the DPIA around them, not the DPIA in a corner while engineering does something else.

**Brett:** That's the order in section 6 of the gap analysis, so we're aligned. Owner is you, and it's a gate on the expansion.

**Ines:** One more. The model provider — I6 and COMP-02. Who is it?

*(pause)*

**Marcus:** It's whatever the tier router is pointed at.

**Priya:** I know what the endpoint is and I can tell you which account it's billed to. I don't know what contract sits behind it, and I've never seen one.

**Ines:** I've never been shown one either, and I'd have been the one to sign it. Then corporate personal data, including the shared Support mailbox, is going to a processor with no processor agreement, no region commitment and no retention terms.

**Brett:** On every turn.

**Ines:** On every turn. That one isn't a design finding, it's a live one, and it started the day the pilot started.

**Brett:** I6 stays High and gets the earliest date on the list. Ines owns the contract, Priya names the endpoint and the account today so Ines has something to write against.

---

## 10. Two things wrong with the pack

**Brett:** Before the actions. Priya flagged two arithmetic problems this morning and I want them in the record rather than quietly fixed.

**Priya:** The first is the headline. The review says fourteen Critical findings and that eleven of them collapse into the PLAT-2814 and PLAT-2817 pair — "one design decision counted from eleven directions, plus three independent Criticals". And the register says fix the pair and "the Critical count falls to three".

**Brett:** And?

**Priya:** And that doesn't survive the pack's own launch gates. Section 9 makes I2 and AI8 gate two, together. So AI8 isn't in the collapsing eleven — the same document says it's in the independent set with I2. Same with AI11, which is gate four with I3. And E1 and E2 are authorisation findings; provenance labelling and an action gate don't close them. Fix the pair and you don't get to three. You get to seven at best.

**Brett:** That's right and it's my error. The eleven was counted against causation loosely — every Critical that becomes reachable *because* of the pair — and then the "falls to three" sentence treats it as every Critical that's *closed* by the pair, which is a smaller set. Two different counts wearing the same number.

**Marcus:** Does it change what we do?

**Brett:** It changes what the summary promises. If the exec summary says "fix two things and Criticals fall to three", that's what gets funded, and then four Criticals are still open and it looks like the fix failed. Correction goes in the next version, both sentences.

**Priya:** The second one is smaller. The README and the review both say "forty-nine refined requirements". Section 5 of the gap analysis has thirty-eight SEC, eleven PRV and eight COMP. That's fifty-seven, and the SRTM traces all of them.

**Brett:** Forty-nine is fifty-seven minus the COMP block. So the count was taken before compliance was added and never redone. Corrected.

**Kwame:** Does anything hang off it?

**Brett:** Only credibility, which is enough. If two people check two numbers and both are wrong, nobody checks the third.

---

## 11. What we could not answer

**Brett:** Quickly, so it's on the record. Document 00 asks twenty questions. Between us we've answered three — Q13, which MCP servers and at what versions; part of Q12, what CI does with an assistant commit; and part of Q8, the framework position. Q1 is outstanding until tomorrow.

**Marcus:** What's still completely open?

**Brett:** Q6, the provider and its contract. Q7, whether there's a retrieval index or vector store — nobody here has said, and AI13 is tagged "if present" until somebody does.

**Priya:** The gap analysis carries it as an assumption — assumption (e), retrieval is live query — and that assumption is right for what's running today. Whether it stays live query when we chase the six-second number is a different question, and I'd not want that written down as settled.

**Brett:** Then it's the pack's own assumption confirmed for today and open for the target architecture, and AI13 stays tagged. Q10, where it runs and on what — no infrastructure information at all, which is why two whole threat surfaces weren't walked. Q17, logging. Q18, the kill switch. Q19, caps.

**Kwame:** Some of that is platform. Transport, secret handling, log retention — those are on the controls page and the pack's own appendix F says a baseline would likely close or downgrade S2, S5, T5, I4, R4 and RR3.

**Brett:** It says "would likely", and it says it because nothing was supplied. Send me the controls page, mapped finding by finding, and I'll close the ones it actually covers. What I won't do is mark six findings closed in the minutes because a page exists — we've had one worked example this afternoon of a real control aimed at the wrong side of a boundary, and I'd rather not have a second.

**Kwame:** Understood. I'll map it rather than assert it.

**Brett:** Ninety-five minutes, and I want to say the uncomfortable part plainly. We closed nothing. Not one of seventy-two findings moved to closed, three severities moved and two of them moved up. What we did do is turn a document that says "not stated" a hundred and forty times into a document that says what is actually true in about a dozen places, and we found out that a decision everyone assumed had been made was never made by anybody. That's what this hour was for. It isn't a bad result; it's just not the result people expect from a validation session.

**Dana:** It's the first time anyone's read the epic out loud to us.

**Brett:** That's roughly finding O4. Eighteen acceptance criteria, none of them security, two of them removing controls. Dana, that one's yours as well.

**Dana:** I'll take it. And I'd rather write the security criteria into the epic than have them sit in a review nobody on the delivery side reads.

**Brett:** Then that's the best outcome available from this session and it's the last thing on the list.

---

## 12. Actions

| # | Action | Owner | By |
|---|---|---|---|
| 1 | Produce the app registration and granted scopes per connector, so Q1 is answered by configuration rather than recollection. I2, E1, E2, E4, R3 and AI8 are re-rated from that evidence and not before | Priya Raghunathan | 2026-09-10 |
| 2 | Write the content-trust position as an ADR of its own — not a scoping note and not an ADR deferring to a ticket — covering all five connectors, with Ines and Brett on the review. Record that no such decision exists today | Marcus Oyelaran | 2026-09-19 |
| 3 | Redraw the trust model against the eight boundaries in `03-security-architecture.md` §3, adding the six missing components and the external-author actor. Retire `diagram1-assumed.svg` from the architecture page | Marcus Oyelaran | 2026-09-19 |
| 4 | Commit path: assistant commits go to a feature branch and a draft pull request; assistant-authored commits excluded from credential-holding pipelines. Record that the working branch is unprotected and that `platform-ci` holds a standing branch-protection exemption | Priya Raghunathan | 2026-09-26 |
| 5 | Pin the five MCP servers by digest and hash their tool definitions, failing closed on mismatch. Replace `latest` resolution. Note that the web-search server is a community server | Priya Raghunathan | 2026-09-17 |
| 6 | Produce the egress proxy's current allow-list and default action. I3 is re-rated against that evidence; it does not move on the existence of the proxy | Kwame Osei | 2026-09-16 |
| 7 | Map the standing platform controls page finding by finding against S2, S5, T5, I4, R4 and RR3. Findings close on the mapping, not on the page | Kwame Osei | 2026-09-23 |
| 8 | Name the model provider, the endpoint and the account holding it, so a processor agreement can be drafted against something | Priya Raghunathan | 2026-09-10 |
| 9 | Model-provider processor agreement, region pinning, retention and training-use position; add to the sub-processor register | Ines Ferreira | 2026-10-17 |
| 10 | DPIA, sequenced around the launch gates rather than ahead of them. Gate on the pilot expansion beyond Platform and Support | Ines Ferreira | Before expansion |
| 11 | Metering: aggregate at write time, and a retrospective deletion of the per-user rows already in the warehouse, with a date | Ines Ferreira (requirement), Priya Raghunathan (pipeline) | 2026-10-03 |
| 12 | Article 14 position for the shared Support mailbox and the three Slack Connect channels, as an identified third-party population rather than a general one | Ines Ferreira | 2026-10-03 |
| 13 | Add the gated tool class list to the executive summary of `01-security-review.md`, so it cannot be read as confirmation on every action. Bring the question of whether org-visible Slack posts belong in the gated set back with pilot numbers | Brett Crawley (pack), Dana Whitfield (numbers) | 2026-09-16 |
| 14 | Correct the Critical-collapse arithmetic in `01-security-review.md` §1 and §3 and in the register roll-up: the pair does not reduce Criticals to three, because AI8, AI11, E1 and E2 are not closed by it | Brett Crawley | 2026-09-12 |
| 15 | Correct the refined-requirement count from forty-nine to fifty-seven in the README and `01-security-review.md` §2 | Brett Crawley | 2026-09-12 |
| 16 | Remove "bypassed by construction" from `06-threat-model.md` §3.2; the tickets do not establish it. Attach the working-branch and exemption-list evidence to T2 instead | Brett Crawley | 2026-09-12 |
| 17 | Write security acceptance criteria into PLAT-2810 and its children from the launch gates, so the next story does not repeat this | Dana Whitfield | 2026-09-26 |
| 18 | Reconvene on the remaining fifty-odd findings not walked today, once actions 1, 6 and 7 have landed | Brett Crawley | 2026-09-30 |

**Dispositions recorded in the room**

- **AI1** — confirmed, Critical, unchanged. Evidence added: shared Support mailbox; three Slack Connect channels with two enterprise customers.
- **AI21** — confirmed, Critical, unchanged. Gated class list to be restated; scope of org-visible writes reopened for evidence.
- **T2 / AI24** — confirmed, Critical, unchanged. Pack wording corrected; new evidence strengthens it.
- **I3** — confirmed, Critical, evidence requested before any change.
- **AI25** — confirmed, Critical, unchanged. Egress proxy does not cover it.
- **AI3** — confirmed, High; likelihood raised from Medium to High.
- **AI16** — confirmed, High, unchanged.
- **P6** — raised from Medium to High; mitigation extended to a retrospective deletion.
- **I6** — confirmed, High; earliest date on the list.
- **P2** — confirmed, High; population identified rather than general.
- **O1** — confirmed, High, unchanged; document owner accepted.
- **O4** — confirmed, High, unchanged; document owner accepted.
- **AI13** — remains tagged "if present". Retrieval is live query today; not settled for the target design.
- **I2, E1, E2, E4, R3, AI8** — unchanged pending action 1.
- **S2, S5, T5, I4, R4, RR3** — unchanged pending action 7.
- **All other findings** — not walked in this session. Status unchanged.
