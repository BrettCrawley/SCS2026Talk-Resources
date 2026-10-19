<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- Copyright 2026 Brett Crawley -->

# Elevation of Autonomy — Card Deck (full text)

Read this after `ai-ml-threats.md` for per-element elicitation of AI/agentic threats. The
complete deck is reproduced here so the elicitation pass never depends on a file outside the
skill. Canonical source: https://github.com/BrettCrawley/elevation-of-autonomy
(`elevation-of-autonomy-print-and-play.md`; companion guide and facilitator runbook alongside).
Copyright 2026 Brett Crawley, CC BY-SA 4.0, v0.1. Sequence and rate the findings afterwards
with `ai-ml-atlas.md`.

## How to use it in a review

- **Walk all 30 cards against every AI/agentic element in the DFD.** Not the cards that seem
  relevant — all of them. Each card's *Mitigation prompts* are the questions to ask; a card
  produces either a finding or a one-line "no exposure — reason".
- **Tag findings** `[EoA·<suit><rank>]`: suits S (♠ Spades), H (♥ Hearts), D (♦ Diamonds),
  C (♣ Clubs), T (★ Trumps); ranks A K Q J 10 9, Trumps 1–7. Examples `[EoA·SA]` Prompt
  Injection, `[EoA·H9]` Confused Deputy Across Servers, `[EoA·T7]` Adversarial Subspace.
- **Record coverage** in the EoA coverage table of the AI/ML Threat Surface section
  (`templates/threat-model-template.md` §6b) — one row per card, outcome and finding IDs. The
  shipping gate fails a document that lists AI/ML in scope without all 30 rows.
- Trumps are the structural hazards from `ai-ml-threats.md` §1–2; play them against the
  *design*, not against a component.

### Card index

| ID | Card | ID | Card | ID | Card |
|---|---|---|---|---|---|
| EoA·SA | Prompt Injection | EoA·HA | Excessive Agency | EoA·DA | Sensitive Information Disclosure |
| EoA·SK | Tool Misuse | EoA·HK | Identity and Privilege Abuse | EoA·DK | Vector and Embedding Weakness |
| EoA·SQ | Supply Chain Compromise | EoA·HQ | Inter-Agent Trust Exploitation | EoA·DQ | Hallucinated Facts |
| EoA·SJ | Memory Poisoning | EoA·HJ | Cascading Failure | EoA·DJ | Unbounded Consumption |
| EoA·S10 | Improper Output Handling | EoA·H10 | Rogue Agent | EoA·D10 | System Prompt Leakage |
| EoA·S9 | Tool Description Injection | EoA·H9 | Confused Deputy Across Servers | EoA·D9 | Server Impersonation and Rogue Servers |
| EoA·CA | Transfer | EoA·T7 | Adversarial Subspace | EoA·T3 | Excessive Autonomy by Design |
| EoA·CK | Retention and Removal | EoA·T6 | Geometric Attack | EoA·T2 | Invisible Dependency |
| EoA·CQ | Inference | EoA·T5 | Context Rot | EoA·T1 | Wrong Abstraction |
| EoA·CJ | Minimisation | EoA·T4 | Decision Boundary Transfer | | |
| EoA·C10 | Unintervenability | | | | |

---

## ♠ Spades - Adversarial Threats

### ♠A — Prompt Injection `[EoA·SA]`

> *"Anything the model reads can be interpreted as an instruction."*

**Threat.** An attacker-controlled text reaches the model's context and is interpreted as a new instruction. The injection may be direct (in the user prompt) or indirect (in retrieved content, tool output, memory, or another agent's message). The model cannot reliably distinguish instructions from data.

**References.** OWASP LLM01. ASI01 when it redirects an agent. CAPEC-242 conceptually.

**Mitigation prompts.** How are inputs from each source delimited? What happens when a retrieved document contains an instruction? What actions are irreversible, and are any of them reachable from a single model output?

### ♠K — Tool Misuse `[EoA·SK]`

> *"A legitimate tool used for illegitimate ends is still destructive."*

**Threat.** The agent invokes a legitimate, authorised tool in a way that causes harm because the arguments were attacker-influenced or the tool's blast radius was too wide.

**References.** ASI02. OWASP LLM06 secondary.

**Mitigation prompts.** For each tool, what is the worst thing it could do with attacker-controlled arguments? Are destructive arguments allow-listed? Is human confirmation required for irreversible outcomes?

### ♠Q — Supply Chain Compromise `[EoA·SQ]`

> *"The code you didn't write runs with the credentials you have."*

**Threat.** A component in the AI supply chain (base model, adapter, library, MCP server, prompt template) is compromised upstream or via an update.

**References.** OWASP LLM03. ASI04.

**Mitigation prompts.** What is in your AI-BOM? How are updates reviewed? What does each component have access to that it does not need?

### ♠J — Memory Poisoning `[EoA·SJ]`

> *"Today's lie becomes tomorrow's ground truth."*

**Threat.** An adversary causes false or malicious content to be written to long-term memory where it persists across sessions and is later retrieved as trusted context.

**References.** ASI06.

**Mitigation prompts.** Who can write to memory? Is provenance attached? Is memory partitioned per user? How are security-relevant memory reads validated?

### ♠10 — Improper Output Handling `[EoA·S10]`

> *"The model's output is not user input, except in every way that matters."*

**Threat.** A downstream consumer treats model output as trusted, leading to exfiltration, rendering, or execution of attacker-influenced content.

**References.** OWASP LLM05.

**Mitigation prompts.** Which consumers of model output exist, and what do they assume? Where is output sanitised, encoded, or structured? Are there rendering paths that fetch remote content?

### ♠9 — Tool Description Injection `[EoA·S9]`

> *"The tool description is itself a prompt."*

**Threat.** An MCP server (or equivalent tool registry) supplies tool descriptions and parameter schemas that arrive in the model's context as instructions. A hostile or compromised server can inject prompts via the description field itself, not just the tool's return value. The "rug pull" variant mutates the description after the user has approved the tool, so the approved version and the live version diverge silently.

**References.** OWASP LLM01 indirect injection. ASI01. ASI04. MCP-specific.

**Mitigation prompts.** Are tool descriptions pinned and integrity-checked between approval and use? What happens when a server updates a description silently? Are descriptions delimited from user prompts in the model's context? Does any tool have a description that contains imperative language?

---

## ♥ Hearts - Autonomy Threats

### ♥A — Excessive Agency `[EoA·HA]`

> *"Give the agent only what the task requires, then give it less."*

**Threat.** The agent holds capabilities, permissions, or autonomy beyond what the task requires, expanding blast radius on any compromise.

**References.** OWASP LLM06.

**Mitigation prompts.** What is the minimum scope for each tool? Does the agent need autonomy, or would confirmation suffice? Could capabilities be split per task?

### ♥K — Identity and Privilege Abuse `[EoA·HK]`

> *"A shared service account is a shared single point of failure."*

**Threat.** Agents share credentials, inherit broad identities, or operate with long-lived tokens. Compromise propagates across the system.

**References.** ASI03.

**Mitigation prompts.** How many agents share identities? How are credentials scoped, rotated, and audited? What is the blast radius of each identity?

### ♥Q — Inter-Agent Trust Exploitation `[EoA·HQ]`

> *"Agents trust each other because you told them to."*

**Threat.** An orchestrator or peer agent trusts another agent's messages, tool calls, or return values without validation. A compromised or misbehaving agent propagates its effects.

**References.** ASI07.

**Mitigation prompts.** Do agents authenticate to each other? Are inter-agent messages structured and validated? Could a rogue agent impersonate another?

### ♥J — Cascading Failure `[EoA·HJ]`

> *"One agent's hallucination is another agent's ground truth."*

**Threat.** An error, hallucination, or partial compromise in one agent propagates through a multi-agent system, amplifying as it spreads.

**References.** ASI08.

**Mitigation prompts.** Where are the circuit breakers? Are retry budgets bounded? Can the chain be killed from one place?

### ♥10 — Rogue Agent `[EoA·H10]`

> *"The agent looked legitimate in every individual action."*

**Threat.** A compromised, misaligned, forgotten, or unsanctioned agent operates in the environment, producing harm through actions that look legitimate in isolation.

**References.** ASI10.

**Mitigation prompts.** Is there an agent inventory? How is anomalous behaviour detected? What is the kill-switch latency?

### ♥9 — Confused Deputy Across Servers `[EoA·H9]`

> *"Two MCP servers in one client share a context they should not share."*

**Threat.** An MCP client is connected to multiple servers concurrently. One server's tool can shadow another's by exposing a tool with the same or similar name, intercepting calls intended elsewhere. One server can read context, approvals, or tool results that belong to another. The client becomes a confused deputy, brokering authority between mutually distrusting servers.

**References.** ASI03 cross-context. ASI07 inter-component trust. CAPEC-141.

**Mitigation prompts.** Are tools namespaced per server? Can two servers register the same tool name? Is each server's context isolated from the others? Does the user see which server a tool call is going to, in language they can verify? What happens when servers are added or removed mid-session?

---

## ♦ Diamonds - Data Threats

### ♦A — Sensitive Information Disclosure `[EoA·DA]`

> *"The model will tell you what it knows, whether it should or not."*

**Threat.** The model emits personal data, secrets, or proprietary information drawn from training, retrieval, or context.

**References.** OWASP LLM02.

**Mitigation prompts.** What data is in scope for retrieval? Is authorisation enforced at the data layer? What are the output filters catching?

### ♦K — Vector and Embedding Weakness `[EoA·DK]`

> *"The vector store is your new database and it has no access control."*

**Threat.** The RAG pipeline leaks data across tenants, allows embedding-based attacks, or inherits UI-layer access controls that do not apply at retrieval.

**References.** OWASP LLM08.

**Mitigation prompts.** How is the vector store partitioned? When is authorisation evaluated: at query time or earlier? Who can write to the corpus?

### ♦Q — Hallucinated Facts `[EoA·DQ]`

> *"The model is confidently wrong and the system treats confidence as correctness."*

**Threat.** The model generates false but plausible content that downstream consumers or users treat as ground truth. Includes slopsquatting, fabricated citations, and invented identifiers.

**References.** OWASP LLM09.

**Mitigation prompts.** Where does model output inform decisions or actions? Is there grounding? Are claims about external entities (people, packages, systems) verified?

### ♦J — Unbounded Consumption `[EoA·DJ]`

> *"Denial of wallet is a denial of service."*

**Threat.** Cost, compute, or rate limits are absent or ineffective. Malicious users (or bugs) cause runaway spend.

**References.** OWASP LLM10.

**Mitigation prompts.** What are the hard caps per user, per session, per agent? Are loops bounded? How is spend monitored?

### ♦10 — System Prompt Leakage `[EoA·D10]`

> *"The system prompt is not a secret store."*

**Threat.** System prompts containing credentials, business logic, or security instructions are extracted via prompt injection or inference.

**References.** OWASP LLM07.

**Mitigation prompts.** What is in the system prompt that should not be? What happens if the whole prompt leaks tomorrow?

### ♦9 — Server Impersonation and Rogue Servers `[EoA·D9]`

> *"Every byte of your prompt and every tool result flows through that server."*

**Threat.** An MCP server is typosquatted, hijacked, or stood up adversarially in a registry the client trusts. Once connected, it sees every prompt routed to its tools, every credential or token shared with it, and every return value. Data exfiltration is the primary risk; tool-output tampering is the secondary risk. The transport (stdio vs HTTP) changes the attack surface but not the underlying problem.

**References.** OWASP LLM03 supply chain. ASI04. MCP-specific.

**Mitigation prompts.** How is the server identified: by name, by signature, by pinned hash? What is the source of truth for the registry? What credentials and data does each server see? Is HTTP transport authenticated and bound to a specific origin? What happens if a server is silently replaced?

---

## ♣ Clubs - Privacy Threats

### ♣A — Transfer `[EoA·CA]`

> *"The model creates personal data at the point of transfer."*

**Threat.** The model manufactures personal data that is then transferred to a downstream system, log, or onward recipient. The data has no provenance and no consent chain.

**References.** T.R.I.M. Transfer. GDPR Article 5(1)(a), 5(1)(b).

**Mitigation prompts.** Does the data carry provenance tags? Can downstream consumers distinguish generated from collected data? Is onward transfer logged?

### ♣K — Retention and Removal `[EoA·CK]`

> *"Fabricated data persists the same as real data."*

**Threat.** Personal data (real or hallucinated) is persisted in RAG, memory, logs, or fine-tuning datasets without a mechanism for surgical removal. Article 16 and Article 17 rights become unenforceable.

**References.** T.R.I.M. Retention. GDPR Articles 16, 17.

**Mitigation prompts.** For each persistent store: can you locate a specific individual's data? Can you delete it? Can you prevent recurrence?

### ♣Q — Inference `[EoA·CQ]`

> *"The model derives personal data you never collected."*

**Threat.** The model infers new personal data (including special-category data under Article 9) from partial or unrelated inputs. The act of inference is itself the privacy event.

**References.** T.R.I.M. Inference. GDPR Article 9. LINDDUN Identifying.

**Mitigation prompts.** What does the model infer about people that it was not told? Does it ever touch special categories? What is the lawful basis for inferred data?

### ♣J — Minimisation `[EoA·CJ]`

> *"You minimise what you collect. Now minimise what you generate."*

**Threat.** The model generates more personal data than the task requires, producing unrequested claims that are both unminimised and hallucination-prone.

**References.** T.R.I.M. Minimisation. GDPR Article 5(1)(c).

**Mitigation prompts.** Is the input minimal for the task? Is the output minimal? Are output schemas constrained to what was asked?

### ♣10 — Unintervenability `[EoA·C10]`

> *"The subject cannot find out, cannot correct, cannot prevent recurrence."*

**Threat.** Data subjects have no practical mechanism to discover what the system claims about them, no route to correct it, and no assurance that corrections persist.

**References.** LINDDUN Unawareness/Unintervenability. GDPR Articles 13, 14, 16.

**Mitigation prompts.** Is the processing disclosed in the privacy notice? Is there a subject access process that covers model outputs? Do rectifications persist across sessions?

---

## ★ Trumps - Structural Hazards

Trumps beat any non-trump card. They represent structural properties of AI systems (architectural, mathematical, or product-design failures) that cannot be mitigated inside the model itself. The OWASP lists do not catch them because the OWASP framing assumes the model's behaviour is itself the defence; these cards exist because, for this class of threat, it cannot be.

### ★7 — Adversarial Subspace `[EoA·T7]`

> *"The attack surface is a space, not a list."*

**Threat.** Any input to an AI system is translated into a lower-dimensional numerical representation. That flattening creates a subspace of inputs that all produce approximately the same model behaviour. The subspace is mathematically enormous, provably unsearchable, and unpatchable. It is a property of the architecture, not a bug. Prompt-library-based red teaming and pattern-matching guardrails test a vanishing fraction of this surface. This card represents the deepest reason structural mitigations beat statistical ones.

**References.** Cox & Bunzel (2025), arXiv:2511.05102. Tramèr et al. (2017). Goodfellow, Shlens, Szegedy (2015). EchoGram (HiddenLayer, 2025) as a contemporary surface example.

**Mitigation prompts.** Are we relying on a library of known bad prompts as a defence? If yes, we are defending a vanishing fraction of the space. Is our security guarantee architectural or statistical? If statistical, what happens when the next perturbation lands outside our library tomorrow? What determines the outcome of every consequential decision: the model's classification, or a deterministic check downstream?

### ★6 — Geometric Attack `[EoA·T6]`

> *"The boundary is the attack surface, not the inputs that cross it."*

**Threat.** An attacker targets the geometry of the model's decision surface directly: by probing a black-box classifier (GeoDA, SurFree), by exploiting non-Euclidean embeddings (AGSM), or by rotating an angular-margin embedding on a hypersphere (ArcFace-style attacks). The attack succeeds without access to weights, training data, or gradients.

**References.** Tramèr et al. 2017 foundation. GeoDA, SurFree, AGSM, angular-margin attack literature. CAPEC-115 when authentication is gated by the model.

**Mitigation prompts.** Does any consequential decision depend on a single model's classification? Can an attacker probe it with queries? Is the downstream enforcement deterministic or does it inherit the model's verdict? Is adversarial testing matched to the geometry the model uses?

### ★5 — Context Rot `[EoA·T5]`

> *"Your safety instructions were at the top. They have decayed in attention weight."*

**Threat.** As a session grows, attention to system prompts, role definitions, and authorisation context decays. Guardrails that held on turn 1 fail on turn 50 without any adversarial input.

**References.** Chroma 2025 research. Cross-cutting amplifier for LLM01, LLM06, ASI01, ASI02, ASI06, ASI08.

**Mitigation prompts.** What is the longest realistic session? At that length, which safety-relevant tokens are in the lost-in-the-middle zone? Are critical instructions periodically re-injected?

### ★4 — Decision Boundary Transfer `[EoA·T4]`

> *"The boundary your model defends is the boundary every other model defends."*

**Threat.** Models trained on the same domain share similar decision boundaries regardless of algorithm or dataset. Adversarial examples transfer freely; model robustness is a property of the domain, not the model.

**References.** Tramèr et al. 2017. Cox applications.

**Mitigation prompts.** What security guarantees are we relying on the model itself to provide? Can any of them be moved to a deterministic layer?

### ★3 — Excessive Autonomy by Design `[EoA·T3]`

> *"You gave the agent autonomy because the demo was cool."*

**Threat.** Product decisions grant the agent autonomy that the risk model does not justify. Confirmation steps are removed because they are "friction". The autonomy becomes the blast radius.

**References.** LLM06 taken seriously at the product level.

**Mitigation prompts.** Which confirmations were removed for UX reasons? What is the worst thing the agent can do with no human in the loop? Does the product justification survive a post-incident review?

### ★2 — Invisible Dependency `[EoA·T2]`

> *"The thing you depend on is not in your SBOM."*

**Threat.** The agent's behaviour depends on model versions, prompt templates, tool descriptions, or memory state that are not in any tracked inventory.

**References.** LLM03. ASI04.

**Mitigation prompts.** What determines this agent's behaviour? Is all of it pinned, versioned, and inventoried? What happens when an external dependency changes silently?

### ★1 — Wrong Abstraction `[EoA·T1]`

> *"You are treating the model as a system of record."*

**Threat.** Downstream processes, users, or agents treat model output as authoritative. The model is neither a database nor a source of truth, and any consumer that treats it as one imports every failure mode as a fact.

**References.** ASI09. LLM09 at the architectural level.

**Mitigation prompts.** Where is model output treated as authoritative? What provenance does the UI surface? Is there a verification step, or has the caveat been lost?

---
