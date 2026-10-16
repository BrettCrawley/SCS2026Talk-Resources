# Design Patterns — Deep Reference

## Table of Contents
1. [Software Design Patterns](#software-design-patterns)
2. [System Design Patterns](#system-design-patterns)
3. [Security Design Patterns](#security-design-patterns)
4. [Pattern Selection Guide](#pattern-selection-guide)

---

## Software Design Patterns

### Creational Patterns

**Factory Method** — Define an interface for creating objects, but let subclasses decide which class to instantiate.
- Use when: the exact type to create depends on runtime configuration or input. Common in plugin architectures.
- Security use: create different authentication handlers based on the configured provider without changing calling code.

**Abstract Factory** — Create families of related objects without specifying concrete classes.
- Use when: the system must work with multiple families of products (e.g., UI toolkit themes, database backends).
- Security use: create a family of crypto primitives (encryptor, hasher, signer) that are consistent with each other (e.g., all FIPS-compliant or all cloud-native).

**Builder** — Separate the construction of a complex object from its representation.
- Use when: object construction involves many parameters, optional fields, or validation rules.
- Security use: build security policies step-by-step with validation at each step. A `SecurityPolicyBuilder` that ensures you can't create a policy without at least one authentication mechanism.

**Singleton** — Ensure a class has only one instance and provide global access.
- Use sparingly. Global state is an anti-pattern in most contexts.
- Legitimate uses: connection pools, configuration registries, logging infrastructure.
- Security risk: singletons in multi-threaded contexts need thread safety. A singleton that holds credentials must be protected against unauthorized access from any thread.

**Prototype** — Create objects by cloning an existing instance.
- Use when: object creation is expensive and configuration is complex.
- Security risk: deep vs shallow clone matters. A shallow clone of an object containing a reference to a database connection shares that connection — potentially violating least privilege.

### Structural Patterns

**Adapter** — Convert one interface to another that clients expect.
- Use when: integrating legacy systems, third-party libraries, or external APIs with different interfaces.
- Security use: wrap a legacy authentication system behind a modern OIDC-compatible interface.

**Decorator** — Attach additional responsibilities to objects dynamically.
- Use when: you need to add behavior (logging, caching, authorization) without modifying the original class.
- Security use: decorate a service with authorization checking, audit logging, and rate limiting as separate, composable layers.

**Facade** — Provide a simplified interface to a complex subsystem.
- Use when: a subsystem has many classes and the client needs a simple entry point.
- Security use: a `CryptoFacade` that exposes `encrypt(data)` and `decrypt(data)`, hiding key management, algorithm selection, and IV generation.

**Proxy** — Provide a surrogate that controls access to another object.
- Use when: you need access control, lazy initialization, logging, or remote access.
- Security use: a protection proxy that checks authorization before delegating to the real object. A logging proxy that records all access.

**Composite** — Compose objects into tree structures to represent part-whole hierarchies.
- Use when: clients need to treat individual objects and compositions uniformly.
- Security use: model permission hierarchies where a folder's permissions compose with file permissions.

### Behavioral Patterns

**Strategy** — Define a family of algorithms, encapsulate each one, and make them interchangeable.
- Use when: multiple algorithms exist for a task and the choice depends on context or configuration.
- Security use: pluggable encryption strategies (AES-GCM for performance, RSA for interoperability), pluggable authentication strategies (password, SSO, certificate).

**Observer** — Define a one-to-many dependency so that when one object changes, all dependents are notified.
- Use when: decoupled communication between components. Event-driven architectures.
- Security use: security event broadcasting — an authentication failure notifies the rate limiter, the audit logger, and the anomaly detector independently.

**Chain of Responsibility** — Pass a request along a chain of handlers. Each handler decides whether to handle it or pass it along.
- Use when: multiple handlers might process a request, and the handler isn't known in advance.
- Security use: middleware chains in web frameworks — authentication, authorization, input validation, rate limiting, and request logging as independent, ordered handlers.

**Command** — Encapsulate a request as an object, allowing parameterization, queuing, and undo.
- Use when: you need to queue, log, or undo operations.
- Security use: audit logging via command objects — every action is an immutable command record. Undo/redo with full audit trail.

**State** — Allow an object to alter its behavior when its internal state changes.
- Use when: an object has distinct behavioral modes (e.g., a connection that behaves differently when authenticated vs unauthenticated).
- Security use: session state machine — `Unauthenticated → Authenticated → Elevated → Locked` with different allowed operations in each state.

**Template Method** — Define the skeleton of an algorithm, deferring some steps to subclasses.
- Use when: multiple variants of an algorithm share the same structure but differ in specific steps.
- Security use: a request processing template that always validates input, always logs the request, and always checks authorization — but lets subclasses define the business logic step.

### Modern Patterns

**Repository** — Mediates between the domain and data mapping layers, acting like an in-memory collection.
- Decouples business logic from data access. Enables unit testing with in-memory fakes.
- Define repositories as interfaces in the domain layer, implement them in the infrastructure layer (Clean Architecture).

**Unit of Work** — Maintains a list of objects affected by a business transaction and coordinates writing changes.
- Ensures atomicity of business operations that span multiple repositories.
- Security implication: all-or-nothing guarantees prevent partial updates that could leave the system in an insecure state.

**Specification** — Encapsulate business rules as composable, reusable predicates.
- Use when: business rules are complex and need to be combined (`AND`, `OR`, `NOT`).
- Security use: compose authorization rules — `IsAuthenticated AND (IsAdmin OR IsOwner) AND NOT IsBlocked`.

**CQRS (Command Query Responsibility Segregation)** — Separate read and write models.
- Use when: read and write workloads have very different characteristics.
- Security benefit: the read model can be exposed with broader access (read-only), while the write model is tightly controlled.
- Trade-off: eventual consistency between read and write models. Not suitable when reads must reflect the very latest writes.

**Event Sourcing** — Store state changes as a sequence of immutable events rather than mutable current state.
- Use when: you need a complete audit trail, temporal queries, or event-driven architecture.
- Security benefit: immutable event log is a built-in audit trail. State at any point in time can be reconstructed.
- Security risk: events may contain PII. GDPR right to erasure conflicts with immutability. Solutions: crypto-shredding (encrypt PII with per-user keys, delete the key to "forget").

---

## System Design Patterns

### Decomposition Patterns

**Decompose by Business Capability** — Align services to business capabilities (order management, inventory, payments), not technical layers (API, business logic, data).
- Each service owns its data, its business logic, and its interface.
- Security benefit: blast radius is limited to a business capability, not a technical layer.

**Strangler Fig** — Incrementally replace a legacy system by routing requests to new components as they're built.
- New components sit alongside the old system. A routing layer directs traffic.
- Security benefit: security improvements can be deployed incrementally without a risky big-bang migration.

**Backends for Frontends (BFF)** — Create separate backend services for each frontend (web, mobile, admin).
- Each BFF tailors the API to its frontend's needs and security requirements.
- Security benefit: the admin BFF can enforce stricter authentication and audit logging than the public web BFF.

### Communication Patterns

**API Gateway** — Single entry point for all client requests. Handles authentication, rate limiting, routing, TLS termination.
- Security benefit: centralized security enforcement. Internal services don't need to handle TLS or authentication.
- Risk: single point of failure. Mitigate with high availability and circuit breakers.

**Service Mesh** — Infrastructure layer for service-to-service communication (e.g., Istio, Linkerd).
- Provides mTLS, retries, circuit breaking, and observability without application code changes.
- Security benefit: mTLS between all services by default. Zero-trust networking without application changes.

**Event-Driven / Pub-Sub** — Services communicate via events through a message broker.
- Decouples producers from consumers. Enables async processing and replay.
- Security considerations: message encryption in transit and at rest. Topic-level access control. Schema validation to prevent malicious payloads.

**Saga Pattern** — Manage distributed transactions as a sequence of local transactions with compensating actions.
- Use instead of distributed two-phase commit (which doesn't scale and is fragile).
- Security consideration: compensating actions must be idempotent and secure. A failed payment reversal shouldn't create a negative balance.

### Resilience Patterns

**Circuit Breaker** — Detect failures and stop calling a failing service to prevent cascade failures.
- States: Closed (normal) → Open (failing, reject calls) → Half-Open (test with limited traffic).
- Security consideration: circuit breakers for authentication services must fail closed (deny access), not open (allow access).

**Bulkhead** — Isolate failures by partitioning resources (thread pools, connection pools, processes).
- Named after ship compartments that prevent flooding from spreading.
- Security benefit: a resource exhaustion attack on one endpoint doesn't starve others.

**Retry with Backoff** — Retry failed requests with exponential backoff and jitter.
- Prevents thundering herd problems after transient failures.
- Security consideration: retries must not bypass rate limiting or create amplification attacks.

**Graceful Degradation** — When a non-critical service fails, continue with reduced functionality.
- Example: if the recommendation service is down, show popular items instead.
- Security rule: never degrade security controls. If the auth service is down, deny access — don't serve unauthenticated content.

### Infrastructure Patterns

**Sidecar** — Deploy helper functionality (logging, monitoring, proxy) alongside the main service as a co-process.
- Part of the service mesh pattern. Each service instance gets a sidecar proxy.
- Security benefit: security concerns (mTLS, token validation) handled by the sidecar, not application code.

**Ambassador** — A specialized sidecar that handles client-side connectivity (TLS, retry, discovery).
- Security benefit: centralized TLS configuration, certificate rotation handled by the ambassador.

**Immutable Infrastructure** — Servers are never modified after deployment. Changes are deployed as new instances.
- Security benefit: eliminates configuration drift. Every instance is identical to what was tested.
- Enables rapid rollback if a deployment introduces a security issue.

---

## Security Design Patterns

**Secure Session Management**
- Session ID generated by CSPRNG, sufficient length (128+ bits of entropy)
- Stored server-side (Redis, database) — never in a cookie value
- Cookie attributes: HttpOnly, Secure, SameSite=Strict, short Max-Age
- Session fixation prevention: regenerate session ID after authentication
- Idle timeout (15-30 min) and absolute timeout (8-12 hours)

**Intercepting Validator**
- All input validated at the system boundary by a dedicated validation layer
- Validators are composable and reusable (strategy pattern)
- Validation failures logged with details for security monitoring
- Input is validated once and the validated result (typed, bounded) is passed inward

**Secure Logger**
- Structured logging with mandatory fields (timestamp, service, action, user, trace ID)
- PII scrubbing: configurable fields that are masked or hashed before writing
- Log integrity: hash chain or signing to detect tampering
- Immutable storage: logs shipped to write-once storage

**Security Kernel**
- Minimal, auditable core that enforces security policy
- All security-critical decisions pass through the kernel
- The kernel is small enough to be formally reviewed and tested exhaustively
- Everything outside the kernel is untrusted by default

**Reference Monitor**
- Mediates all access to resources
- Always invoked (complete mediation), tamper-proof, and verifiably correct
- Implemented as a centralized authorization service or policy decision point
- All enforcement points call the reference monitor — they don't implement policy locally

**Capability-Based Security**
- Access controlled by possession of an unforgeable token (capability)
- Capabilities are specific: a capability to read file X, not "access to the filesystem"
- Minimizes ambient authority — a process has only the capabilities explicitly granted to it
- Used in systems like Capsicum, Fuchsia, and some microservice architectures

---

## Pattern Selection Guide

| Problem | Consider These Patterns |
|---------|------------------------|
| How do I structure my codebase? | Clean Architecture, Hexagonal Architecture, Vertical Slice |
| How do I add behavior without modifying code? | Decorator, Strategy, Plugin Architecture |
| How do I handle multiple algorithms? | Strategy, Template Method |
| How do I decouple components? | Observer, Event-Driven, Pub-Sub, Mediator |
| How do I control access to objects? | Proxy (protection), Reference Monitor, Capability-Based |
| How do I validate input? | Intercepting Validator, Chain of Responsibility |
| How do I handle distributed transactions? | Saga, Event Sourcing, Outbox Pattern |
| How do I prevent cascade failures? | Circuit Breaker, Bulkhead, Graceful Degradation |
| How do I separate read and write concerns? | CQRS, Read Replica, Materialized View |
| How do I decompose a monolith? | Strangler Fig, Decompose by Business Capability |
| How do I handle cross-cutting concerns? | Decorator, AOP, Middleware/Pipeline, Sidecar |
| How do I audit everything? | Event Sourcing, Command, Secure Logger |
| How do I manage authorization? | RBAC, ABAC, PBAC, Security Kernel |
