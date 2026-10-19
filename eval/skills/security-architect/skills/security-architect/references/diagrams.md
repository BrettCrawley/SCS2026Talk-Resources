<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Brett Crawley -->

# Diagram Generation — Templates and Guidance

## Table of Contents
1. [System Context Diagram](#system-context-diagram)
2. [Container / Component Diagram](#container-component-diagram)
3. [Data Flow Diagram with Trust Zones](#data-flow-diagram)
4. [Sequence Diagram](#sequence-diagram)
5. [Class Diagram](#class-diagram)
6. [Entity-Relationship Diagram](#entity-relationship-diagram)
7. [State Machine Diagram](#state-machine-diagram)
8. [Deployment Diagram](#deployment-diagram)
9. [Diagram Selection Guide](#diagram-selection-guide)

---

## System Context Diagram

Shows the system as a single box with its external actors and systems. C4 Level 1.

Use when: Starting any new design. Establishing scope and external dependencies.

```mermaid
flowchart LR
    subgraph External Actors
        U["👤 End User<br/>(Web Browser)"]
        A["👤 Admin<br/>(Admin Portal)"]
    end

    S["🏢 Our System<br/>Order Management"]

    subgraph External Systems
        PAY["💳 Payment Gateway<br/>(Stripe)"]
        EMAIL["📧 Email Service<br/>(SendGrid)"]
        IDP["🔐 Identity Provider<br/>(Auth0)"]
    end

    U -->|"HTTPS"| S
    A -->|"HTTPS + MFA"| S
    S -->|"REST/TLS"| PAY
    S -->|"SMTP/TLS"| EMAIL
    S <-->|"OIDC"| IDP
```

**Rules**:
- One box for the system under design — don't decompose it yet
- Show all external actors (human and system)
- Label all connections with protocol and security mechanism
- Mark which connections cross the internet vs internal network

---

## Container / Component Diagram

Shows the internal structure of the system. C4 Levels 2-3.

Use when: Decomposing the system into deployable units (containers) or logical components.

```mermaid
flowchart TB
    subgraph Internet["🌐 Internet"]
        U["👤 User"]
    end

    subgraph DMZ["DMZ"]
        GW["API Gateway<br/>(Kong)"]
        CDN["Static Assets<br/>(CloudFront)"]
    end

    subgraph AppTier["Application Tier"]
        AUTH["Auth Service<br/>(Node.js)"]
        ORDER["Order Service<br/>(Python)"]
        NOTIFY["Notification Service<br/>(Python)"]
    end

    subgraph DataTier["Data Tier"]
        DB[("PostgreSQL<br/>(Orders)")]
        CACHE[("Redis<br/>(Sessions)")]
        QUEUE["RabbitMQ<br/>(Events)"]
    end

    U -->|"HTTPS"| GW
    U -->|"HTTPS"| CDN
    GW -->|"gRPC/mTLS"| AUTH
    GW -->|"gRPC/mTLS"| ORDER
    AUTH -->|"TCP/TLS"| CACHE
    ORDER -->|"TCP/TLS"| DB
    ORDER -->|"AMQP/TLS"| QUEUE
    QUEUE -->|"AMQP/TLS"| NOTIFY
```

**Rules**:
- Group by deployment zone / trust boundary
- Label each container with its technology stack
- Show all communication paths with protocol
- Distinguish synchronous (solid lines) from asynchronous (dashed lines) communication

---

## Data Flow Diagram with Trust Zones

Shows how data moves through the system, with explicit trust boundaries.

Use when: Analyzing data flows for threat modeling input. Identifying where data crosses trust boundaries.

```mermaid
flowchart LR
    subgraph Untrusted["🔴 Untrusted Zone"]
        BROWSER["Browser<br/>(User Input)"]
    end

    subgraph DMZ["🟡 DMZ"]
        WAF["WAF"]
        LB["Load Balancer"]
    end

    subgraph Trusted["🟢 Trusted Zone"]
        API["API Server"]
        VALIDATOR["Input Validator"]
        BIZ["Business Logic"]
    end

    subgraph Restricted["🔵 Restricted Zone"]
        DB[("Database<br/>(Encrypted at Rest)")]
        SECRETS["Vault<br/>(Secrets)"]
    end

    BROWSER -->|"1. Raw User Input<br/>(HTTPS)"| WAF
    WAF -->|"2. Filtered Input"| LB
    LB -->|"3. Forwarded Request"| API
    API -->|"4. Raw Payload"| VALIDATOR
    VALIDATOR -->|"5. Validated Data"| BIZ
    BIZ -->|"6. Parameterized Query<br/>(TLS)"| DB
    API -->|"7. Fetch Credentials<br/>(mTLS)"| SECRETS

    style Untrusted fill:#fee,stroke:#c00
    style DMZ fill:#ffe,stroke:#cc0
    style Trusted fill:#efe,stroke:#0c0
    style Restricted fill:#eef,stroke:#00c
```

**Rules**:
- Color-code trust zones (red = untrusted, yellow = semi-trusted, green = trusted, blue = restricted)
- Number the data flows to show sequence
- Label what data moves at each step (not just "request" — "raw user input", "validated order data", "encrypted PII")
- Mark trust boundary crossings explicitly — this is where threats concentrate
- Show where encryption, validation, and authentication occur

---

## Sequence Diagram

Shows the interaction between components over time.

Use when: Detailing auth flows, multi-service interactions, error handling sequences.

```mermaid
sequenceDiagram
    actor User
    participant Browser
    participant Gateway as API Gateway
    participant Auth as Auth Service
    participant API as Order Service
    participant DB as Database

    User->>Browser: Submit Order
    Browser->>Gateway: POST /orders (JWT in header)
    Gateway->>Auth: Validate JWT
    
    alt JWT Valid
        Auth-->>Gateway: 200 OK (claims)
        Gateway->>API: Forward Request + Claims
        API->>API: Authorize (check role)
        API->>DB: INSERT order (parameterized)
        DB-->>API: Order ID
        API-->>Gateway: 201 Created
        Gateway-->>Browser: 201 + Order ID
    else JWT Expired
        Auth-->>Gateway: 401 Unauthorized
        Gateway-->>Browser: 401 (generic error)
        Note over Gateway: Log: auth_failure, ip, timestamp
    else JWT Invalid Signature
        Auth-->>Gateway: 403 Forbidden
        Gateway-->>Browser: 403 (generic error)
        Note over Gateway: Log: potential_attack, ip, timestamp
    end
```

**Rules**:
- Include error paths and security-relevant branches (auth failure, validation failure)
- Show where logging/auditing occurs with Notes
- Use `alt` blocks to show different outcomes
- Never show sensitive data in the diagram (tokens, passwords) — use labels like "JWT" or "credentials"

---

## Class Diagram

Shows class structure, interfaces, and relationships.

Use when: Detailing OO design, showing pattern implementations, documenting interfaces.

```mermaid
classDiagram
    class OrderRepository {
        <<interface>>
        +findById(id: UUID) Order
        +save(order: Order) void
        +delete(id: UUID) void
    }

    class PostgresOrderRepository {
        -connectionPool: DataSource
        +findById(id: UUID) Order
        +save(order: Order) void
        +delete(id: UUID) void
    }

    class OrderService {
        -repo: OrderRepository
        -authz: AuthorizationService
        -events: EventPublisher
        +placeOrder(cmd: PlaceOrderCommand) OrderId
        +cancelOrder(id: UUID, userId: UUID) void
    }

    class AuthorizationService {
        <<interface>>
        +checkPermission(userId: UUID, action: String, resource: String) void
    }

    class PlaceOrderCommand {
        +customerId: UUID
        +items: List~LineItem~
        +validate() void
    }

    OrderRepository <|.. PostgresOrderRepository : implements
    OrderService --> OrderRepository : depends on
    OrderService --> AuthorizationService : depends on
    OrderService --> PlaceOrderCommand : uses
```

**Rules**:
- Show interfaces and their implementations (demonstrates DIP)
- Mark dependencies with direction arrows (who depends on whom)
- Include authorization and security services as explicit dependencies
- Use stereotypes (`<<interface>>`, `<<abstract>>`, `<<entity>>`) for clarity

---

## Entity-Relationship Diagram

Shows data model structure and relationships.

Use when: Designing database schemas, documenting data models.

```mermaid
erDiagram
    USER ||--o{ ORDER : places
    USER {
        uuid id PK
        string email UK "encrypted"
        string password_hash "argon2id"
        string role "enum: user, admin"
        timestamp created_at
        timestamp last_login
    }

    ORDER ||--|{ ORDER_LINE : contains
    ORDER {
        uuid id PK
        uuid user_id FK
        string status "enum: pending, paid, shipped, cancelled"
        decimal total
        timestamp created_at
        timestamp updated_at
    }

    ORDER_LINE }|--|| PRODUCT : references
    ORDER_LINE {
        uuid id PK
        uuid order_id FK
        uuid product_id FK
        int quantity
        decimal unit_price
    }

    PRODUCT {
        uuid id PK
        string name
        decimal price
        int stock_count
        boolean active
    }

    AUDIT_LOG {
        uuid id PK
        uuid user_id FK
        string action
        string resource_type
        uuid resource_id
        jsonb details "scrubbed of PII"
        timestamp created_at
    }
```

**Rules**:
- Annotate sensitive fields with their protection mechanism (encrypted, hashed, scrubbed)
- Include audit tables — they're part of the data model
- Show cardinality explicitly (||, |{, o{)
- Use enums for status fields — document valid values
- Include indexes on fields used in queries and foreign key relationships

### Graph ER Diagram (for Graph Databases)

For graph databases, model as nodes and relationships:

```mermaid
graph LR
    subgraph Nodes
        PKG["📦 Package<br/>name, version, ecosystem"]
        VULN["🔴 Vulnerability<br/>id, severity, cvss"]
        LICENSE["📄 License<br/>spdx_id, type"]
        REPO["🏗️ Repository<br/>url, branch"]
    end

    subgraph Relationships
        PKG -->|"DEPENDS_ON<br/>{scope, optional}"| PKG
        PKG -->|"HAS_VULNERABILITY"| VULN
        PKG -->|"LICENSED_UNDER"| LICENSE
        PKG -->|"BELONGS_TO"| REPO
    end
```

---

## State Machine Diagram

Shows lifecycle states and transitions.

Use when: Modeling session lifecycle, order status, user account states, workflow states.

```mermaid
stateDiagram-v2
    [*] --> Unauthenticated

    Unauthenticated --> Authenticating : login_attempt
    Authenticating --> Authenticated : credentials_valid
    Authenticating --> Unauthenticated : credentials_invalid
    Authenticating --> MFARequired : credentials_valid + MFA_enabled

    MFARequired --> Authenticated : mfa_valid
    MFARequired --> Locked : mfa_failed_3x

    Authenticated --> Elevated : step_up_auth_success
    Authenticated --> Unauthenticated : logout
    Authenticated --> Unauthenticated : session_timeout

    Elevated --> Authenticated : elevation_timeout (5min)
    Elevated --> Unauthenticated : logout

    Locked --> Unauthenticated : admin_unlock
    Locked --> Unauthenticated : lockout_timeout (30min)

    note right of Locked
        Log: account_locked
        Alert: security_team
    end note

    note right of Elevated
        Required for: password_change,
        payment, admin_actions
    end note
```

**Rules**:
- Include security-relevant states (Locked, Elevated, MFARequired)
- Show timeout transitions (sessions expire, lockouts expire)
- Annotate states with logging/alerting requirements
- Model failure transitions (what happens on authentication failure, exceeded attempts)

---

## Deployment Diagram

Shows infrastructure topology and deployment configuration.

Use when: Documenting how the system is deployed, network topology, infrastructure security.

```mermaid
flowchart TB
    subgraph Cloud["☁️ AWS eu-west-1"]
        subgraph PublicSubnet["Public Subnet"]
            ALB["Application<br/>Load Balancer"]
        end

        subgraph PrivateSubnet["Private Subnet"]
            subgraph ECS["ECS Cluster"]
                SVC1["Order Service<br/>(3 replicas)"]
                SVC2["Auth Service<br/>(2 replicas)"]
            end
        end

        subgraph DataSubnet["Data Subnet (Isolated)"]
            RDS[("RDS PostgreSQL<br/>(Multi-AZ, Encrypted)")]
            REDIS[("ElastiCache Redis<br/>(Encrypted)")]
        end

        subgraph Security["Security Services"]
            WAF["AWS WAF"]
            KMS["AWS KMS"]
            SECRETS["Secrets Manager"]
        end
    end

    INTERNET["🌐 Internet"] -->|"HTTPS"| WAF
    WAF -->|"Filtered"| ALB
    ALB -->|"HTTP (internal)"| SVC1
    ALB -->|"HTTP (internal)"| SVC2
    SVC1 -->|"TLS"| RDS
    SVC2 -->|"TLS"| REDIS
    SVC1 -.->|"Encrypt/Decrypt"| KMS
    SVC1 -.->|"Fetch Secrets"| SECRETS
```

**Rules**:
- Show network segmentation (public, private, isolated subnets)
- Mark encryption at each boundary
- Show replicas and high-availability configuration
- Include security services (WAF, KMS, Secrets Manager) as explicit infrastructure components
- Distinguish data flow (solid lines) from control/management flow (dashed lines)

---

## Diagram Selection Guide

| Question | Diagram Type |
|----------|-------------|
| What is the system and what does it talk to? | System Context |
| What's inside the system? | Container / Component |
| How does data flow and where are the trust boundaries? | Data Flow Diagram |
| What happens step-by-step in this interaction? | Sequence Diagram |
| What does the object model look like? | Class Diagram |
| What does the data model look like? | Entity-Relationship Diagram |
| What states can this entity be in? | State Machine |
| How is it deployed? | Deployment Diagram |

**For Design Mode**: Start with System Context → Container → Data Flow → Sequence (for key flows) → Class (for core domain) → ER (for data model).

**For Review Mode**: Start with whichever diagram reveals the biggest concern. Usually Data Flow (trust boundaries) or Container (coupling).

**For Advisory Mode**: Use the diagram that best answers the specific question. Usually one is enough.
