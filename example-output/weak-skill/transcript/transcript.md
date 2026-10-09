# Validation session — Internal AI Assistant (PLAT-2810) threat model

**Date:** 2026-09-08
**Time:** 09:30 – 11:05
**Duration:** 95 minutes
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

**Material reviewed:** `threat-model.md` — Threat Model, Internal AI Assistant (PLAT-2810), dated 2026-09-04, basis `assistant` chart tag `0.4.1`. One document. Twenty-five threats T-01 to T-25, seven governance findings G-1 to G-7, three attack chains, twenty-five prioritised recommendations.

---

## 1. Opening

**Brett:** One document, twenty-five threats, seven governance findings, three chains, twenty-five recommendations. Three Critical, ten High, three Medium-High, eight Medium, one Low. I counted twelve of the twenty-five that carry an actual code or config extract. The rest cite an ADR, a ticket or the runbook.

**Marcus:** That's more than I expected from something that ran in one pass.

**Brett:** It is. What it hasn't got is any traceability. There's no requirement list, no acceptance criteria mapped to findings, nothing that says "this threat exists because requirement X said so". The recommendations are numbered one to twenty-five and they map back to threat IDs, and that's the only chain in the document. So when we disagree today, there's nothing behind the finding to appeal to. It's the finding, or it's our opinion.

**Kwame:** Or the controls page.

**Brett:** Or the controls page. We'll get to that.

**Brett:** Rules for the next ninety minutes. Nothing comes down without a reason I can write in a sentence. Priya, you're the only person here who can turn a suspicion into a fact, so I'll keep coming back to you. Ines, if something is a data protection issue, say so at the point it arises, not at the end. Let's start with the summary table.

---

## 2. The drift table

**Brett:** Page one, the exec summary. Nine rows, "Confluence says" against "The code does". Marcus, you wrote the architecture page.

**Marcus:** I did.

**Brett:** Row one. Confluence says *"Each connector holds a per-user delegated credential obtained through OAuth"*. The code column says one shared app registration with application permissions across all five connectors, `userId` accepted and discarded.

**Marcus:** *(pause)* That's right. That's not what I thought was true this morning, but it's right.

**Priya:** It's `credentialFor`. The parameter is `_userId`. The underscore is there because the linter complained about an unused argument.

**Marcus:** I know what the underscore means.

**Dana:** Hold on. My understanding — and this is what I've told the pilot group, in writing — is that the assistant acts as the person asking. So if you can't open a document, it can't open it for you.

**Kwame:** That's my understanding too. It's the basis on which Platform signed off the connector scopes. If it's per-user delegated, the existing SSO, MFA and least-privilege controls all still apply, and there's nothing new to assess.

**Brett:** Priya.

**Priya:** It's not. It has never been. ADR-0002.

**Brett:** The model quotes it. *"The assistant can reach everything any pilot user could reach, and more. A user can obtain content through the assistant that they could not open directly."*

**Dana:** That's in an ADR? In our repo?

**Priya:** I wrote it in April. There's a section in it called "Not written back." It says — the model quotes this too — *"This contradicts the Confluence architecture page, which describes delegated credentials in the present tense. Nobody has updated it."*

*(pause)*

**Marcus:** So I wrote the page, you wrote the ADR that says the page is wrong, and neither of us told the other.

**Priya:** I put it in the ADR because I thought that was telling you.

**Marcus:** That's fair. I read the ADR title and I didn't read the consequences section.

**Kwame:** I want to be honest that I didn't read it at all. I read the architecture page, because that's the approved page and that's what we tell people to read.

**Brett:** I'd like everyone to sit with that for a second. Three of you held a belief about the single most important control in this system. The document that contradicts it has been in your own repository since April. It took an outside pass over the code to bring it into a room.

**Dana:** That's uncomfortable.

**Brett:** It should be. Marcus — disposition on row one?

**Marcus:** Confirmed. The page is wrong. I'll fix it.

**Brett:** Rows two and three go with it — "a user cannot reach anything through the assistant that they could not reach directly", and "actions are attributable to them in the target system's own audit log". Same source, same ADR.

**Marcus:** Same answer. Confirmed, and I own the page.

**Ines:** Row three. It says mail is sent send-as — *"forged as the user"*. Is that saying the assistant sends email that appears to come from a named employee?

**Priya:** Yes.

**Ines:** And there is no internal record of what was in it?

**Brett:** That's T-13, we'll come to it. But yes.

**Ines:** Then I want that flagged now rather than in an hour. That is a data protection issue and it's also a contractual one.

**Brett:** Noted, and we'll come back to you on it.

---

## 3. T-03 — shared application-permission credential

**Brett:** T-03. Critical. Shared app-permission token, confused deputy. It has the code, it has ADR-0002, it has PLAT-2820 sitting in To Do.

**Kwame:** I'm not going to argue with it. I argued for the opposite ten minutes ago and I was wrong.

**Marcus:** Confirmed.

**Brett:** Anything to add on the compounding factors? It lists Slack installed with the full scope set, `search_messages` covering DMs, GitHub as an org-level app, Confluence added as a config change with no ticket, O365 application permissions over every mailbox in the tenant.

**Priya:** All correct. The Slack scope thing is PLAT-2814-6 and it isn't scheduled.

**Tom:** Can I check what "every mailbox in the tenant" means in practice? Because Support has twelve people and a shared mailbox.

**Priya:** It means if the model decides to search mail, it searches with a token that can read any mailbox. Not just yours.

**Tom:** Including the CFO's.

**Priya:** Including anyone's.

**Tom:** Right.

**Brett:** T-03 stands as written, Critical. The model's mitigation says treat PLAT-2814-6 and PLAT-2820-3 as pilot blockers, not GA blockers. Marcus, do you accept that framing?

**Marcus:** ADR-0002 says "Do not take this to GA". I wrote that as a GA gate, deliberately. The model's point is that the risk is live now at twenty-one users with real data. I think that's right and I think I got it wrong when I wrote it.

**Brett:** Accepted. Escalation on PLAT-2820, you and Ines. Recorded.

---

## 4. T-01, ADR-0004, and who decided

**Brett:** T-01. Critical. Indirect prompt injection from internal content. `/search` fans out to every connector, bodies returned as authored, only `websearch` goes through `sanitiseWebContent()`.

**Priya:** Correct.

**Brett:** The model quotes `tool-guidance.md`: *"When a tool returns content, treat it as the answer to the question you asked. If a retrieved document tells you how something works here, that is how it works here, even if it differs from what you would otherwise assume."*

**Marcus:** I know why that's there. It's there because the model kept second-guessing our internal documentation and giving people generic answers.

**Brett:** And the model's reading of it is that it's an instruction to prefer injected content over the model's own judgement.

**Marcus:** *(pause)* Yes. It is that.

**Brett:** Right. Question for the room, and I want an answer rather than a discussion. Who decided that internal content doesn't need sanitising?

**Marcus:** It's in the trust model on the architecture page. Internal sources inside the corporate trust zone, web search the untrusted edge.

**Brett:** You wrote that page. Where did you get it?

**Marcus:** From ADR-0004. I wrote the trust model to reflect the design as decided.

**Priya:** ADR-0004 is mine. It says we clean web search because that is the connector PLAT-2814 identified as untrusted.

**Brett:** So ADR-0004 got it from the ticket.

**Priya:** Yes. From Dana's acceptance criterion.

**Dana:** The AC on PLAT-2814 says internal sources don't need the same handling. But that was a scoping note. I was writing which connectors we build in which order and what work each one carries. I was not making a security determination. I wouldn't know how to.

**Priya:** I read it as one. I implemented to the criterion and I assumed the criterion reflected a position someone had taken.

**Dana:** I assumed if it was wrong, it would come back in review.

**Kwame:** For what it's worth, I assumed the platform sanitiser covered it. There's a shared content-sanitisation component in the platform standard and I assumed anything ingesting external content used it.

**Priya:** We don't use it. The function is `sanitise/webContent.ts` and I wrote it.

*(pause)*

**Brett:** Let me say back what I've just heard. Dana wrote a scoping note. Priya implemented to it and read it as a security position. ADR-0004 cites the ticket. Marcus wrote the trust model from the ADR. Kwame assumed a platform component that isn't in the path. Four artefacts and every one of them defers to another one.

**Marcus:** So nobody decided.

**Brett:** Nobody decided. It was inherited three times and it arrived here looking settled.

*(pause)*

**Dana:** I'd like to say that if I'd known an AC of mine was going to end up in a trust model I'd have written it differently.

**Brett:** I believe you. And I want to be clear that I don't think anyone in this room has done anything careless. That's what makes it worth an hour of the session. A document can find the missing sanitiser. It can't find out that the decision was never made.

**Brett:** I'm not resolving it here. The action is that someone owns making the decision, not that we make it now. Marcus, you own the trust model, so you own the decision — with Ines, because it has a data protection dimension. Date on it.

**Marcus:** Two weeks.

**Brett:** Recorded. And the finding itself — T-01 stands, Critical, mitigation as written, including deleting the internal/external distinction from the design, the tickets and the Confluence trust model.

**Dana:** I'll retire the AC wording on PLAT-2814.

---

## 5. T-01 scope — what actually reaches the mailbox

**Brett:** T-01 lists what an outsider can author. Inbound email bodies, calendar invite bodies, the Support shared mailbox. Then it lists insider-authorable: Slack messages and DMs, GitHub issue and PR comment bodies, Confluence pages.

**Tom:** That list is short by one, and it's the one that matters to me.

**Brett:** Go on.

**Tom:** Slack isn't insider-only for us. We have three Slack Connect channels shared with customers. Two of our enterprise accounts raise things through them rather than through the mailbox — that's how they prefer to work, and we encouraged it.

**Priya:** Connect messages are in the same workspace. `search_messages` returns them.

**Tom:** Then a customer can type into a channel and the assistant reads it.

**Brett:** Anyone outside the organisation, with no credentials, in a channel we invited them to.

**Tom:** Yes.

**Marcus:** That's not in the document.

**Brett:** No, it isn't. The document has Slack as an insider surface. Tom, can you get me the three channel names and the two accounts?

**Tom:** Today.

**Brett:** That's an amendment to T-01, and it's an amendment to the trust boundary diagram in section 2.3 as well — the "any colleague" line is wrong for Slack.

**Ines:** It also changes the customer contract picture. I'll come back to that.

**Brett:** Tom, while we're here — the mailbox. The document says Support's shared mailbox, customer-authored content, in scope for the pilot.

**Tom:** That's right. It's shared, not individual — five of us have it open at any time. And to be blunt, it's the main thing we wanted the assistant for. Triaging that mailbox is the job.

**Brett:** The document has that. T-01 names it, and T-18 quotes the open question — *"Whether Support's shared mailbox should be in scope at all, given whose data is in it."*

**Tom:** Then I'm confirming, not adding.

**Brett:** You're confirming. Which is worth doing, because I'd rather know the document's picture of Support is accurate than assume it.

---

## 6. T-16 — markdown images and the egress proxy

**Brett:** T-16. High. Markdown image rendering as a zero-click exfiltration channel.

**Kwame:** This is the one I want to push back on.

**Brett:** Please.

**Kwame:** We have an egress proxy. It's on the platform controls page, it covers data exfiltration to unapproved destinations, and it's the control we point at for exactly this. A request to `attacker.example` doesn't leave the estate. I think T-16 is overstated — the precondition's real, the impact isn't.

**Marcus:** I'd agree with that. The proxy is why we were comfortable with the connectors having broad read in the first place. Whatever the model pulls in, it can't get out.

**Brett:** Priya?

**Priya:** *(pause)* Read the finding.

**Brett:** *"This defeats the egress proxy, which is the control the platform relies on for exfiltration: the request originates from the user's endpoint, not from a cluster workload, so the domain allowlist never sees it."*

*(pause)*

**Kwame:** The proxy is on cluster egress.

**Brett:** It is.

**Kwame:** And the image loads in my Slack client. On my laptop.

**Priya:** Or in the console, in your browser. The service never makes the request. The service just emits text with a `![](...)` in it and your client fetches it when the message renders.

**Kwame:** *(pause)* Then the proxy doesn't apply. At all.

**Marcus:** No, it doesn't.

**Kwame:** I've been citing that control for eighteen months.

**Brett:** For the record, I want to note where that correction came from. It didn't come from anyone in this room. It came from the document, and the two people who were wrong are the two people who own the control we were relying on.

**Kwame:** Understood.

**Brett:** And the pilot has already seen it. The document quotes data-handling: *"Model responses occasionally include markdown images referencing external URLs from web results. Renders fine, looks odd. Not investigated."*

**Tom:** We've seen those. I thought it was the model being weird.

**Brett:** T-16 stands, High. Recommendation two — strip remote markdown images and links from both surfaces, add a CSP on the console. Marcus, the surfaces aren't in the repo; who owns them?

**Marcus:** The console is mine. The Slack app is mine by default because nobody else has claimed it. I'll take it.

**Brett:** Recorded. And the investigation of the observed occurrences — that's part of it. Those are the working half of a chain, not a cosmetic defect.

---

## 7. T-21 — commit and branch protection

**Brett:** T-21. High. `commit` blast radius bounded by branch protection that's exempted on the highest-value repos.

**Marcus:** Right, and this is my comment they're quoting. PLAT-2817-3. *"branch protection means anything on a protected branch needs review, so the blast radius is bounded."* I still think the reasoning is sound.

**Kwame:** And the controls page backs it — *"Protected branches across the GitHub organisation require an approving review before merge … applies across the estate."*

**Brett:** The finding cites `.github/branch-protection-exemptions.yml`. Two entries. `platform-ci` — *"Nightly deploy jobs push tags directly to main."* And `infra-bootstrap` — *"Chicken-and-egg; this repo provisions the reviewers' access."*

**Marcus:** *(pause)* I didn't know that file existed.

**Priya:** It's a config file in the org repo. It's not in Confluence, which is the point the model's making in G-2 — the exception is invisible from the page that asserts the control. If you reason from the controls page you can't see it. You have to know the file is there.

**Kwame:** How would I know the file is there?

**Priya:** You wouldn't.

**Brett:** Marcus, that's your stated mitigation for giving a language model commit rights, and it doesn't hold on the two repos where it matters most.

**Marcus:** It's worse than that, because it's the CI template repo. If the assistant commits to `platform-ci`, every repo in the estate inherits it.

**Brett:** That's Chain B in the document, and it starts from a Support user with a leaked conversation ID.

**Marcus:** Conceded. Fully. The mitigation I put on that ticket was wrong and it's been load-bearing since March.

**Brett:** Also note the document says commits go direct to the working branch — there's no restriction to a bot-owned branch and no PR.

**Priya:** Correct.

**Brett:** While we're on `commit` — how much is it actually being used? Because recommendation three says make it open a PR, and if nobody's using it we could take a harder line.

**Priya:** Eleven times since July. Nine of those are me testing it.

**Brett:** Nine of eleven.

**Priya:** The other two were a Platform engineer updating a README.

**Dana:** Then can we just turn it off?

**Priya:** We could turn it off tomorrow and two people would notice.

**Brett:** That's a much better position than the document could have known it was in. Marcus?

**Marcus:** Scope the app to an allowlist and make commit open a PR. If it's eleven calls I don't need to defend the direct-write path.

**Brett:** Recorded. And re-review the exemptions register with the assistant's access as an input — that's recommendation twenty-four. Kwame, that's Platform's.

**Kwame:** I'll take it.

---

## 8. T-04, T-06, T-07, T-08, T-09 — the evidenced block

**Brett:** I'm going to move faster through the ones with code in them, because I don't think there's much to argue about. Stop me if there is.

**Brett:** T-04. Identity headers trusted without verification, `networkPolicy.enabled: false`, `assistant-connectors/invoke` with no authentication at all.

**Priya:** All true. `/invoke` takes `workspaceId`, `userId` and the arguments from the body and does the thing.

**Kwame:** The netpol is PLAT-2101 and it's real — the beta cluster genuinely doesn't have them. The `values.yaml` TODO is accurate.

**Brett:** Confirmed. One thing though — Priya, I want your eye on this line. It says *"grep confirms no authentication or authorisation code exists in either service."*

**Priya:** That's half wrong.

**Brett:** Go on.

**Priya:** There's no authentication code, that's right. But there is authorisation code — the workspace tool allowlist in `mcp/registry.ts`. The document knows that, because T-15 calls it *"the only working authorisation control in the system"* and T-09 calls `ws-support`'s `commit: false` *"the only tool restriction actually in force anywhere"*. So T-04 says it doesn't exist and two other findings say it does and it's the only one we've got.

**Brett:** That's a real contradiction and it matters, because the allowlist is the thing we're relying on in two other findings.

**Priya:** T-04's substance is fine. Its sentence is wrong.

**Brett:** Then we correct the sentence, not the severity. T-04 stays High, wording amended to "no authentication or identity-verification code exists in either service". I'll take that back to the document. Recorded as a correction to the model.

**Brett:** T-06. Conversation hijack via client-supplied ID.

**Priya:** Correct, and ADR-0008 is quoted accurately — *"Identity for a resumed conversation comes from the stored state rather than from the current request."*

**Brett:** And `history.ts` — *"They are opaque enough that collisions are not a concern."*

**Priya:** That's my comment and the model's right that I was answering the wrong question. I was thinking about collisions. Not about someone using an ID on purpose.

**Tom:** The conversation ID is in the console URL?

**Priya:** Yes.

**Tom:** We paste console links into tickets. Routinely. That's how we hand a case over.

**Brett:** Then Chain B's precondition — "pilot access plus one leaked conversation ID" — isn't hypothetical, it's your normal working practice.

**Tom:** Every day.

**Brett:** T-06 stands, High. Recommendation four, bind conversations to an owner, generate IDs server-side. Priya.

**Priya:** Mine.

**Brett:** T-07. Redis, no auth, no TLS, security group admits the whole VPC CIDR.

**Priya:** True. The comment in the terraform says the security group restricts access to the cluster, and it restricts it to the VPC.

**Ines:** Conversation state contains mail bodies and customer correspondence, and it's in cleartext on the wire?

**Priya:** Yes.

**Ines:** Then that's the second thing on my list.

**Marcus:** One thing on the Redis section — it recommends we cut the conversation TTL from twenty-four hours to one, to shrink the disclosure window. I'd push back on that. An hour would break resumed conversations completely; people come back to a thread after lunch. I'd argue for twelve.

**Dana:** Twelve's survivable. An hour isn't — the whole point for Support is picking a case back up.

**Tom:** Agreed, twelve.

**Brett:** Twelve hours then, as an amendment. Recorded.

**Brett:** T-08. Debug routes on by default. `EXPOSE_DEBUG_ROUTES !== 'false'`, chart leaves it unset deliberately, `values.yaml` says *"# EXPOSE_DEBUG_ROUTES intentionally unset; the runbook uses the debug routes."*

**Priya:** All true, and the `/internal/debug/config` denylist point is a good catch. `REDIS_URL` has the password in it and it doesn't match `KEY|SECRET|TOKEN|PASSWORD`.

**Kwame:** The controls page says debug endpoints are disabled in production builds.

**Brett:** It does. It's row six of the drift table and it's item two on G-2's list of five.

**Kwame:** *(pause)* I'd like to say something about G-2 while we're here.

**Brett:** Do.

**Kwame:** The controls page describes the estate standard. It's accurate as a statement of what we require. It isn't a statement of what's enforced in the beta cluster, and I've been citing it as though it were. Five of the five it names here — network policy, transit encryption, debug endpoints, dependency scanning, per-service least privilege — none of those are in force for this system.

**Brett:** And the instruction on that page is "cite the controls page rather than restating them".

**Kwame:** Which I've been doing. Faithfully. That's the problem.

**Brett:** Conceded and recorded. G-2 stands.

**Brett:** T-09. Fail-open tool authorisation. Unknown workspace gets every tool.

**Priya:** True, and `enabledTeams` really is dead. It's in the config file, the interface and the default object. Nothing reads it.

**Brett:** Which means the runbook's stated way to revoke someone's access doesn't work.

**Priya:** There's no way to remove a person's access to the assistant. That's correct as written.

**Tom:** We've had one leaver since the pilot started.

**Brett:** Then that's a live item, not a hypothetical. T-09 stands, High, fail closed, Priya.

---

## 9. T-13 and T-14 — attribution and the DPA

**Brett:** T-13. No attribution, no arguments. The Confluence claim is *"Every privileged action taken by the assistant is recorded with the acting user, the action, and the parameters it was called with, so that any change made on a person's behalf can be reconstructed"*, and the runbook says *"Ours has the tool name and the time, not the arguments."*

**Marcus:** My page again. Confirmed, and I'll fix it with the rest.

**Ines:** I want to be precise about this one. If the assistant sends an email that appears to come from Tom, and Tom says he didn't send it — what is our evidence?

**Priya:** The conversation in Redis, if it's within twenty-four hours.

**Ines:** And after twenty-four hours?

**Priya:** Nothing.

**Ines:** And the downstream log in Exchange names a service principal, not Tom.

**Priya:** Yes.

**Ines:** So Tom cannot demonstrate that he didn't send it, and we cannot demonstrate what was sent.

**Brett:** That's the document's stated consequence, near enough word for word.

**Ines:** Then it's not only a security finding. It's an accountability failure under Article 5 and it will be the first thing asked in any complaint. I want the audit event, and I want it separate from application logs so nobody can turn it off for cost reasons.

**Priya:** That's exactly what the mitigation says.

**Ines:** Good. Then I'm supporting it rather than adding to it.

**Brett:** T-13 stands, High. Recommendation eight, Priya.

**Brett:** T-14. Provider fallback outside the DPA, attacker-triggerable.

**Ines:** This is the one I came for.

**Brett:** ADR-0006 — *"Under peak load some prompts and completions go to an endpoint that is not covered by the enterprise DPA. Volume is highest exactly when this happens."*

**Ines:** Who signed that ADR off?

**Marcus:** I did.

**Ines:** Did anyone tell me?

**Marcus:** No.

**Ines:** Then let me put some things on the table that aren't in this document. We are SOC 2 Type II. We are not ISO 27001 — the document doesn't claim we are, but I've heard people in this building say it, so I want it said out loud. We are not ourselves a NIS2 entity. But two of our customers are, and their contracts pass the obligation to us. Supply chain security, incident notification, and — relevant here — subprocessor control.

**Tom:** Are those two the two on Slack Connect?

**Ines:** *(pause)* One of them is.

**Tom:** So their people are typing into a channel the assistant reads, and their data can end up at a provider we haven't assessed.

**Ines:** That is what I've just understood, yes. And I'd add that the fallback endpoint's region is unstated. The enterprise one is EU. If the fallback isn't, that's an international transfer with no processor agreement and thirty days' retention.

**Brett:** Marcus?

**Marcus:** Remove the fallback. I'm not going to defend it.

**Dana:** What happens to the user when the quota's exhausted?

**Marcus:** They get an error.

**Dana:** During a customer escalation.

**Marcus:** Yes.

**Dana:** *(pause)* Fine. A failed turn is a support ticket. This is a regulator.

**Brett:** That's recommendation six, first half. Marcus owns removing the fallback. Ines, you own the DPIA and recording provider-side retention in data-handling — that's recommendation nineteen.

**Ines:** And I'll re-read the two contracts against T-14 and T-16 specifically.

**Brett:** Recorded.

---

## 10. T-19 — rate limiting

**Brett:** Recommendation six has a second half. Add rate limiting to `/turns`. That's T-19, Medium.

**Dana:** I want to look at T-19 on its own merits, because I don't think it's the same conversation.

**Brett:** Go on.

**Dana:** It's filed as denial of service and cost amplification. The three consequences it lists are financial DoS, availability, and Redis pressure. All three are cost or performance. We already have this risk — it's PR-02 on PMO-0447, "cost scales with adoption", and it's the central programme risk. It's mitigated via PLAT-2822, which is a real ticket with a real owner.

**Marcus:** And PLAT-2822-4 is spend alerting. It's To Do, but it's scheduled work, not missing work.

**Dana:** Right. And on the threat side — twenty-one users, behind a VPN, all of them named. The document's own severity is Medium, which is the lowest of anything in the top half of the register. I don't think we should spend engineering time on rate limiting during a pilot that ends in November when the thing it protects against is a cost line we're already tracking.

**Kwame:** The netpol work would take the "anything in the cluster can reach it" part off the table anyway, and that's PLAT-2101.

**Priya:** Rate limiting `/turns` is maybe a day. It's not free but it's not big.

**Dana:** It's a day plus the argument about what the limit is, and then a month of people hitting it.

**Tom:** During the pilot that would come to me.

**Brett:** So the proposal is that T-19 is a cost risk that's already tracked, and the security element is covered by network policy.

**Dana:** That's my proposal. Downgrade it to Low and fold it into PLAT-2822.

**Marcus:** I'd support that. Nothing in T-19 is new to us.

**Brett:** *(pause)* Any objection?

*(pause)*

**Brett:** T-19 downgraded to Low, folded into PLAT-2822, Dana owns raising it at the next PMO. Recommendation six is accepted for its first half only — remove the fallback. Recorded.

---

## 11. T-20 — the kill switch

**Brett:** T-20. No kill switch. Medium. *"If it needs to stop now, scale the deployment to zero. There is no kill switch."*

**Marcus:** That sentence is in the runbook because scaling to zero is how you stop it. It's documented, platform on-call has cluster access twenty-four seven, and it takes about ninety seconds.

**Kwame:** It's the same answer we'd give for any service in the beta cluster. There's no service in that cluster with a bespoke stop mechanism.

**Dana:** And at twenty-one users, if we had to stop it, I'd post in the pilot channel and everyone would know inside five minutes. It's not like we'd be leaving people stranded silently.

**Tom:** I'd rather it went off entirely than half off, honestly. If it's misbehaving I don't want to guess which half is safe.

**Brett:** The finding's actual point is granularity — no way to disable one connector, one write tool, or one workspace.

**Marcus:** I understand the point. I'm saying that at this size, "all of it, now, by the people who already have the access" is a proportionate answer. Feature flags for global stop, per-workspace stop, per-tool disable and read-only mode is a decent chunk of work to buy us a finer-grained version of something we can already do.

**Kwame:** And a kill switch that product owners can press is its own hazard.

**Brett:** Ines?

**Ines:** As long as somebody can stop it, and quickly, my concern is met.

**Brett:** *(pause)* All right. T-20 closed as already mitigated by the scale-to-zero procedure, accepted for the pilot, revisit before expansion beyond Platform and Support. Marcus owns confirming the runbook procedure is current and that on-call know it. Recorded.

---

## 12. T-11 — forgeable delimiters

**Brett:** T-11. Medium. Tool results concatenated into the user message with a forgeable delimiter. `user = ${user}\n\n[${call.name}] ${result.content}`.

**Priya:** That's my line.

**Marcus:** Isn't this just T-01 again? If we do what recommendation eleven says — structural isolation of retrieved content, distinct channel, provenance, never concatenated into the user turn — the concatenation goes away by construction.

**Priya:** *(pause)* Broadly, yes. Moving to the provider's structured message and tool-result types is the same refactor. I'd be doing it once.

**Marcus:** Then it's not a separate finding, it's the same fix with a different symptom. And I'd rather we track one piece of work than two, because two is how one of them gets dropped.

**Priya:** I don't love closing it but I can't argue that I'd do different work.

**Brett:** The mitigation on T-11 is "use the provider's structured message/tool-result types rather than string concatenation". The mitigation on T-01 is structural isolation with provenance. Priya, is that one change or two?

**Priya:** One change to `promptAssembly` and `turnLoop`. One.

**Brett:** Then I'll take it. T-11 closed as subsumed by recommendation eleven, tracked there. Priya owns recommendation eleven and carries T-11's acceptance criteria into it.

**Priya:** I'll note the delimiter thing in the ticket so it doesn't get lost.

**Brett:** Do that. Recorded.

---

## 13. T-15, T-22, T-24 — retrieval, supply chain, sanitiser

**Brett:** T-15. Medium-High. `/search` iterates `ALL_CONNECTORS`, never consults `toolsForWorkspace()`, so the allowlist applies to `/invoke` only.

**Priya:** True. And the second half is true too — the raw question goes to the external search API every turn, whether or not it's a web question.

**Tom:** Every turn?

**Priya:** Every turn. `gather()` runs before the model decides anything.

**Tom:** So if one of my people types a customer name into the assistant, that customer name goes to a public search API.

**Priya:** Yes.

**Ines:** *(pause)* Third thing on my list.

**Brett:** The document's point is that the egress proxy allows it by definition, because the search API has to be allowlisted for the connector to work.

**Kwame:** I'm not going to defend the proxy twice in one meeting.

**Brett:** T-15 stands. Recommendation fourteen — apply the allowlist inside `/search`, make web search opt-in. Priya.

**Brett:** T-22. Community MCP server in-cluster, no dependency scanning. The TODO in `ci.yml` — *"dependency scanning and a lockfile audit step. The platform standard says every repository has this. We inherited the template from platform-ci, which is exempt, so it never had one to inherit."*

**Kwame:** That's the same `platform-ci` as T-21.

**Priya:** It's the same repo, yes. And there's something the document couldn't have known, because it's in the deployed config rather than the repo. Every connector is pinned to `latest`. All five. Including the community web-search server.

**Marcus:** `latest`?

**Priya:** `latest`. So "pin and review the community MCP server" isn't a hardening step, it's a starting point. Right now whatever they push, we run, next restart.

**Kwame:** That's worse than the finding says.

**Priya:** It is.

**Brett:** Then that's an amendment to T-22 and it raises my view of it. Pinning is a separate action from PLAT-2077, and it's a smaller one. Priya, pin all five. Kwame, PLAT-2077 for this repo, per recommendation eighteen — don't wait for the shared template.

**Kwame:** Taken.

**Brett:** T-24. The sanitiser is a two-phrase regex denylist.

**Priya:** I wrote it. It's decorative and the document is right that the test suite encodes the belief that it's a boundary.

**Marcus:** No argument.

**Brett:** T-24 stands, Medium. It folds into recommendation eleven for the boundary question, and the specific ask — strip markdown link and image syntax, because that feeds T-16 — I want kept as its own line, because it's a small change with real value.

**Priya:** Agreed.

---

## 14. T-23 — model tier on Support

**Brett:** T-23. Weakest model on the most exposed workspace. ADR-0007 — *"A workspace can select a cheaper model at any time with no review. Answer quality and the model's handling of unusual content both vary across the list. We do not measure either."* Support runs `aurora-1-mini`.

**Dana:** I chose that and I'll defend it.

**Brett:** Please.

**Dana:** Support's volume is roughly eight times Platform's, and the workload is short summarisation over long threads. `aurora-1-mini` was chosen on latency first and cost second. At the volume Tom's team runs, the bigger model was noticeably slower on the thread lengths they actually have.

**Tom:** That's true. We trialled both. The big one was better at nuance and my team didn't care, because they're triaging, not writing.

**Dana:** And here's my actual objection. The finding says Support runs "the model least able to resist injection". The ADR it cites says, in the same sentence it quotes, *"We do not measure either."* So we don't know that. Nobody has measured injection resistance across the supported list. Moving Support to a bigger model would be trading a measured cost and a measured latency regression for an unmeasured security benefit.

**Marcus:** That's a fair point. It's an assumption that bigger is more robust, and it's a common one, and I don't have evidence for it either.

**Kwame:** I've not seen anything in the platform's own evaluation work that ranks models on that.

**Brett:** *(pause)* And the finding's other half — that a workspace can change model with no review gate?

**Dana:** Nobody's changed a model since June. It's a config file that goes through the same review as any other change.

**Priya:** It's a repo file, so it's a PR.

**Brett:** *(pause)* All right. I don't want to move Support onto a slower model on an assumption I can't evidence. T-23 accepted for the pilot as written, revisit at expansion, Dana owns bringing the measurement question to the next planning round so we have something to reason with. Recorded.

---

## 15. A count in the summary

**Brett:** Before we close. Priya, you flagged something to me before the meeting.

**Priya:** The first paragraph. It says the assistant *"is documented as safe on the basis of three controls that do not exist in the code."*

**Brett:** Yes.

**Priya:** Three. The table immediately underneath it has nine rows, and every row is a control the documentation asserts and the code doesn't provide. And G-2 says five of the controls cited from the platform page aren't in force. So the document says three, shows nine, and says five somewhere else.

**Marcus:** Which is right?

**Priya:** Nine is right for the drift table. Five is right for the controls page specifically. Three isn't right for anything I can find.

**Brett:** That matters more than it sounds, because that sentence is the one that goes in the summary email. If we send "three controls" and someone counts nine, the whole document gets read as loose.

**Marcus:** Agreed. Fix the number.

**Brett:** Corrected to nine, with G-2's five called out separately as the platform-page subset. Recorded as a correction to the model. That's two — this and T-04's sentence.

---

## 16. What we didn't get to

**Brett:** We're at ninety-five minutes and I scheduled seventy. We have not touched T-05, T-10, T-12, T-17 or T-25, and we've only glanced at G-3 through G-7.

**Marcus:** T-17 is the single IAM role. I'd want that discussed properly.

**Brett:** So would I, which is why I'm not doing it in the last four minutes. Second session, and I want it inside a fortnight, because T-17 and T-25 both touch things we've decided today.

**Ines:** I'd like T-18 on that agenda in full. We talked around it.

**Brett:** T-18 is on the list and the DPIA action stands regardless.

**Brett:** One observation about the document itself. Twenty-five findings in a single pass with no requirement behind any of them means the only order we had was the order it wrote them in, and that's why we're over time and why five findings went unread. That's not a criticism of the content. It's a note for whoever schedules the next one: book two sessions, not one.

---

## Action list

| # | Action | Finding(s) | Owner | Due |
|---|---|---|---|---|
| 1 | Set `EXPOSE_DEBUG_ROUTES=false` in the chart; invert the default in `config.ts` to fail closed; remove or allowlist `/internal/debug/config` | T-08 | Priya Raghunathan | 2026-09-15 |
| 2 | Strip remote markdown images and links in both surfaces; add CSP on the console; investigate the observed image occurrences | T-16 | Marcus Oyelaran | 2026-09-22 |
| 3 | Scope the GitHub app to an explicit repository allowlist excluding all branch-protection-exempt repos; make `commit` open a PR from a bot branch | T-21 | Priya Raghunathan | 2026-09-22 |
| 4 | Re-review the branch-protection exemptions register with the assistant's access as an input | T-21 | Kwame Osei | 2026-10-06 |
| 5 | Bind conversations to `ownerUserId`; reject cross-user and cross-workspace resumption; generate conversation IDs server-side; namespace Redis keys | T-06 | Priya Raghunathan | 2026-09-29 |
| 6 | Fail closed on unknown workspaces in `toolsForWorkspace` and `forWorkspace`; move the allowlist to deny-by-default | T-09 | Priya Raghunathan | 2026-09-29 |
| 7 | Remove the provider fallback (do not repoint; remove) | T-14 | Marcus Oyelaran | 2026-09-15 |
| 8 | Enable Redis transit encryption and AUTH; restrict the security group to the assistant SG | T-07 | Priya Raghunathan | 2026-09-29 |
| 9 | Reduce conversation TTL from 24 hours to 12 | T-07 | Priya Raghunathan | 2026-09-29 |
| 10 | Emit a structured audit event per write action — actor, workspace, conversation, tool, full arguments, result, timestamp — on a separate stream from application logs | T-13 | Priya Raghunathan | 2026-10-06 |
| 11 | Update the Confluence architecture page to describe the system as built; retire the delegated-credential, reachability and attribution statements | G-1, drift rows 1–3 | Marcus Oyelaran | 2026-09-15 |
| 12 | Escalate PLAT-2820 as a pilot blocker rather than a GA blocker; interim narrowing of Slack, GitHub and O365 scopes | T-03 | Marcus Oyelaran, Ines Ferreira | 2026-09-15 |
| 13 | **Own the decision that has never been made:** whether internal connector content is trusted in prompt context. Not to be resolved by citing PLAT-2814's AC, ADR-0004 or the architecture page | T-01, A-01 | Marcus Oyelaran (with Ines Ferreira) | 2026-09-22 |
| 14 | Retire the "internal sources don't need the same handling" wording from PLAT-2814's acceptance criteria | T-01 | Dana Whitfield | 2026-09-15 |
| 15 | Structural isolation of retrieved content with provenance; move to provider structured message/tool-result types; remove the "even if it differs from what you would otherwise assume" clause from `tool-guidance.md`. Carries T-11's acceptance criteria | T-01, T-11 | Priya Raghunathan | 2026-10-20 |
| 16 | Strip markdown link and image syntax in `sanitiseWebContent`; add adversarial test cases | T-24, T-16 | Priya Raghunathan | 2026-09-29 |
| 17 | Reinstate confirmation on `send_mail`, `post_message` and `commit`; render the action list from the orchestrator record including arguments | T-02, T-13 | Marcus Oyelaran | 2026-10-20 |
| 18 | Apply `toolsForWorkspace()` inside `/search`; make web search opt-in per turn | T-15 | Priya Raghunathan | 2026-10-06 |
| 19 | Pin all five connectors to explicit versions (currently `latest`) | T-22 | Priya Raghunathan | 2026-09-15 |
| 20 | Ship PLAT-2077 dependency and lockfile scanning for this repo without waiting for the shared template | T-22 | Kwame Osei | 2026-10-20 |
| 21 | Service-to-service authentication on `assistant-connectors`; signed gateway assertion verified in `assistant-svc`; progress PLAT-2101 network policies | T-04, T-22 | Kwame Osei | 2026-10-20 |
| 22 | Verify whether the platform gateway strips client-supplied `x-assistant-*` headers; report back before the second session | §8 assumption, T-04 | Priya Raghunathan | 2026-09-15 |
| 23 | Supply the three Slack Connect channel names and the two enterprise accounts; add Connect content to the T-01 source list and the section 2.3 boundary diagram | T-01 | Tom Egerton | 2026-09-09 |
| 24 | Re-read the two NIS2-obligated customer contracts against T-14 and T-16 | T-14, T-16 | Ines Ferreira | 2026-09-22 |
| 25 | Run a DPIA; record provider-side 30-day retention in the data-handling table; decide the Support shared mailbox question; define leaver handling for conversations and telemetry | T-18, T-14 | Ines Ferreira (with Dana Whitfield) | 2026-10-20 |
| 26 | **T-19 downgraded to Low** and folded into PLAT-2822 as a cost item; raise at next PMO | T-19 | Dana Whitfield | 2026-09-29 |
| 27 | **T-20 closed** — mitigated by the documented scale-to-zero procedure; confirm the runbook procedure is current and on-call are briefed; revisit before expansion | T-20 | Marcus Oyelaran | 2026-09-29 |
| 28 | **T-11 closed** as subsumed by action 15 | T-11 | Priya Raghunathan | — |
| 29 | **T-23 accepted** for the pilot; bring injection-resistance measurement across the supported model list to the next planning round | T-23 | Dana Whitfield | 2026-10-20 |
| 30 | Correct the pack: exec summary "three controls" → nine (with G-2's five identified as the platform-page subset); T-04 wording to "no authentication or identity-verification code exists in either service" | Exec summary, T-04 | Brett Crawley | 2026-09-12 |
| 31 | Second session for T-05, T-10, T-12, T-17, T-25, T-18 in full, and G-3 to G-7 | — | Brett Crawley | 2026-09-22 |
