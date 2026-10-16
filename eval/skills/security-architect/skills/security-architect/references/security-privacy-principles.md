# Security & Privacy Principles — Deep Reference

## Table of Contents
1. [Security Principles Applied](#security-principles-applied)
2. [Privacy Architecture Patterns](#privacy-architecture-patterns)
3. [Privacy Dark Patterns — Detection and Prevention](#privacy-dark-patterns)
4. [The Data Lifecycle — Architecture Implications](#data-lifecycle-architecture)
5. [Authentication and Authorization Patterns](#authentication-and-authorization)
6. [Cryptography for Architects](#cryptography-for-architects)
7. [API Security Patterns](#api-security)
8. [Observability and Security Monitoring](#observability)

---

## Security Principles Applied

### Defense in Depth — Layered Controls

Design multiple independent layers. If one fails, the next holds:

```
Layer 1: Network → Firewalls, WAF, DDoS protection, network segmentation
Layer 2: Transport → TLS, mutual TLS, certificate pinning
Layer 3: Application → Input validation, output encoding, parameterized queries
Layer 4: Authentication → MFA, session management, credential rotation
Layer 5: Authorization → RBAC/ABAC, least privilege, complete mediation
Layer 6: Data → Encryption at rest, field-level encryption, tokenization
Layer 7: Monitoring → Audit logs, anomaly detection, alerting
Layer 8: Recovery → Backups, disaster recovery, incident response
```

Architecture decision: each layer should be independently testable and independently deployable where possible. Don't build a monolithic security middleware that handles all layers — decompose by concern.

### Least Privilege — Implementation Patterns

- **Service accounts**: Each service gets its own identity with minimal permissions. A reporting service has read-only database access. A payment service cannot access user profile tables.
- **Time-bound access**: Use short-lived tokens (JWTs with 15-minute expiry) rather than long-lived API keys.
- **Scoped tokens**: OAuth2 scopes define what an access token can do. A token with `read:profile` cannot `write:profile`.
- **Network-level**: Services can only reach the services they need. Payment service → payment gateway (yes), payment service → analytics dashboard (no).
- **Database-level**: Use database roles with column-level grants where supported. The application database user cannot `DROP TABLE`.

### Fail Securely — Architecture Patterns

- **Circuit breaker fails closed**: When an auth service is down, deny access — don't bypass authorization.
- **Default deny**: Firewall rules, CORS policies, CSP headers all default to denying everything, then explicitly allow what's needed.
- **Error handling**: Catch specific exceptions. Never catch `Exception` and continue. Log the full error internally; return a generic error externally.
- **Graceful degradation**: When a non-critical service fails, the system continues with reduced functionality — but never with reduced security.
- **Timeout handling**: Requests that time out are treated as failures, not successes. A timed-out authorization check means access denied.

### Complete Mediation — Every Access Checked

- **No authorization caching without explicit invalidation**: If you cache "user X can access resource Y", you need a mechanism to invalidate that cache when permissions change.
- **Middleware enforcement**: Authorization checks happen at the gateway or middleware layer, not scattered through business logic. A single enforcement point is easier to audit and harder to bypass.
- **Re-authentication for sensitive operations**: Password change, payment confirmation, and admin actions should require re-authentication even within an active session.

### Separation of Duties — Architectural Decomposition

- **Control plane vs data plane**: The service that configures access policies is separate from the service that enforces them.
- **Key management**: The service that uses encryption keys does not manage them. Key Management Service (KMS) is a separate concern.
- **Audit logging**: The system being audited does not control its own audit logs. Logs are shipped to an immutable external store.
- **Deployment**: The person who writes code is not the same person who approves the deployment to production (enforced by CI/CD pipeline).

---

## Privacy Architecture Patterns

### Minimize — Collect Less
- **Aggregation**: Store aggregated analytics (page views per day) instead of individual events (user X visited page Y at time Z)
- **Pseudonymization**: Replace direct identifiers with pseudonyms. The mapping table is stored separately with stricter access controls.
- **Anonymization**: Remove or generalize identifying attributes until re-identification is impractical. k-anonymity, l-diversity, t-closeness are formal measures.
- **Edge processing**: Process data at the edge (client-side analytics, federated learning) so raw personal data never reaches your servers.

### Separate — Distribute Data
- **Data partitioning**: Store personal data and behavioral data in separate services with separate access controls.
- **Reference architecture**: Identity service holds PII. Other services hold only pseudonymous IDs that reference the identity service. If the analytics service is breached, no PII is exposed.
- **Geographic separation**: Store EU residents' data in EU regions. Not just for compliance — it limits blast radius.

### Hide — Encrypt and Protect
- **Envelope encryption**: Data encrypted with a Data Encryption Key (DEK), DEK encrypted with a Key Encryption Key (KEK) held in KMS.
- **Field-level encryption**: Encrypt sensitive fields (SSN, credit card) individually, not just the whole database. Different fields can have different access policies.
- **Tokenization**: Replace sensitive data with non-reversible tokens for processing that doesn't need the real value (analytics, testing).
- **Differential privacy**: Add calibrated noise to query results so individual records cannot be inferred.

### Enforce — Technical Controls
- **Consent management architecture**: Consent is stored as a structured record (purpose, timestamp, version, expiry) not a boolean flag. Downstream services check consent before processing.
- **Purpose-bound processing**: Data tagged with its collection purpose. Processing pipelines enforce purpose limitation — data collected for "order fulfillment" cannot be used for "marketing" without separate consent.
- **Retention enforcement**: Automated retention policies with cryptographic erasure. When retention expires, the DEK is deleted, rendering the data unrecoverable.
- **Data subject request pipeline**: Automated handling of access, rectification, and erasure requests. The system can enumerate all data about a subject across all services and act on it within regulatory timeframes.

---

## Privacy Dark Patterns

### Detection Checklist

When reviewing a design for privacy dark patterns, check each of these:

| Dark Pattern | Test Question | Architectural Fix |
|--------------|---------------|-------------------|
| Hidden defaults | Are privacy-invasive settings opt-out instead of opt-in? | Default all sharing to off. Require explicit opt-in. |
| Trick questions | Are consent prompts confusing (double negatives, pre-checked boxes)? | Plain language. One question per purpose. No pre-checked boxes. |
| Forced continuity | Is it harder to delete an account than to create one? | Account deletion is a one-click action with clear confirmation. |
| Privacy zuckering | Does the UI encourage oversharing? | Only request data needed for the current task. No "complete your profile" nudges for optional fields. |
| Misdirection | Is the privacy-preserving option visually de-emphasized? | Equal visual weight for all options. The private option is not grayed out or smaller. |
| Confirmshaming | Does declining data sharing use guilt-inducing language? | Neutral language for all choices. "No thanks" not "No, I don't care about my security." |
| Roach motel | Is it easy to grant consent but hard to revoke it? | Revocation is as easy as granting. Same number of clicks, same location in the UI. |
| Nagging | Does the system repeatedly ask for consent after the user declines? | Ask once. Respect the answer. Provide a settings page if they change their mind. |

### Architecture-Level Prevention

- **Consent service as a first-class component**: Not an afterthought buried in user settings. A dedicated consent service with its own API, storage, and audit trail.
- **Privacy UX review as a gate**: No consent flow ships without review against the dark patterns checklist. Automate where possible (flag double negatives, detect pre-checked boxes in UI tests).
- **A/B testing boundaries**: Never A/B test consent flows in ways that reduce privacy protections for the "B" group.

---

## Data Lifecycle Architecture

### Collection
- API design: only accept the fields you need. Don't accept and silently ignore extra fields — reject them.
- Client-side validation: don't let sensitive data reach the server if it's invalid. But never trust client-side validation alone.
- Consent capture: at the point of collection, record what the user consented to, in what version of the policy, at what timestamp.

### Processing
- Pipeline architecture: data processing is a pipeline of discrete, auditable steps. Each step has a defined input, output, and purpose.
- Purpose binding: each pipeline is tagged with its purpose. Data can only enter a pipeline if the user's consent covers that purpose.
- PII detection: automated scanning to detect PII in unexpected places (log files, analytics events, error messages).

### Storage
- Encryption at rest: always. No exceptions. Use envelope encryption.
- Access controls: database-level, application-level, and network-level. Defense in depth.
- Classification: every data store has a data classification label (public, internal, confidential, restricted). Access policies follow classification.
- Backup encryption: backups are encrypted with separate keys. Backup access is audited.

### Sharing
- Data sharing agreements: formalized in architecture as API contracts with access controls, rate limits, and audit logging.
- Data loss prevention: automated scanning at egress points (APIs, email, file exports) to detect PII leaving the system.
- Third-party integrations: third-party SDKs and APIs are treated as untrusted. Data shared with them is minimized and audited.

### Retention
- Policy-as-code: retention periods are defined in configuration, enforced by automated jobs, and auditable.
- Cascading deletion: deleting a user cascades to all related data across all services. The system maps all data relationships.
- Backup alignment: retention policies account for backup schedules. If data must be deleted in 30 days, backups older than 30 days must also be purged or the data within them must be cryptographically erased.

### Destruction
- Cryptographic erasure: delete the encryption key rather than overwriting all copies of the data. Effective for cloud storage where you can't guarantee physical overwrite.
- Media sanitization: for on-premises hardware, follow NIST SP 800-88 guidelines.
- Verification: after deletion, verify that data is no longer accessible via any path (API, database, cache, backup, search index, CDN).

---

## Authentication and Authorization Patterns

### Authentication
- **OAuth2 / OIDC**: Use for delegated authentication. Authorization Code flow with PKCE for web and native apps. Never Implicit flow.
- **Session management**: Short-lived sessions (15–30 min idle timeout), secure cookie attributes (HttpOnly, Secure, SameSite=Strict), server-side session store.
- **Token architecture**: Access tokens (short-lived, 15 min) for API calls. Refresh tokens (longer-lived, hours/days) for session continuity. Refresh token rotation on every use.
- **MFA**: TOTP or WebAuthn/FIDO2. SMS-based MFA is better than nothing but vulnerable to SIM swapping.
- **Passwordless**: WebAuthn/passkeys where possible. Eliminates credential stuffing as a threat class entirely.

### Authorization
- **RBAC** (Role-Based Access Control): Roles are assigned to users. Permissions are assigned to roles. Simple and auditable. Best for systems with well-defined, stable roles.
- **ABAC** (Attribute-Based Access Control): Access decisions based on attributes of the user, resource, and environment. More flexible than RBAC. Better for dynamic, context-dependent access decisions.
- **PBAC** (Policy-Based Access Control): Access decisions evaluated by a policy engine (e.g., OPA, Cedar). Policies are code, versioned and tested like code.
- **Capability-based security**: Access is granted by possessing an unforgeable token (capability) rather than by checking an access control list. Used in some microservice architectures.
- **Authorization architecture**: Centralize authorization logic in a dedicated policy decision point (PDP). Application services are policy enforcement points (PEPs) that call the PDP.

---

## Cryptography for Architects

Architects don't implement crypto — they choose the right primitives, design for algorithm agility, and plan for the post-quantum transition.

### Decision Guide

| Need | Primitive (Current) | Post-Quantum Alternative | Example |
|------|---------------------|--------------------------|---------|
| Data at rest | AES-256-GCM | AES-256-GCM (quantum-safe) | Database field encryption |
| Data in transit | TLS 1.2+ (ECDHE + AES-256-GCM) | TLS 1.3 with ML-KEM (Kyber) hybrid | HTTPS, gRPC with TLS |
| Password storage | Argon2id, bcrypt | Argon2id (quantum-safe) | User credentials |
| Data integrity | HMAC-SHA-256 or digital signatures | HMAC-SHA-256 (quantum-safe) | API request signing |
| Non-repudiation | Ed25519, RSA-PSS | ML-DSA (Dilithium), SLH-DSA (SPHINCS+) | Audit log signing |
| Key exchange | ECDH (P-256, X25519) | ML-KEM (Kyber) or hybrid ECDH+ML-KEM | TLS handshake, key agreement |
| Token generation | CSPRNG | CSPRNG (quantum-safe) | Session IDs, API keys |
| Searchable encryption | Deterministic encryption, HMAC indexing | Same (symmetric, quantum-safe) | Encrypted search |
| Key management | KMS (AWS KMS, Vault) | KMS with PQC algorithm support | All of the above |

### Crypto Agility — Algorithms as Configuration

Crypto agility is the architectural principle that cryptographic algorithms, key sizes, and protocols should be configurable and swappable without code changes. This is not optional — it is a structural requirement for any system expected to outlive its current algorithm choices.

**Why it matters**: Algorithms get broken, deprecated, or superseded. SHA-1 was once standard. RSA-1024 was once sufficient. The post-quantum transition will require replacing most asymmetric cryptography. If your algorithms are hardcoded, each transition is a re-architecture. If they're configuration, it's a deployment.

**Architecture patterns for crypto agility**:

- **Crypto provider abstraction**: Define an interface (e.g., `CryptoProvider`) with methods like `encrypt()`, `decrypt()`, `sign()`, `verify()`, `hash()`. Implementations wrap specific algorithms. The application depends on the interface, never on a specific algorithm.

- **Algorithm identifiers in ciphertext**: Every encrypted value includes a header or metadata indicating which algorithm and key version produced it. This enables decryption even after algorithm rotation — old data can be read with the old algorithm while new data uses the new one.

- **Configuration-driven selection**: Algorithm choice lives in configuration (environment variables, config files, Vault), not in code. Changing from AES-256-GCM to AES-256-CBC (or to a post-quantum algorithm) is a configuration change, not a code change.

- **Dual-write / gradual migration**: When rotating algorithms, encrypt with the new algorithm but retain the ability to decrypt with the old one. Backfill old data on a schedule. This avoids big-bang migrations.

- **Cipher suite configuration**: TLS cipher suites, JWT signing algorithms, and API signature schemes should all be configurable at the deployment level with strong defaults. Disable weak algorithms by default; enable only what's needed.

- **Testing for agility**: Include integration tests that swap algorithm configurations and verify the system still works. If a test breaks when you change the algorithm config, you've found a hardcoded dependency.

**Example configuration structure**:
```yaml
crypto:
  encryption:
    algorithm: AES-256-GCM          # Swappable
    key_provider: aws-kms           # Swappable
    key_id: alias/app-data-key
  signing:
    algorithm: Ed25519              # Swappable to ML-DSA when ready
    key_provider: vault
    key_path: signing/app-key
  hashing:
    password_algorithm: argon2id
    integrity_algorithm: SHA-256
  tls:
    min_version: "1.2"
    cipher_suites:                  # Ordered by preference
      - TLS_AES_256_GCM_SHA384
      - TLS_CHACHA20_POLY1305_SHA256
    # Future: hybrid PQC cipher suites when available
```

### Quantum Computing — Architectural Impact

**The threat model**: Quantum computers with sufficient qubits (cryptographically relevant quantum computers, or CRQCs) will break RSA, ECC, and other asymmetric cryptography based on integer factorization and discrete logarithms. Symmetric cryptography (AES) and hash functions (SHA-256) are weakened but remain viable at doubled key sizes (AES-256 provides 128-bit post-quantum security).

**"Harvest now, decrypt later" (HNDL)**: Adversaries are collecting encrypted data today with the intent to decrypt it when quantum computers become available. Any data with a secrecy requirement extending beyond 2030-2035 should be treated as at risk now.

**NIST Post-Quantum Standards** (finalized 2024):
- **ML-KEM (Kyber)** — Key Encapsulation Mechanism for key exchange. Replaces ECDH.
- **ML-DSA (Dilithium)** — Digital Signature Algorithm. Replaces Ed25519/RSA for general signing.
- **SLH-DSA (SPHINCS+)** — Stateless Hash-Based Signature. A conservative alternative to ML-DSA based on hash functions (well-understood security assumptions).
- **FN-DSA (Falcon)** — Compact signatures, standardization ongoing. Useful where signature size matters.

**Architectural decisions for the quantum transition**:

1. **Inventory your cryptographic dependencies**: Know every place your system uses asymmetric cryptography — TLS connections, JWT signing, code signing, encrypted storage, certificate chains, VPN tunnels, API authentication. You cannot migrate what you haven't mapped.

2. **Hybrid mode**: During the transition, use hybrid schemes that combine a classical and a post-quantum algorithm (e.g., ECDH + ML-KEM). If either algorithm is secure, the combined scheme is secure. This hedges against both quantum attacks and potential weaknesses in new PQC algorithms.

3. **Certificate and PKI planning**: Post-quantum certificates are larger (ML-DSA public keys are ~1.3KB vs 32 bytes for Ed25519). This affects TLS handshake performance, certificate chains, and storage. Plan for increased bandwidth and storage.

4. **Performance impact**: PQC algorithms have different performance profiles. ML-KEM key generation is fast but ciphertexts are larger. ML-DSA signing is fast but signatures are ~2.4KB. Benchmark in your specific environment before committing.

5. **HNDL mitigation timeline**: For data that must remain confidential for 10+ years, begin migrating to PQC key exchange (ML-KEM hybrid) now. For authentication and signing, the urgency is lower — these only matter when a CRQC exists, not retroactively.

6. **Crypto agility enables the transition**: If you've built with crypto agility (algorithms as config, provider abstraction, algorithm identifiers in ciphertext), the PQC migration is a configuration rollout. If you haven't, it's a re-architecture.

**Migration priority**:
```
Highest priority (HNDL risk):
  → Key exchange / encryption of long-lived secrets → Migrate to ML-KEM hybrid NOW

Medium priority:
  → Digital signatures for long-lived artifacts (code signing, document signing) → Plan migration to ML-DSA

Lower priority (no retroactive risk):
  → Authentication signatures (JWTs, API auth) → Migrate when ecosystem support matures
  → Symmetric encryption → Already quantum-safe at AES-256; no action needed
  → Password hashing → Already quantum-safe; no action needed
```

### Key Management Architecture
- Never store keys alongside the data they protect
- Use a dedicated KMS for key generation, storage, and rotation
- Envelope encryption: data encrypted with DEK, DEK encrypted with KEK in KMS
- Key rotation: automate it. Rotation should not cause downtime or data loss
- Key hierarchy: root keys → master keys → data keys. Each level protects the next
- **PQC readiness**: Verify that your KMS supports (or has a roadmap for) post-quantum algorithms. AWS KMS and Azure Key Vault are adding PQC support — check current status before selecting a provider
- **Key size planning**: PQC keys and ciphertexts are significantly larger than classical equivalents. Ensure key storage, transmission, and caching can handle the increased sizes

---

## API Security

- **Input validation**: Validate all input at the API boundary. Whitelist allowed characters, enforce length limits, reject unexpected fields.
- **Output encoding**: Encode output based on context (HTML, JSON, URL). Prevents XSS and injection.
- **Rate limiting**: Per-user, per-IP, and per-endpoint. Use token bucket or sliding window algorithms.
- **API gateway**: Centralize authentication, rate limiting, logging, and TLS termination. Services behind the gateway don't need to re-implement these.
- **API versioning**: Use URL path versioning (`/v1/`, `/v2/`) for clarity. Sunset old versions with advance notice.
- **GraphQL specifics**: Query depth limiting, query cost analysis, field-level authorization. GraphQL's flexibility is also its attack surface.
- **gRPC specifics**: Use mTLS between services. Define and enforce message size limits. Use interceptors for authentication and logging.

---

## Observability and Security Monitoring

### Structured Logging Architecture
- Log in structured format (JSON). Include: timestamp, service, trace ID, user ID (pseudonymized), action, result, duration.
- Never log: passwords, tokens, PII, encryption keys, full credit card numbers.
- Log levels: ERROR (something failed), WARN (something might be wrong), INFO (significant business events), DEBUG (development only, never in production).
- Ship logs to immutable, centralized storage. The application cannot modify or delete its own logs.

### Audit Trail Design
- Append-only store for security-relevant events (authentication, authorization, data access, configuration changes).
- Each audit record: who, what, when, where, why (if available), outcome (success/failure).
- Tamper detection: hash-chain or Merkle tree to detect modification. Alternatively, use a WORM (Write Once Read Many) storage backend.
- Retention: regulatory requirements dictate minimum retention. Typically 1-7 years depending on industry.

### Distributed Tracing
- Every request gets a trace ID at the edge. All downstream services propagate it.
- Trace ID appears in logs, metrics, and error reports — enabling correlation across services.
- Security use: trace ID enables forensic analysis of a suspicious request across all services it touched.

### Alerting Architecture
- Alert on anomalies, not just thresholds. Sudden spike in 401s, unusual data access patterns, login from new geography.
- Alert fatigue is a security risk. Too many false positives means real alerts get ignored. Tune aggressively.
- Separation of duties: the team that writes application code does not control alerting rules for security events.
