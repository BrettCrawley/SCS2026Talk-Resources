# SOLID Principles & Clean Architecture — Deep Reference

## Table of Contents
1. [SOLID in Practice](#solid-in-practice)
2. [Clean Architecture Layers](#clean-architecture-layers)
3. [Well-Architected in Practice](#well-architected-in-practice)
4. [Common Violations and Fixes](#common-violations-and-fixes)
5. [Architecture Smells](#architecture-smells)

---

## SOLID in Practice

### Single Responsibility Principle (SRP)

**The test**: "Describe what this class does. If the description contains 'and', it probably violates SRP."

**Common violations**:
- A `UserService` that handles registration, authentication, profile updates, and email notifications
- A controller that validates input, executes business logic, and formats the response
- A repository that queries the database and also handles caching

**How to fix**: Decompose by reason to change. A `UserRegistrationService`, `AuthenticationService`, `ProfileService`, and `NotificationService` each have one reason to change.

**Security implication**: SRP limits blast radius. If the authentication module is compromised, the profile module is unaffected because they share no state or code paths.

### Open-Closed Principle (OCP)

**The test**: "Can I add a new behavior without modifying existing code?"

**Patterns that enable OCP**:
- Strategy pattern: new algorithms without changing the context
- Decorator pattern: new behaviors layered onto existing objects
- Plugin architecture: new capabilities loaded at runtime
- Event-driven design: new handlers without modifying the publisher

**Security implication**: OCP reduces the risk of introducing regressions in security-critical code. Adding a new authentication provider shouldn't require modifying the existing authentication pipeline.

### Liskov Substitution Principle (LSP)

**The test**: "Can I use any subtype wherever the base type is expected, and the program still behaves correctly?"

**Classic violations**:
- `Square extends Rectangle` where `setWidth()` also sets height — breaks the invariant that width and height are independent
- `ReadOnlyList extends List` that throws `UnsupportedOperationException` on `add()` — clients expecting `List` behavior will break
- An `AdminUser extends User` that weakens authorization checks — security violation via LSP violation

**Behavioral contracts to preserve**:
- Preconditions cannot be strengthened in subtypes
- Postconditions cannot be weakened in subtypes
- Invariants of the supertype must be preserved
- The History Constraint: subtypes cannot introduce state changes that the supertype wouldn't allow

**Security implication**: LSP violations in authorization hierarchies create privilege escalation paths. If `RestrictedUser` is substitutable for `User` but has different security properties, callers may inadvertently grant elevated access.

### Interface Segregation Principle (ISP)

**The test**: "Does any client of this interface use fewer than half its methods?"

**How to decompose fat interfaces**:
- Role interfaces: `Readable`, `Writable`, `Deletable` instead of `FullCRUD`
- Command-query separation: `CommandHandler` and `QueryHandler` instead of `Handler`
- Capability interfaces: `CanSendEmail`, `CanGenerateReport` instead of `Service`

**Security implication**: ISP limits the attack surface exposed to each client. A read-only client should depend on a read-only interface, so even if the client is compromised, it cannot invoke write operations.

### Dependency Inversion Principle (DIP)

**The test**: "Do my high-level modules import low-level modules directly, or do they depend on abstractions?"

**Patterns that implement DIP**:
- Constructor injection: pass dependencies as constructor parameters
- Interface-based programming: depend on `UserRepository` (interface), not `PostgresUserRepository` (implementation)
- Event-driven: emit events rather than calling concrete services

**The Clean Architecture dependency rule is DIP applied at the architectural level**: business logic depends on abstractions that the infrastructure layer implements.

**Security implication**: DIP enables security-critical components to be swapped without changing business logic. Switching from HMAC to RSA for token signing is a dependency swap, not a rewrite.

---

## Clean Architecture Layers

### Layer 1: Entities (Enterprise Business Rules)
- Encapsulate the most general business rules
- Could be used by many different applications
- Least likely to change when something external changes
- Plain objects with business logic — no framework annotations, no database dependencies
- Example: `Order` entity with rules like "an order cannot have negative quantities" and "discount cannot exceed 50%"

### Layer 2: Use Cases (Application Business Rules)
- Application-specific business rules
- Orchestrate the flow of data to and from entities
- Direct entities to use their enterprise-wide business rules
- Changes here should not affect entities, and should not be affected by changes to frameworks or databases
- Example: `PlaceOrderUseCase` that validates the order, checks inventory, calculates total, and emits an event

### Layer 3: Interface Adapters
- Convert data from the format most convenient for use cases and entities to the format most convenient for external agencies (database, web, etc.)
- Controllers, presenters, gateways
- Example: `OrderController` that maps HTTP request → use case input, and use case output → HTTP response
- Example: `SqlOrderRepository` that implements the `OrderRepository` interface using SQL

### Layer 4: Frameworks & Drivers
- The outermost layer — the glue code
- Web framework, database driver, message broker client, HTTP client
- This is where all the details go
- Keep this layer thin — it should only contain wiring code

### Key Rules
1. **Dependencies point inward**: an inner layer never knows about an outer layer
2. **Data crosses boundaries as simple structures**: DTOs or plain data classes, not framework objects
3. **The Dependency Rule is enforced by interfaces**: inner layers define interfaces, outer layers implement them
4. **Testing becomes trivial**: business logic can be tested without frameworks, databases, or HTTP

### Hexagonal Architecture (Ports & Adapters)

An alternative framing of the same ideas:
- **Ports**: interfaces defined by the application core (inbound ports for driving, outbound ports for driven)
- **Adapters**: implementations that connect ports to external systems
- **Inbound adapters** (driving): REST controller, CLI, message consumer — they call the application
- **Outbound adapters** (driven): database repository, HTTP client, message producer — the application calls them

The hexagon shape is a visual metaphor — there's no special significance to six sides. The point is that the application core is at the center, and all external concerns attach via adapters.

---

## Well-Architected in Practice

### Operational Excellence
- Infrastructure as Code for all environments
- Automated CI/CD pipelines with security gates (SAST, DAST, dependency scanning, SBOM generation)
- Observability: structured logging, distributed tracing, metrics dashboards
- Runbooks for common operational scenarios
- Post-incident reviews that produce architectural improvements, not just process changes

### Security Pillar
- Identity and access management at every layer (network, application, data)
- Encryption in transit (TLS 1.2+) and at rest (AES-256 or equivalent)
- Secrets management (Vault, AWS Secrets Manager, Azure Key Vault) — never environment variables in production
- Network segmentation and zero-trust networking
- Automated security testing in CI/CD
- Incident response plan that's actually tested

### Reliability Pillar
- Design for failure: every component will fail, design for graceful degradation
- Redundancy: no single points of failure for critical paths
- Circuit breakers: prevent cascade failures
- Health checks: deep health checks that verify dependencies, not just "the process is running"
- Chaos engineering: regularly test failure scenarios in production-like environments

### Performance Efficiency
- Caching strategy: what to cache, where (CDN, application, database), invalidation strategy
- Database optimization: query patterns drive schema design, not the other way around
- Async processing: queue long-running work, don't block request threads
- Connection pooling: for databases, HTTP clients, and message brokers
- Load testing: establish baselines, set alerts on degradation

### Cost Optimization
- Right-size compute resources based on actual utilization
- Use spot/preemptible instances for fault-tolerant workloads
- Reserved capacity for stable baseline, on-demand for spikes
- Data tiering: hot/warm/cold storage based on access patterns
- Tag everything for cost attribution

---

## Common Violations and Fixes

| Violation | Symptom | Fix |
|-----------|---------|-----|
| God class | One class with 2000+ lines and 50+ methods | Decompose by responsibility |
| Feature envy | Class A constantly reaches into Class B's data | Move behavior to where the data lives |
| Shotgun surgery | One change requires modifications in 10 files | Consolidate related behavior |
| Leaky abstraction | Callers must understand the implementation to use the interface | Redesign the abstraction |
| Circular dependency | A depends on B depends on C depends on A | Introduce an interface to break the cycle |
| Anemic domain model | Entities are just data bags, all logic in services | Move logic into entities |
| Framework coupling | Business logic imports framework classes | Apply dependency inversion |

---

## Architecture Smells

**Smell: Distributed Monolith**
You built microservices but they're all tightly coupled, deploy together, and share a database.
Fix: Define clear bounded contexts. Each service owns its data. Communicate via events or well-defined APIs.

**Smell: Smart Endpoints, Dumb Pipes (Inverted)**
Your message broker contains business logic (complex routing, transformation, orchestration).
Fix: Keep infrastructure pipes simple. Business logic belongs in services.

**Smell: Database-Driven Design**
Your architecture is shaped by the database schema rather than business capabilities.
Fix: Start from domain modeling. Let the database schema follow the domain, not the other way around.

**Smell: Insufficient Trust Boundaries**
All internal services trust each other implicitly — no authentication or authorization between services.
Fix: Zero-trust architecture. Every service authenticates and authorizes every request, even from internal callers.

**Smell: God Service**
One service handles 70% of the traffic and 40% of the business logic.
Fix: Decompose by bounded context. Apply the Strangler Fig pattern to migrate incrementally.
