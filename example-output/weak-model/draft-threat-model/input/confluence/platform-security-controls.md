# Platform Security Controls — Standing Reference

*Confluence space: Platform Engineering · Last updated 2025-11-14 by Platform Security · Fictional, for conference demonstration purposes.*

> **Page status:** Approved. This page is the reference for teams writing designs and threat models. Cite it rather than restating controls.

---

## Purpose

Teams repeatedly re-document the same platform controls in design documents. This page is the single reference. If a control is listed here, a design can rely on it without restating the detail.

---

## Network

**Perimeter.** All inbound traffic terminates at the edge. Internal services carry no public ingress route unless explicitly requested and approved.

**Outbound egress control.** All outbound traffic from cluster workloads passes through the egress proxy, which enforces a domain allowlist. Additions are requested through Platform Security and reviewed weekly. This control has been in place since 2023 and covers data exfiltration to unapproved destinations.

**Remote access.** Corporate systems are reachable over the VPN, which requires MFA. Direct access from the public internet is not possible for internal services.

---

## Source control

**Branch protection.** Protected branches across the GitHub organisation require an approving review before merge. Direct pushes to protected branches are rejected. This has been policy since the 2024 secure development standard and applies across the estate.

**Signed commits.** Required on protected branches.

**Secret scanning.** Enabled organisation-wide, push protection on.

---

## Identity

**SSO.** All corporate applications authenticate through the identity provider. MFA is enforced for all users.

**Service identities.** Workload identities are provisioned per service with least privilege. Requests are reviewed by Platform Security.

---

## Secrets

**Storage.** AWS Secrets Manager. Rotation is automated where the downstream system supports it.

**Access.** Workload identity scoped to the specific secrets a service requires.

---

## Logging and audit

**Platform logs.** Retained 90 days hot, 12 months cold.

**Audit trail.** Corporate SaaS systems retain their own audit logs under vendor terms. Platform Security has read access for investigation.

---

## Vulnerability management

**Dependency scanning.** Enabled on all repositories through the shared CI template. Critical findings block the build.

**Container scanning.** Base images scanned on push, rebuilt weekly.

---

## Runtime

**Network segmentation.** Default-deny network policies apply between namespaces. A service can reach only the services it has declared a dependency on.

**Encryption in transit.** TLS is terminated at the edge and re-established internally. Traffic between services and to managed datastores is encrypted in transit.

**Debug and diagnostic endpoints.** Disabled in production builds. Where a service exposes diagnostic routes for development, they are switched off by configuration before promotion.

---

## What this page does not cover

Application-layer controls are the responsibility of the owning team. This page covers platform-provided controls only.

---

## Change log

| Date | Change | By |
|---|---|---|
| 2024-02-19 | Branch protection section added following the secure development standard | Platform Security |
| 2025-03-06 | Egress proxy section expanded | Platform Security |
| 2025-11-14 | Logging retention updated | Platform Security |
