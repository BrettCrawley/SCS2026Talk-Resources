<!-- SPDX-License-Identifier: Apache-2.0 AND CC-BY-4.0 -->
<!-- Copyright 2026 Brett Crawley -->
<!-- OWASP Cumulus card text in section 2 is by TNG Technology Consulting GmbH, CC BY 4.0 -->

# Cloud Threat Modelling — Detailed Reference

This reference covers threats specific to cloud and DevOps environments. Use it whenever the system under review touches IaaS, PaaS, serverless, managed databases, IAM federation, CI/CD-to-cloud trust, or cloud-resident data stores.

It draws from the established industry catalogues (MITRE ATT&CK Cloud, CSA Top Threats, AWS Well-Architected, OWASP Cloud-Native and Serverless Top 10), the OWASP Cumulus card deck, and the named bodies of work by individual cloud security researchers that the field has converged on.

Cloud threats sit *alongside* STRIPED, not inside it. Apply STRIPED to the application logic, then walk this reference to surface the cloud-control-plane and operations threats that STRIPED alone will not catch.

---

## Contents

1. Industry Catalogues (ATT&CK Cloud, CSA Top Threats, AWS Well-Architected, OWASP Cloud-Native / Serverless Top 10)
2. OWASP Cumulus — Cloud Threat Card Deck (five suits)
3. Named Bodies of Work
4. AWS-Specific Threat Baseline
5. Diagnostic Questions by Category
6. Mitigations Worth Suggesting
7. Tooling References
8. How to Use This Reference During a Threat Model

Container images, registries, runtimes and Kubernetes are covered separately in `container-threats.md`; managed container platforms (EKS/GKE/AKS/ECS/Fargate/Cloud Run) need both files.

---

## 1. Industry Catalogues

### MITRE ATT&CK — Cloud (IaaS / SaaS / Identity Provider)

MITRE ATT&CK® technique identifiers and names in this file are taken from MITRE ATT&CK and are subject to the ATT&CK Terms of Use (https://attack.mitre.org/resources/legal-and-branding/terms-of-use/). For that content only: © 2026 The MITRE Corporation. This work is reproduced and distributed with the permission of The MITRE Corporation.

The closest thing to a canonical adversary taxonomy for cloud. Tactics from Initial Access through Impact, with techniques tagged to specific CSPs where relevant. Reference the technique ID inline in findings (e.g. `[ATT&CK T1078.004]`).

Techniques worth knowing by ID:

| ID | Technique | Why it matters |
|----|-----------|---------------|
| T1078.004 | Valid Accounts: Cloud Accounts | Compromised IAM users, federated identities, service principals |
| T1199 | Trusted Relationship | Cross-account roles, vendor SaaS-to-cloud trust, marketplace integrations |
| T1098.001 | Account Manipulation: Additional Cloud Credentials | Attacker creates new access keys on a compromised principal |
| T1098.003 | Account Manipulation: Additional Cloud Roles | Privilege escalation via role attachment |
| T1526 | Cloud Service Discovery | Recon of available cloud services and APIs |
| T1538 | Cloud Service Dashboard | Console-based recon and lateral movement |
| T1530 | Data from Cloud Storage Object | S3/Blob/GCS bucket exfiltration |
| T1578 | Modify Cloud Compute Infrastructure | Snapshot creation, AMI sharing, instance modification for persistence |
| T1562.008 | Disable or Modify Cloud Logs | CloudTrail/CloudWatch/Defender evasion |
| T1580 | Cloud Infrastructure Discovery | Enumeration of compute, storage, network assets |
| T1496 | Resource Hijacking | Cryptojacking, abuse of compute for attacker workloads |
| T1485 | Data Destruction | Bucket/snapshot/backup deletion (cloud ransomware-style impact) |
| T1486 | Data Encrypted for Impact | KMS-key-tampering ransomware variants |

### CSA Top Threats to Cloud Computing

The CSA Top Threats Working Group produces the headline survey-driven list. The persistent top entries across the last several editions are misconfiguration, IAM weaknesses, insecure interfaces and APIs, lack of cloud security architecture, weak control plane, account hijacking, insider threat, limited cloud usage visibility, and abuse and nefarious use of cloud services. Tag findings inline as `[CSA T-2024-01]` etc. when relevant.

The CSA Top Threats Deep Dive reports are particularly useful because they map real breaches (Capital One, SolarWinds, Snowflake 2024, CrowdStrike 2024, the Microsoft tenant breach 2024) to the threats and to specific Cloud Controls Matrix (CCM) controls. Treat them as worked examples.

### AWS Well-Architected Security Pillar and AWS CIRT material

The in-house AWS view, weighted toward shared responsibility. Useful for asking "does the design respect what AWS protects vs what the customer is on the hook for?" The AWS Customer Incident Response Team (CIRT) public talks are a high-signal source of named attack patterns observed in the wild.

### OWASP Cloud-Native Application Security Top 10

Application-layer framings that complement MITRE: insecure cloud configuration, injection, authentication and authorisation failures, supply chain (CN-NA-04), inadequate logging and monitoring, broken authentication of microservices, and so on. Use this when the conversation is about the workload, not the control plane.

### OWASP Serverless Top 10

Mandatory reading where Lambda/Functions/Cloud Run is in scope. The serverless attack surface differs in important ways: function event injection, broken authentication via direct function invocation, over-privileged function permissions, function event-data injection from non-HTTP triggers (S3, SNS, DynamoDB streams), and abuse of execution flow control through cold-start timing.

---

## 2. OWASP Cumulus — Cloud Threat Card Deck

Card text from OWASP Cumulus by TNG Technology Consulting GmbH (https://github.com/TNG/cumulus), licensed CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Card IDs (CU·…) and walk instructions added; card text unmodified.

OWASP Cumulus is the cloud variant of Adam Shostack's Elevation of Privilege, maintained by TNG Technology Consulting and adopted by OWASP. It classifies cloud threats into five suits, each containing up to twelve cards. Use these as discussion prompts when running a workshop, or as a checklist when reviewing a design solo.

The five suits are: **Access & Secrets** (the trump suit), **Delivery**, **Recovery**, **Monitoring**, and **Resources**.

### Access & Secrets (trump suit)

Threats around credentials, identity, and authorisation in cloud environments.

| Card | Threat | Description |
|------|--------|-------------|
| 2 | Missing access review | We grant permissions to 3rd parties (e.g. CI/CD systems), but do not review them regularly. |
| 3 | Long-living secrets | Our secrets are long-lived and can be reused when they get leaked. |
| 4 | No password policy | We don't enforce strong passwords for cloud access, so brute-forcing is possible. |
| 5 | Access to credentials | We (as developers) have access to technical credentials. |
| 6 | Slow credential rotation | We don't propagate changes in permissions quickly enough throughout the whole system. |
| 7 | Repudiation | We can't trace back whether authenticated users/developers granted themselves additional permissions. |
| 8 | No least privilege | We don't restrict permissions (developers, technical users) to the minimum, allowing for a privilege escalation. |
| 9 | Privilege escalation | Our Identity and Access Management lets authenticated users/developers grant themselves additional permissions. |
| 10 | No MFA | We don't enforce MFA for developer access. |
| J | Secrets in artifacts | Our deployment artifacts contain secrets that can be extracted. |
| Q | Complex IAM | Our Identity and Access Management is too complex. |
| K | Poor secrets management | We don't use an established solution for credential management. |
| A | Secrets in source code | Our source code contains secrets. |

### Delivery

Threats around the build, dependency, and deployment pipeline.

| Card | Threat | Description |
|------|--------|-------------|
| 2 | No SBOM | We don't know the versions of our dependencies or whether they are up to date. |
| 3 | Bundled devDependencies | We include unneeded dependencies when deploying our system (test, build, compile-time dependencies). |
| 4 | Dependency confusion | We don't know the source repository of our dependencies. |
| 5 | Rogue dependencies | We don't know how a new version of a dependency changes our system. |
| 6 | Unattended updates | Our system can be re-deployed by a change in an external dependency. |
| 7 | Missing vulnerability scans | We don't know whether our dependencies introduce security issues. |
| 8 | Outdated dependencies | We use outdated dependencies of our runtime platform (OS, container image, serverless runtime). |
| 9 | Dubious dependencies | We use untrustworthy dependencies (unmaintained, used by too few people, developed by single developers, ...). |
| 10 | Missing network control | We don't limit ingress or egress when running CI pipelines. |
| J | Insufficient SCM | We don't know when someone injects code into our codebase. |
| Q | No source code integrity | We are not certain which code/artifacts we are deploying. |
| K | Silent pipeline runs | We won't notice when a deployment is started from a developer account. |
| A | Silent pipeline changes | We won't notice when someone alters the deploy pipeline. |

### Recovery

Threats around backups, rollback, and disaster recovery.

| Card | Threat | Description |
|------|--------|-------------|
| 3 | No restore | We have backups but do not check regularly whether we can restore them or not. |
| 4 | No infrastructure backups | We have no backups for our infrastructure (IaC and its state). |
| 5 | No backups of data | We have no backups of our application data. |
| 6 | No backups of secrets | We have no backups for our secrets. |
| 7 | No infrastructure rollback | We cannot restore our infrastructure to a previous state. |
| 8 | No application rollback | We cannot restore our application to a previous state. |
| 9 | No system rollback | We cannot restore our complete environment to a previous state. |
| 10 | Unsafe data deletions | We don't create backups before deleting important data. |
| J | No backup redundancy | All our backups can be destroyed at once, due to lack of redundancy. |
| Q | Missing backup integrity | We can't tell whether our backup has been modified. |
| K | Broad delete permissions | We can have the same person deleting resources and their backups. |
| A | No disaster recovery plan | We have no disaster recovery plan. |

### Monitoring

Threats around observability, alerting, and audit.

| Card | Threat | Description |
|------|--------|-------------|
| 4 | Alert fatigue | We receive too many alerts, leading to desensitisation and the risk of missing critical alerts. |
| 5 | Information disclosure | We don't restrict access to the sensitive parts of our logs. |
| 6 | Insufficient traceability | We can't easily identify useful information in logs. |
| 7 | Missing cost alerting | We won't get an alert if an end user generates huge cloud bills for us. |
| 8 | No log integrity | We don't notice if an authenticated attacker/developer deactivates or manipulates our tools for traceability. |
| 9 | No audits for prod access | We don't know if an authenticated attacker/developer accessed the production environment. |
| 10 | Insufficient monitoring | We cannot react to problems in time because our monitoring has blind spots. |
| J | Unclear alerts | We need too long to figure out what an alert means. |
| Q | No incident response plan | We do not know how to react when our monitoring sends alerts. |
| K | Inaccessible logs | We can't access our logs if the production environment goes down. |
| A | Secrets in logs | We write secrets/personal data to our logs. |

### Resources

Threats around capacity, network exposure, and cloud-resource governance.

| Card | Threat | Description |
|------|--------|-------------|
| 4 | Unreachable contacts | We can't get contacted by our cloud provider in case of emergency. |
| 5 | Non-compliance | We don't regularly check compliance with our internal policy for using/configuring cloud resources. |
| 6 | Missing rate limits | We have not configured any rate limits for our services. |
| 7 | Missing resource limits | We have no configured resource limits. |
| 8 | Excessive capabilities | We can deploy applications with excessive capabilities. |
| 9 | Single point of failure | Our whole system can be affected by a single rogue service. |
| 10 | Missing ingress control | We don't control ingress traffic. |
| J | Missing egress control | We don't control egress traffic. |
| Q | Missing env separation | Our production and staging environments are connected, either directly or indirectly (e.g. via CI/CD). |
| K | Public resources | Our cloud resources are publicly exposed without any need. |
| A | No cloud policy | We have no clear policy for using/configuring cloud resources. |

---

## 3. Named Bodies of Work

The cloud security research community has a small number of authors whose work has become canonical reference material. Knowing these names lets you tag findings against established taxonomies rather than reinventing them.

### Spencer Gietzen (Rhino Security Labs)

Author of *AWS IAM Privilege Escalation – Methods and Mitigation*, the seminal paper cataloguing 20-plus named escalation paths. Examples to look for in any AWS environment:

- `iam:CreatePolicyVersion` plus `iam:SetDefaultPolicyVersion` (modify any attached policy)
- `iam:PassRole` plus `lambda:CreateFunction` plus `lambda:InvokeFunction` (assume role indirectly)
- `iam:PassRole` plus `ec2:RunInstances` (launch instance with target role)
- `iam:AttachUserPolicy`, `iam:AttachGroupPolicy`, `iam:AttachRolePolicy`
- `sts:AssumeRole` chaining across accounts
- `iam:UpdateAssumeRolePolicy` (rewrite trust policy on a target role)
- `iam:CreateAccessKey` on another user

Also created **Pacu** (offensive AWS framework) and **CloudGoat** (vulnerable AWS environment for training).

### Nick Frichette (Datadog) and Christophe Tafani-Dereeper (Datadog)

Maintain **hackingthe.cloud**, the most complete open library of AWS, Azure, and GCP offensive techniques, and co-author **Stratus Red Team**, which encodes those TTPs as runnable emulations mapped to MITRE ATT&CK. If you want a checklist of named cloud attacks, this and Pacu are the primary sources.

### Scott Piper (Wiz, formerly Summit Route)

Author of **flaws.cloud** and **flaws2.cloud** (the canonical learn-by-doing AWS attack walk-throughs), **CloudMapper**, and a great deal of the community vocabulary around AWS account perimeters, Organizations boundaries, and credential exposure modes. His "AWS Security Maturity Roadmap" is widely cited.

### Daniel Grzelak (Plerion, ex-Atlassian/Linktree)

Named several patterns now in common use: **shadow admins**, "the most dangerous AWS principals", AWS account ID exposure as a recon primitive, GuardDuty evasion, and the "canary token" approach to detecting credential theft.

### Will Bengtson (HashiCorp, ex-Netflix)

Defined the canonical detection patterns for **IMDS credential theft via SSRF** and out-of-VPC use of temporary credentials, post Capital One. Reference his work when discussing IMDSv2 enforcement and credential context monitoring.

### Andrés Riancho

Documented the original SSRF-to-IMDS attack chain on AWS years before Capital One. Remains the reference for that specific pattern.

### Kinnaird McQuade (Cyera, ex-Salesforce)

Author of **Cloudsplaining**, which classifies IAM permissions into named risk categories: Infrastructure Modification, Resource Exposure, Privilege Escalation, Data Exfiltration, Credentials Exposure. Also **Policy Sentry** (least-privilege IAM policy generation). The Cloudsplaining categories are themselves a useful threat taxonomy.

### Toni de la Fuente (Prowler Cloud)

Maintains **Prowler**, whose 400-plus checks are effectively an enumerated catalogue of cloud misconfigurations across AWS, Azure, GCP, and Kubernetes, with mappings to CIS, NIST, PCI, HIPAA, SOC 2, and MITRE ATT&CK. Treat the check IDs as a threat list when reviewing an existing environment.

### Houston Hopkins and Chris Farris

Publish the **breaches.cloud** tracker. Farris's writing on "ransomware in S3" via KMS key tampering, and on abandoned-resource takeover, is particularly worth knowing.

### Rami McCarthy (Wiz, ex-Cisco)

Writes regularly on AWS attack paths, lateral movement, and the practical limits of guardrails. His incident-response primers complement the detection-engineering view.

### Aidan Steele

Deep AWS internals research. His findings frequently surface previously-unmodelled assumptions: signed URL behaviour, AssumeRole edge cases, regional control-plane quirks, VPC trickery.

### Rich Mogull (FireMon / Securosis / CSA)

Author of the **Cloud Security Maturity Model** and a lot of the foundational shared-responsibility threat framing now embedded in CSA materials.

### General threat modelling authors with strong cloud chapters

- **Adam Shostack** — *Threat Modeling: Designing for Security* and *Threats: What Every Engineer Should Learn from Star Wars*. Also curates the EoP variants catalogue (where Cumulus and Elevation of Autonomy live).
- **Loren Kohnfelder** — *Designing Secure Software*. Cloud trust boundaries treated explicitly.
- **Izar Tarandach and Matt Coles** — *Threat Modeling: A Practical Guide for Development Teams*. Best practical material on threat-modelling pipeline-deployed cloud workloads, and the originators of the "Continuous Threat Modeling" formulation that Cumulus is designed to support.

---

## 4. AWS-Specific Threat Baseline

When the environment is AWS, walk this list as a minimum. Each item maps to one or more of the catalogues above. Adapt the equivalents for Azure (Entra ID, Storage Accounts, Managed Identities, Activity Log) and GCP (IAM, Cloud Storage, Service Accounts, Audit Logs).

1. **IAM privilege-escalation paths** (Gietzen's 20-plus patterns). Run Cloudsplaining or Pacu against the account to enumerate.
2. **AssumeRole chaining and confused-deputy** across accounts and partners. Verify external IDs on every cross-account role.
3. **Resource-policy abuse** on S3, KMS, Lambda, ECR, SNS, SQS, Secrets Manager. Public or wildcard principals are immediate findings.
4. **SSRF to IMDS**, even in 2025 despite IMDSv2. Verify IMDSv2 enforcement at the account level via SCP, not per-instance.
5. **EC2 / ECS / EKS instance- and task-role over-permissioning**. Apply Cloudsplaining categories to every workload role.
6. **Public exposure of S3, EBS snapshots, RDS snapshots, AMIs, ECR repositories**. Check Block Public Access at account level.
7. **Sub-domain takeover via dangling Route 53 records** pointing at deleted ELB, CloudFront, S3, or Elastic Beanstalk endpoints.
8. **Lambda environment-variable secret extraction** and runtime-layer compromise. Move secrets to Secrets Manager or Parameter Store with KMS encryption.
9. **CloudTrail evasion**: disabling, region pivot, S3 destination tampering, organisation-trail gaps. Use organisation trails with log-file validation enabled.
10. **GuardDuty / Detective / Config detection blind spots**. Check region coverage and enabled feature classes.
11. **SCP and permission-boundary misalignment** within Organizations. Test that boundaries and SCPs actually deny what they claim to.
12. **Backup vault, snapshot, and KMS-key cross-account access** for ransomware-style impact. Apply Vault Lock and key resource policies that deny deletion.
13. **CI/CD-to-cloud trust**: GitHub Actions OIDC trust policies, GitLab JWT, Bitbucket Pipelines OIDC. Verify `sub` and `aud` claims are properly scoped.
14. **Marketplace AMI and third-party SaaS cross-account roles** (the "vendor role" supply-chain vector). Audit external access analyser findings.
15. **Console session and federated session theft**, particularly via browser extensions and infostealer malware on developer endpoints.

---

## 5. Diagnostic Questions by Category

### Identity, Access, and Secrets

- Are all human identities federated through SSO with MFA, or are there long-lived IAM users?
- What is the access-key age distribution? Any over 90 days?
- Is there a documented break-glass account, and is its use alarmed?
- Are root accounts (AWS) or Global Administrators (Azure) protected with hardware MFA and monitored?
- Are workload identities short-lived (instance roles, IRSA, workload identity federation, managed identities)?
- Do any principals have wildcard `*` in Action or Resource without justification?
- Is there a Cloudsplaining or Prowler report for the account, and are findings tracked?
- Are secrets in Secrets Manager / Key Vault / Secret Manager rather than in environment variables, parameter files, or source code?
- Are CI/CD systems using OIDC federation rather than long-lived keys?

### Pipeline and Delivery

- Is there a complete SBOM for every deployable artefact?
- Are dependencies pinned and integrity-verified (lock files, hashes, Sigstore)?
- Is there a control preventing dependency confusion (private registry first, scoped packages)?
- Are pipeline runs on protected branches only, with required reviews?
- Is the build environment ephemeral and reproducible?
- Are deployment artefacts signed (Sigstore, Notary, AWS Signer)?
- Are CI runners network-restricted (egress controlled, no general internet access)?
- Is there a control preventing self-hosted runners from being abused?

### Recovery and Resilience

- Are backups stored in a separate trust boundary (different account, different region, different credentials)?
- Are restore drills run on a schedule, with documented results?
- Are backups immutable (S3 Object Lock, Vault Lock, immutability policies)?
- Can the same principal delete both production data and its backups?
- Is IaC state itself backed up, and is its remote-state bucket versioned and locked?
- Is there a disaster recovery plan with RPO and RTO targets agreed with the business?

### Monitoring and Detection

- Are control-plane logs (CloudTrail, Activity Log, Cloud Audit Logs) centralised, organisation-wide, and tamper-resistant?
- Are data-plane logs (S3 access, VPC Flow, Storage Account, Cloud Storage audit) enabled where the data sensitivity warrants it?
- Are detection rules tied to an alert that actually reaches an on-call human, not just a dashboard?
- Are alerts tested? Does anyone know what to do when one fires?
- Is there cost alerting that catches anomalous spend (cryptojacking, abuse of consumer-facing endpoints)?
- Are logs accessible during a production outage (separate account, separate auth)?
- Are PII and secrets stripped from logs before ingest?

### Resources, Network, and Governance

- Are public-facing resources explicitly enumerated and justified?
- Is egress from compute workloads restricted (VPC endpoints, egress firewalls, no IGW where possible)?
- Are environments separated at the account or subscription boundary, not just at the namespace boundary?
- Are SCPs (or Azure Management Group policies, GCP Organisation Policies) used to enforce non-negotiable controls (deny region X, require encryption, prevent CloudTrail tampering)?
- Are resource limits set, and are they low enough to bound a runaway-cost incident?
- Is there a published cloud policy that the team can be held to?

---

## 6. Mitigations Worth Suggesting

Patterns that recur in good cloud security designs:

- **Federated identity with short-lived credentials** for everything: humans (SSO + MFA + session limits), workloads (instance roles, IRSA, workload identity federation), CI/CD (OIDC).
- **Permission boundaries and SCPs** as a non-negotiable layer below role policies.
- **Separation of duties via separate accounts**: one account per environment, one for logging, one for security tooling, one for backups. Not VPCs, not namespaces, not tags.
- **Immutable, redundant, integrity-verified backups** stored under separate credentials.
- **Centralised, tamper-resistant audit logging** (organisation trails, Object Lock destinations, log-file validation).
- **Egress controls** at the workload level (VPC endpoints, egress firewall, no broad NAT). The default of "compute can reach anywhere on the internet" is the wrong default.
- **IaC with policy-as-code gates** (OPA/Rego, Checkov, tfsec, KICS, Conftest) in the pipeline, plus drift detection.
- **Continuous configuration scanning** (Prowler, ScoutSuite, CSPM) with findings tracked, not just generated.
- **Runtime detection** (GuardDuty, Defender for Cloud, Security Command Center) with alerts wired to a real on-call.
- **Chaos and game days** that include security scenarios (a credential leaks, an account is compromised, a region disappears).

---

## 7. Tooling References

| Purpose | Tool |
|---------|------|
| IAM analysis | Cloudsplaining, Policy Sentry, Access Analyser, Repokid |
| Misconfiguration scanning | Prowler, ScoutSuite, CloudSploit, Steampipe |
| Offensive simulation | Pacu, Stratus Red Team, CloudGoat, AWSGoat, IAM Vulnerable |
| Attack-path graphing | CloudMapper, PMapper, Cartography, Awspx |
| IaC scanning | Checkov, tfsec, KICS, Terrascan, Conftest |
| Container and runtime | Trivy, Grype, Falco, Tetragon |
| Secrets scanning | TruffleHog, gitleaks, detect-secrets |
| SBOM and supply chain | Syft, Grype, Sigstore (cosign), in-toto, SLSA, sbom-graph |
| Drift and posture | Driftctl, Steampipe, native CSPM |
| Reference attack libraries | hackingthe.cloud, MITRE ATT&CK Cloud, breaches.cloud |

---

## 8. How to Use This Reference During a Threat Model

1. After mapping the attack surface, identify which cloud services are in scope.
2. Walk MITRE ATT&CK Cloud techniques relevant to those services.
3. Walk the five Cumulus suits as a structured prompt set, looking for cards that apply.
4. For AWS specifically, walk the 15-item baseline.
5. Cross-check findings against the OWASP Cloud-Native Top 10 (and Serverless Top 10 if relevant) to make sure the workload-layer threats are captured as well.
6. Tag each finding inline with the relevant catalogue identifier so the report is reviewable against the source.

A good cloud threat model produces findings that a reviewer can independently verify by looking up the same technique ID, card, or check ID in the reference. If a finding does not map back to one of these catalogues, ask whether it is genuinely novel or whether it has already been named by someone else.
