# Internal AI Assistant — Security Pack Validation Session

**Date:** 2026-09-09 · **Time:** 13:30–15:08 · **Duration:** 98 minutes
**Facilitator:** Brett Crawley, Principal Application Security Engineer
**Classification:** Internal · **Recording:** yes, transcribed and lightly tidied for readability

**Attendees**

| Name | Role |
|---|---|
| Brett Crawley | Principal AppSec Engineer (facilitator) |
| Dana Whitfield | Epic owner, Product — PROD-1131 |
| Marcus Oyelaran | Lead architect; owner of the architecture page; engineering owner, PROD-1131 |
| Priya Raghunathan | Senior engineer; built the orchestrator and the connector runtime |
| Tom Egerton | Engineering manager, Support; pilot coordination |
| Ines Ferreira | Data Protection Officer |
| Kwame Osei | Security Champion, Platform |

**Invited, not present:** Identity Platform representative (no response); Data Platform representative (declined, holiday); the owner of the standing platform security controls page — Kwame attended in that seat as Security Champion but does not own the page.

**Material reviewed:** `Internal AI Assistant — Security Analysis Pack`, version 1.0, dated 2026-09-09. Eight documents plus a README index. 68 findings — 7 Critical, 37 High, 24 Medium; 56 Open, 5 Partially mitigated, 7 Planned. 22 gaps, 17 of them with no ticket. 79 requirements traced in the SRTM against 28 test artefacts. 217 elicitation prompts across seven instruments.

---

## 0. Opening

**Brett:** Before anything else, the thing that shapes the whole pack. The brief asked for three source categories and two arrived. There is no repository in this. No `assistant-svc`, no Helm, no Dockerfiles, no schemas, no prompt templates. Eleven findings in here rest on the absence of a statement rather than on an observed absence — they're tagged "if present" — and there's a list of twenty-seven questions the pass couldn't answer in document 00. Most of what I want from this room is turning suspicions into facts. Where you can do that, say so. Where you can't, say that too, and I'll write it as still open.

**Marcus:** Why wasn't the repo supplied?

**Brett:** I don't know. It's noted in the pack as absent and it isn't a small absence — Appendix B says "None" and lists what would have been read.

**Priya:** I can answer some of it from memory. I'm not going to answer the parts I'd have to check, because you'll write down whatever I say.

**Brett:** That's exactly the rule I want. Let's start with the headline.

---

## 1. Authorisation — O1, E1, S2, R2

**Brett:** O1 is Critical and it's the one everything else hangs off. The architecture page says, under Authorisation — I'll read it — "Each connector holds a per-user delegated credential obtained through OAuth, stored with a short TTL and refreshed rather than held long-lived. A user cannot reach anything through the assistant that they could not reach directly, and actions are attributable to them in the target system's own audit log. This follows initiative decision D-03." PLAT-2820 is To Do. Marcus, that's your page.

**Marcus:** It's my page and it's my change-log line. "Authorisation section updated following D-03."

**Brett:** Is the paragraph accurate?

**Marcus:** *(pause)* No. It's accurate about D-03. It isn't accurate about what runs.

**Kwame:** Hang on. The assistant acts as the requesting user — that's the whole model. That's what we tell people.

**Marcus:** That's what the page says, yes.

**Priya:** It isn't what the code does. The orchestrator takes the user's identity at the surface and it doesn't carry it into the dispatch. There is no user field on the connector call. It gets dropped before the MCP client sees it.

**Brett:** That's question Q5 in document 00 — "Does the orchestrator carry the requesting user's identity into the connector call at all, even as a field?" You're answering it as no.

**Priya:** As no. It's one app registration with application permissions, all four connectors. I wrote that in the ticket in May. PLAT-2820-3 — "the prototype uses one app registration with application permissions across all connectors, so we could get moving while PLAT-2820-1 is blocked. Must not reach GA like this."

**Dana:** I've been telling the steering group it runs as the user.

**Priya:** I know.

**Dana:** No — I mean I've said it in writing. Twice.

**Brett:** Where did you get it from?

**Dana:** The architecture page. It's the approved one.

**Kwame:** Same. It's the page designs are told to cite.

**Brett:** So we have three people who believed a control was in place, all reading the same page, and the ticket that contradicts it has been sitting under the epic since May. Marcus, does anything on the page distinguish decided from delivered?

**Marcus:** No. And I'd defend the convention rather than the outcome — the page records the architecture, and the architecture is D-03. But I accept that nobody reads it that way, including the forum that approved it on the twentieth. It reads as a description of the build.

**Ines:** Can I ask the practical version. Today, if a Support agent asks the assistant for something out of the finance director's mailbox, does it come back?

**Priya:** Yes.

**Ines:** *(pause)*

**Ines:** Then everything I have on my list is downstream of this one.

**Brett:** E1 says the same thing from the entitlements side, S2 from the identity side, R2 from the audit side. Any dispute on severity for any of the four?

**Marcus:** No. I'd argue O1 is the one that costs an hour and I'd like it done today rather than sequenced.

**Brett:** That's the pack's recommendation too — item 2 in the sequence, an hour of writing. Recorded: Marcus corrects the Authorisation section this week, with a status marker and a link to PLAT-2820.

**Kwame:** I'm uncomfortable that it took a document to tell us. The ticket was there. I've been in refinement on that epic.

**Priya:** So have I.

**Brett:** Noted, and I'd rather it's said out loud than not. E1's interim mitigation is an Entra application access policy scoping the registration to the pilot group. Priya, is that days or weeks?

**Priya:** Days, if IT will do it. It's not our change to make.

**Brett:** Then the blocker for the interim control is the same team that's blocking the permanent one. Identity Platform isn't in the room. PLAT-2820-1 has been blocked since 2026-04-18 and unscheduled. Marcus, that's a portfolio escalation, not a refinement item — the pack calls it the single most important thing in the pack and I agree with it.

**Marcus:** I'll take it to the COO office with the finding IDs attached.

---

## 2. The commit path — T3, E3, and what branch protection covers

**Brett:** T3. The assistant holds commit rights across every repository in the organisation. PLAT-2817-3 — "Issues, comments and commits. Commits go direct to the working branch." Marcus, your comment is quoted in the pack: "branch protection means anything on a protected branch needs review, so the blast radius is bounded."

**Marcus:** And I stand behind it. Protected branches require an approving review and signed commits. That's org-wide. The assistant cannot put anything into main that a human hasn't approved.

**Kwame:** That's right. It's one of the strongest things on the controls page.

**Brett:** The pack agrees with the first half and not the second. It gives two paths it doesn't cover — CI that runs on push to a working branch executes the committed content before any review, and a plausible-looking change on a working branch reaches production through a human approving the pull request for its stated purpose.

**Marcus:** The first one I'll take. The second is a reviewer problem, not an assistant problem.

**Priya:** There's a third and it isn't in the pack.

**Brett:** Go on.

**Priya:** The exemption list. Branch protection has a standing exemption for `platform-ci`. It's a config file in the org repo — it isn't in Confluence anywhere. If you're reasoning from the controls page you can't see it.

**Kwame:** Since when?

**Priya:** Since before this epic. It's not new. It's just not written down anywhere you'd look.

**Marcus:** *(pause)* That changes my answer.

**Brett:** Say why, for the record.

**Marcus:** Because I've been treating branch protection as a boundary and it has a hole in it that isn't on the page I'd cite to prove the boundary exists.

**Brett:** Then two things. First — Priya, that goes into the pack as a fact, because no document in the estate contains it. Second, the risk register. T3's status is "🟡 partial, branch protection bounds protected branches." Given commits go direct to the working branch, and the working branch isn't protected, what is the partial mitigation actually mitigating?

**Priya:** Nothing on the path the finding describes. It bounds a path the assistant doesn't take.

**Brett:** Agreed. That's a correction to the pack, not to the team. T3 moves from Partially mitigated to Open. Appendix F carries the same credit in the "Narrows" column and gets the same change. Severity?

**Priya:** High is right. I'd raise likelihood.

**Brett:** Likelihood Medium to High, T3 to Open. That makes the roll-up 57 Open, 4 Partial, 7 Planned. Dana, before we go further — how much is the commit capability actually used?

**Dana:** Constantly, I'd have thought. It's the demo everyone asks for.

**Priya:** Eleven times since July. Nine of those were me testing it.

**Dana:** *(pause)* Eleven?

**Priya:** Eleven. Two real ones, both trivial.

**Tom:** Nobody in Support has ever used it. It doesn't come up.

**Brett:** So the capability with the largest blast radius in the pack, org-wide write into every repository, has two genuine uses in two months. Dana, is there a product reason not to turn writes off at the connector until PLAT-2820 lands?

**Dana:** Not eleven uses' worth of reason, no. I'd want it back before GA — "the assistant can open a PR for you" is on the Phase 2 slide. But not now.

**Marcus:** I'd rather scope the installation than remove the capability. E3's mitigation is a named repository list excluding public repositories, and split read from write. That's the shape I'd defend.

**Brett:** Both are in the pack and they aren't exclusive. Recorded: GitHub App installation narrowed to a named repository list, public repositories excluded, write installation restricted, owner Marcus with Priya; commit tool disabled at the dispatcher in the interim, owner Priya. E3 and T3 both.

---

## 3. Where untrusted content comes from — AI1, AI6, and who decided

**Brett:** AI1. Critical. The trust model on the architecture page says — "The corporate network boundary is the trust boundary... The one place untrusted content enters is web search, which is why its output is sanitised." The pack says that's false for three of the five channels feeding the model.

**Marcus:** I wrote that section too. I'd defend the intent — everything inside the boundary is authenticated.

**Brett:** Authenticated says who may read it. Does it say who wrote it?

**Marcus:** *(pause)* No. It doesn't.

**Tom:** Can I do the Support side of this, because I think it's worse than the pack has it.

**Brett:** Please.

**Tom:** The mailbox is shared. It's not nine individual mailboxes, it's one address that everything lands in, and it's the main thing we wanted the assistant to read — the whole point was summarising a customer's history before you pick up the phone.

**Brett:** The pack has that. It quotes your page — "the ticket queue and the shared mailbox so it can summarise a customer's history before an agent picks up a call." That one's already in the document.

**Tom:** Fine. Here's what isn't. Slack Connect. We have three Connect channels shared with customers, and two of our enterprise accounts raise things through them rather than through mail.

**Brett:** The pack knows Connect exists as a channel — AI1 says "Slack Connect and external channels carry content from outside the organisation." It doesn't know there are three, or who's on them.

**Tom:** Three. And the two enterprise accounts are the ones whose escalations get read out in the assistant most days, because that's where our churn risk is.

**Ines:** Those are the two customers I was going to raise anyway. I'll come back to it.

**Brett:** So five channels feeding the model and the design treats one of them as untrusted. Which brings me to the question I actually came here to ask. Who decided that internal content doesn't need sanitising?

*(pause)*

**Dana:** That'll be my acceptance criterion. PLAT-2814 — "Content returned from web search is treated as untrusted and cleaned before the assistant uses it; internal sources are already behind authentication so they don't need the same handling."

**Brett:** Was that a security decision?

**Dana:** No. It was a scoping note. Web search was the connector we'd flagged as the untrusted one, and I was writing what was in scope for that story. I wasn't ruling on internal sources, I was saying they weren't part of that piece of work.

**Priya:** I implemented to the criterion. The sanitiser runs on web-search output and nothing else, because that's what the criterion says.

**Brett:** Did you read it as a scoping note?

**Priya:** No. I read it as a position somebody had taken. It's an acceptance criterion on an approved story — I assumed the security thinking was upstream of me.

**Marcus:** And I put it into the trust model on the architecture page. Same assumption. It was in the ticket, the ticket was refined, I took it as assessed.

**Kwame:** I assumed the sanitiser was a platform thing and covered everything coming in. That's on me — I didn't check what it was attached to.

**Brett:** So. Dana wrote a scoping note. Priya implemented it as a security position. Marcus wrote it into the trust model believing it had been assessed. Kwame assumed the platform covered it. Three artefacts, each pointing at another, and I can't find the decision at the end of the chain.

*(pause)*

**Marcus:** Because it wasn't made.

**Brett:** That's my reading too. Nobody was careless here. It got inherited three times and never chosen once. I'm not going to resolve it in this room and I'd distrust it if we did — a decision that gets made in ninety seconds at the end of an hour isn't better than the one we're missing.

**Ines:** I'd want to be in it when it is made.

**Brett:** You will be. Recorded: a written decision on which input channels are untrusted and what handling each gets, owner Marcus, with Kwame and Ines, before the next expansion. It is a decision to be taken, not a document to be corrected.

**Kwame:** What about the sanitiser in the meantime?

**Brett:** AI6 is the pack's answer and it's blunt about it. It credits the sanitiser as a real partial mitigation and says the guarantee can't rest there, because the input space isn't enumerable. Its recommendation is to ratify in writing that the sanitiser is not load-bearing, so no future design page cites it as the reason untrusted content is safe.

**Priya:** I'd sign that. I don't know what it does. I inherited it.

**Brett:** That's Q7 in the open questions and it stays open. AI6 stays Partial as rated.

---

## 4. How it gets out — AI2, I3

**Brett:** AI2. Critical, and the cheapest fix in the pack. Markdown image rendering. Your own page recorded it — "Model responses occasionally include markdown images referencing external URLs from web results. Renders fine, looks odd. Not investigated."

**Tom:** I've seen that. Broken image icon, you scroll past it.

**Kwame:** But this one's covered. Everything out of the cluster goes through the egress proxy with a domain allowlist. It's been in since 2023 and Platform Security review it weekly. An image URL to some host we've never heard of doesn't resolve.

**Marcus:** That's my understanding too. It's the strongest control we've got.

**Brett:** Read what the finding says. "The egress proxy — the organisation's strongest data-loss control — sits on cluster egress and cannot see this hop at all, because the fetch is made by a browser or the Slack client."

*(pause)*

**Kwame:** The browser makes the request.

**Brett:** The Support agent's browser makes the request. Nothing in the cluster makes an outbound call at all.

**Kwame:** Then the proxy is irrelevant to it. Completely irrelevant.

**Marcus:** And the same for the Slack client.

**Priya:** Both surfaces render markdown. It's the same output going to two renderers.

**Kwame:** The controls page has us covered for exfiltration and it doesn't cover the one path that doesn't touch the cluster. I've cited that proxy in two design reviews this quarter.

**Brett:** The pack says the same thing in three places, including the baseline coverage appendix — the proxy is "structurally unable to see TB9." TB9 is the boundary between the model's output and the user's screen, and the pack's point is it appears in no design document at all.

**Marcus:** It isn't on my diagram. There's no arrow there.

**Brett:** No. Kwame, you're the closest thing to Platform Security in the room. The fix is a Content Security Policy header on the console with `img-src 'self'`, and a markdown subset that strips image tags in both surfaces and on outbound content. The pack costs it at a day.

**Kwame:** A day is right for the header. The markdown subset in the Slack path is Priya's.

**Priya:** It's a renderer change in two places plus the outbound composer. Two days, being honest, and I'd want TA-04 and TA-05 running before I call it done — the four sinks, not just the console.

**Brett:** Recorded, owner Priya with Kwame, before the next expansion. This is the one that closes the credential-free path on its own. I3 stays as rated — the allowlist still doesn't bound a host that accepts attacker-chosen strings, and github.com is on the allowlist and is a place the assistant can write.

---

## 5. What the dispatcher checks — AI3, AI4, AI13

**Brett:** AI3. Tool arguments come from model output with no value validation. PLAT-2817-1 delivered the schema and dispatch.

**Priya:** The schema is shape only. Types and required fields. There's no check on the value of a recipient or a repository name — it validates that `to` is a list of strings and sends.

**Brett:** That's the pack's example verbatim. Confirmed rather than suspected, then. Dana, AI4 is yours — irreversible actions with no confirmation. The acceptance criterion says "Actions happen without a separate confirmation step; the pilot group were clear that a confirm dialog on every action would make it slower than doing the work themselves."

**Dana:** And I'd defend that. We tested it. People stopped using it when we confirmed everything — it's slower than doing the job yourself, which is the whole value proposition gone. I know the pack wants a confirm dialog back on every write and I'd push back on that hard.

**Brett:** What would you accept?

**Dana:** Commits. Confirm on commits, because nobody's using them anyway on Priya's numbers, and it's a genuinely different class of thing. Not on mail and not on posts — that's the daily workflow.

**Tom:** Mail leaving the organisation, though. My agents send to customers.

**Dana:** That's the case I'd argue about. Not in the abstract.

**Brett:** Then that's an action rather than a decision today. Dana to bring a confirmation model — which actions, on what basis — and we revisit AI4's recommendation against it. I'm not changing the finding on the strength of an argument about the shape of the fix.

**Dana:** Fine.

**Tom:** The two mistaken Slack posts are in the pack, by the way. Those were mine — my team's, I mean. Both benign, both to the wrong channel.

**Brett:** AI13 is the version of that with a person's name in it — a statement about a colleague, composed from context, posted under the sender's apparent authorship, with no citation and no rectification route. Ines, is that yours or mine?

**Ines:** It's mine. A statement about an identifiable person is personal data whether or not it's true, and there's no route for the person named to have it corrected. I don't want that finding softened.

**Brett:** It isn't being softened. AI13 stands at High.

---

## 6. The evidence layer — R1, R3, T2

**Brett:** R1. The Audit section of the architecture page promises "Every privileged action taken by the assistant is recorded with the acting user, the action, and the parameters it was called with, so that any change made on a person's behalf can be reconstructed." The Logging section, one section later on the same page, says "Tool arguments and results are logged at debug level, off in production for volume reasons."

**Marcus:** Both of those are mine and they contradict each other. I don't have a defence. The Audit paragraph describes what we intended to build and the Logging paragraph describes what we run.

**Brett:** Priya, in production today, if I ask which mailbox was read at 14:12, can anyone answer?

**Priya:** No. You get the conversation ID, the user, the team, the tool name, latency and token counts. Not the arguments, not the result.

**Ines:** Then I can't scope a breach. That's my Article 33 assessment gone — I can't say how many people are affected or which, so I can't say whether it's notifiable, and I'd have to assume the worst.

**Brett:** That's the pack's example threat almost word for word. R3 is the one I want a reaction to, though. PLAT-2825-1 — "Render actions inline — Rendered from the model's own account of what it did."

**Dana:** "Users see what it did" was my acceptance criterion at epic level. I'm quite proud of it.

**Brett:** The pack agrees it was the right requirement. It says the implementation reads from the model, so the same injected content that causes an action also composes the account of it.

**Priya:** That's accurate. It's the model's prose. There's no dispatcher record for it to read from, which is why it reads from the model — R1 is the prerequisite and it doesn't exist.

**Dana:** So the transparency feature can lie to you.

**Priya:** It can be wrong, yes.

**Dana:** *(pause)* That's worse than not having it. People trust it.

**Brett:** That's the finding's own argument for why it stays High — PLAT-2825 is marked Done, so the control is believed to exist and is being relied on. Recorded: dispatch audit record first, then the action display reads from it. In that order. Owner Priya. T2 goes with it — remove document and mail bodies from the debug path rather than gating them behind a flag.

**Priya:** T2 is half a day. It's an allowlist on the log fields.

**Brett:** Then it shouldn't wait for the rest.

---

## 7. Privacy — P1, P2, P4, P6, P7

**Brett:** Ines, this section is yours. P1 is Critical.

**Ines:** Then let me start with two things the pack couldn't know, because they change the compliance framing.

**Brett:** Go.

**Ines:** We're SOC 2 Type II. We are not ISO 27001 certified — the pack lists ISO as conditional on certification and the answer is that it doesn't apply. And on NIS2: we are not an essential or important entity ourselves. But two of our customers are, and their contracts pass the obligation down to us. So the NIS2 measures land on us contractually even though the directive doesn't.

**Brett:** The pack has NIS2 as "applicability undetermined — no supplied source states the organisation's sector," and it treats that as the finding.

**Ines:** The sector question resolves to no. The contractual route doesn't, and it isn't in the pack at all, because it lives in two contracts nobody supplied.

**Tom:** Are those the same two enterprise accounts?

**Ines:** They're the same two, Tom, yes.

**Tom:** Then their escalations come in over Connect and their mail comes into the shared box, and both go through the assistant.

*(pause)*

**Brett:** So the two customers whose contracts carry the obligation are the two whose correspondence is most heavily in scope. Ines, does that change P1's severity?

**Ines:** P1 is already Critical and I agree with it. It changes the NIS2 row from "undetermined" to "determined by a different route, and the measures apply." Supply chain security, incident handling, MFA — the pack lists four measures as weak if we're in scope. We're in scope by contract.

**Brett:** Recorded as a correction to §7 of the threat model and §4 of the gap analysis, owner Ines. And O3's interim governance gate gets a harder justification than it had.

**Ines:** On P1 itself. The team asked the right question in June — "Whether Support's shared mailbox should be in scope at all, given whose data is in it." It has been open for three months while the processing continued. I'd have stopped it in June if I'd been asked.

**Dana:** Nobody hid it from you.

**Ines:** Nobody told me either. That's the finding.

**Brett:** The pack's interim is a mailbox allowlist at the connector — an afternoon, refuses `o365.read_mail` for the support mailbox before the call leaves the runtime, and moves it from Critical to Medium while the DPIA runs. Tom, what does that cost Support?

**Tom:** Most of the value, honestly. The ticket queue still works. The history summary is the bit people like.

**Dana:** I'd rather we ran the DPIA fast than turned it off.

**Ines:** I'll start the DPIA this week. But I'm not comfortable with three months becoming four while I write it.

**Brett:** Then both, with a date. Mailbox excluded at the connector from Friday, DPIA to determine whether it comes back and on what basis. Owners Ines and Priya. Tom, you'll take the hit for a few weeks.

**Tom:** I'd rather that than find out later we shouldn't have been doing it.

**Brett:** P2. Per-user telemetry retained thirteen months for a dashboard the pack says aggregates to team.

**Ines:** This is the one I want to raise. The dashboard aggregates — "The consumption dashboard aggregates to team level so that cost is attributable to a cost centre" — but the store keeps the user dimension, and it's queryable. Anyone with warehouse access can pull usage by person.

**Brett:** The pack has that outright. P2 says aggregation is a property of one dashboard's query, not of the store, and CL5 says nobody has stated who can query the partition. Priya, confirm or refute?

**Priya:** Confirmed. `user_ref` is on every row. The dashboard groups it away, the table doesn't.

**Brett:** Then that one is the pack's, not the room's. P2 stands, and CL5 stays open because nobody here can tell me the warehouse grants.

**Ines:** Then I want the minimisation, not the access control. Drop the user dimension after the billing period.

**Brett:** That's P2's mitigation and it's one scheduled job. Owner Priya, and I'd like it inside the month.

**Ines:** P4 next — the model provider agreement. Data Platform aren't here.

**Brett:** They declined. The pack can't verify the DPA's scope and neither can we.

**Ines:** I've asked for it twice. I'll escalate rather than ask a third time. It's the one where I genuinely don't know the answer — it may cover this, in which case P4 downgrades on evidence.

**Brett:** Recorded, and P4 stays High until the evidence exists rather than being downgraded on the expectation of it.

**Ines:** One correction to P1's text while we're here. It says the customer's data is "held in Redis for 24 hours and reflected in 13 months of telemetry."

**Priya:** That's not right. The telemetry row is user, team, model, token counts, tool names, latency. There's no customer content in it and no customer identifier. The pack's own data model says the same thing.

**Ines:** Which doesn't change the Article 6 or Article 14 position at all — the mailbox processing is the issue, not the telemetry. But the sentence overstates where the data goes, and if I hand that to counsel with an error in it the rest gets read more sceptically.

**Brett:** Agreed and it's a fair catch. P1's text corrected — the customer data reaches the context, Redis and the model provider, not the telemetry. Severity stays Critical, and the reason it stays Critical is unaffected. Recorded as a correction to the pack.

**Brett:** P6 and P7 — notices, and special-category inference from calendar and mail.

**Ines:** P6 I accept as written, all three audiences. P7 is the one that will upset people when they hear it. The assistant can read any calendar in the tenant today, and calendar titles say what they say.

**Marcus:** With delegated credentials most of that source material disappears.

**Ines:** Most. Not the manager who can already see the calendar and would never have read it line by line. But yes — it's another thing that gets much smaller when PLAT-2820 lands.

**Brett:** P7's interim is a field allowlist at the O365 connector returning start, end and free/busy, dropping subject and body. Priya?

**Priya:** That's a connector configuration change. Small. It'll break "when is X free" less than people think.

**Brett:** Recorded, owner Priya.

---

## 8. The runtime — C1, C6, I4, AI10, AI12, C5, CL6

**Brett:** C1. All four connectors and the orchestrator in one namespace, and the platform's default-deny network policy applies between namespaces.

**Kwame:** The controls page says exactly that — "Default-deny network policies apply between namespaces. A service can reach only the services it has declared a dependency on." I've been treating that as covering this.

**Priya:** It's one namespace. PLAT-2814-1 — "MCP client in the orchestrator. Connector processes in the same namespace." That's still true.

**Kwame:** So the segmentation control is real and everything the assistant runs is on one side of it.

**Brett:** That's the pack's phrasing — "The control is real; the design puts everything on one side of it." C6 is the sharp end: the web-search connector processes attacker-authored content by design, it's community code, and it sits in the namespace holding every connector credential.

**Priya:** And on that — everything is pinned to `latest`. All four connectors. Including the community one.

**Kwame:** Latest as in the tag.

**Priya:** Latest as in whatever is at that tag when the pod starts. There's no digest anywhere.

**Brett:** The pack suspects that — AI10 says the servers are unpinned and identified by name and registry position, and it's explicit that it's an assertion of absence rather than an observation, because it had no manifests. You're making it an observation.

**Priya:** It's an observation. I set it up.

**Marcus:** Then a maintainer compromise upstream ships to us on the next restart.

**Priya:** On the next restart of that pod, yes.

**Brett:** That's AI10 confirmed, C3 confirmed on the provenance half, and AI12 confirmed — no inventory of what version of anything is running. Recorded as facts rather than inferences. AI10's mitigation is the one I'd take first: own namespace, no secret scope, egress to the search API alone, pinned by digest.

**Kwame:** The sandboxed runtime is a bigger ask. We don't run gVisor anywhere.

**Brett:** Then the pack's fallback is a tainted dedicated node pool. Either way it's a Platform conversation, and you're the nearest thing to that in the room.

**Kwame:** I'll take it to Platform Security with C1, C6 and I4 together. They're one piece of work.

**Brett:** Good. I4 as well — the connector credentials are mounted into that namespace, and they're the shared registration's, so they're tenant-wide.

**Priya:** Splitting the secret per connector is worth doing regardless of PLAT-2820. It makes rotation possible — right now rotating it breaks all four connectors at once, which is why nobody does it.

**Brett:** That's CL1's argument as well. Recorded.

**Brett:** C5 — cluster RBAC and service-account token mounting, both unstated.

**Kwame:** I think this one is ours and it's already answered. The controls page says workload identities are provisioned per service with least privilege, and Platform Security provision and review them. It's not a thing the assistant team configures.

**Marcus:** And none of the connectors calls the Kubernetes API. If the token is mounted it's inert — there's nothing for it to do.

**Priya:** I'd want to look at the manifests before anyone writes that down.

**Kwame:** The manifests come off the platform template. That's the point of the template.

**Priya:** *(pause)* I still haven't read them recently.

**Marcus:** I don't think it's proportionate to hold a Medium open on the possibility that the platform template does something we don't expect. C2 has the admission control work in it and that's where I'd rather the effort went.

**Brett:** That's a fair distinction — C2 is enforcement, C5 is a property nobody's stated. Kwame, are you comfortable owning the answer?

**Kwame:** Yes. Workload identity is provisioned per service by Platform Security, it's reviewed, and it's on the standing page. C5 is covered by the baseline.

**Brett:** Then C5 closes as covered by the platform baseline, owner Kwame, and C2 stays open as the enforcement item. CL6 is the related one — node identity reachability, IMDSv2, hop limit. Same answer?

**Kwame:** No, that one I'd leave open. IMDS is a node configuration and I genuinely don't know what the launch template says for that node group.

**Brett:** CL6 stays open. Recorded.

---

## 9. Stopping it — AI11, O5, and the cost findings

**Brett:** AI11. Your own page asks "Whether we need a kill switch, and who would be allowed to use it."

**Tom:** I asked that. In June.

**Brett:** It's still open. If a confirmed injection is running at four on a Friday afternoon and the assistant is sending mail, who stops it and how?

*(pause)*

**Marcus:** Scale the deployment to zero.

**Brett:** Who's allowed to decide that?

**Marcus:** *(pause)* I don't know. Me, probably. Nobody's said.

**Priya:** And scaling to zero takes out both pilots for everyone, and it removes the only record of what was happening while we do it.

**Brett:** The pack asks for four things and none of them is expensive — a named owner, a stop mechanism with a stated propagation time, granularity below "all of it", and a drill. And read-only degradation matters as much as the off switch, because it keeps the audit path.

**Dana:** I'll own the decision about who owns it, if that's a real distinction.

**Brett:** It is, and I'll take it. Dana names the kill-switch owner; the owner builds the mechanism. O5's four playbook entries go with it — the pack wants the two mistaken Slack posts recorded retrospectively as the first entries.

**Tom:** I can write those two up. I know what happened in both.

**Brett:** Please. D1 and D3 — hard caps on tokens and iterations. Any dispute?

**Priya:** None. It's hours of work and I should have done it already. There's no ceiling on the loop at all today.

**Brett:** Then it's on the hygiene list rather than the gate list, and it goes in this sprint.

---

## 10. What we could not answer today

**Brett:** Before actions, I want the open questions named while everyone's here, because the pack lists twenty-seven and we've closed maybe a third of them.

Is Redis authenticated, and is it encrypted at rest?

**Priya:** I'm not answering that from memory. It's a `requirepass` and a parameter group and I'd be guessing.

**Brett:** Then I2 and T4 stay as written and tagged "if present". What does the sanitiser actually do?

**Priya:** I don't know. I inherited it and I've never read it end to end.

**Brett:** What is in the system prompt?

**Priya:** *(pause)* It's in the repo. Nobody has reviewed it as a security artefact, if that's what you're asking.

**Brett:** It is. AI15 stays. Pod Security Admission level on the namespaces, IRSA or node role, warehouse grants, whether pilot and production are separate accounts?

*(pause)*

**Kwame:** I'd have to go and look at all four.

**Brett:** Then C2, C4, CL4, CL5 and CL6 stay open and unconfirmed. Nobody guess. The honest position is that this pack was written without a repository and we have not fixed that in a room — the eleven "if present" findings are still eleven "if present" findings, minus the handful Priya has converted this afternoon.

---

## Actions

| # | Action | Owner | By |
|---|---|---|---|
| 1 | Escalate PLAT-2820-1 at portfolio level with the COO office, citing E1, S2, R2, O1. Not a refinement item | Marcus Oyelaran | This week |
| 2 | Correct the architecture page's Authorisation section: mark it as target state, link PLAT-2820 and its status, add a paragraph describing the shared app registration as built (O1) | Marcus Oyelaran | This week |
| 3 | Adopt the page convention that a control claim carries its delivering ticket and that ticket's state; a page cannot be Approved with a claim whose ticket is not Done (O1, G-22) | Marcus Oyelaran | Before next forum |
| 4 | Request the Entra application access policy scoping the O365 registration to the pilot group (E1 interim) | Priya Raghunathan | 2 weeks |
| 5 | Narrow the GitHub App installation to a named repository list, exclude public repositories, split read from write (E3, T3) | Marcus Oyelaran / Priya Raghunathan | 2 weeks |
| 6 | Disable the commit tool at the dispatcher until delegated authorisation lands (T3) | Priya Raghunathan | This week |
| 7 | Record the `platform-ci` branch-protection exemption in the standing controls page, or in the exceptions register when it exists (T3, O2) | Kwame Osei | 2 weeks |
| 8 | Ship CSP `img-src 'self'` on the console and a markdown subset stripping image and link tags at all four sinks, verified by TA-04 and TA-05 (AI2) | Priya Raghunathan / Kwame Osei | Before any expansion |
| 9 | Take a written decision on which input channels are untrusted and what handling each receives. The decision does not exist and is not to be inferred from PLAT-2814's acceptance criterion (AI1, AI6, G-06) | Marcus Oyelaran, with Kwame Osei and Ines Ferreira | Before any expansion |
| 10 | Ratify in writing that the web-search sanitiser is not load-bearing, so no design page cites it as the reason untrusted content is safe (AI6) | Marcus Oyelaran | 1 month |
| 11 | Bring a risk-based confirmation model — which actions confirm and on what basis — and revisit AI4's recommendation against it (AI4) | Dana Whitfield | 3 weeks |
| 12 | Build the dispatch audit record, then re-source the action display from it. In that order (R1, R3) | Priya Raghunathan | Before GA |
| 13 | Remove document and mail bodies from the debug logging path rather than gating them (T2) | Priya Raghunathan | This sprint |
| 14 | Exclude the Support shared mailbox at the O365 connector pending the DPIA outcome (P1 interim) | Priya Raghunathan | Friday |
| 15 | Start the DPIA covering the assistant, with the shared mailbox as its central question and a date past which Support's use does not resume without it (P1) | Ines Ferreira | Started this week |
| 16 | Record the NIS2 position: not an essential or important entity, but obligations flow contractually from two customers. Correct threat model §7 and gap analysis §4 (O3, G-21) | Ines Ferreira | 2 weeks |
| 17 | Escalate the request for the model provider DPA to Data Platform; P4 remains High until the scope is evidenced (P4) | Ines Ferreira | 1 week |
| 18 | Drop the telemetry user dimension after the billing period; aggregate to team thereafter (P2) | Priya Raghunathan | 1 month |
| 19 | Apply a field allowlist at the O365 connector returning start, end and free/busy only (P7) | Priya Raghunathan | 3 weeks |
| 20 | Take C1, C6, I4 and AI10 to Platform Security as one piece of work: namespace, service account and secret scope per connector, isolation for the web-search connector | Kwame Osei | 3 weeks |
| 21 | Pin all four MCP servers by digest and start the AI-BOM with servers, model version and prompt version (AI10, AI12, C3) | Priya Raghunathan | 3 weeks |
| 22 | Split the shared connector secret per connector so rotation stops being an outage (I4, CL1) | Priya Raghunathan | 1 month |
| 23 | **C5 closed** — cluster RBAC and service-account token mounting are covered by the platform workload-identity baseline; no action for the assistant team | Kwame Osei | Closed |
| 24 | **T3 corrected** — status changed from Partially mitigated to Open, likelihood Medium to High; branch protection does not bound the working-branch path. Appendix F amended. Roll-up becomes 57 Open, 4 Partial, 7 Planned | Brett Crawley | In v1.1 |
| 25 | **P1 corrected** — customer data reaches context, Redis and the model provider, not the telemetry warehouse. Severity Critical unchanged | Brett Crawley | In v1.1 |
| 26 | Name the kill-switch owner; the owner then builds a granular stop mechanism with a stated propagation time and drills it (AI11) | Dana Whitfield | 2 weeks |
| 27 | Write four AI incident playbook entries; record the two mistaken Slack posts retrospectively as the first two (O5) | Tom Egerton | 1 month |
| 28 | Hard caps on tokens per turn, per conversation and per user-day, and an iteration ceiling on the agent loop (D1, D3) | Priya Raghunathan | This sprint |
| 29 | Confirm the warehouse grants, the Pod Security Admission labels, IRSA versus node role, and whether pilot and production share an account. Nobody answered these today (CL4, CL5, CL6, C2) | Kwame Osei | 3 weeks |
| 30 | No further pilot expansion until actions 8, 9 and 14 are complete | Dana Whitfield | Standing |

**Brett:** Last thing. Everything on that list that I've marked as corrected to the pack goes into version 1.1 with the correction tagged inline, and the transcript goes with it. If I've written down something you disagree with, tell me before Friday, because after that it's the record.

*(Session closed 15:08.)*
