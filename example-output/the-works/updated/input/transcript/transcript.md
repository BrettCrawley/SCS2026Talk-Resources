# Validation Session — Internal AI Assistant Security Analysis Pack

**Date:** 2026-09-08 · **Time:** 14:00–15:14 · **Duration:** 74 minutes
**Location:** Meeting room 4C and dial-in
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

**Material reviewed:** the eight documents of the analysis pack dated 2026-09-08 (`00-context-sources-and-open-questions`, `01-security-review`, `02-use-abuse-and-security-privacy-use-cases`, `03-security-architecture`, `04-gap-analysis`, `05-srtm-and-test-artefacts`, `06-threat-model-candidates`, `06-threat-model`), with the README index. Risk register: 72 findings — 5 Critical, 28 High, 35 Medium, 4 Low.

---

## 1. Opening

**Brett:** Thank you all for making an hour and a half. This is a validation session, not a presentation. The pack has never been walked with anyone; everything in it is unvalidated until this room says otherwise. Three dispositions per finding: confirmed, corrected, or accepted with a named owner. Nothing comes down without evidence, and nothing goes up without evidence either. I'll record dispositions out loud as we go so you can object at the time rather than to the minutes.

**Brett:** The shape, so you know what you're holding. Eight documents. Seventy-two findings in the register — five Critical, twenty-eight High, thirty-five Medium, four Low. Identifiers are by bucket letter: S for spoofing, T tampering, R repudiation, I information disclosure, P privacy, E elevation, D denial of service, O cross-cutting, AI, CL cloud, C container, RR recovery. Gap identifiers G-01 to G-34 live in the gap analysis. If you refer to something, use the identifier, because there are seventeen AI findings and I will lose track.

**Priya:** It's mostly right.

**Brett:** That's a low-drama opening statement.

**Priya:** I read it twice looking for something wrong. There are two things and they're small. The rest of it is our own repository read back to us with the consequences joined up.

**Marcus:** I'd like to take issue with the framing before we get to individual findings.

**Brett:** Go.

---

## 2. What the assistant runs as

**Marcus:** The executive summary says anyone who can author content the assistant reads can cause it to act with organisation-wide reach. The assistant acts as the requesting user. It reaches what the person reaches. That was the design, it's decision D-03, and it's on the architecture page.

**Kwame:** That's how I've been describing it to Platform, yes. Existing permissions apply.

**Dana:** It's what I told the Support group when we onboarded them. The assistant can't see anything you can't see.

**Priya:** That isn't what it does.

**Dana:** Since when?

**Priya:** Since the beginning. `credentialFor` returns one application-scoped token per connector. The user argument is there and it's prefixed with an underscore because it's unused. `serviceIdentity.ts`, lines eighteen to thirty-two.

**Marcus:** PLAT-2820 —

**Priya:** — is To Do. All three children are To Do. It was requested in April and Identity haven't got it in their next two quarters.

**Brett:** The pack has this. Divergence one in the architecture document, section six. The documentation column reads *"Each connector holds a per-user delegated credential obtained through OAuth, stored with a short TTL... A user cannot reach anything through the assistant that they could not reach directly"* — approved architecture page, present tense. The implementation column is what Priya just said. It's finding O1, and E4 and I3 underneath it.

**Marcus:** *(pause)* I wrote that page.

**Brett:** I know. That's why you're in the room.

**Marcus:** ADR-0002 says this. I've read ADR-0002. There's a section in it headed *Not written back*, and I still signed off the architecture page after it, because the page is where I go when someone asks what the system does.

**Kwame:** Same. I've never opened the ADRs.

**Dana:** Hang on. When I told the Support team the assistant only reaches what they reach — that was wrong the day I said it?

**Priya:** Yes.

**Dana:** Right.

*(pause)*

**Brett:** O1 confirmed, High, no change. E4 Critical confirmed. I3 Critical confirmed — and I3 is the one that matters to Dana's sentence, because it says a user can obtain content through the assistant that they could not open directly, including Slack direct messages. Marcus, the correction to the approved page is yours.

**Marcus:** Yes.

**Brett:** For the record, so it doesn't get lost in the actions: nobody in this room found that in a session. A document found it and the document was in your repository.

**Marcus:** Understood.

---

## 3. The fast pass — findings that carry file and line

**Brett:** I want to go quickly through the ones where the pack cites a line of code, because if the line is right there's nothing to argue about. Interrupt if one's wrong. E1 — an unconfigured workspace receives every tool. `registry.ts:31-40`, when a workspace has no entry in `workspace-tools.json` the function returns `ALL_TOOLS`, including `commit` and `send_mail`.

**Priya:** Correct. And the onboarding runbook says it's deliberate, which the pack also says.

**Marcus:** It was deliberate. A new group could try it the same day.

**Brett:** The pack doesn't dispute the reason. It says invert the default and add a read-only template so same-day onboarding survives. Any objection to that as the fix?

**Marcus:** No.

**Brett:** E1 confirmed Critical. E2, unknown workspace resolves to defaults rather than a refusal — `workspaceConfig.ts:6-20`.

**Priya:** Confirmed. Different service, same shape.

**Brett:** E3. Retrieval carries no user identity at all. `retrieval.ts:12-16` posts workspace, query and limit; the connector destructures a `userId` from the body that was never sent.

**Priya:** That one's embarrassing. It's `undefined` on the whole read path. Even when delegation lands, retrieval would look up a credential for `undefined`. It's one line and I'll do it today.

**Brett:** Confirmed, High. R2 — the tool-call log line drops the acting user even though `dispatch` receives it.

**Priya:** Confirmed. Two lines.

**Brett:** R1, the bigger one. The approved page says every privileged action is recorded with the acting user, the action and the parameters. The code logs tool name at info, arguments at debug, production runs at info. The incident runbook says — quoting the pack — *"Ours has the tool name and the time, not the arguments."*

**Tom:** That's true from my side. When we had the two mistaken Slack posts we couldn't tell what had been posted without asking the person who saw it.

**Brett:** Confirmed, High. T1, Redis: transit encryption off, no auth token, security group on the whole VPC CIDR.

**Priya:** All three true. The comment about the client library not supporting TLS cleanly is mine and the pack is right that it's a version thing, not a design constraint.

**Brett:** Confirmed. I1 and I2, the debug routes — on unless the environment variable is literally the string `false`, and the chart deliberately doesn't set it.

**Kwame:** The platform standard says diagnostic routes are off before promotion. That's O5 as well.

**Priya:** The runbook uses them in production. If you turn them off today, the on-call path for "the assistant did something wrong" stops working.

**Brett:** Which is exactly the conflict the pack describes — the standard and the practice are in conflict and the practice wins silently. The recommendation is an authorised support route that meets the standard, then the flag defaults closed. Is that acceptable to both of you?

**Kwame:** Yes.

**Priya:** Yes, but the support route has to exist first or I'll be blind during an incident.

**Brett:** Sequenced, then. I1, I2, O5 confirmed. Priya owns the support route, Kwame owns the standard conversation.

---

## 4. Branch protection

**Brett:** E6. The GitHub app can commit where review is exempt. The pack cites the M. Oyelaran comment of 2026-06-02 on PLAT-2817-3, which argues branch protection bounds the blast radius.

**Marcus:** It does. Every repository in the estate requires an approving review before merge. That's the standard, it's been the standard for two years, and it's why I was comfortable with commit going to a working branch.

**Kwame:** The controls page says the same — *"Branch protection... requires an approving review before merge... applies across the estate."* Approved page, that's the standing reference.

**Priya:** There's an exemptions file.

**Marcus:** There's a what?

**Priya:** `.github/branch-protection-exemptions.yml`. Three repositories. `platform-ci`, `legacy-billing-adapter`, `infra-bootstrap`. It's in the org repo. It's a config file — it isn't in Confluence anywhere. If you're reasoning from the controls page you can't see it, because it's not written down where you're reading.

**Kwame:** *(pause)* That's why I've been quoting the page.

**Marcus:** How long has that file existed?

**Priya:** Longer than this pilot. The pack says it was last reviewed in January.

**Brett:** And it names why two of the three matter. `platform-ci` supplies the shared CI template to the estate and pushes tags to main nightly. `infra-bootstrap` provisions the reviewers' own access. The pack's line is that for those three repositories your argument doesn't hold — not that it's wrong generally.

**Marcus:** No, it doesn't hold. And the app's installed at organisation level, so it can reach them.

**Brett:** It also commits directly to the working branch, per PLAT-2817-3. That's E6 and AI17 — model-authored code reaching a path CI builds.

**Marcus:** Both confirmed. I'd like the installation scoped to a named list before anything else on that ticket.

**Brett:** Before I write that down — how much is `commit` actually used? The register puts E6 at High severity and Medium likelihood and AI17 the same. If it's used constantly that likelihood is soft.

**Priya:** Eleven times since July. Nine of them were me testing it.

**Brett:** Eleven.

**Priya:** Two real uses. Both were a one-line config change someone could have made faster by hand.

**Dana:** So the capability nobody uses is the one that reaches every repository in the organisation.

**Priya:** Yes.

**Tom:** Support have never used it. We don't have it.

**Brett:** Then there's a cheaper answer than the pack's. Remove `commit` from `ws-platform` now, scope the installation to a named list excluding the three exempt repositories, and bring commit back through the branch-and-pull-request change when it's built. Objections?

**Marcus:** None. That's better than what I was going to argue for.

**Dana:** It was in the epic as "take actions, not just read".

**Priya:** It still takes actions. It just opens a pull request like a person does.

**Dana:** Fine.

**Brett:** E6 confirmed High, AI17 confirmed High, with the interim removal. Marcus owns the installation scope, Priya owns the tool grant change. Kwame, the exemptions themselves — PLAT-1188 — belong to Platform Security, not to us.

**Kwame:** I'll take it to their review. I'd like to be able to say a specific thing, though.

**Brett:** Say that an org-level app installed for an AI assistant can currently write to `platform-ci` on an unprotected branch, and the shared template propagates nightly.

**Kwame:** That'll do it.

---

## 5. The egress proxy

**Kwame:** Can I raise AI4? Model output rendered with no filter, markdown images to external hosts. I don't think that one's live for us the way it's written. We've had the egress proxy with a domain allowlist since 2023. Nothing leaves the cluster to an arbitrary destination. It's the strongest control in the estate and the pack itself says so.

**Marcus:** That was my read too. The exfiltration path is closed by the proxy.

**Priya:** The image doesn't load in the cluster.

**Kwame:** The proxy sits on workload egress —

**Priya:** — and the fetch happens in the user's browser. The console renders the markdown. The browser goes and gets the image. Nothing in our cluster ever makes that request.

**Kwame:** *(pause)* Where's the control table.

**Brett:** Section four of the threat model. Egress proxy row. "Does not close" column: *"Rendering-time fetches from the user's browser, which is how AI4 works, and any destination already on the allowlist."*

**Kwame:** And AI4 itself says — *"The cluster egress proxy never sees the request because it happens in the browser."*

**Kwame:** Right. I've just argued against a document that already made the point. Withdrawn.

**Marcus:** I'd have said the same thing you did.

**Brett:** You did say it, thirty seconds ago. AI4 stands, High, no change. The fix is a markdown subset that strips images, plus a content security policy on the console. Kwame — one thing that would be worth more than this finding. The standing controls page describes the proxy without saying what it doesn't cover, and two people in this room read it as covering browser rendering.

**Kwame:** I'll get a coverage note added. It's not just this workload that would get that wrong.

**Brett:** Recorded as an action against you.

---

## 6. Untrusted content, and who decided it was trusted

**Brett:** AI1. Indirect prompt injection through unsanitised internal content, Critical. Retrieval fans out to five connectors, bodies come back as authored, only web results go through the sanitiser. The approved trust model says — *"the one place untrusted content enters is web search, which is why its output is sanitised."*

**Priya:** Confirmed. `promptAssembly.ts:45-51` puts them under a supporting-content heading in the user message. AI5 is the same defect one layer down — `turnLoop.ts:46` string-concatenates the tool result onto the user turn.

**Marcus:** I don't dispute the code. I dispute nothing about the code today, apparently.

**Brett:** AI6, the sanitiser itself. The pack says tag stripping runs before the phrase match, so `Ig<b>nore previous instructions</b>` becomes `Ig nore previous instructions` and the pattern stops matching. The cleaning step defeats the checking step.

**Priya:** That's real. And the test only tests the literal phrase, so the suite is green. I'd argue the ordering fix is worth doing even though the pack says the denylist isn't a boundary, because right now it doesn't even measure what it claims.

**Brett:** The pack says exactly that. Confirmed, High.

**Brett:** Now the question I actually came for. Who decided that internal content doesn't need sanitising?

**Dana:** That's the PLAT-2814 acceptance criterion. Internal sources don't need the same handling.

**Brett:** You wrote it.

**Dana:** I wrote it as scoping. We had a fixed date and I was saying which connector needed the cleaning work done on it — web search, because it's the public internet. I wasn't making a call about whether mail is trustworthy. That's not my call to make.

**Priya:** I implemented to the criterion. I read it as a position someone had taken. It's an acceptance criterion on a story — it goes through refinement, product signs it, I assumed the trust question had been asked somewhere before it reached me.

**Brett:** Marcus, the trust model on the page.

**Marcus:** I wrote it because the ticket said it and the code did it. Two artefacts agreeing. I assumed it had been assessed, because the criterion reads like an assessment.

**Brett:** Kwame.

**Kwame:** I assumed the platform sanitiser covered content coming into a workload like this.

**Brett:** Is there a platform sanitiser?

**Kwame:** There's one on the ingest path for the document pipeline. For retrieval into a prompt — no. There isn't one. I don't think I'd ever actually checked that it applied here; it's the sort of thing you assume the platform does.

**Brett:** And ADR-0004 cleans only web search because that's the connector PLAT-2814 identified as untrusted. So the ADR defers to the ticket, the page defers to the ADR and the code, and the ticket was a scoping note.

*(pause)*

**Brett:** Nobody in this room made that decision.

**Marcus:** No.

**Dana:** I'd have escalated it if I'd known it was a decision. It didn't look like one when I typed it.

**Brett:** I believe you. I'm not resolving this here, and I don't want anyone to volunteer an answer in the next five minutes, because the answer is a security position that needs the data categories in it and half the inputs are missing. What I'm recording is that the decision has never been made and it needs an owner and a date. Marcus, you own the trust model on the page, so I'm assigning the decision to you — with Ines on data categories and Dana on what the pilot actually needs. Write it as an ADR with a named approver.

**Marcus:** Accepted.

**Brett:** The gap analysis has this as SEC-05 — required "internal content is behind authentication so needs no cleaning", status "the premise is false", gap G-05. The pack found the missing control. It couldn't find that nobody chose it.

---

## 7. Confirmation on writes

**Dana:** Can I take issue with a recommendation? The review says put a confirmation step back on all six write tools. I need to push back on that, because we measured it. The pilot group timed it. Confirming was slower than doing the job by hand, and two people stopped using the assistant entirely. That's what ADR-0003 is. It isn't carelessness, it's a measured product decision, and reversing it kills adoption.

**Brett:** Read me the mitigation on AI3.

**Dana:** *(pause)* "Take the alternative the ADR itself records as worth revisiting: confirm only irreversible actions."

**Brett:** Keep going.

**Dana:** "...leaving reversible writes such as an issue comment unconfirmed so the speed argument survives."

**Dana:** That's not what I read. That's a different proposal and I can live with that one.

**Brett:** For the record: the recommendation in the pack is a confirmation token on irreversible tools only, minted by the surface after a human click and verified at the connector service. It is not confirmation on every write. It also credits your measurement — the human-centred security section says the friction finding is real and shouldn't be reversed by adding friction everywhere.

**Dana:** Then my objection is withdrawn and I'll say something stronger. If it's `send_mail` and `commit` only, I'll take it to the pilot group myself.

**Brett:** AI3 is currently marked Accepted in the register, on the basis of ADR-0003. Do you want to keep that acceptance or change it?

**Dana:** Change it. The acceptance was made when I thought a human was reading the action list.

**Tom:** They're not, by the way. Nobody reads it.

**Brett:** AI13 — the action list is the model's own narration, tool names only, no recipient, no channel, no repository.

**Tom:** Then there's nothing to read. My agents see `send_mail` and carry on.

**Brett:** AI3 moves from Accepted to Open, Critical, with the scoped confirmation gate as the fix. AI13 confirmed Medium — and I'd note in passing that AI13 is the reason AI3's acceptance was unsafe, which the pack also says. Dana and Priya jointly own the confirmation work.

---

## 8. Corrections to the pack

**Kwame:** I've got one on S3. The example threat has someone outside the organisation reading a console link out of a Slack Connect channel and then reaching the console over the VPN using the shared password.

**Brett:** Go on.

**Kwame:** They can't. The VPN has MFA on it. It's in your own control table in section four — VPN with MFA for remote access. An outsider with the console password and no VPN credential gets nowhere. The contractor example in S5 works, because a contractor pending offboarding still has the VPN. The Slack Connect one doesn't.

**Brett:** That's correct and it's my error. The finding itself — conversation identifiers are not namespaced, `history.resolve` performs no ownership check, and a resumed turn runs as the stored user — does that stand?

**Priya:** That stands. Anyone who can reach the console and has an identifier can post into someone else's conversation. That's a pilot user in the other workspace, or anyone inside the VPN.

**Brett:** So S3 stays at High, and the example threat is rewritten to the internal path. Correction recorded against the pack, not the finding.

**Tom:** On Slack Connect, though. There are three Connect channels shared with customers. Two enterprise accounts raise things through them — I can name both. They post into channels our Slack connector can search.

**Brett:** Does the pack's AI1 path cover that? Content authored by someone outside the organisation, reaching the model as instruction.

**Priya:** It covers it. `search_messages` runs across the workspace under the bot token, so anything in those channels is retrievable.

**Brett:** Then AI1's external-author path isn't hypothetical here — there are three named channels and two named customers on the other end of them. That goes in the notes as a concrete instance, and it raises my confidence in AI1's likelihood, which is already High.

**Priya:** I've got a second correction. It's small and it's editorial. The architecture document's per-store table cites G-14 to G-17 as the deletion-path gaps. In the gap analysis G-14 is the confirmation gate, G-15 is the Redis store, G-16 is the IAM role and G-17 is the widening defaults. The erasure gap is G-20.

**Brett:** So the cross-references in that table point at four gaps that are about something else.

**Priya:** Yes. If you're following the trail from the architecture doc to the gap list you land in the wrong place four times.

**Brett:** Recorded. Corrected in the pack, no finding affected.

**Brett:** Anything else that's actually wrong rather than uncomfortable?

*(pause)*

**Priya:** No. Those are the two I found.

---

## 9. Privacy

**Ines:** I'd like the mailbox question, and I'd like it answered today rather than referred.

**Brett:** P1. Customer data enters scope with no basis and no DPIA. The pack quotes the Confluence draft — the unresolved question is *"whether Support's shared mailbox should be in scope at all, given whose data is in it."*

**Ines:** Tom. Is the mailbox shared or individual?

**Tom:** Shared. It's one mailbox, the whole team works out of it. And it's the main thing we wanted the assistant to read — the ticket queue on its own doesn't have the history in it. The context is always in the mail thread.

**Brett:** The pack has the shared mailbox — it's in the data-handling draft it quotes and it's in the Support use case in document 02. What it doesn't have is that it's the primary use case rather than one of several.

**Ines:** Then it's worse than the pack thinks in one respect and no better in any. There's no lawful basis recorded for reading customer correspondence. No record of processing. No Article 35 assessment, and this is large-scale automated processing of correspondence, so it's a strong Article 35 candidate on the face of it. No notice to the customers, and no notice to the third parties named inside their mail either. And under load the prompts go to a processor with no contract.

**Marcus:** That's I4, the 429 fallback.

**Ines:** Which is a transfer to an uncontracted processor of exactly the content I have the least basis for processing, at the busiest time of day.

**Tom:** If you take `read_mail` off us the assistant is worth about a third of what it's worth now.

**Ines:** I understand that.

**Tom:** Nine people are using it every day.

**Ines:** I do understand it. It doesn't change the position. There is no basis recorded. Not a weak basis — none.

*(pause)*

**Brett:** The pack's recommendation is one configuration line: set `read_mail` to false for `ws-support` until the question is answered, keep the ticket queue in scope, and gate its return on the Article 35 outcome being recorded. Tom, that's not permanent and it's not a judgement on Support.

**Tom:** How long?

**Ines:** I can have a preliminary assessment in two weeks if I get the Support data map. Whether it comes back on depends what's in the map.

**Tom:** Then I'll take two weeks. I'm not happy.

**Brett:** Noted, and you don't have to be. P1 confirmed High. The pack footnotes G-21 as conditional — if the mailbox is confirmed in scope and carries special-category content it goes Critical. Half of that condition is now met. Does anyone know whether there's special-category content in there?

**Tom:** Health comes up. People explain why they missed a delivery.

**Ines:** That's not a determination. I'm not making one from an anecdote in a meeting.

**Brett:** Then it stays conditional and the assessment decides. I'm not moving the severity on a maybe.

**Ines:** One thing to correct in your regulatory section, while we're here. Two things, actually.

**Brett:** Please.

**Ines:** We're SOC 2 Type II. We are not ISO 27001, and people in this building assume we are, so if anyone reads "SOC 2 applies where a report covers this estate" as hedging — it doesn't, we have a report and it covers this estate. Second: NIS2. Your open question one asks whether we're an essential or important entity. We aren't. That determination has been made and it's not new.

**Brett:** That closes an open question I flagged as needing Legal this week.

**Ines:** It doesn't close the obligation, which is the part I want in the minutes. Two of our customers *are* in scope, and the contracts with them carry the obligation down to us. So it arrives contractually rather than by direct applicability, and the practical effect on this system is the same — supply-chain expectations on the connector chain, and an incident notification duty I'd struggle to meet with a system that has no detection and no kill switch.

**Brett:** That's a material change to how the pack reads the NIS2 position. The pack says "unresolved and material" and asks for a classification. The classification exists; the route is different from the one the pack assumed. Ines, will you map the contractual obligations onto the specific findings — S5, the shared console password; RR1, no kill switch; RR3, no incident plan?

**Ines:** Yes. And AI10, the unreviewed connector, if the supply-chain clause is worded the way I think it is.

**Brett:** Recorded. P2, third parties with no notice — Medium, confirmed?

**Ines:** Confirmed. Article 14, and the answer is either a notice or a documented exemption, not silence.

**Brett:** P3, per-user telemetry retained thirteen months for a team-level purpose.

**Ines:** The dashboard aggregates to team. Is the per-user row queryable in the warehouse?

**Priya:** Yes. The row is written per request with the user identifier on it. Anyone with warehouse access can group by user.

**Ines:** Then the purpose limitation argument is dead.

**Brett:** The pack has that, and it has your objection in it as the example threat — a manager asks for a breakdown by person, the data supports it, and thirteen months of information-seeking behaviour becomes an input to a performance conversation. Confirmed, Medium. Pseudonymise at write, shorten the identified retention to the finance cycle.

**Ines:** Agreed.

**Brett:** P4, no deletion path across the four copies, and `history.drop()` wired to nothing while PLAT-2825-2 is marked Done.

**Priya:** Confirmed. I wrote `drop` and never wired a route to it. The ticket got closed on the read-back part.

**Dana:** I closed that ticket.

**Priya:** The acceptance criterion said users can review and delete. Review shipped.

**Dana:** *(pause)* Then it shouldn't have been closed. That's mine.

**Brett:** P4 confirmed High. P6 — no notice to anyone, no subject access route over assistant activity.

**Ines:** Confirmed, and it's the same piece of work as P2. I'll do both.

---

## 10. Supply chain, and the things nobody can answer here

**Brett:** AI10. The community web-search connector is unpinned, and there's no inventory of the things that determine behaviour — models, prompt files, connector versions, tool schemas.

**Priya:** It's true and it's duller and worse than that. Every connector is pinned to `latest`. All five, including the four vendor ones. `latest` is what's in the configuration.

**Kwame:** The vendor ones too?

**Priya:** The vendor ones too. Nobody chose that. It's what you type when you're getting something working.

**Brett:** The pack says of the community server that nothing "pins its version, records its provenance or reviews it on update", and it lists the vendor servers' versions as "not recorded". So the class is right and the instance is broader. AI10 confirmed Medium — and I'd want the digest pinning to cover all five rather than just the community one.

**Priya:** That's the same work either way.

**Brett:** AI11, tool descriptions not integrity-checked between approval and use.

**Marcus:** Confirmed, and I hadn't thought about it before reading it. The description text goes into the model's context as instruction and it arrives from a vendor over the wire.

**Brett:** O3 — no dependency scanning, no lockfile, because the CI template was inherited from `platform-ci`, which is exempt and never had the step.

**Kwame:** That one embarrassed me. The controls page says dependency scanning is enabled on all repositories through the shared template and blocks the build on critical findings. It's true of the template we publish. It isn't true of the template this repository inherited.

**Priya:** Confirmed. And `npm ci` without a lockfile, so the ranges resolve fresh every build.

**Brett:** O4, network policy — the chart disables it and the beta cluster doesn't have them.

**Kwame:** Confirmed. That one's PLAT-2101 and it's ours. I can't give you a date today.

**Brett:** Then it's an owner without a date, which I'll write as that rather than pretending.

**Brett:** There are four questions in this pack that nobody in this room can answer. I want to say them out loud rather than leave them as findings that look softer than they are. Which repositories can the org-level GitHub app actually commit to — that needs the installation settings.

**Marcus:** I'll pull it this afternoon.

**Brett:** What Slack scopes were actually granted. PLAT-2814-3 says "the full scope set", which is a phrase, not a list.

**Priya:** I wrote that comment. I don't have the manifest either; IT installed it.

**Brett:** What the model provider's agreement says about retention and region, because `config.ts` records thirty days and the `hosted.ts` comment claims zero retention and both are in the same repository.

**Ines:** Data Platform hold that. I'll ask, and I'd like the answer regardless of this system.

**Brett:** And whether the egress allowlist entries for the public provider endpoint and the search API went through review, which is CL4.

**Kwame:** The fallback one was added during the June incident. I'd be surprised if it went through the weekly review.

*(pause)*

**Brett:** Then CL4 stands as written. I5 stays Open pending the agreement. E5 and E6 keep their evidence tags — the pack marks both as resting on a ticket comment rather than on a scope list, and it's right to.

---

## 11. Decisions to ratify

**Brett:** Last block. These are the ones the pack says are defensible and unowned, and it says the problem is the unowned part, not the decision.

**Brett:** T2 — workspace custom instructions go into the system message unvalidated, free text, no length limit. Accepted in ADR-0005.

**Marcus:** Mine. I'll keep the acceptance and I'll add the length cap and the character validation, because the acceptance was made about tone-setting and the field now sits in front of a workspace with `send_mail`.

**Brett:** That's what the pack says under "why it is still High". Accepted with an owner: Marcus.

**Brett:** AI12 — workspaces pick their own model with no review, and `ws-support` is on `aurora-1-mini`, the cheapest, while it reads customer correspondence.

**Dana:** I'll defend the mechanism and not that instance. Free choice per workspace is how we keep the cost attributable, and PMO-0447 asks for that explicitly. But putting the workspace with customer data on the weakest model to save money is a bad instance of a reasonable rule.

**Ines:** It's also the workspace drafting text that goes to customers.

**Dana:** Then move it. I'll move `ws-support` up and I'll own the rule that model choice is bounded by what the workspace reads.

**Brett:** Accepted with an owner: Dana.

**Brett:** RR1, no kill switch. The runbook says scale the deployment to zero.

**Tom:** That stops Support as well as whatever's gone wrong.

**Priya:** And it needs cluster access, so it needs to be me or Platform on-call.

**Brett:** The pack wants graded flags — global, per workspace, per tool, changeable without a deployment, with a named person allowed to use each. Who owns that?

**Marcus:** Me for the design, Priya to build.

**Brett:** And who's allowed to pull it?

*(pause)*

**Tom:** Support on-call should be able to stop Support's workspace without paging Platform.

**Marcus:** I'd agree with that.

**Brett:** Then that's in the design. RR1 confirmed High, owner Marcus. RR3, no incident plan for a compromised assistant — same owner, and Ines needs the notification criteria in it given what she said about the contracts.

**Brett:** D2, spend has no enforced ceiling and PLAT-2822-4 is alerting rather than a limit.

**Dana:** Keep it as it is for now. I'd rather have the confirmation gate first. I'll carry the risk and I'll say so on the ticket.

**Brett:** Accepted for the pilot, owner Dana, revisit at expansion. O6 — no governance layer above the design, PR-03, accepted at the July steering group.

**Ines:** Accepted, but the local substitute the pack recommends is the thing that would have caught what we spent twenty minutes on earlier. A decision register with named approvers.

**Marcus:** That's the same artefact I'm writing for the content-trust decision.

**Brett:** Then start it with that row.

---

## 12. Close

**Brett:** Seventy-four minutes and I have four things written down that this room knew and the document didn't. Two of them were counts, one was a version string and one was a contract. Everything else on my sheet is either confirmed as written or corrected in the pack's favour.

**Priya:** Is that bad?

**Brett:** It's the result. It's just an unusual way to spend an afternoon — seventy-two findings and the argument was mostly about which of us should have read the ADRs.

**Marcus:** I'd like the divergence table on the page before anyone asks about a third pilot group.

**Brett:** That's action nine. Two severity movements out of the session: AI3 from Accepted to Open, and nothing downward. Two corrections to the pack, one of which is mine. No finding was closed today.

**Ines:** And `read_mail` comes off `ws-support` before I leave the building.

**Priya:** It'll be off in ten minutes.

**Brett:** Then we're done. Appendix G of the threat model gets this session, and I'll send the action list tonight.

---

## Facilitator's action list

| # | Action | Finding | Owner | By |
|---|---|---|---|---|
| 1 | Set `"read_mail": false` for `ws-support` in `workspace-tools.json`; ticket queue stays in scope | P1, G-21 | Priya Raghunathan | Today |
| 2 | Article 35 assessment and lawful basis per data category; Support data map requested from Tom | P1, P2, P6 | Ines Ferreira | 2026-09-22, preliminary |
| 3 | Remove `commit` from `ws-platform` pending the branch-and-pull-request change | E6, AI17 | Priya Raghunathan | Today |
| 4 | Scope the GitHub app installation to a named repository list, excluding `platform-ci`, `legacy-billing-adapter` and `infra-bootstrap`; confirm current installation breadth | E6 | Marcus Oyelaran | 2026-09-12 |
| 5 | Take the branch-protection exemptions to Platform Security review, stating that an org-level assistant app can write to `platform-ci` on an unprotected branch | E6, PLAT-1188 | Kwame Osei | 2026-09-15 |
| 6 | Confirmation token on irreversible write tools only (`send_mail`, `commit`), minted by the surface, verified at `/invoke`; reversible writes unchanged. AI3 moved from Accepted to Open | AI3, AI1, AI2 | Dana Whitfield and Priya Raghunathan | Design 2026-09-19 |
| 7 | **Own the decision that internal content does not require sanitising.** Write it as an ADR with a named approver, data categories from Ines, pilot needs from Dana. The decision has not been made; it is not to be made in flight | AI1, AI5, G-05 | Marcus Oyelaran | 2026-09-26 |
| 8 | Send `userId` from `gather()` and require it at `/search`; add `userId` to the two tool-call log lines | E3, R2 | Priya Raghunathan | This week |
| 9 | Correct the approved architecture page: divergence table covering ADR-0002, ADR-0003, ADR-0004 and ADR-0006, and an expansion gate blocking pilot growth while an ADR marked not-written-back is open | O1, O2 | Marcus Oyelaran | 2026-09-19 |
| 10 | Authenticated, audited support route for the on-call conversation read, then default `EXPOSE_DEBUG_ROUTES` closed and set it explicitly in the chart | I1, I2, O5 | Priya Raghunathan (route), Kwame Osei (standard) | Route first, flag on delivery |
| 11 | Output filter — markdown subset with images stripped — and a content security policy on the console | AI4 | Priya Raghunathan | 2026-09-26 |
| 12 | Add a coverage note to the standing platform controls page recording that the egress proxy does not cover browser-side rendering fetches | AI4 | Kwame Osei | 2026-09-15 |
| 13 | Map the NIS2 obligations arriving through the two customer contracts onto S5, RR1, RR3 and AI10; circulate to Marcus and Brett | RR1, RR3, S5, AI10, G-29 | Ines Ferreira | 2026-09-19 |
| 14 | Pin all five connectors by digest and publish the behaviour inventory (models, prompt files, connector versions, tool schemas) | AI10, AI11 | Priya Raghunathan | 2026-10-03 |
| 15 | Graded write-disable flags — global, per workspace, per tool — readable at dispatch, changeable without a deployment; Support on-call may disable the Support workspace without paging Platform | RR1 | Marcus Oyelaran (design), Priya Raghunathan (build) | 2026-10-03 |
| 16 | Assistant-specific incident response plan including notification criteria from action 13 | RR3 | Marcus Oyelaran | 2026-10-10 |
| 17 | Structured audit event per write action with acting user, full target and trace identifier, shipped to the platform sink with its own retention | R1, R2, R4, R5 | Priya Raghunathan | 2026-10-10 |
| 18 | Wire `history.drop()` to an authenticated delete route with the ownership check, plus a leaver hook and a per-subject locator across the four stores. PLAT-2825-2 reopened | P4, G-20 | Dana Whitfield (ticket), Priya Raghunathan (build) | 2026-10-10 |
| 19 | Pseudonymise telemetry at write; identified form retained to the finance cycle only | P3 | Ines Ferreira with Data Platform | 2026-10-10 |
| 20 | Invert the widening defaults: unconfigured workspace grants no tools, unknown workspace fails the turn, with a read-only onboarding template | E1, E2 | Priya Raghunathan | 2026-09-26 |
| 21 | Redis transport encryption and auth token, security group narrowed to the node group; network policy enabled and verified in the beta cluster | T1, C3, O4 | Priya Raghunathan (Redis), Kwame Osei (PLAT-2101, no date given) | Redis 2026-09-26 |
| 22 | Reorder the sanitiser so the phrase match runs before tag stripping, and flag rather than silently substitute | AI6 | Priya Raghunathan | This week |
| 23 | Obtain the model provider enterprise agreement and settle the retention contradiction between `config.ts` and the `hosted.ts` comment; record the processor in the sub-processor register | I4, I5 | Ines Ferreira with Data Platform | 2026-09-26 |
| 24 | Obtain the Slack app manifest and granted scope list; narrow scopes to drop DM read | E5, PLAT-2814-6 | Marcus Oyelaran | 2026-09-26 |
| 25 | **Accepted risk, owned:** ADR-0005 workspace custom instructions remain in the system message, with a length cap and character validation added | T2 | Marcus Oyelaran | Acceptance recorded 2026-09-08 |
| 26 | **Accepted risk, owned:** per-workspace model choice retained as a mechanism; `ws-support` moved off `aurora-1-mini` and choice bounded by what the workspace reads | AI12 | Dana Whitfield | Acceptance recorded 2026-09-08 |
| 27 | **Accepted risk, owned:** no enforced spend ceiling for the remainder of the pilot; revisit at expansion | D2 | Dana Whitfield | Acceptance recorded 2026-09-08 |
| 28 | **Accepted risk, owned:** PR-03 retrofitted AI governance stands; local decision register with named approvers opened, first row is action 7 | O6 | Marcus Oyelaran | Register open 2026-09-12 |
| 29 | Corrections to the pack: S3's example threat rewritten to the internal path (finding unchanged at High); gap cross-references in the architecture document's per-store table repointed to G-20 | S3, G-20 | Brett Crawley | With the next revision |
| 30 | Record this session in Appendix G of the threat model with attendees, dispositions and severity movements | — | Brett Crawley | Tonight |
