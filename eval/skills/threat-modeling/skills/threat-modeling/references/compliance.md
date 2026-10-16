# Compliance Framework Mappings Reference

Use this reference to map threat findings to relevant regulatory and industry standards. Apply the frameworks that match the context — don't add all of them by default.

---

## OWASP Top 10 (2021)

Every web/API finding should be tagged with its OWASP category where it applies. This is universally understood and helps developers prioritise.

| ID | Category | Common Threats |
|----|----------|---------------|
| A01 | Broken Access Control | IDOR, missing auth checks, path traversal, CORS misconfiguration |
| A02 | Cryptographic Failures | Plaintext passwords, weak TLS, insecure storage of sensitive data |
| A03 | Injection | SQL injection, command injection, XSS, SSTI, LDAP injection |
| A04 | Insecure Design | Missing rate limiting, insecure architecture decisions, absent security controls |
| A05 | Security Misconfiguration | Default credentials, verbose error messages, unnecessary features enabled |
| A06 | Vulnerable & Outdated Components | Libraries with known CVEs, abandoned dependencies |
| A07 | Identification & Authentication Failures | Brute force, weak passwords, session fixation, insecure tokens |
| A08 | Software & Data Integrity Failures | Insecure deserialization, CI/CD without integrity checks, auto-update without signature |
| A09 | Security Logging & Monitoring Failures | Missing audit logs, no alerting on suspicious events |
| A10 | SSRF | Server-side request forgery, unvalidated URL fetching |

**Usage**: Tag inline as `[OWASP A03]` after the finding title.

---

## HIPAA Security Rule

Apply when the system handles Protected Health Information (PHI) — medical records, diagnoses, treatment history, billing information, or any data that could identify a patient.

| Section | Requirement | Relevant Threats |
|---------|-------------|-----------------|
| §164.308(a)(1) | Risk analysis and management | All high/critical findings — must be formally documented |
| §164.308(a)(3) | Workforce access management | Elevation of privilege, missing RBAC |
| §164.308(a)(5) | Security awareness training | Human-centered security failures |
| §164.312(a)(1) | Access controls (unique user ID, automatic logoff, encryption) | Spoofing, authentication weaknesses, missing session expiry |
| §164.312(a)(2) | Emergency access procedure | DoS without fallback plans |
| §164.312(b) | Audit controls (hardware, software, procedural) | Missing audit logging, log tampering |
| §164.312(c)(1) | Integrity controls (PHI not improperly altered or destroyed) | Tampering, insufficient input validation |
| §164.312(d) | Person or entity authentication | Weak auth, missing MFA for PHI access |
| §164.312(e)(1) | Transmission security (encryption in transit) | Missing TLS, plaintext transmission |

**Usage**: Tag inline as `[HIPAA §164.312(b)]` after the finding title.

### HIPAA Breach Notification Trigger
Any finding involving potential exposure of unsecured PHI (encryption failure, unauthorised access) carries a breach notification obligation under the HIPAA Breach Notification Rule. Flag these explicitly.

---

## GDPR (General Data Protection Regulation)

Apply when the system processes personal data of EU/UK residents, regardless of where the company is based.

| Article | Requirement | Relevant Threats |
|---------|-------------|-----------------|
| Art. 5 | Data minimisation, purpose limitation, accuracy | Over-collection of PII, storing data beyond its purpose |
| Art. 6 | Lawful basis for processing | Processing without consent or legitimate interest |
| Art. 15-17 | Data subject rights (access, rectification, erasure) | No deletion mechanism, no DSAR process |
| Art. 25 | Data protection by design and by default | Privacy Dark Patterns, insecure defaults, no pseudonymisation |
| Art. 28 | Data processor agreements | No DPA with third-party services receiving PII |
| Art. 32 | Technical and organisational measures | Encryption failures, missing access controls, inadequate logging |
| Art. 33 | Breach notification to supervisory authority (72 hours) | Any critical data exposure finding |
| Art. 35 | Data Protection Impact Assessment (DPIA) | High-risk processing (health, biometric, large scale profiling) |
| Art. 44-49 | International transfers | Sending EU data to non-adequate third countries without SCCs |

**Usage**: Tag inline as `[GDPR Art. 32]` after the finding title.

---

## PCI-DSS v4.0

Apply when the system stores, processes, or transmits payment card data (cardholder data environment).

| Requirement | Area | Relevant Threats |
|------------|------|-----------------|
| Req. 2 | Apply secure configurations | Hardcoded credentials, default passwords, unnecessary services |
| Req. 3 | Protect stored cardholder data | PAN stored unencrypted, CVV stored anywhere |
| Req. 4 | Protect data in transit | TLS requirements, no plaintext transmission of card data |
| Req. 6 | Develop secure systems and software | Injection flaws, OWASP Top 10, vulnerable components |
| Req. 7 | Restrict access by business need | IDOR, over-permissioned accounts, missing least privilege |
| Req. 8 | Identify users and authenticate access | Weak passwords, no MFA for admin, shared credentials |
| Req. 10 | Log and monitor all access | Missing audit logs, insufficient retention |
| Req. 11 | Test security regularly | No vulnerability scanning, no penetration testing |

**Usage**: Tag inline as `[PCI-DSS Req. 6]` after the finding title.

---

## SOC 2 Type II (Trust Services Criteria)

Apply for SaaS products and cloud services where customers require assurance about security, availability, confidentiality, and privacy.

| Criteria | Area | Relevant Threats |
|---------|------|-----------------|
| CC6.1 | Logical access controls | Authentication weaknesses, missing access reviews |
| CC6.2 | Authentication and authorisation | Elevation of privilege, broken access control |
| CC6.3 | Role-based access | Over-privileged accounts, no RBAC |
| CC6.6 | Encryption | Data at rest and in transit |
| CC7.1 | System monitoring | Missing logging and alerting |
| CC7.2 | Security event detection | No SIEM, no anomaly detection |
| CC8.1 | Change management | No code review process, deploying without testing |
| A1 | Availability | DoS risks, no redundancy |
| C1 | Confidentiality | Information disclosure, third-party data sharing |
| P1-P8 | Privacy | CCPA/GDPR alignment, data minimisation |

**Usage**: Tag inline as `[SOC 2 CC6.1]` after the finding title.

---

## Compliance Summary Template

Add this section to the threat report whenever compliance frameworks apply:

```
## Compliance Summary

### HIPAA
| Finding | Section | Gap |
|---------|---------|-----|
| Missing audit logging | §164.312(b) | No mechanism to record PHI access |
| Plaintext password comparison | §164.312(d) | Authentication does not meet standard |

### GDPR
| Finding | Article | Gap |
|---------|---------|-----|
| No data deletion mechanism | Art. 17 | Right to erasure cannot be fulfilled |

### OWASP Top 10
| Finding | Category | Risk |
|---------|---------|------|
| SQL injection | A03: Injection | Critical |
| Missing access checks | A01: Broken Access Control | Critical |
```

If no compliance frameworks apply, omit this section with a brief note explaining why (e.g., "This is an internal tooling project with no regulated data.").
