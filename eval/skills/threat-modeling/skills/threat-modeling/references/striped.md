# STRIPED Threat Analysis — Detailed Reference

This reference expands each STRIPED category with diagnostic questions and language-specific patterns to look for. Work through each category for every significant system element.

---

## S — Spoofing

**Core question**: Can an attacker forge identity and act as a legitimate user, service, or system?

### Diagnostic questions
- How are users authenticated? Is it stateless (JWT) or stateful (session)?
- Are tokens/sessions properly invalidated on logout?
- Is mutual TLS used for service-to-service communication?
- Are API keys transmitted securely (headers, not query strings)?
- Is there protection against credential stuffing or brute force?
- Are OAuth flows validated correctly (state parameter, redirect URI pinning)?
- Is the issuer/audience validated on inbound JWTs?

### Red flags by language
| Language | Pattern to flag |
|----------|----------------|
| Python | `jwt.decode()` without `algorithms=` and without verifying `aud`/`iss` |
| Java | Custom `UserDetails` that ignores `isEnabled()`/`isAccountNonLocked()` |
| JavaScript/TS | Trusting `req.user` set client-side; `localStorage` for auth tokens (XSS risk) |
| All | Comparing secrets with `==` instead of constant-time comparison |

### Mitigations to suggest
- Use well-maintained auth libraries (Passport.js, Spring Security, python-jose)
- Enforce MFA for privileged operations
- Implement account lockout and rate limiting on auth endpoints
- Use `httpOnly` + `Secure` + `SameSite=Strict` cookies for session tokens

---

## T — Tampering

**Core question**: Can an attacker modify data in transit, at rest, or in processing?

### Diagnostic questions
- Is all network communication encrypted (TLS 1.2+ minimum, 1.3 preferred)?
- Are database inputs parameterised (no string concatenation in queries)?
- Is input validated server-side (not just client-side)?
- Are file uploads validated for type, size, and content?
- Are message queues or event streams protected from replay or injection?
- Are configuration files and secrets stored outside the codebase?
- Is data integrity verified (HMACs, checksums) where necessary?

### Red flags by language
| Language | Pattern to flag |
|----------|----------------|
| Python | f-string or `.format()` in SQL queries; `subprocess(shell=True)` with user input |
| Java | `Statement.execute()` with concatenated strings; `Runtime.exec()` with user data |
| JavaScript/TS | Template literals in SQL; `eval()`, `new Function()`, `innerHTML = userInput` |
| All | Deserialising untrusted data (pickle, Java ObjectInputStream, JSON.parse on unvalidated input) |

### Mitigations to suggest
- Use parameterised queries / ORMs exclusively
- Validate and sanitise all inputs server-side
- Use structured serialisation (JSON with schema validation, protobuf) not pickle/Java serialisation for untrusted data
- Sign messages with HMAC where integrity matters

---

## R — Repudiation

**Core question**: Can a user or attacker deny having taken an action?

### Diagnostic questions
- Are security-relevant actions logged (login, logout, failed attempts, privilege changes, data access)?
- Are logs tamper-resistant (append-only storage, remote SIEM)?
- Do logs include sufficient context (user ID, IP, timestamp, action, resource)?
- Are audit logs separate from application logs?
- Is non-repudiation required by compliance (PCI-DSS, HIPAA)? If so, are digital signatures in use?

### Red flags
- No logging around authentication events
- Logs stored only locally and writable by the application process
- Sensitive data in logs (passwords, full card numbers, PII)
- No correlation ID for tracing actions across distributed services

### Mitigations to suggest
- Structured logging with a correlation ID on every request
- Append-only audit log table or write-once log storage (S3 Object Lock, CloudTrail)
- Avoid logging sensitive fields — log references (user ID) not values (password)
- For high-assurance: digital signatures on audit events

---

## I — Information Disclosure

**Core question**: Is sensitive data exposed to parties who shouldn't have it?

### Diagnostic questions
- Are error messages sanitised before reaching the user? (Stack traces, SQL errors, internal paths)
- Is sensitive data encrypted at rest (passwords hashed, PII encrypted)?
- Are API responses filtered to return only what the caller needs?
- Are debug endpoints or admin routes protected from public access?
- Are secrets (API keys, connection strings) kept out of source code and logs?
- Is there Insecure Direct Object Reference (IDOR) — accessing another user's data by changing an ID?
- Are directory listings disabled? Are backup files (.bak, .sql) excluded from web roots?

### Red flags by language
| Language | Pattern to flag |
|----------|----------------|
| Python | `traceback.print_exc()` in response handlers; `print(password)` in logs |
| Java | `e.printStackTrace()` in response; returning full entity objects from REST endpoints |
| JavaScript/TS | `console.log` with request objects; returning full DB models from API routes |
| All | Storing credentials in `.env` committed to git; secrets in query params |

### Mitigations to suggest
- Generic error messages to users; detailed errors to logs only
- Use `bcrypt`/`argon2` for passwords; AES-256 for PII at rest
- Apply the principle of least privilege to API responses (use DTOs/view models)
- Secret management via Vault, AWS Secrets Manager, or environment injection

---

## P — Privacy

**Core question**: Is PII (Personally Identifiable Information) collected, stored, processed, and deleted correctly?

### Diagnostic questions
- Is data minimisation applied — only collecting what's strictly necessary?
- Is there a documented retention policy and automated deletion?
- Is consent obtained before collecting sensitive data (health, location, biometrics)?
- Is PII encrypted in transit and at rest?
- Can users access, correct, and delete their data (GDPR/CCPA requirements)?
- Is PII present in logs, analytics events, or error reports?
- Are third-party analytics/tracking tools receiving PII?
- Is data transferred across borders with appropriate safeguards?

### Red flags
- Logging full user objects including email, name, or address
- Indefinite retention with no deletion mechanism
- Sharing PII with third-party SDKs (analytics, crash reporting) without disclosure
- Storing geolocation, device fingerprints, or browsing history beyond session scope
- No user-facing privacy controls

### Mitigations to suggest
- Pseudonymise or tokenise PII in non-production environments
- Implement soft-delete with scheduled hard-delete jobs
- Scrub PII from logs using a log filter/middleware
- Provide a data subject access request (DSAR) workflow

---

## D — Denial of Service

**Core question**: Can an attacker (or misconfigured client) degrade or destroy availability?

### Diagnostic questions
- Are rate limits applied to all public endpoints?
- Are resource-intensive operations (file processing, ML inference, queries) protected against abuse?
- Is there protection against large payload attacks (body size limits)?
- Are database queries bounded (pagination, LIMIT clauses)?
- Are regex patterns checked for catastrophic backtracking (ReDoS)?
- Are background jobs resilient to poison-pill messages?
- Is there circuit-breaking for downstream dependencies?

### Red flags by language
| Language | Pattern to flag |
|----------|----------------|
| Python | Unbounded `re.match()` on user input; reading entire file into memory; no timeout on HTTP calls |
| Java | Unbounded thread creation; `Thread.sleep()` in request path blocking threads |
| JavaScript/TS | No `maxBodySize` on Express; synchronous `fs.readFileSync()` in request handler; ReDoS-vulnerable regex |
| All | Queries without LIMIT; no connection pool limits |

### Mitigations to suggest
- Rate limiting middleware (express-rate-limit, Bucket4j, slowapi)
- Body size limits and request timeouts at the web server level
- Async processing with queues for expensive operations
- Load testing and chaos engineering for resilience validation

---

## E — Elevation of Privilege

**Core question**: Can an attacker gain more permissions than they are entitled to?

### Diagnostic questions
- Is authorisation checked on every protected route/method (not just authentication)?
- Is access control enforced server-side (never trust client-supplied role claims)?
- Is there horizontal privilege escalation — can user A access user B's resources?
- Is there vertical privilege escalation — can a regular user call admin functions?
- Is the principle of least privilege applied to service accounts and DB users?
- Are admin/internal endpoints protected separately from user-facing ones?
- Is there Mass Assignment — can a user update fields (like `role`, `isAdmin`) they shouldn't?

### Red flags by language
| Language | Pattern to flag |
|----------|----------------|
| Python | `@login_required` without `@permission_required`; using `.update(**request.data)` without field filtering |
| Java | Missing `@PreAuthorize` on service methods; `BeanUtils.copyProperties()` from request to entity |
| JavaScript/TS | Checking `req.user.role` client-side only; `Object.assign(user, req.body)` |
| All | DB user has `DROP TABLE` or `CREATE USER` privileges; service account has admin rights |

### Mitigations to suggest
- Centralise authorisation logic — use a policy engine (Casbin, OPA, Spring Security expressions)
- Explicitly allowlist updatable fields (never blindly bind request body to model)
- Use Row-Level Security in PostgreSQL for multi-tenant data
- Regularly audit IAM roles and service account permissions
