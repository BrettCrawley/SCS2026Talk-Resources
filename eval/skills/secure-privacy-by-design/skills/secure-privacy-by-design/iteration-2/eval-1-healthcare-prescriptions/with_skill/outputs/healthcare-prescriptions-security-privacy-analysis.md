# Security and Privacy by Design Analysis: Online Prescription Refill Module
**Date:** 2026-03-31
**Version:** 1.0
**Frameworks:** STRIDE · LINDDUN · OWASP Top 10 · GDPR / Privacy by Design · NHS Digital Standards
**Regulatory scope:** GDPR · UK NHS Digital Standards · NIS2 Directive (if essential service) · Data Protection Act 2018

---

## Executive Summary

This analysis covers the design of a new online prescription refill feature within a UK-based NHS healthcare portal. The module allows authenticated patients to view active prescriptions (fetched from the EHR via FHIR API) and request refills, which are routed to GP queues for approval/decline with optional notes. Patients receive email or SMS notifications when requests are actioned.

**Most significant security risks:**
1. **Authorisation bypass (High/High)** — Patients could access other patients' prescriptions or request refills on their behalf if the GP-to-patient mapping and row-level access controls are not correctly enforced at the FHIR API boundary.
2. **FHIR API injection (High/High)** — Malicious input (prescription ID, patient identifier) passed to the EHR system could lead to SQL injection, command injection, or enumeration attacks if the FHIR client does not properly validate/sanitise inputs.
3. **Notification interception (Medium/High)** — SMS/email notifications containing prescription or request details could be intercepted, leaked, or delivered to wrong recipients if transport is unencrypted or contact details are not validated.

**Most significant privacy risks:**
1. **Linkability across systems (High)** — Patient activity on the portal (prescription requests, dates, timing) combined with metadata from notifications creates a persistent link to the patient's real identity across systems and time, enabling profiling by healthcare staff or external actors.
2. **Non-compliance with data retention (High)** — Refill requests, GP notes, and audit logs must be retained for NHS record-keeping but also minimised for GDPR; if retention and deletion policies are not defined upfront, the system will accumulate sensitive data indefinitely.
3. **Disclosure through GP notes (Medium/High)** — GPs may inadvertently embed sensitive personal information (family details, mental health flags, lifestyle) in decline notes; if these notes are not redacted before patient notification or logged inappropriately, GDPR disclosure principles are violated.

**Top 5 priorities for engineering:**
1. **Implement row-level access control (RLAC) in the prescription query** — Ensure FHIR API calls pass the authenticated patient's ID and enforce server-side filtering; never trust client-side filtering.
2. **Define data minimisation and retention policy** — Specify exactly what is logged, for how long, and the deletion process; align with NHS records retention schedules and GDPR data minimisation.
3. **Validate and sanitise all EHR inputs** — Treat FHIR API responses as untrusted; implement strict schema validation and output encoding before displaying to users.
4. **Implement secure notification routing** — Ensure SMS/email delivery is authenticated, encrypted in transit (TLS 1.3+), and that contact details are verified before first use and re-validated on change.
5. **Establish audit logging for healthcare data access** — Log all read/write access to prescriptions and refill requests with user ID, action, timestamp, and reason; this is both a security control (detect abuse) and a GDPR transparency requirement (data subject access requests).

---

## 1. Assumptions and Context

**Assumptions made (in lieu of live questions):**

1. **Architecture:** The portal is a web application (pure SaaS) with no downloadable client software, installed mobile app, or embedded firmware. It runs in the UK on cloud infrastructure (AWS, Azure, or NHS-compliant hosting).

2. **Deployment scope:** Deployed in the UK, but may receive requests from EU patients (e.g., UK citizens working abroad, patients on holiday). GDPR applies regardless of patient location.

3. **NHS login integration:** The portal already has NHS login (OAuth2/OIDC) integrated, providing strong authentication (2FA at NHS level). This analysis assumes authentication is already secure and focuses on the refill module's authorisation and data handling.

4. **EHR integration:** The existing EHR system exposes a FHIR API (HL7 FHIR STU3 or R4). The portal calls this API to fetch prescriptions; we assume the EHR enforces its own access controls, but the portal must add a second layer of access control.

5. **Notification mechanism:** Notifications (approval/decline) are sent via email or SMS. The portal maintains a patient contact preference record and has access to email/phone number from NHS login.

6. **Multi-tenancy:** Assume the portal is single-tenant (one UK health authority or NHS trust) or has strong multi-tenant isolation if deployed regionally.

7. **Compliance baseline:** The portal is subject to GDPR, Data Protection Act 2018, NHS Digital Data Security and Protection Toolkit (DSPT) standards, and potentially NIS2 (if operated by an NHS trust or essential service provider).

8. **CRA scope:** CRA does **not** apply—the product is pure SaaS with no downloadable or embedded software components. No CRA obligations (SBOM, incident reporting to ENISA) are required.

9. **NIS2 applicability:** If the portal operator is an NHS trust or classified as an "essential entity" under NIS2, the operator must comply with NIS2 risk management, incident reporting (24h early warning, 72h full notification), and supply chain security requirements. We flag this for legal/compliance review but assume NIS2 obligations apply at the operational level, not specific to this module's design (except where they affect data security and availability).

10. **PSTI scope:** PSTI does **not** apply—the product is not a consumer connectable device (IoT).

---

## 2. Requirements Classification and Gap Analysis

### 2.1 Original Requirements (Classified)

#### Functional Requirements (FR)
| ID | Requirement | Details |
|---|---|---|
| **FR-001** | Patients view active prescriptions | Retrieve current prescriptions from EHR (FHIR API); display medication name, dosage, date issued, date expires, dispensary/pharmacy |
| **FR-002** | Patients submit refill request | Patient selects a prescription and submits a request; request includes patient ID, prescription ID, optional notes |
| **FR-003** | GPs receive and review requests | Requests appear in GP task queue; GP sees patient details, prescription, request date, notes |
| **FR-004** | GPs approve or decline requests | GP action creates approval or decline record; decline may include GP notes explaining reason |
| **FR-005** | Patients receive notifications | Email or SMS sent to patient when request is approved or declined; notification includes action taken and (if declined) the reason |

#### Security Non-Functional Requirements (SEC)
| ID | Requirement | Details |
|---|---|---|
| **SEC-001** | Authentication | NHS login integration already in place (inherited requirement) |
| **SEC-002** | HTTPS/TLS encryption | All data in transit must use TLS 1.3+ |

#### Privacy Non-Functional Requirements (PRV)
| ID | Requirement | Details |
|---|---|---|
| **PRV-001** | GDPR compliance | Process personal data (NHS number, DOB, contact) only for lawful basis; implement data subject rights (access, erasure, portability) |

#### Performance Non-Functional Requirements (PERF)
| ID | Requirement | Details |
|---|---|---|
| **PERF-001** | Prescription list load time | Fetch and render prescription list within 2 seconds for typical patient |
| **PERF-002** | Notification delivery | Send notification within 5 minutes of GP action |

#### Compliance/Regulatory Requirements (COMP)
| ID | Requirement | Details |
|---|---|---|
| **COMP-001** | NHS Digital DSPT | Implement controls as per NHS Digital Data Security and Protection Toolkit baseline |

### 2.2 Gap Analysis

**Critical security gaps identified:**

- **SEC-003 [NEW]:** Row-level access control (RLAC) for prescriptions — Currently undefined. Patients must only see their own prescriptions; GPs must only see requests for patients in their care.
- **SEC-004 [NEW]:** Input validation and sanitisation — No requirement to validate FHIR API inputs/outputs or sanitise user submissions before forwarding to EHR or displaying.
- **SEC-005 [NEW]:** Session management and token handling — No explicit requirement for NHS login token validation, token expiry, logout, or session revocation.
- **SEC-006 [NEW]:** Rate limiting and brute force protection — No explicit requirement to rate-limit refill submissions or API calls (could enable DoS).
- **SEC-007 [NEW]:** Secrets management — No requirement for secure storage of EHR API credentials, notification service credentials.
- **SEC-008 [NEW]:** Error handling — No requirement to avoid leaking sensitive data in error messages (e.g., "Patient NHS number not found" vs. "Request failed").
- **SEC-009 [NEW]:** Audit logging — No explicit requirement to log access to prescriptions or refill requests.

**Critical privacy gaps identified:**

- **PRV-002 [NEW]:** Lawful basis — Not defined. Is the refill feature opt-in or opt-out? Is consent required, or is the lawful basis "contract" (patient-NHS relationship)?
- **PRV-003 [NEW]:** Data minimisation — What data is logged? Are timestamps, IP addresses, GP action details all necessary? Scope collection.
- **PRV-004 [NEW]:** Data retention and deletion — No policy. How long must refill requests be kept for audit? When are they deleted? Who deletes them?
- **PRV-005 [NEW]:** Consent for notifications — Is prior consent required before sending SMS/email? GDPR Article 7 requires proof of consent; PECR (UK marketing rules) require explicit opt-in for electronic marketing.
- **PRV-006 [NEW]:** Data subject rights — How will patients exercise their GDPR rights (access, erasure, portability, rectification) for refill request data and GP notes?
- **PRV-007 [NEW]:** Third-party data sharing — Are notifications sent via a third-party SMS/email provider? If yes, require data processing agreement (DPA).
- **PRV-008 [NEW]:** Privacy notice — Must inform patients what data is collected, how it's used, who has access, and how long it's kept.

**Regulatory compliance gaps:**

- **COMP-002 [NEW]:** Data Protection Impact Assessment (DPIA) — Processing patient healthcare data with a GP decision (decline reason) may require a DPIA under GDPR Article 35.
- **COMP-003 [NEW]:** Breach detection and reporting — If a refill request or GP note is disclosed/exposed, NHS Digital Data Security Toolkit and GDPR require incident reporting within 72 hours.
- **COMP-004 [NEW]:** Supply chain security — If using third-party SMS/email providers, conduct supplier security assessment and sign a data processing agreement.

**Performance considerations:**

- PERF requirements are clear; no gaps.

---

## 3. Use Cases

### UC-001: Patient Views Prescriptions
**Actor:** Authenticated patient
**Goal:** Retrieve and display current active prescriptions
**Preconditions:**
- Patient is authenticated via NHS login
- Patient's NHS number is known to the portal
- EHR system contains active prescriptions for the patient

**Main Flow:**
1. Patient clicks "View Prescriptions" in the portal
2. Portal issues authenticated request to EHR FHIR API: `GET /Patient/{patientId}/MedicationRequest`
3. EHR API returns list of active MedicationRequest resources (medication, dosage, date issued, expiry)
4. Portal displays prescriptions in a table/list (medication name, dosage, dispensary, issue/expiry dates)
5. For each prescription, portal shows "Request Refill" button

**Postconditions:**
- Patient sees their current prescriptions
- Patient can identify which prescriptions are eligible for refill
- Access is logged (who viewed what, when)

**Data involved:**
- Patient NHS number (identifier)
- MedicationRequest resources (medication details, dates)
- Audit log entry (patient ID, timestamp, action: "view prescriptions")

**Trust boundary crossings:**
1. Portal ↔ EHR API: Patient context (NHS number) is passed; EHR must enforce access control
2. Portal ↔ Patient browser: Prescription data is returned in HTTPS response; must not leak other patients' data

---

### UC-002: Patient Requests Refill
**Actor:** Authenticated patient
**Goal:** Submit a refill request for a specific prescription
**Preconditions:**
- Patient is authenticated
- Patient has viewed prescriptions (UC-001)
- Patient has selected a specific prescription to refill

**Main Flow:**
1. Patient clicks "Request Refill" on a prescription
2. Portal opens refill request form (optional notes from patient)
3. Patient submits form; portal validates input
4. Portal creates RefillRequest record in database: {patientId, prescriptionId, notes, status="pending", createdAt, GP assigned to patient}
5. Portal assigns request to the patient's registered GP (from NHS directory or existing portal mapping)
6. Portal inserts notification task: "Send approval/decline notification to patient when status changes"

**Postconditions:**
- RefillRequest record is created in database
- Request appears in assigned GP's task queue
- Audit log records: patient ID, prescription ID, refill request created, timestamp

**Data involved:**
- PatientId, PrescriptionId, RefillRequest (notes, status, timestamps)
- GP assignment (patient ↔ GP mapping)
- Audit log entry

**Trust boundary crossings:**
1. Patient browser → Portal API: Prescription ID and notes are submitted; portal must validate that prescription exists and belongs to the patient
2. Portal database: RefillRequest is stored; must be encrypted at rest and access-controlled

---

### UC-003: GP Reviews and Actions Refill Request
**Actor:** Authenticated GP/healthcare staff
**Goal:** View pending refill requests and approve or decline with optional notes
**Preconditions:**
- GP is authenticated via NHS login
- GP has access to their patient task queue
- One or more RefillRequest records exist with status="pending" for this GP's patients

**Main Flow:**
1. GP logs into portal and views task queue
2. Portal retrieves all RefillRequest records where status="pending" AND assigned_gp=authenticated_gp (or assigned_gp's team)
3. GP selects a request; portal displays:
   - Patient name, NHS number
   - Prescription details (medication, dosage, last dispensed date)
   - Refill request date
   - Patient notes (if any)
4. GP approves or declines:
   - **If approve:** GP submits approval; portal sets status="approved", creates approval timestamp, creates notification task
   - **If decline:** GP submits decline with optional notes; portal sets status="declined", stores GP notes, creates notification task
5. Portal schedules notification task: send email/SMS to patient with action and (if declined) reason

**Postconditions:**
- RefillRequest status is updated (approved / declined)
- GP action is recorded with timestamp
- Notification task is created and queued
- Audit log records: GP ID, request ID, action, notes (if any), timestamp

**Data involved:**
- RefillRequest (prescription details, patient context)
- GP notes (decline reason — potentially sensitive)
- Notification metadata (recipient contact, action)
- Audit log entry

**Trust boundary crossings:**
1. Portal database ↔ GP: GP retrieves patient refill requests; portal must enforce that GP can only see requests for patients in their care
2. Portal → Notification service: Patient contact details and request outcome are passed to SMS/email provider; must use authenticated/encrypted channel
3. Portal → Audit log: All actions recorded; audit log must be tamper-proof and immutable

---

### UC-004: Patient Receives Notification
**Actor:** Notification service (background process), Patient (recipient)
**Goal:** Deliver email or SMS notification to patient about refill request outcome
**Preconditions:**
- RefillRequest status has been updated by a GP (approved or declined)
- Notification task is queued
- Patient has a verified email address or phone number in the portal

**Main Flow:**
1. Notification service polls/listens for pending notification tasks
2. For a RefillRequest notification:
   - Retrieves patient contact preference (email or SMS)
   - Retrieves patient contact detail (email or phone)
   - Composes message: "Your refill request for [medication] has been [approved/declined]"
   - If declined, includes GP reason (if provided)
   - Sends via email or SMS provider (third-party service)
3. Notification is logged with delivery timestamp
4. If delivery fails, task is retried (exponential backoff)

**Postconditions:**
- Patient receives notification in preferred channel
- Notification log entry is created
- Portal updates RefillRequest: notification_sent_at, notification_status="delivered"

**Data involved:**
- RefillRequest (outcome, GP notes)
- Patient contact details (email, phone)
- Notification content and delivery status
- Audit log entry

**Trust boundary crossings:**
1. Portal → SMS/Email provider: Patient contact and message content are sent; must use authenticated API and TLS encryption
2. Notification provider → Patient: SMS/Email may be intercepted or logged by provider; data minimisation (not sending unnecessary details) is important

---

### UC-005: Patient Exercises Data Subject Rights (Access)
**Actor:** Authenticated patient
**Goal:** Request and download all personal data held about them related to refill requests
**Preconditions:**
- Patient submits a data access request (GDPR Article 15)
- Portal has a data export function or manual process

**Main Flow:**
1. Patient submits data access request via portal or email
2. Portal/operator identifies all records associated with patient: RefillRequest, notification logs, audit logs (if applicable to the patient)
3. Data is compiled into a structured format (JSON, XML, or CSV)
4. Patient is notified that data is ready; link to download is sent (time-limited, secure URL)
5. Patient downloads data
6. Access request is logged

**Postconditions:**
- Patient has received all their personal data in a portable, machine-readable format
- Access request is logged and retained for proof of compliance

**Data involved:**
- All RefillRequest records for the patient
- Notification logs
- Audit logs (access records, timestamps)
- Data access request log

**Trust boundary crossings:**
1. Portal → Patient: Data export is delivered via HTTPS; must use time-limited, signed URLs to prevent unauthorized access

---

### UC-006: Patient Exercises Data Subject Rights (Erasure)
**Actor:** Authenticated patient
**Goal:** Request deletion of personal data related to refill requests
**Preconditions:**
- Patient submits erasure request (GDPR Article 17) or account deletion request
- No active business reason to retain data (e.g., prescription is no longer active)

**Main Flow:**
1. Patient submits erasure request
2. Portal checks if any associated RefillRequest records can be deleted (e.g., no pending decisions, old requests)
3. For erasable records: soft-delete (mark deleted, keep for audit); for long-term retention (audit log), anonymise or redact patient ID
4. Notification service cancels any pending notifications
5. Patient is notified of erasure completion within 30 days

**Postconditions:**
- Personal data is deleted (or anonymised) from RefillRequest table
- Audit trail is retained (anonymised if possible)
- Erasure request is logged

**Data involved:**
- RefillRequest records (to be deleted)
- Audit logs (partially anonymised)
- Erasure request log

**Trust boundary crossings:**
- Portal database: Must support atomic delete/anonymise operations

---

## 4. Threat Analysis

### 4.1 Security Threats (STRIDE)

---

#### ST-001: Unauthorised Access to Other Patients' Prescriptions (Elevation of Privilege / Spoofing)
**STRIDE category:** Elevation of Privilege
**Affected use case(s):** UC-001, UC-002
**Description:**
An authenticated patient crafts a malicious request to the portal API, replacing their own patient ID with another patient's ID in the FHIR query, e.g., `GET /api/prescriptions?patientId=ATTACKER_TARGET_ID`. If the portal does not enforce row-level access control, the FHIR API returns prescriptions for the target patient, exposing medication details.

**Attack vector:**
1. Patient A logs in successfully (authenticated)
2. Patient A opens browser developer tools and modifies the API request, changing their patientId parameter to Patient B's ID (e.g., NHS number obtained from the NHS directory or guessed)
3. Portal forwards the request to FHIR API without validating that the requested patientId matches the authenticated user
4. FHIR API may trust the portal and return Patient B's prescriptions
5. Patient A can now view, and potentially request refills on, Patient B's prescriptions

**Likelihood:** **High** — Common API security flaw (broken object-level authorisation). Patient ID is often sequential or predictable; Patient A knows other NHS numbers (family, colleagues).

**Impact:** **High** — Confidentiality breach (access to another patient's prescription history); Integrity breach (refill requests on behalf of another patient); potential medication error if refill is processed.

---

#### ST-002: FHIR API Input Injection (Tampering / Information Disclosure)
**STRIDE category:** Tampering, Information Disclosure
**Affected use case(s):** UC-001
**Description:**
The portal constructs FHIR API requests using patient-supplied data (patient ID, prescription ID) without proper validation/sanitisation. If the FHIR API uses these inputs in a query or command (e.g., SQL, SPARQL, or XPath query), an attacker can inject malicious syntax.

Example: A malicious prescription ID like `id=001' OR '1'='1` could break out of a filter, returning all prescriptions in the system.

**Attack vector:**
1. Patient submits refill request with malicious prescriptionId
2. Portal constructs FHIR query: `GET /MedicationRequest?id={prescriptionId}`
3. Portal does not validate prescriptionId; forwards as-is
4. FHIR API endpoint processes query, and if backed by a vulnerable database or query engine, injection succeeds
5. Attacker retrieves unintended data or modifies query results

**Likelihood:** **Medium** — FHIR APIs are typically well-designed and use parameterised queries, but portal developers might not validate input before forwarding.

**Impact:** **High** — Information disclosure (access to other prescriptions), potential tampering of medical records.

---

#### ST-003: Authorisation Bypass for GP Actions (Elevation of Privilege)
**STRIDE category:** Elevation of Privilege
**Affected use case(s):** UC-003
**Description:**
A GP or authenticated staff member attempts to access or action a refill request that belongs to a different GP's patient list. For example, GP A logs in and tries to approve a request assigned to GP B, by directly modifying the requestId in the API call.

**Attack vector:**
1. GP A and GP B are both authenticated in the system
2. GP A learns the ID of a refill request assigned to GP B (e.g., from system error message, or sequential IDs)
3. GP A submits an approval/decline action with the foreign requestId
4. Portal does not verify that the request is assigned to GP A's patients
5. GP A approves/declines a decision they have no authority over

**Likelihood:** **Medium** — Requires an authenticated user with healthcare privileges; sequential/guessable request IDs increase likelihood.

**Impact:** **High** — Integrity of medical decisions (improper refill approval/denial), potential patient harm.

---

#### ST-004: Notification Interception and Content Leakage (Information Disclosure)
**STRIDE category:** Information Disclosure
**Affected use case(s):** UC-004
**Description:**
Notifications (email or SMS) containing refill status and GP notes are intercepted or leaked due to unencrypted transport, insecure storage, or improper handling by third-party providers.

**Attack vector:**
1. Portal sends SMS/email notification via third-party provider (e.g., Twilio, AWS SES)
2. If API call to provider is not over TLS, SMS/email content is logged in plaintext on intermediate systems
3. Attacker on the same network or with access to third-party logs can read notifications
4. GP decline notes (potentially containing sensitive patient information) are exposed

**Likelihood:** **Medium** — Depends on transport security and third-party provider's security posture.

**Impact:** **Medium** — Information disclosure (refill status, GP notes). If notes contain mental health flags or family details, impact is higher.

---

#### ST-005: Refill Request Tampering (Tampering)
**STRIDE category:** Tampering
**Affected use case(s):** UC-002, UC-003
**Description:**
A patient or an attacker modifies a RefillRequest record after it is created but before the GP reviews it. For example, patient updates their notes to remove a sensitive detail, or changes the prescriptionId to request a different medication.

**Attack vector:**
1. Patient A submits a refill request with initial notes
2. Patient A later submits a PATCH request to the portal, modifying the request notes or associated prescriptionId
3. If the portal does not enforce immutability of submitted requests or does not log the modification, the GP sees altered data
4. GP makes a decision based on incorrect/misleading information

**Likelihood:** **Medium** — Requires understanding of API structure; depends on whether portal allows modifications.

**Impact:** **Medium** — Integrity (incorrect GP decision based on modified request); potential medication error.

---

#### ST-006: Replay Attack on GP Action (Tampering / Repudiation)
**STRIDE category:** Tampering
**Affected use case(s):** UC-003
**Description:**
An attacker intercepts a GP's approval/decline request (HTTPS response or request) and replays it multiple times, causing multiple approvals or declines to be recorded for the same refill request.

**Attack vector:**
1. GP submits an approval action; request includes authorization token and action details
2. If the portal does not use nonce or idempotency keys, replaying the exact request payload causes the action to be processed again
3. Multiple approval notifications are sent, or request status is toggled multiple times

**Likelihood:** **Low** — HTTPS provides transport security; idempotency is a standard REST principle. Likelihood is higher if token is not revalidated on each request.

**Impact:** **Low-Medium** — Operational (duplicate notifications); Integrity (request status log shows duplicate entries).

---

#### ST-007: Session Hijacking (Spoofing)
**STRIDE category:** Spoofing
**Affected use case(s):** UC-001, UC-002, UC-003
**Description:**
An attacker steals or guesses an NHS login session token and uses it to impersonate a patient or GP within the refill module.

**Attack vector:**
1. Attacker obtains a valid NHS login session token (via XSS, Man-in-the-Middle, or other means)
2. Attacker uses the token to make API requests to the refill module
3. If the portal does not re-validate the token on each request or does not check token expiry, attacker has full access

**Likelihood:** **Medium** — Depends on NHS login token management and HTTPS enforcement.

**Impact:** **High** — Full impersonation (view prescriptions, submit refills, approve/decline decisions).

---

#### ST-008: Denial of Service — Refill Request Flooding (Denial of Service)
**STRIDE category:** Denial of Service
**Affected use case(s):** UC-002
**Description:**
An authenticated patient (or attacker with stolen credentials) rapidly submits multiple refill requests for the same prescription or many different prescriptions, overwhelming the GP task queue or consuming database resources.

**Attack vector:**
1. Attacker submits 1000 refill requests in rapid succession using a script or by modifying the API call
2. Each request is logged and appears in the GP task queue
3. GPs are overwhelmed; system performance degrades due to database load
4. Notification service struggles to send thousands of notifications

**Likelihood:** **Medium** — No explicit rate limiting mentioned in requirements.

**Impact:** **Medium** — Availability (GP task queue becomes unusable); Operational (notification backlog).

---

#### ST-009: Insecure Secrets Storage (Tampering / Information Disclosure)
**STRIDE category:** Information Disclosure
**Affected use case(s):** UC-001, UC-004
**Description:**
EHR API credentials, SMS/email provider API keys, or database passwords are hardcoded in the portal's source code or stored in plaintext configuration files.

**Attack vector:**
1. Portal source code is leaked (e.g., via misconfigured GitHub repo, supply chain compromise)
2. Attacker finds hardcoded API credentials
3. Attacker uses credentials to access EHR system, SMS provider, or patient database directly
4. Full system compromise

**Likelihood:** **Medium** — Common development mistake; risk is higher if code is shared across teams.

**Impact:** **Critical** — Complete system compromise (access to all patient data, ability to send fake notifications, modify prescriptions).

---

#### ST-010: Insufficient Error Handling (Information Disclosure)
**STRIDE category:** Information Disclosure
**Affected use case(s):** UC-001, UC-002
**Description:**
Error messages returned by the portal or FHIR API contain sensitive information (patient IDs, prescription details, database query traces).

**Attack vector:**
1. Attacker submits invalid input to the portal API (e.g., non-existent prescriptionId)
2. Portal returns error: "Prescription ID 12345 not found for patient NHS:9876543210"
3. Attacker learns: valid patient IDs, valid prescription ID ranges, internal system structure
4. Attacker uses information for further attacks (e.g., enumeration, targeted injection)

**Likelihood:** **Medium** — Depends on error handling implementation.

**Impact:** **Medium** — Information disclosure (patient IDs, prescription structure); aids reconnaissance for further attacks.

---

#### ST-011: Lack of Audit Logging (Non-Repudiation / Repudiation)
**STRIDE category:** Non-Repudiation
**Affected use case(s):** UC-001, UC-002, UC-003
**Description:**
The portal does not log access to prescriptions or GP actions on refill requests. If a GP denies they approved a harmful refill, or a patient denies requesting a refill, there is no audit trail to verify what actually happened.

**Attack vector:**
1. Scenario: GP claims they never approved a high-risk medication refill; patient claims they never submitted the request
2. Without audit logs, the claim is unverifiable
3. System operator cannot investigate or attribute actions

**Likelihood:** **Medium** — Logging is often considered "nice to have" rather than mandatory during initial design.

**Impact:** **Medium** — Non-repudiation (inability to prove who did what); Compliance (GDPR Article 32 requires audit of access; NHS Digital DSPT requires non-repudiation for clinical decisions).

---

### 4.2 Privacy Threats (LINDDUN)

---

#### PT-001: Linkability Across Prescription Requests and Notification Metadata (Linkability)
**LINDDUN category:** Linkability
**Affected use case(s):** UC-002, UC-004
**Description:**
Prescription refill requests, notifications, and timestamps can be linked together to build a profile of a patient's medication use, health conditions, and GP communication patterns. Even if prescription details are redacted, the metadata (request date, approval/decline pattern, notification delivery time) reveals significant personal information.

Example: A pattern of refill requests for antidepressants on specific dates, combined with notification delivery times, can reveal the patient's identity, location (via IP geolocation), and mental health status.

**Affected personal data:**
- Prescription identifier (links to medication type and patient)
- Request timestamp, approval/decline timestamp, notification delivery timestamp
- Patient contact preference (email vs. SMS — reveals communication habits)
- GP notes (unstructured, may contain identifiers or sensitive context)

**Affected data subjects:** Patients whose refill requests are visible or logged.

**Likelihood:** **High** — Timestamps and medication linkage are inherent to the system; profiling is easy without explicit privacy controls.

**Impact:** **High** — Privacy (medical history inferred from request patterns); secondary use (data could be sold, analyzed, or used for discrimination).

**GDPR relevance:** Article 5(1)(a) (lawfulness, fairness, transparency), Article 5(1)(b) (purpose limitation — data must not be used for profiling beyond legitimate healthcare purposes).

---

#### PT-002: Re-identifiability of Supposedly Anonymous Audit Logs (Identifiability)
**LINDDUN category:** Identifiability
**Affected use case(s):** UC-001, UC-002, UC-003
**Description:**
Audit logs are intended to be a trustworthy, non-repudiation record, but they may retain sufficient identifying information to re-identify patients or GPs. For example, an audit log that records:
- Action: "view prescriptions"
- Timestamp: 2026-03-31 14:23:45
- Prescription: Insulin 100IU
- GP: Dr. Smith

can be re-identified by cross-referencing with NHS records or other datasets. Even if patient name is removed, the combination of prescription type, GP, and timestamp may uniquely identify the patient.

**Affected personal data:**
- Patient ID (partially anonymised, but prescription details re-identify)
- Prescription type, dosage, date (medical data)
- GP identifier, action (healthcare provider data)
- Timestamp (behavioural data)

**Affected data subjects:** Patients and GPs in audit logs.

**Likelihood:** **Medium** — Re-identification requires access to external datasets (NHS directory, prescription patterns), but is feasible.

**Impact:** **Medium-High** — Privacy (healthcare information exposed), Non-repudiation (audit logs are no longer trustworthy if PII is retained).

**GDPR relevance:** Article 5(1)(a) (transparency), Article 6 (lawful basis for processing audit data), Article 32 (security of audit logs).

---

#### PT-003: Disclosure of Sensitive GP Notes to Patient (Disclosure of Information)
**LINDDUN category:** Disclosure of Information
**Affected use case(s):** UC-003, UC-004
**Description:**
When a GP declines a refill request with notes (e.g., "Patient requires liver function test before antidepressant refill due to alcohol misuse"), the notes are sent to the patient via email/SMS. If the patient shares the notification with others (or the notification is intercepted), sensitive personal information (mental health flags, lifestyle, medical conditions) is disclosed beyond the patient themselves.

**Affected personal data:**
- GP notes (unstructured, may contain mental health, substance use, family context, etc.)
- Prescription information (medication type, which implies condition)

**Affected data subjects:** Patient (direct), potentially family/contacts if notification is shared.

**Likelihood:** **High** — GPs have no guidance on what to include in notes; patients share notifications; email/SMS are not private channels.

**Impact:** **High** — Disclosure (sensitive health information leaked); Discrimination risk (if notes hint at mental health, substance use, etc.).

**GDPR relevance:** Article 5(1)(c) (data minimisation — notes should not contain unnecessary sensitive detail), Article 9 (special category data — mental health, substance abuse require extra safeguards).

---

#### PT-004: Unawareness of Data Collection and Notification Preferences (Unawareness)
**LINDDUN category:** Unawareness
**Affected use case(s):** UC-002, UC-004
**Description:**
Patients may not be aware that:
1. Refill requests are logged with timestamps and metadata for audit purposes
2. GP can see the patient's notes and reason for the request
3. Notifications are sent via email or SMS and may be stored by the third-party provider
4. Audit logs are retained for a specific period (e.g., 7 years for NHS records)
5. Data may be shared with third parties (e.g., SMS provider, audit systems)

If these details are not clearly communicated in a privacy notice, patients cannot make informed choices.

**Affected personal data:**
- All data processed by the refill module (prescriptions, requests, notifications, audit logs)

**Affected data subjects:** All patients using the refill feature.

**Likelihood:** **High** — Privacy notices are often not prominently displayed during feature onboarding.

**Impact:** **High** — Non-compliance (lack of transparency violates GDPR Article 13/14), Loss of trust.

**GDPR relevance:** Article 13 (information to be provided when data is collected), Article 14 (information to be provided when data is not obtained from the data subject).

---

#### PT-005: Non-Compliance with Data Retention Requirements (Non-Compliance)
**LINDDUN category:** Non-Compliance
**Affected use case(s):** UC-001, UC-002, UC-003
**Description:**
The system accumulates refill request records, GP notes, and audit logs indefinitely without a deletion policy. NHS records retention guidelines typically require:
- Clinical records: 7-10 years (depending on patient age, condition, etc.)
- Audit logs: 1-2 years (or longer if involved in a dispute)

But GDPR requires data minimisation and deletion where no longer necessary. If the system does not enforce automatic deletion or if deletion is manual/ad-hoc, regulatory non-compliance is inevitable.

**Affected personal data:**
- RefillRequest records (prescription details, patient context)
- GP notes (sensitive decision-making data)
- Audit logs (patient access history, GP actions)

**Affected data subjects:** All patients and GPs using the system.

**Likelihood:** **High** — Deletion policies are rarely implemented upfront; data accumulates over time.

**Impact:** **High** — Non-compliance (GDPR Articles 5(1)(e) — storage limitation, and 17 — right to erasure), Operational risk (regulatory fines).

**GDPR relevance:** Article 5(1)(e) (storage limitation), Article 17 (right to erasure), Article 32 (security of processing — includes secure deletion).

---

#### PT-006: Non-Repudiation Harm — Inability to Deny Healthcare Actions (Non-Repudiation)
**LINDDUN category:** Non-Repudiation
**Affected use case(s):** UC-003
**Description:**
A GP's approval/decline action on a refill request is logged and cannot be denied (non-repudiation). While this is desirable for accountability, it can also harm the GP if:
1. The action was unauthorized (e.g., stolen credentials)
2. The action is used as evidence in a medical malpractice claim or disciplinary proceeding
3. The log is used to build a profile of the GP's decision-making (bias, poor judgment)

From a GDPR perspective, GPs are data subjects too; logging their actions creates personal data about them.

**Affected personal data:**
- GP ID, action, timestamp, notes
- Implicit data about GP's decision-making patterns, availability, workload

**Affected data subjects:** GPs and healthcare staff.

**Likelihood:** **Medium** — GPs are expected to take responsibility for actions, but logging can be misused.

**Impact:** **Low-Medium** — Privacy (GP activity profiled), Fairness (logs used for disciplinary purposes without due process).

**GDPR relevance:** Article 5 (fairness, transparency), Article 6 (lawful basis for processing GP data).

---

## 5. Abuse Cases

### 5.1 Security Abuse Cases

---

#### SAC-001: Unauthorized Access to Another Patient's Prescription List
**Linked threat:** ST-001
**Attacker type:** External authenticated user (patient with valid NHS login)
**Goal:** Access another patient's prescription history to find out what medication they take (e.g., for blackmail, discrimination, curiosity)

**Attack Flow:**
1. Patient A logs into the portal (authenticated via NHS login)
2. Patient A opens browser developer console and modifies the API request to `GET /api/prescriptions?patientId=NHS:1234567890` (Patient B's NHS number)
3. Portal does not validate that the patientId matches the authenticated user; forwards request to FHIR API
4. FHIR API trusts the portal and returns Patient B's prescriptions
5. Patient A can now see all active prescriptions for Patient B

**Impact if successful:**
- Confidentiality breach: Patient B's prescription history (medication types, dosages, dates) is exposed
- Integrity risk: Patient A can now submit refill requests on behalf of Patient B
- Privacy violation: Medications can reveal serious health conditions (antidepressants, antiretrovirals, etc.)

**OWASP Top 10 category:** A01:2021 – Broken Access Control

---

#### SAC-002: FHIR API Injection to Enumerate All Patients
**Linked threat:** ST-002
**Attacker type:** External authenticated user (patient) or unauthenticated attacker with intercepted token
**Goal:** Extract all patient prescriptions from the EHR system using SQL/query injection

**Attack Flow:**
1. Attacker submits refill request with malicious prescriptionId: `id=* OR 1=1`
2. Portal constructs FHIR query: `GET /MedicationRequest?id=* OR 1=1`
3. If the FHIR API backend uses a vulnerable query engine (e.g., XPath, SPARQL), the query is interpreted as "all MedicationRequests"
4. Attacker receives prescriptions for all patients in the system
5. Attacker extracts a complete patient-prescription mapping

**Impact if successful:**
- Confidentiality breach: All prescriptions in the EHR system are exposed
- Data exfiltration: Attacker builds a patient-medication database
- Integrity risk: Attacker can craft advanced targeted attacks (e.g., prescriptionId for a specific high-risk medication)

**OWASP Top 10 category:** A03:2021 – Injection

---

#### SAC-003: GP Approves Refill for Another GP's Patient
**Linked threat:** ST-003
**Attacker type:** Internal authenticated user (healthcare staff / GP)
**Goal:** Approve a medication refill outside scope of authority (e.g., for profit, sabotage, unauthorized access)

**Attack Flow:**
1. GP A logs into the portal and views their task queue
2. GP A discovers the API endpoint for approving requests: `POST /api/refill-requests/{requestId}/approve`
3. GP A guesses or learns the requestId of a request assigned to GP B (e.g., sequential IDs, error messages, or system logs)
4. GP A submits approval: `POST /api/refill-requests/12345/approve`
5. Portal approves the request without verifying that requestId belongs to GP A's patient list
6. Patient receives notification that their refill was approved by an unauthorized GP

**Impact if successful:**
- Integrity: Medical decision made by unauthorized healthcare provider
- Safety: Potential medication error or drug interaction (unauthorized GP may not know patient history)
- Non-repudiation: GP B cannot prove they did not approve the request; audit trail is compromised

**OWASP Top 10 category:** A01:2021 – Broken Access Control

---

#### SAC-004: Notification Interception Reveals Sensitive Medication Details
**Linked threat:** ST-004
**Attacker type:** External attacker (network eavesdropper, SMS/email provider employee, mail handler)
**Goal:** Intercept notifications to learn sensitive patient health information

**Attack Flow:**
1. GP declines a refill with notes: "Patient requires liver function test before antidepressant refill due to suspected alcohol misuse"
2. Portal sends email notification: "Your refill request for Sertraline has been declined. Reason: Patient requires liver function test before antidepressant refill due to suspected alcohol misuse"
3. If email is sent via unencrypted SMTP or through a third-party provider without TLS enforcement, it may be logged in plaintext
4. Attacker accesses email provider logs or network traffic and reads the notification
5. Attacker learns patient's prescription, mental health condition, and substance use status

**Impact if successful:**
- Confidentiality: Sensitive health information (mental health, substance abuse) disclosed
- Discrimination: Attacker could use information for blackmail, employment discrimination, insurance fraud
- Privacy: GDPR Article 9 (special category data) violated

**OWASP Top 10 category:** A02:2021 – Cryptographic Failures

---

#### SAC-005: Refill Request Flooding DoS
**Linked threat:** ST-008
**Attacker type:** External authenticated user (patient or attacker with stolen credentials)
**Goal:** Overwhelm the GP task queue and notification system to disrupt service

**Attack Flow:**
1. Patient (or attacker with patient credentials) writes a script to submit 10,000 refill requests for the same prescription in rapid succession
2. Each request is saved to the database and queued for GP review
3. Notification service attempts to send 10,000 notifications
4. Database and notification service are overwhelmed; response times degrade; GPs cannot access the task queue
5. Legitimate refill requests are delayed or lost

**Impact if successful:**
- Availability: Service becomes unusable for all patients and GPs
- Operational: Notification service exhausted, potential cost overrun if SMS/email charges per message
- Data integrity: Task queue may be corrupted or inconsistent

**OWASP Top 10 category:** A05:2021 – Broken Access Control / A07:2021 – Identification and Authentication Failures

---

#### SAC-006: Hardcoded Credentials Lead to Direct Database Access
**Linked threat:** ST-009
**Attacker type:** External attacker with access to source code (via GitHub leak, supply chain compromise, etc.)
**Goal:** Access patient database directly, bypassing portal authentication and audit logging

**Attack Flow:**
1. Portal source code is leaked (e.g., GitHub repo with hardcoded credentials)
2. Attacker finds EHR API credentials and database connection string in code
3. Attacker uses credentials to connect directly to patient database
4. Attacker extracts all patient prescriptions, refill requests, and GP notes
5. Attacker modifies refill request statuses or deletes records to cover tracks

**Impact if successful:**
- Confidentiality: All patient data accessed without authentication or audit
- Integrity: Data can be modified or deleted
- Non-repudiation: Audit trail is bypassed

**OWASP Top 10 category:** A02:2021 – Cryptographic Failures, A05:2021 – Broken Access Control

---

### 5.2 Privacy Abuse Cases

---

#### PAC-001: Medication History Used for Discrimination
**Linked threat:** PT-001
**Actor:** Third party (employer, insurer, app that correlates data)
**Scenario:**
Patient's refill request history (medication type, frequency, GP decline reasons) is exposed or leaked. A third party (e.g., insurance company, employer wellness program) uses the information to discriminate:
- Insurance company raises premiums for patients with antidepressant or antiretroviral refills
- Employer wellness app correlates patient's medication with performance/productivity, leading to bias in performance reviews
- Health data broker purchases anonymized refill data and cross-references with other datasets to re-identify patients

**Affected data subjects:** Patients whose medication use is exposed.

**Privacy By Design principle violated:**
- Principle 5: End-to-end security (data is not protected throughout its lifecycle)
- Principle 6: Visibility and transparency (patient is unaware of secondary use)

**Regulatory exposure:**
- GDPR Articles 5(1)(a)–(c) (unlawful, unfair, non-transparent processing)
- GDPR Article 9 (special category data — medical data — cannot be processed for discrimination)
- UK Equality Act 2010 (discrimination on grounds of disability, health)
- Potential fines: up to EUR 20 million or 4% of annual turnover

---

#### PAC-002: GP Notes Retained Indefinitely Without Deletion
**Linked threat:** PT-005
**Actor:** System itself (passive accumulation)
**Scenario:**
Patient submits a refill request that is declined by the GP with sensitive notes: "Patient reports family history of schizophrenia; consider psychiatric review before antidepressant adjustment." The notes are stored in the database. Five years later, the refill request is still in the system, and no deletion process is in place. When the patient is offered a new job, the employer requests a background check and a medical examination. The health data is inadvertently disclosed or the patient feels anxiety knowing sensitive mental health notes exist in a healthcare system they no longer use.

**Affected data subjects:** Patients with sensitive health conditions whose data is retained longer than necessary.

**Privacy By Design principle violated:**
- Principle 3: Privacy embedded into design (retention policy should be designed upfront, not ad-hoc)
- Principle 6: Visibility and transparency (patient is not told how long notes are kept)

**Regulatory exposure:**
- GDPR Article 5(1)(e) (storage limitation — data must not be kept longer than necessary)
- GDPR Article 17 (right to erasure — patient can demand deletion)
- Potential fine: up to EUR 20 million or 4% of annual turnover

---

#### PAC-003: Patient Unaware of GP's Access to Refill Request Context
**Linked threat:** PT-004
**Actor:** System (lack of transparency)
**Scenario:**
Patient submits a refill request with notes explaining: "Having difficulty affording prescriptions this month; requesting expedited refill to avoid gap in treatment." The patient intends this information to be private between themselves and their GP. However, the portal does not clearly explain that:
1. The GP can see the notes
2. Notes are logged in the audit system
3. Notes may be visible to other healthcare staff with access to the patient's record
4. Notes are retained for 7 years as part of the patient's medical record

Patient is unaware of this data sharing and assumes the notes are for administrative purposes only.

**Affected data subjects:** Patients submitting refill requests.

**Privacy By Design principle violated:**
- Principle 6: Visibility and transparency (no clear explanation of data flow)
- Principle 7: Respect for user privacy (patient is not given control/choice)

**Regulatory exposure:**
- GDPR Article 13 (information to be provided when personal data is collected directly from the data subject)
- Potential fine: up to EUR 10 million or 2% of annual turnover (Article 83(4))

---

## 6. Counter-Use Cases

### 6.1 Security Use Cases (Countermeasures)

---

#### SUC-001: Row-Level Access Control for Prescription Queries
**Mitigates:** SAC-001, ST-001
**Security control:** Implement server-side access control that enforces: Patient can only retrieve prescriptions for which patientId = authenticated_user_id; GP can only access requests for patients in their care (enforced via patient-GP mapping table).

**Implementation notes:**
- FHIR API client in the portal must pass the authenticated patient's ID in every request
- Patient ID comes from the NHS login token (never from client-side input)
- FHIR API server must enforce filtering: `GET /Patient/{patientId}/MedicationRequest` where {patientId} is server-validated against the authenticated user
- Use parameterised queries or FHIR API filtering syntax (not string concatenation)
- For GPs, implement a lookup: `SELECT refill_requests WHERE gp_id = authenticated_gp_id AND patient_id IN (SELECT patient_id FROM gp_patient_mapping WHERE gp_id = authenticated_gp_id)`

**OWASP ASVS reference:** ASVS 4.0 §4.1.3 — Access control decisions must be enforced server-side

**Residual risk:** If the patient-GP mapping is incorrect (e.g., GP is reassigned), a patient's prescriptions may become inaccessible or visible to the wrong GP. Mitigation: Implement a reconciliation process and audit log to detect mapping changes.

---

#### SUC-002: Input Validation and FHIR API Sanitisation
**Mitigates:** SAC-002, ST-002
**Security control:** Validate all user-supplied inputs (patient ID, prescription ID, notes) before forwarding to the FHIR API or storing in the database. Use strict whitelist validation, parameterised queries, and FHIR schema validation.

**Implementation notes:**
- Patient ID: Validate that it matches the authenticated user (via NHS login token); reject any deviations
- Prescription ID: Validate format (e.g., UUIDs, alphanumeric pattern); reject anything that doesn't match expected format
- Patient notes (free text): Enforce maximum length (e.g., 500 characters); sanitise HTML/special characters; use parameterised inserts into database
- FHIR API responses: Validate that returned resources match the expected FHIR schema (e.g., MedicationRequest, Patient); reject unexpected fields or data types
- Use a FHIR SDK or library (e.g., HL7 FHIR JavaScript, HAPI FHIR) that handles validation automatically

**OWASP ASVS reference:** ASVS 4.0 §5.1.1 — Input validation for all inputs from untrusted sources

**Residual risk:** Validation is complex; edge cases (e.g., Unicode homographs, encoded input) may bypass filters. Mitigation: Use established validation libraries and test against OWASP fuzzing payloads.

---

#### SUC-003: Enforce Idempotency and Transaction-Level Access Control for GP Actions
**Mitigates:** SAC-003, ST-003, ST-006
**Security control:** (a) Verify that GP action is only allowed if the request's assigned_gp = authenticated_gp (or the GP's team). (b) Use idempotency keys to prevent replay attacks.

**Implementation notes:**
- Before allowing a GP to approve/decline, check: `SELECT assigned_gp FROM refill_requests WHERE id = {requestId} AND assigned_gp = {authenticated_gp_id}`
- If the check fails, return 403 Forbidden and log the unauthorized attempt
- For idempotency: Require client to provide an idempotency key (UUID) in the request header
- Server checks if the same idempotency key was already processed; if yes, return the cached result (no duplicate action)
- Store idempotency key ↔ action result mapping in a transient cache (TTL 24 hours)

**OWASP ASVS reference:** ASVS 4.0 §4.1.1 — Access control is enforced at every level

**Residual risk:** If the assigned_gp mapping is wrong or the GP's team membership is stale, the check may reject valid requests. Mitigation: Implement a team member lookup service with caching and periodic refresh.

---

#### SUC-004: Encrypt Notifications in Transit and Enforce Contact Verification
**Mitigates:** SAC-004, ST-004
**Security control:** (a) All email/SMS sent via third-party providers must use authenticated, encrypted APIs (TLS 1.3+). (b) Patient's email/phone is verified before first use and re-validated if changed.

**Implementation notes:**
- SMS/email provider: Use HTTPS API with mutual TLS (verify provider certificate); use API key authentication (OAuth2 or signed requests)
- If provider logs are accessible to humans, ensure portal sends minimized notification content (e.g., "Your prescription refill was [approved/declined]" with a portal link to view details, not embedding GP notes in the SMS body)
- Email: Use TLS encryption (STARTTLS or implicit TLS on port 465); enable SPF, DKIM, DMARC to prevent email spoofing
- Contact verification: Before sending the first notification, send a verification email/SMS to patient and require them to confirm (e.g., "Is this your correct email? Yes / No")
- If contact details change, re-send verification before using the new contact

**OWASP ASVS reference:** ASVS 4.0 §2.7 — Session management includes authenticated channels

**Residual risk:** Third-party provider (SMS/email company) may still log notifications internally. Mitigation: Use privacy policies, Data Processing Agreements (DPAs), and audit clauses in contracts. Consider encrypting the notification content server-side and decrypting at the third party (unlikely feasible for SMS).

---

#### SUC-005: Request Immutability and Tamper Detection
**Mitigates:** SAC-005, ST-005
**Security control:** Once a refill request is submitted, the core fields (prescriptionId, patientId) cannot be modified. Modifications to notes are logged and attributed to the modifier.

**Implementation notes:**
- Database schema: Mark core fields (prescriptionId, patientId) as immutable; use database constraints (e.g., CHECK constraint) to prevent UPDATEs
- Patient-initiated updates (e.g., adding additional notes): Create an audit trail (who, what, when). If notes are modified, log the old and new values
- API endpoint: Disable PATCH on core fields; only allow appending to notes or marking as retracted
- Notification: If request is modified after submission but before GP review, inform the GP with a flag ("This request was modified by the patient on 2026-03-31 14:30")

**OWASP ASVS reference:** ASVS 4.0 §8.3.3 — Logging includes sensitive data modifications

**Residual risk:** Patient and GP may collide to submit false requests and then claim tampering. Mitigation: Strong audit logging (includes immutable timestamps, digital signatures) and security review of high-risk requests.

---

#### SUC-006: Secure Secrets Management
**Mitigates:** SAC-006, ST-009
**Security control:** Store all secrets (API credentials, database passwords) in a secure vault, not in source code or plaintext config files.

**Implementation notes:**
- Use a secrets management system (e.g., AWS Secrets Manager, Azure Key Vault, HashiCorp Vault, or Kubernetes Secrets for cloud-native deployments)
- FHIR API credentials: Store in the vault; rotate every 90 days
- Database connection string: Store in the vault; use temporary credentials (e.g., IAM database authentication) if supported
- SMS/email provider API keys: Store in the vault
- Environment variables in deployment: Do not hardcode; populate from the vault at runtime
- Source code: Never commit secrets to Git; use `.gitignore` and pre-commit hooks (e.g., git-secrets) to prevent accidental commits
- Code review: Automated scanning (e.g., GitHub Secret Scanning, TruffleHog) to detect hardcoded secrets

**OWASP ASVS reference:** ASVS 4.0 §2.2 — Secrets are stored securely

**Residual risk:** Vault access is a single point of failure; if vault is compromised, all secrets are exposed. Mitigation: Implement strong vault access control (MFA, IP whitelisting, audit logging), and least-privilege IAM permissions.

---

#### SUC-007: Robust Error Handling and Information Hiding
**Mitigates:** SAC-001 (aids reconnaissance), ST-010
**Security control:** Error messages must not leak sensitive information; log detailed errors server-side only.

**Implementation notes:**
- API error responses: Return generic messages (e.g., "Request failed" or "Unauthorized") without revealing patient IDs, prescription details, or database schema
- Server-side logging: Log detailed errors (full stack trace, patient ID, query) for debugging, but do not return to client
- HTTP status codes: Use standard codes (200, 400, 403, 404, 500) without custom messages that hint at system state
- Frontend: Display user-friendly error messages (e.g., "We couldn't find your prescription. Please try again later or contact support") instead of raw API errors
- Example of bad error message: "Prescription ID 12345 not found for patient NHS:9876543210"
- Example of good error message: "Your prescription information could not be retrieved. Please try again."

**OWASP ASVS reference:** ASVS 4.0 §7.4 — Error handling does not expose sensitive information

**Residual risk:** Even generic error messages can be brute-forced (e.g., timing attacks to detect whether a patient ID exists). Mitigation: Implement rate limiting and add jitter to response times.

---

#### SUC-008: Comprehensive Audit Logging
**Mitigates:** SAC-001, SAC-003, ST-011
**Security control:** Log all security-relevant actions: authentication, authorization decisions, access to prescriptions, GP approvals/declines, data modifications, errors.

**Implementation notes:**
- Log schema: Include: timestamp (UTC), user_id, action, resource_id (e.g., prescriptionId, requestId), result (success/failure), IP address (optional, if not privacy-invasive), error message (if applicable)
- Immutability: Write logs to an append-only store (e.g., AWS CloudTrail, database with append-only schema); do not allow deletion
- Retention: Retain for 2 years (NHS/GDPR standard); older logs are archived and later deleted per data retention policy
- Monitoring: Automated alerts for suspicious patterns (e.g., multiple failed authentication attempts, access to many patients, bulk deletions)
- Access control: Only admins and security team can query logs; encrypted at rest
- Log examples:
  - "2026-03-31 14:23:00 | user=patient-NHS:1234567890 | action=view_prescriptions | result=success | count=3 | ip=203.0.113.50"
  - "2026-03-31 14:25:00 | user=gp-ID:Dr.Smith | action=decline_refill | request_id=RF-12345 | notes_length=156 | result=success"
  - "2026-03-31 14:30:00 | user=patient-NHS:1234567890 | action=view_prescriptions | result=failure | reason=session_expired"

**OWASP ASVS reference:** ASVS 4.0 §8.1.1 — Application logs security events

**Residual risk:** Audit logs contain personal data (patient IDs, action details) which must itself be protected. Mitigation: Encrypt logs at rest, limit access, and implement a retention/deletion process for logs (as per PT-005).

---

#### SUC-009: Rate Limiting and Brute Force Protection
**Mitigates:** SAC-005, ST-008
**Security control:** Limit the rate of refill request submissions per patient, per GP, and globally. Lock accounts after repeated failed access attempts.

**Implementation notes:**
- Per-patient rate limit: Max 10 refill requests per day, max 1 request per minute per prescription (to prevent replay/flooding)
- Per-GP rate limit: Max 1000 actions per day (to prevent bulk approval/decline abuse)
- Global rate limit: Max 10,000 requests per minute to /api/refill-requests (to detect DDoS)
- Implementation: Use a distributed rate limiter (Redis, AWS API Gateway, or WAF rules)
- Failed authentication: After 5 failed NHS login attempts, lock account for 15 minutes and send alert email
- Response: Return 429 Too Many Requests with Retry-After header

**OWASP ASVS reference:** ASVS 4.0 §11.1.1 — Rate limiting is implemented

**Residual risk:** Rate limits can be bypassed by distributed attacks (many IPs). Mitigation: Combine IP-based rate limiting with user-based limits and implement CAPTCHA for high-risk actions.

---

### 6.2 Privacy Use Cases (Privacy Controls)

---

#### PUC-001: Data Minimisation for Notifications
**Mitigates:** PAC-001, PT-001, PT-004
**Privacy control:** Notifications should contain only essential information. GP notes should be redacted or minimized before sending to patient.

**Implementation notes:**
- Patient-facing notification content:
  - Approval: "Your prescription for [medication name] has been approved. You can collect it from [pharmacy name]."
  - Decline: "Your prescription for [medication name] needs further review. Please contact your GP for details."
  - Do NOT include: GP's full notes, specific reason in the SMS/email body
  - Reason to contact GP: Patient can log into portal and view the decline reason (with portal encryption)
- GP-facing decision: GP can enter detailed notes in the system, but they are not automatically sent to patient
- Alternative: Provide patient a portal link to view the reason (gated behind authentication)

**Privacy by Design principle:** Principle 2: Privacy as default (minimize data shared by default)

**Implementation notes (continued):**
- Database: Store full GP notes in the refill_requests table, but add a field `patient_notification_content` (truncated/redacted notes)
- API endpoint to retrieve decline reason: Authenticated patient can call GET /api/refill-requests/{id}/notes_for_patient, which returns only the patient-safe subset
- Audit logging: Log when patient views the detailed reason (for transparency)

---

#### PUC-002: Data Retention and Automatic Deletion Policy
**Mitigates:** PAC-002, PT-005
**Privacy control:** Define a clear retention schedule aligned with NHS records retention guidelines and GDPR data minimisation.

**Implementation notes:**
- Retention schedule:
  - Active prescriptions: Retained as long as prescription is active (per NHS clinical records policy)
  - Completed refill requests (approved or declined): Retained for 7 years (NHS records retention standard)
  - Notification logs: Retained for 1 year (operational/audit purposes)
  - Audit logs (system access): Retained for 1 year; older logs archived and deleted
  - Patient contact preference history: Retained for 2 years (for audit of consent)
- Deletion process:
  - Automated batch job runs daily at 23:00 UTC; identifies records meeting deletion criteria
  - Soft-delete: Mark records as deleted (flag in database) for 30 days (recovery period)
  - Hard-delete: After 30 days, permanently delete from database and backups
  - Encryption key deletion: For encrypted data, delete encryption keys (if applicable) at the same time as hard-delete
- Verification: Quarterly audit to verify deletion is working (sample checks: count of records by age, verify no 8-year-old refill requests exist)
- Documentation: Privacy notice and user portal explain retention periods

---

#### PUC-003: Patient Consent for Notifications
**Mitigates:** PT-004
**Privacy control:** Obtain and document explicit consent before sending notifications (SMS/email). Patient can change notification preference at any time.

**Implementation notes:**
- Consent collection:
  - At portal onboarding (when patient first links NHS login), ask: "May we send you email/SMS notifications about your prescription refills?" with Yes/No/Prefer SMS only/Prefer email only options
  - Store consent choice in patient_notification_preferences table: {patient_id, email_consent, sms_consent, preference, consent_timestamp}
  - Require affirmative consent (opt-in), not opt-out
- Privacy notice: Inform patient:
  - "We will send you a notification (email or SMS) when your prescription refill request is approved or declined."
  - "If your request is declined, the notification will include the reason (so you can contact your GP if needed)."
  - "You can change your notification preferences at any time in your account settings."
- Portal setting: Patient can toggle email/SMS preferences; changes are logged with timestamp
- PECR compliance (UK electronic marketing rules): SMS and email marketing require prior consent; refill notifications are "transactional" (a necessary part of the service), but consent is still best practice

---

#### PUC-004: Privacy Notice and Transparency
**Mitigates:** PAC-003, PT-004
**Privacy control:** Provide a clear, accessible privacy notice that explains what data is collected, how it's used, who has access, and how long it's kept.

**Implementation notes:**
- Privacy notice content (per GDPR Article 13):
  - Identity of data controller and DPO contact
  - Purpose of processing: To process prescription refill requests and manage patient-GP communication
  - Lawful basis: Contract (patient's agreement to use the service) or legitimate interest (efficient healthcare delivery)
  - Recipients: GPs (within the health authority), SMS/email providers (with Data Processing Agreement)
  - Retention period: See PUC-002 (7 years for completed requests, 1 year for notification logs)
  - Data subject rights: Access (GDPR Article 15), Erasure (Article 17, with limitations for clinical records), Portability (Article 20), Rectification (Article 16)
  - Right to lodge a complaint with the ICO
- Placement:
  - Prominent link on portal homepage ("Privacy Notice" or "How we use your data")
  - Shown during onboarding with checkbox: "I have read and understand the Privacy Notice"
  - In-app help text explaining data flows
- Accessibility: Large font, simple language, available in multiple languages if serving diverse populations

---

#### PUC-005: Lawful Basis Documentation
**Mitigates:** PT-002, PT-004
**Privacy control:** Document the lawful basis for processing patient data in the refill module. Ensure it aligns with NHS legal obligations and patient expectations.

**Implementation notes:**
- Lawful basis analysis (GDPR Article 6):
  - Refill request submission: "Contract" (patient-NHS relationship) or "Legitimate interest" (efficient healthcare delivery)
  - GP access to request: "Contract" and "Legal obligation" (NHS duty of care)
  - Audit logging: "Legal obligation" (NHS records retention, GDPR accountability)
  - Notification: "Consent" (patient explicitly consents to notifications, per PUC-003)
- Documentation: Record in a processing inventory or DPIA:
  - What is being processed (prescription data, refill requests, GP decisions)
  - Who is processing it (patient, GP, system admins)
  - Why (lawful basis)
  - For how long (retention schedule, per PUC-002)
- Risk assessment: If lawful basis is unclear or contested (e.g., processing GP notes for secondary research), conduct a Data Protection Impact Assessment (DPIA, GDPR Article 35) to identify and mitigate risks

---

#### PUC-006: Data Subject Rights Fulfillment (Access, Erasure, Portability)
**Mitigates:** PT-004
**Privacy control:** Implement portal features and processes to allow patients to exercise GDPR rights.

**Implementation notes:**
- Right of Access (GDPR Article 15):
  - Portal feature: Patient clicks "Download my data" → Portal generates export of all refill requests, notifications, and associated audit entries in JSON/CSV
  - Process: Request fulfilled within 30 days; include metadata (access logs, GP notes, etc.)
  - Format: Structured, machine-readable (JSON or CSV), with explanatory headers
- Right of Erasure (GDPR Article 17):
  - Limitation: Clinical records cannot be deleted (NHS records retention policy overrides GDPR); patient can request anonymisation instead
  - Process: Patient submits erasure request; system anonymises refill requests (remove patient ID, encrypt notes, etc.) for completed requests; pending requests are deleted
  - Notification: Patient is informed of what can/cannot be deleted and why
- Right to Portability (GDPR Article 20):
  - Portal feature: Patient can export data in machine-readable format and request transfer to another healthcare provider
  - Process: Provide secure download link with time-limited access
- Right to Rectification (GDPR Article 16):
  - Patient can correct contact details (email, phone) in the portal
  - Patient cannot modify past refill requests (immutability control), but can submit a dispute/clarification note
- Right to Object (GDPR Article 21):
  - If patient objects to processing for a non-essential purpose (e.g., research use), the system stops processing for that purpose

---

## 7. Refined Requirements

### Original Requirements (Classified)

#### Functional Requirements (FR)
| ID | Original/Refined | Requirement |
|---|---|---|
| **FR-001** | Original | Patients view active prescriptions |
| **FR-002** | Original | Patients submit refill request |
| **FR-003** | Original | GPs receive and review requests |
| **FR-004** | Original | GPs approve or decline requests |
| **FR-005** | Original | Patients receive notifications |

#### Security Non-Functional Requirements (SEC)
| ID | Original/Refined | Requirement |
|---|---|---|
| **SEC-001** | Original | Authentication via NHS login integration |
| **SEC-002** | Original | HTTPS/TLS encryption for data in transit |
| **SEC-003** | **[NEW]** | Row-level access control for prescriptions — Patients can only retrieve their own prescriptions; GPs can only access requests for their patients [from ST-001, SAC-001] |
| **SEC-004** | **[NEW]** | Input validation and sanitisation — All user-supplied inputs (patient ID, prescription ID, notes) validated before FHIR API calls or database storage [from ST-002, SAC-002] |
| **SEC-005** | **[NEW]** | Session management — NHS login tokens must be validated on every request; token expiry enforced; logout/revocation implemented [from ST-007] |
| **SEC-006** | **[NEW]** | Rate limiting — Max 10 refill requests per patient per day; max 1000 GP actions per day; global DDoS protection [from ST-008, SAC-005] |
| **SEC-007** | **[NEW]** | Secrets management — API credentials, database passwords stored in secure vault (not hardcoded); rotation every 90 days [from ST-009, SAC-006] |
| **SEC-008** | **[NEW]** | Error handling — Error messages do not leak patient IDs, prescription details, or system internals; detailed errors logged server-side only [from ST-010, SAC-001] |
| **SEC-009** | **[NEW]** | Audit logging — All access to prescriptions and refill requests logged with user ID, action, timestamp, result; logs immutable and retained per retention policy [from ST-011, SUC-008] |
| **SEC-010** | **[NEW]** | Request immutability — Core fields (prescriptionId, patientId) of refill requests cannot be modified after submission; modifications are logged [from ST-005, SAC-005] |
| **SEC-011** | **[NEW]** | Idempotency for GP actions — GP approval/decline requests use idempotency keys to prevent replay attacks [from ST-006, SUC-003] |
| **SEC-012** | **[NEW]** | GP access control — GP can only approve/decline requests for patients in their care; enforced server-side [from ST-003, SAC-003] |

#### Privacy Non-Functional Requirements (PRV)
| ID | Original/Refined | Requirement |
|---|---|---|
| **PRV-001** | Original | GDPR compliance — Process personal data lawfully, fairly, transparently |
| **PRV-002** | **[NEW]** | Lawful basis documentation — Specify lawful basis for each data processing activity (contract, consent, legal obligation, legitimate interest) [from PT-004] |
| **PRV-003** | **[NEW]** | Data minimisation for notifications — Notifications contain only essential information; GP notes not embedded in SMS/email; patient accesses detailed reason via authenticated portal link [from PAC-001, PT-001, PT-004, PUC-001] |
| **PRV-004** | **[NEW]** | Data retention and deletion policy — Completed refill requests retained for 7 years; notification logs retained for 1 year; automated deletion process in place [from PT-005, PAC-002, PUC-002] |
| **PRV-005** | **[NEW]** | Consent for notifications — Obtain explicit opt-in consent before sending email/SMS; patient can change preferences at any time [from PT-004, PUC-003] |
| **PRV-006** | **[NEW]** | Privacy notice — Publicly available notice explaining what data is collected, how it's used, who has access, retention period, data subject rights [from PT-004, PAC-003, PUC-004] |
| **PRV-007** | **[NEW]** | Data subject rights — Implement features for patients to exercise GDPR rights: access (data export), erasure (deletion/anonymisation), portability, rectification [from PUC-006] |
| **PRV-008** | **[NEW]** | Supply chain security — All third-party vendors (SMS/email providers) must have Data Processing Agreements (DPAs) and undergo security assessment [from COMP-004, ST-004] |

#### Performance Non-Functional Requirements (PERF)
| ID | Original/Refined | Requirement |
|---|---|---|
| **PERF-001** | Original | Prescription list load time < 2 seconds |
| **PERF-002** | Original | Notification delivery < 5 minutes |

#### Compliance/Regulatory Requirements (COMP)
| ID | Original/Refined | Requirement |
|---|---|---|
| **COMP-001** | Original | NHS Digital DSPT compliance — Implement controls per NHS Data Security and Protection Toolkit |
| **COMP-002** | **[NEW]** | Data Protection Impact Assessment (DPIA) — Conduct DPIA for processing patient healthcare data with GP decisions (required by GDPR Article 35) [from gap analysis] |
| **COMP-003** | **[NEW]** | Breach detection and reporting — Implement incident response process; report data breaches to ICO within 72 hours; patient notification within 72 hours if high risk [from gap analysis] |
| **COMP-004** | **[NEW]** | Secure notification delivery — SMS/email sent via authenticated, encrypted APIs (TLS 1.3+); contact details verified before first use [from ST-004, SAC-004, SUC-004] |
| **COMP-005** | **[NEW]** | NIS2 applicability assessment — If portal operator is NHS trust or essential service, verify compliance with NIS2 incident reporting (24h early warning, 72h full notification) and supply chain security requirements [from Assumptions] |

---

## 8. Security Requirements Traceability Matrix (SRTM)

| Req ID | Requirement (brief) | Type | Use Cases | Threat / Abuse Case | Control (SUC/PUC) | Test ID | Test Description | Priority |
|--------|---------------------|------|-----------|---------------------|---------------------|---------|------------------|----------|
| FR-001 | Patients view active prescriptions | FR | UC-001 | — | — | TA-001 | Prescriptions loaded correctly | Medium |
| FR-002 | Patients submit refill request | FR | UC-002 | ST-005, ST-008, SAC-005 | SUC-005, SUC-009 | TA-002 | Refill request submitted and logged | Medium |
| FR-003 | GPs receive and review requests | FR | UC-003 | ST-003, SAC-003 | SUC-003 | TA-003 | Requests routed to correct GP queue | Medium |
| FR-004 | GPs approve or decline requests | FR | UC-003 | ST-003, ST-006, SAC-003, SAC-005 | SUC-003, SUC-009 | TA-004 | GP action recorded and logged | Medium |
| FR-005 | Patients receive notifications | FR | UC-004 | ST-004, SAC-004 | SUC-004, PUC-001 | TA-005 | Notification sent within 5 minutes | Medium |
| SEC-001 | Authentication via NHS login | SEC | UC-001, UC-002, UC-003 | ST-007 | — | TA-006 | NHS login token validated on each request | High |
| SEC-002 | HTTPS/TLS encryption | SEC | UC-001, UC-002, UC-003, UC-004 | ST-004, ST-009, SAC-004 | — | TA-007 | All API calls use TLS 1.3+ | Critical |
| SEC-003 | Row-level access control for prescriptions | SEC | UC-001 | ST-001, SAC-001 | SUC-001 | TA-008 | Patient cannot access other patients' prescriptions | Critical |
| SEC-004 | Input validation and sanitisation | SEC | UC-001, UC-002 | ST-002, SAC-002 | SUC-002 | TA-009 | FHIR API injection attacks blocked | Critical |
| SEC-005 | Session management | SEC | UC-001, UC-002, UC-003 | ST-007 | SUC-001 (token from NHS login) | TA-010 | Token expiry enforced; logout clears session | High |
| SEC-006 | Rate limiting | SEC | UC-002 | ST-008, SAC-005 | SUC-009 | TA-011 | Rate limiting enforced; requests over limit rejected | High |
| SEC-007 | Secrets management | SEC | UC-001, UC-004 | ST-009, SAC-006 | SUC-006 | TA-012 | Secrets not found in source code or logs | Critical |
| SEC-008 | Error handling | SEC | UC-001, UC-002 | ST-010, SAC-001 | SUC-007 | TA-013 | Error messages do not leak sensitive data | High |
| SEC-009 | Audit logging | SEC | UC-001, UC-002, UC-003 | ST-011, SAC-003 | SUC-008 | TA-014 | All actions logged with user ID and timestamp | High |
| SEC-010 | Request immutability | SEC | UC-002 | ST-005, SAC-005 | SUC-005 | TA-015 | Core request fields cannot be modified | Medium |
| SEC-011 | Idempotency for GP actions | SEC | UC-003 | ST-006 | SUC-003 | TA-016 | Replayed GP action is idempotent | Medium |
| SEC-012 | GP access control | SEC | UC-003 | ST-003, SAC-003 | SUC-003 | TA-017 | GP cannot approve/decline other GPs' requests | Critical |
| PERF-001 | Prescription list load time < 2s | PERF | UC-001 | — | — | TA-018 | Prescription list renders within 2 seconds | Medium |
| PERF-002 | Notification delivery < 5 min | PERF | UC-004 | — | — | TA-019 | Notification sent within 5 minutes | Medium |
| PRV-001 | GDPR compliance | PRV | UC-001, UC-002, UC-003, UC-004 | PT-004 | PUC-002, PUC-004, PUC-005, PUC-006 | TA-020 | Data processing aligns with GDPR | Critical |
| PRV-002 | Lawful basis documentation | PRV | UC-001, UC-002, UC-003 | PT-004 | PUC-005 | TA-021 | Lawful basis documented for each processing | High |
| PRV-003 | Data minimisation for notifications | PRV | UC-004 | PT-001, SAC-004, PAC-001 | PUC-001 | TA-022 | Notifications do not contain full GP notes | High |
| PRV-004 | Data retention and deletion policy | PRV | UC-001, UC-002, UC-003, UC-004 | PT-005, PAC-002 | PUC-002 | TA-023 | Old records automatically deleted per policy | High |
| PRV-005 | Consent for notifications | PRV | UC-004 | PT-004 | PUC-003 | TA-024 | Explicit consent obtained before notifications sent | High |
| PRV-006 | Privacy notice | PRV | All | PT-004, PAC-003 | PUC-004 | TA-025 | Privacy notice accessible and clear | Medium |
| PRV-007 | Data subject rights | PRV | UC-005, UC-006 | PT-004 | PUC-006 | TA-026 | Data export, deletion, portability features functional | High |
| PRV-008 | Supply chain security | PRV | UC-004 | ST-004, SAC-004 | SUC-004, PUC-008 (DPA) | TA-027 | Third-party vendors have DPAs and security assessments | High |
| COMP-001 | NHS Digital DSPT compliance | COMP | All | — | SUC-008, SUC-001, SUC-004, SUC-006 | TA-028 | NHS DSPT controls implemented | High |
| COMP-002 | Data Protection Impact Assessment | COMP | UC-002, UC-003 | — | PUC-005 | TA-029 | DPIA completed and documented | Medium |
| COMP-003 | Breach detection and reporting | COMP | All | ST-001, ST-002, ST-004, ST-009 | SUC-008 | TA-030 | Incident response plan documented; breach reporting tested | High |
| COMP-004 | Secure notification delivery | COMP | UC-004 | ST-004, SAC-004 | SUC-004 | TA-031 | Email/SMS delivery via authenticated TLS APIs | Critical |
| COMP-005 | NIS2 applicability assessment | COMP | All | — | — | TA-032 | NIS2 assessment completed (if applicable) | High |

---

## 9. Test Artifacts

### 9.1 Functional Security Tests

---

#### TA-001: Prescription List Retrieval Functional Test
**Type:** Functional Security Test
**Requirement(s):** FR-001, SEC-003
**Scenario:** Authenticated patient requests their prescription list via GET /api/prescriptions; system correctly retrieves and displays only the patient's prescriptions.

**Test approach:** Unit test + Integration test
- Unit: Verify that the API endpoint enforces `patientId == authenticated_user.patient_id`
- Integration: Test FHIR API call with valid patient ID; verify response contains correct prescriptions

**Expected outcome:**
- API returns 200 OK with prescription list
- Returned prescriptions belong only to the authenticated patient
- Medications, dosages, dates are correctly parsed from FHIR response
- Response is within 2 seconds

**Automation potential:** High

---

#### TA-006: NHS Login Token Validation Test
**Type:** Functional Security Test
**Requirement(s):** SEC-001, SEC-005
**Scenario:** Test that the portal validates NHS login session token on each API request.

**Test approach:** Integration test
- Send API request with valid token; verify request is processed
- Send API request with expired token; verify request is rejected (401 Unauthorized)
- Send API request with invalid/malformed token; verify request is rejected
- Send API request without token; verify request is rejected

**Expected outcome:**
- Valid token: 200 OK
- Expired/invalid token: 401 Unauthorized
- No token: 401 Unauthorized
- Error message does not reveal why token is invalid (e.g., "Unauthorized" not "Token expired")

**Automation potential:** High

---

#### TA-009: FHIR Input Validation Test
**Type:** Functional Security Test
**Requirement(s):** SEC-004
**Scenario:** Test that malicious input to FHIR API is rejected or sanitised.

**Test approach:** Unit + Integration test
- Test with malicious prescriptionId values: `id=001' OR '1'='1`, `id=<script>alert(1)</script>`, `id=../../etc/passwd`
- Verify that each malicious input is either rejected (400 Bad Request) or sanitised before forwarding to FHIR API
- Verify FHIR API response is validated against expected schema

**Expected outcome:**
- Malicious input is rejected or encoded
- FHIR response is validated; unexpected fields or data types are rejected
- No injection attacks succeed

**Automation potential:** High

---

#### TA-012: Secrets Not in Source Code Test
**Type:** Functional Security Test
**Requirement(s):** SEC-007
**Scenario:** Automated scan of source code and configuration files for hardcoded secrets.

**Test approach:** Automated static analysis
- Use tools like TruffleHog, git-secrets, or GitHub Secret Scanning to scan all committed files
- Check environment variable files, .env files, code comments, strings
- Verify all secrets are stored in a vault (e.g., AWS Secrets Manager)

**Expected outcome:**
- No hardcoded API keys, database credentials, or tokens found
- All secrets are retrieved from vault at runtime
- Build pipeline rejects commits with detected secrets

**Automation potential:** High

---

#### TA-014: Audit Logging Comprehensive Test
**Type:** Functional Security Test
**Requirement(s):** SEC-009
**Scenario:** Verify that all security-relevant actions are logged.

**Test approach:** Integration test + Audit log inspection
- Perform actions: view prescriptions, submit refill, approve/decline
- Query audit log for corresponding entries
- Verify log entries contain: timestamp, user_id, action, resource_id, result, IP address (optional)

**Expected outcome:**
- All actions are logged
- Log entries are immutable (cannot be modified or deleted)
- Logs are retained per retention policy

**Automation potential:** Medium

---

#### TA-024: Notification Consent Test
**Type:** Functional Security Test
**Requirement(s):** PRV-005, COMP-004
**Scenario:** Verify that notifications are only sent to patients who have consented.

**Test approach:** Integration test
- Create test patient with notification consent = false
- Approve a refill request for that patient
- Verify no notification is sent
- Change consent to true; approve another refill
- Verify notification is sent

**Expected outcome:**
- Notifications respect patient consent preferences
- Logs show when consent is changed

**Automation potential:** High

---

### 9.2 Security Attack Tests

---

#### TA-008: Broken Object-Level Authorization (BOLA) Test
**Type:** Security Attack Test
**Abuse case(s):** SAC-001, ST-001
**Attack scenario:** Authenticated patient attempts to access another patient's prescriptions by modifying the patientId parameter.

**Test approach:** Automated API security test
- Authenticate as Patient A
- Request: GET /api/prescriptions?patientId=PATIENT_B_ID
- Verify request is rejected (403 Forbidden) or returns Patient A's prescriptions only

**Suggested tools:** OWASP ZAP (Automated Scan), Burp Suite, custom script (curl, Python requests)

**Expected outcome:** Request is rejected; Patient A cannot access Patient B's data

---

#### TA-017: GP Authorization Bypass Test
**Type:** Security Attack Test
**Abuse case(s):** SAC-003, ST-003
**Attack scenario:** GP A attempts to approve a refill request assigned to GP B.

**Test approach:** Automated API test
- Authenticate as GP A
- Request: POST /api/refill-requests/{requestId_belonging_to_gp_b}/approve
- Verify request is rejected (403 Forbidden)

**Suggested tools:** Burp Suite, custom script

**Expected outcome:** Request is rejected; GP A cannot approve requests outside their authority

---

#### TA-011: Rate Limiting DDoS Test
**Type:** Security Attack Test
**Abuse case(s):** SAC-005, ST-008
**Attack scenario:** Authenticated patient submits 100 refill requests within 1 minute.

**Test approach:** Automated load test
- Write script to submit refill requests rapidly
- Verify rate limiter responds with 429 Too Many Requests after limit is exceeded

**Suggested tools:** Apache JMeter, Locust, custom script

**Expected outcome:**
- Requests within limit: 200 OK
- Requests exceeding limit: 429 Too Many Requests
- Retry-After header is present

---

#### TA-007: Cryptographic Failures Test
**Type:** Security Attack Test
**Abuse case(s):** SAC-004, ST-004
**Attack scenario:** Verify that all data in transit is encrypted with TLS 1.3+.

**Test approach:** Network analysis
- Use tools like Wireshark or browser dev tools to inspect API calls
- Verify all HTTP requests are redirected to HTTPS
- Verify TLS version is 1.3 or higher
- Verify certificate is valid and matches domain

**Suggested tools:** Wireshark, SSL Labs (https://www.ssllabs.com/), nmap

**Expected outcome:**
- All requests use HTTPS
- TLS 1.3+ is enforced
- Certificate is valid and trusted

---

### 9.3 Privacy Verification Tests

---

#### TA-022: Data Minimisation in Notifications Test
**Type:** Privacy Verification
**Requirement(s):** PRV-003, PUC-001
**Scenario:** Verify that decline notifications do not contain full GP notes.

**Test approach:** Manual audit / Automated content inspection
- GP declines a refill with detailed notes: "Patient requires liver function test before antidepressant refill due to suspected alcohol misuse"
- Approve the refill; capture the notification (email/SMS) sent to patient
- Verify notification contains: "Your refill has been declined. Please contact your GP for details."
- Verify notification does NOT contain: Full GP notes, mental health references, substance abuse mentions
- Verify patient can log into portal and view the detailed reason (under authentication)

**Expected outcome:**
- Notification is minimised and does not leak sensitive details
- Patient has access to full reason via authenticated portal link

---

#### TA-023: Data Retention and Deletion Test
**Type:** Privacy Verification
**Requirement(s):** PRV-004, PUC-002
**Scenario:** Verify that old refill request records are automatically deleted.

**Test approach:** Automated audit / Manual data inspection
- Create test refill request with creation date 7 years ago
- Run deletion batch job
- Query database for the test record
- Verify record is deleted (or soft-deleted and scheduled for hard-delete after 30 days)

**Expected outcome:**
- Records older than retention period are deleted
- Deletion logs record what was deleted and when

---

#### TA-025: Privacy Notice Accessibility Test
**Type:** Privacy Verification
**Requirement(s):** PRV-006
**Scenario:** Verify that privacy notice is accessible, clear, and contains required information.

**Test approach:** Manual audit + Accessibility check
- Navigate to privacy notice
- Verify it contains: data controller identity, purpose, lawful basis, recipients, retention, data subject rights, complaint process
- Verify it is written in clear language (no jargon)
- Verify it is accessible (large font, readable color contrast, WCAG 2.1 AA compliant)
- Verify it is prominently linked from portal homepage and onboarding

**Expected outcome:**
- Privacy notice is comprehensive, clear, and accessible
- All required GDPR information is present

---

#### TA-026: Data Subject Rights Implementation Test
**Type:** Privacy Verification
**Requirement(s):** PRV-007, PUC-006
**Scenario:** Verify that patients can exercise GDPR rights.

**Test approach:** Manual + Automated test
- Access: Authenticated patient clicks "Download my data" → system generates export in JSON/CSV → download succeeds
- Erasure: Patient submits erasure request → system deletes/anonymises eligible records → verify deletion
- Portability: Patient requests data export; verify format is machine-readable

**Expected outcome:**
- All GDPR rights are functional
- Data is exported in correct format within 30 days

---

### 9.4 Penetration Testing Scenarios

---

#### TA-030: Incident Response and Breach Notification Simulation
**Type:** Penetration Test Scenario
**Scope:** Entire refill module; assume a data breach has occurred (e.g., SQL injection exposed 100 patient records).

**Objectives:**
1. Verify incident detection: Alert systems trigger when suspicious activity is detected
2. Verify incident response: Team is notified; incident is logged and categorized
3. Verify breach notification: Determine if breach is high-risk; notify affected patients and ICO within 72 hours
4. Verify remediation: Root cause is identified and fixed

**Key abuse cases to validate:**
- ST-002 (FHIR API injection) leading to patient data disclosure
- ST-009 (hardcoded credentials) leading to unauthorized database access

**Out of scope:**
- Physical security (data center access)
- Social engineering (phishing attacks on staff)

---

#### TA-031: End-to-End GP Impersonation Test
**Type:** Penetration Test Scenario
**Scope:** GP login, task queue access, refill approval/decline.

**Objectives:**
1. Attempt to login as a GP without valid credentials
2. If login succeeds, attempt to access another GP's task queue
3. Attempt to approve/decline requests for patients not in care
4. Log all actions and verify they are caught by audit logs or access control

**Key abuse cases to validate:**
- ST-007 (session hijacking)
- ST-003 (GP authorization bypass)
- SAC-003 (GP approves other GPs' requests)

**Out of scope:**
- NHS login vulnerabilities (assumed to be secure)

---

#### TA-033: GDPR Data Subject Rights Fulfillment Test
**Type:** Penetration Test Scenario
**Scope:** Data subject access requests, deletion requests, portability requests.

**Objectives:**
1. Submit a data access request and verify all personal data is exported correctly
2. Request deletion of data; verify deletion is completed within 30 days
3. Request data portability; verify format is machine-readable and complete
4. Verify audit logs show all access requests

**Key privacy threats to validate:**
- PT-004 (Unawareness of data collection)
- PT-005 (Non-compliance with data retention)
- PAC-002 (GP notes retained indefinitely)

**Out of scope:**
- Right to be forgotten exceptions (clinical records retention)

---

## Appendix A: STRIDE Reference

**STRIDE** is a threat modeling framework developed by Microsoft. Each category represents a class of security threat:

| Category | Description | Example |
|----------|-------------|---------|
| **Spoofing Identity** | Pretending to be someone or something else (authentication bypass) | An attacker uses a stolen NHS login token to impersonate a patient |
| **Tampering with Data** | Modifying data in transit or at rest | Changing a refill request status from "pending" to "approved" without authorization |
| **Repudiation** | Denying responsibility for an action; inability to prove who did what | A GP claims they never approved a refill; no audit trail exists |
| **Information Disclosure** | Leaking sensitive data to unauthorized parties | Prescriptions visible to other patients; notifications intercepted |
| **Denial of Service** | Making the system unavailable to legitimate users | Flooding refill requests to overwhelm GPs and database |
| **Elevation of Privilege** | Gaining higher levels of access than authorized (e.g., user → admin) | Patient accessing another patient's prescriptions; GP approving requests outside their scope |

---

## Appendix B: LINDDUN Reference

**LINDDUN** is a privacy threat modeling framework developed by KU Leuven. Each category represents a class of privacy threat:

| Category | Description | Example |
|----------|-------------|---------|
| **Linkability** | Connecting two pieces of information to an individual across contexts | Linking prescription refill requests by timestamp to identify medication use patterns |
| **Identifiability** | Re-identifying a person from supposedly anonymous data | Inferring patient identity from combination of medication type, GP, and request date |
| **Non-Repudiation** | Inability to deny an action; permanent record of user's activities (harms the user) | GP's approval/decline actions logged and used against them in disciplinary proceedings |
| **Detectability** | Ability to detect that data about a person exists, even without reading it | Knowing someone is using the refill service from metadata, even if prescription details are hidden |
| **Disclosure of Information** | Personal data exposed beyond intended scope | GP notes containing sensitive health information sent in email notification |
| **Unawareness** | User unaware of what data is collected or how it's used | Patient doesn't know audit logs record all prescription accesses |
| **Non-Compliance** | System fails to meet legal or regulatory requirements | Data accumulated without deletion policy; GDPR storage limitation violated |

---

## Appendix C: OWASP Top 10 (2021) Quick Reference

| Rank | Category | Risk | Mitigation |
|------|----------|------|-----------|
| **A01** | Broken Access Control | Users can access data/functions they shouldn't | Implement RLAC, server-side authorization checks, least privilege |
| **A02** | Cryptographic Failures | Sensitive data exposed in transit or at rest | Use TLS 1.3+, encrypt sensitive data at rest, secure key management |
| **A03** | Injection | Malicious input interpreted as code (SQL, OS, XPath) | Input validation, parameterised queries, output encoding |
| **A04** | Insecure Design | Flawed architecture or business logic | Threat modeling, security requirements, secure SDLC |
| **A05** | Broken Authentication | Session/credential compromise | MFA, strong session management, token rotation, logout |
| **A06** | Software and Data Integrity Failures | Untrusted dependencies or updates | Dependency scanning (SBOM), secure supply chain, code signing |
| **A07** | Identification and Authentication Failures | Users cannot be reliably identified | Strong authentication, audit logging, session invalidation |
| **A08** | Software and Data Integrity Failures | Vulnerable components, insecure CI/CD | Keep dependencies patched, secure artifact repository |
| **A09** | Logging and Monitoring Failures | Security incidents not detected | Audit logging, alerting, log retention, incident response |
| **A10** | Server-Side Request Forgery (SSRF) | Server makes unintended requests | Input validation, allow-list URLs, network segmentation |

---

## Appendix D: GDPR Privacy by Design Principles

The **7 foundational principles of Privacy by Design** (GDPR Article 5 and ICO guidance):

1. **Proactive not Reactive**
   - Address privacy risks before they occur, not after breaches
   - Conduct threat modeling, DPIA, privacy impact assessments upfront

2. **Privacy as Default**
   - Minimize data collection by default; opt-in for any secondary uses
   - Example: Notification preferences are opt-in; refill requests are only shared with assigned GP, not broadcast

3. **Privacy Embedded into Design**
   - Embed privacy into system architecture, not as an add-on
   - Example: Retention policy and deletion process are built into schema and automated, not manual

4. **Full Functionality**
   - Achieve privacy goals without sacrificing core system functionality
   - Example: GPs need to see patient notes for clinical decision-making; don't strip all context, but redact before patient notification

5. **End-to-End Security**
   - Protect data throughout its lifecycle (collection, storage, use, sharing, deletion)
   - Example: Encryption in transit (TLS), at rest (database encryption), secure deletion

6. **Visibility and Transparency**
   - Users must know what data is collected, how it's used, and have clear mechanisms to exercise rights
   - Example: Privacy notice, data export feature, user control over notification preferences

7. **Respect for User Privacy**
   - Keep users' interests central; implement strong access controls and audit
   - Example: Patient cannot see GP notes beyond what's necessary for their care; GP cannot see other GPs' decisions

---

## Appendix E: Regulatory Compliance Summary

### GDPR (General Data Protection Regulation)
**Scope:** The refill module processes personal data (NHS number, DOB, contact, medication, refill requests, GP notes) of EU and UK residents.

**Key Obligations:**
- **Lawful basis (Article 6):** Document why data is processed (contract, consent, legal obligation, legitimate interest)
  - Refill request submission: Contract (patient-NHS relationship)
  - GP access to request: Legal obligation (duty of care) + Legitimate interest (efficient healthcare)
  - Notifications: Consent (patient opts in)
  - Audit logging: Legal obligation (NHS records retention, GDPR accountability)

- **Transparency (Article 13/14):** Provide privacy notice explaining what data is collected, why, who has access, how long it's kept, and data subject rights
  - **Compliance gap found:** No privacy notice exists (PRV-006 [NEW])

- **Data minimisation (Article 5(1)(c)):** Only collect/process data necessary for purpose
  - **Compliance gap found:** Unclear whether GP notes in notifications are minimised (PRV-003 [NEW])

- **Storage limitation (Article 5(1)(e)):** Delete data when no longer necessary
  - **Compliance gap found:** No retention/deletion policy (PRV-004 [NEW])

- **Data subject rights (Articles 15–20):**
  - Right of access (Article 15): Patient can request copy of all personal data
  - Right to erasure (Article 17): Patient can request deletion (with limitations for clinical records)
  - Right to portability (Article 20): Patient can request data in machine-readable format
  - Right to rectification (Article 16): Patient can correct inaccurate data
  - **Compliance gap found:** No portal features implemented for these rights (PRV-007 [NEW])

- **Security (Article 32):** Implement appropriate technical and organisational measures to secure data
  - Encryption in transit (TLS) ✓ (SEC-002)
  - Encryption at rest (database) [NEW — gap]
  - Access control (RLAC) [NEW — SEC-003]
  - Audit logging [NEW — SEC-009]

- **Data Protection Impact Assessment (Article 35):** Required when processing large amounts of special category data (healthcare, mental health) with automated decision-making or profiling
  - **Required for this system:** Yes, because refill requests involve healthcare data (prescription, medication) and GP decisions
  - **Compliance gap:** DPIA not mentioned (COMP-002 [NEW])

- **Breach notification (Article 33):** Notify supervisory authority (ICO) within 72 hours of becoming aware of a breach; notify affected individuals without undue delay if high risk
  - **Compliance gap:** No incident response process (COMP-003 [NEW])

**GDPR Fines for Violations:**
- Article 83(4) — Low-risk breaches (e.g., incorrect transparency info): up to EUR 10 million or 2% of global annual turnover
- Article 83(5) — High-risk breaches (e.g., unauthorized access, storage limitation violations, security failures): up to EUR 20 million or 4% of global annual turnover

**Compliance Requirements Generated:**
- PRV-002: Lawful basis documentation
- PRV-004: Data retention and deletion policy
- PRV-005: Consent for notifications
- PRV-006: Privacy notice
- PRV-007: Data subject rights implementation
- COMP-002: Data Protection Impact Assessment
- COMP-003: Breach detection and reporting

---

### NHS Digital Data Security and Protection Toolkit (DSPT)
**Scope:** The portal operator (NHS trust or healthcare provider) must meet baseline controls for NHS systems.

**Key Obligations:**
- **Data security standards:** Implement controls across 10 domains: information governance, security policy, personnel security, asset management, access control, cryptography, physical and environmental security, operations security, communications security, system acquisition/development/maintenance

- **Relevant controls for refill module:**
  - Access control: Users authenticated and authorized (RLAC) ✓ (SEC-003)
  - Encryption: Data in transit (TLS) ✓ (SEC-002), data at rest [NEW — gap]
  - Audit logging: All access logged ✓ (SEC-009)
  - Incident management: Breach detected and reported [NEW — COMP-003]
  - Third-party management: SMS/email providers assessed and DPAs signed [NEW — PRV-008, COMP-004]

**Compliance Requirements Generated:**
- COMP-001: NHS Digital DSPT compliance (existing requirement)
- All SEC and PRV controls above support DSPT compliance

---

### NIS2 Directive (Network and Information Security Directive)
**Scope:** If the portal operator is an NHS trust or classified as an "essential entity" under NIS2 (healthcare, digital infrastructure, managed services), the organisation must comply with NIS2.

**Key Obligations:**
- **Risk management:** Develop and implement cybersecurity risk management measures
- **Incident reporting:** Detect and report significant incidents within 24 hours (early warning) and 72 hours (full notification) to national authority (NCSC in UK)
- **Supply chain security:** Assess suppliers (SMS/email providers) for security
- **Business continuity:** Maintain crisis management and disaster recovery plans
- **MFA and privileged access:** Require MFA for staff; implement PAM (Privileged Access Management)
- **Encryption:** Encrypt data in transit and at rest

**Status for Refill Module:**
- NIS2 does not apply directly to system design; it is an organisational obligation
- However, the design must support NIS2 compliance: audit logging (incident reporting), encryption, supply chain security, and availability
- **Compliance requirements:** COMP-005 (NIS2 applicability assessment)

**Note:** As of 2026-03-31, NIS2 transposition deadline for EU member states is October 2024. The UK (no longer EU member) has parallel NIS Regulations (UK equivalent) with similar obligations. Clarify whether the portal operator is NIS2/NIS subject.

---

### UK Data Protection Act 2018
**Scope:** Complements GDPR for UK data subjects.

**Key Obligations:**
- Schedule 2 (conditions for lawful processing): Document lawful basis for each processing activity
- Schedule 3 (conditions for processing special category data): Healthcare data requires explicit lawful basis (contract, consent, or substantial public interest)
- Part 4 (rights of data subjects): Implement GDPR Articles 15–22 in UK context

**Compliance:** Largely covered by GDPR requirements above.

---

### UK PSTI Act 2022 (Product Security and Telecommunications Infrastructure Act)
**Scope:** Applies to consumer connectable devices (IoT) sold in UK (e.g., smart thermostats, connected cameras).

**Applicability to Refill Module:** **NOT APPLICABLE** — The module is a healthcare portal (web service), not a consumer device. No PSTI obligations.

---

### EU Cyber Resilience Act (CRA)
**Scope:** Applies to products with digital elements (software or hardware) sold in EU market. Mandates security by design, SBOM, vulnerability disclosure, incident reporting, and security updates.

**Applicability to Refill Module:** **OUT OF SCOPE** — The module is pure SaaS with no downloadable software, installed client, firmware, or embedded components. CRA currently does not apply to pure SaaS services. However, if the portal included a downloadable mobile app (iOS/Android), CRA would apply. Clarify with compliance team if future mobile app is planned.

**Note:** CRA interpretation continues to evolve; consult legal/compliance team if unsure.

**Compliance Status:** No CRA obligations; no SBOM, incident reporting to ENISA, or security update lifetime declarations required for SaaS scope.

---

### UK Equality Act 2010
**Scope:** Prohibits discrimination based on protected characteristics (age, disability, gender, race, religion, sexual orientation, etc.).

**Relevant to Refill Module:**
- If prescription/health data is exposed (e.g., antidepressants, antiretrovirals), could be used for discrimination (employment, insurance, housing)
- Example: PT-001 (Linkability) and PAC-001 (Medication history used for discrimination)
- Control: Data minimisation, encryption, secure deletion (PRV-003, PRV-004, SEC-007)

**Compliance Status:** Indirectly supported by privacy and security controls above.

---

### HIPAA (US Health Insurance Portability and Accountability Act)
**Scope:** Applies to healthcare providers and covered entities in the US.

**Applicability to Refill Module:** **NOT APPLICABLE** — The system is deployed in UK, serving UK/EU patients, not US healthcare system. If the operator later expands to US, HIPAA would apply.

---

### PCI-DSS (Payment Card Industry Data Security Standard)
**Scope:** Applies to organizations that handle credit card payments.

**Applicability to Refill Module:** **NOT APPLICABLE** — The module does not process payments. If the portal includes a pharmacy payment system in future, PCI-DSS would apply.

---

## Summary: Compliance Obligations by Regulation

| Regulation | Applicable? | Key Gaps Found | Req IDs Generated |
|---|---|---|---|
| **GDPR** | **YES** | Lawful basis, privacy notice, data retention, data subject rights, DPIA, breach reporting | PRV-002, PRV-004, PRV-005, PRV-006, PRV-007, COMP-002, COMP-003 |
| **NHS Digital DSPT** | **YES** | Data minimisation in notifications, encryption at rest, third-party DPAs | PRV-003, PRV-008, COMP-004 |
| **NIS2 / NIS Regulations** | **Likely** (confirm with compliance) | Incident reporting capability, supply chain security | COMP-005 |
| **Data Protection Act 2018** | **YES** | Covered by GDPR + lawful basis documentation | PRV-002 |
| **UK Equality Act 2010** | **Indirect** | Privacy controls to prevent discrimination via data leakage | PRV-003, PRV-004, SEC-007 |
| **PSTI Act 2022** | **NO** | Not applicable (not IoT consumer device) | — |
| **CRA (EU Cyber Resilience Act)** | **NO** | Not applicable (pure SaaS, no downloadable components) | — |
| **HIPAA** | **NO** | Not applicable (UK deployment, not US healthcare) | — |
| **PCI-DSS** | **NO** | Not applicable (no payment processing) | — |

---

## Final Compliance Checklist

**Before launch, verify:**

- [ ] GDPR lawful basis documented for all processing activities (PRV-002, COMP-001)
- [ ] Privacy notice created and prominently linked (PRV-006)
- [ ] Data retention and deletion policy implemented (PRV-004)
- [ ] Patient consent mechanism for notifications functional (PRV-005)
- [ ] Data subject rights (access, erasure, portability) implemented (PRV-007)
- [ ] Data Protection Impact Assessment (DPIA) completed (COMP-002)
- [ ] Incident response plan documented; breach reporting tested (COMP-003)
- [ ] Third-party SMS/email providers have Data Processing Agreements (DPA) (COMP-004, PRV-008)
- [ ] NIS2/NIS applicability assessed (COMP-005)
- [ ] NHS Digital DSPT controls implemented (COMP-001)
- [ ] All security requirements (SEC-001 through SEC-012) implemented and tested
- [ ] All privacy controls (PUC-001 through PUC-006) implemented and audited

---

**END OF ANALYSIS**

Document prepared following the Secure and Privacy by Design skill framework.
All sections completed: Executive Summary, Problem Space, Requirements Classification, Use Cases, Threat Analysis (STRIDE + LINDDUN), Abuse Cases, Counter-Use Cases, Refined Requirements, SRTM, Test Artifacts, Appendices (STRIDE, LINDDUN, OWASP Top 10, GDPR PbD, Regulatory Compliance).
