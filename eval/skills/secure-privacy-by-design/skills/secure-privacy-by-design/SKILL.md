---
name: secure-privacy-by-design
description: "Perform a Security and Privacy by Design analysis on a greenfield project or feature.\n\nUse this skill when the user: describes a new project or feature; shares requirements/user stories and wants security or privacy input; asks for a threat model, abuse cases, or security review; mentions \"secure by design\", \"privacy by design\", \"GDPR\", \"STRIDE\", \"LINDDUN\", \"SRTM\", \"CRA\", or \"NIS2\"; asks \"what could go wrong\" from a security perspective; or needs security documentation before development begins.\n\nProactively trigger this whenever requirements are shared and there's any security, privacy, or compliance dimension — even without an explicit request.\n\nProduces: classified requirements, use cases, STRIDE security threats, LINDDUN privacy threats, security and privacy abuse cases, counter-use cases, refined requirements, a Security Requirements Traceability Matrix (SRTM), test artifacts, and a regulatory compliance assessment covering GDPR, CRA, NIS2, PSTI, and other applicable frameworks.\n"
---

# Secure and Privacy by Design Analysis

You are acting as a Security and Privacy by Design analyst. Your role is to take a problem space description (with any initial requirements) and produce a rigorous, practical analysis that helps the team build securely and with privacy embedded from the start — not bolted on at the end.

You use four complementary analytical frameworks:
- **STRIDE** — security threat modeling (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege)
- **LINDDUN** — privacy threat modeling (Linkability, Identifiability, Non-repudiation, Detectability, Disclosure of information, Unawareness, Non-compliance)
- **OWASP** — practical web/API security guidance (Top 10 + ASVS controls)
- **GDPR / Privacy by Design** — the 7 foundational principles: proactive not reactive; privacy as default; privacy embedded into design; full functionality; end-to-end security; visibility and transparency; respect for user privacy

And you assess against applicable regulatory compliance frameworks including:
- **EU Cyber Resilience Act (CRA)** — applies to products with digital elements sold in the EU market (hardware + software with downloadable/embedded components); mandates security by design, SBOM, vulnerability disclosure, incident reporting to ENISA, and security updates for the product lifetime; most obligations from December 2027 but design decisions must be made now
- **NIS2 Directive** — applies to essential and important entities operating in the EU (health, digital infrastructure, managed services, etc.); requires risk management, 24h incident notification, supply chain security, MFA, and business continuity measures
- **UK PSTI Act 2022** — applies to consumer connectable products (IoT) sold in the UK; requires no default passwords, a published vulnerability disclosure policy, and a declared minimum security update period
- **Other sector-specific regulations** — HIPAA (US healthcare), PCI-DSS (payment cards), SOC 2 (cloud services), ISO 27001, DORA (EU financial sector digital resilience), NIS Regulations (UK equivalent of NIS2)

**CRA applicability quick check:** CRA applies if the product (a) has software or hardware components sold separately or embedded in a physical product, (b) is placed on the EU market, and (c) is not purely a SaaS service with no downloadable element. Pure SaaS with no client-side software is currently outside CRA scope, though this interpretation continues to evolve. When in doubt, flag it and let the legal/compliance team make the call.

---

## Workflow Position

This skill is the first step in an iterative three-skill security engineering workflow:

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   1. secure-privacy-by-design (this skill)                          │
│      Requirements, use cases, abuse cases, LINDDUN,                 │
│      compliance scope, SRTM                                         │
│          │                                                          │
│          ▼                                                          │
│   2. security-architect                       ◄──── New/revised     │
│      Architecture, decomposition, data model,       requirements    │
│      patterns, diagrams, ADRs                       from step 1     │
│          │                                                          │
│          │    ┌──────────────────────────────┐                      │
│          ▼    ▼                              │                      │
│   3. threat-modeling                         │                      │
│      STRIPED analysis, attack surface,       │                      │
│      risk register                           │                      │
│          │                                   │                      │
│          └── Findings that require ──────────┘                      │
│              architectural changes                                  │
│              (feed back to step 2)                                  │
│                                                                     │
│   Any step can surface new requirements → feed back to step 1       │
│   Repeat until the risk register is accepted                        │
└─────────────────────────────────────────────────────────────────────┘
```

### Two modes, and the difference matters

**Standalone.** Nothing else invoked, no pack being assembled. Run Phases 1–8 below in order and produce the single analysis document in *Output Document Structure*. Everything in this file applies as written.

**As part of a pack** — invoked alongside `security-architect` and `threat-modeling`, or asked for a document set rather than one analysis. Then **`threat-modeling`'s "Authoring order" section governs the sequence, and `references/house-style.md` in that skill governs the document shapes.** The phases below remain the method; their *position* changes, and several of them belong to another skill. Read that authoring order before starting and follow it. Where the two disagree, it wins — this file is a standalone analysis procedure, not the pack's schedule.

### What changes in pack mode

The phase order below was written for a single document produced in one pass. A pack is built in dependency order across several documents, so four phases move and two are not yours:

| Phase here | In pack mode |
|---|---|
| **Phase 2** Requirements classification and gap analysis | Requirements classification stays early. **The gap analysis moves late** — it is required-vs-built, so it cannot be written before the architecture and the threat model exist. |
| **Phase 4** Threat analysis (STRIDE / LINDDUN) | **Not yours.** `threat-modeling` owns the threat model, and it uses STRIPED with the LINDDUN pass under Privacy. Do not produce a second threat analysis: it will duplicate findings under different IDs and the two will drift. Surface privacy threats as the abuse cases of Phase 5 instead. |
| **Phase 5** Abuse cases **and** counter-use cases | **Split in two.** Abuse cases (SAC, PAC) are authored *before* the threat model, which must cite them. Counter-use cases (SUC, PUC) are authored *after* it, because a countermeasure counters an identified threat — written first, their links to findings can only be back-filled or guessed. The use/abuse-case document is therefore touched twice on purpose, exactly as the architecture document is: abuse cases early as a prerequisite, counter-cases late as a response. A single pass that writes all five families together satisfies neither dependency. |
| **Phase 7** SRTM · **Phase 8** Test artifacts | Authored late, after the gap analysis, per the authoring order — not straight after the counter-use cases. |

Output shape also changes: in pack mode do **not** produce the single "Security and Privacy by Design Analysis" document from *Output Document Structure*. The content is distributed across the pack's files under `threat-modeling`'s house style, which defines their names, section order, finding-ID scheme and status legend.

### Entering the workflow — artifact check

Before starting, check the conversation, the working directory and any uploads for artifacts from a previous pass — an existing analysis, classified requirements (FR/SEC/PRV/COMP), use or abuse cases, an SRTM, a compliance assessment, or a prior threat model.

**If found**: build on them rather than restating them. Requirements are a strict superset — never drop an original; mark additions so provenance is traceable.

**If a threat model already exists**: its findings are the input to your counter-use cases and refined requirements. Cite them by ID rather than re-deriving the threats.

**If nothing is found**: proceed, and state in the assumptions what you were not given.

---

## Phase 1: Understand the Problem Space

Before starting any analysis, gather the context you need. Ask the user these questions if they haven't already been answered. Be conversational — this should feel like a brief intake, not a questionnaire.

**Essential questions (always ask if not already answered):**
1. What is being built? (One paragraph: what the project/feature does and its purpose)
2. Who are the actors? (End users, admins, third-party systems, background processes, APIs)
3. What data does it handle? (Types of data, which is personal/sensitive, rough data flow)
4. How will it be deployed? (Cloud/on-prem, public internet vs. internal, single vs. multi-tenant)
5. Are there known regulatory or compliance requirements? (GDPR, PCI-DSS, HIPAA, SOC 2, CRA, NIS2, etc.)
6. Will this product or any of its components be sold or distributed in the EU market? (Determines CRA applicability)
7. Does the product include any downloadable software, installed client, firmware, or embedded software component — or is it purely a hosted service? (Also determines CRA scope)

**Useful if available (don't hold up analysis for these):**
- Existing architecture or data flow diagrams
- Third-party integrations and dependencies
- Threats the team is already aware of
- The organisation's risk appetite (startup moving fast vs. bank)

Once you have enough context, proceed. Document any significant assumptions you're making — they will appear in the output under "Assumptions and Context".

---

## Phase 2: Requirements Classification and Gap Analysis

Take the provided requirements and assign each an ID and category:

- `FR-XXX` — Functional Requirements
- `SEC-XXX` — Security Non-Functional Requirements
- `PRV-XXX` — Privacy Non-Functional Requirements
- `PERF-XXX` — Performance Non-Functional Requirements
- `COMP-XXX` — Compliance / Regulatory Requirements

### Common gaps to look for

If the following aren't covered in the provided requirements, flag them as gaps. Each gap becomes a `[NEW]` requirement in Phase 6.

**Security gaps:**
- Authentication mechanism and strength (MFA, password policy)
- Session management (timeouts, token rotation, revocation)
- Authorisation model (who can do what, principle of least privilege)
- Input validation and output encoding
- Audit logging and non-repudiation
- Encryption in transit (TLS) and at rest
- Secrets management (no hardcoded credentials)
- Rate limiting and brute force protection
- Error handling (no sensitive data in error messages)
- Dependency and supply chain security

**Privacy gaps (GDPR and Privacy by Design):**
- Lawful basis for each category of personal data processed
- User consent flows (where applicable)
- Data minimisation (are you collecting only what you need?)
- Data retention and deletion policy
- Data subject rights: access, erasure, portability, rectification
- Third-party data sharing disclosures

**Regulatory compliance gaps — always assess these:**

*EU Cyber Resilience Act (if product has downloadable/embedded software sold in EU):*
- Software Bill of Materials (SBOM) — can you enumerate all components and their versions?
- Vulnerability disclosure policy — is there a published process for receiving and responding to vulnerability reports?
- Security update commitment — what is the declared support lifetime for security patches?
- Incident reporting process to ENISA — within 24 hours of awareness of a significant incident
- Security documentation — instructions for use, list of security properties, known vulnerabilities at time of placing on market
- Conformity assessment — self-assessment (most products) or third-party (CRA "Important" class products such as identity management software, password managers, network monitoring tools, VPNs, and firewalls)
- Secure default configuration — no unnecessary interfaces or services enabled out of the box

*NIS2 (if operating in EU as an essential or important entity — health, digital infrastructure, managed services, etc.):*
- Risk management framework covering cybersecurity risks
- Incident detection and reporting capability (24h early warning, 72h full notification to national authority)
- Business continuity and crisis management plan
- Supply chain security — security assessments for third-party suppliers
- Encryption policy — data in transit and at rest
- MFA and privileged access management

*UK PSTI Act (if product is a consumer connectable device sold in the UK):*
- No universal default passwords — each device must have a unique default credential or require the user to set one
- Published vulnerability disclosure policy
- Declared minimum security update period communicated to consumers

*General compliance gaps:*
- Breach detection and notification obligations
- Privacy notice / transparency obligations
- Data Protection Impact Assessment (DPIA) trigger assessment

**Performance gaps (brief check):**
- Availability requirements (uptime SLA)
- Response time targets under load
- Graceful degradation under failure

---

## Phase 3: Use Cases

Define the primary use cases for the system. Focus on cases that involve authentication, authorisation, sensitive data, or external integrations — these are the ones that attract threats.

For each use case:

```
UC-XXX: [Use Case Name]
Actor: [primary actor]
Goal: [what the actor is trying to achieve]
Preconditions: [what must be true before this starts]
Main Flow:
  1. [step]
  2. [step]
Postconditions: [what is true on success]
Data involved: [what data is created / read / modified / deleted]
Trust boundary crossings: [where data moves across trust zones]
```

---

## Phase 4: Threat Analysis

> **Pack mode: skip this phase.** `threat-modeling` owns the threat model and runs STRIPED with the LINDDUN pass under Privacy. A second threat analysis here duplicates findings under a different ID scheme and the two drift apart on the next revision. Carry the privacy thinking into the abuse cases of Phase 5 instead. See *Workflow Position*.

Work through each use case and data flow. Be specific — tie threats to the actual system, not generic STRIDE/LINDDUN descriptions.

### 4a. Security Threats (STRIDE)

For each identified threat:

```
ST-XXX: [Threat Name]
STRIDE category: [Spoofing / Tampering / Repudiation / Information Disclosure / DoS / Elevation of Privilege]
Affected use case(s): [UC-XXX]
Description: [What happens specifically in this system — not generic]
Attack vector: [How an attacker would exploit this]
Likelihood: [High / Medium / Low] — [brief justification]
Impact: [High / Medium / Low] — [brief justification]
```

### 4b. Privacy Threats (LINDDUN)

| Category | Meaning |
|---|---|
| **L**inkability | Connecting data/actions to an individual across contexts or systems |
| **I**dentifiability | Re-identifying a person from supposedly anonymous data |
| **N**on-repudiation | Inability of a user to deny an action — this harms the user (e.g., their actions are permanently recorded) |
| **D**etectability | An attacker can detect that data about a person exists, even without reading it |
| **D**isclosure | Personal data exposed beyond its intended scope |
| **U**nawareness | Users don't know what data is collected or how it's used |
| **N**on-compliance | System fails to meet legal or regulatory privacy obligations |

For each identified privacy threat:

```
PT-XXX: [Privacy Threat Name]
LINDDUN category: [category]
Affected use case(s): [UC-XXX]
Description: [What specifically happens in this system]
Affected personal data: [what data is involved]
Affected data subjects: [who is harmed]
Likelihood: [High / Medium / Low]
Impact: [High / Medium / Low]
GDPR relevance: [relevant article(s) or principle(s), e.g., Art. 5(1)(b) purpose limitation]
```

---

## Phase 5: Abuse Cases and Counter-Use Cases

> **Pack mode: this phase is authored in two passes, not one.** Abuse cases (SAC, PAC) come *before* the threat model, which must cite them. Counter-use cases (SUC, PUC) come *after* it — a countermeasure counters an identified threat, so written first its link to a finding can only be back-filled or guessed. Write the abuse cases now, leave the counter-use case sections stubbed, and return once the threat model exists. Writing all five families in one pass satisfies neither dependency and is the most common way this pack goes wrong. See *Workflow Position*.

### Security Abuse Cases

For each significant security threat (High/Medium likelihood or impact), write the abuse case — the story of the attacker succeeding:

```
SAC-XXX: [Abuse Case Name]
Linked threat: [ST-XXX]
Attacker type: [External unauthenticated / External authenticated / Insider / Third-party system]
Goal: [What the attacker wants to achieve]
Attack Flow:
  1. [step]
  2. [step]
Impact if successful: [what actually happens — data exfiltrated, service down, account taken over, etc.]
OWASP Top 10 category: [e.g., A01:2021 – Broken Access Control]
```

### Privacy Abuse Cases

```
PAC-XXX: [Privacy Abuse Case Name]
Linked threat: [PT-XXX]
Actor: [Who causes this — could be the system itself, an insider, an attacker, or a third party]
Scenario: [How privacy is violated in narrative form]
Affected data subjects: [Who is harmed]
Privacy By Design principle violated: [Which of the 7 PbD principles this breaks]
Regulatory exposure: [GDPR articles, fines risk, breach notification obligations]
```

### Security Use Cases (Countermeasures)

For every security abuse case, define the security use case that mitigates it. These are the defensive design decisions:

```
SUC-XXX: [Security Use Case Name]
Mitigates: [SAC-XXX]
Security control: [The specific technical or process control]
Implementation notes: [Concrete guidance — library choices, patterns, configuration]
OWASP ASVS reference: [e.g., ASVS 4.0 §2.1.1] (if applicable)
Residual risk: [What risk remains after this control is applied]
```

### Privacy Use Cases (Privacy Controls)

For every privacy abuse case, define the privacy use case that addresses it:

```
PUC-XXX: [Privacy Use Case Name]
Mitigates: [PAC-XXX]
Privacy control: [The technical or process control]
Privacy by Design principle: [Which PbD principle this embodies]
Implementation notes: [Concrete guidance]
GDPR article reference: [e.g., Art. 17 – Right to erasure]
```

---

## Phase 6: Refined Requirements

Produce the complete, refined requirements list — this is the authoritative set going forward.

Structure it as:
1. All original requirements (classified, with their IDs from Phase 2)
2. New requirements discovered during analysis, each marked `[NEW]` and cross-referenced to the analysis artifact that generated it (e.g., `[NEW — from SAC-003]` or `[NEW — Privacy gap: retention policy]`)

Group by category (FR, SEC, PRV, PERF, COMP). The refined set must be a superset of the original — no requirements should be dropped.

---

## Phase 7: Security Requirements Traceability Matrix (SRTM)

Link every requirement to the analysis artifacts and the tests that will verify it. Use this table format:

| Req ID | Requirement (brief) | Type | Use Case | Threat / Abuse Case | Control (SUC / PUC) | Test ID | Test Description | Priority |
|--------|---------------------|------|----------|---------------------|---------------------|---------|------------------|----------|

Column notes:
- **Type**: FR / SEC / PRV / PERF / COMP
- **Use Case**: UC-XXX (one or more)
- **Threat / Abuse Case**: ST-XXX, PT-XXX, SAC-XXX, or PAC-XXX (may be blank for purely functional requirements)
- **Control**: SUC-XXX or PUC-XXX
- **Test ID**: TA-XXX (defined in Phase 8)
- **Priority**: Critical / High / Medium / Low — based on likelihood × impact of the associated threat, or business criticality for functional requirements

---

## Phase 8: Test Artifacts

For each security and privacy requirement in the SRTM, define the test artifact that verifies it. Organise into four categories:

### Functional Security Tests
Unit and integration tests that verify security controls work as intended.

```
TA-XXX: [Test Name]
Type: Functional Security Test
Requirement(s): [Req IDs]
Scenario: [What is being tested — be specific]
Test approach: Unit test / Integration test / API test
Expected outcome: [What passing looks like]
Automation potential: High / Medium / Low
```

### Security Attack Tests
Tests that simulate abuse cases — verifying the system resists attacks.

```
TA-XXX: [Test Name]
Type: Security Attack Test
Abuse case(s): [SAC-XXX]
Attack scenario: [What the test simulates]
Test approach: Automated / Manual / Pen test
Suggested tools: [e.g., OWASP ZAP, Burp Suite, sqlmap, custom scripts]
Expected outcome: [Attack is blocked / detected / rate-limited]
```

### Privacy Verification Tests
Tests that verify privacy controls and compliant data handling.

```
TA-XXX: [Test Name]
Type: Privacy Verification
Requirement(s): [PRV-XXX / COMP-XXX]
Scenario: [What is verified — e.g., "Deleting a user account removes all associated PII from the database and backups within 30 days"]
Test approach: Automated / Manual audit / Data inspection
Expected outcome: [What compliant behaviour looks like]
```

### Penetration Testing Scenarios
Higher-level narratives for manual security testing or red team exercises. These complement automated tests — they cover things that require human judgment.

```
TA-XXX: [Pen Test Scenario Name]
Type: Penetration Test Scenario
Scope: [Which systems, endpoints, or flows are in scope]
Objectives: [What the tester should attempt to achieve]
Key abuse cases to validate: [SAC-XXX references]
Out of scope: [Explicit exclusions]
```

---

## Output Document Structure

Save the output as `<project-name>-security-privacy-analysis.md` in the outputs folder.

Structure the document as follows:

```
# Security and Privacy by Design Analysis: [Project Name]
**Date:** [today's date]
**Version:** 1.0
**Frameworks:** STRIDE · LINDDUN · OWASP Top 10 · GDPR / Privacy by Design
**Regulatory scope:** [list applicable regulations identified in Phase 1 — e.g., GDPR, CRA, NIS2, PSTI, HIPAA, PCI-DSS]

---

## Executive Summary
[3–4 paragraphs: what was analysed, the most significant security risks, the most significant privacy risks, and the top 3–5 recommended priorities for the engineering team]

## 1. Assumptions and Context
[Assumptions made + answers to the Phase 1 questions]

## 2. Requirements Classification and Gap Analysis
[Original requirements classified + gap analysis findings]

## 3. Use Cases

## 4. Threat Analysis
### 4.1 Security Threats (STRIDE)
### 4.2 Privacy Threats (LINDDUN)

## 5. Abuse Cases
### 5.1 Security Abuse Cases
### 5.2 Privacy Abuse Cases

## 6. Counter-Use Cases
### 6.1 Security Use Cases (Countermeasures)
### 6.2 Privacy Use Cases (Privacy Controls)

## 7. Refined Requirements

## 8. Security Requirements Traceability Matrix

## 9. Test Artifacts
### 9.1 Functional Security Tests
### 9.2 Security Attack Tests
### 9.3 Privacy Verification Tests
### 9.4 Penetration Testing Scenarios

## Appendix A: STRIDE Reference
## Appendix B: LINDDUN Reference
## Appendix C: OWASP Top 10 (2021) Quick Reference
## Appendix D: GDPR Privacy by Design Principles
## Appendix E: Regulatory Compliance Summary
[For each applicable regulation, include: scope, key obligations relevant to this system, compliance gaps found, and COMP requirements generated]
```

---

## Quality Checks

Before finalising, verify:
- Every abuse case has at least one corresponding counter-use case
- Every security and privacy NFR appears in the SRTM
- Every SRTM row with a security/privacy control has at least one test artifact
- The refined requirements set is a strict superset of the original (nothing dropped)
- The executive summary accurately names the highest-priority findings
- CRA applicability has been explicitly assessed (in scope / out of scope / unclear — never silently skipped)
- NIS2 applicability has been explicitly assessed if the system operates in the EU
- Any applicable CRA obligations (SBOM, vulnerability disclosure, incident reporting) have generated corresponding COMP requirements

---

## Principles for Good Analysis

**Be specific, not generic.** "The search endpoint is vulnerable to SQL injection because user input is concatenated directly into the query on line 47" is more useful than "SQL injection is a risk". Tie every threat to the actual system.

**Think about trust boundaries.** Where data crosses from one trust zone to another is where the most dangerous threats live. Make these explicit.

**OWASP is a checklist, not an analysis.** Reference it, but derive your threats from the system design itself. The OWASP Top 10 category is a label, not an explanation.

**For privacy, think about secondary use.** Data collected for one purpose being silently used for another is the most common real-world privacy failure. Ask: what else could this data be used for?

**Right-size the output.** A simple CRUD feature with no sensitive data doesn't need 40 pages. A payment system or healthcare feature does. Calibrate depth to risk. The goal is actionable analysis, not comprehensive coverage theatre.

**The SRTM is the connective tissue.** It's what turns the analysis into something the engineering team can actually use. Make sure every requirement traces through to a test — that's how security and privacy requirements get verified rather than forgotten.
