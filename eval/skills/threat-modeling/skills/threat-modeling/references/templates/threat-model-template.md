# [System Name] — Threat Model

<!-- TEMPLATE. This is the canonical full-document scaffold; the section order is house style
     §2a and the numbering below matches it. Replace every [placeholder]; delete all HTML
     comments and any conditional section that does not apply (say why in §2 Out of scope).
     Format rules (attribution, IDs, register columns, status legend, Mermaid) live ONLY in
     references/house-style.md — do not restate or vary them here. -->

**Version:** [n.n] ([one-line change note]) · **Date:** [YYYY-MM-DD] · **Classification:** [omit for internal]
**Prepared by:** **[Reviewer name, Title]** — author of this threat model and facilitator of the [date(s)] validation session(s). Produced with AI assistance using the security-review skill set authored by **Brett Crawley, Principal Application Security Engineer**.
**Model:** [family and version actually used, e.g. Claude Fable 5.1 — never a bare family name or a guess]
<!-- Reviewer IS Brett: collapse to one line naming him once. External review: add the §1a lines. -->
**Prepared for:** [Client contact (Client organisation)] <!-- external only -->
**Supersedes:** [filename of the earlier pass, if any] · **Companion:** [`security-architecture-and-srtm` filename, if a two-document pack]
**Method:** [e.g. STRIPED per element + LINDDUN privacy pass; AI/ML surface via OWASP LLM/ASI, EoA, ATLAS; cloud via ATT&CK Cloud + Cumulus; containers via ATT&CK Containers + OWASP K10 — mapped to OWASP Top 10 (2021), [regulations]]

**Status legend:** 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted. Severities: Critical / High / Medium / Low / Info.

> [One-paragraph framing: what this document covers and why; what inputs it rests on; the standard the findings meet — every significant finding carries a concrete example threat and a concrete mitigation.]

---

## 1. What changed from the previous pass

<!-- Only when this supersedes an earlier version of the same review. Otherwise delete. -->

| Previous-pass worry | Reality found this pass | Verdict |
|---|---|---|
| **[Worry]** | [What the design/code actually shows, with issue refs] | **[Resolved / Largely resolved / Survives as [ID]]** |

New findings this pass surfaces: [IDs with one-line descriptions — credit the team where they self-identified them].

---

## 2. Context & Scope

- **What is the system?** [One paragraph.]
- **What was analysed:** [tickets, design pages, repos (feature + associated), schemas, parent model]
- **Languages & frameworks in scope:** [...]
- **Compliance triggers:** [GDPR / UK GDPR, PCI-DSS, HIPAA, SOC 2, NIS2, CRA, PSTI — assess applicability explicitly]
- **Surfaces in scope:** [tick: STRIPED · AI/ML · Cloud · Containers · Third-party dependencies]
- **Out of scope:** [what, and why]
- **Headline finding(s):** [the one or two things the reader must know]

---

## 3. Attack Surface Summary

<!-- Mermaid must be render-safe (house style §5). In a two-document pack the diagrams may live
     in the companion architecture doc — then keep the tables here and reference the companion. -->

### 3.1 High-level architecture (trust zones)
```mermaid
flowchart LR
    [...]
```

### 3.2 CI/CD trust hierarchy and blast radius
[Diagram or prose: who can change what, and what a compromise of each stage reaches.]

### 3.3 Highest-risk flow (sequence)
```mermaid
sequenceDiagram
    [...]
```

### 3.4 Network / access view
[Diagram or prose.]

### 3.5 Data classification & residency

| Store | Data | Classification | Region | Protection at rest | Retention / deletion path |
|---|---|---|---|---|---|
| [...] | [...] | [...] | [...] | [...] | [...] |

### 3.6 Trust boundaries

| ID | Boundary | Crossing | Control at the crossing | Confidence | Evidence / open issue |
|---|---|---|---|---|---|
| TB1 | [...] | [...] | [...] | [High / Medium / Low] | [file:line, ADR, #issue] |

---

## 4. Existing Organisational Controls

<!-- Inherited org/platform baseline (SCPs/RCPs, shared IAM, platform guardrails): what it closes,
     the structural gaps it does not close, account-specific carve-outs. Omit for external
     reviews with no inherited baseline — say so. -->

| Control | Closes | Does not close | Notes |
|---|---|---|---|
| [...] | [...] | [...] | [...] |

---

## 5. STRIPED Analysis

<!-- Default grouping: one subsection per STRIPED letter, findings in the canonical ID scheme
     (S1, T2, R1, I3, P1, D1, E2 — house style §3). Every distinct vulnerability is its own
     finding heading. Alternative grouping (house style §2a item 5): where trust boundaries
     dominate the risk story, group per TBn with the STRIPED letter tagged inline on each finding;
     IDs stay canonical either way. -->

### Spoofing

#### S1 — [Finding title] — **[Severity]** [status emoji]
`[STRIPED-S]` `[OWASP A0n:2021 Name]` `[GDPR Art. nn / other reg]`

- **Issue.** [What the weakness is, with evidence: file:line, ADR, issue number, doc name.]
- **Example threat.** [Inline, two or more sentences: who the attacker is, what they send through which entry point of this system, what the system does, and the human/business consequence. Never "see SAC-nn".]
- **Mitigation.** [The fix, concretely: config, code pattern, named control, where it sits, sequencing.]
- **Example mitigation.** [The actual control inline — a config/code fragment or a named feature with its setting, and what it checks. Never a list of SEC-nn IDs.]
- **Refs.** [SAC-nn · SEC-nn · TA-nn · tracking issue — cross-references live here, not in the example lines.]
- **Why it's still [severity]:** [one line where partial mitigation exists — omit if obvious.]

### Tampering
#### T1 — [...]

### Repudiation
#### R1 — [...]

### Information Disclosure
#### I1 — [...]

### Privacy
<!-- LINDDUN pass lives here: tag `[LINDDUN-L/I/Nr/D/Dd/U/Nc]` alongside the STRIPED-P tag. -->
#### P1 — [...]

### Denial of Service
#### D1 — [...]

### Elevation of Privilege
#### E1 — [...]

---

## 6. Additional Threat Surfaces

<!-- Each subsection is conditional. Delete the ones that do not apply and record that in §2. -->

### 6a. Cross-cutting findings (O)
<!-- Supply chain, documentation/security drift, observability gaps that belong to no single
     element. Finding IDs O1, O2… -->
#### O1 — [...]

### 6b. AI/ML Threat Surface (AI)
<!-- Include when AI/ML components are detected. References: ai-ml-threats.md,
     elevation-of-autonomy.md, ai-ml-atlas.md. Finding IDs AI1, AI2… Tag each finding with its
     OWASP (`[LLM01]`, `[ASI03]`), EoA (`[EoA·SA]`) and ATLAS (`[ATLAS AML.T0051.001]`) identifiers. -->

**Structural hazards (apply first — these bound everything else)**
- Adversarial subspace: [where the system relies on the model recognising or refusing inputs; the deterministic enforcement]
- Decision boundary transfer: [classifiers whose verdict is load-bearing; what backs them up]
- Context rot: [maximum session length; re-injection policy; high-stakes session policy]

**Model access per trust boundary** (ATLAS AML.TA0000): [TBn → product-mediated / API / full / physical]

**Prompt-injection surface:** [every input channel reaching the model: user, RAG, tool output, memory, agent-to-agent]
**Output sinks and the deterministic filter at each:** [renderer, tool arguments, DB, logs, agent messages]
**Agency:** [scope per agent and per tool; identity model per-agent or shared; inter-agent trust; MCP inventory, sandboxing, review gate]
**ML pipeline (non-LLM):** [training-data provenance; model loading format/source/integrity; inference endpoint controls]
**Privacy:** [output minimisation; hallucination as personal data; rectification across RAG/memory/logs/training data; Art. 22 basis]

#### AI1 — [Finding title] — **[Severity]** [emoji]
`[LLM01]` `[EoA·SA]` `[ATLAS AML.T0051.001 — Demonstrated]` `[OWASP A03]`
- **Issue / Example threat / Mitigation / Example mitigation / Refs** as in §5 — examples inline, never by reference.

**EoA elicitation coverage.** One row per card — all 30, walked against every AI/agentic element (`elevation-of-autonomy.md`). Outcome is a finding ID or "no exposure — [reason]"; never blank.

| Card | Threat | Elements walked | Outcome |
|---|---|---|---|
| EoA·SA | Prompt Injection | [...] | [AI1] |
| EoA·SK | Tool Misuse | [...] | [...] |
| EoA·SQ | Supply Chain Compromise | | |
| EoA·SJ | Memory Poisoning | | |
| EoA·S10 | Improper Output Handling | | |
| EoA·S9 | Tool Description Injection | | |
| EoA·HA | Excessive Agency | | |
| EoA·HK | Identity and Privilege Abuse | | |
| EoA·HQ | Inter-Agent Trust Exploitation | | |
| EoA·HJ | Cascading Failure | | |
| EoA·H10 | Rogue Agent | | |
| EoA·H9 | Confused Deputy Across Servers | | |
| EoA·DA | Sensitive Information Disclosure | | |
| EoA·DK | Vector and Embedding Weakness | | |
| EoA·DQ | Hallucinated Facts | | |
| EoA·DJ | Unbounded Consumption | | |
| EoA·D10 | System Prompt Leakage | | |
| EoA·D9 | Server Impersonation and Rogue Servers | | |
| EoA·CA | Transfer | | |
| EoA·CK | Retention and Removal | | |
| EoA·CQ | Inference | | |
| EoA·CJ | Minimisation | | |
| EoA·C10 | Unintervenability | | |
| EoA·T7 | Adversarial Subspace | design | |
| EoA·T6 | Geometric Attack | design | |
| EoA·T5 | Context Rot | design | |
| EoA·T4 | Decision Boundary Transfer | design | |
| EoA·T3 | Excessive Autonomy by Design | design | |
| EoA·T2 | Invisible Dependency | design | |
| EoA·T1 | Wrong Abstraction | design | |

**Architectural split (Cox-thesis check).** For each load-bearing security guarantee, name the deterministic control outside the model that carries it. Any guarantee that ends "the model will refuse" or "the classifier will detect" is an unmitigated finding.

**ATLAS attack path(s).** At least one end-to-end path, Reconnaissance / Initial Access → AI Model Access → … → Impact, naming the deterministic control that breaks it and the telemetry that would observe it. Cite `AML.CSxxxx` case studies where they exist.

### 6c. Cloud Threat Surface (CL)
<!-- Include when cloud infrastructure is in scope. Reference: cloud-threats.md. Finding IDs
     CL1, CL2… Tag `[ATT&CK T1078.004]`, `[Cumulus AS-A]`, `[CSA T-2024-01]`. State the
     provider/customer responsibility split. -->
#### CL1 — [...]

### 6d. Container & Orchestration Threat Surface (C)
<!-- Include when images, registries, container runtimes or an orchestrator are in scope.
     Reference: container-threats.md. Finding IDs C1, C2… Structure by layer: Image → Registry →
     Runtime → Orchestrator. Tag `[ATT&CK T1611]`, `[K01]`, `[D04]`, `[CIS-K8s 5.2.1]`,
     `[PSS Restricted]`. For managed platforms, say which findings are the provider's. -->

**Isolation boundary for untrusted workloads:** [which workloads run attacker-influenced input, and the deterministic boundary containing each]
**Escape path:** [app → container → node → control plane / cloud identity — where does a deterministic control break it?]

#### C1 — [...]

---

## 7. Recovery & Resilience, Dependencies, Human-Centered Security

### 7.1 Recovery & Resilience (RR)
<!-- Backup isolation, restore drills, the same-principal-deletes-prod-and-backups check.
     Finding IDs RR1, RR2… -->
#### RR1 — [...]

### 7.2 Third-Party Dependencies
<!-- Per dependency-eval.md. Copy-left licence = hard block. -->
| Library | Version | CVEs (ID / CVSS) | Licence | Maintenance | Library-specific attack vectors | Verdict |
|---|---|---|---|---|---|---|

### 7.3 Human-Centered Security
<!-- Per privacy.md: controls that fail because they fight user behaviour; privacy dark patterns. -->

---

## 8. Compliance Summary

| Framework | Applicability | Position | Key open items | Status |
|---|---|---|---|---|
| **[GDPR / UK GDPR]** | [applies because…] | [one line] | [IDs + issue refs] | [emoji] |
| **[NIS2 / CRA / PSTI / PCI-DSS / HIPAA / SOC 2]** | [assess explicitly — never silently skip] | [...] | [...] | [...] |

---

## 9. Design Flaw Summary — Fix Before [gate]

<!-- Design/deployment-level items no amount of careful coding fixes. Frame against the real gate.
     Separate launch gates from fast, cheap hardening that shouldn't wait. -->

**Launch gates**
1. **[ID]** — [action]. *[Flag the single most important item.]*

**Fast, cheap hardening that shouldn't wait:** [IDs + one-line actions].

---

## 10. Risk Register

<!-- Columns and right-sizing rule: house style §3. Internal reviews use the full column set;
     external reviews use the right-sized set shown here. Retain mitigated threats with their
     status — never delete them. -->

| ID | Threat | Category | Ref | Severity | Likelihood | Compliance | Mitigation (summary) | Status |
|----|--------|----------|-----|----------|-----------|------------|----------------------|--------|
| **T1** | [...] | STRIPED-T | OWASP A03 | **High** | Medium | PCI-DSS 6.5.1 | [summary + TA ref] | 🔴 Open |
| **AI1** | [...] | AI | LLM01, EoA·SA, ATLAS AML.T0051.001 | **High** | High | — | [...] | 🟡 filter designed, not deployed ([#issue]) |
| **CL1** | [...] | Cloud | ATT&CK T1530, Cumulus R-J | **High** | Medium | GDPR Art. 32 | [...] | 🟢 mitigated ([#issue]) |
| **C1** | [...] | Container | ATT&CK T1611, K01 | **Critical** | Medium | — | [...] | 🔵 planned |

\* [Footnote any conditional severity (`High*`): the condition and its sequencing consequence.]

**Roll-up:** [counts by status per bucket (S/T/R/I/P/D/E/O/AI/CL/C/RR), plus a one-paragraph severity summary reflecting the *current* picture.]

---

## 11. Merge Reconciliation

<!-- Against the parent / programme model. Omit if none exists — say so. -->

| Parent finding | Applies here? | Local ID | Note |
|---|---|---|---|

Net-new findings not in the parent: [IDs].

---

## 12. Assumptions & Limitations

- Reflects [the inputs] as supplied ([date]); issue-number statuses are point-in-time.
- Docs-read vs code-read: [findings tagged "if present" and what a code pass would confirm].
- Roots of trust assumed: [silicon, KMS, IdP, sub-processors].
- Threat-model stance: [e.g. physical access possible; home network may host an attacker].
- Not legal advice; [DPIA / regulatory items] to be confirmed with counsel.
- **Next iteration:** [when to re-run and with what additional access].

---

## 13. Appendices

- **A. Sources** — [tickets, pages, repos, docs]
- **B. Repositories / file map analysed**
- **C. Associated tickets** (including remediation tickets)
- **D. Next steps**
- **E. MITRE cross-map** — ATT&CK (Cloud / Containers) and ATLAS technique IDs per finding
- **F. Baseline-control coverage per finding** (internal reviews)
- **G. Session validation log** — per house style §4: date, participants, corrections, confirmed mitigations, accepted risks, severity changes, action items with owners and ticket IDs
