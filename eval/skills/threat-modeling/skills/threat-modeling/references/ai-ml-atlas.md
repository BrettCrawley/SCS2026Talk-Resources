# MITRE ATLAS — Adversarial Threat Landscape for AI Systems

MITRE ATLAS™ technique, tactic and mitigation identifiers and names are drawn from the ATLAS data (ATLAS-latest.yaml, data version 2026.08), © 2021–2026 The MITRE Corporation, licensed under the Apache License, Version 2.0 (https://www.apache.org/licenses/LICENSE-2.0). Source: https://github.com/mitre-atlas/atlas-data. The selection, annotations, OWASP mappings and guidance in this file are original and not part of ATLAS.

Read this after `ai-ml-threats.md` when AI/ML components are in scope. ATLAS is applied *after*
elicitation (STRIPED, OWASP LLM/ASI, Elevation of Autonomy): it sequences findings into attack
paths, maps them to detection, and grounds likelihood in observed maturity. Verified against
ATLAS data version 2026.08 (`dist/ATLAS-latest.yaml`, modified 2026-05-27).

## Contents

1. What ATLAS adds and when to use it
2. Maturity — use it for likelihood
3. Tactics
4. Techniques most relevant to LLM / agentic systems
5. Cross-reference: OWASP → ATLAS
6. Mitigations (with Cox-thesis classification)
7. How to apply ATLAS in the analysis

---

## 1. What ATLAS adds

ATLAS (https://atlas.mitre.org, data at https://github.com/mitre-atlas/atlas-data) is the
AI-specific sibling of ATT&CK: a matrix of adversary **tactics** (why) and **techniques** (how),
grounded in real incidents and red-team exercises. As of v2026.08 it has 16 tactics, ~200
techniques and sub-techniques, 39 mitigations and 72 case studies. It complements the OWASP
catalogues rather than replacing them:

| Catalogue | Answers | Use it for |
|---|---|---|
| OWASP LLM / Agentic Top 10 | *What classes of weakness exist?* | Coverage — did we consider every risk category |
| Elevation of Autonomy | *What could go wrong here?* | Elicitation — structured brainstorming per element |
| **MITRE ATLAS** | *How does an adversary actually chain this, and has it happened?* | Attack paths, detection mapping, likelihood from observed maturity |

Use ATLAS when you need to (a) order findings into a plausible kill chain, (b) map findings to
telemetry and detection, (c) cross-reference the AI surface with the surrounding infrastructure
(ATLAS mirrors ATT&CK and carries `attack-reference` links, so `AML.T0012 Valid Accounts` and
ATT&CK `T1078` are the same story told twice), or (d) justify a likelihood rating with an
observed case study.

## 2. Maturity — use it for likelihood

Every ATLAS technique carries a **maturity** field. Use it directly in the Risk Register:

| Maturity | Meaning | Likelihood floor |
|---|---|---|
| **Realized** | Observed in a real incident | High — do not rate below Medium without justification |
| **Demonstrated** | Shown in a red-team exercise or published PoC | Medium |
| **Feasible** | Plausible, not yet demonstrated | Low–Medium; say it is theoretical |

## 3. Tactics (◆ = no ATT&CK equivalent)

| ID | Tactic | AI-specific content |
|---|---|---|
| AML.TA0002 | Reconnaissance | Papers, model cards, repos; RAG-indexed targets (T0064); autonomous recon (T0116) |
| AML.TA0003 | Resource Development | Proxy models, poisoned public artifacts (T0115), hallucinated entities (T0060), AI service proxies |
| AML.TA0004 | Initial Access | AI supply chain (T0010), prompt infiltration via public app (T0093), artifact-processing pipelines (T0119) |
| AML.TA0000 ◆ | **AI Model Access** | Inference API (T0040), physical environment (T0041), full model (T0044), AI-enabled product (T0047) |
| AML.TA0005 | Execution | Prompt injection (T0051), agent tool invocation (T0053), agent clickbait (T0100), deploy agent (T0103) |
| AML.TA0006 | Persistence | Manipulate model (T0018), RAG poisoning (T0070), agent context poisoning (T0080), tool poisoning (T0110) |
| AML.TA0012 | Privilege Escalation | Jailbreak (T0054), tool invocation (T0053), escape to host (T0105) |
| AML.TA0007 | Defense Evasion | Evade model (T0015), obfuscation (T0068), delayed instructions (T0094), chat-history manipulation (T0092), rug pull (T0109) |
| AML.TA0013 | Credential Access | Unsecured creds (T0055), RAG (T0082) / agent config (T0083) / agent tool (T0098) credential harvesting |
| AML.TA0008 | Discovery | Model ontology/family, system information (T0069), agent configuration (T0084), hallucinations (T0062) |
| AML.TA0015 | Lateral Movement | Valid accounts, tool invocation (T0053), alternate auth material (T0091), remote services (T0122) |
| AML.TA0009 | Collection | AI artifact collection (T0035), data from AI services — RAG DBs and tools (T0085) |
| AML.TA0001 ◆ | **AI Attack Adaptation** | Proxy model (T0005), craft adversarial data (T0043), prompt/retrieval crafting (T0065/T0066), verify (T0042), autonomous orchestration (T0124) |
| AML.TA0014 | Command and Control | AI service API (T0096), AI agent (T0108), AI web interface (T0114), artifact repository (T0120) as C2 relays |
| AML.TA0010 | Exfiltration | Via inference API (T0024), LLM data leakage (T0057), response rendering (T0077), agent tool invocation (T0086) |
| AML.TA0011 | Impact | DoS (T0029), cost harvesting (T0034), integrity erosion (T0031), data destruction via tools (T0101), machine compromise (T0112), external harms (T0048) |

The two ◆ tactics have no ATT&CK equivalent and are the ones reviewers most often skip.
**AI Model Access** is the pivot: almost every ATLAS attack path passes through it, so document
exactly how much model access each trust boundary grants (product-mediated, query-only, logits,
weights, training pipeline) — that single fact bounds the rest of the analysis.

## 4. Techniques Most Relevant to LLM / Agentic Systems

Tag findings inline as `[ATLAS AML.T0051.001]`. Maturity in brackets.

**Prompt and context manipulation**
- AML.T0051 LLM Prompt Injection — .000 Direct [R], .001 Indirect [D], .002 Triggered [D]
- AML.T0054 LLM Jailbreak [R]
- AML.T0065 LLM Prompt Crafting [R]; AML.T0068 LLM Prompt Obfuscation [D]
- AML.T0093 Prompt Infiltration via Public-Facing Application [D] — injection planted for future ingestion
- AML.T0094 Delay Execution of LLM Instructions [D] — sleeper instructions keyed to a later event
- AML.T0061 LLM Prompt Self-Replication [D] — wormable injection across agents / inboxes
- AML.T0067 LLM Trusted Output Components Manipulation [D] — .000 Citations
- AML.T0077 LLM Response Rendering [D] — markdown/HTML sinks; see `ai-ml-threats.md` §6 Output Handling
- AML.T0092 Manipulate User LLM Chat History [D] — anti-forensics

**Agents, tools and MCP**
- AML.T0053 AI Agent Tool Invocation [D] — sits in Execution, Privilege Escalation *and* Lateral Movement
- AML.T0086 Exfiltration via AI Agent Tool Invocation [R]
- AML.T0101 Data Destruction via AI Agent Tool Invocation [R]
- AML.T0110 AI Agent Tool Poisoning [R] — .000 Definition and Instructions, .001 Implementation, .002 Runtime Response (covers MCP tool description poisoning — see `ai-ml-threats.md` §5 MCP)
- AML.T0010.005 AI Supply Chain Compromise: AI Agent Tool [R]; AML.T0011.002 User Execution: Poisoned AI Agent Tool [R]
- AML.T0080 AI Agent Context Poisoning [D] — .000 Memory, .001 Thread
- AML.T0081 Modify AI Agent Configuration [D]; AML.T0084 Discover AI Agent Configuration [D] (.001 Tool Definitions, .003 Call Chains)
- AML.T0083 Credentials from AI Agent Configuration [D]; AML.T0098 AI Agent Tool Credential Harvesting [D]
- AML.T0100 AI Agent Clickbait [D] — computer-use / browser agents
- AML.T0103 Deploy AI Agent [R]; AML.T0108 AI Agent (as C2) [D]
- AML.T0105 Escape to Host [R]
- AML.T0116 / T0117 / T0124 Autonomous Reconnaissance / Attack-Path Adaptation / Attack Orchestration [R] — the attacker is itself an agent
- AML.T0118 Autonomous AI Agent Communication [R] — .000 Shared Artifacts, .001 Direct

**RAG and retrieval**
- AML.T0064 Gather RAG-Indexed Targets [D]
- AML.T0066 Retrieval Content Crafting [D]
- AML.T0070 RAG Poisoning [D]; AML.T0071 False RAG Entry Injection [D]
- AML.T0082 RAG Credential Harvesting [D]; AML.T0085.000 Data from AI Services: RAG Databases [D]

**Discovery**
- AML.T0056 Extract LLM System Prompt [F]
- AML.T0069 Discover LLM System Information [D] — .000 Special Character Sets, .001 System Instruction Keywords, .002 System Prompt
- AML.T0062 Discover LLM Hallucinations [D] → AML.T0060 Publish Hallucinated Entities [D] (slopsquatting)
- AML.T0013 / T0014 Discover AI Model Ontology / Family

**Execution and C2**
- AML.T0050 Command and Scripting Interpreter [R]; AML.T0102 Generate Malicious Commands [R]
- AML.T0011.000 User Execution: Unsafe AI Artifacts [R] (pickle, unsafe weight deserialisation)
- AML.T0096 AI Service API / AML.T0114 AI Service Web Interface / AML.T0120 AI Artifact Repository as C2 channels

**Supply chain and integrity**
- AML.T0010 AI Supply Chain Compromise [R] — .000 Hardware, .001 AI Software, .002 Data, .003 Model, .004 Container Registry, .005 AI Agent Tool
- AML.T0018 Manipulate AI Model [R] — .000 Poison, .001 Modify Architecture, .002 Embed Malware, .003 Modify Prompt Construction Logic (GGUF templates etc.)
- AML.T0020 Training Data Poisoning [R]; AML.T0059 Erode Dataset Integrity [D]
- AML.T0115 Publish Poisoned AI Artifacts [R] — .000 Datasets, .001 Models, .002 AI Agent Tools
- AML.T0109 AI Supply Chain Rug Pull [R]; AML.T0111 AI Supply Chain Reputation Inflation [D]
- AML.T0119 Exploit Automated Artifact Processing Pipeline [R]
- AML.T0076 Corrupt AI Model [R]

**Exfiltration and leakage**
- AML.T0057 LLM Data Leakage [D]
- AML.T0024 Exfiltration via AI Inference API — .000 Membership Inference [F], .001 Invert Model [F], .002 Extract Model [R]
- AML.T0025 Exfiltration via Cyber Means [R]; AML.T0055 Unsecured Credentials [R]

**Impact**
- AML.T0015 Evade AI Model [R]; AML.T0043 Craft Adversarial Data [R] (.000–.004)
- AML.T0029 Denial of AI Service [D]; AML.T0046 Spamming AI System with Chaff Data [F]
- AML.T0034 Cost Harvesting [F] — .000 Excessive Queries, .001 Resource-Intensive Queries, .002 Agentic Resource Consumption
- AML.T0031 Erode AI Model Integrity [R]
- AML.T0112 Machine Compromise [D] — .000 Local AI Agent, .001 AI Artifacts
- AML.T0048 External Harms [R] — .000 Financial, .001 Reputational, .002 Societal, .003 User, .004 AI IP Theft

## 5. Cross-Reference: OWASP → ATLAS

Add an ATLAS tag to every OWASP-tagged finding so the report supports both a coverage view and
an attack-path view.

| OWASP | Primary ATLAS techniques |
|---|---|
| LLM01 Prompt Injection | T0051.*, T0054, T0065, T0068, T0093, T0094, T0061 |
| LLM02 Sensitive Information Disclosure | T0057, T0056, T0069, T0024.*, T0055, T0082, T0083 |
| LLM03 Supply Chain | T0010.*, T0115.*, T0011.000/.001/.002, T0109, T0111, T0060 |
| LLM04 Data and Model Poisoning | T0020, T0018.*, T0059, T0070, T0080.*, T0099 |
| LLM05 Improper Output Handling | T0077, T0067.*, T0050, T0102 |
| LLM06 Excessive Agency | T0053, T0086, T0101, T0105, T0103 |
| LLM07 System Prompt Leakage | T0056, T0069.002, T0084 |
| LLM08 Vector and Embedding Weaknesses | T0064, T0066, T0070, T0071, T0082, T0085.000 |
| LLM09 Misinformation | T0062, T0060, T0031, T0067.000 |
| LLM10 Unbounded Consumption | T0029, T0034.*, T0046, T0024.002 |
| ASI (agentic) findings | T0053, T0080.*, T0081, T0084.*, T0086, T0098, T0100, T0101, T0110.*, T0118.*, T0124, T0073, T0074 |

## 6. ATLAS Mitigations

ATLAS ships a mitigation catalogue (`AML.M0000`–`AML.M0038`), each tagged Policy,
Technical-Cyber or Technical-AI. Cite them alongside the design-time controls in the
`ai-ml-threats.md` §10 Mitigation-to-Threat Traceability — auditors recognise them — but classify each under the
Cox thesis (`ai-ml-threats.md` §1.3). The Technical-AI ones are mostly *probabilistic backstops* and must not
be the load-bearing control.

| ID | Mitigation | Cox-thesis classification |
|---|---|---|
| AML.M0004 | Limit AI Service Query Volume and Rate | Deterministic — primary |
| AML.M0005 / M0019 | Control Access to AI Models and Data at Rest / in Production | Deterministic — primary |
| AML.M0011 | Restrict Library Loading | Deterministic — primary for unsafe artifacts |
| AML.M0013 / M0014 | Code Signing / Verify AI Artifacts | Deterministic — primary for supply chain |
| AML.M0015 | Predictive AI Adversarial Input Detection | Probabilistic — backstop |
| AML.M0020 | Generative AI Guardrails | Probabilistic unless implemented as deterministic filtering — classify per implementation |
| AML.M0021 / M0022 | Generative AI Guidelines / Model Alignment | Inside the model — never load-bearing |
| AML.M0023 | AI Bill of Materials | Deterministic — primary for supply chain |
| AML.M0024 | AI Telemetry Logging | Detective — required for every Discovery / Exfiltration finding |
| AML.M0025 | Maintain AI Dataset Provenance | Deterministic — primary for poisoning |
| AML.M0026 / M0027 / M0028 | Privileged / Single-User / Tools Permissions Configuration | Deterministic — primary for agents (least privilege) |
| AML.M0029 | Human In-the-Loop for AI Agent Actions | Deterministic gate — primary for irreversible actions |
| AML.M0030 | Restrict AI Agent Tool Invocation on Untrusted Data | Deterministic — primary; the ATLAS name for the "no tool calls after untrusted content" rule |
| AML.M0031 | Memory Hardening | Deterministic — primary for T0080 |
| AML.M0032 | Segmentation of AI Agent Components | Deterministic — primary |
| AML.M0033 | Input and Output Validation for AI Agent Components | Deterministic (schema) — primary |
| AML.M0035 | AI Red Team | Process control |
| AML.M0036 | Limit AI Workload Resource Consumption | Deterministic — primary for T0034 |
| AML.M0037 / M0038 | Authority Expansion Controls / Scope Drift Detection | M0037 deterministic (ceiling), M0038 probabilistic — backstop |

## 7. How to Apply ATLAS in the Analysis

1. **Establish model access first.** For each trust boundary, state which AML.TA0000 technique
   an adversary on the far side achieves (T0047 product-mediated, T0040 API, T0044 full,
   T0041 physical).
2. **Tag every AI/ML finding with an ATLAS technique** in addition to its OWASP/EoA tag, and
   carry the maturity into the likelihood rating. If a finding has no ATLAS technique, either it
   is novel (say so) or it is not an adversary behaviour (reclassify as a weakness, not a threat).
3. **Build at least one end-to-end attack path** using ATLAS tactics left-to-right, from
   Reconnaissance / Initial Access through AI Model Access to Impact. If the path is credible
   without a deterministic control breaking it, that is a design flaw — Fix Before Implementation.
4. **Map each path to detection.** Every path should cross at least one point where AML.M0024
   telemetry would observe it. If it doesn't, add a detection finding.
5. **Cite case studies** (`AML.CSxxxx`) where they exist — e.g. CS0022 package hallucination,
   CS0024 Morris II RAG worm, CS0041 rules-file backdoor, CS0045/CS0053/CS0054 MCP-server
   exfiltration, CS0059 EchoLeak zero-click, CS0064 poisoned GGUF templates, CS0069 agent-driven
   espionage campaign. An observed technique justifies a higher likelihood; a finding without a
   case study is not lower severity by default, but say which it is.
6. **Reconcile with ATT&CK** for the non-AI infrastructure so the two matrices tell one story —
   an ATLAS Initial Access finding and an ATT&CK Initial Access finding on the same host should
   share a mitigation.

Do not use ATLAS as an elicitation checklist — it is incident-derived and lags novel attack
classes by months. Elicit with EoA and OWASP; confirm, sequence and rate with ATLAS.

When writing up: the **ATLAS Attack Paths** block is part of the AI/ML Threat Surface section in `templates/threat-model-template.md` (§6b).
