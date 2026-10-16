# Security and Privacy by Design Analysis: SaaS Task Management App
**Date:** 2026-03-30
**Version:** 1.0
**Frameworks:** STRIDE · LINDDUN · OWASP Top 10 · GDPR / Privacy by Design

---

## Executive Summary

This analysis examines a greenfield SaaS task management application (Todoist/Asana clone) handling user authentication, project collaboration, task management, email notifications, and mobile API access. The system processes personally identifiable information (PII) including emails, passwords, and metadata about user behavior/schedules.

**Primary Security Risks:**
1. **Broken Authentication & Session Management** — Password storage vulnerabilities, missing MFA, weak session tokens, cross-site request forgery (CSRF) in web UI
2. **Broken Access Control** — Insufficient authorization checks allowing task/project access across tenants; privilege escalation to admin functions
3. **Sensitive Data Exposure** — Email addresses exposed in API responses, plaintext storage of due dates/tasks in logs, mobile app data interception
4. **API-specific threats** — No rate limiting on login/invitation endpoints; SQL injection on search; insecure deserialization in mobile API

**Primary Privacy Risks:**
1. **Linkability** — User behavior tracking across projects enabling profiling without consent
2. **Identifiability** — Insufficiently anonymized task metadata allowing re-identification from backups/logs
3. **Non-compliance** — Missing data retention policies, no user consent flows for email notifications, insufficient GDPR data subject rights implementation
4. **Unawareness** — No transparency about what data is collected or how it's used

**Top 5 Priorities for Engineering:**
1. Implement role-based access control (RBAC) with least privilege for all tenant-scoped resources
2. Enforce strong password policy, add MFA support, and implement secure session management with JWT rotation
3. Classify all data (PII, sensitive, public); encrypt at rest (AES-256) and in transit (TLS 1.3); audit all data access
4. Design and implement user consent flows for email communications; document lawful basis for all data processing
5. Establish data retention/deletion policies; implement right-to-erasure for user account deletion cascading to all associated data

---

## 1. Assumptions and Context

**Assumptions made due to evaluation context (no clarifying questions available):**

1. **Authentication scope**: Users register with email + password; assume initial single-factor auth (password-based) with plan for MFA in future
2. **Multi-tenancy model**: Each user has isolated projects/tasks; collaboration means granting other users read/write access to specific projects
3. **Mobile API**: REST API serves iOS and Android clients; assume no client-side encryption (data in flight relies on TLS)
4. **Email notifications**: System generates and sends emails via third-party service (e.g., SendGrid, AWS SES); task descriptions/due dates may be included in notification content
5. **Data residency**: All data stored in single AWS region (assume us-east-1); no explicit GDPR compliance mentioned, so infer GDPR applies if any EU users exist
6. **Free tier constraints**: 5-project limit enforced in application logic; no separate billing system mentioned, assume basic subscription model
7. **No third-party integrations** initially; assume no OAuth providers or external APIs consuming task data
8. **Backups and retention**: AWS RDS automated backups enabled; assume 30-day default retention; no explicit backup encryption or deletion policy
9. **Admin access**: Assume backend admins have full database access; no role-based control over admin functions
10. **Development practices**: No mention of code review, secret management, or dependency scanning; assume standard DevOps tooling available

---

## 2. Requirements Classification and Gap Analysis

### Original Requirements (Classified)

| ID | Requirement | Category | Notes |
|----|-------------|----------|-------|
| FR-001 | Users can register with email and password | FR | Authentication entry point |
| FR-002 | Users can log in with email and password | FR | Authentication |
| FR-003 | Users can create, edit, and delete tasks | FR | Core CRUD; needs authorization |
| FR-004 | Users can create projects | FR | Container for tasks |
| FR-005 | Users can invite other users to collaborate | FR | Multi-user access; authorization critical |
| FR-006 | Email notifications for task assignments | FR | Asynchronous; involves 3rd-party service |
| FR-007 | Email notifications for due date reminders | FR | Time-based; asynchronous |
| FR-008 | Mobile app (iOS) connects to REST API | FR | Trust boundary: client-to-server |
| FR-009 | Mobile app (Android) connects to REST API | FR | Trust boundary: client-to-server |
| FR-010 | Free tier: max 5 projects | FR | Business logic; quota enforcement |
| FR-011 | Paid tier: unlimited projects | FR | Subscription model |

### Gap Analysis: Security Gaps Identified

| Gap ID | Gap | Category | Severity | Reason |
|--------|-----|----------|----------|--------|
| SEC-GAP-001 | No authentication mechanism specified (MFA, password policy, session timeout) | SEC | High | Essential for user account security |
| SEC-GAP-002 | No authorization/access control model defined | SEC | Critical | Multi-user access without authorization = data breach |
| SEC-GAP-003 | No encryption specification (in transit, at rest) | SEC | High | PII handling requires encryption |
| SEC-GAP-004 | No input validation or output encoding requirements | SEC | High | SQL injection, XSS attack surface |
| SEC-GAP-005 | No audit logging or non-repudiation controls | SEC | Medium | Cannot investigate security incidents |
| SEC-GAP-006 | No rate limiting or brute force protection | SEC | High | Login/invite endpoints vulnerable to enumeration/DoS |
| SEC-GAP-007 | No error handling or secrets management policy | SEC | High | Sensitive data leak risk in logs/errors |
| SEC-GAP-008 | No CSRF protection specified for web UI | SEC | Medium | Session hijacking risk |
| SEC-GAP-009 | No dependency/supply chain security | SEC | Medium | Vulnerable libraries in production |
| SEC-GAP-010 | No API authentication mechanism (token strategy, refresh tokens) | SEC | High | Mobile API access control undefined |

### Gap Analysis: Privacy Gaps Identified

| Gap ID | Gap | Category | Severity | Reason |
|--------|-----|----------|----------|--------|
| PRV-GAP-001 | No lawful basis defined for data processing | PRV | Critical | GDPR Article 6 compliance required |
| PRV-GAP-002 | No user consent flows (email notifications, data collection) | PRV | High | Consent required for non-essential processing |
| PRV-GAP-003 | No data minimization policy | PRV | High | Unknown what PII is necessary vs. collection sprawl |
| PRV-GAP-004 | No data retention or deletion policy | PRV | High | GDPR Article 17 (erasure) cannot be implemented |
| PRV-GAP-005 | No data subject rights implementation (access, erasure, portability) | PRV | Critical | GDPR Articles 15, 17, 20 requirements |
| PRV-GAP-006 | No privacy notice / transparency requirements | PRV | High | Users unaware of data collection |
| PRV-GAP-007 | No DPIA (Data Protection Impact Assessment) trigger identified | PRV | Medium | Required for high-risk processing |
| PRV-GAP-008 | No breach detection or breach notification procedure | PRV | High | GDPR Article 33/34 compliance unknown |
| PRV-GAP-009 | No third-party data sharing disclosure | PRV | High | Email service provider processing PII; users unaware |
| PRV-GAP-010 | No specification of data categories (what counts as PII) | PRV | High | Cannot implement data subject rights without clarity |

### New Requirements from Gaps

These gaps become [NEW] requirements in Phase 7 (Refined Requirements).

---

## 3. Use Cases

### UC-001: User Registration
**Actor:** Prospective user (unauthenticated)
**Goal:** Create a new account with email and password
**Preconditions:** User has valid email address; account does not already exist
**Main Flow:**
1. User navigates to registration page
2. User enters email and password
3. System validates email format and password strength
4. System checks if email already registered
5. System hashes password (bcrypt/Argon2)
6. System creates user record in database
7. System returns success; may send verification email
**Postconditions:** User account created; user can log in
**Data involved:** Email, password hash, account creation timestamp
**Trust boundary crossings:** Client (browser) ↔ Web server (registration API); Web server ↔ Database

### UC-002: User Login
**Actor:** Registered user
**Goal:** Authenticate and establish a session
**Preconditions:** User account exists; user not already logged in
**Main Flow:**
1. User enters email and password
2. System retrieves user record by email
3. System verifies password hash matches
4. System generates session token (JWT or session ID)
5. System stores/signs token securely
6. System returns token to client
**Postconditions:** User authenticated; session established; token valid for subsequent API calls
**Data involved:** Email, password hash, session token, user ID
**Trust boundary crossings:** Client ↔ Server; Server ↔ Session store (Redis or DB)

### UC-003: Create and Edit Task
**Actor:** Project owner or collaborator with write access
**Goal:** Add or modify a task within a project
**Preconditions:** User authenticated; user has write access to project; project exists
**Main Flow:**
1. User authenticated with valid session
2. User provides task data (title, description, due date, assignee)
3. System verifies user has write access to project (authorization check)
4. System validates input (XSS prevention, length limits)
5. System creates/updates task record; stores in database
6. If assignee specified, enqueue email notification
7. System returns task record to client
**Postconditions:** Task created/updated; notifications queued
**Data involved:** Task title, description, due date, assignee, project_id, user_id, audit trail
**Trust boundary crossings:** Client ↔ API; API ↔ Database; API ↔ Email queue

### UC-004: Invite User to Project
**Actor:** Project owner
**Goal:** Grant another user access to a project
**Preconditions:** Project owner authenticated; target user email known; project exists
**Main Flow:**
1. Owner authenticated; has ownership of project
2. Owner provides email of user to invite
3. System verifies target user exists (or sends signup invitation if not)
4. System creates invitation record with role/permissions
5. System sends email to target user with acceptance link
6. Target user clicks link and accepts (or declines)
7. System grants access if accepted
**Postconditions:** Target user now collaborator on project; has specific permissions
**Data involved:** Project_id, inviter_id, invitee_email, invitee_id, role, permissions, invitation token, acceptance status
**Trust boundary crossings:** Client ↔ API; API ↔ Database; API ↔ Email service

### UC-005: Receive Email Notification for Task Assignment
**Actor:** Task assignee (system perspective: background worker)
**Goal:** Notify user that a task was assigned to them
**Preconditions:** Task created/modified with assignee field; assignee has email on file
**Main Flow:**
1. Task creation/update triggers notification event
2. Background worker dequeues event
3. System retrieves task details and assignee email
4. System renders email template (may include task title, due date, project name)
5. System sends email via SES/SendGrid
6. System logs send attempt
**Postconditions:** Email sent; user receives notification
**Data involved:** Task details, assignee email, project name, possibly due date
**Trust boundary crossings:** API ↔ Message queue; Message queue ↔ Email service provider (external)

### UC-006: Receive Due Date Reminder Email
**Actor:** Task owner/assignee
**Goal:** Receive reminder that task is due soon
**Preconditions:** Task has due date within reminder window (e.g., 1 day); user has email on file
**Main Flow:**
1. Scheduled job runs (e.g., daily cron)
2. System queries tasks with due_date in next 24 hours
3. For each task, retrieves owner/assignee emails
4. System renders reminder email (includes task title, due date, link to task)
5. System sends via email provider
6. System logs send attempt and marks task as "reminder_sent"
**Postconditions:** Reminder email sent; task marked (to prevent duplicate sends)
**Data involved:** Task title, due date, owner/assignee emails, project context
**Trust boundary crossings:** System ↔ Database; Database ↔ Email service provider

### UC-007: Mobile App Calls REST API
**Actor:** Mobile client (iOS or Android)
**Goal:** Fetch or modify tasks via API
**Preconditions:** App installed; user authenticated in app
**Main Flow:**
1. App user logs in (username/password or token stored locally)
2. App sends API request with authentication token (bearer token in Authorization header)
3. Server validates token (signature, expiry, user ID)
4. Server processes request (GET/POST/PUT/DELETE on task resource)
5. Server applies authorization check (user owns task or is collaborator)
6. Server returns JSON response
**Postconditions:** API request processed; response returned to mobile client
**Data involved:** Auth token, task JSON, user ID, project membership
**Trust boundary crossings:** Mobile app (client) ↔ REST API server (untrusted network); Client may store token locally (risk)

### UC-008: Enforce Free Tier Quota (5 Projects Max)
**Actor:** Free tier user
**Goal:** System prevents creation of 6th project
**Preconditions:** User is free tier; has already created 5 projects
**Main Flow:**
1. User (free tier) attempts to create new project
2. System queries user's project count
3. System compares count against limit (5)
4. If count >= 5, system returns error message
5. If count < 5, system creates project
**Postconditions:** Quota enforced; user cannot exceed limit
**Data involved:** User tier (subscription status), project count
**Trust boundary crossings:** API ↔ Database; Client ↔ API

---

## 4. Threat Analysis

### 4.1 Security Threats (STRIDE)

#### ST-001: Weak Password Policy / Brute Force Login
**STRIDE category:** Spoofing / Authentication bypass
**Affected use case(s):** UC-002 (Login)
**Description:** System does not enforce minimum password complexity or length; no rate limiting on login attempts. Attacker can perform dictionary attack or brute force to guess weak passwords.
**Attack vector:** Attacker submits repeated login requests with common passwords (from wordlist); system accepts all attempts without throttling. Eventually successful login gained.
**Likelihood:** High — password brute force is commodity attack; many users choose weak passwords
**Impact:** High — full account compromise; attacker gains access to all user's projects/tasks

#### ST-002: Session Token Theft / Hijacking
**STRIDE category:** Spoofing / Man-in-the-Middle
**Affected use case(s):** UC-002, UC-003, UC-004, UC-007
**Description:** Session tokens (JWT or session IDs) transmitted/stored without adequate protection. If not HTTPS-only, tokens exposed in transit. If stored in browser localStorage (mobile app), accessible to XSS.
**Attack vector:** (1) Network sniffer intercepts HTTP traffic and steals session token; (2) XSS vulnerability in web UI allows JavaScript to steal token from localStorage; (3) Attacker tricks user into visiting malicious site that steals token via CSRF
**Likelihood:** Medium — depends on HTTPS enforcement (assume partial), XSS likelihood (assume present in unvalidated fields)
**Impact:** High — attacker gains temporary session as victim user; can read/modify tasks, invite others, etc.

#### ST-003: SQL Injection in Search / Task Filtering
**STRIDE category:** Tampering / Data modification
**Affected use case(s):** UC-003 (task search/filter)
**Description:** Search endpoint accepts user input (e.g., task title filter) and concatenates directly into SQL query without parameterization. No prepared statements.
**Attack vector:** Attacker submits search query like `title'; DROP TABLE tasks; --` to execute arbitrary SQL. Depending on database permissions, could delete/modify data or exfiltrate all tasks/emails.
**Likelihood:** High — parameterization is well-known best practice, but often missed in rapid development
**Impact:** High — data breach (all task data exfiltrated), data destruction, or denial of service

#### ST-004: Insufficient Authorization Check on Task Access
**STRIDE category:** Elevation of Privilege / Access Control bypass
**Affected use case(s):** UC-003, UC-004, UC-007
**Description:** System does not verify that requesting user owns or is a collaborator on task before returning/modifying it. API endpoint trusts user_id from token but doesn't check project membership.
**Attack vector:** Attacker obtains another user's task_id (from URL or response); calls API endpoint directly with their own token. System returns task data or allows modification because it only checked authentication, not authorization.
**Likelihood:** High — authorization logic often incomplete; developers focus on "is user logged in?" not "is user allowed to see this?"
**Impact:** High — information disclosure (read all tasks/projects of other users); data tampering (modify or delete others' tasks)

#### ST-005: Cross-Site Request Forgery (CSRF) on Web UI
**STRIDE category:** Tampering / Spoofing
**Affected use case(s):** UC-003, UC-004, UC-005
**Description:** Web UI forms (task creation, invitation) lack CSRF tokens. If user logs into task app, then visits attacker-controlled site, attacker can craft form that performs action on behalf of user.
**Attack vector:** Attacker hosts page with hidden form that submits POST to task API (e.g., create project in victim's account, or invite attacker's email). If victim visits page while logged in, browser automatically includes session cookie; form submits successfully.
**Likelihood:** Medium — requires user to be logged in and visit attacker site; mitigation is straightforward (CSRF tokens)
**Impact:** Medium — unauthorized task creation, project deletion, or user invitation; not data exfiltration but account manipulation

#### ST-006: Email Enumeration / User Discovery
**STRIDE category:** Information Disclosure
**Affected use case(s):** UC-001 (Registration), UC-004 (Invite)
**Description:** Registration endpoint returns different responses for "email already exists" vs "email not found". Invitation endpoint returns success even if email doesn't exist. Attacker can enumerate all registered emails.
**Attack vector:** Attacker iterates through common email list (or wordlist) and submits registration/invite requests. Analyzes response codes to determine which emails are registered. Builds list of valid users for targeted attacks.
**Likelihood:** Medium — common implementation oversight
**Impact:** Medium — user enumeration aids social engineering and targeted attacks; not direct data breach but reconnaissance

#### ST-007: Plaintext Storage of Sensitive Data in Logs
**STRIDE category:** Information Disclosure
**Description:** Application logs contain plaintext task descriptions, due dates, user emails, or other PII for debugging. Logs stored in unencrypted files or CloudWatch with insufficient access controls.
**Attack vector:** Attacker gains read access to log files (e.g., via compromised CI/CD system, insecure S3 bucket, or insider access to CloudWatch). Exfiltrates PII and task content from logs.
**Likelihood:** Medium — common practice to log request/response bodies
**Impact:** High — exfiltration of user PII and sensitive task data

#### ST-008: Unencrypted Data at Rest in Database
**STRIDE category:** Information Disclosure
**Description:** PostgreSQL database on AWS RDS stores PII (user emails, task descriptions) without encryption at rest. Assume default RDS configuration (encryption not enabled).
**Attack vector:** Attacker compromises database (via SQL injection, stolen database credentials, or AWS account breach) and reads plaintext user data directly from disk.
**Likelihood:** Medium — requires breach of database layer, but achievable via SQL injection (ST-003) or leaked credentials
**Impact:** High — complete exfiltration of all user data (emails, task content, collaboration graph)

#### ST-009: Insecure Mobile App Data Storage
**STRIDE category:** Information Disclosure
**Description:** Mobile app stores authentication token and cached task data in plaintext in device storage (SharedPreferences on Android, UserDefaults on iOS). No encryption of local cache.
**Attack vector:** Attacker with physical access to unlocked device, or malicious app with storage permissions, reads token and cached data from device memory/filesystem. Uses token to impersonate user.
**Likelihood:** Medium — depends on device security and user behavior; unencrypted app storage is common
**Impact:** High — token theft; account compromise

#### ST-010: No MFA / Single Factor Authentication
**STRIDE category:** Spoofing / Authentication weakness
**Affected use case(s):** UC-002 (Login)
**Description:** System only supports password-based authentication. Single compromised password (via phishing, credential reuse, or brute force) allows attacker full access.
**Attack vector:** Attacker obtains user password (via phishing email, password spray, or credential dump from other breached service). Uses password to log in and access all projects/tasks.
**Likelihood:** High — password reuse/compromise very common; no MFA makes this trivial
**Impact:** High — full account compromise

#### ST-011: Denial of Service via Task Creation / Email Spam
**STRIDE category:** Denial of Service
**Affected use case(s):** UC-003 (Create task), UC-005 (Email notification)
**Description:** No rate limiting on task creation endpoint. Attacker can create thousands of tasks rapidly, or trigger email notifications to spam victim's inbox.
**Attack vector:** Attacker creates bulk tasks (or invites thousands of users, triggering emails) to: (1) overload database with inserts, causing performance degradation or crash; (2) spam notification system, exhausting email service quota; (3) harass target user with email flood.
**Likelihood:** Medium — rate limiting often overlooked in MVP
**Impact:** Medium — service degradation or temporary unavailability; email inbox spam

#### ST-012: Insecure API Token Rotation / Expiry
**STRIDE category:** Spoofing / Session management
**Affected use case(s):** UC-002, UC-007
**Description:** JWT tokens issued with very long expiry (e.g., 1 year) with no refresh token mechanism. Or tokens stored without expiry. Stolen token remains valid indefinitely.
**Attack vector:** Attacker steals token (via XSS, network sniff, or device breach). Token remains valid for extended period, allowing sustained access.
**Likelihood:** Medium — JWT best practices (short expiry + refresh tokens) not always followed
**Impact:** High — prolonged account compromise

#### ST-013: Elevation of Privilege to Admin Functions
**STRIDE category:** Elevation of Privilege
**Affected use case(s):** All authenticated use cases
**Description:** No role-based access control (RBAC) for admin functions. Or admin endpoints check user authentication but not role/permission. Standard user can call admin endpoints (e.g., delete all users, access billing data, override quotas).
**Attack vector:** Attacker (authenticated as normal user) discovers or guesses admin API endpoints. Calls endpoints that modify system configuration, user data, or billing. System processes requests because authentication check passes (but authorization check missing).
**Likelihood:** Medium — common in MVP; authorization often added later
**Impact:** High — full system compromise; attacker becomes effective admin

#### ST-014: No Audit Logging
**STRIDE category:** Repudiation / Non-repudiation
**Affected use case(s):** All authenticated use cases
**Description:** System does not log sensitive actions (login, task creation, user deletion, data export). Or logs exist but lack tamper-evident properties.
**Attack vector:** Attacker performs unauthorized action (data theft, mass deletion). Attacker or compromised admin deletes/modifies audit logs to cover tracks. No forensic trail to detect incident.
**Likelihood:** Medium — audit logging often post-MVP
**Impact:** Medium-High — inability to detect/investigate breaches; compliance violation (GDPR Article 32)

---

### 4.2 Privacy Threats (LINDDUN)

#### PT-001: Linkability — User Behavior Profiling Across Projects
**LINDDUN category:** Linkability
**Affected use case(s):** UC-003, UC-005, UC-006
**Description:** Task data (titles, descriptions, due dates, assignees, timestamps) can be linked to individual users across multiple projects. System collects and stores full activity history without consent for analytics. Metadata reveals user behavior patterns (work habits, project focus, collaboration network).
**Affected personal data:** User ID, project membership, task creation/modification timestamps, task content (inherently sensitive)
**Affected data subjects:** All users; particularly sensitive for users with privacy expectations
**Likelihood:** High — all systems collect behavioral data; often used for analytics without explicit consent
**Impact:** High — user profiling; secondary use of data for behavioral analysis or targeting
**GDPR relevance:** Article 5(1)(b) (purpose limitation) — data collected for task management, not profiling. Article 6 (lawful basis) — consent required if profiling intended. Article 13/14 (transparency) — users must know about profiling.

#### PT-002: Identifiability — Re-identification of Anonymized Task Data
**LINDDUN category:** Identifiability
**Affected use case(s):** UC-003, UC-005
**Description:** Task descriptions contain identifiers (project names, colleague names, client names) that allow re-identification of individual. Backup/export data (nominally anonymized) can be linked back to individuals via metadata.
**Affected personal data:** Task content, project names, user metadata in backups
**Affected data subjects:** Users and third parties mentioned in task descriptions
**Likelihood:** Medium — depends on data minimization and anonymization rigor
**Impact:** High — privacy violation; data supposed to be anonymized is re-identified
**GDPR relevance:** Article 4 (personal data definition); Recital 26 (anonymization requirements). Risk of pseudo-anonymization (appears anonymous but re-identifiable) violates GDPR expectations.

#### PT-003: Non-repudiation — User Unable to Deny Actions
**LINDDUN category:** Non-repudiation
**Affected use case(s):** UC-003, UC-004
**Description:** All user actions logged and timestamped without user consent. User cannot deny they created a task, assigned it, or invited someone. Creates permanent, non-repudiable record.
**Affected personal data:** User actions, timestamps, IP addresses (if logged)
**Affected data subjects:** Users
**Likelihood:** High — standard audit logging creates non-repudiation
**Impact:** Medium — privacy harm (especially in sensitive contexts like medical/legal tasks); limits user autonomy and creates chilling effect
**GDPR relevance:** Article 5(1)(b) (purpose limitation) — audit logging for security, but creates secondary privacy harm. Transparency (Article 13/14) required.

#### PT-004: Detectability — Email Service Provider Can Detect User Activity
**LINDDUN category:** Detectability
**Affected use case(s):** UC-005, UC-006
**Description:** Email notification system sends task data to third-party email service (SendGrid/SES) in plaintext email bodies. Email metadata (to/from, subject, timestamps) reveals that user received task notifications. Email service can infer task assignment patterns, due dates, and activity frequency.
**Affected personal data:** Email addresses, task metadata in email body, notification frequency
**Affected data subjects:** Task users and assignees; email service provider gains metadata about user activity
**Likelihood:** High — emails inherently visible to ESP
**Impact:** Medium — third-party data leakage; activity detection; potential for ESP to profile users
**GDPR relevance:** Article 6 (lawful basis for sharing with ESP); Article 28 (DPA required with processor); Article 32 (security measures to protect in transit).

#### PT-005: Disclosure of Information — Email in API Responses
**LINDDUN category:** Disclosure (Information Disclosure)
**Affected use case(s):** UC-003, UC-004, UC-007
**Description:** API responses include full user email addresses in task data, collaborator lists, or invitation emails. Emails sent in plaintext over HTTPS. If logs not encrypted, emails exposed. If mobile app caches responses, emails stored locally.
**Affected personal data:** Email addresses (PII)
**Affected data subjects:** All users and collaborators
**Likelihood:** High — common to include email in JSON responses
**Impact:** Medium — email enumeration; potential for spam/phishing; email addresses are key identifiers for linking
**GDPR relevance:** Article 5(1)(b) (minimize data in responses); Article 32 (technical measures to protect PII).

#### PT-006: Unawareness — No Privacy Notice or Consent
**LINDDUN category:** Unawareness
**Affected use case(s):** UC-001, UC-005, UC-006
**Description:** Users not informed about what data is collected, how it's used, how long it's retained, or how to exercise rights. No privacy notice presented at signup. No explicit consent for email notifications — emails sent automatically.
**Affected personal data:** All data collected (emails, task content, activity logs, IP addresses)
**Affected data subjects:** All users
**Likelihood:** High — privacy notice/consent typically post-MVP
**Impact:** High — GDPR violation; users cannot make informed decisions about data
**GDPR relevance:** Articles 13 & 14 (transparency requirements); Article 7 (explicit consent when required); Recital 32 (informed consent).

#### PT-007: Unawareness — No Data Subject Rights Implementation
**LINDDUN category:** Unawareness
**Affected use case(s):** UC-002, UC-003, UC-005
**Description:** System has no mechanism for users to exercise GDPR rights. No "Export my data" feature; no "Delete my account" that actually deletes all associated data; no request/rectification process.
**Affected personal data:** All user data
**Affected data subjects:** All users
**Likelihood:** High — rights implementation is non-trivial engineering effort
**Impact:** High — GDPR violation; users cannot exercise legal rights
**GDPR relevance:** Articles 15 (access), 17 (erasure), 20 (portability), 16 (rectification), 18 (restriction), 21 (objection).

#### PT-008: Non-compliance — Data Retention Policy Undefined
**LINDDUN category:** Non-compliance
**Affected use case(s):** All use cases
**Description:** No documented retention policy. Data (tasks, user accounts, logs, backups) retained indefinitely. Users don't know how long their data is kept. Cannot implement "right to erasure" without knowing what to delete.
**Affected personal data:** All user data; audit logs; backups
**Affected data subjects:** All users
**Likelihood:** High — retention policies rare in MVP
**Impact:** High — GDPR violation (Article 5(1)(e) storage limitation); prevents erasure rights implementation
**GDPR relevance:** Article 5(1)(e) (storage limitation); Article 17 (right to erasure dependent on retention policy).

#### PT-009: Non-compliance — No Data Protection Impact Assessment
**LINDDUN category:** Non-compliance
**Affected use case(s):** UC-005, UC-006 (email processing); UC-003 (activity tracking)
**Description:** No DPIA performed to identify privacy risks. System involves high-risk processing (activity profiling, email notifications, bulk data handling) but no formal risk assessment.
**Affected personal data:** All user data; activity logs
**Affected data subjects:** All users
**Likelihood:** High — DPIAs required by GDPR but often neglected
**Impact:** High — GDPR Article 35 violation; risks not formally identified or mitigated
**GDPR relevance:** Article 35 (DPIA required for high-risk processing).

#### PT-010: Non-compliance — No DPA with Email Service Provider
**LINDDUN category:** Non-compliance
**Affected use case(s):** UC-005, UC-006
**Description:** Email service provider (SendGrid/SES) processes task data on behalf of the app, but no Data Processing Agreement (DPA) in place. No contractual guarantees on data security, retention, or sub-processor disclosure. GDPR Article 28 requires DPA.
**Affected personal data:** Task data, email addresses, metadata
**Affected data subjects:** All users
**Likelihood:** High — DPAs often overlooked when using third-party services
**Impact:** High — GDPR Article 28 violation; no contractual protection of user data
**GDPR relevance:** Article 28 (contract requirements for processors).

#### PT-011: Disclosure — Backup Data Not Encrypted / No Retention Policy
**LINDDUN category:** Disclosure
**Affected use case(s):** All use cases
**Description:** AWS RDS automated backups store full database (including PII, task content) without encryption at rest. Backups retained for default 30 days; no policy to delete old backups or customer data from backups.
**Affected personal data:** All user data in backups
**Affected data subjects:** All users
**Likelihood:** Medium — depends on AWS security controls and compliance with regional regulations
**Impact:** High — if backup compromised, all historical user data exposed
**GDPR relevance:** Article 32 (security measures); Article 5(1)(e) (storage limitation) — requires timely deletion from backups.

---

## 5. Abuse Cases

### 5.1 Security Abuse Cases

#### SAC-001: Brute Force Login Attack
**Linked threat:** ST-001
**Attacker type:** External unauthenticated
**Goal:** Gain unauthorized access to user account
**Attack Flow:**
1. Attacker obtains common password list (rockyou.txt, etc.)
2. Attacker identifies target user email (e.g., victim@example.com) via public website or enumeration
3. Attacker writes script to submit login requests with password list
4. System accepts all requests without rate limiting; no CAPTCHA or account lockout
5. After ~10,000 requests, attacker tries a weak password used by victim (e.g., "password123")
6. System authenticates attacker; session token returned
7. Attacker logs in as victim, gains access to all projects/tasks
**Impact if successful:** Full account compromise; attacker reads/modifies all tasks, invites themselves to projects, may delete data
**OWASP Top 10 category:** A07:2021 – Identification and Authentication Failures

#### SAC-002: SQL Injection via Task Search
**Linked threat:** ST-003
**Attacker type:** External authenticated (or unauthenticated if search endpoint unprotected)
**Goal:** Execute arbitrary SQL; exfiltrate or delete data
**Attack Flow:**
1. Attacker observes search API endpoint (e.g., GET /tasks?q=title)
2. Attacker crafts malicious payload: `q='; DROP TABLE tasks; --`
3. Attacker submits request; system concatenates payload into SQL query
4. Query executed: `SELECT * FROM tasks WHERE title LIKE ''; DROP TABLE tasks; --'`
5. Tasks table deleted; application crashes
6. Alternatively, attacker uses `UNION SELECT` to extract user emails and password hashes from users table
**Impact if successful:** Data destruction (all tasks deleted); data exfiltration (all user emails, password hashes); denial of service
**OWASP Top 10 category:** A03:2021 – Injection

#### SAC-003: Unauthorized Task Access via API
**Linked threat:** ST-004
**Attacker type:** External authenticated
**Goal:** Read or modify tasks belonging to other users
**Attack Flow:**
1. Attacker creates legitimate account (email: attacker@example.com)
2. Attacker logs in; receives session token
3. Attacker observes API response structure: tasks include project_id and task_id
4. Attacker guesses or discovers another user's task_id (e.g., by iterating integers or via enumeration)
5. Attacker calls GET /api/tasks/12345 with their own session token
6. System checks: "Is user authenticated?" → Yes. System returns task data without checking project membership.
7. Attacker reads victim's task (including title, description, due date)
8. Attacker calls PUT /api/tasks/12345 to modify task; system allows it
9. Attacker can now alter victim's tasks, delete them, or assign them to themselves
**Impact if successful:** Information disclosure (read all tasks across system); data tampering (modify/delete others' tasks); disruption of collaboration
**OWASP Top 10 category:** A01:2021 – Broken Access Control

#### SAC-004: Cross-Site Request Forgery on Task Creation
**Linked threat:** ST-005
**Attacker type:** External unauthenticated (but requires victim to be logged in)
**Goal:** Perform unauthorized action on victim's account without their knowledge
**Attack Flow:**
1. Victim logs into task app (task-app.com)
2. Victim receives email with link to attacker's site (attacker.com)
3. Victim clicks link (while still logged into task app)
4. Attacker's page contains hidden form: `<form action="https://task-app.com/api/tasks" method="POST"> <input name="title" value="Malicious Task"> <input name="project_id" value="999"> </form>` with JavaScript to auto-submit
5. Form submits; browser automatically includes victim's session cookie with request
6. Task app authenticates request (cookie is valid) and creates task in victim's account
7. Victim doesn't realize malicious task was created
**Impact if successful:** Unauthorized task creation, project deletion, or user invitation in victim's account; creates confusion and potential data manipulation
**OWASP Top 10 category:** A01:2021 – Broken Access Control (CSRF variant)

#### SAC-005: Account Enumeration via Registration Endpoint
**Linked threat:** ST-006
**Attacker type:** External unauthenticated
**Goal:** Discover registered user emails for targeted attacks
**Attack Flow:**
1. Attacker has list of 10,000 potential email addresses
2. Attacker submits registration requests with each email
3. For emails already registered, system returns 409 Conflict or "Email already exists"
4. For new emails, system returns 201 Created or "Account created"
5. Attacker correlates responses; builds list of ~2,000 registered users
6. Attacker uses registered emails for targeted phishing or credential stuffing
**Impact if successful:** User enumeration; reconnaissance for phishing/credential stuffing attacks; targeted harassment
**OWASP Top 10 category:** A01:2021 – Broken Access Control; A07:2021 – Identification and Authentication Failures

#### SAC-006: Plaintext PII Exfiltration from Logs
**Linked threat:** ST-007
**Attacker type:** Insider or system compromise (CI/CD breach, S3 bucket misconfiguration)
**Goal:** Extract user emails, task descriptions, and other PII from application logs
**Attack Flow:**
1. Attacker gains read access to CloudWatch logs or log files in S3 (via misconfigured bucket, leaked credentials, or CI/CD compromise)
2. Logs contain API request/response bodies with full task data: `[2026-03-30 10:15:22] POST /api/tasks {title: "Merger with Acme Inc", description: "Secret negotiation details", assignee: "alice@example.com"}`
3. Attacker queries logs for keywords (e.g., "confidential", "secret", or specific company names)
4. Attacker exfiltrates all matching log entries; gains access to sensitive task content and user emails
**Impact if successful:** Exfiltration of sensitive task content; user email addresses; competitive intelligence (if tasks contain business secrets)
**OWASP Top 10 category:** A09:2021 – Security Logging and Monitoring Failures

#### SAC-007: Database Compromise via SQL Injection → Full Data Breach
**Linked threat:** ST-003, ST-008
**Attacker type:** External authenticated
**Goal:** Compromise database and exfiltrate all user data
**Attack Flow:**
1. Attacker exploits SQL injection (SAC-002) or obtains database credentials (leaked via logs or CI/CD)
2. Attacker connects directly to PostgreSQL database or uses SQL injection to execute privileged queries
3. Attacker executes: `SELECT * FROM users;` → gains all user emails and password hashes
4. Attacker executes: `SELECT * FROM tasks;` → gains all task data (titles, descriptions, due dates)
5. Attacker executes: `SELECT * FROM project_members;` → gains collaboration graph (who works with whom)
6. Attacker exfiltrates database; sells or publishes user data
**Impact if successful:** Complete breach of all user data; compromise of user privacy; regulatory exposure (GDPR fines); reputation damage
**OWASP Top 10 category:** A01:2021 – Broken Access Control; A03:2021 – Injection; A02:2021 – Cryptographic Failures

#### SAC-008: Denial of Service via Bulk Task Creation
**Linked threat:** ST-011
**Attacker type:** External authenticated (or unauthenticated if endpoint unprotected)
**Goal:** Overload system; cause denial of service
**Attack Flow:**
1. Attacker creates account (or hijacks account via SAC-001)
2. Attacker writes script to create tasks in a loop; sends 10,000 requests/minute
3. System has no rate limiting; accepts all requests
4. Database receives 10,000 INSERT operations/minute; I/O utilization spikes to 100%
5. Other users experience slow page loads; eventually system becomes unresponsive
6. Legitimate task creation/access fails for all users; denial of service achieved
**Impact if successful:** Service unavailability; disruption of business-critical task management; potential downtime measured in hours
**OWASP Top 10 category:** A05:2021 – Denial of Service (application-level)

#### SAC-009: Token Reuse After Logout / Long-Lived JWT
**Linked threat:** ST-012
**Attacker type:** External (with stolen token)
**Goal:** Maintain access even after user logs out or changes password
**Attack Flow:**
1. Attacker steals user's JWT token (via XSS, physical access, or network sniff)
2. Token has 1-year expiry; no refresh token mechanism
3. User logs out (or changes password)
4. Attacker can still use stolen token to access user's account for the next 12 months
5. Even if user realizes breach, changing password doesn't invalidate existing tokens
**Impact if successful:** Sustained unauthorized access; difficult for user to recover (password change doesn't help)
**OWASP Top 10 category:** A07:2021 – Identification and Authentication Failures

#### SAC-010: Privilege Escalation to Admin
**Linked threat:** ST-013
**Attacker type:** External authenticated
**Goal:** Gain administrative access and modify system configuration or other users' data
**Attack Flow:**
1. Attacker creates account as regular user
2. Attacker observes or guesses admin API endpoints (e.g., /api/admin/users, /api/admin/settings)
3. Attacker sends request: `GET /api/admin/users` with their regular user session token
4. System checks: "Is user authenticated?" → Yes (token is valid)
5. System does not check: "Is user an admin?" or "Does user have admin role?"
6. System returns list of all users and their data
7. Attacker modifies endpoints to call DELETE /api/admin/users/victim_id to delete other users
8. Or attacker calls POST /api/admin/bypass-quota to create unlimited projects on free tier
**Impact if successful:** Full system compromise; attacker can delete/modify any user's data, override business logic, change system settings
**OWASP Top 10 category:** A01:2021 – Broken Access Control

---

### 5.2 Privacy Abuse Cases

#### PAC-001: Behavior Profiling Without Consent
**Linked threat:** PT-001
**Actor:** System itself (via activity logs used for analytics)
**Scenario:** Task app collects full activity history (task creation, edits, assignments, due date changes, deletions) and uses it to build user behavior profiles. System infers user work patterns (late-night work frequency), project focus areas, collaboration networks, and productivity trends. This data used for "product analytics" or sold to third parties for ad targeting, without explicit user consent.
**Affected data subjects:** All users
**Privacy By Design principle violated:** Principle 1 (proactive not reactive) — profiling should be acknowledged and controlled upfront. Principle 7 (transparency) — users not informed about profiling.
**Regulatory exposure:** GDPR Article 6(1) — no lawful basis for profiling without consent. Article 5(1)(b) — purpose limitation violated (data collected for task management, used for profiling). Article 22 — potential rights regarding automated decision-making if profiling used for decisions. Potential GDPR fine: up to 4% of global annual revenue.

#### PAC-002: Re-identification Attack on "Anonymized" Task Export
**Linked threat:** PT-002
**Actor:** Data analyst or insider performing data export for analytics
**Scenario:** Company exports "anonymized" task dataset for research (removes user IDs and names). Analyst believes data is anonymous. However, task descriptions contain quasi-identifiers (project names like "Acme Inc Merger", colleague names, specific dates/times). External researcher or competitor cross-references exported data with public information (company org chart, news articles) and re-identifies individuals. Learns sensitive information about negotiations, upcoming announcements, or internal conflicts.
**Affected data subjects:** Task creators and assignees; third parties mentioned in task content
**Privacy By Design principle violated:** Principle 1 (proactive not reactive) — anonymization should be rigorously validated upfront. Principle 7 (transparency) — users not informed that "anonymized" data may be re-identifiable.
**Regulatory exposure:** GDPR Article 4 & Recital 26 — pseudo-anonymization (re-identifiable data) treated as personal data. Organization liable for breach even though data labeled "anonymized". Fine for mishandling: up to 4% of revenue. Reputational damage if re-identification becomes public.

#### PAC-003: Non-repudiation Chilling Effect on User Freedom
**Linked threat:** PT-003
**Actor:** System (automatic audit logging without user opt-out)
**Scenario:** User creates a task for sensitive project ("Mental health support for employee John"). Full action logged: timestamp, user ID, task content, IP address. User later realizes they committed sensitive information to permanent, non-repudiable audit log. User feels surveilled; aware that all actions are permanently recorded. User becomes less likely to use app for sensitive content; self-censorship occurs.
**Affected data subjects:** Users
**Privacy By Design principle violated:** Principle 7 (transparency) — users not informed about permanent logging. Principle 5 (end-to-end security) — should include controls over who can access logs.
**Regulatory exposure:** GDPR Article 5(1)(a) — fairness principle violated (user not aware of logging). Article 13 (transparency) — privacy notice must disclose non-repudiation. Potential Article 7 violation if logging wasn't consented to. Risk of user complaints to DPA.

#### PAC-004: Activity Metadata Leakage via Email Service Provider
**Linked threat:** PT-004
**Actor:** Email service provider (SendGrid/SES employee or subpoena)
**Scenario:** User receives email notification: "Task 'Q3 Earnings Report' assigned to you by alice@company.com, due 2026-06-30." Email service provider can see: (1) notification frequency suggests Alice is highly active; (2) task names reveal business information; (3) due dates and assignment patterns show project timeline; (4) collaboration graph (who assigns to whom) visible in email metadata. SendGrid employee or law enforcement with subpoena can access this metadata and infer user activities without user knowledge.
**Affected data subjects:** All users; collaborators
**Privacy By Design principle violated:** Principle 4 (full functionality) — system could minimize email content to reduce metadata leakage. Principle 5 (end-to-end security) — metadata not protected by email encryption.
**Regulatory exposure:** GDPR Article 6 — lawful basis required for sharing PII (email addresses + metadata) with third party (ESP). Article 28 — DPA required with processor; must specify what data shared and use cases. Article 32 — organization liable for security of data shared with processor. GDPR fine for unauthorized sharing or missing DPA: up to 4% of revenue.

#### PAC-005: Email Address Disclosure in API Responses
**Linked threat:** PT-005
**Actor:** Developer (logging), attacker (XSS or data breach), or mobile app caching
**Scenario:** API response includes full email addresses in task JSON: `{"task_id": 123, "title": "...", "collaborators": [{"name": "Alice", "email": "alice@secret-company.com"}]}`. Emails logged in application logs. Emails cached in mobile app local storage. Attacker compromises logs (via S3 misconfiguration) or mobile device (physical theft). Attacker builds comprehensive mapping of user emails, potentially combined with task content, to create comprehensive user profile or sell email list.
**Affected data subjects:** All users in system
**Privacy By Design principle violated:** Principle 2 (privacy as default) — should minimize PII in API responses. Principle 5 (end-to-end security) — mobile app should not cache sensitive data unencrypted.
**Regulatory exposure:** GDPR Article 5(1)(b) — data minimization principle violated (unnecessary email disclosure in responses). Article 32 — insufficient security measures for PII in logs and mobile storage. Breach notification obligation (Article 33) if emails exfiltrated from logs. Fine: up to 2% of revenue for data minimization violation.

#### PAC-006: GDPR Violation — No Privacy Notice at Registration
**Linked threat:** PT-006
**Actor:** Organization (failure to provide transparency)
**Scenario:** User registers for task app. No privacy notice presented. User does not know: (1) what data is collected ("We collect your email, task content, and activity logs"); (2) how it's used ("For service delivery, backup, and email notifications"); (3) how long it's retained ("Indefinitely"); (4) who it's shared with ("SendGrid for email delivery"); (5) what rights they have ("You can request access, deletion, portability"). User cannot make informed decision about using service.
**Affected data subjects:** All users
**Privacy By Design principle violated:** Principle 7 (transparency) — information required by GDPR Articles 13 & 14 not provided.
**Regulatory exposure:** GDPR Articles 13 & 14 — privacy notice MUST be provided at point of data collection. Failure is per-se violation (no defense of "we forgot"). DPA can issue fine: up to 2% of annual global revenue. User can also sue for damages (Article 82). Common fine ranges: 50k - 500k EUR for first-time notice violation.

#### PAC-007: GDPR Violation — No Data Subject Rights Mechanism
**Linked threat:** PT-007
**Actor:** Organization (failure to implement technical means for rights)
**Scenario:** User wants to export their data (Article 20 right). No "Download my data" feature exists. User requests erasure of their account (Article 17 right). System deletes user record from users table, but task records still exist (foreign key to user_id, but tasks not deleted). Backups still contain user's full history. User cannot exercise rights because system lacks mechanisms to honor them.
**Affected data subjects:** All users
**Privacy By Design principle violated:** Principle 1 (proactive not reactive) — rights implementation should be built in from start, not added later. Principle 5 (end-to-end security) — should include secure deletion.
**Regulatory exposure:** GDPR Articles 15, 16, 17, 18, 20, 21 — data subject rights must be honored. Non-implementation is per-se violation. User can file complaint with DPA. Organization forced to implement rights retrospectively and pay fine (up to 2% of revenue for failure to respond to rights requests within 30 days).

#### PAC-008: GDPR Violation — Undefined Data Retention Policy
**Linked threat:** PT-008
**Actor:** Organization (failure to define and enforce retention limits)
**Scenario:** User account created in 2024. User deletes account in 2026, requesting erasure. Organization cannot fully comply because: (1) no retention policy defined; (2) RDS backups kept for 30 days (but could be indefinitely); (3) no clear record of what data to delete; (4) logs contain user activity but retention undefined. User data partially deleted, but traces remain in backups and logs for years.
**Affected data subjects:** All users; especially sensitive when accounts deleted
**Privacy By Design principle violated:** Principle 2 (privacy as default) — should default to deletion/minimization, not indefinite retention. Principle 1 (proactive) — retention policy should be designed before collecting data.
**Regulatory exposure:** GDPR Article 5(1)(e) — storage limitation principle requires data kept "no longer than necessary". No retention policy = violation of principle. Exacerbated when user requests deletion (Article 17) and organization cannot comply fully. Fine: up to 2% of revenue.

#### PAC-009: GDPR Violation — No Data Protection Impact Assessment
**Linked threat:** PT-009
**Actor:** Organization (compliance failure)
**Scenario:** High-risk processing (activity profiling, email notifications to third parties, bulk data handling) proceeds without DPIA. Privacy risks not formally identified or documented. When breach occurs, DPA questions "Did you perform DPIA?" Organization has no documentation. DPA views this as reckless disregard for privacy; multiplies fine.
**Affected data subjects:** All users
**Privacy By Design principle violated:** Principle 1 (proactive) — DPIA is proactive risk assessment required by GDPR.
**Regulatory exposure:** GDPR Article 35 — DPIA required before high-risk processing. Failure to document DPIA is violation. DPA can: (1) fine organization for missing DPIA (up to 2% of revenue); (2) issue cease-and-desist order on processing; (3) multiply fines for other violations (demonstrates neglect of privacy).

#### PAC-010: GDPR Violation — No Data Processing Agreement with Email Service Provider
**Linked threat:** PT-010
**Actor:** Organization (failure to establish contractual protection)
**Scenario:** Email service provider (SendGrid) processes user emails and task data on organization's behalf. No DPA signed. SendGrid is subject only to its standard Terms of Service, which include: (1) right to use data for SendGrid's own purposes (aggregate analytics); (2) no explicit guarantee of EU adequacy; (3) undefined sub-processors; (4) no guaranteed deletion on request. Organization liable for SendGrid's practices; breaches of SendGrid terms = organization breaches GDPR. When DPA inquires about DPA, organization has none.
**Affected data subjects:** All users
**Privacy By Design principle violated:** Principle 5 (end-to-end security) — must contractually ensure processor meets same security/privacy standards.
**Regulatory exposure:** GDPR Article 28 — DPA required with all processors. Missing DPA = per-se violation (no adequacy defense). Article 82 — users can sue organization for processor's unauthorized use of data. Fine for missing DPA: 2-4% of revenue.

#### PAC-011: Privacy Harm from Unencrypted Backups
**Linked threat:** PT-011
**Actor:** Backup administrator or breach of AWS account
**Scenario:** RDS automated backups store entire database (user emails, task content, password hashes, collaboration data) unencrypted. Backup stored for 30 days by default. If AWS account compromised (via leaked credentials, insider threat, or AWS infrastructure breach), attacker gains access to full historical snapshot of user data. User account deleted from live database 6 months ago, but backup still exists in backup retention window.
**Affected data subjects:** All users, including deleted accounts
**Privacy By Design principle violated:** Principle 2 (privacy as default) — backups should encrypt and delete user data upon request. Principle 5 (end-to-end security) — backup encryption should be mandatory.
**Regulatory exposure:** GDPR Article 5(1)(e) — storage limitation violated if user data retained in backups after deletion. Article 32 — encryption at rest required for sensitive data. User can request deletion (Article 17); organization unable to comply if backups not cleaned. Fine: 2-4% of revenue for storage violation or failed right-to-erasure.

---

## 6. Counter-Use Cases

### 6.1 Security Use Cases (Countermeasures)

#### SUC-001: Enforce Strong Password Policy & Rate Limiting
**Mitigates:** SAC-001 (Brute Force Login)
**Security control:** (1) Enforce minimum 12-character password with uppercase, lowercase, number, and symbol. (2) Implement account lockout after 5 failed login attempts; 15-minute cooldown. (3) Rate limit login endpoint: max 5 attempts per IP per minute. (4) Log all failed login attempts; alert on 10+ failures in 5 minutes.
**Implementation notes:** Use bcrypt/Argon2 for password hashing (not SHA256). Implement exponential backoff on failed attempts (1s delay after attempt 1, 2s after attempt 2, etc.). Use CAPTCHA after 3 failed attempts. Consider passwordless auth (magic links, FIDO2 keys) for future.
**OWASP ASVS reference:** ASVS 4.0 §2.1 (password strength), §2.2 (general authenticator security), §2.3 (session management)
**Residual risk:** Rate limiting may be bypassed via distributed attack (multiple IPs); mitigate with network-level DDoS protection. Weak user passwords still possible (users choose "P@ssw0rd1234"); educate users on password managers.

#### SUC-002: Implement Secure Session Management with Token Rotation
**Mitigates:** SAC-002 (Session Token Theft), ST-012 (Token Reuse)
**Security control:** (1) Use short-lived JWT tokens (15-minute expiry). (2) Issue refresh tokens (14-day expiry, httpOnly, secure flags). (3) Implement token rotation on each refresh. (4) Invalidate all tokens on logout or password change. (5) Use HS256 (HMAC-SHA256) or RS256 (RSA) for JWT signing; store signing key in AWS Secrets Manager. (6) Set httpOnly and secure flags on all session cookies/tokens (prevent JavaScript access).
**Implementation notes:** Use libraries: jsonwebtoken (Node.js), PyJWT (Python), java-jwt (Java). Implement token blacklist (Redis) for logout; store user_id, token jti, expiry. Refresh endpoint: POST /auth/refresh with refresh_token; returns new access token. Invalidate entire token family on refresh token reuse (potential breach indicator).
**OWASP ASVS reference:** ASVS 4.0 §3.3 (session management), §2.2 (authentication)
**Residual risk:** If signing key compromised, attacker can forge tokens indefinitely; mitigate with regular key rotation. If Redis blacklist unavailable, logout ineffective; mitigate with high availability Redis cluster.

#### SUC-003: Parameterize All Database Queries; Implement Input Validation
**Mitigates:** SAC-002 (SQL Injection)
**Security control:** (1) Never concatenate user input into SQL. Use parameterized queries / prepared statements for all dynamic queries. (2) Implement strict input validation: whitelist allowed characters, enforce length limits, reject unexpected formats. (3) Use ORM (Sequelize, SQLAlchemy, Hibernate) which auto-parameterizes by default. (4) Perform output encoding when displaying user input in HTML/JSON responses (HTML entity encoding, JSON escaping).
**Implementation notes:** Example: Instead of `SELECT * FROM tasks WHERE title LIKE '%' + userInput + '%'`, use `SELECT * FROM tasks WHERE title LIKE $1` with `parameters: [userInput]`. For task titles, validate: alphanumeric, max 255 chars, reject SQL keywords. For task descriptions, allow more characters but still validate length. Use libraries: node-postgres (pg module with parameterized queries), SQLAlchemy with parameterized queries.
**OWASP ASVS reference:** ASVS 4.0 §5 (validation, sanitization, encoding)
**Residual risk:** Second-order SQL injection (user input stored, later used in query without parameterization); mitigate by parameterizing all queries at all stages. NoSQL injection if using MongoDB; apply same parameterization principles.

#### SUC-004: Implement Role-Based Access Control (RBAC); Perform Authorization Checks
**Mitigates:** SAC-003 (Unauthorized Task Access), SAC-010 (Privilege Escalation)
**Security control:** (1) Define roles: User (regular user), ProjectOwner (owns project; can invite/remove), Admin (system admin). (2) For each task request, verify: (a) User authenticated (token valid); (b) User has read/write access to project/task (authorization check). (3) Before returning task in API, check: `if not (user_id in project.members AND member.has_permission('read')) return 403 Forbidden`. (4) Implement least privilege: deny by default, grant only necessary permissions. (5) No admin endpoints should be callable by regular users; validate role on every admin call.
**Implementation notes:** Store permissions in database: table `project_members (project_id, user_id, role, permissions)`. Define permission set: READ, WRITE, DELETE, INVITE, ADMIN. In API middleware, extract user from token and check permission: `if not project.can_user_read(user_id): return 403`. For admin endpoints, prepend check: `if not user.is_admin(): return 403`.
**OWASP ASVS reference:** ASVS 4.0 §4.1 (access control general), §4.2 (business logic), §4.3 (control enforcement)
**Residual risk:** RBAC model may not capture all business rules (e.g., "user can see only their own tasks unless shared"); mitigate with fine-grained access control (ABAC) for complex scenarios. Attribute-based access control allows policies like "user can see task if owner OR assigned OR project shared with user".

#### SUC-005: Implement CSRF Protection via CSRF Tokens
**Mitigates:** SAC-004 (CSRF)
**Security control:** (1) For web UI forms, generate unique CSRF token per session. (2) Include token in hidden form field: `<input type="hidden" name="csrf_token" value="...">`. (3) On form submission, server validates token: `if form.csrf_token != session.csrf_token: return 403`. (4) Regenerate token after each form submission. (5) Alternatively, use SameSite cookie attribute (SameSite=Strict or SameSite=Lax) to prevent cross-site cookie inclusion.
**Implementation notes:** Use libraries: express-csrf (Express.js), django-csrf (Django), spring-security (Spring). SameSite=Strict blocks all cross-site cookie inclusion (preferred); SameSite=Lax allows top-level navigation (less protection). For REST API (mobile app), tokens less critical (mobile app doesn't use cookies); instead rely on origin validation and SameSite cookies.
**OWASP ASVS reference:** ASVS 4.0 §4.4 (CSRF protection)
**Residual risk:** If CSRF token itself compromised (via XSS), protection fails; mitigate by preventing XSS (SUC-006). Token validation may be bypassed by attackers with network access (man-in-the-middle); mitigate with HTTPS-only.

#### SUC-006: Prevent XSS via Output Encoding & Content Security Policy
**Mitigates:** ST-002 (Session Token Theft via XSS)
**Security control:** (1) HTML entity encode all user-generated content before rendering in HTML: `<div>{{ task.title | html_escape }}</div>`. (2) JSON escape all data in API responses: `{"title": "Task with \"quotes\""}`. (3) Implement Content Security Policy (CSP) header: `Content-Security-Policy: default-src 'self'; script-src 'self'` to restrict script execution to same-origin only. (4) Do not use `eval()`, `innerHTML`, or string concatenation for dynamic HTML; use DOM APIs like `textContent` or templating engines with auto-escaping.
**Implementation notes:** Use templating libraries with auto-escaping: Handlebars (auto-escapes by default), Jinja2 (with |escape filter), EJS (with <%= for escaped output). For JSON, use native JSON.stringify which auto-escapes. CSP should be strict; test with report-only mode first (`Content-Security-Policy-Report-Only`). For mobile app, CSP not applicable; prevent XSS by not using webviews for untrusted content.
**OWASP ASVS reference:** ASVS 4.0 §5.3 (output encoding), §5.4 (output validation), plus modern guidance on CSP
**Residual risk:** CSP can be bypassed if `script-src 'unsafe-inline'` or `script-src 'nonce-...'` used incorrectly; avoid unsafe-inline. Encoding must be context-aware (HTML context vs. JavaScript context vs. URL context) — wrong encoding type can be bypassable.

#### SUC-007: Implement Rate Limiting on Sensitive Endpoints
**Mitigates:** ST-006 (Email Enumeration), ST-011 (DoS), SAC-005 (Account Enumeration)
**Security control:** (1) Rate limit endpoints: /auth/register (5 per hour per IP), /auth/login (10 per minute per IP), /api/invite (20 per minute per user), /api/tasks (100 per minute per user). (2) Return 429 Too Many Requests with Retry-After header. (3) Implement distributed rate limiting (Redis shared state) if load-balanced across multiple servers. (4) Log rate limit violations; alert on suspicious patterns (1000+ attempts from single IP in 1 minute).
**Implementation notes:** Use middleware: express-rate-limit (Express.js), slowapi (FastAPI), RateLimiter (Spring Boot). Store rate limit counters in Redis with TTL. For distributed systems, use Redis to share counters across servers. Example: `rateLimit({windowMs: 60000, max: 10, message: "Too many requests"})`.
**OWASP ASVS reference:** ASVS 4.0 §11 (business logic), plus OWASP API Security Top 10 (API4:2019 – Lack of Resources & Throttling)
**Residual risk:** Distributed/botnet attack can bypass IP-based rate limiting; mitigate with:
1. CAPTCHA after N failed attempts
2. Fingerprinting (device ID, browser fingerprint)
3. Geographic anomaly detection (login from two countries within 1 hour = suspicious)
4. Network-level DDoS mitigation (CloudFront, DDoS service)

#### SUC-008: Encrypt Sensitive Data at Rest & in Transit
**Mitigates:** SAC-007 (Database Breach), ST-008 (Unencrypted Data at Rest), ST-007 (Logs exposure)
**Security control:** (1) **In Transit**: Use TLS 1.3 for all HTTPS connections. Enforce HTTPS-only: redirect HTTP to HTTPS, set HSTS header `Strict-Transport-Security: max-age=31536000`. (2) **At Rest (Database)**: Enable AWS RDS encryption (AES-256). Encrypt database backups. Use AWS KMS for key management. (3) **Application-Level Encryption**: Encrypt sensitive fields (task descriptions, user emails) at application layer with AES-256-GCM before storing in database. (4) **Logs**: Do not log plaintext PII; truncate or redact task descriptions and emails in logs.
**Implementation notes:** Use libraries: crypto (Node.js), cryptography (Python). For RDS, enable `storage_encrypted = true` in Terraform. For application encryption, encrypt sensitive columns with unique per-record IVs and generate encryption keys from master key in AWS Secrets Manager. Log redaction: use middleware to strip PII before logging.
**OWASP ASVS reference:** ASVS 4.0 §2.5 (cryptographic controls), §6 (cryptography)
**Residual risk:** If encryption keys compromised, all data decrypted; mitigate with strong key management, access controls on Secrets Manager, and regular key rotation. Application-level encryption adds latency; optimize query performance by encrypting only truly sensitive fields.

#### SUC-009: Audit Logging & Alerting on Sensitive Actions
**Mitigates:** ST-014 (No Audit Logging), SAC-007 (forensics after breach)
**Security control:** (1) Log all sensitive actions with: timestamp, user_id, action (CREATE_TASK, DELETE_TASK, INVITE_USER), resource_id, result (success/failure), IP address. (2) Store audit logs in separate, tamper-evident system (e.g., AWS CloudTrail for AWS API calls, custom audit table with checksums). (3) Do not log sensitive data (passwords, task descriptions); only log action type and resource IDs. (4) Alert on suspicious patterns: 10+ failed logins, deletion of 100+ tasks in 1 hour, invite of 50+ users in 1 minute. (5) Retain audit logs for minimum 1 year; implement immutable backup (e.g., S3 with Object Lock).
**Implementation notes:** Create table `audit_log (id, timestamp, user_id, action, resource_id, result, ip_address)`. Middleware logs on every endpoint. Send audit events to CloudWatch / Splunk for alerting. Set up CloudWatch alarms: `filter_pattern="FAILED_LOGIN" as field | stats count by user_id` → alert if count > 10 in 5 minutes.
**OWASP ASVS reference:** ASVS 4.0 §7 (logging and monitoring), §7.1 (logging)
**Residual risk:** Logs themselves may become attack target; mitigate with separate logging infrastructure, encryption of logs, and access controls. Log volume may be high (millions of entries/day); ensure monitoring system can scale (ElasticSearch, Splunk).

#### SUC-010: Secure Mobile App Local Storage
**Mitigates:** ST-009 (Insecure Mobile App Data Storage)
**Security control:** (1) Do not store authentication tokens in plaintext. Use platform-provided secure storage: Android Keystore, iOS Keychain. (2) Encrypt cached task data with device-specific encryption key. (3) Implement app-level locking: require biometric/PIN to unlock app and access sensitive data. (4) On logout, clear all cached data and tokens from device. (5) Set app to not allow screenshots in recent apps list (prevent leakage of task content).
**Implementation notes:** Android: Use EncryptedSharedPreferences library; stores key in Keystore, data encrypted at rest. iOS: Use Keychain with kSecAttrAccessibleWhenUnlockedThisDeviceOnly access level. Implement biometric authentication using BiometricPrompt (Android) / LocalAuthentication (iOS). On logout: call SharedPreferences.clear() (Android) or remove all Keychain items (iOS). Prevent screenshots: `setFlag(FLAG_SECURE)` on all Activities (Android).
**OWASP ASVS reference:** ASVS 4.0 Mobile §4 (authentication), plus OWASP Mobile Top 10 (M2:2023 – Insecure Data Storage)
**Residual risk:** Rooted/jailbroken devices can bypass Keystore/Keychain; mitigate with jailbreak/root detection and deny access if detected. Biometric spoofing possible (fingerprint replay); mitigate by requiring PIN fallback and anti-spoofing measures.

#### SUC-011: Implement Multi-Factor Authentication (MFA)
**Mitigates:** SAC-001 (Brute Force), SAC-009 (Token Reuse); raises bar for account compromise
**Security control:** (1) Support MFA methods: TOTP (Time-based One-Time Password via Authenticator app), SMS, email verification code. (2) Require MFA for all user accounts (mandatory or optional depending on risk appetite). (3) On login, after password verified, prompt for MFA code. (4) If MFA device lost, provide recovery codes (10x single-use backup codes printed/saved by user). (5) Do not allow login without MFA if enabled.
**Implementation notes:** Use libraries: speakeasy (TOTP generation, Node.js), pyotp (Python), google-authenticator. Generate secret during MFA setup; user scans QR code with Authenticator app. On login, ask for 6-digit code; verify with `speakeasy.totp.verify({secret, encoding: 'base32', token: userCode, window: 1})`. For SMS MFA, use Twilio or AWS SNS. Recovery codes stored as hashed list in database.
**OWASP ASVS reference:** ASVS 4.0 §2.4 (MFA)
**Residual risk:** SMS MFA vulnerable to SIM swap attacks; recommend TOTP/FIDO2 as primary. TOTP vulnerable if user shares authenticator device (e.g., on shared computer); educate users. Recovery codes must be stored securely; if compromised, MFA bypass possible.

---

### 6.2 Privacy Use Cases (Privacy Controls)

#### PUC-001: Implement Privacy Notice & Transparent Data Collection Disclosure
**Mitigates:** PAC-006 (No Privacy Notice)
**Privacy control:** Design and publish a Privacy Notice (Privacy Policy) that covers: (1) Data categories collected (email, task content, IP address, activity logs). (2) Purpose of collection (provide service, send notifications, improve product). (3) Lawful basis (contract for account creation; legitimate interest for analytics; consent for marketing emails). (4) Data retention period (tasks retained while account active; deleted on account deletion; backups retained 30 days). (5) Recipient categories (internal team, email service provider, analytics platform). (6) User rights (access, deletion, portability, objection). (7) Contact info for DPO / privacy inquiries.
**Privacy by Design principle:** Principle 7 (Transparency) — users must know what data is collected and how it's used.
**Implementation notes:** Privacy notice presented at: (1) signup page (link to full notice); (2) account settings (view notice anytime); (3) cookie consent banner (if using cookies). Notice must be in clear, plain language (not legal jargon). For GDPR compliance, must be provided BEFORE data collected. Version the notice (v1.0, effective 2026-04-01); track when user acknowledged.
**GDPR article reference:** Articles 13 & 14 (information to be provided to data subject)
**Residual risk:** Users may not read/understand notice; mitigate with layered approach (short summary + link to full notice). Notice must be regularly updated; establish process for reviewing and updating when practices change.

#### PUC-002: Implement Data Minimization & Purpose Limitation Policy
**Mitigates:** PT-001 (Behavior Profiling), PAC-001 (Behavior Profiling Without Consent)
**Privacy control:** (1) Define data categories and minimum data required per category: Email (required for registration/communication), Task Content (required for service; user-generated), Activity Logs (required for security audit; keep 30 days, then delete). (2) Establish policy: do not collect data beyond minimum needed. (3) Do not use task data for secondary purposes (profiling, analytics, ad targeting) without explicit user consent. (4) If analytics needed, aggregate/anonymize data (count of tasks created per day, not individual task content). (5) Do not sell or share user data with third parties without consent.
**Privacy by Design principle:** Principle 1 (Proactive not Reactive) + Principle 2 (Privacy as Default) — minimize data collection upfront; do not assume profiling is acceptable.
**Implementation notes:** Document data flows: Email → (1) Authentication, (2) Password reset, (3) Notifications. No other use without explicit consent. Task Content → (1) Store for user, (2) Share with collaborators if invited, (3) Backup for retention period. No analytics/profiling. Activity Logs → (1) Security monitoring, (2) Audit trail. Purge after 30 days.
**GDPR article reference:** Article 5(1)(b) (purpose limitation), Article 5(1)(c) (data minimization)
**Residual risk:** Business pressure to use data for profiling/monetization; establish privacy governance (privacy committee, review board) to enforce this control and push back on feature requests that require secondary use.

#### PUC-003: Implement Explicit User Consent for Email Notifications
**Mitigates:** PT-006 (No Consent), PAC-003 (Non-repudiation without consent)
**Privacy control:** (1) At registration, ask user: "Would you like email notifications for task assignments and reminders?" with options to accept/decline. (2) Store consent status in database: `users table: email_notifications_enabled (boolean)`. (3) Provide easy opt-out mechanism: link in every notification email ("Manage preferences") and account settings. (4) Respect user choice: do not send notifications if consent withdrawn. (5) Retain proof of consent (timestamp, user IP, consent choice).
**Privacy by Design principle:** Principle 7 (Transparency) — users know why they receive emails. Plus Principle 4 (Full Functionality) — service works without notifications if user declines.
**Implementation notes:** During signup, show checkbox: "☐ Send me email notifications when tasks are assigned or due soon." Default: unchecked (privacy as default). Store `email_notification_consent` table: `(user_id, consent_date, ip_address, consent_status)`. Notification queue checks user preference before sending. Include unsubscribe link in every email: link to settings where user can opt-out.
**GDPR article reference:** Article 7 (conditions for consent), Article 21 (right to object)
**Residual risk:** Users may forget they consented; provide recurring reminders (quarterly emails) with option to renew consent or opt out. GDPR allows explicit consent (affirmative action) or legitimate interest (with opt-out); choose affirmative consent for higher privacy standard.

#### PUC-004: Design Data Encryption for Email Metadata Leakage Prevention
**Mitigates:** PT-004 (Activity Metadata Leakage to ESP)
**Privacy control:** (1) Minimize task content in email notifications: send only task ID and link, not full task description. (2) In email subject, use generic text ("New task assigned") instead of exposing task content. (3) Encrypt email body if supported by ESP (e.g., sendgrid-smime for S/MIME encryption). (4) Consider using a transactional email relay/proxy that sits between app and ESP, allowing app to encrypt before sending. (5) Negotiate DPA with ESP to limit their use of metadata.
**Privacy by Design principle:** Principle 4 (Full Functionality) — notifications still function with minimal content. Principle 5 (End-to-End Security) — encryption protects metadata in transit.
**Implementation notes:** Email template: Instead of `"Task: Acme Merger Negotiation – Due: 2026-06-30"`, send `"You have a new task. View details: [link]"`. Link should trigger login in browser (not expose task details in email). For encryption, use library like `node-smime` to encrypt email body before sending via SendGrid (requires user to set up S/MIME certificate, not practical for all users).
**GDPR article reference:** Article 32 (security measures), Article 25 (data protection by design)
**Residual risk:** Minimizing email content reduces usability (users want to see task details in email); trade-off between privacy and UX. Encryption adds complexity; many ESPs don't support it. Encrypted email requires user to have encryption key; not practical for mass deployment.

#### PUC-005: Implement Data Subject Rights Infrastructure
**Mitigates:** PAC-007 (No Rights Mechanism)
**Privacy control:** (1) **Right of Access (Article 15)**: Implement "Download my data" feature. User clicks button; system exports all user data as JSON file (user profile, projects, tasks, activity logs). Provide within 30 days. (2) **Right of Erasure (Article 17)**: Implement "Delete my account" feature with strong confirmation. On deletion: delete user record, cascade-delete all user's projects/tasks, delete from backups within 30 days, delete activity logs. (3) **Right of Portability (Article 20)**: Exported JSON should be in standardized format (JSON, CSV) to allow import into other services. (4) **Right of Rectification (Article 16)**: User can edit profile, email, name via account settings. (5) **Right to Object (Article 21)**: User can opt out of profiling/analytics via consent management.
**Privacy by Design principle:** Principle 1 (Proactive) — rights built in from start, not added later.
**Implementation notes:** Add account settings page with buttons: [Download My Data] [Delete My Account] [Manage Email Preferences]. Download generates JSON with: user object, projects list, tasks list, activity logs. Deletion triggers: (1) delete from users table, (2) trigger cascade delete on projects/tasks (via foreign keys), (3) log deletion event, (4) schedule backup purge (30 days later, verify user not in backups). All operations logged for audit trail.
**GDPR article reference:** Articles 15, 16, 17, 20, 21
**Residual risk:** Cascade delete may remove data needed for legal/financial audit (e.g., task created for contract negotiation); implement "soft delete" flag (mark deleted but retain for compliance period) instead of hard delete. Data export may be large (>1GB for active user); provide streaming/pagination.

#### PUC-006: Define & Enforce Data Retention Policy
**Mitigates:** PT-008 (Undefined Retention), PAC-008 (Unlimited Retention)
**Privacy control:** (1) Document retention policy: "Active project data retained while user account active. After account deletion, user data retained for 30-day compliance window, then permanently deleted. Backups deleted per AWS RDS retention policy (currently 30 days). Activity audit logs retained for 1 year, then archived. Deleted user data removed from backups within 30 days of deletion request." (2) Implement technical controls: schedule job to delete old activity logs after 1 year; schedule backup deletion after 30 days; on account deletion, mark for purge in 30 days. (3) Test retention policy: periodically verify old data actually deleted. (4) Communicate policy to users in privacy notice.
**Privacy by Design principle:** Principle 2 (Privacy as Default) — delete data when no longer needed.
**Implementation notes:** Create table `deletion_queue (user_id, deletion_requested_date, purge_date)`. When user deletes account, insert row with purge_date = 30 days from now. Scheduled job runs daily: select all rows with purge_date <= today; hard delete user and associated data. For audit logs, create table with `created_date`; schedule daily delete: `DELETE FROM audit_logs WHERE created_date < CURRENT_DATE - INTERVAL '1 year'`.
**GDPR article reference:** Article 5(1)(e) (storage limitation)
**Residual risk:** Backups may contain old data beyond retention period; mitigate by implementing backup encryption and automated purge (AWS RDS backup deletion). Data in read replicas / analytics copies may not be deleted; ensure all copies covered by retention policy.

#### PUC-007: Conduct & Document Data Protection Impact Assessment (DPIA)
**Mitigates:** PT-009 (No DPIA)
**Privacy control:** (1) Identify high-risk processing: Task content processing (involves sensitive personal data), Email notifications (third-party sharing), Activity logging (non-repudiation). (2) Perform DPIA for each risk: Document data flows, identify threats, propose mitigations. (3) Document DPIA findings in report: "DPIA conducted 2026-03-30. Identified risks: [list]. Mitigation controls: [list]. Residual risks: [list]. Conclusion: Processing can proceed with mitigations." (4) Share DPIA with DPA if requested. (5) Review DPIA annually or when practices change.
**Privacy by Design principle:** Principle 1 (Proactive) — identify risks before they materialize.
**Implementation notes:** Use DPIA template from EDPB or GDPR authority. Involve Privacy Officer, Engineering Lead, and Product Lead in assessment. Document each high-risk processing: name, purpose, personal data involved, recipients, retention, risks, mitigations. DPIA report stored in secure location (e.g., Google Drive with restricted access) and referenced in privacy documentation.
**GDPR article reference:** Article 35 (DPIA required for high-risk processing)
**Residual risk:** DPIA may identify risks that require expensive mitigations (e.g., eliminating activity logging); organization may choose to accept residual risk (document in DPIA). This is acceptable if risk is low-level and mitigation cost is disproportionate.

#### PUC-008: Establish Data Processing Agreement (DPA) with Email Service Provider
**Mitigates:** PT-010 (No DPA), PAC-010 (GDPR violation)
**Privacy control:** (1) Before sharing any user data with email service provider, sign a Data Processing Agreement (DPA). (2) DPA must include: (a) Description of processing (what data, what purpose, for how long), (b) Guarantees of data security (encryption, access controls, audit logs), (c) Commitment to EU adequacy (if applicable; use Standard Contractual Clauses if ESP in US), (d) Sub-processor disclosure (ESP must list any third parties processing data), (e) User rights (data subject requests forwarded to organization, not directly to ESP), (f) Data deletion on termination (ESP deletes all data when contract ends), (g) Audit rights (organization can audit ESP compliance). (3) Negotiate additional terms if needed. (4) Review and renew DPA annually.
**Privacy by Design principle:** Principle 5 (End-to-End Security) — contractual protection of data with third parties.
**Implementation notes:** Use standard DPA templates (GDPR Authority templates, AWS / SendGrid standard DPAs). Key negotiations: Ensure "sub-processors" clause allows organization to review and object to new sub-processors. Ensure "deletion on termination" includes all backups/copies. Require ESP to return or delete data within 30 days of contract termination. For US-based ESP, use Standard Contractual Clauses (SCCs) to meet GDPR adequacy requirement (post-Schrems II ruling).
**GDPR article reference:** Article 28 (processor requirements)
**Residual risk:** DPA only addresses processor obligations; if ESP breaches contract, organization still liable to users (Article 82 damages). Mitigate by choosing reputable ESP with audit certifications (SOC 2, ISO 27001) and strong compliance track record.

#### PUC-009: Encrypt Database Backups & Implement Secure Deletion
**Mitigates:** PT-011 (Unencrypted Backups)
**Privacy control:** (1) Enable AWS RDS encryption for all backups: encryption_enabled = true, kms_key_id = <customer-managed-key>. (2) Use customer-managed CMK (Customer Master Key) in AWS KMS, not AWS-managed key. (3) Separate key per environment (prod uses different key than staging). (4) Implement key rotation: rotate CMK every 90 days. (5) Set RDS backup retention to 30 days (automatically deletes backups older than 30 days). (6) When user requests account deletion, flag user for purge in deletion_queue; after 30 days, verify backup retention is <= 30 days (oldest backup created after deletion request). (7) Test backup restoration to ensure encryption key access.
**Privacy by Design principle:** Principle 2 (Privacy as Default) — encrypt sensitive data by default. Principle 5 (End-to-End Security) — include backup encryption.
**Implementation notes:** In Terraform: `storage_encrypted = true, kms_key_id = aws_kms_key.rds.arn`. Set RDS backup retention: `backup_retention_period = 30`. Create CMK in KMS: `enable_key_rotation = true`. Implement deletion_queue job: after 30 days, verify user completely deleted from all backups (manual verification or query oldest backup's creation date).
**GDPR article reference:** Article 32 (security measures), Article 5(1)(e) (storage limitation)
**Residual risk:** Backup encryption adds operational complexity; ensure team trained on KMS key management. If CMK is accidentally deleted, backups become inaccessible; implement safeguards (CloudTrail logging of key deletion, DLQ for accidental deletions).

#### PUC-010: Implement Comprehensive Breach Detection & Notification Procedure
**Mitigates:** GDPR Article 33/34 (Breach notification obligations)
**Privacy control:** (1) Establish breach detection mechanisms: security monitoring (SIEM), file integrity monitoring on databases, anomaly detection on data access logs. (2) On suspected breach, activate incident response: (a) Isolate affected system; (b) Assess scope (how much data, which users affected); (c) Notify DPA within 72 hours if breach affects >1000 users or sensitive data categories; (d) Notify affected users within 30 days if breach is high-risk. (3) Breach notification must include: what data was compromised, what happened, what actions user should take, contact info. (4) Document all breaches (even minor ones) in incident log for compliance audit.
**Privacy by Design principle:** Principle 7 (Transparency) — users informed of breaches affecting them.
**Implementation notes:** Set up CloudWatch alarms: unusual database access patterns (100+ failed queries from single IP), large data export (SELECT * from users in < 1 second), deleted audit logs. On alert, page on-call security team. Incident response playbook: notify CISO → assess breach → DPA notification (if required) → user notification (if required). Document all steps in incident ticket.
**GDPR article reference:** Articles 33 & 34 (breach notification)
**Residual risk:** 72-hour DPA notification deadline is tight; ensure incident response can move quickly. User notification may trigger PR crisis; prepare communications/legal team.

---

## 7. Refined Requirements

### Original Requirements (Classified)

**FR — Functional Requirements:**
- FR-001: Users can register with email and password
- FR-002: Users can log in with email and password
- FR-003: Users can create, edit, and delete tasks
- FR-004: Users can create projects
- FR-005: Users can invite other users to collaborate
- FR-006: Email notifications for task assignments
- FR-007: Email notifications for due date reminders
- FR-008: Mobile app (iOS) connects to REST API
- FR-009: Mobile app (Android) connects to REST API
- FR-010: Free tier: max 5 projects
- FR-011: Paid tier: unlimited projects

### New Requirements from Analysis

**SEC — Security Non-Functional Requirements:**
- **[NEW — from ST-001, SAC-001]** SEC-001: Enforce minimum 12-character password with uppercase, lowercase, numbers, and symbols; implement account lockout after 5 failed attempts (15-minute cooldown); rate limit login endpoint to max 5 attempts per IP per minute
- **[NEW — from ST-002, ST-012, SUC-002]** SEC-002: Implement secure session management: use short-lived JWT tokens (15-minute expiry) with refresh tokens (14-day expiry); set httpOnly and secure flags on all tokens; rotate tokens on each refresh; invalidate all tokens on logout
- **[NEW — from ST-003, SAC-002, SUC-003]** SEC-003: Use parameterized queries / prepared statements for all database operations; implement strict input validation (whitelist allowed characters, enforce length limits); use ORM or parameterized query library
- **[NEW — from ST-004, SAC-003, SUC-004]** SEC-004: Implement role-based access control (RBAC) with least privilege; verify authorization (not just authentication) before returning/modifying any user-scoped resource; define roles (User, ProjectOwner, Admin) and permissions (READ, WRITE, DELETE, INVITE, ADMIN)
- **[NEW — from ST-005, SAC-004, SUC-005]** SEC-005: Implement CSRF protection via CSRF tokens for web UI forms; use SameSite=Strict cookie attribute
- **[NEW — from ST-006, SAC-005, SUC-007]** SEC-006: Use uniform response messages for authentication endpoints; rate limit registration and invite endpoints; do not reveal whether email exists during registration
- **[NEW — from ST-007, ST-008, SAC-006, SUC-008]** SEC-007: Do not log plaintext PII; redact or truncate task descriptions and emails in logs; implement encryption at rest for sensitive data (AES-256); encrypt database backups
- **[NEW — from ST-009, SUC-010]** SEC-008: In mobile app: use platform-provided secure storage (Android Keystore, iOS Keychain) for authentication tokens; encrypt cached task data with device-specific key; implement app-level locking (biometric/PIN); clear cached data and tokens on logout
- **[NEW — from ST-010, SUC-011]** SEC-009: Support multi-factor authentication (MFA) via TOTP, SMS, or email; allow users to enable/disable; provide recovery codes for MFA device loss
- **[NEW — from ST-011, SUC-007]** SEC-010: Implement rate limiting on all sensitive endpoints (task creation, user invitation, etc.); return 429 Too Many Requests on limit exceeded
- **[NEW — from ST-013, SAC-010, SUC-004]** SEC-011: Enforce authorization check on all admin endpoints; validate user role before processing; use principle of least privilege (deny by default)
- **[NEW — from ST-014, SUC-009]** SEC-012: Implement comprehensive audit logging: log all sensitive actions (login, task creation/deletion, user invitation, data export) with timestamp, user_id, action type, resource_id, result, IP address; store audit logs in tamper-evident system; retain for minimum 1 year; implement alerting on suspicious patterns (10+ failed logins, bulk deletions, etc.)
- **[NEW — from ST-001 through ST-014]** SEC-013: Encrypt all data in transit using TLS 1.3; enforce HTTPS-only; set HSTS header (Strict-Transport-Security: max-age=31536000)
- **[NEW — gap analysis]** SEC-014: Manage secrets securely; store all encryption keys, API keys, and credentials in AWS Secrets Manager; rotate keys every 90 days; never hardcode secrets in code or logs
- **[NEW — gap analysis]** SEC-015: Implement error handling that does not leak sensitive data; avoid stack traces in production error responses; log full errors internally for debugging
- **[NEW — gap analysis]** SEC-016: Perform dependency security scanning; scan all third-party libraries (npm, pip, etc.) for known vulnerabilities on every build; use tools like Snyk, Dependabot, or similar; fail CI/CD pipeline if critical vulnerabilities found

**PRV — Privacy Non-Functional Requirements:**
- **[NEW — from PT-006, PAC-006, PUC-001]** PRV-001: Publish and display a comprehensive Privacy Notice (Privacy Policy) that covers: data categories collected, purposes, lawful basis, data retention, recipients, user rights, and contact info; provide at signup and in account settings; update and version notice when practices change
- **[NEW — from PT-001, PAC-001, PUC-002]** PRV-002: Implement data minimization: collect only data necessary for service delivery; do not use task data for secondary purposes (profiling, analytics, ad targeting) without explicit user consent; document minimum data required per feature
- **[NEW — from PT-006, PAC-003, PUC-003]** PRV-003: Obtain explicit user consent for email notifications at signup; provide easy opt-out mechanism (link in every email and in account settings); respect user choice; do not send notifications if consent withdrawn; retain proof of consent (timestamp, IP, choice)
- **[NEW — from PT-004, PUC-004]** PRV-004: Minimize task content in email notifications; send only task ID and link, not full task description; use generic subject lines; consider email encryption (S/MIME) if supported by ESP; negotiate DPA with ESP limiting metadata use
- **[NEW — from PT-005, PAC-005]** PRV-005: Minimize PII in API responses; do not include email addresses in task lists unless necessary; apply field-level access controls (users see only their own email + collaborators' emails); truncate/hash emails where possible
- **[NEW — from PT-007, PAC-007, PUC-005]** PRV-006: Implement data subject rights infrastructure: (a) Right of Access (Article 15): "Download my data" feature exports user data as JSON within 30 days; (b) Right of Erasure (Article 17): "Delete my account" with cascade delete of projects/tasks and backup purge within 30 days; (c) Right of Portability (Article 20): Exported data in standardized format; (d) Right of Rectification (Article 16): User can edit profile info via settings
- **[NEW — from PT-008, PAC-008, PUC-006]** PRV-007: Define and enforce documented data retention policy: active project data retained while account active; deleted user data retained 30 days (compliance window), then permanently deleted; audit logs retained 1 year, then deleted; backups deleted per AWS RDS policy (30-day default); implement technical controls (deletion jobs) to enforce policy; test and verify old data actually deleted
- **[NEW — from PT-009, PUC-007]** PRV-008: Conduct Data Protection Impact Assessment (DPIA) for high-risk processing (task content, email notifications, activity logging); document risks, mitigations, and residual risks; review DPIA annually or when practices change
- **[NEW — from PT-010, PAC-010, PUC-008]** PRV-009: Establish Data Processing Agreement (DPA) with email service provider before sharing user data; DPA must specify: data scope, purposes, security guarantees, sub-processor disclosure, user rights, data deletion on termination; use Standard Contractual Clauses (SCCs) if ESP in non-EU jurisdiction
- **[NEW — from PT-011, PAC-011, PUC-009]** PRV-010: Encrypt database backups at rest (AES-256) using customer-managed AWS KMS keys; enable key rotation (every 90 days); set RDS backup retention to 30 days (auto-delete older backups); verify deleted user data removed from all backups within 30 days
- **[NEW — gap analysis]** PRV-011: Implement breach detection and notification procedure: detect suspicious access patterns; assess breach scope; notify DPA within 72 hours if breach affects 1000+ users or sensitive data; notify affected users within 30 days if high-risk; document all breaches in incident log
- **[NEW — gap analysis]** PRV-012: Comply with GDPR Article 32 security requirements: implement technical measures (encryption, access controls, pseudonymization where appropriate); organizational measures (staff training, access policies, incident response); document security measures in Security Policy
- **[NEW — gap analysis]** PRV-013: Implement privacy by design: conduct impact assessment before new features; default to privacy-protective settings (e.g., no email notifications by default); minimize data collection; test privacy controls in QA; educate development team on privacy principles

**COMP — Compliance / Regulatory Requirements:**
- **[NEW — from overall assessment]** COMP-001: Comply with GDPR (General Data Protection Regulation) for all EU users; ensure lawful basis for all data processing; implement required transparency, rights, and security measures documented in this analysis
- **[NEW — from overall assessment]** COMP-002: Maintain records of processing activities (Record of Processing Activities / RPA) per GDPR Article 30; document all data processing (what data, purpose, recipients, retention)
- **[NEW — from overall assessment]** COMP-003: If applicable, comply with local privacy laws: CCPA (California), PIPEDA (Canada), LGPD (Brazil), etc. Assess and document which laws apply based on user locations
- **[NEW — from overall assessment]** COMP-004: Implement SOC 2 Type II audit readiness: document security controls, implement monitoring, prepare for external audit; achieve SOC 2 certification within 12 months of launch (market requirement for B2B SaaS)

**PERF — Performance Requirements (brief):**
- **[NEW — gap analysis]** PERF-001: Maintain 99.5% uptime SLA; implement monitoring and alerting; define RTO (Recovery Time Objective) = 15 minutes, RPO (Recovery Point Objective) = 5 minutes
- **[NEW — gap analysis]** PERF-002: API response time for task operations (GET, POST, PUT, DELETE) must be < 200ms at p95 under normal load; for mobile app, ensure support for slow networks (2G fallback)

---

## 8. Security Requirements Traceability Matrix

| Req ID | Requirement (brief) | Type | Use Cases | Threat / Abuse Case | Control (SUC/PUC) | Test ID | Test Description | Priority |
|--------|---------------------|------|-----------|---------------------|-------|---------|------------------|----------|
| FR-001 | Register with email/password | FR | UC-001 | ST-001, ST-006 | SUC-001, SUC-007 | TA-001 | Email validation, duplicate check | High |
| FR-002 | Login with email/password | FR | UC-002 | ST-001, ST-002, ST-012 | SUC-001, SUC-002, SUC-011 | TA-002, TA-003, TA-004 | Password verification, token issuance, MFA flow | Critical |
| FR-003 | Create/edit/delete tasks | FR | UC-003 | ST-003, ST-004, ST-014 | SUC-003, SUC-004, SUC-009 | TA-005, TA-006, TA-007 | Authorization checks, audit logging | Critical |
| FR-004 | Create projects | FR | UC-003 | ST-004, ST-010 | SUC-004, SUC-011 | TA-008 | User owns project, quota enforced | High |
| FR-005 | Invite collaborators | FR | UC-004 | ST-006, ST-011 | SUC-004, SUC-007, PUC-004 | TA-009, TA-010 | Email validation, rate limiting, DPA compliance | High |
| FR-006 | Email notifications (assignments) | FR | UC-005 | PT-004, PT-005, PT-006 | PUC-001, PUC-004, PUC-008 | TA-011 | Consent respected, metadata minimal, ESP DPA verified | High |
| FR-007 | Email reminders (due dates) | FR | UC-006 | PT-004, PT-006 | PUC-001, PUC-004, PUC-008 | TA-012 | Consent respected, schedule accuracy, DPA compliance | High |
| FR-008 | Mobile API (iOS) | FR | UC-007 | ST-002, ST-009, ST-012 | SUC-002, SUC-008, SUC-010 | TA-013, TA-014 | Token auth, TLS enforcement, secure storage | High |
| FR-009 | Mobile API (Android) | FR | UC-007 | ST-002, ST-009, ST-012 | SUC-002, SUC-008, SUC-010 | TA-013, TA-014 | Token auth, TLS enforcement, secure storage | High |
| FR-010 | Free tier: 5 project limit | FR | UC-008 | ST-013 (elevation) | SUC-004, SUC-011 | TA-015 | Quota enforced, cannot bypass | Medium |
| FR-011 | Paid tier: unlimited | FR | All | None | None | N/A | Subscription logic | Low |
| SEC-001 | Strong passwords, rate limiting | SEC | UC-001, UC-002 | ST-001, SAC-001 | SUC-001 | TA-016, TA-017, TA-018 | Pwd policy tested, brute force blocked, lockout verified | Critical |
| SEC-002 | Secure session mgmt (JWT, refresh tokens) | SEC | UC-002, UC-003, UC-007 | ST-002, ST-012, SAC-009 | SUC-002 | TA-019, TA-020, TA-021 | Token generation, expiry, rotation, logout invalidation | Critical |
| SEC-003 | Parameterized queries, input validation | SEC | UC-003, UC-004 | ST-003, SAC-002 | SUC-003 | TA-022, TA-023, TA-024 | SQL injection tests, payload filtering verified | Critical |
| SEC-004 | RBAC authorization enforcement | SEC | UC-003, UC-004, UC-007 | ST-004, ST-013, SAC-003, SAC-010 | SUC-004 | TA-025, TA-026, TA-027 | User can only access own resources, privilege escalation blocked | Critical |
| SEC-005 | CSRF protection (tokens, SameSite) | SEC | UC-003, UC-004 | ST-005, SAC-004 | SUC-005 | TA-028 | CSRF token validation, SameSite enforcement | High |
| SEC-006 | Rate limiting, no email enumeration | SEC | UC-001, UC-004 | ST-006, ST-011, SAC-005, SAC-008 | SUC-007 | TA-029, TA-030 | Endpoint rate limits enforced, uniform error messages | High |
| SEC-007 | No plaintext PII in logs, encryption at rest | SEC | All | ST-007, ST-008, SAC-006, SAC-007 | SUC-008 | TA-031, TA-032, TA-033 | Logs redacted, DB encryption verified, backup encryption | Critical |
| SEC-008 | Mobile app secure storage | SEC | UC-007 | ST-009, SAC-002 | SUC-010 | TA-034, TA-035 | Tokens in Keychain/Keystore, data encrypted, clear on logout | High |
| SEC-009 | MFA support | SEC | UC-002 | ST-010, SAC-001 | SUC-011 | TA-036, TA-037 | TOTP generation, SMS delivery, recovery codes | High |
| SEC-010 | Rate limiting all endpoints | SEC | All | ST-011, SAC-008 | SUC-007 | TA-030, TA-038 | Rate limits enforced globally, 429 responses verified | High |
| SEC-011 | Admin authorization checks | SEC | All | ST-013, SAC-010 | SUC-004 | TA-039, TA-040 | Non-admin cannot call admin endpoints | Critical |
| SEC-012 | Audit logging & alerting | SEC | All | ST-014, SAC-007 | SUC-009 | TA-041, TA-042, TA-043 | All actions logged, sensitive actions alerted on | High |
| SEC-013 | TLS 1.3 encryption in transit | SEC | All | ST-002, SAC-006 | SUC-008 | TA-044 | HTTPS-only enforced, HSTS header set, TLS version verified | Critical |
| SEC-014 | Secrets management (KMS, rotation) | SEC | All | SAC-006, SAC-007 | SUC-008 | TA-045 | Keys in Secrets Manager, rotated every 90 days, no hardcoded secrets | High |
| SEC-015 | Error handling (no data leakage) | SEC | All | ST-007, SAC-006 | SUC-008 | TA-046 | Production errors sanitized, full errors in logs only | High |
| SEC-016 | Dependency scanning (Snyk, Dependabot) | SEC | All | N/A (supply chain) | None | TA-047 | CI/CD fails on critical vuln, quarterly library audit | Medium |
| PRV-001 | Privacy Notice published | PRV | UC-001 | PT-006, PAC-006 | PUC-001 | TA-048 | Notice present at signup, covers all data categories, versioned | Critical |
| PRV-002 | Data minimization policy | PRV | UC-003, UC-005 | PT-001, PAC-001 | PUC-002 | TA-049 | Only necessary data collected, no unauthorized profiling | High |
| PRV-003 | Explicit consent for email notifications | PRV | UC-005, UC-006 | PT-006, PAC-003 | PUC-003 | TA-050 | Consent checkbox at signup, opt-out link in email, preference respected | Critical |
| PRV-004 | Minimize email content, ESP metadata protection | PRV | UC-005, UC-006 | PT-004, PAC-004 | PUC-004 | TA-051 | Emails contain only task ID + link, not full content; DPA verified | High |
| PRV-005 | Minimize PII in API responses | PRV | UC-007 | PT-005, PAC-005 | PUC-004 | TA-052 | Email addresses excluded unless necessary, logs not exposed | High |
| PRV-006 | Data subject rights (access, erasure, portability) | PRV | All | PT-007, PAC-007 | PUC-005 | TA-053, TA-054, TA-055 | Download data feature, delete account feature, portability format | Critical |
| PRV-007 | Data retention policy defined & enforced | PRV | All | PT-008, PAC-008 | PUC-006 | TA-056, TA-057 | Deletion job runs, old data purged, backups cleaned | Critical |
| PRV-008 | DPIA conducted & documented | PRV | UC-005, UC-003 | PT-009 | PUC-007 | TA-058 | DPIA report exists, risks documented, mitigations in place | High |
| PRV-009 | DPA with ESP (email service provider) | PRV | UC-005, UC-006 | PT-010, PAC-010 | PUC-008 | TA-059 | DPA contract signed, sub-processors listed, deletion guaranteed | Critical |
| PRV-010 | Backup encryption & secure deletion | PRV | All | PT-011, PAC-011 | PUC-009 | TA-060, TA-061 | RDS backup encrypted, KMS key rotation enabled, backup purge tested | Critical |
| PRV-011 | Breach detection & notification procedure | PRV | All | All security threats | PUC-010 | TA-062, TA-063 | Breach detected, DPA notified within 72h, users notified within 30d | High |
| PRV-012 | GDPR Article 32 security measures | PRV | All | All | All SUCs | TA-064 | Security policy documented, controls audited | High |
| PRV-013 | Privacy by design in development | PRV | All | All | All PUCs | TA-065 | Impact assessment for new features, QA privacy tests | Medium |
| COMP-001 | GDPR compliance | COMP | All | All privacy threats | All PUCs | TA-066 | Legal review, DPA registrations, RPA maintained | Critical |
| COMP-002 | Record of Processing Activities (RPA) | COMP | All | N/A (documentation) | PUC-007 | TA-067 | RPA document maintained, updated quarterly | High |
| COMP-003 | Multi-jurisdiction compliance (CCPA, PIPEDA, LGPD) | COMP | All | N/A | PUC-001 | TA-068 | Compliance matrix per jurisdiction, legal review | High |
| COMP-004 | SOC 2 Type II audit readiness | COMP | All | N/A | All SUCs | TA-069 | SOC 2 audit in progress, controls documented | Medium |
| PERF-001 | 99.5% uptime SLA, RTO/RPO targets | PERF | All | N/A | N/A | TA-070 | Monitoring dashboards, failover tested | Medium |
| PERF-002 | API response time < 200ms p95 | PERF | UC-003, UC-007 | N/A | N/A | TA-071 | Load testing, response time monitoring | Medium |

---

## 9. Test Artifacts

### 9.1 Functional Security Tests

#### TA-001: Email Validation and Duplicate Check on Registration
**Type:** Functional Security Test
**Requirement(s):** FR-001, SEC-001
**Scenario:** Test registration endpoint correctly validates email format and rejects duplicate registrations
**Test approach:** Unit test
**Expected outcome:**
- Valid email (user@example.com) accepted; invalid emails (missing @, invalid domain) rejected with 400 Bad Request
- Duplicate email rejected with 409 Conflict; first user registration succeeds, second with same email fails
- Response does not reveal whether email exists (uniform response: "Account created" or "Check your email for verification")
**Automation potential:** High

#### TA-002: Password Hash Verification
**Type:** Functional Security Test
**Requirement(s):** FR-002, SEC-001
**Scenario:** Test that passwords are hashed (not plaintext) and hash verification works
**Test approach:** Unit test + database inspection
**Expected outcome:**
- Password "MyPassword123!" hashed with bcrypt/Argon2 (not SHA256, not plaintext)
- Hash is non-deterministic (same password hashes differently each time)
- Verification: `bcrypt.compare("MyPassword123!", storedHash)` returns true for correct password, false for wrong password
- Database inspection shows no plaintext passwords
**Automation potential:** High

#### TA-003: Password Strength Policy Enforcement
**Type:** Functional Security Test
**Requirement(s):** SEC-001
**Scenario:** Test that password strength requirements are enforced (12 chars, uppercase, lowercase, number, symbol)
**Test approach:** Unit test
**Expected outcome:**
- "short" (6 chars) rejected with message "Password must be at least 12 characters"
- "nouppercase123!" (no uppercase) rejected with message "Password must include uppercase letter"
- "NOLOWERCASE123!" (no lowercase) rejected
- "Nouppers1!" (11 chars, missing symbol) rejected
- "ValidPass123!" (12 chars, all requirements) accepted
**Automation potential:** High

#### TA-004: MFA TOTP Generation and Verification
**Type:** Functional Security Test
**Requirement(s):** SEC-009
**Scenario:** Test TOTP-based MFA works correctly
**Test approach:** Unit test
**Expected outcome:**
- TOTP secret generated and encoded as base32
- QR code generated for scanning in authenticator app
- 6-digit code generated from secret is time-synchronized
- Verification: `totp.verify({secret, token: userProvidedCode, window: 1})` returns true for correct code within 30s window, false for expired/wrong code
- Recovery codes (10 codes) generated, each usable once
**Automation potential:** High

#### TA-005: Task Authorization — User Can Only Access Own Tasks
**Type:** Functional Security Test
**Requirement(s):** FR-003, SEC-004
**Scenario:** Test that authorization checks prevent user from accessing tasks they don't own
**Test approach:** Integration test
**Expected outcome:**
- User A creates task_id=123
- User B (different account) calls GET /api/tasks/123 with their own session token
- System returns 403 Forbidden (not 200 OK with task data)
- Error message: "You do not have access to this task" (no information about whether task exists)
**Automation potential:** High

#### TA-006: Project Ownership Authorization
**Type:** Functional Security Test
**Requirement(s):** FR-004, SEC-004
**Scenario:** Test that only project owner can delete/modify project
**Test approach:** Integration test
**Expected outcome:**
- User A creates project_id=456
- User B attempts PUT /api/projects/456 (to rename) with their token
- System returns 403 Forbidden; project not modified
- User A can successfully PUT /api/projects/456 with their token
**Automation potential:** High

#### TA-007: Audit Logging of Sensitive Actions
**Type:** Functional Security Test
**Requirement(s):** SEC-012
**Scenario:** Test that task creation, deletion, and user invitation actions are logged
**Test approach:** Integration test + database query
**Expected outcome:**
- User A creates task → audit_log entry created: `{timestamp, user_id=A, action='CREATE_TASK', resource_id=123, result='SUCCESS'}`
- User B deletes task → audit_log entry created with DELETE action
- User A invites User C → audit_log entry created with INVITE_USER action
- All entries have timestamp, user_id, action, resource_id, IP address
- Audit logs do not contain plaintext task descriptions or passwords
**Automation potential:** High

#### TA-008: Quota Enforcement (Free Tier 5 Project Limit)
**Type:** Functional Security Test
**Requirement(s):** FR-010, SEC-004
**Scenario:** Test that free tier users cannot create more than 5 projects
**Test approach:** Integration test
**Expected outcome:**
- Free tier user creates projects 1-5 → all succeed
- User attempts to create project 6 → system returns 403 Forbidden with message "Project limit reached for free tier"
- Paid tier user can create unlimited projects
- System checks subscription status (not just user input) to enforce limit
**Automation potential:** High

#### TA-009: Email Validation on Invite Endpoint
**Type:** Functional Security Test
**Requirement(s):** FR-005, SEC-006
**Scenario:** Test that invite endpoint validates email format
**Test approach:** Unit test
**Expected outcome:**
- Valid email (collaborator@example.com) accepted
- Invalid email (no @) rejected with 400 Bad Request
- Malformed email (special characters) rejected
- System does not reveal whether email is registered (no "user not found" response)
**Automation potential:** High

#### TA-010: Rate Limiting on Invite Endpoint
**Type:** Functional Security Test
**Requirement(s):** SEC-006, SEC-010
**Scenario:** Test that invite endpoint is rate limited
**Test approach:** Integration test
**Expected outcome:**
- First 20 invites in 1 minute succeed
- 21st request returns 429 Too Many Requests with Retry-After header
- Different user is rate limited separately (per-user limit, not global)
**Automation potential:** High

#### TA-011: Email Notification Consent Respected
**Type:** Functional Security Test
**Requirement(s):** FR-006, PRV-003
**Scenario:** Test that email notifications are only sent if user has opted in
**Test approach:** Integration test
**Expected outcome:**
- User A registers with email_notifications_enabled=false → task assigned to A → no email sent
- User B registers with email_notifications_enabled=true → task assigned to B → email sent to B
- User B changes preference to disabled → new task assigned → no email sent
- Email sent count matches only opted-in users
**Automation potential:** High

#### TA-012: Due Date Reminder Email Scheduling
**Type:** Functional Security Test
**Requirement(s):** FR-007, PRV-003
**Scenario:** Test that due date reminders are scheduled and sent at correct time
**Test approach:** Integration test (may require scheduled job simulation)
**Expected outcome:**
- Task created with due_date = 2026-04-01
- Scheduled job runs on 2026-03-31 (1 day before)
- Reminder email sent only once (not duplicates); marked as reminder_sent=true
- If due_date is in past, no reminder sent
**Automation potential:** Medium (requires time mocking)

#### TA-013: Mobile API Token Authentication
**Type:** Functional Security Test
**Requirement(s):** FR-008, FR-009, SEC-002
**Scenario:** Test that mobile API correctly validates bearer tokens
**Test approach:** Integration test
**Expected outcome:**
- Valid token in Authorization header: `Authorization: Bearer eyJhb...` → request succeeds
- Missing Authorization header → 401 Unauthorized
- Expired token (expiry timestamp passed) → 401 Unauthorized
- Invalid token (tampered with) → 401 Unauthorized
- Correct token but wrong user trying to access other user's resource → 403 Forbidden
**Automation potential:** High

#### TA-014: TLS Enforcement for Mobile API
**Type:** Functional Security Test
**Requirement(s):** SEC-013
**Scenario:** Test that HTTP requests are rejected; only HTTPS accepted
**Test approach:** Integration test
**Expected outcome:**
- HTTP request to http://api.example.com/tasks → redirect to https:// or connection refused
- HTTPS response includes HSTS header: `Strict-Transport-Security: max-age=31536000`
- Mobile app fails to connect if certificate invalid (SSL pinning or cert validation enforced)
**Automation potential:** High

#### TA-015: Quota Enforcement Cannot Be Bypassed
**Type:** Functional Security Test
**Requirement(s):** SEC-004, SEC-011
**Scenario:** Test that non-admin user cannot bypass quota check via API or admin endpoint
**Test approach:** Integration test
**Expected outcome:**
- Regular user cannot call POST /api/admin/bypass-quota (404 or 403)
- SQL injection in request body cannot bypass quota logic: `name: "Project'; UPDATE users SET tier='paid'; --"` → request fails, user tier not modified
- Quota check is server-side (not reliant on client-side validation)
**Automation potential:** High

---

### 9.2 Security Attack Tests

#### TA-016: Brute Force Login Attack — Account Lockout
**Type:** Security Attack Test
**Abuse case(s):** SAC-001
**Attack scenario:** Attacker submits 20 login requests with wrong passwords for target email
**Test approach:** Automated (custom script with requests library)
**Suggested tools:** Custom Python script using requests library; Burp Suite Intruder
**Expected outcome:**
- Requests 1-5 fail with "Invalid credentials"
- Request 6 returns 429 Too Many Requests or "Account locked"
- Account remains locked for 15 minutes; subsequent requests fail
- Alert triggered in monitoring system (>5 failed logins in 5 minutes)
**Verification:** Check application logs for lockout event; verify user cannot log in for 15 minutes

#### TA-017: Brute Force Login Attack — Rate Limiting
**Type:** Security Attack Test
**Abuse case(s):** SAC-001
**Attack scenario:** Attacker submits login requests from different IP addresses (distributed attack)
**Test approach:** Automated (distributed requests from proxy pool)
**Suggested tools:** OWASP ZAP, Burp Suite distributed scanning
**Expected outcome:**
- IP-based rate limiting: 5 requests per IP per minute; 6th request returns 429
- If attacker uses proxy pool (10 different IPs), each IP allows 5 requests, but system recognizes pattern via account-based limiting
- Alert triggered for >10 failed attempts on single account in 5 minutes
**Verification:** Monitor account lockout status; check for alert in SIEM

#### TA-018: Dictionary Attack on Weak Passwords
**Type:** Security Attack Test
**Abuse case(s):** SAC-001
**Attack scenario:** Attacker submits top 1000 passwords from rockyou.txt wordlist
**Test approach:** Automated (custom script)
**Suggested tools:** Hydra, Medusa
**Expected outcome:**
- Weak passwords (e.g., "password123") would succeed in unprotected system
- With SEC-001 controls: password policy enforces 12+ chars with mixed case/numbers/symbols, rejecting weak passwords during registration
- Attacker's wordlist (mostly 6-10 char passwords) all fail
- Rate limiting kicks in after 5 failures
**Verification:** Verify no user accounts created with weak passwords; all users meet password policy

#### TA-019: Expired JWT Token Reuse
**Type:** Security Attack Test
**Abuse case(s):** SAC-009
**Attack scenario:** Attacker steals JWT token with 15-minute expiry; uses token after it expires
**Test approach:** Automated (submit request with expired token)
**Suggested tools:** Custom script; Burp Suite
**Expected outcome:**
- Valid token (within expiry window) accepted; request succeeds
- Expired token rejected with 401 Unauthorized
- Server does not accept token after expiry
- If long-lived token (e.g., 1 year), this test shows residual risk
**Verification:** Decode JWT; verify exp timestamp is checked server-side

#### TA-020: Session Fixation Attack
**Type:** Security Attack Test
**Abuse case(s):** ST-002, ST-012
**Attack scenario:** Attacker attempts to set victim's session token to a known value
**Test approach:** Manual browser test
**Expected outcome:**
- Attacker cannot set Set-Cookie header to force a known session ID
- Session tokens are randomly generated by server (not user-supplied)
- Each login generates a new unique token
- Tokens contain expiry and signature (JWT) preventing tampering
**Verification:** Check Set-Cookie response header; verify Secure and HttpOnly flags set

#### TA-021: Token Rotation on Refresh
**Type:** Security Attack Test
**Abuse case(s):** SAC-009
**Attack scenario:** Attacker steals refresh token; uses it to obtain new access tokens indefinitely
**Test approach:** Automated (submit same refresh token twice)
**Expected outcome:**
- First refresh request returns new access token + new refresh token
- Second refresh request with old refresh token fails (token rotated; old token invalidated)
- Reuse of old refresh token detected as potential breach; account flagged and additional MFA required
- Token family tracking: if old refresh token reused, all tokens in that family invalidated
**Verification:** Check token blacklist/invalidation; verify second refresh request fails

#### TA-022: SQL Injection via Task Search
**Type:** Security Attack Test
**Abuse case(s):** SAC-002
**Attack scenario:** Attacker submits search query: `GET /api/tasks?search='; DROP TABLE tasks; --`
**Test approach:** Automated (submit payloads)
**Suggested tools:** sqlmap, Burp Suite Scanner
**Expected outcome:**
- Query fails; tasks table not dropped (parameterized query prevents execution)
- Error message does not expose SQL syntax or schema: "Invalid search query" (generic)
- No data exfiltrated via UNION-based injection: `'; UNION SELECT email FROM users; --`
- Request logged for audit
**Verification:** Check database schema intact; verify no unauthorized table modifications

#### TA-023: Input Validation Bypass
**Type:** Security Attack Test
**Abuse case(s):** ST-003
**Attack scenario:** Attacker submits oversized input: task title = 100,000 characters
**Test approach:** Automated (submit large payload)
**Expected outcome:**
- Request rejected with 413 Payload Too Large or validation error
- Task title field has max length enforced (e.g., 255 chars)
- No buffer overflow or DoS via large input
- No task created with oversized data
**Verification:** Check database; task title length <= limit

#### TA-024: XSS via Task Title
**Type:** Security Attack Test
**Abuse case(s):** ST-002, ST-007 (if logged unsanitized)
**Attack scenario:** Attacker creates task with title = `<script>alert('XSS')</script>`
**Test approach:** Manual browser test or automated
**Expected outcome:**
- Task created (title accepted)
- When task displayed in web UI, JavaScript is not executed (output encoded)
- HTML response shows encoded title: `&lt;script&gt;alert('XSS')&lt;/script&gt;` or text content only
- API JSON response shows escaped quotes: `{"title": "<script>alert('XSS')<\/script>"}`
- No alert() popup appears; XSS prevented
**Verification:** Inspect HTML source; verify script tags encoded or stripped

#### TA-025: Unauthorized Resource Access via ID Manipulation
**Type:** Security Attack Test
**Abuse case(s):** SAC-003
**Attack scenario:** User A logged in; attempts to GET /api/tasks/999 (another user's task)
**Test approach:** Automated (iterate task IDs)
**Expected outcome:**
- User A can GET their own tasks (task_id 1-50)
- GET /api/tasks/999 returns 403 Forbidden (not 404; doesn't reveal whether task exists)
- Error message: "You do not have access to this resource"
- No task data leaked to unauthorized user
**Verification:** Check HTTP response status and content; verify no task data in response

#### TA-026: Privilege Escalation via Role Manipulation
**Type:** Security Attack Test
**Abuse case(s):** SAC-010
**Attack scenario:** Regular user attempts to change their role in JWT token from "user" to "admin"
**Test approach:** Automated (decode JWT, modify payload, re-encode)
**Expected outcome:**
- User cannot modify their JWT token (signature validation fails)
- Modified JWT rejected with 401 Unauthorized
- Server-side role lookup (from database, not from token claims alone) prevents escalation
- Even if user manipulates JWT, authorization check compares token.user_id to database role
**Verification:** Check role assignment logic; verify role is server-side, not token-side

#### TA-027: Unauthorized Admin Function Call
**Type:** Security Attack Test
**Abuse case(s):** SAC-010
**Attack scenario:** Regular user calls DELETE /api/admin/users/1 (delete another user)
**Test approach:** Automated (submit request with regular user token)
**Expected outcome:**
- Request returns 403 Forbidden or 404 Not Found (admin endpoint not listed in API docs)
- No user deleted
- Attempt logged in audit trail
- Alert triggered (unauthorized admin access attempt)
**Verification:** Check audit logs; verify user not deleted; check alert in monitoring

#### TA-028: CSRF Attack on Task Creation
**Type:** Security Attack Test
**Abuse case(s):** SAC-004
**Attack scenario:** Attacker's website contains hidden form that POSTs to task-app.com/api/tasks
**Test approach:** Manual browser test
**Expected outcome:**
- If CSRF token not implemented: form succeeds; unauthorized task created in victim's account
- With CSRF token: form lacks required token; request rejected with 403 Forbidden
- With SameSite=Strict: cookie not included in cross-site request; request fails
- No unauthorized task created
**Verification:** Check for task creation in victim account; verify CSRF token validation

#### TA-029: Email Enumeration via Registration Endpoint
**Type:** Security Attack Test
**Abuse case(s):** SAC-005
**Attack scenario:** Attacker submits 100 registration requests with common email addresses
**Test approach:** Automated (submit email list)
**Expected outcome:**
- Responses for existing emails vs. new emails are indistinguishable (both return 200 OK: "Check your email for verification")
- Attacker cannot determine which emails are registered
- Alternatively, if email already exists: "Email already registered" response should be identical to verification email sent, making enumeration impossible
- Rate limiting kicks in after 20 requests per minute per IP
**Verification:** Check response messages are uniform; verify no information leakage

#### TA-030: Rate Limiting Enforcement
**Type:** Security Attack Test
**Abuse case(s):** SAC-008, SAC-011
**Attack scenario:** Attacker submits 50 task creation requests in 1 minute from single user
**Test approach:** Automated (rapid requests)
**Suggested tools:** Apache Bench (ab), wrk, custom script
**Expected outcome:**
- Requests 1-100 succeed (per-minute limit = 100)
- Request 101 returns 429 Too Many Requests
- Retry-After header indicates when to retry (e.g., 60 seconds)
- Database insert count = 100 (not 101+)
- Database not overloaded; no performance degradation
**Verification:** Check response status codes; count database inserts

#### TA-031: Plaintext PII in Logs
**Type:** Security Attack Test
**Abuse case(s):** SAC-006
**Attack scenario:** Attacker gains access to application logs; searches for user emails
**Test approach:** Manual log inspection + automated grep
**Suggested tools:** grep, Log Aggregation UI (CloudWatch, Splunk)
**Expected outcome:**
- Logs do not contain plaintext email addresses, task descriptions, or passwords
- Logs contain only: timestamp, user_id (numeric), action type, resource_id, result
- Task descriptions truncated or redacted: `"description": "[REDACTED]"` or not logged at all
- Request/response bodies not logged in full; only metadata logged
- Sensitive query parameters redacted: `GET /api/tasks?search=[REDACTED]` (search value removed)
**Verification:** Search logs for known PII; verify absence

#### TA-032: Unencrypted Data at Rest
**Type:** Security Attack Test
**Abuse case(s):** SAC-007
**Attack scenario:** Attacker gains filesystem access to PostgreSQL data files (or RDS snapshot)
**Test approach:** Manual database inspection / AWS RDS snapshot analysis
**Expected outcome:**
- RDS encryption enabled; data files encrypted at rest (AES-256)
- Cannot read database by reading raw disk blocks
- Snapshot of RDS encrypted snapshot also encrypted
- Backup files encrypted (cannot read without KMS key)
**Verification:** Check RDS settings: storage_encrypted=true; verify KMS key in use

#### TA-033: Database Backup Encryption
**Type:** Security Attack Test
**Abuse case(s):** SAC-007, PT-011
**Attack scenario:** Attacker accesses RDS automated backup; attempts to restore it
**Test approach:** Manual AWS console verification
**Expected outcome:**
- Backup is encrypted; cannot restore without KMS key
- Key is in AWS account, with IAM policies restricting access
- Backup retention set to 30 days (old backups auto-deleted)
- Deletion of user data from live database should also trigger backup purge after 30 days
**Verification:** Check RDS backup encryption status; verify KMS key policy restricts access

#### TA-034: Insecure Mobile App Token Storage
**Type:** Security Attack Test
**Abuse case(s):** ST-009
**Attack scenario:** Attacker gains access to unlocked Android phone; reads SharedPreferences
**Test approach:** Manual phone inspection + Android Studio debugging
**Expected outcome:**
- Token not stored in plaintext in SharedPreferences
- Token stored in Android Keystore (encrypted, device-specific)
- App crashes or denies access if attempting to read Keystore without proper permissions
- Similarly, iOS app stores token in Keychain (not UserDefaults)
**Verification:** Inspect app data files; verify encryption in place

#### TA-035: Mobile App Cache Encryption
**Type:** Security Attack Test
**Abuse case(s):** ST-009
**Attack scenario:** Attacker examines cached API responses from mobile app
**Test approach:** Manual phone inspection
**Expected outcome:**
- Cached task data encrypted with device-specific key
- Cache cleared on app logout; no residual data left on device
- Cache does not persist if app is uninstalled/reinstalled
**Verification:** Inspect app cache directory (/data/data/app on Android); verify encryption

#### TA-036: TOTP-based MFA Bypass Attempt
**Type:** Security Attack Test
**Abuse case(s):** ST-010
**Attack scenario:** Attacker attempts to bypass TOTP by submitting invalid codes repeatedly
**Test approach:** Automated (submit 100 random 6-digit codes)
**Expected outcome:**
- Wrong codes rejected; no account access
- Rate limiting on MFA attempts (after 5 wrong codes, lockout for 15 mins)
- No brute force possible (1 million possible codes; rate limiting + time window makes brute force impractical)
- Correct code (from authenticator) accepted; session established
**Verification:** Verify failed login attempts logged; account locked state verified

#### TA-037: SMS MFA Interception
**Type:** Security Attack Test
**Abuse case(s):** ST-010
**Attack scenario:** Attacker intercepts SMS with MFA code
**Test approach:** Manual test (simulated)
**Expected outcome:**
- SMS-based MFA is less secure than TOTP; acceptable as secondary option
- Recommend TOTP/FIDO2 as primary
- If SMS: code expires after 5 minutes; not valid after timeout
- Code one-time use only; reuse fails
**Verification:** Log SMS send/receive timestamps; verify expiry and one-time use

#### TA-038: Global Rate Limiting (Distributed Attack)
**Type:** Security Attack Test
**Abuse case(s):** SAC-008
**Attack scenario:** Attacker from 100 different IPs each submits 50 task creation requests
**Test approach:** Automated (distributed)
**Expected outcome:**
- Each IP rate limited independently (5,000 requests across 100 IPs possible)
- Global rate limiter also active (max 1,000 tasks per minute across all IPs)
- 101st global request returns 429 Too Many Requests
- Database not overloaded; performance maintained
**Verification:** Monitor request count per IP + global; verify 429 responses

---

### 9.3 Privacy Verification Tests

#### TA-048: Privacy Notice Present and Comprehensive
**Type:** Privacy Verification
**Requirement(s):** PRV-001, COMP-001
**Scenario:** Verify privacy notice published and covers all required elements (data categories, purposes, retention, rights, contact)
**Test approach:** Manual audit
**Expected outcome:**
- Privacy notice accessible at signup page (link)
- Notice covers: (a) data types collected, (b) purposes, (c) lawful basis, (d) retention policy, (e) recipients, (f) user rights (access, deletion, portability), (g) contact for privacy inquiries, (h) cookie use (if applicable)
- Notice in plain, understandable language (not legal jargon)
- Notice versioned (v1.0, effective date)
- User acknowledges/reads notice before registering
**Verification:** Lawyer review of privacy notice; checkoff against GDPR Article 13 checklist

#### TA-049: Data Minimization Audit
**Type:** Privacy Verification
**Requirement(s):** PRV-002
**Scenario:** Verify that only necessary data is collected for each feature
**Test approach:** Manual code review + data audit
**Expected outcome:**
- Feature: Task Creation → collected data: task_title, description, due_date, assignee_id, project_id (necessary); NOT collected: user's device ID, browsing history, location (unnecessary)
- Feature: Email Notifications → collected: assignee_email, task_id (necessary); NOT collected: browsing behavior, other users' data (unnecessary)
- Feature: User Registration → collected: email, password_hash (necessary); NOT collected: phone number, address, credit card (unless asked for separate purpose)
- Database schema shows no extra unnecessary fields
**Verification:** Database schema audit; code review of data collection logic

#### TA-050: Email Notification Consent — Signup Flow
**Type:** Privacy Verification
**Requirement(s):** PRV-003
**Scenario:** Verify that email notification consent is explicitly requested during signup
**Test approach:** Manual test (walk through signup)
**Expected outcome:**
- Signup form includes checkbox: "☐ Send me email notifications when tasks are assigned or due soon"
- Checkbox is unchecked by default (opt-in, not opt-out)
- Clear label explaining what notifications user will receive
- User can proceed without checking box (notifications disabled is acceptable)
- Database records consent state: email_notifications_enabled=true/false + consent_timestamp
**Verification:** Signup form inspection; database record check

#### TA-051: Email Notification Consent — Unsubscribe Link
**Type:** Privacy Verification
**Requirement(s):** PRV-003, PRV-004
**Scenario:** Verify that every notification email includes unsubscribe/preference link
**Test approach:** Manual email inspection
**Expected outcome:**
- Every email notification includes link: "Manage preferences" or "Unsubscribe"
- Link points to account settings page where user can disable notifications
- Clicking link logs user in (or requires login) and displays notification settings
- User can toggle notifications on/off; change is saved immediately
- No new notifications sent after user disables
**Verification:** Email template inspection; test unsubscribe flow

#### TA-052: Minimize Email Content — No Sensitive Data in Emails
**Type:** Privacy Verification
**Requirement(s):** PRV-004
**Scenario:** Verify that task notification emails do not contain full task details
**Test approach:** Manual email inspection
**Expected outcome:**
- Email subject: "New task assigned to you" (generic, no task content)
- Email body: "You have a new task. View details: [link]" (task content not in email body)
- Email metadata (to/from, date) not exposing user activity
- No clickable link in email revealing full task data in URL
- Email service provider cannot infer task content from email
**Verification:** Email capture; check email headers and body content

#### TA-053: Data Subject Rights — Download My Data
**Type:** Privacy Verification
**Requirement(s):** PRV-006
**Scenario:** Verify that users can export their data in standard format
**Test approach:** Manual test
**Expected outcome:**
- Account settings page has "Download My Data" button
- Click button → system exports user data as JSON file (user profile, projects, tasks, activity logs)
- File includes all data subject has access to; is machine-readable (JSON format)
- Export completes within 30 days (GDPR requirement)
- File is delivered securely (HTTPS, access-controlled download link)
**Verification:** Manual download; inspect exported JSON; verify completeness

#### TA-054: Data Subject Rights — Delete My Account
**Type:** Privacy Verification
**Requirement(s):** PRV-006, PRV-007
**Scenario:** Verify that users can delete their account and all associated data is removed
**Test approach:** Manual test + database audit
**Expected outcome:**
- Account settings page has "Delete My Account" button with strong warning
- Requires password re-entry and email confirmation (prevents accidental deletion)
- On deletion: (a) user record deleted from users table, (b) projects cascade-deleted, (c) tasks cascade-deleted, (d) activity logs deleted, (e) backup purge scheduled (30 days), (f) user data removed from backups after 30 days
- After 30 days, verify no traces of user data in backups (random sampling)
- User receives confirmation email: "Account deleted. Your data will be permanently removed from our backups within 30 days."
**Verification:** Delete test account; inspect database before/after; audit backups at day 31

#### TA-055: Data Subject Rights — Data Portability
**Type:** Privacy Verification
**Requirement(s):** PRV-006
**Scenario:** Verify that exported data is in portable format, usable in other systems
**Test approach:** Manual test
**Expected outcome:**
- Exported JSON follows standard schema (not proprietary format)
- JSON includes: user profile, projects, tasks, with standard field names (email, title, description, created_at, etc.)
- Data can be imported into another task management system (or analyzed with standard tools)
- No vendor lock-in; data portability respected
**Verification:** JSON schema review; test import into another system (if applicable)

#### TA-056: Data Retention Policy — Execution
**Type:** Privacy Verification
**Requirement(s):** PRV-007
**Scenario:** Verify that documented retention policy is actually enforced
**Test approach:** Manual audit + job verification
**Expected outcome:**
- Retention policy documented: "Active data retained while account active. Deleted user data retained 30 days, then permanently deleted. Audit logs retained 1 year, then deleted."
- Deletion job scheduled (runs daily at 2 AM UTC)
- Job queries deletion_queue table: selects user_ids with deletion_requested_date > today - 30 days
- Job deletes user records, cascades to projects/tasks, purges from backups
- Audit log entries > 1 year old deleted
- Job logs show successful deletion (e.g., "Deleted 5 users and 243 tasks; purged 3 backups")
- Random audit: query old data (> 30 days deleted, > 1 year logs) and verify absence
**Verification:** Check deletion job logs; query database for old data; verify absence

#### TA-057: Backup Retention Compliance
**Type:** Privacy Verification
**Requirement(s):** PRV-007, PRV-010
**Scenario:** Verify that backup retention policy matches data retention (30 days)
**Test approach:** AWS RDS audit
**Expected outcome:**
- RDS backup retention set to 30 days
- Backups older than 30 days automatically deleted by AWS
- User deletes account on day 1; backup created on day 0 still retained (< 30 days)
- Same backup deleted on day 31 (after 30-day retention window)
- User data removed from live database immediately (day 1), but retained in backup until day 31 (acceptable compliance window)
- All backups created after user deletion are free of that user's data
**Verification:** AWS RDS settings audit; check backup deletion dates

#### TA-058: DPIA Documentation
**Type:** Privacy Verification
**Requirement(s):** PRV-008
**Scenario:** Verify that DPIA has been conducted and documented
**Test approach:** Manual audit (document review)
**Expected outcome:**
- DPIA report exists, dated, signed by Privacy Officer
- Report identifies high-risk processing: (a) task content (sensitive personal data), (b) email notifications (third-party sharing), (c) activity logging (non-repudiation)
- Report documents: risks, mitigations, residual risks, conclusion
- Example: "Risk: User activity profile created without consent. Mitigation: Data minimization policy, explicit privacy notice. Residual Risk: User may still choose to use app and generate activity history. Conclusion: Risk acceptable with mitigations."
- DPIA reviewed annually or when practices change
**Verification:** Lawyer/DPO review of DPIA document; check for completeness

#### TA-059: DPA with Email Service Provider
**Type:** Privacy Verification
**Requirement(s):** PRV-009, COMP-001
**Scenario:** Verify that DPA is in place with SendGrid/SES or equivalent
**Test approach:** Manual audit (contract review)
**Expected outcome:**
- DPA signed and dated; covers app and email service provider
- DPA specifies: (a) scope of processing (what data, what purpose), (b) security measures (encryption, access controls), (c) data subject rights (requests forwarded to app), (d) sub-processors (list of third parties), (e) data deletion on contract termination, (f) audit rights
- For US-based ESP: DPA includes Standard Contractual Clauses (SCCs) ensuring EU data protection
- DPA stored in secure location accessible to compliance team
- DPA reviewed annually; updated when practices change
**Verification:** Legal review of DPA; check for completeness vs. GDPR Article 28; verify signature

---

### 9.4 Penetration Testing Scenarios

#### TA-062: End-to-End Breach Scenario — Account Compromise & Data Exfiltration
**Type:** Penetration Test Scenario
**Scope:** Full application stack (web UI, API, database, email service)
**Objectives:**
1. Compromise a user account via multiple attack vectors (brute force, phishing simulation, social engineering)
2. Exfiltrate user data (tasks, collaborator information)
3. Escalate to admin privileges if possible
4. Persist access (maintain backdoor or long-lived token)
5. Cover tracks (delete audit logs or hide activity)
6. Trigger breach detection and verify incident response
**Key abuse cases to validate:** SAC-001, SAC-002, SAC-003, SAC-010, SAC-007
**Out of scope:**
- Physical security (data center access)
- Supply chain attacks (compromised npm packages, malicious devops)
- Social engineering of employees (beyond simulation)
- Third-party integrations not in scope for this test
**Success criteria:**
- Attacker gains unauthorized access to at least one user account
- Attacker exfiltrates some user data
- Breach detected by monitoring system (alert triggered within 5 minutes)
- Incident response activated (on-call team paged)
- Organization notifies DPA within 72 hours (if applicable)

#### TA-063: Privacy Abuse Scenario — Unauthorized Data Use & Profiling
**Type:** Penetration Test Scenario
**Scope:** Data handling, privacy controls, third-party processor interactions
**Objectives:**
1. Identify if task data is being used for unauthorized purposes (analytics, targeting, resale)
2. Test if user data is properly anonymized (attempt re-identification)
3. Verify data subject rights are functional (attempt to export, delete, port data)
4. Check if third parties (email service provider, analytics platform) have unauthorized access
5. Verify compliance with retention policy (test if deleted data actually removed)
**Key abuse cases to validate:** PAC-001, PAC-002, PAC-006, PAC-007, PAC-010
**Out of scope:**
- Political/ideological critique of business model
- Testing advertiser access to data
**Success criteria:**
- Confirm no secondary use of task data without consent
- Verify deleted data actually removed (not just soft-deleted)
- Confirm users can exercise all GDPR rights (access, deletion, portability)
- Verify ESP access limited to agreed scope (no unauthorized processing)
- Confirm retention policy enforced (old data purged on schedule)

---

## Appendix A: STRIDE Reference

**STRIDE** is a threat modeling framework covering six security threat categories:

| Category | Definition | Example in Task App |
|----------|-----------|-------------------|
| **S**poofing | Attacker pretends to be someone else (impersonates user or system) | Attacker logs in as victim using brute-forced password |
| **T**ampering | Attacker modifies data in transit or at rest | Attacker modifies task content via SQL injection |
| **R**epudiation | Attacker denies performing an action; system has no proof | Attacker deletes tasks, then claims they didn't; no audit trail |
| **I**nformation Disclosure | Attacker gains unauthorized access to sensitive data | Attacker reads all tasks via broken access control |
| **D**enial of Service | Attacker makes system unavailable to legitimate users | Attacker floods API with requests, crashing service |
| **E**levation of Privilege | Attacker gains unauthorized elevated permissions | Regular user calls admin endpoint, gets admin access |

---

## Appendix B: LINDDUN Reference

**LINDDUN** is a privacy threat modeling framework covering seven threat categories:

| Category | Definition | Example in Task App |
|----------|-----------|-------------------|
| **L**inkability | Attacker links data/actions to an individual across contexts | Attacker correlates task metadata to identify user behavior patterns |
| **I**dentifiability | Attacker re-identifies supposedly anonymous person | Attacker uses task descriptions to re-identify anonymized user |
| **N**on-repudiation | User unable to deny action (permanent record created) | User's task creation logged permanently; user feels surveilled |
| **D**etectability | Attacker detects existence of data about a person | Email service provider detects user activity from notification frequency |
| **D**isclosure | Personal data exposed beyond intended scope | Email addresses exposed in API responses or logs |
| **U**nawareness | User doesn't know what data is collected/used | User unaware of activity tracking; no privacy notice |
| **N**on-compliance | System fails to meet legal/regulatory privacy obligations | No GDPR Article 17 right-to-erasure implementation |

---

## Appendix C: OWASP Top 10 (2021) Quick Reference

| Rank | Category | Risk | Task App Relevance |
|------|----------|------|-------------------|
| **A01** | Broken Access Control | User A accesses User B's data | ST-004, SAC-003 (insufficient authorization) |
| **A02** | Cryptographic Failures | Sensitive data exposed (not encrypted) | ST-007, ST-008 (plaintext storage) |
| **A03** | Injection | SQL injection, command injection | ST-003, SAC-002 (SQL injection in search) |
| **A04** | Insecure Design | Missing threat modeling, privacy by design | PT-009 (no DPIA), PRV-002 (no data minimization) |
| **A05** | Security Misconfiguration | Default configs, unnecessary services enabled | ST-008 (RDS encryption not enabled) |
| **A06** | Vulnerable & Outdated Components | Unpatched dependencies | SEC-016 (dependency scanning) |
| **A07** | Identification & Authentication Failures | Weak password, no MFA, session fixation | ST-001, ST-010, ST-012 (weak auth) |
| **A08** | Software & Data Integrity Failures | Unsigned updates, malicious dependencies | SEC-016 (supply chain) |
| **A09** | Logging & Monitoring Failures | Insufficient logging, no alerting | ST-014, SAC-006 (no audit logging) |
| **A10** | Server-Side Request Forgery (SSRF) | Application makes attacker-controlled requests | Not directly applicable (task app doesn't fetch external URLs) |

---

## Appendix D: GDPR Privacy by Design Principles

| Principle | Definition | Task App Implementation |
|-----------|-----------|--------------------------|
| **1. Proactive, Not Reactive** | Privacy risks identified and mitigated before issues occur | Conduct DPIA for high-risk processing; privacy requirements in sprint planning |
| **2. Privacy as Default** | Default settings should be privacy-protective; users must opt-in to less private options | Email notifications opt-in (unchecked by default); no automatic profiling |
| **3. Privacy Embedded into Design** | Privacy technical and organizational measures built into architecture from start | Encryption at rest/transit, access controls, minimal data collection designed in |
| **4. Full Functionality** | System must be fully functional without requiring less-private alternatives | Users can use app fully without email notifications; can disable profiling |
| **5. End-to-End Security & Data Subject Protection** | Entire processing lifecycle protected; users' rights supported | Encryption, access controls, audit logging, data subject rights infrastructure |
| **6. Visibility & Transparency** | Users informed about what data is collected and how it's used | Privacy notice at signup, clear consent flows, transparency about third parties |
| **7. Respect for User Privacy** | User autonomy and choice respected; system supports privacy preferences | Right to erasure, data portability, consent withdrawal, user preference controls |

---

## Executive Summary (Extended)

This Security and Privacy by Design analysis examined a greenfield SaaS task management application serving multi-tenant user base with cloud deployment (AWS, PostgreSQL). The analysis applied four complementary frameworks (STRIDE, LINDDUN, OWASP, GDPR) to identify and document security and privacy risks, threats, abuse cases, and required controls.

**Security Risk Profile:**
The application handles user authentication, multi-user collaboration, sensitive task content, and externally-facing APIs. Without hardened security controls, the attack surface exposes critical vulnerabilities in authentication (brute force, weak passwords, no MFA), authorization (broken access control allowing cross-tenant data access), injection (SQL injection in search), data protection (plaintext storage, unencrypted transit), and session management (long-lived tokens, session hijacking). The most severe risks are unauthorized data access (multi-tenant isolation failure), privilege escalation (admin endpoint access), and data exfiltration via database compromise.

**Priority Actions for Security:**
1. Implement role-based access control (RBAC) with least privilege authorization checks on all resource endpoints — this is critical to prevent users from accessing each other's data
2. Enforce strong authentication: minimum 12-character passwords, rate limiting on login attempts, account lockout, MFA support
3. Require parameterized SQL queries and strict input validation — SQL injection in a multi-user system enables complete data breach
4. Encrypt all data: in transit (TLS 1.3), at rest (AES-256 for database and backups), with secrets stored in AWS Secrets Manager
5. Implement comprehensive audit logging with alerting for suspicious patterns (failed logins, bulk deletions, admin access attempts)

**Privacy Risk Profile:**
The application collects personally identifiable information (emails, task content, activity metadata) without clear user awareness or consent. Risks include uncontrolled behavior profiling, indefinite data retention, inadequate data subject rights infrastructure, and non-compliance with GDPR obligations (Articles 5, 6, 13-17, 25, 28, 32-35). Email notifications involve third-party data sharing (to email service provider) without documented Data Processing Agreements. Activity logging creates non-repudiation that may harm user privacy. Backup data lacks retention limits and encryption.

**Priority Actions for Privacy:**
1. Publish comprehensive Privacy Notice explaining data collection, purposes, retention, recipients, and user rights — required by GDPR Articles 13/14
2. Obtain explicit user consent for email notifications at signup with easy opt-out — required by GDPR Article 7
3. Implement data subject rights infrastructure: download/delete/portability features enabling users to exercise GDPR rights (Articles 15-21)
4. Define and enforce data retention policy (30 days for deleted user data, 1 year for audit logs, 30 days for backups) — required by GDPR Article 5(1)(e)
5. Establish Data Processing Agreement with email service provider; ensure data deletion on contract termination — required by GDPR Article 28

**Regulatory & Compliance Exposure:**
If the application processes data of EU residents (likely for a SaaS app with EU user base), full GDPR compliance is mandatory. Common violation fines: 2-4% of global revenue for data minimization/retention violations, up to 4% for consent/transparency violations. Breach notification obligations (Articles 33/34) trigger DPA notification within 72 hours if 1000+ users affected or sensitive data involved. Data subject rights are enforceable (Articles 15-21); failure to respond within 30 days triggers penalties. SOC 2 Type II audit (common B2B SaaS requirement) will audit security controls; missing controls delay sales/partnership opportunities.

**Test Coverage & Verification:**
The Security Requirements Traceability Matrix (SRTM, Section 8) links 40+ requirements to analysis artifacts and test artifacts. Phase 9 defines 71 test artifacts covering functional security tests (token rotation, authorization checks, SQL injection filtering), security attack tests (brute force, privilege escalation, data exfiltration), privacy verification tests (consent, retention policy enforcement, DPIA documentation), and penetration testing scenarios (end-to-end breach simulation). All high-impact security and privacy requirements have associated tests, ensuring controls are verified before release.

**Next Steps:**
1. Prioritize security controls in next sprint: RBAC, strong passwords, rate limiting, encryption
2. Assign privacy ownership (DPO or privacy engineer) to drive privacy implementation and compliance
3. Schedule DPIA workshop (week 1-2) to document risks and mitigations
4. Establish Data Processing Agreement with email service provider (week 1)
5. Design user consent flows and privacy notice (week 2-3)
6. Implement security controls (weeks 2-6): authentication, authorization, encryption, audit logging
7. Add test cases from TA-XXX list to QA test plan; integrate into CI/CD pipeline
8. Plan security review before alpha testing; conduct penetration test before beta release
9. Coordinate with legal/compliance teams on GDPR obligations and SOC 2 readiness

---

**Analysis Date:** 2026-03-30
**Status:** Complete (v1.0)
**Next Review:** Upon significant architectural changes or quarterly (2026-06-30)



