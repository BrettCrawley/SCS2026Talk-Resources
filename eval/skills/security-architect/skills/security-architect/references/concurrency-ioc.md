# Concurrency, IoC, and Cross-Cutting Concerns — Deep Reference

## Table of Contents
1. [Multi-Threading](#multi-threading)
2. [Multi-Processing](#multi-processing)
3. [Choosing Between Threads and Processes](#choosing-threads-vs-processes)
4. [Dependency Injection](#dependency-injection)
5. [Aspect-Oriented Programming](#aspect-oriented-programming)
6. [Proxies and Agents](#proxies-and-agents)
7. [Inversion of Control](#inversion-of-control)

---

## Multi-Threading

### Core Concepts

**Thread Safety**: Code is thread-safe if it behaves correctly when accessed by multiple threads simultaneously without requiring external synchronization.

**Race Condition**: Two or more threads access shared state, and the outcome depends on the interleaving of operations. A classic example: check-then-act (check if a file exists, then write to it — another thread may delete it between the check and the write).

**Deadlock**: Two or more threads are waiting for each other to release locks, and none can proceed. Prevention strategies: lock ordering (always acquire locks in the same order), lock timeouts, deadlock detection.

**Starvation**: A thread is perpetually denied access to resources because other threads are always prioritized.

**Livelock**: Threads repeatedly change state in response to each other without making progress — like two people stepping aside for each other in a corridor.

### Thread Safety Patterns

**Immutability** — The safest approach. If data cannot be modified, it cannot cause race conditions.
- Use immutable data classes and value objects wherever possible
- In Python: `@dataclass(frozen=True)`, `NamedTuple`, or `attrs(frozen=True)`
- In Java: `record` types, `final` fields, `Collections.unmodifiableList()`
- In JavaScript/TypeScript: `Object.freeze()`, `readonly` properties, `as const`

**Confinement** — Each thread has its own copy of the data. No sharing means no contention.
- Thread-local storage: `threading.local()` in Python, `ThreadLocal<T>` in Java
- Message passing between threads instead of shared memory
- Actor model: each actor has private state, communicates only via messages (Akka, Erlang-style)

**Synchronization** — When shared mutable state is unavoidable:
- **Mutexes/Locks**: Protect critical sections. Keep critical sections as short as possible.
- **Read-write locks**: Allow concurrent reads but exclusive writes. Use when reads vastly outnumber writes.
- **Semaphores**: Control access to a finite number of resources (e.g., connection pool with max 10 connections).
- **Atomic operations**: Lock-free primitives for simple operations (increment, compare-and-swap). `AtomicInteger`, `threading.Lock` context managers.
- **Lock-free data structures**: Concurrent queues, concurrent hash maps. Use library implementations — writing correct lock-free code is extremely difficult.

### Async/Await Patterns

Async/await is for I/O-bound concurrency — not CPU-bound parallelism. It runs on a single thread with cooperative multitasking.

- **Python** (`asyncio`): Use for network I/O (HTTP calls, database queries). Does not parallelize CPU work due to the GIL. Use `asyncio.gather()` for concurrent I/O operations.
- **JavaScript** (`async/await`): Single-threaded event loop. All I/O is async by default. Use `Promise.all()` for concurrent operations.
- **Java** (`CompletableFuture`, virtual threads): Virtual threads (Project Loom) provide lightweight threads for I/O-bound work without the `async/await` syntax.

**Security considerations for async code**:
- Request context (user identity, trace ID) must be propagated across `await` boundaries. Use context variables (`contextvars` in Python, `AsyncLocalStorage` in Node.js).
- Timeouts on all async operations to prevent resource exhaustion. A forgotten `await` with no timeout is a potential DoS vector.
- Error handling: unhandled rejections/exceptions in async code can silently swallow failures. Always handle errors explicitly.

### The GIL (Python-Specific)

Python's Global Interpreter Lock (GIL) allows only one thread to execute Python bytecode at a time. This means:
- Multi-threading in Python does NOT provide CPU parallelism for Python code
- Multi-threading in Python DOES provide concurrency for I/O-bound operations (the GIL is released during I/O)
- For CPU-bound parallelism in Python, use multi-processing (`multiprocessing` module) or C extensions that release the GIL

---

## Multi-Processing

### When to Use Processes

- CPU-bound work that needs true parallelism (data processing, image processing, ML training)
- Isolation requirements: a crash in one process doesn't affect others
- Security boundaries: each process can have different OS-level permissions (Linux capabilities, seccomp profiles)

### IPC (Inter-Process Communication) Mechanisms

| Mechanism | Speed | Complexity | Security |
|-----------|-------|------------|----------|
| Pipes/stdin-stdout | Fast | Low | Moderate — data crosses process boundary |
| Message queues | Medium | Medium | Good — broker can enforce ACLs |
| Shared memory | Very fast | High | Risk — both processes access same memory |
| Sockets (Unix/TCP) | Medium | Medium | Good — can use TLS, authentication |
| Memory-mapped files | Fast | High | Risk — file permissions are the only control |
| RPC (gRPC, Thrift) | Medium | Medium | Good — supports mTLS, authentication |

**Security guidance**: Prefer message passing (queues, pipes, sockets) over shared memory. Shared memory is fast but creates a shared attack surface. If shared memory is required, use OS-level access controls and validate all data read from shared memory as if it were untrusted input.

### Process Pool Patterns

- Pre-fork model: create a pool of worker processes at startup. Distribute work via a queue.
- Python: `multiprocessing.Pool`, `concurrent.futures.ProcessPoolExecutor`
- Security: each worker process should run with minimum privileges. If a worker is compromised, it cannot access resources beyond its scope.

---

## Choosing Threads vs Processes

| Factor | Threads | Processes |
|--------|---------|-----------|
| Memory usage | Low (shared memory space) | High (separate memory space) |
| Communication | Easy (shared state) but risky | Harder (IPC) but safer |
| Isolation | None — one thread can corrupt another's state | Full — a crash in one process doesn't affect others |
| Security boundary | No isolation — all threads share privileges | Strong — each process can have different privileges |
| CPU parallelism | Language-dependent (GIL in Python) | Yes, always |
| I/O concurrency | Yes | Yes |
| Startup cost | Low | Higher |

**Architectural recommendation**: Use processes for security boundaries and CPU parallelism. Use threads (or async) for I/O concurrency within a process. The combination — multiple processes, each with async I/O — is a robust pattern for web services.

---

## Dependency Injection

### Principles

Dependency Injection (DI) is DIP made concrete: instead of a class creating its dependencies, they're passed in from outside.

### Injection Styles

**Constructor Injection** (preferred):
```
class OrderService:
    def __init__(self, repo: OrderRepository, notifier: Notifier):
        self._repo = repo
        self._notifier = notifier
```
- All dependencies explicit and visible
- Object is fully initialized after construction
- Easy to test: pass fakes in tests

**Method Injection**:
```
class ReportGenerator:
    def generate(self, data_source: DataSource) -> Report:
        ...
```
- Use when the dependency varies per invocation, not per instance

**Interface Injection**: The dependency provides an injection method that the client must call. Less common, mostly seen in older frameworks.

### DI Containers

Containers automate dependency resolution:
- Register interfaces and their implementations
- The container constructs the object graph, resolving all dependencies
- Lifecycle management: singleton, scoped (per-request), transient (new each time)

**Common containers**: Spring (Java), .NET DI, `dependency-injector` (Python), InversifyJS (TypeScript)

**Service Locator** — the anti-pattern:
- A global registry that components query for their dependencies
- Problem: hides dependencies (they're not visible in the constructor), makes testing harder, creates a global mutable singleton
- DI containers are not service locators — the difference is that with DI, dependencies are pushed in, not pulled out

### Security Implications of DI

- **Scoped lifetimes matter**: A singleton database connection shared across all requests means one request's transaction can leak into another. Use scoped (per-request) lifetimes for security-sensitive dependencies.
- **Interface-based security**: If your `AuthorizationService` is an interface, you can swap in a more restrictive implementation for high-security contexts without changing application code.
- **Testing**: DI enables injecting fake/stub security services in tests, ensuring business logic is tested in isolation from security infrastructure.

---

## Aspect-Oriented Programming

### The Problem AOP Solves

Cross-cutting concerns — functionality that spans multiple modules — create code duplication and tangling:
- Logging
- Authentication and authorization
- Caching
- Transaction management
- Error handling
- Metrics and tracing
- Input validation
- Rate limiting

Without AOP, every method that needs logging contains logging code. Every method that needs authorization contains authorization code. This violates SRP and makes it easy to miss an enforcement point.

### AOP Concepts

- **Aspect**: A module that encapsulates a cross-cutting concern (e.g., `LoggingAspect`, `AuthorizationAspect`)
- **Join Point**: A point in the program where an aspect can be applied (method call, field access, exception throw)
- **Advice**: The action taken at a join point (before, after, around)
- **Pointcut**: An expression that selects join points (e.g., "all methods in package X", "all methods annotated with `@Secured`")
- **Weaving**: The process of applying aspects to targets. Can happen at compile time, load time, or runtime.

### AOP Implementation Patterns

**Decorator-Based AOP** (Python, TypeScript):
```python
def require_auth(permission):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            check_permission(get_current_user(), permission)
            return func(*args, **kwargs)
        return wrapper
    return decorator

@require_auth("orders:read")
def get_orders():
    ...
```
This is the most common form of AOP in dynamic languages. Each decorator is an aspect.

**Middleware/Pipeline AOP** (Express, Django, ASP.NET):
- Request passes through a pipeline of middleware functions
- Each middleware can inspect, modify, or short-circuit the request
- Order matters: authentication before authorization before rate limiting before business logic

**Proxy-Based AOP** (Spring, .NET):
- The DI container wraps injected objects in dynamic proxies
- Proxies intercept method calls and apply aspects (transactions, logging, caching)
- The application code doesn't know it's being intercepted

### Security Implications

- **Consistent enforcement**: AOP ensures security checks are applied uniformly. A developer can't forget to add authorization to a new endpoint if it's applied via an aspect/middleware.
- **Audit trail**: A logging aspect captures all invocations without developers needing to add logging code.
- **Risk**: Aspect ordering matters for security. If caching runs before authorization, a cached response might bypass an auth check. Define and enforce aspect ordering explicitly.
- **Risk**: Aspects that modify method arguments can introduce injection vulnerabilities if they don't validate their own inputs.

---

## Proxies and Agents

### Proxy Patterns

**Protection Proxy**: Controls access to the real object based on the caller's identity or permissions.
- The proxy checks authorization before delegating to the real object
- Used in: ORM lazy-loading with access control, API gateways, RPC middleware

**Virtual Proxy**: Creates expensive objects on demand (lazy initialization).
- Security consideration: ensure the lazy initialization itself is thread-safe and doesn't create TOCTOU (Time-of-Check-to-Time-of-Use) vulnerabilities.

**Remote Proxy**: Represents an object in a different address space (process, machine).
- gRPC stubs, RMI stubs, REST client wrappers
- Security: all remote communication must be authenticated and encrypted. The proxy should handle TLS, retry, and circuit breaking.

**Caching Proxy**: Caches results of expensive operations.
- Security: cached data must respect authorization. User A's cached data must not be served to User B unless it's genuinely public. Cache keys must include the user's identity or authorization scope.
- Cache poisoning: validate inputs to the cache key to prevent attackers from controlling what gets cached and served to others.

**Logging Proxy**: Records all method invocations for audit purposes.
- Intercepts calls transparently, logs parameters and results, then delegates
- Security: the logged parameters must be scrubbed of sensitive data (passwords, tokens, PII)

### Agent Patterns

**Autonomous Agents**: Software components that operate independently to achieve goals.
- Monitor-Analyze-Plan-Execute (MAPE) loop
- Security: agents that can take actions (call APIs, modify data, execute code) must operate under least privilege. Each agent gets a scoped set of capabilities.

**MCP-Style Tool Integration**: Agents interact with external systems via defined tool interfaces.
- The tool interface defines what the agent can do — the agent cannot exceed its tool set
- Security: tool invocations must be validated, rate-limited, and audited. The agent's tool set is its trust boundary.

**Multi-Agent Systems**: Multiple agents collaborate to solve complex problems.
- Security: inter-agent communication must be authenticated. One compromised agent should not be able to impersonate another or escalate its capabilities.
- Least privilege per agent: the data-gathering agent cannot modify data. The action-taking agent cannot exfiltrate data.

---

## Inversion of Control

### The Hollywood Principle: "Don't call us, we'll call you"

IoC is the broader principle that DI and AOP are specific implementations of. In traditional control flow, your code calls library code. In IoC, the framework calls your code.

### Forms of IoC

**Dependency Injection**: The container constructs and injects dependencies (covered above).

**Event-Driven IoC**: Your code registers event handlers. The framework invokes them when events occur.
- DOM events, message broker consumers, webhook handlers
- Security: event handlers must validate the event payload as untrusted input. The event source may be spoofed.

**Template Method IoC**: A framework defines the algorithm skeleton. Your code fills in specific steps.
- Django views, JUnit test lifecycle, React component lifecycle
- Security: the framework handles the security-critical steps (input parsing, output encoding). Your code handles only business logic.

**Plugin Architecture**: The host application loads and executes plugins at runtime.
- Security: plugins are untrusted code. They must run in sandboxes with limited permissions. Plugin APIs should expose the minimum necessary capabilities.
- Validation: plugins must be verified (signed, hash-checked) before loading.
- Isolation: plugins should not be able to access other plugins' data or the host's internal state.

**Service Provider Interface (SPI)**: Define an interface that third parties implement. The framework discovers and loads implementations at runtime.
- Java SPI, Python entry points, .NET assemblies
- Security: same as plugins — loaded code is untrusted until verified.
