<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Brett Crawley -->

# Deliverable House Style & Attribution

Apply this whenever the skill produces a **written security deliverable for a real system** — a threat model, security review, gap analysis / SRTM, security-architecture document, use/abuse-case document, or an implementation guide. The goal is that every document looks and reads consistently, carries proper attribution, and — critically — **renders cleanly when exported to PDF**. Apply it to every threat-modelling output by default — right-size the *depth* of each section to the system's risk, not the *number* of sections.

---

## 1. Mandatory attribution block

Every produced document must carry a **Prepared by** line near the header, plus Date, Version, and a one-line status/change note. Attribution has two parts, and both matter:

1. **The reviewer who ran this review** — the AppSec team member producing the document, **with their job title**. If you don't know who is running the review, **ask** ("Who should I cite as the author, and what's their title?") — do not invent a name or title.
2. **Credit to the skill author** — state that the analysis was produced with the AI-assisted security-review skill set **authored by Brett Crawley, Principal Application Security Engineer**. This credit is fixed and should appear even when someone else runs the review.

Where the work involved **live validation sessions** (a threat-modelling walkthrough with the solution owner/architects), name the **facilitator and their role** and the architects/owners who validated, and reference the session date(s).

**Template (reviewer is someone other than the skill author):**
```
**Prepared by:** **<Reviewer name>, <Title>** — author of this <document type>
and facilitator of the threat-modelling validation session(s). Produced with AI assistance
using the security-review skill set authored by **Brett Crawley, Principal Application
Security Engineer**.
**Model:** <family and version actually used, e.g. Claude Fable 5.1>
```

**Template (reviewer IS Brett — collapse to one):**
```
**Prepared by:** **Brett Crawley, Principal Application Security Engineer** —
author of this <document type> and facilitator of the validation session(s); produced with
AI assistance.
**Model:** <family and version actually used, e.g. Claude Fable 5.1>
```

The **Model:** line is mandatory in every variant, on its own header line, naming family *and* version. "Claude", "an LLM", "latest" and a guessed name all fail the gate — if you do not know which model you are, say so to the reviewer and ask before shipping rather than inventing one.

**What the header must not contain.** No `Author:` label (it is `Prepared by:` with the attribution sentence); no `Document: n of m` (name siblings under `Companion:` by filename); no `Session participants:` or narration of how the review was run ("sole analyst", "desk review") — that belongs in Assumptions & Limitations, once, and in Appendix G only if a session actually happened. If no validation session took place, drop "facilitator of the validation session(s)" from the attribution rather than claiming it. A version-history / "Delta from previous version" table is not a substitute for the header lines and is forbidden for a first version: §2a item 1 exists only when `Supersedes:` names an earlier pass.

Tailor per document (e.g. an implementation guide can note it "includes research the reviewer committed to run in the session"). Keep it factual — cite only titles/roles you actually know.

### 1a. External / client-review header variant

When the review is performed **for an external client** rather than an internal team, extend the header:

- **Prepared for:** `<Client contact> (<Client organisation>)` — external review by `<Reviewer>`.
- **Classification:** mark the document (e.g. `Confidential (external review)`).
- **Supersedes:** name any earlier pass this document replaces (e.g. the initial website-only analysis), by filename.
- **Companion:** name the sibling document(s) in the pack (e.g. the architecture/SRTM half alongside the threat-model half), by filename, and say in one line how the pack divides the work.
- **Method line:** one line stating the frameworks applied and the regulatory mappings (e.g. `STRIPED per trust boundary + LINDDUN privacy pass, mapped to OWASP Top 10 (2021), UK GDPR, and PSTI 2022`).

External reviews typically have **no org baseline and no shared Jira** — see §3 for how the risk-register columns right-size in that case. Reference the client's issue tracker numbers (`#2472`) where they exist.

---

## 2. Document structure (house style)

Two families. Right-size depth to risk; omit sections that genuinely don't apply and say why.

### 2a. Threat model
Use this section order so workload threat models line up with the programme model. The numbering is the numbering of `references/templates/threat-model-template.md`, which is the only full scaffold — start every real-system threat model from it:

0. **Title + header** (Prepared-by block, version, date, session-validation note; external variant per §1a where applicable).
1. **What changed from the previous pass** *(when this supersedes an earlier version of the same review)* — a three-column delta table: **previous-pass worry | reality found this pass | verdict** (resolved / mostly resolved / survives as `<finding ID>`). Close the section by naming net-new findings this pass surfaced. This is distinct from merge reconciliation against a *parent* model (item 11): it shows the reader the review is accumulating, and it credits what the team fixed.
2. **Context & Scope** — What is the system? · What was analysed · Languages & frameworks in scope · Compliance triggers · Out of scope · **Headline finding(s)**.
3. **Attack Surface Summary** — Mermaid **high-level architecture** (trust zones), **CI/CD trust hierarchy & blast radius**, a **sequence diagram** for the highest-risk flow, a **network/access** view; plus **Data classification & residency** and **Trust boundaries** tables. Give each trust boundary a stable ID (`TB1`, `TB2`, `TB1b`…) and a **Confidence** column (how sure are we the stated control actually holds — cite the open issue where it doesn't yet).
4. **Existing Organisational Controls** — the inherited org/platform baseline (e.g. SCP/RCP), what it closes, and the structural gaps it does *not* close. Note any account-specific carve-outs. *(Omit for external reviews with no inherited baseline — say so.)*
5. **STRIPED Analysis** — findings grouped Spoofing / Tampering / Repudiation / Information Disclosure / Privacy / Denial of Service / Elevation of Privilege (the LINDDUN pass sits under Privacy, tagged `[LINDDUN-Nc]` etc.). **Alternative grouping:** where trust boundaries dominate the risk story (typical for device/IoT and multi-zone systems), findings may instead be grouped **per trust boundary** (TB1, TB2…) with the STRIPED category tagged inline on each finding (`[STRIPED-I/E]`). Either way, finding IDs stay on the canonical scheme (§3).
6. **Additional Threat Surfaces** — conditional subsections, each with its own ID bucket: **6a Cross-cutting (O)** for supply chain, doc/security drift and observability; **6b AI/ML (AI)** per `ai-ml-threats.md`, `elevation-of-autonomy.md`, `ai-ml-atlas.md` — includes the structural-hazards check, the Cox-thesis architectural split and at least one ATLAS attack path; **6c Cloud (CL)** per `cloud-threats.md`; **6d Container & Orchestration (C)** per `container-threats.md`, structured Image → Registry → Runtime → Orchestrator. Delete subsections that don't apply and say so in Context & Scope.
7. **Recovery & Resilience**, **Third-Party Dependencies**, **Human-Centered Security**.
8. **Compliance Summary** — per applicable framework (GDPR/UK GDPR, PDPA, NIS2, CRA applicability, SOC 2 / ISO 27001, Cyber Essentials, PSTI). Assess applicability explicitly — never silently skip CRA/NIS2. Where the product has **life-safety consequences**, `Safety` is a valid Reference/Compliance tag in its own right.
9. **Design Flaw Summary — Fix Before Production** — prioritised, ticketed. Frame against the real gate (e.g. "fix before customer #1"); separate **launch gates** from **fast, cheap hardening** that shouldn't wait.
10. **Risk Register** (see §3) with a roll-up summary table.
11. **Merge Reconciliation** vs the parent/programme model — which parent findings apply here, which are net-new, which don't apply.
12. **Assumptions & limitations** — what the review rests on and what it did *not* do. State explicitly: docs-read vs code-read (tag inferred findings "if present" and name what a code pass would confirm); the roots of trust assumed (silicon, KMS, IdP, sub-processors); that issue-number statuses are point-in-time; and a not-legal-advice line where DPIA/regulatory items are in scope. End with a **next-iteration pointer**: when to re-run and with what additional access.
13. **Appendices** — A: sources; B: repositories/file map analysed; C: associated Jira tickets (incl. remediation tickets); D: next steps; E: MITRE cross-map (ATT&CK Cloud/Containers and ATLAS technique IDs per finding); F: baseline-control coverage per finding; **G: Session validation log** (see §4).

### 2b. Companion documents
- **Security Review (executive)** — Executive summary (lead with the *current, post-session* posture, not the raw first-pass) · Scope & method · Risk posture at a glance (table) · Design-vs-implementation reconciliation · Regulatory posture · Prioritised recommendations & gate readiness · What's done well (keep) · Next steps. This is what leadership reads first — keep it honest and current.
- **Gap Analysis / SRTM** — Assumptions & context · Requirements classification (FR/SEC/PRV/PERF/COMP) · Gap analysis (security/privacy/regulatory/performance) with a **consolidated gap list** (`G-nn | title | severity | type`) · Regulatory compliance assessment · Refined requirements (strict superset — never drop originals; mark each `[NEW — from SAC-xx/G-nn]` so provenance is traceable) · **SRTM** (requirement → use case → threat → control → test → priority) · Test artifacts (each `TA-nn` with: type — attack / functional / privacy verification; the scenario; *expected* outcome; tools; priority) · **Recommended sequence** bucketed as: launch gates · fast hygiene (days, cheap) · near-term · **decisions to ratify** (accepted residuals to carry knowingly, in an ADR — not fixes). Open with a **Headline** section that leads with credit for what's genuinely strong before the themed clusters of what remains — reviews land better and read more honestly when they acknowledge good engineering first. A **Privacy by Design scorecard** appendix (the seven PbD principles vs the system's posture) is encouraged where privacy is a first-order concern.
- **Security Architecture** — Architectural context/constraints · System context (C4-L1 Mermaid) · Component decomposition · **Data-flow diagram with trust zones** · **Data model & schemas** (Mermaid `erDiagram` of the entities carrying sensitive data, with classification annotated per field, plus a per-store table: location, classification, protection at rest, retention, deletion path — schema-level gaps get a G-nn) · Control architecture (identity, crypto, network, detective, provisioning) · Data lifecycle · Security implications of accepted ADRs · Assessment against principles · Architectural changes required (vs tactical fixes) · New requirements surfaced.
- **Use / Abuse / Security-Use-Case** — Use cases (UC) · Security abuse cases (SAC) · Privacy abuse cases (PAC) · Security use cases / countermeasures (SUC) · Privacy use cases (PUC). Every abuse case links to a threat-model finding and to at least one counter-use case; implemented controls carry evidence and residual risk.
- **Implementation guide** (when a finding needs one) — the finding in one line · what the platform does/doesn't do (with sources) · layered controls in priority order · concrete config/code (buildspec, Terraform, etc.) · acceptance criteria · effort/sequencing · sources.

---

## 3. Findings, severity, status & the risk register

- **Finding IDs:** STRIPED letter + sequence (`S1`, `T2`, `R3`, `I2`, `P1`, `D1`, `E1`) for §5 findings; bucket prefixes for the additional surfaces — `O` cross-cutting/supply chain, `AI` AI/ML, `CL` cloud, `C` container/orchestration, `RR` recovery & resilience (`AI1`, `CL2`, `C1`, `RR1`). A prompt-injection finding is `AI1`, not `T2`. The number is a sequence, not a service — note this so `S3` isn't misread as "Amazon S3". Cross-reference the parent/programme finding where one exists. **This scheme is canonical even when findings are grouped per trust boundary** — do not invent domain-prefixed IDs (`T-LAN-1`, `T-PRV-2`); the boundary and domain belong in the finding title and tags, not the ID.
- **Risk register columns (keep this order):** `ID | Threat | Severity | Likelihood | Baseline state | Compliance | (parent) ref | Mitigation summary | Jira | Status`. **Right-size the columns to what actually exists:** for external/client reviews with no org baseline, no parent model, and no shared Jira, drop `Baseline state` and `(parent) ref`, replace `Jira` with the client's tracker references (or fold issue numbers into Mitigation/Status), and add `Category | Ref` columns after `Threat` for the STRIPED/LINDDUN/AI/Cloud/Container category and the OWASP / ATT&CK / ATLAS / Cumulus / CSA / K-D-CIS / Safety reference.
- **Baseline-state legend:** green (org/platform baseline closes it) · amber (baseline narrows blast radius, workload action still required) · red (baseline does nothing). Use the traffic-light emojis if the render target supports them.
- **Unified status legend (verbatim — do not add, rename or drop states):** 🔴 **Open** (no mitigation started) · 🟡 **Partial / In progress** — *always cite the tracking issue inline* (e.g. `🟡 fix merged, deploy pending (#2472)`) · 🔵 **Planned** (designed/roadmapped, not started) · 🟢 **Mitigated / Live** · ⚪ **Accepted** (a documented, owner-approved risk acceptance). Compound statuses are fine where honest (`🟢 mitigated · 🟡 rotation undrilled`). Where the client's own docs carry an honesty legend, adopt theirs and say so — don't force a translation.
- **Conditional severity:** where severity depends on a condition (e.g. real customer data on a fielded device), mark it with an asterisk (`High*`) and footnote the condition under the register — this keeps the sequencing argument honest without inflating the current picture.
- **Evidence-based:** cite `file:line`, ADR/NFR IDs, org policy names, and **ticket IDs**. **Retain threats that already have mitigations** — record the mitigation and its evidence with a status rather than deleting the threat; that traceability is the point. Where a finding rests on documentation rather than code, tag it **"if present"** and name the check that would confirm it.
- Include a **register roll-up** (counts by status per STRIPED bucket) and a one-paragraph severity summary that reflects the *current* picture.

---

## 4. Session-validation log & revision history

Security documents are living artefacts validated with the team, so make the provenance explicit:

- When a finding is confirmed/corrected/accepted in a **live session**, tag the change inline (e.g. `[session 2026-07-16]`) with the outcome, and maintain an **Appendix "Session validation log"** capturing: corrections to the model, confirmed mitigations, accepted risks, severity downgrades/upgrades, and **action items with their ticket IDs and owners**.
- **Bump the version** and add a one-line change note on each material update; keep prior versions as backups so before/after can be diffed.
- If the review ran across multiple sessions, log each separately (date + participants) and note anything not yet reached.
- When a new version **supersedes** a previous full pass (not just a session update), say so in the header (§1a) and open with the delta table (§2a item 1).

---

## 5. Mermaid diagrams — render-safe rules (Mermaid ~v11; important for PDF export)

Diagrams are exported to PDF, and the Mermaid parser is strict. These rules prevent the parse failures that otherwise appear only at render time:

- **Flowchart NODE and EDGE label text must not contain** parentheses, semicolons, arrow glyphs, middle-dots, the warning glyph, or circled numbers. Parentheses raise a `PS` parse error; a semicolon is treated as a statement separator. Replace: middle-dot → `/` or `,`; arrow glyph → `to`/`then`/`-`; warning glyph → drop it (never `(!)` inside a node label — that reintroduces parentheses); circled `1` → `1.`.
- **Quoted subgraph titles are safe** for punctuation and parentheses: `subgraph EDGE ["S3 edge (IAM + TLS only)"]`. The same applies to **quoted node and edge labels** (`NODE["label (with parens)"]`, `-->|"label"|`) — but when in doubt, keep the banned characters out of labels entirely.
- **Shape delimiters are fine:** cylinder `[( ... )]` and stadium `([ ... ])` — the parentheses there are syntax, not label text (keep inner text free of the banned characters).
- **Emojis:** use only simple ones known to render (globe, office building) or none; avoid variation-selector emojis (e.g. the cloud emoji).
- **Don't** chain a labelled edge directly into a subgraph, and **don't** combine `&` multi-target/source with chaining — split into separate statements.
- **Sequence diagrams:** message text may contain parentheses but still **no semicolons**.
- **ER diagrams (`erDiagram`):** attribute names must be single tokens (no spaces); annotations (classification, encryption) go in the quoted comment string after the attribute; relationship labels take no parentheses.
- **classDef styling** is encouraged for consistent visual semantics across the pack (e.g. one class for data stores, one for HSM/key material, one for admin planes) — define classes at the bottom of each diagram.
- **Before shipping, run the lint:** `python3 scripts/check_mermaid.py <deliverable>.md` (in the skill folder). It flags semicolons in sequence messages, banned characters in flowchart labels and edges, `&`-with-chaining, and erDiagram attribute/relationship issues, and exits non-zero. A deliverable is not finished until it exits 0. A manual pass is not a substitute — semicolons in sequence messages are the recurring miss. `scripts/check_deliverable.py` runs this and the rest of the house-style checks together; it is the shipping gate.

---

## 6. Tone

Specific over generic ("the search endpoint concatenates user input on line 47" beats "injection risk"). Actionable — each finding has a concrete mitigation. Proportionate — don't bury the one Critical in a sea of Lows. Honest and current — the executive summary should reflect the latest validated state, and threats with mitigations stay in the register with their status, not airbrushed out. **Credit where due** — when a design is genuinely strong, say so up front and by name (the specific control, not "good security posture"); a review that acknowledges what the team got right earns the standing to be blunt about what they didn't. When agreeing with a risk the team already self-identified, say you're agreeing — don't present their finding as your discovery.

---

## 7. Worked examples in findings (make each finding concrete)

Every significant finding should carry a concrete **example threat** and an **example mitigation**, not just an abstract description:

- **Example threat** — a short attacker walkthrough showing how the weakness would actually be exploited *in this system* (e.g. "an attacker submits `' OR 1=1--` to `/search`, returning the full customer table"). The best examples name the *human consequence*, not just the technical one — "who is home, when they sleep, when the bathroom is occupied" lands harder than "PII disclosure".
- **Example mitigation** — a short illustration of the fix: a config snippet, code pattern, or named control (e.g. "use parameterised queries: `cur.execute('... WHERE id = %s', [id])`").
- Where a finding is severe despite partial mitigation, add a one-line **"why it's still <severity>"** justification so the rating survives the validation session.

**A cross-reference is not an example.** `Example threat: see SAC-001` or `Example mitigation: SEC-004, SEC-005; test TA-101` fails this section and must be rewritten. The abuse case, requirement and test artifact IDs go in a separate `Refs:` line; the example lines carry the substance inline, even when a SAC or SEC exists for it in the companion document — the reader of the threat model must never have to open another file to understand a finding. Minimum content:

- **Example threat** — who the attacker is, what they send or do, through which entry point of *this* system, what the system does in response, and the human or business consequence. At least two sentences with system-specific nouns (endpoint, field, queue, tool name, principal). "An attacker could exploit this" is not an example.
- **Example mitigation** — the actual control: a config fragment, a code pattern, a policy statement, or a named product feature with the setting that makes it work, and where in the architecture it sits. If it is a deterministic control, say what it checks; if it is a backstop, say so. A list of requirement IDs is not a mitigation.

Worked examples are what make a finding land with engineers in the validation session; abstract statements ("injection risk") get waved through, a concrete scenario does not. Draw examples from the actual system in scope. Where a related threat model already has a vetted **example-threat / example-mitigation catalogue**, reuse and adapt its entries rather than reinventing them. In the finding template, add an `Example:` and `Example mitigation:` line under `Description` / `Mitigation`.

---

## 8. Inputs to request before starting

Before generating, confirm you have (and if not, **ask for**) the inputs the analysis depends on:

- the initiative / design tickets (Jira) and the design pages (Confluence);
- the **relevant source repositories checked out locally — the feature repo AND its associated repos** (dependencies, shared libraries, infra). Teams routinely under-list these, so ask explicitly for associated repos, not just the headline one;
- the **parent / programme threat model** where one exists, as background so the workload model builds on it rather than duplicating it;
- the **data schemas** — DDL/migrations, ORM models, or ERDs for every store touching personal or sensitive data. The schema is where PII classification and encryption assessment actually happen: undeclared PII in free-form fields, unprotected columns, and missing deletion paths are found by reading the schema, not the prose. Without it, every privacy and encryption-at-rest finding is inferred and must be tagged "if present";
- the **previous version of this system's threat model**, if one has been produced before — seed the review with it so context accumulates over time, and open the new version with the §2a delta table;
- who to cite as the reviewer (name + title) and the session participants.

Don't start a deep analysis under-fed: a missing associated repo or the parent model is the most common cause of gaps. If the review proceeds on documentation without code access, that is workable — but say so in Assumptions & limitations, tag inferred findings "if present", and set the next-iteration pointer to a code-confirmed pass.

---

## 9. How this fits the human engagement (light pointer)

These skills generate the artefacts; the surrounding human process is what makes them trustworthy. In brief: **share** the doc set with the solution owners before the session; **validate live** in a recorded walkthrough where owners are asked to call out errors and decisions **out loud** (only what reaches the transcript can be fed back); **feed the transcript back** to update the threat model to match the agreed decisions; then **propagate** those changes to the companion documents so they don't drift; and **store** the finished threat model as versioned markdown in the team's repo so the next feature review can be seeded from it. Full detail lives in the team's threat-modelling process documents.

---

## 10. Standard engagement prompt & model choice

A single canonical prompt drives the engagement: invoke all three skills together; do the **use / abuse / security-use-case** work first (to gather requirements and surface gaps) **then** the threat model; point at the tickets, Confluence and checked-out repos (feature + associated) and the parent model; require existing mitigations recorded against each threat with ticket IDs (mitigated / partial / planned) rather than dropped; produce the full document set in markdown, MVG house style, render-safe Mermaid, with worked example threats and mitigations; and ask for the reviewer's name/title and the session participants. Run generation and transcript-merge on a **high-capability model** (e.g. Claude Opus 4.8 / Opus 5 / Fable) — cheaper models increase rework and net cost more.

---

## 11. Templates

The only full-document scaffolds live in `references/templates/`. This file defines the rules; the templates apply them; nothing else in the skill restates either.

- `threat-model-template.md` — the canonical threat model. Section numbering matches §2a exactly; the AI/ML, cloud and container surfaces are conditional subsections of §6.
- `security-architecture-srtm-template.md` — the architecture + requirements half of a two-document pack (headline, validated architecture with trust-boundary table, data model, gap analysis, UC→SAC→SUC loop, refined requirements, SRTM, test artifacts, recommended sequence, PbD scorecard).

Use them as scaffolds, not straitjackets: keep the section order and table shapes, replace every `[placeholder]`, delete conditional sections that don't apply (and say so in Context & Scope), and delete guidance comments before shipping.
