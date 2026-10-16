# Container and Orchestration Threat Modelling — Detailed Reference

Read this when the system is built, shipped, or run as containers. Containers are their own
surface, distinct from cloud: an on-prem cluster, a docker-compose stack on a VM, a CI runner
with the Docker socket mounted, or an AI agent's code-execution sandbox all trigger this
reference even with no cloud provider in scope. Managed platforms (EKS, GKE, AKS, ECS, Fargate,
Cloud Run) need this file **and** `cloud-threats.md` — say which findings are the provider's.

Container threats sit *alongside* STRIPED. Apply STRIPED to the application, then walk the four
layers below as four trust boundaries. Most real incidents cross at least two.

| Layer | Trust boundary | Typical adversary starting point |
|---|---|---|
| **Image** | Build pipeline → artifact | Poisoned base image, malicious dependency, secrets baked into layers |
| **Registry** | Artifact → cluster | Public-registry pull, tag mutability, weak registry auth |
| **Runtime** | Container ↔ host | Compromised application inside the container (RCE, deserialisation, prompt-injected agent) |
| **Orchestrator** | Workload ↔ control plane ↔ other workloads | Leaked kubeconfig / service-account token, over-permissive RBAC, exposed API server |

Finding IDs for this surface use the `C` bucket (`C1`, `C2`…) per `house-style.md` §3.

## Contents

1. Industry Catalogues (ATT&CK Containers, OWASP Docker / Kubernetes Top 10, CIS, PSS, NSA/CISA)
2. Threats by Layer (image, registry, runtime, orchestrator)
3. Diagnostic Questions
4. Mitigations Worth Suggesting
5. Tooling References
6. How to Use This Reference During a Threat Model

---

## 1. Industry Catalogues

### MITRE ATT&CK — Containers platform (Enterprise v19)

Techniques tagged with the Containers platform. Tag findings `[ATT&CK Txxxx]`; ATT&CK v19
regrouped some tactics (e.g. Stealth, Defense Impairment), so cite the technique ID rather than
the tactic name.

| Technique | Where it shows up |
|---|---|
| T1190 Exploit Public-Facing Application | Exposed API server, dashboard, or an app inside a pod |
| T1133 External Remote Services | Kubelet API, Docker daemon on TCP (2375/2376) |
| T1078 Valid Accounts (.001 Default, .003 Local) | Stolen kubeconfig, default SA token, registry creds |
| T1204.003 User Execution: Malicious Image | Developer or CI pulls a backdoored image |
| T1059.013 Command and Scripting Interpreter: Container CLI/API | `kubectl` / Docker API driven execution |
| T1609 Container Administration Command | `kubectl exec`, `docker exec` with stolen credentials |
| T1610 Deploy Container | Attacker deploys a privileged pod to escape or mine |
| T1053.007 Scheduled Task/Job: Container Orchestration Job | Malicious CronJob for persistence |
| T1525 Implant Internal Image | Backdoored image pushed to the org's registry |
| T1543.005 Create or Modify System Process: Container Service | Modified container runtime / systemd unit |
| T1136.001 Create Account: Local Account | New service account on the cluster |
| T1098.006 Account Manipulation: Additional Container Cluster Roles | New ClusterRoleBinding for persistence / escalation |
| **T1611 Escape to Host** | Privileged container, host mounts, CAP_SYS_ADMIN, runtime CVEs (runc, containerd) |
| T1068 Exploitation for Privilege Escalation | Kernel / runtime exploit from inside a container |
| T1612 Build Image on Host | Build a clean-looking image on the node to evade registry scanning |
| T1036.005 Masquerading: Match Legitimate Name or Location | Malicious pod named like a system component |
| T1685 Disable or Modify Tools | Kill Falco/Tetragon agent, tamper with audit logging |
| T1070 Indicator Removal | Delete pod logs, ephemeral pods that leave no trace |
| T1552.001 / T1552.007 Unsecured Credentials: Files / Container API | Secrets in env vars or files; SA token readable by any process; Docker/kubelet API |
| T1528 Steal Application Access Token | Cloud IMDS via node identity (see `cloud-threats.md`), K8s SA tokens |
| T1110 Brute Force (.001/.003/.004) | Registry or dashboard logins |
| T1613 Container and Resource Discovery | Enumerating pods, services, secrets from inside a pod |
| T1046 Network Service Discovery / T1069 Permission Groups Discovery | Flat pod network; RBAC enumeration |
| T1550.001 Use Alternate Authentication Material: Application Access Token | Pod-to-pod lateral movement with a stolen SA token |
| T1496.001 Resource Hijacking: Compute | Cryptomining in compromised pods |
| T1485 Data Destruction / T1490 Inhibit System Recovery / T1499 Endpoint DoS | Deleting deployments, PVCs, backups; resource exhaustion |
| T1195 Supply Chain Compromise (not platform-tagged, still applies) | Poisoned base image or build dependency |

### OWASP Docker Top 10 (D01–D10)

| ID | Title | Note |
|---|---|---|
| D01 | Secure User Mapping | Run as non-root (`USER`), user namespaces |
| D02 | Patch Management Strategy | Base image and host kernel patching cadence |
| D03 | Network Segmentation and Firewalling | Never expose the Docker daemon; separate networks |
| D04 | Secure Defaults and Hardening | Drop capabilities, read-only rootfs, no-new-privileges |
| D05 | Maintain Security Contexts | Do not mix trust levels on one host |
| D06 | Protect Secrets | No secrets in images, env vars, or build args |
| D07 | Resource Protection | CPU/memory/PID limits |
| D08 | Container Image Integrity and Origin | Signing, digest pinning, trusted registries |
| D09 | Follow Immutable Paradigm | Read-only filesystem, no runtime patching |
| D10 | Logging | Container and daemon logs shipped off-host |

### OWASP Kubernetes Top 10 (K01–K10)

| ID | Title | Note |
|---|---|---|
| K01 | Insecure Workload Configurations | privileged, hostPID/hostNetwork, root, writable rootfs |
| K02 | Supply Chain Vulnerabilities | Untrusted images, no SBOM, no signature verification |
| K03 | Overly Permissive RBAC | cluster-admin bindings, wildcard verbs, `list secrets` cluster-wide |
| K04 | Lack of Centralized Policy Enforcement | No admission control (Kyverno / Gatekeeper / PSA) |
| K05 | Inadequate Logging and Monitoring | API audit log off, no runtime detection |
| K06 | Broken Authentication Mechanisms | Static tokens, anonymous auth, long-lived kubeconfigs |
| K07 | Missing Network Segmentation Controls | No NetworkPolicy — default allow-all pod network |
| K08 | Secrets Management Failures | Secrets unencrypted in etcd, mounted broadly, in ConfigMaps |
| K09 | Misconfigured Cluster Components | Exposed kubelet / etcd / API server, insecure flags |
| K10 | Outdated and Vulnerable Kubernetes Components | Unpatched control plane, runtime, CNI, operators |

### CIS Benchmarks

- **CIS Docker Benchmark** — host configuration, daemon configuration, daemon files, images and
  build files, runtime, operations.
- **CIS Kubernetes Benchmark** — control plane components (1.x), etcd (2.x), control plane
  configuration (3.x), worker nodes (4.x), policies (5.x: RBAC, PSS, network, secrets).
- Managed variants: CIS EKS / GKE / AKS Benchmarks — control-plane sections largely become the
  provider's responsibility.

Cite as `[CIS-K8s 5.2.1]`. Use kube-bench / docker-bench-security output as evidence where the
user has it.

### Pod Security Standards (PSS) and Pod Security Admission (PSA)

Three levels: **Privileged** (unrestricted) · **Baseline** (blocks known privilege escalations:
host namespaces, privileged, most capabilities, hostPath) · **Restricted** (Baseline plus
non-root, drop ALL capabilities, seccomp RuntimeDefault, no privilege escalation, restricted
volume types). Every namespace should declare a PSA level; treat an unlabelled namespace as
Privileged. Restricted is the deterministic control for most K01 findings. Tag `[PSS Restricted]`.

### NSA / CISA Kubernetes Hardening Guide

Pod security, network separation, authentication and authorisation, audit logging, upgrades.
Use as the "what good looks like" reference in the mitigation column.

### Other references worth knowing
- **Kubernetes Threat Matrix (Microsoft)** — predecessor to ATT&CK Containers; useful k8s-specific examples
- **CNCF Cloud Native Security Whitepaper** — lifecycle framing: Develop / Distribute / Deploy / Runtime
- **SLSA** — build provenance levels; applies directly to image builds
- **Sigstore / cosign / SBOM (SPDX, CycloneDX)** — supply-chain evidence an admission controller can verify deterministically

---

## 2. Threats by Layer

### Image (build)
- Unpinned or mutable base image (`latest`, tag not digest) — `[D08]` `[K02]` `[ATT&CK T1195]`
- Base image from an untrusted or unmaintained publisher; no provenance — `[D08]` `[SLSA]`
- Secrets in layers, build args, or a copied `.env`; visible via `docker history` — `[D06]` `[T1552.001]`
- Runs as root; no `USER` directive — `[D01]` `[K01]`
- Package manager, shell, compilers left in the runtime image (attack tooling for free) — `[D04]`
- No SBOM; no scan gate; scan results non-blocking — `[K02]` `[D02]`
- Build executes untrusted code (PR-triggered CI builds, `curl | sh` in Dockerfile) — `[T1195]`
- Poisoned build cache or compromised builder — `[T1612]`

### Registry (distribution)
- Tag mutability: same tag re-pushed with different content — `[D08]`
- CI registry credentials with push rights everywhere — `[K03]`-equivalent for the registry
- Pull-through of public images with no allowlist — `[K02]` `[T1204.003]`
- Signatures exist but nothing verifies them at admission — `[K04]`
- Registry exposed without auth; anonymous pull of internal images — `[K06]`
- Namespace / organisation confusion (typosquatted org on Docker Hub; the model-registry
  equivalent is in `ai-ml-threats.md`) — `[T1195]` `[T1525]`

### Runtime (container ↔ host)
- `privileged: true`; hostPID / hostNetwork / hostIPC — `[K01]` `[T1611]`
- hostPath mounts, especially `/`, `/var/run/docker.sock`, `/proc`, `/sys` — `[T1611]`
- Dangerous capabilities (CAP_SYS_ADMIN, CAP_NET_ADMIN, CAP_SYS_PTRACE, CAP_DAC_OVERRIDE) — `[D04]`
- `allowPrivilegeEscalation: true`; setuid binaries in the image — `[PSS Restricted]`
- No seccomp / AppArmor / SELinux profile — `[CIS-K8s 5.7]`
- Writable root filesystem — `[D09]`
- No resource limits (node DoS, noisy neighbour) — `[D07]` `[T1496.001]` `[T1499]`
- Shared kernel: multi-tenant or untrusted-code workloads on plain runc — needs gVisor / Kata / Firecracker
- Runtime CVEs (runc, containerd, kernel) with no patch cadence — `[K10]` `[D02]` `[T1068]`
- Docker daemon on TCP — `[D03]` `[T1133]`
- **AI agent / code-interpreter sandboxes**: the workload is attacker-controlled by design.
  Require no network egress by default, no host mounts, ephemeral lifetime, Restricted PSS,
  resource limits, and a sandboxed runtime where the tenant boundary matters. Cross-reference
  `ai-ml-threats.md` §10 and ATLAS `AML.T0105 Escape to Host` (`ai-ml-atlas.md`).

### Orchestrator (control plane, identity, network)
- API server / dashboard / kubelet / etcd reachable from untrusted networks — `[K09]` `[T1190]` `[T1133]`
- Anonymous auth; static token file; long-lived kubeconfigs on laptops — `[K06]` `[T1078]`
- Default service account auto-mounted into every pod (`automountServiceAccountToken`) — `[K03]` `[T1552.007]`
- RBAC: cluster-admin to humans/CI; wildcard verbs/resources; `create pods` (= escalation via a
  privileged pod); `get secrets` cluster-wide; `impersonate`, `escalate`, `bind` — `[K03]` `[T1098.006]`
- Node identity reachable from pods via cloud IMDS — `[T1528]` (link to `cloud-threats.md`)
- No NetworkPolicy: flat pod network, open egress — `[K07]` `[T1046]` `[T1550.001]`
- No admission control: anything that authenticates can deploy anything — `[K04]` `[T1610]`
- Secrets unencrypted in etcd; secrets in ConfigMaps; Helm values with secrets committed — `[K08]`
- Operators / controllers with cluster-wide RBAC installed from an unread chart — `[K02]` `[K03]`
- Helm from an untrusted repo; chart hooks running arbitrary Jobs — `[K02]` `[T1053.007]`
- Audit logging off or not shipped; no runtime detection — `[K05]` `[T1685]` `[T1070]`
- Unpatched control plane / CNI / ingress controller — `[K10]`
- Ingress controller misconfiguration (snippet annotations, path confusion) — `[K09]`
- Service mesh: mTLS permissive mode, sidecar-injection bypass, over-trusted mesh control plane — `[K07]`
- Multi-tenancy by namespace alone (no real isolation) — `[K01]` `[K07]`
- Backups deletable by the same principal that can delete the workload — `[T1490]` (see also cloud Recovery suit)

---

## 3. Diagnostic Questions

### Image and supply chain
- Are base images pinned by digest and pulled from an allowlisted registry?
- Who can push to the registry, and are pushed images signed and verified at admission?
- Is there an SBOM per image, and does a scan finding block promotion?
- Does the Dockerfile run as non-root, and is the final stage minimal (distroless / scratch)?
- Can `docker history` or layer inspection reveal a secret?

### Runtime
- Which PSA level does each namespace enforce? Any namespace at Privileged?
- Which workloads are privileged, use host namespaces, or mount hostPath — and why?
- Is there a seccomp/AppArmor profile? Read-only rootfs? Dropped capabilities?
- Which workloads execute untrusted input (user uploads, AI-generated code, PR builds)? What isolation boundary contains them?
- Is the Docker socket mounted anywhere (CI runners are the usual offender)?

### Orchestrator
- Is the API server reachable from the internet or from pods that don't need it?
- How do humans and CI authenticate — OIDC with short-lived tokens, or kubeconfigs?
- Which principals can `create pods`, `exec`, `get secrets`, `bind`, `escalate`, or `impersonate`?
- Is the default SA token auto-mounted? Which pods actually need a token?
- Is there a default-deny NetworkPolicy per namespace, egress included?
- Is there an admission controller, and what does it enforce (signatures, PSS, digest pinning, limits)?
- Are secrets encrypted at rest in etcd, and is an external secrets manager used?
- Is API audit logging on and shipped off-cluster? Is there runtime detection (Falco / Tetragon)?
- For managed clusters: which of the above are the provider's, and have you verified the provider's defaults rather than assumed them?

---

## 4. Mitigations Worth Suggesting

Deterministic, design-time controls first (these satisfy the Cox-thesis test in
`ai-ml-threats.md` §1.3 when AI workloads are involved):

- **Admission control** (Kyverno / OPA Gatekeeper / PSA): enforce Restricted PSS, signature
  verification, digest pinning, resource limits, no default SA token — the single control that
  converts most K01/K02/K04 findings from "policy" to "enforced"
- **Default-deny NetworkPolicy** per namespace, egress included; explicit allow lists
- **RBAC least privilege**: no wildcard verbs; separate human, CI and workload identities;
  short-lived OIDC tokens; `automountServiceAccountToken: false` by default
- **Image supply chain**: distroless/minimal base, digest pinning, private allowlisted registry,
  Sigstore signing + verification, SBOM generation, scan gate in CI, SLSA-style provenance
- **Runtime hardening**: non-root, read-only rootfs, drop ALL capabilities, seccomp
  RuntimeDefault, no host namespaces or mounts, resource limits
- **Isolation tier for untrusted code**: gVisor / Kata / Firecracker, or a tainted dedicated node
  pool, for anything that runs attacker-influenced code — including AI agent sandboxes
- **Secrets**: external secrets manager (Vault / KMS-backed), etcd encryption at rest; never in
  images, env vars, or ConfigMaps
- **Detection**: API audit logs shipped off-cluster; runtime detection (Falco / Tetragon); alert
  on privileged-pod creation, `exec` into pods, and new ClusterRoleBindings
- **Patch cadence** for base images, nodes, runtime, control plane, and operators
- **Backup isolation**: separate principal and account for backups (cross-ref cloud Recovery suit)

---

## 5. Tooling References

| Area | Tools |
|---|---|
| Image scanning / SBOM | Trivy, Grype, Syft, Docker Scout |
| Signing / provenance | cosign (Sigstore), Notation, in-toto, SLSA |
| Config / benchmark | kube-bench, docker-bench-security, Kubescape, Checkov, KICS, Polaris |
| Admission / policy | Kyverno, OPA Gatekeeper, Pod Security Admission |
| RBAC analysis | rbac-tool, kubectl-who-can, KubiScan |
| Runtime detection | Falco, Tetragon |
| Attack simulation | kube-hunter, Peirates, kdigger |
| Sandboxed runtimes | gVisor, Kata Containers, Firecracker |

---

## 6. How to Use This Reference During a Threat Model

1. Identify which of the four layers are in scope and draw each as a trust boundary on the DFD.
   For managed control planes, draw the provider boundary explicitly and state shared responsibility.
2. For each layer, walk the §2 threats and §3 questions; tag findings with ATT&CK Containers,
   OWASP D/K, CIS, or PSS identifiers, and use `C`-bucket finding IDs.
3. Identify every workload that runs untrusted input and name the isolation boundary that
   contains it. "The application validates input" is not a container boundary — flag it.
4. Build the escape path: app compromise → container → node → control plane / cloud identity.
   If no deterministic control breaks the chain, it is a design flaw — Fix Before Implementation.
5. Reconcile with `cloud-threats.md` (node IAM, IMDS, provider-hosted registry) and, when AI
   workloads are present, with `ai-ml-threats.md` / `ai-ml-atlas.md` (agent sandboxes, AML.T0105).
6. Write up under the **Container & Orchestration Threat Surface** block of
   `templates/threat-model-template.md` (§6d).
