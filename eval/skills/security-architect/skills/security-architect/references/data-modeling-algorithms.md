# Data Structures, Algorithms, and Data Modeling — Deep Reference

## Table of Contents
1. [Graph Algorithms for Security](#graph-algorithms-for-security)
2. [Data Structures for Security Applications](#data-structures-for-security)
3. [Graph Databases and FalkorDB](#graph-databases)
4. [Data Modeling Strategies](#data-modeling)
5. [Visualization and Dashboard Architecture](#visualization-architecture)
6. [Cloud-Native and Distributed Architecture](#cloud-native)
7. [Infrastructure as Code Security](#iac-security)

---

## Graph Algorithms for Security

Graphs are a natural fit for security analysis because systems are graphs — nodes are components, edges are connections, and vulnerabilities propagate along edges.

### Traversal Algorithms

**Breadth-First Search (BFS)**:
- Security use: blast radius analysis — starting from a compromised component, BFS finds all components reachable within N hops
- Use for: finding shortest attack paths, enumerating all affected dependencies

**Depth-First Search (DFS)**:
- Security use: dependency chain analysis — following a dependency chain to its root
- Use for: cycle detection in dependency graphs (cyclic dependencies create circular trust)

### Shortest Path Algorithms

**Dijkstra's Algorithm**:
- Security use: finding the path of least resistance for an attacker — model edge weights as exploit difficulty or privilege required
- Use for: attack graph analysis, identifying the easiest path from external access to sensitive data

**A* Algorithm**:
- Security use: guided search in large attack graphs using heuristics (estimated remaining exploit cost)
- More efficient than Dijkstra when a good heuristic is available

### Centrality Algorithms

**Betweenness Centrality**:
- Security use: identifies components that are critical chokepoints — if compromised, they affect the most communication paths
- High betweenness centrality = high-value target for attackers and high-priority for defenders
- In dependency graphs: a library with high betweenness centrality is a supply chain risk

**PageRank / Eigenvector Centrality**:
- Security use: identifies components whose compromise would cascade most broadly
- A component is important if it's depended on by other important components (recursive definition)

**Degree Centrality**:
- In-degree: components with many dependents (widely used libraries)
- Out-degree: components with many dependencies (high attack surface through supply chain)

### Community Detection

**Louvain Algorithm / Label Propagation**:
- Security use: identify clusters of tightly-coupled components that should share a trust boundary
- Components in the same community likely share the same security context
- Use for: automated trust boundary discovery in microservice architectures

### Cycle Detection

**Topological Sort** (fails on cycles):
- Security use: dependency graphs should be a DAG (Directed Acyclic Graph). Cycles indicate circular dependencies that make security updates difficult
- In SBOM analysis: cyclic dependencies can mean updating one package forces updating another, which forces updating the first (deadlock)

**Tarjan's Algorithm / Kosaraju's Algorithm** (Strongly Connected Components):
- Security use: find groups of mutually dependent components — these form an update unit (you can't update one without updating all)

### Graph Algorithms in Practice (SBOM Analysis)

Applying these to Software Bill of Materials (SBOM) graphs:

| Algorithm | SBOM Application |
|-----------|-----------------|
| BFS from vulnerable node | Blast radius: what depends (transitively) on this vulnerable library? |
| Betweenness centrality | Which libraries, if compromised, affect the most dependency paths? |
| PageRank | Which libraries are most critical based on recursive importance? |
| Cycle detection | Where are circular dependencies that complicate updates? |
| Community detection | Which groups of libraries form natural update units? |
| Shortest path | What is the minimum number of updates needed to patch a vulnerability? |
| Diamond dependency detection | Where do multiple versions of the same library coexist due to upstream pinning? |

---

## Data Structures for Security

### Bloom Filters
- **What**: Probabilistic set membership test. Can say "definitely not in set" or "probably in set."
- **Security use**: Rate limiting (has this IP exceeded its quota?), deduplication (have we seen this request ID?), checking against deny lists.
- **Trade-off**: False positives possible, false negatives impossible. Size and false positive rate are tunable.

### Merkle Trees
- **What**: Binary tree of hashes. Leaf nodes are hashes of data blocks. Internal nodes are hashes of their children.
- **Security use**: Data integrity verification (blockchain, Git, SBOM integrity), efficient tamper detection, proof of inclusion.
- **Architecture use**: Verify that a large dataset hasn't been tampered with by checking only the root hash.

### Hash Tables / Hash Maps
- **Security use**: O(1) lookup for session stores, token validation, IP allowlists/denylists.
- **Security risk**: Hash collision attacks (HashDoS). Use cryptographically strong hash functions for security-critical hash tables, or use randomized hashing (SipHash).

### Tries (Prefix Trees)
- **Security use**: Efficient IP address matching for firewalls and geoblocking. CIDR range matching. URL path matching for routing and access control.
- **Variant**: Radix trees (compressed tries) for memory-efficient IP lookup.

### Skip Lists
- **What**: Layered linked list providing O(log n) search, insert, and delete.
- **Security use**: Ordered access control lists with efficient lookup. Used in some database engines (Redis sorted sets).

### Append-Only Logs (Immutable Data Structures)
- **What**: Data structure that only supports append operations. Previous entries cannot be modified.
- **Security use**: Audit logs, event sourcing stores, certificate transparency logs.
- **Architecture**: Use write-once storage (S3 Object Lock, WORM media) to enforce immutability at the infrastructure level.

---

## Graph Databases

### When to Use Graph Databases

Use a graph database when:
- Relationships between entities are as important as the entities themselves
- Queries involve variable-length paths (friends-of-friends, dependency chains, attack paths)
- Schema is highly connected and evolving
- Queries like "find all paths from A to B" or "what is A's shortest path to B through C" are common

Don't use when:
- Data is tabular with simple joins
- Aggregate queries (SUM, COUNT, AVG) are the primary workload
- Data volume is very large but sparsely connected

### Property Graph Model

- **Nodes**: Entities with labels and properties (e.g., `(:Package {name: "lodash", version: "4.17.21"})`)
- **Edges**: Relationships with types and properties (e.g., `-[:DEPENDS_ON {scope: "runtime"}]->`)
- **Properties**: Key-value pairs on both nodes and edges

### Cypher Query Language (Neo4j, FalkorDB)

Common patterns for security analysis:

```cypher
// Blast radius: all packages affected by a vulnerability
MATCH (v:Vulnerability {id: "CVE-2024-1234"})<-[:HAS_VULN]-(pkg:Package)
      <-[:DEPENDS_ON*]-(affected:Package)
RETURN DISTINCT affected.name, affected.version

// Betweenness centrality (built-in in most graph DBs)
CALL algo.betweenness.stream('Package', 'DEPENDS_ON')
YIELD nodeId, centrality
RETURN algo.getNodeById(nodeId).name, centrality
ORDER BY centrality DESC LIMIT 10

// Diamond dependency: multiple versions of the same package
MATCH (a:Package)-[:DEPENDS_ON*]->(p1:Package {name: $name}),
      (a)-[:DEPENDS_ON*]->(p2:Package {name: $name})
WHERE p1.version <> p2.version
RETURN a.name, p1.version, p2.version

// Cycle detection
MATCH path = (p:Package)-[:DEPENDS_ON*]->(p)
RETURN [n IN nodes(path) | n.name] AS cycle
```

### FalkorDB Specifics

FalkorDB is an in-memory graph database built on Redis:
- Very fast for traversal queries
- Supports Cypher query language
- Runs as a Redis module — can be deployed alongside existing Redis infrastructure
- Graph algorithms available as built-in procedures
- Suitable for SBOM analysis, dependency graphs, network topology graphs
- Limitation: entire graph must fit in memory. Not suitable for extremely large graphs (billions of edges)

### Polyglot Persistence

Often the right answer is multiple databases, each optimized for its workload:

| Workload | Database Type | Example |
|----------|--------------|---------|
| Transactional business data | Relational (PostgreSQL) | Orders, users, payments |
| Dependency/relationship analysis | Graph (FalkorDB, Neo4j) | SBOM graphs, network topology |
| Full-text search | Search engine (Elasticsearch) | Log search, document search |
| Session/cache | Key-value (Redis) | Session store, API cache |
| Document storage | Document (MongoDB) | Configuration, metadata |
| Time-series metrics | Time-series (TimescaleDB, InfluxDB) | Monitoring, audit events |
| Event/audit log | Append-only (Kafka, S3) | Audit trail, event sourcing |

**Security of polyglot persistence**: Each database has its own authentication, authorization, and encryption configuration. Each needs its own backup and recovery strategy. Data consistency across databases requires careful transaction management (saga pattern, outbox pattern).

---

## Data Modeling

### Entity-Relationship Modeling

1. Identify entities (nouns in requirements)
2. Identify relationships (verbs between entities)
3. Identify attributes (properties of entities)
4. Determine cardinality (1:1, 1:N, M:N)
5. Identify keys (natural and surrogate)
6. Normalize to eliminate redundancy (then selectively denormalize for performance)

### Normalization (Quick Reference)

| Normal Form | Rule | Violation Example |
|-------------|------|-------------------|
| 1NF | Atomic values, no repeating groups | `tags: "security,architecture,design"` (should be a separate table) |
| 2NF | No partial dependencies on composite keys | A field that depends on only part of a composite primary key |
| 3NF | No transitive dependencies | `order → customer_id → customer_name` (customer_name depends on customer_id, not on order) |
| BCNF | Every determinant is a candidate key | Rare in practice — 3NF is usually sufficient |

**When to denormalize**: Read-heavy workloads with expensive joins. Denormalization trades write complexity for read performance. Always document what's denormalized and why.

### Graph Modeling

1. Identify nodes (entities that have identity)
2. Identify relationships (how entities connect — name them as verbs)
3. Decide what's a property vs what's a node (if you query on it or connect things through it, make it a node)
4. Model cardinality through relationship patterns (1:N = one node with many outgoing edges)
5. Consider relationship properties (weight, timestamp, type)

**Graph modeling for security**:
- Trust boundaries become subgraphs or node labels
- Data flows become directed edges with labels (protocol, encryption status)
- Access control relationships: `(User)-[:HAS_ROLE]->(Role)-[:GRANTS]->(Permission)-[:ON]->(Resource)`
- Attack graphs: `(Attacker)-[:EXPLOITS {difficulty: 3}]->(Vulnerability)-[:COMPROMISES]->(Component)`

### Document Modeling

- Embed related data when it's always accessed together (order + line items)
- Reference related data when it's accessed independently or shared (user profile referenced by many orders)
- Security consideration: embedded documents inherit the parent's access control. If line items have different sensitivity than the order, reference them separately.

---

## Visualization Architecture

### Dashboard Design Principles

- **Information hierarchy**: Most critical metrics at the top-left (first seen). Secondary details below and to the right.
- **Drill-down pattern**: Overview → Category → Detail. Each level filters the next.
- **Color semantics**: Red = critical/danger, amber = warning, green = healthy. Don't use red and green alone (color blindness). Use shape and position as redundant signals.
- **Real-time vs historical**: Real-time dashboards show current state. Historical dashboards show trends. Don't mix them on the same view without clear labeling.

### Real-Time Data Pipeline Architecture

```
Source → Ingestion (Kafka/Kinesis) → Processing (Flink/Spark) → Storage (TimescaleDB/ClickHouse) → API → Dashboard
```

- **Ingestion**: Event streaming for real-time. Batch loading for historical.
- **Processing**: Stream processing for aggregation, enrichment, anomaly detection.
- **Storage**: Time-series database optimized for insert-heavy, time-range-query workloads.
- **API**: GraphQL or REST with WebSocket for live updates.
- **Dashboard**: Grafana, custom React dashboards, or embedded chart libraries (Recharts, D3, Plotly).

### Security Dashboard Specifics

Key metrics for security dashboards:
- Vulnerability counts by severity over time (trend, not just current)
- Mean time to remediate by severity
- Dependency graph health (centrality risks, cyclic dependencies)
- Authentication anomalies (failed logins, unusual geolocations)
- Data access patterns (spikes, unusual hours, unusual volumes)

---

## Cloud-Native and Distributed Architecture

### Zero Trust Architecture
- No implicit trust based on network location
- Every request is authenticated, authorized, and encrypted
- Microsegmentation: fine-grained network policies between services
- Continuous verification: re-evaluate trust at every access, not just at initial connection

### Container Security
- Minimal base images (distroless, Alpine) to reduce attack surface
- No root user in containers — run as a non-root user with minimal capabilities
- Read-only filesystem where possible
- Image scanning: scan for vulnerabilities before deployment and continuously in registries
- Image signing: verify provenance with Cosign/Notary

### Serverless Security
- Function-level IAM: each function has its own role with minimal permissions
- Cold start timing: timing side-channels can leak information about function initialization
- Dependency risks: all dependencies are bundled with the function and must be scanned
- Ephemeral compute: no persistent state reduces some attack vectors but complicates audit logging

### Service Mesh Security
- Mutual TLS (mTLS) between all services by default
- Traffic policies: define which services can communicate with which
- Observability: distributed tracing across the mesh for security forensics
- Rate limiting and circuit breaking at the mesh level

---

## Infrastructure as Code Security

### Policy-as-Code
- Use tools like OPA (Open Policy Agent), Sentinel, or Checkov to enforce security policies on infrastructure definitions
- Policies run in CI/CD: a Terraform plan that creates an S3 bucket without encryption is blocked before deployment
- Version policies alongside infrastructure code

### Secure Defaults in IaC Templates
- Encryption enabled by default on all storage resources
- Public access blocked by default on all resources
- Logging enabled by default on all services
- Network access restricted by default (deny all, allow specific)
- Use modules/reusable templates with secure defaults so developers don't need to think about security for each resource

### Drift Detection
- Continuously compare deployed infrastructure against the IaC definition
- Unauthorized changes (manual console modifications) are detected and alerted
- Security implication: an attacker who gains console access and modifies security groups would be detected by drift detection

### Supply Chain Security for IaC
- Pin module versions — don't use `latest` or `main`
- Verify module source (official registry, signed commits)
- SBOM for infrastructure: enumerate all modules, providers, and their versions
- Renovate/Dependabot for automated dependency updates on IaC modules
