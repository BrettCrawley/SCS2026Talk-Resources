# Security and Privacy by Design Analysis: Healthcare Patient Portal – Prescription Refill Feature
**Date:** 2026-03-30
**Version:** 1.0
**Frameworks:** STRIDE · LINDDUN · OWASP Top 10 · GDPR / Privacy by Design

---

## Executive Summary

This analysis examines a new prescription refill request feature for a UK healthcare patient portal. The feature allows patients to view and request refills for active prescriptions, with GP approvals and patient notifications. The system integrates with an existing EHR via HL7 FHIR API and leverages NHS login authentication.

**Key Security Risks:**
1. **Unauthorized prescription access** — lateral movement between patient accounts or cross-patient data exposure via the FHIR API integration
2. **Tampering with refill requests** — a patient modifying their own or another's refill request status before GP review
3. **Denial of Service on GP queue** — attackers flooding the system with bogus refill requests, blocking legitimate medical work
4. **Authentication bypass in NHS login integration** — session hijacking or token theft could allow attacker access to another patient's portal account

**Key Privacy Risks:**
1. **Identifiability of prescription data** — prescription patterns linked to patient identity in logs, breach notifications, or third-party audits
2. **Linkability across systems** — prescription refill data linked to patient actions in other NHS systems or commercial healthcare analytics
3. **Non-compliance with GDPR data minimisation** — excessive collection of prescription metadata or refill attempt history
4. **Unawareness of data use** — patients not informed that refill requests create permanent audit records or may be shared with pharmacy systems

**Top 5 Recommended Priorities:**
1. Implement strict API-level authorization checks on FHIR queries to prevent cross-patient prescription access (ST-001, SAC-001)
2. Design immutable audit logs for refill requests with cryptographic integrity checks to prevent tampering (ST-003, SAC-003)
3. Establish rate limiting and abuse detection on refill request submission to protect GP queue (ST-005, SAC-005)
4. Define and enforce a 90-day data retention policy for refill request metadata with automated deletion (PRV-007, PAC-007)
5. Develop a comprehensive Privacy Notice explaining prescription data flows, retention, and patient rights (PRV-001, PAC-001)

---

## 1. Assumptions and Context

### Problem Statement
A UK-based healthcare provider is building a new online prescription refill request feature within an existing NHS-integrated patient portal. Patients will view their active prescriptions (pulled from the EHR via FHIR API), submit refill requests, receive status notifications, and GPs will approve or decline requests with optional notes. The portal already handles NHS login authentication.

### Essential Context Answers

**1. What is being built?**
An online prescription refill workflow module enabling:
- Patient view of active prescriptions from the EHR
- Patient submission of refill requests
- GP review queue and approval/decline actions
- Patient notification on status changes (email or SMS)
- GP ability to add decline reasons

**2. Who are the actors?**
- **Patients**: authenticated NHS login users accessing their own prescriptions
- **GPs**: authorised healthcare professionals reviewing and actioning refill requests
- **EHR system**: backend system providing prescription data via FHIR API
- **Notification system**: email/SMS service sending status updates
- **Pharmacy systems** (future): may integrate to dispense approved refills
- **Background jobs**: process expired requests, cleanup old data

**3. What data does it handle?**
- **Prescription data**: medication name, dosage, frequency, prescriber, issue date, expiry date
- **Patient identifiers**: NHS number, name, DOB, contact details (for notifications)
- **Refill request metadata**: request ID, request date/time, patient ID, prescription ID, status, GP notes
- **Audit logs**: who accessed what, when, refill actions taken
- **Notification delivery**: email addresses or phone numbers (PII)
All data is sensitive health information subject to GDPR Article 9 special categories.

**4. How will it be deployed?**
- **Assumed**: UK-based cloud infrastructure (NHS Cloud or private cloud with NHS Digital compliance)
- **Assumed**: Internet-facing patient portal with NHS login (OpenID Connect)
- **Assumed**: Internal GP dashboard (may be on same platform or separate system)
- **Assumed**: Multi-tenant architecture (one deployment for the healthcare provider)

**5. Known regulatory/compliance requirements?**
- **GDPR**: Articles 5 (lawful processing), 6 (lawful basis), 9 (special categories), 17 (right to erasure), 32 (security), 33 (breach notification)
- **NHS Digital Standards**: Data Security and Protection Toolkit (DSPT) compliance, IG Toolkit requirements
- **Data Protection Act 2018**: UK implementation of GDPR
- **Common law duty of confidentiality**: healthcare data has special legal status
- **Implied**: PCI-DSS-like expectations for payment/billing integration (future)

### Significant Assumptions
1. **NHS login uses OAuth 2.0 / OpenID Connect** — tokens are short-lived (15–30 min), refresh tokens are secure
2. **FHIR API is internal or tightly controlled** — not public, requires API authentication (mutual TLS or OAuth)
3. **Patient notifications are asynchronous** — not real-time, so queue backpressure doesn't block refill submission
4. **GP queue is a single authoritative database** — no eventual consistency issues that could lose refill requests
5. **Backups and disaster recovery are in place** — data can be recovered in breach scenarios
6. **No integration with commercial analytics or third-party advertising** — data is not sold or shared beyond NHS ecosystem (yet)
7. **Portal is England-only for now** — GDPR Article 5(1)(e) (storage limitation) aligns with NHS retention guidance

---

## 2. Requirements Classification and Gap Analysis

### Original Requirements (Classified)

| ID | Requirement | Category |
|---|---|---|
| FR-001 | Patients can view their active prescriptions pulled from EHR via FHIR API | FR |
| FR-002 | Patients can submit a refill request for any active prescription | FR |
| FR-003 | Refill request creates a task in the GP's queue | FR |
| FR-004 | GPs can approve or decline refill requests | FR |
| FR-005 | GPs can add a note when declining a refill request | FR |
| FR-006 | Patients receive notifications (email/SMS) when GP approves or declines their request | FR |
| SEC-001 | Authentication uses existing NHS login integration | SEC |
| COMP-001 | System complies with GDPR and NHS Digital standards | COMP |

### Gap Analysis

**Security Gaps Identified:**

| Gap | Rationale | Becomes |
|---|---|---|
| No explicit authorization model defined | Who can view/action refill requests? Can a patient see another patient's refills? Can a GP action refills for patients not in their practice? | SEC-002, SEC-003 |
| No input validation or sanitization requirements | Refill request notes, prescription lookups, etc. are not validated | SEC-004 |
| No rate limiting or abuse protection | A malicious user could flood the GP queue or attempt brute-force FHIR queries | SEC-005 |
| No audit logging requirements | No mention of who did what, when, for non-repudiation | SEC-006 |
| No encryption in transit or at rest specified | FHIR API, notifications, stored refill requests | SEC-007, SEC-008 |
| No session management or timeout policy | How long are NHS login sessions valid? Can attackers hijack a session? | SEC-009 |
| No error handling guidance | Do error messages leak sensitive data? | SEC-010 |
| No dependency/supply chain security | What versions of FHIR libraries, notification SDKs? | SEC-011 |

**Privacy Gaps Identified:**

| Gap | Rationale | Becomes |
|---|---|---|
| No lawful basis defined for processing | Why collect prescription metadata, refill history, notification logs? | PRV-001 |
| No user consent mechanism | Are patients informed and consenting to data collection? | PRV-002 |
| No data minimisation policy | What refill metadata is actually needed? | PRV-003 |
| No retention/deletion policy | How long are refill requests kept? Are old records deleted? | PRV-004 |
| No data subject rights implementation | How do patients exercise right to access, erasure, portability? | PRV-005 |
| No third-party data sharing disclosure | Are notification records shared with analytics vendors? | PRV-006 |
| No breach detection/notification plan | What's the process if refill data is accessed by unauthorized parties? | PRV-007 |
| No Privacy Notice or transparency obligations | Patients may not know what data is collected or how it's used | PRV-008 |
| No DPIA trigger assessment | Processing special category data (health) may require a formal DPIA | COMP-002 |

---

## 3. Use Cases

### UC-001: Patient Views Active Prescriptions
**Actor:** Patient (authenticated via NHS login)
**Goal:** See current medications to decide which to refill
**Preconditions:**
- Patient is authenticated and logged in to the portal
- Patient's NHS number is known to the system
- EHR system is operational and accessible
- Patient has at least one active prescription

**Main Flow:**
1. Patient navigates to "My Prescriptions" in the portal
2. System calls FHIR API with patient's NHS number
3. EHR returns list of active prescriptions (status=active)
4. Portal displays prescriptions: medication name, dosage, frequency, prescriber, issue date, expiry date
5. Patient reviews list

**Postconditions:**
- Patient has viewed prescription data
- System has logged the access event

**Data involved:**
- Patient NHS number (lookup key)
- Prescription records (medication, dosage, dates)
- Audit log (patient ID, timestamp, action="view_prescriptions")

**Trust boundary crossings:**
- Patient portal (internet-facing) → FHIR API (internal/tightly controlled)
- Patient identity asserted by NHS login → EHR system authorization

---

### UC-002: Patient Submits Refill Request
**Actor:** Patient
**Goal:** Request a prescription refill from their GP
**Preconditions:**
- Patient is authenticated
- Patient has viewed active prescriptions
- Selected prescription is still active (not expired)

**Main Flow:**
1. Patient clicks "Request Refill" on a prescription
2. Portal displays a confirmation form (optional: allow patient to add a note)
3. Patient submits the refill request
4. System validates:
   - Patient is authenticated
   - Prescription ID belongs to this patient (authorization check)
   - Prescription is not expired
   - Prescription is not already requested for refill recently (abuse check)
5. System creates a refill request record (status=pending)
6. System adds the request to GP's queue
7. System triggers async notification job to notify GP
8. Portal displays confirmation to patient: "Your refill request has been submitted"

**Postconditions:**
- Refill request record created in database
- GP queue updated
- Audit log recorded
- Notification job queued

**Data involved:**
- Patient ID
- Prescription ID
- Refill request (ID, status, timestamp, patient notes if any)
- Audit log (patient ID, action="submit_refill_request", prescription ID, timestamp)

**Trust boundary crossings:**
- Patient portal → Database (internal)
- Patient portal → Notification system (internal)

---

### UC-003: GP Reviews and Actions Refill Request
**Actor:** GP (authenticated, authorised to prescribe for this patient)
**Goal:** Approve or decline a refill request and notify the patient
**Preconditions:**
- GP is authenticated and logged in (assumes GP portal or separate system)
- GP is authorized to prescribe for the patient (e.g., GP is in the patient's practice)
- A refill request in status=pending exists for a patient under this GP's care
- GP has sufficient clinical information to make a decision

**Main Flow:**
1. GP views their refill queue (filtered to their practice/patient list)
2. GP selects a pending refill request
3. GP reviews: patient name, NHS number, medication, last dispensed date, refill history
4. GP makes a decision:
   - **Approve**: GP clicks "Approve", system updates refill request status=approved, optionally creates a new prescription in EHR, queues notification to patient
   - **Decline**: GP clicks "Decline", optionally enters decline reason/note, system updates status=declined, queues notification to patient
5. System logs the action (who, when, decision)
6. Patient is notified asynchronously

**Postconditions:**
- Refill request status updated
- Audit log recorded (GP ID, decision, timestamp)
- Patient notification queued
- If approved: new prescription record may be created in EHR (out of scope for this analysis, but noted)

**Data involved:**
- Refill request (ID, status, notes, timestamp)
- Audit log (GP ID, action, decision, timestamp, optional decline reason)
- Patient ID (for notification)

**Trust boundary crossings:**
- GP portal → Database (internal)
- Database → Notification system (internal)

---

### UC-004: Patient Receives Notification
**Actor:** Notification system (async job)
**Goal:** Deliver status update to patient via email or SMS
**Preconditions:**
- Refill request status has been updated (approved or declined)
- Patient has a valid email or phone number on file
- Notification service is operational

**Main Flow:**
1. Background job polls for pending notifications
2. For each pending notification:
   - Fetch refill request details
   - Fetch patient contact details (email/phone)
   - Compose notification (text for email/SMS)
   - Send via email provider (e.g., SendGrid) or SMS provider (e.g., Twilio)
   - Log send event
   - Mark notification as sent
3. Retry on failure (exponential backoff)

**Postconditions:**
- Notification sent (or retried/failed)
- Audit log includes notification event

**Data involved:**
- Patient email/phone (PII)
- Refill request summary (medication, status, decline reason if any)
- Audit log (notification ID, recipient, timestamp, success/failure)

**Trust boundary crossings:**
- Database → External email/SMS provider (internet)
- Data exposed to third-party notification service

---

## 4. Threat Analysis

### 4.1 Security Threats (STRIDE)

#### ST-001: Cross-Patient Prescription Access via FHIR API
**STRIDE category:** Information Disclosure / Elevation of Privilege
**Affected use case(s):** UC-001
**Description:**
A malicious user or compromised GP account could craft a crafted FHIR query to retrieve prescriptions for a patient other than themselves. If the FHIR API does not enforce strict authorization (i.e., checking that the querying user's NHS number matches the requested patient), an attacker could iterate through NHS numbers to harvest prescription data.

**Attack vector:**
1. Attacker authenticates as a legitimate user (patient or GP)
2. Attacker calls FHIR API endpoint: `/fhir/Medication?patient={target-nhs-number}`
3. If the API only validates that a request is authenticated (not that the authenticated user is the target patient), the API returns prescriptions for the target
4. Attacker harvests sensitive medication data

**Likelihood:** Medium — This is a common authorization flaw; depends on whether the FHIR API was designed with proper authorization controls. NHS systems vary in maturity.

**Impact:** High — Prescription data is sensitive health information. Disclosure to unauthorized parties violates GDPR and common law duty of confidentiality. Could enable blackmail, discrimination, or secondary use.

---

#### ST-002: Session Hijacking / NHS Login Token Theft
**STRIDE category:** Spoofing
**Affected use case(s):** UC-001, UC-002, UC-003, UC-004
**Description:**
If NHS login tokens are stored insecurely (e.g., in localStorage, without HttpOnly flag, or transmitted over non-HTTPS), an attacker could steal a session token and impersonate the patient/GP. This could be via XSS, network sniffing, or physical device access.

**Attack vector:**
1. Attacker obtains a patient's NHS login token (XSS, MITM, stolen laptop, etc.)
2. Attacker adds token to their own request headers
3. Attacker is now authenticated as the patient
4. Attacker can view prescriptions, submit refill requests, or modify the patient's account

**Likelihood:** Medium — Session theft is common; depends on whether the portal follows OAuth 2.0 and OWASP Session Management best practices.

**Impact:** High — Account takeover. Attacker gains full access to patient's health data and can manipulate their refill requests.

---

#### ST-003: Tampering with Refill Request Status
**STRIDE category:** Tampering
**Affected use case(s):** UC-002, UC-003
**Description:**
If refill request records are not immutable or cryptographically signed, an attacker with database access (or via an API endpoint that doesn't validate authorization) could modify the status of a refill request. For example, a malicious patient could approve their own request by changing status from pending to approved.

**Attack vector:**
1. Attacker gains database access (e.g., SQL injection, leaked credentials, or insider) or discovers an unprotected API endpoint
2. Attacker executes: `UPDATE refill_requests SET status='approved' WHERE id={target-request-id}`
3. Refill request is marked as approved without GP review
4. Pharmacy dispenses medication based on the forged approval

**Likelihood:** Medium — Depends on whether the refill_requests table has proper access controls and whether the API enforces that only GPs can approve.

**Impact:** High — Medication dispensed without clinical review is a patient safety and fraud risk. Could also be used to deny a legitimate refill (change status to declined).

---

#### ST-004: Input Validation / Injection Attacks
**STRIDE category:** Tampering / Information Disclosure
**Affected use case(s):** UC-002, UC-003
**Description:**
If patient notes or GP decline reasons are not validated, an attacker could inject SQL, JavaScript, or other payloads. For example:
- Patient notes: `'; DROP TABLE refill_requests; --`
- GP decline reason: `<script>alert('xss')</script>`

**Attack vector:**
1. Patient submits refill request with notes containing SQL injection payload
2. Notes are stored in database without sanitization
3. Later, when notes are displayed in GP portal, the payload executes (for XSS)
4. Or, if notes are logged/aggregated in a way that re-evaluates the string, SQL injection triggers

**Likelihood:** Medium — Depends on whether the system uses parameterized queries and encodes output.

**Impact:** Medium — Could lead to data exfiltration, denial of service, or XSS. Healthcare systems are high-value targets.

---

#### ST-005: Denial of Service – GP Queue Flooding
**STRIDE category:** Denial of Service
**Affected use case(s):** UC-002
**Description:**
Without rate limiting, an attacker could submit thousands of refill requests in rapid succession, overwhelming the GP queue and preventing legitimate refill requests from being processed. This could delay patient care.

**Attack vector:**
1. Attacker script submits refill requests for every prescription in a patient account (or across multiple accounts if they have access)
2. No rate limiting check exists; each request is accepted
3. GP queue grows to thousands of unreviewed requests
4. GPs cannot effectively triage; legitimate refill requests are lost in the noise

**Likelihood:** High — This attack requires no special privileges, just script automation.

**Impact:** Medium-High — Disruption to clinical workflow; patients may not receive needed medications on time.

---

#### ST-006: Insufficient Audit Logging / Non-Repudiation
**STRIDE category:** Repudiation
**Affected use case(s):** UC-001, UC-002, UC-003, UC-004
**Description:**
If the system does not log all access to prescriptions and all actions on refill requests, or if logs are not tamper-proof, a malicious GP could deny that they approved a refill for a patient they shouldn't have prescribed for. Similarly, a patient could deny submitting a refill request.

**Attack vector:**
1. Malicious GP approves a refill for a patient, then later deletes the log entry
2. When questioned, GP claims they never approved the refill
3. Without audit proof, investigation is inconclusive

**Likelihood:** Medium — Depends on whether logs are protected and backed up securely.

**Impact:** High — Cannot hold users accountable; audit trail is essential for healthcare compliance and patient safety investigations.

---

#### ST-007: Unencrypted Data in Transit
**STRIDE category:** Information Disclosure
**Affected use case(s):** UC-001, UC-002, UC-003, UC-004
**Description:**
If communication between the patient portal, EHR FHIR API, and notification services is not encrypted (HTTPS/TLS), an attacker on the network could intercept and read prescription data, refill requests, and patient contact details.

**Attack vector:**
1. Attacker performs network sniffing (MITM) on a shared network (e.g., public WiFi, unencrypted internal network)
2. Attacker intercepts FHIR API requests: `GET /fhir/Medication?patient=NHS123456`
3. Attacker sees prescription data in plaintext

**Likelihood:** Low-Medium — Depends on deployment environment (public cloud should have TLS; legacy on-prem systems may not).

**Impact:** High — Prescription data exposed to unauthorized parties.

---

#### ST-008: Unencrypted Data at Rest
**STRIDE category:** Information Disclosure
**Affected use case(s):** UC-001, UC-002, UC-003
**Description:**
If the database storing prescriptions, refill requests, and audit logs is not encrypted at rest, an attacker with physical or cloud access to storage could read sensitive data.

**Attack vector:**
1. Attacker gains access to database server (misconfigured cloud instance, stolen backup drive, etc.)
2. Attacker reads prescriptions and refill requests directly from unencrypted database files

**Likelihood:** Low — Assuming cloud provider or modern infrastructure with encryption enabled by default.

**Impact:** High — Large-scale data breach.

---

#### ST-009: Weak Session Management / Timeout
**STRIDE category:** Spoofing / Elevation of Privilege
**Affected use case(s):** UC-001, UC-002, UC-003
**Description:**
If NHS login sessions do not timeout or have excessively long timeouts, a stolen or hijacked session remains valid for a long time, increasing the window for exploitation.

**Attack vector:**
1. Attacker steals a patient's NHS login token
2. If session timeout is 8 hours (instead of 15 minutes), attacker has 8 hours to exploit the account
3. Attacker submits refill requests, views prescription data, modifies account settings

**Likelihood:** Medium — Depends on session timeout configuration.

**Impact:** High — Extended account compromise.

---

#### ST-010: Error Messages Leak Sensitive Data
**STRIDE category:** Information Disclosure
**Affected use case(s):** UC-001, UC-002, UC-003
**Description:**
If error messages include sensitive information (e.g., "Prescription ID 12345 not found" or "Patient NHS123456 has no refills"), an attacker could infer valid prescription/patient IDs and use this to craft further attacks.

**Attack vector:**
1. Attacker attempts to access a random prescription ID
2. Portal responds: "Error: Prescription 99999 not found for patient NHS000001"
3. Attacker now knows that prescription 99999 exists (or doesn't) and can enumerate valid prescriptions

**Likelihood:** Medium — Common in poorly designed APIs.

**Impact:** Low-Medium — Information disclosure. Used for enumeration attacks.

---

### 4.2 Privacy Threats (LINDDUN)

#### PT-001: Identifiability – Prescription Patterns Linked to Patient Identity
**LINDDUN category:** Identifiability
**Affected use case(s):** UC-001, UC-002
**Affected personal data:** Prescription records, medication names, dosages, patient NHS number
**Affected data subjects:** Patients
**Likelihood:** High — Prescription data is inherently linked to identity in the system design.
**Impact:** High — Prescription patterns (e.g., medications for mental health, HIV, cancer) are highly stigmatizing and sensitive. If a breach occurs, the link to patient identity is immediate and unavoidable.
**GDPR relevance:**
- Article 5(1)(b) – Purpose limitation: Prescriptions collected for healthcare should not be used for profiling, insurance discrimination, etc.
- Article 9 – Special categories: Health data requires explicit lawful basis (e.g., healthcare provision).

---

#### PT-002: Linkability – Refill Request History Across Systems
**LINDDUN category:** Linkability
**Affected use case(s):** UC-002, UC-003
**Affected personal data:** Refill request records, approval/decline decisions, GP notes, timestamps
**Affected data subjects:** Patients
**Likelihood:** High — Refill request records are stored long-term and could be linked across the NHS IT estate or third-party systems if shared.
**Impact:** High — A patient's medication adherence, refill patterns, and GP approval decisions could be linked across multiple NHS systems or sold to insurers/employers, enabling discrimination.
**GDPR relevance:**
- Article 6 – Lawful basis: Refill requests are processed for healthcare, but secondary uses (e.g., analytics, audits) must have a lawful basis.
- Article 5(1)(a) – Lawfulness: Linking refill data across systems without consent may violate the principle of lawfulness.

---

#### PT-003: Non-Repudiation – GP Actions Permanently Recorded
**LINDDUN category:** Non-Repudiation
**Affected use case(s):** UC-003
**Affected personal data:** GP ID, decisions, timestamps, patient identifiers
**Affected data subjects:** GPs (harmed by inability to deny actions), Patients (need accountability)
**Likelihood:** High — Audit logs are designed to be permanent.
**Impact:** Medium — While audit logs are necessary for patient safety and compliance, GPs may object to permanent recording of their decisions (e.g., if they feel a decline decision could be misinterpreted as negligent). However, this is a legal/ethical necessity, not a privacy harm.
**GDPR relevance:**
- Article 32 – Security: Audit logs must be protected from tampering.
- Article 5(1)(f) – Integrity and confidentiality: Logs must be secure.
**Note:** Non-repudiation is necessary for accountability; the harm here is mitigated by transparency and proper governance.

---

#### PT-004: Detectability – Refill Request Logs Reveal Existence of Patient Data
**LINDDUN category:** Detectability
**Affected use case(s):** UC-002, UC-003, UC-004
**Affected personal data:** Refill request IDs, timestamps, patient IDs, access logs
**Affected data subjects:** Patients
**Likelihood:** Medium — Logs are typically protected, but if logs are accessed by unauthorized parties (breach, insider), they reveal the existence of patient data.
**Impact:** Low-Medium — Detectability alone does not reveal the content of prescriptions, but confirms that a patient is using the system and has submitted requests on specific dates. This could be used to infer health status (e.g., if a patient submits many refill requests suddenly, inferring health crisis).
**GDPR relevance:**
- Article 32 – Security: Logs must be protected from unauthorized access.

---

#### PT-005: Disclosure – Prescription Data Exposed to Notification Service Providers
**LINDDUN category:** Disclosure
**Affected use case(s):** UC-004
**Affected personal data:** Patient email/phone, medication name, refill status, optional decline reason
**Affected data subjects:** Patients
**Likelihood:** High — Notifications must be sent to external email/SMS providers (e.g., SendGrid, Twilio) to reach patients.
**Impact:** High — Patient contact details and medication status are disclosed to third parties who may not be bound by GDPR (if outside UK/EU) or may have weaker security practices.
**GDPR relevance:**
- Article 28 – Data Processing Agreements: External providers must be Data Processors with a legally binding DPA.
- Article 44 onwards – Data Transfers: If providers are outside the UK, there must be a standard contractual clause (SCC) or UK adequacy decision in place.
- Article 6 – Lawful basis: Processing for patient notification is lawful, but the chain of processors must be documented.

---

#### PT-006: Unawareness – Patients Unaware of Refill Request Data Retention
**LINDDUN category:** Unawareness
**Affected use case(s):** UC-002, UC-003, UC-004
**Affected personal data:** All refill request records, audit logs, notification delivery records
**Affected data subjects:** Patients
**Likelihood:** High — If no Privacy Notice is provided, patients may not know that their refill requests are logged indefinitely.
**Impact:** Medium-High — Patients cannot make informed decisions about using the service if they don't know how long data is kept or who can access it. This violates GDPR transparency principles.
**GDPR relevance:**
- Article 13/14 – Information to be provided: Patients must be informed of data retention, purposes, and rights.
- Article 5(1)(a) – Transparency: Processing must be transparent to the data subject.

---

#### PT-007: Non-Compliance – Data Retention Exceeds NHS/GDPR Guidance
**LINDDUN category:** Non-Compliance
**Affected use case(s):** UC-002, UC-003
**Affected personal data:** Refill request records, audit logs
**Affected data subjects:** Patients
**Likelihood:** High — If no retention policy is defined, refill requests may be kept indefinitely, which exceeds NHS Information Governance guidance (typically 3–7 years for healthcare records).
**Impact:** High — Regulatory fine (up to €20M or 4% revenue) and reputational damage.
**GDPR relevance:**
- Article 5(1)(e) – Storage limitation: Data must be kept no longer than necessary.
- Article 17 – Right to erasure: Patients have the right to request deletion of data after a certain period.

---

#### PT-008: Non-Compliance – No Data Subject Rights Implementation
**LINDDUN category:** Non-Compliance
**Affected use case(s):** UC-001, UC-002, UC-003
**Affected personal data:** Prescriptions, refill requests, audit logs
**Affected data subjects:** Patients
**Likelihood:** High — If the portal does not provide mechanisms for patients to exercise GDPR rights (access, erasure, portability), it is non-compliant.
**Impact:** High — Regulatory violation; patients cannot exercise fundamental rights.
**GDPR relevance:**
- Article 15 – Right of access: Patients must be able to request a copy of their data.
- Article 17 – Right to erasure: Patients must be able to request deletion.
- Article 20 – Right to data portability: Patients must be able to request their data in a portable format.
- Article 21 – Right to object: Patients must be able to object to certain types of processing.

---

#### PT-009: Non-Compliance – No DPIA Conducted
**LINDDUN category:** Non-Compliance
**Affected use case(s):** UC-001, UC-002, UC-003, UC-004
**Affected personal data:** All (special category health data)
**Affected data subjects:** Patients
**Likelihood:** High — Processing of health data typically requires a DPIA under GDPR Article 35.
**Impact:** High — Regulatory violation; lack of due diligence.
**GDPR relevance:**
- Article 35 – Data Protection Impact Assessment: Mandatory for processing of special category data.
- Article 36 – Prior consultation: May require consulting the ICO if high risk is identified.

---

## 5. Abuse Cases

### 5.1 Security Abuse Cases

#### SAC-001: Cross-Patient Prescription Harvesting
**Linked threat:** ST-001
**Attacker type:** External authenticated (compromised patient account) or Insider (GP)
**Goal:** Harvest prescription data for multiple patients to sell to insurance companies, pharmaceutical companies, or use for blackmail.
**Attack Flow:**
1. Attacker compromises a patient account (phishing, credential stuffing) or is a rogue GP with access
2. Attacker writes a script to enumerate NHS numbers: `for i in 1000000000..9999999999: call FHIR /fhir/Medication?patient={i}`
3. Attacker captures all valid prescriptions (filtering out 404 responses)
4. Attacker harvests medication data for thousands of patients
5. Attacker sells data to third party

**Impact if successful:**
- Thousands of patient prescription records exposed
- GDPR breach notification triggered; potential €20M fine
- NHS IT system compromised or suspected of compromise
- Patient trust eroded

**OWASP Top 10 category:** A01:2021 – Broken Access Control

---

#### SAC-002: Session Hijacking – Account Takeover
**Linked threat:** ST-002
**Attacker type:** External unauthenticated
**Goal:** Gain access to a patient's account and modify refill requests or view prescription history.
**Attack Flow:**
1. Attacker performs phishing email: "Verify your NHS login" → attacker's phishing site
2. Patient enters NHS credentials; attacker captures them (or attacker steals session token via XSS)
3. Attacker logs into patient's portal with stolen credentials or token
4. Attacker views patient's prescriptions, submits refill requests, or modifies account details
5. Attacker may sell access to insurance companies or use for extortion

**Impact if successful:**
- Patient account fully compromised
- Unauthorized prescriptions requested (fraud, stock-up for sale)
- Patient privacy violated; prescriptions revealed to attacker
- Attacker gains access to NHS services (if NHS login is used across other systems)

**OWASP Top 10 category:** A07:2021 – Identification and Authentication Failures

---

#### SAC-003: Tampering – Refill Request Status Modification
**Linked threat:** ST-003
**Attacker type:** Insider (database admin, developer) or external (SQL injection)
**Goal:** Approve a refill request without GP review, causing pharmacy to dispense medication without clinical authorization.
**Attack Flow:**
1. Attacker gains write access to the refill_requests table (SQL injection via patient notes field, or insider access)
2. Attacker finds a refill request with status=pending for a patient
3. Attacker executes: `UPDATE refill_requests SET status='approved', approved_by_gp='fake-gp-id' WHERE id={request-id}`
4. System records approval as if a GP approved it
5. Pharmacy checks the approval and dispenses medication
6. Patient receives medication without clinical review

**Impact if successful:**
- Patient safety risk: unauthorized medication dispensing
- Fraud: attacker could request expensive/controlled medications
- Non-repudiation: system cannot prove who actually approved the request
- Regulatory violation: healthcare record integrity compromised

**OWASP Top 10 category:** A03:2021 – Injection

---

#### SAC-004: SQL Injection – Data Exfiltration or Denial of Service
**Linked threat:** ST-004
**Attacker type:** External unauthenticated
**Goal:** Extract patient data or delete records to disrupt the service.
**Attack Flow:**
1. Attacker submits a refill request with notes containing SQL injection: `'; DROP TABLE refill_requests; --`
2. If the system concatenates notes into a SQL query without parameterization, the payload executes
3. Attacker exfiltrates patient data or deletes the refill_requests table

**Impact if successful:**
- Database records deleted or modified
- Sensitive data exfiltrated
- Service disruption (DOS)
- Regulatory breach (data integrity violated)

**OWASP Top 10 category:** A03:2021 – Injection

---

#### SAC-005: GP Queue Flooding – Denial of Service
**Linked threat:** ST-005
**Attacker type:** External unauthenticated or authenticated (if access is not rate-limited)
**Goal:** Overwhelm the GP queue to prevent GPs from reviewing legitimate refill requests.
**Attack Flow:**
1. Attacker script submits 1000 refill requests per hour, one per patient account or prescription
2. No rate limiting check exists; all requests are accepted
3. GP queue grows exponentially
4. GPs cannot effectively triage; legitimate refill requests are buried
5. Patients experience delayed or missed refill approvals; medications run out

**Impact if successful:**
- GP workflow disrupted
- Patients may miss medications due to delayed approvals
- Clinical risk: unmanaged chronic conditions
- Service reputation damaged

**OWASP Top 10 category:** A05:2021 – Broken Access Control (combined with rate limiting)

---

#### SAC-006: Audit Log Tampering – Non-Repudiation
**Linked threat:** ST-006
**Attacker type:** Insider (database admin, developer)
**Goal:** Delete or modify audit logs to deny or conceal unauthorized actions.
**Attack Flow:**
1. Malicious GP approves a refill for a patient they shouldn't have (conflict of interest, fraud)
2. Insider helps delete the audit log entry
3. When questioned, GP claims they never approved the refill
4. Without audit proof, investigation is inconclusive; GP faces no consequences

**Impact if successful:**
- Accountability broken
- Fraudulent refills approved without evidence
- Patient safety risk: prescriptions for inappropriate patients
- Regulatory violation: audit trail integrity compromised

**OWASP Top 10 category:** A06:2021 – Vulnerable and Outdated Components (if logging library is compromised)

---

#### SAC-007: Unencrypted Data in Transit – Network Sniffing
**Linked threat:** ST-007
**Attacker type:** External (network attacker, MITM)
**Goal:** Intercept and read patient prescription data, refill requests, and contact details.
**Attack Flow:**
1. Attacker performs ARP spoofing or DNS hijacking on a shared network (public WiFi, compromised router)
2. Attacker intercepts HTTPS traffic without TLS (if portal does not enforce HTTPS)
3. Attacker captures prescription data, patient NHS numbers, email addresses
4. Attacker harvests data for secondary use (sale, blackmail, identity theft)

**Impact if successful:**
- Patient prescription data exposed to attacker
- Patient contact details (email, phone) exposed
- GDPR breach; patient notification required
- Attacker can link prescription data to patient identity

**OWASP Top 10 category:** A02:2021 – Cryptographic Failures

---

### 5.2 Privacy Abuse Cases

#### PAC-001: Insurance Discrimination Based on Prescription Data
**Linked threat:** PT-001, PT-002
**Actor:** Third-party insurer or employer gaining access to refill request history via breach or authorized data sharing
**Scenario:**
1. A patient with a mental health condition (e.g., bipolar disorder, depression) uses the refill portal to request prescriptions
2. Prescription data is breached or shared with an insurance company (either via a data broker or a future NHS analytics partnership)
3. Insurer sees the patient's refill patterns and decides to deny coverage or increase premiums
4. Patient is discriminated against based on health status

**Affected data subjects:** Patients
**Privacy By Design principle violated:**
- PbD Principle 1 (Proactive, not reactive): System was not designed to prevent secondary use of prescription data
- PbD Principle 2 (Privacy as default): Data was not minimized; full prescription history was retained indefinitely
- PbD Principle 5 (End-to-end security): Data was not protected sufficiently to prevent secondary use

**Regulatory exposure:**
- GDPR Article 5(1)(b) – Purpose limitation: Prescriptions collected for healthcare should not be used for insurance decisions without explicit consent
- GDPR Article 9 – Special categories: Health data cannot be used for insurance without explicit opt-in consent (UK law may be stricter)
- GDPR Articles 35–36 – DPIA and prior consultation: Not conducted; high-risk processing not assessed
- ICO guidance: UK healthcare data is highly sensitive; secondary uses require strict safeguards

---

#### PAC-002: Prescription Patterns Inferred from Refill Request Metadata
**Linked threat:** PT-004, PT-006
**Actor:** Attacker or insider accessing refill request logs or audit trails
**Scenario:**
1. An attacker gains unauthorized access to refill request logs (via breach or leaked backup)
2. Attacker analyzes the logs and observes that a specific patient (identifiable by NHS number or patient ID) has submitted refill requests for HIV antiretroviral medication every 30 days for the past 3 years
3. Attacker infers that the patient is HIV-positive
4. Attacker uses this information for blackmail, public disclosure, or selling to third parties

**Affected data subjects:** Patients
**Privacy By Design principle violated:**
- PbD Principle 1 (Proactive, not reactive): System did not anticipate this inference risk
- PbD Principle 2 (Privacy as default): Logs retained forever; no automatic deletion after clinical decision made
- PbD Principle 3 (Privacy embedded into design): No pseudonymization or de-identification of logs

**Regulatory exposure:**
- GDPR Article 9 – Special categories: Health data inferred from patterns is still special category data; same protections apply
- GDPR Article 5(1)(e) – Storage limitation: Logs kept longer than necessary
- ICO guidance: De-identification must be irreversible; linked pseudonyms are not sufficient

---

#### PAC-003: Refill Data Linked Across NHS Systems Without Consent
**Linked threat:** PT-002
**Actor:** Future NHS data sharing initiative or analytics project without proper governance
**Scenario:**
1. NHS Digital initiates an analytics project to identify patterns in prescribing behavior
2. Refill request data from this portal is linked to prescribing data from the EHR system and social care data
3. The linkage reveals that patients in deprived areas have lower medication adherence
4. This data is published or shared with local authorities, which use it for resource allocation or even to reduce eligibility
5. Patients are unaware their refill behavior is being analyzed in this way

**Affected data subjects:** Patients
**Privacy By Design principle violated:**
- PbD Principle 4 (Full functionality): System design did not anticipate linkage; no controls to prevent unauthorized linkage
- PbD Principle 7 (Respect for user privacy): No user awareness or consent for secondary use

**Regulatory exposure:**
- GDPR Article 6 – Lawful basis: Secondary use requires a separate lawful basis (not inherited from primary healthcare use)
- GDPR Article 13/14 – Transparency: Patients were not informed of this secondary use
- Common law duty of confidentiality: Health data shared beyond NHS healthcare purpose violates fiduciary duty
- ICO guidance: Public sector analytics must have clear governance and transparent purpose

---

#### PAC-004: Third-Party Notification Provider Breach Exposes Prescription Status
**Linked threat:** PT-005
**Actor:** External email/SMS provider (SendGrid, Twilio, etc.) compromised or rogue employee
**Scenario:**
1. Refill notification messages are sent via a third-party email provider (e.g., SendGrid)
2. The provider is breached or an employee accesses customer data
3. Attacker gains access to notification logs, including patient emails and medication status (e.g., "Your refill for atorvastatin has been declined")
4. Attacker correlates emails to patient identities and sells the list to insurance or pharmaceutical companies

**Affected data subjects:** Patients
**Privacy By Design principle violated:**
- PbD Principle 3 (Privacy embedded into design): System design delegated privacy responsibility to third party without contractual safeguards
- PbD Principle 5 (End-to-end security): Data exposed in transit to third party

**Regulatory exposure:**
- GDPR Article 28 – Data Processing Agreements: DPA must include security obligations for processors
- GDPR Article 33 – Breach notification: Breach by processor must be reported to ICO and patients
- GDPR Article 44+ – Data transfers: If provider is outside UK, SCCs or UK adequacy decision required
- GDPR Article 5(1)(f) – Integrity and confidentiality: Third-party provider must ensure data security

---

#### PAC-005: Lack of Privacy Notice – Patients Unaware of Data Retention
**Linked threat:** PT-006, PT-008
**Actor:** System deployer failing to provide transparency
**Scenario:**
1. Portal is launched without a Privacy Notice or data retention disclosure
2. Patients submit refill requests, assuming the data is used only for that request and then deleted
3. In reality, refill request records are kept for 7 years for audit purposes
4. A patient requests data subject rights (right to access) and discovers their refill history is extensive and stored indefinitely
5. Patient feels violated; trust in NHS system eroded

**Affected data subjects:** Patients
**Privacy By Design principle violated:**
- PbD Principle 7 (Respect for user privacy): No transparency provided to patients
- PbD Principle 1 (Proactive, not reactive): No upfront consent or awareness mechanism

**Regulatory exposure:**
- GDPR Article 13/14 – Information to be provided: Patients must be informed of data retention, purposes, recipients, and rights
- GDPR Article 5(1)(a) – Lawfulness, fairness, transparency: Processing must be transparent
- ICO guidance: Healthcare providers must provide accessible privacy notices before collecting data
- Regulatory fine: Up to €20M or 4% revenue

---

#### PAC-006: Data Retention Exceeds NHS Guidance – Unnecessary Storage
**Linked threat:** PT-007
**Actor:** System design not aligned with NHS Information Governance
**Scenario:**
1. Refill request records are stored indefinitely due to lack of retention policy
2. 10 years later, a patient requests erasure; the healthcare provider cannot delete the data because no system was built to support it
3. Regulator discovers that data is kept far longer than NHS IG guidance (which recommends 3–7 years)
4. Provider is fined for violating GDPR Article 5(1)(e) – storage limitation

**Affected data subjects:** Patients
**Privacy By Design principle violated:**
- PbD Principle 2 (Privacy as default): Default was to retain forever, not to minimize and delete
- PbD Principle 1 (Proactive, not reactive): Retention policy should have been designed upfront

**Regulatory exposure:**
- GDPR Article 5(1)(e) – Storage limitation: Data kept longer than necessary violates the principle
- GDPR Article 17 – Right to erasure: Patient requests deletion; system cannot comply
- ICO guidance: NHS organizations should implement automated deletion policies
- Regulatory fine: Up to €20M or 4% revenue

---

#### PAC-007: No DPIA Conducted – High-Risk Processing Unassessed
**Linked threat:** PT-009
**Actor:** Compliance function failing to trigger DPIA
**Scenario:**
1. System processes health data (special category) from NHS login authenticated users
2. No Data Protection Impact Assessment is conducted; risk is not formally assessed
3. System is deployed with gaps in privacy controls (e.g., unencrypted notifications)
4. Patient data is breached
5. Regulator investigates and finds that a DPIA should have been conducted per Article 35
6. Provider is fined for failing to conduct due diligence

**Affected data subjects:** Patients
**Privacy By Design principle violated:**
- PbD Principle 1 (Proactive, not reactive): No upfront risk assessment
- PbD Principle 3 (Privacy embedded into design): Risk was not designed into the system at inception

**Regulatory exposure:**
- GDPR Article 35 – Data Protection Impact Assessment: Mandatory for special category data processing
- GDPR Article 36 – Prior consultation: May require ICO consultation if high risk identified
- ICO guidance: Healthcare DPIAs must cover data flows, third parties, retention, access controls
- Regulatory fine: Up to €20M or 4% revenue

---

## 6. Counter-Use Cases

### 6.1 Security Use Cases (Countermeasures)

#### SUC-001: Attribute-Based Access Control (ABAC) on FHIR API
**Mitigates:** SAC-001 (ST-001)
**Security control:**
Implement fine-grained authorization checks at the FHIR API layer. For every request, verify:
- Authenticated user's NHS number matches the requested patient's NHS number (for patients)
- Authenticated GP's practice is the prescribing practice for the requested patient (for GPs)
- Authenticated user has the required role (patient, GP, admin)

**Implementation notes:**
- Use OAuth 2.0 scope-based authorization: Patient scope can only query their own prescriptions; GP scope limited to assigned patients
- FHIR API should enforce authorization at the resource level: `GET /fhir/Patient/NHS123456/Medication` requires authorization to access that specific patient
- Use a healthcare-specific ABAC library (e.g., AuthZEN, Keycloak with FHIR scopes) or custom policy engine
- Deny all by default; explicitly whitelist authorized queries
- Log all authorization decisions (accept/reject) for audit

**OWASP ASVS reference:** ASVS 4.0 §4.1 (General Access Control) – "Access control decisions must be enforced at the server side, not the client side"

**Residual risk:**
- Compromised GP account can still query all their assigned patients (acceptable; GPs need access to their patient list)
- Misconfiguration of practice-to-patient mapping could allow unauthorized access (mitigated by regular audits)

---

#### SUC-002: Secure Session Management & Token Protection
**Mitigates:** SAC-002 (ST-002)
**Security control:**
Harden session management by enforcing secure token storage and transmission.

**Implementation notes:**
- **Token storage**: Store NHS login tokens in secure, HttpOnly, SameSite cookies (not localStorage)
- **Token transmission**: Enforce HTTPS-only; reject any HTTP requests
- **Token lifespan**: Short-lived tokens (15–30 min); use refresh tokens (1–7 days) for re-authentication
- **Token rotation**: Rotate refresh tokens on use; issue new tokens on each refresh
- **Session timeout**: Absolute timeout (30 min of inactivity); force re-authentication after timeout
- **CORS policy**: Strict; allow only same-origin requests
- **XSS prevention**: Implement Content Security Policy (CSP) headers to prevent inline scripts
- **CSRF protection**: Use SameSite cookie attribute (Strict or Lax) to prevent cross-site request forgery

**OWASP ASVS reference:** ASVS 4.0 §3.3 (Session Management) – Token lifespan, refresh tokens, timeout policies

**Residual risk:**
- Physical device theft: Attacker can access portal if device is not locked; mitigated by OS-level security
- Phishing: User gives away credentials; mitigated by user education and optional MFA

---

#### SUC-003: Immutable Audit Logs with Cryptographic Integrity
**Mitigates:** SAC-003, SAC-006 (ST-003, ST-006)
**Security control:**
Design refill request records and audit logs to be immutable and tamper-proof.

**Implementation notes:**
- **Immutable storage**: Use append-only data structures (event sourcing) or write-once storage (e.g., AWS S3 Object Lock)
- **Cryptographic signing**: Sign each audit log entry with a private key; include a hash chain (each entry includes hash of previous entry)
- **Separate storage**: Store audit logs in a separate, restricted database/system; not modifiable by the main application
- **Access controls**: Only security operations team can access audit logs; require MFA and approval
- **Backup verification**: Back up audit logs to immutable storage (e.g., tape, cloud cold storage); verify backup integrity regularly
- **Example**: Each refill request action is logged as `{timestamp, user_id, action, refill_id, old_status, new_status, signature(hash_of_previous_entry)}`

**OWASP ASVS reference:** ASVS 4.0 §8.2 (Logging) – Ensure log entries cannot be deleted or modified; use cryptographic integrity

**Residual risk:**
- Insider with access to cryptographic keys could forge log entries; mitigated by key management (e.g., HSM, separation of duties)
- Deletion of log entries from immutable storage; mitigated by geographic replication and legal holds

---

#### SUC-004: Input Validation & Output Encoding
**Mitigates:** SAC-004 (ST-004)
**Security control:**
Implement strict input validation and output encoding to prevent injection attacks.

**Implementation notes:**
- **Input validation**: Whitelist allowed characters for each field (e.g., patient notes: alphanumeric + common punctuation; no SQL keywords)
- **Parameterized queries**: Use prepared statements / parameterized queries for all database interactions; never concatenate user input into SQL
- **Output encoding**: Encode output based on context (HTML entity encoding for web display, SQL escaping for database, URL encoding for URLs)
- **Validation library**: Use a mature, maintained library (e.g., OWASP ModSecurity, libinjection for SQLi detection)
- **Example for patient notes**:
  ```
  // Bad: String notes = request.getParameter("notes");
  //      String sql = "INSERT INTO refill_requests (notes) VALUES ('" + notes + "')";

  // Good: String notes = request.getParameter("notes");
  //       if (!Pattern.matches("^[a-zA-Z0-9 ,.\-()]*$", notes)) { throw new ValidationException(); }
  //       PreparedStatement pstmt = conn.prepareStatement("INSERT INTO refill_requests (notes) VALUES (?)");
  //       pstmt.setString(1, notes);
  ```

**OWASP ASVS reference:** ASVS 4.0 §5.1 (Input Validation) & §5.3 (Output Encoding)

**Residual risk:**
- Logic-based injection (e.g., LDAP injection, command injection in other contexts); mitigated by using safe libraries (e.g., LDAP libraries that parameterize filters)

---

#### SUC-005: Rate Limiting & Abuse Detection
**Mitigates:** SAC-005 (ST-005)
**Security control:**
Implement rate limiting on refill request submission and abuse detection.

**Implementation notes:**
- **Rate limiting**: Limit refill requests to 5 per hour per patient; 10 per day per patient
- **IP-based rate limiting**: Limit to 100 requests per hour per IP address (to catch automated attacks)
- **Anomaly detection**: Flag requests that deviate from user patterns (e.g., 50 requests in 1 hour for a patient who normally submits 1 per month)
- **Queue depth**: Monitor GP queue size; alert if it exceeds 1000 items; reject submissions if queue exceeds 5000 (graceful degradation)
- **CAPTCHA**: Trigger CAPTCHA after 3 failed rate limit checks (optional, for web)
- **Implementation**: Use a rate limiting library (e.g., Redis-based rate limiter, AWS API Gateway throttling) or custom middleware

**OWASP ASVS reference:** ASVS 4.0 §11.1 (Business Logic) – Rate limiting for sensitive operations

**Residual risk:**
- DDoS on other endpoints (not just refill requests); mitigated by WAF (Web Application Firewall) and DDoS protection service
- Distributed attack from many IPs; mitigated by bot detection and IP reputation lists

---

#### SUC-006: Error Handling – No Sensitive Data in Messages
**Mitigates:** ST-010
**Security control:**
Design error messages to avoid leaking sensitive information.

**Implementation notes:**
- **Generic error messages**: Instead of "Prescription ID 12345 not found", return "You do not have permission to view this prescription"
- **Detailed logging**: Log the actual error (with IDs, details) server-side; return only a generic message and error code to client
- **Example**:
  ```
  // Bad: return "Prescription 12345 not found for patient NHS123456"

  // Good:
  log.error("Prescription lookup failed: id=12345, patient=NHS123456, user=NHS789, reason=not_found");
  return "An error occurred. Please contact support with error code E001.";
  ```

**OWASP ASVS reference:** ASVS 4.0 §7.4 (Error Handling) – "Error messages should not leak sensitive information"

**Residual risk:**
- Stack traces or detailed errors exposed in development/staging environments; mitigated by environment-specific config
- Client-side error messages (browser console); mitigated by user education and obfuscation

---

#### SUC-007: Encryption in Transit (TLS)
**Mitigates:** SAC-007 (ST-007)
**Security control:**
Enforce HTTPS/TLS for all communication.

**Implementation notes:**
- **TLS version**: Enforce TLS 1.2 or higher (recommend TLS 1.3)
- **Certificate**: Valid, trusted certificate (not self-signed in production)
- **Cipher suites**: Use strong cipher suites; disable weak algorithms (RC4, MD5, DES)
- **HSTS**: Enable HTTP Strict-Transport-Security (HSTS) header: `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- **Certificate pinning** (optional): For mobile/native clients, pin expected certificate to prevent MITM via compromised CAs
- **Implementation**: Use TLS termination proxy (e.g., HAProxy, AWS ALB); configure via infrastructure-as-code

**OWASP ASVS reference:** ASVS 4.0 §9.1 (Cryptographic Transport) – TLS 1.2+, HSTS

**Residual risk:**
- Zero-day in TLS implementation; mitigated by keeping TLS libraries up to date (e.g., OpenSSL, BoringSSL)

---

#### SUC-008: Encryption at Rest
**Mitigates:** ST-008
**Security control:**
Encrypt all sensitive data at rest in the database and backups.

**Implementation notes:**
- **Database encryption**: Enable transparent data encryption (TDE) or database-level encryption (e.g., AWS RDS encryption, PostgreSQL pgcrypto)
- **Field-level encryption** (optional): For highly sensitive fields (prescriptions, patient NHS numbers), encrypt at the application layer before storing
- **Key management**: Use a secure key management service (e.g., AWS KMS, HashiCorp Vault)
- **Backup encryption**: Encrypt backups with the same keys; store backup keys separately
- **Key rotation**: Rotate encryption keys annually; test key rotation procedures
- **Example**: Use AWS RDS with KMS encryption enabled; master key managed by AWS KMS

**OWASP ASVS reference:** ASVS 4.0 §9.2 (Cryptographic Storage) – Encryption at rest for sensitive data

**Residual risk:**
- Key compromise; mitigated by secure key management and regular key rotation

---

#### SUC-009: Session Timeout & Absolute Timeout
**Mitigates:** ST-009
**Security control:**
Implement aggressive session timeouts to limit the impact of token theft.

**Implementation notes:**
- **Inactivity timeout**: 15 minutes of inactivity; user must re-authenticate
- **Absolute timeout**: 30 minutes from login; user must re-authenticate regardless of activity
- **Refresh token timeout**: 7 days; refresh token expires and user must do full login again
- **Implementation**: Use NHS login's native timeout settings (if available); or implement in application (track last activity timestamp)
- **User notification**: Warn user 2 minutes before timeout; allow them to extend session

**OWASP ASVS reference:** ASVS 4.0 §3.3.2 – Session timeout

**Residual risk:**
- User inconvenience: Frequent re-authentication may cause users to disable timeouts or use weaker auth; mitigated by UX design and optional MFA

---

### 6.2 Privacy Use Cases (Privacy Controls)

#### PUC-001: Privacy Notice & Transparency
**Mitigates:** PAC-005 (PT-006)
**Privacy control:**
Publish a comprehensive Privacy Notice before collecting any data.

**Privacy by Design principle:** PbD Principle 7 (Respect for user privacy)

**Implementation notes:**
- **Content**: Privacy Notice must cover:
  - Data controller (healthcare organization)
  - Lawful basis for processing prescriptions (Article 6: healthcare treatment) and refill requests (Article 9: explicit consent or healthcare necessity)
  - Purpose: facilitate refill requests, improve prescribing safety, audit for compliance
  - Recipients: GPs, pharmacy systems (future), audit teams, NHS Digital (if applicable)
  - Retention: Refill request records kept for 7 years (NHS IG guidance); then deleted
  - Data subject rights: Access (GDPR 15), erasure (17), portability (20), rectification (16), objection (21)
  - Contact: Data controller, Data Protection Officer
  - Complaint: ICO contact details
- **Format**: Plain language, layered (summary + detailed), accessible (large font, easy reading)
- **Timing**: Presented to patient before first refill request; refreshed annually
- **Storage**: Patient can download and print for records

**GDPR article reference:** Articles 13/14 (Information to be provided), 5(1)(a) (Transparency)

---

#### PUC-002: Data Minimisation & Purpose Limitation
**Mitigates:** PAC-001, PAC-002, PAC-006 (PT-001, PT-002, PT-007)
**Privacy control:**
Collect only the minimum data necessary for the refill request function and prevent secondary use.

**Privacy by Design principle:** PbD Principle 2 (Privacy as default)

**Implementation notes:**
- **Data collection**: Collect only:
  - Patient NHS number (necessary to link to EHR)
  - Prescription ID and medication name (necessary for refill)
  - Request timestamp (necessary for audit)
  - GP approval decision (necessary for clinical workflow)
  - Do NOT collect: patient address, phone number (optional; collect only for notification if patient consents separately)
- **Retention**: Refill request record kept for 7 years; then automatically deleted
- **Purpose limitation**: Refill data used only for:
  - Facilitating refill workflow
  - Audit and compliance
  - NOT used for: analytics, prescribing behavior studies, insurance decisions, or secondary research without separate consent
- **Technical control**: Implement a data retention policy in code; schedule automatic deletion of records older than 7 years
- **Example SQL**: `DELETE FROM refill_requests WHERE created_at < NOW() - INTERVAL '7 years'` (run daily)

**GDPR article reference:** Articles 5(1)(b) (Purpose limitation), 5(1)(e) (Storage limitation)

---

#### PUC-003: Data Subject Rights – Access, Erasure, Portability
**Mitigates:** PAC-005, PAC-006 (PT-006, PT-008)
**Privacy control:**
Implement mechanisms for patients to exercise GDPR rights.

**Privacy by Design principle:** PbD Principle 1 (Proactive, not reactive)

**Implementation notes:**
- **Right of access (Article 15)**:
  - Allow patient to view all their refill requests and audit logs via portal
  - Provide downloadable export of all personal data (CSV or PDF)
  - Respond to formal SAR (Subject Access Request) within 30 days
- **Right to erasure (Article 17)**:
  - Allow patient to delete their own refill requests (if no GP action pending)
  - Implement "right to be forgotten": delete refill request and related audit logs (except anonymized statistical logs)
  - Respond to erasure requests within 30 days
- **Right to data portability (Article 20)**:
  - Allow patient to download their data in a portable format (CSV, JSON, XML)
  - Include: prescriptions, refill requests, approval dates, GPs involved
- **Right to rectification (Article 16)**:
  - Allow patient to correct their own contact details, health information (if applicable)
  - If corrected data was previously used in a refill decision, notify patient
- **Right to object (Article 21)**:
  - Allow patient to opt out of audit logging or specific uses

**GDPR article reference:** Articles 15–21 (Data subject rights)

---

#### PUC-004: Data Protection Impact Assessment (DPIA)
**Mitigates:** PAC-007 (PT-009)
**Privacy control:**
Conduct a formal DPIA per GDPR Article 35 before system launch.

**Privacy by Design principle:** PbD Principle 1 (Proactive, not reactive)

**Implementation notes:**
- **DPIA must cover**:
  - Description of processing: who processes what data, how, for what purpose
  - Necessity and proportionality: is this data collection necessary? Could it be done with less data?
  - Risk analysis: identify privacy risks (ST-001 through PT-009 from this analysis)
  - Mitigation measures: how will identified risks be mitigated? (tie to SUCs and PUCs)
  - Data flows: diagram where data moves (patient portal → FHIR API → EHR → notification service, etc.)
  - Third parties: who has access to data? What are their security/privacy obligations?
  - Retention: justify 7-year retention period; confirm it aligns with NHS guidance
  - Compliance with principles: verify system complies with GDPR Article 5 (lawfulness, fairness, transparency, etc.)
- **Outcome**: Sign-off from Data Protection Officer and senior management; document residual risks
- **Review**: Repeat DPIA if system design changes significantly

**GDPR article reference:** Articles 35–36 (DPIA and prior consultation)

---

#### PUC-005: Third-Party Data Processor Agreements
**Mitigates:** PAC-004 (PT-005)
**Privacy control:**
Establish legally binding Data Processing Agreements (DPAs) with any third-party service that touches patient data.

**Privacy by Design principle:** PbD Principle 5 (End-to-end security)

**Implementation notes:**
- **Identify processors**: Email provider (SendGrid), SMS provider (Twilio), cloud infrastructure provider (AWS, etc.), analytics vendor (if any)
- **DPA requirements**: Each DPA must include:
  - Definition of data, processing scope, duration, nature
  - Data Protection Officer contact information
  - Security obligations: encryption, access controls, audit logging, incident response
  - Sub-processor rules: Processor cannot sub-contract without prior written approval
  - Data subject rights: Processor must assist with subject access requests, erasure, etc.
  - Liability and indemnification: Processor liable for GDPR breaches
  - Termination: Data is deleted or returned upon termination
  - Audit rights: Data controller can audit processor's compliance
  - Certification: ISO 27001, SOC 2 Type II compliance (for email/SMS providers)
- **Notification provider example**: Email provider must commit to:
  - Encrypt data in transit (TLS) and at rest
  - Limit access to authenticated staff only
  - Notify healthcare organization within 24 hours of any breach
  - Delete email logs after 90 days (configurable)
  - Comply with GDPR Articles 32–34 (security and breach notification)

**GDPR article reference:** Articles 28 (Data Processing Agreements), 44+ (International data transfers if applicable)

---

#### PUC-006: Automated Data Deletion Policy
**Mitigates:** PAC-006 (PT-007)
**Privacy control:**
Implement automated deletion of refill request data after retention period expires.

**Privacy by Design principle:** PbD Principle 2 (Privacy as default)

**Implementation notes:**
- **Retention policy**: Refill request records (status, notes, approval details) deleted after 7 years
- **Audit logs**: Anonymized audit logs kept for 10 years (regulatory requirement); identifiable logs deleted after 7 years
- **Implementation**:
  - Database schema: Add `created_at`, `deleted_at` timestamps
  - Cron job: Run daily or weekly; delete records where `created_at < NOW() - INTERVAL '7 years'` AND `status IN ('approved', 'declined')` (don't delete pending requests until actioned)
  - Logging: Log each deletion (what was deleted, when, who triggered it) to immutable audit trail
  - Testing: Test deletion process in staging; verify data is actually deleted from database and backups
  - Notifications: Optional: notify patient 30 days before their data is deleted; allow them to request retention extension
- **Example cron job**:
  ```
  0 2 * * * /opt/scripts/delete-old-refill-requests.sh
  # This script:
  # 1. Queries refill_requests WHERE created_at < NOW() - INTERVAL '7 years'
  # 2. Archives the data to immutable storage (for legal hold purposes)
  # 3. Deletes from production database
  # 4. Logs the deletion
  # 5. Verifies deletion via count query
  ```

**GDPR article reference:** Articles 5(1)(e) (Storage limitation), 17 (Right to erasure)

---

#### PUC-007: Incident Response & Breach Notification
**Mitigates:** PAC-001, PAC-002, PAC-003 (PT-001, PT-002, PT-004)
**Privacy control:**
Establish a breach detection and notification process per GDPR Article 33–34.

**Privacy by Design principle:** PbD Principle 1 (Proactive, not reactive)

**Implementation notes:**
- **Breach detection**:
  - Monitor for unusual database queries (e.g., access to >1000 prescription records)
  - Monitor failed login attempts (e.g., >10 failed attempts per IP)
  - Monitor unauthorized API calls (e.g., queries outside user's authorized scope)
  - Set up alerts in SIEM (Security Information Event Management) system
- **Incident response plan**:
  - Detect: Alert triggers; incident response team convenes
  - Contain: Isolate affected systems; revoke compromised credentials; patch vulnerabilities
  - Assess: Determine scope (how many patients affected? What data accessed?)
  - Notify ICO: Within 72 hours if breach is likely to result in risk to rights and freedoms (Article 33)
  - Notify patients: Within 30 days if high risk; use clear, plain language (Article 34)
  - Document: Keep records of incident, response, and decisions for regulator review
- **Notification template**:
  ```
  Subject: Important: Your prescription data may have been accessed

  Dear [Patient Name],

  We are writing to inform you that on [DATE], we discovered that your health data may have been accessed without authorization.
  Specifically, the following data was affected:
  - Your prescriptions (medication names, dosages)
  - Your refill requests (dates, status)

  What we are doing:
  - We have stopped the unauthorized access
  - We are working with law enforcement
  - We are offering you [free credit monitoring, etc.]

  What you should do:
  - Monitor your accounts for suspicious activity
  - Consider changing your NHS password
  - Contact us if you have questions: [contact details]

  [ICO contact information]
  ```

**GDPR article reference:** Articles 33–34 (Breach notification)

---

#### PUC-008: Consent Management (if applicable)
**Mitigates:** PAC-001 (PT-001)
**Privacy control:**
If any secondary use of prescription data is planned, implement explicit consent collection and management.

**Privacy by Design principle:** PbD Principle 7 (Respect for user privacy)

**Implementation notes:**
- **When required**: GDPR Article 9 (special categories) requires explicit consent for most health data processing beyond direct healthcare treatment
- **Consent for notifications**: Collect explicit consent for email/SMS notifications (may already be implicit; confirm)
- **Consent for secondary uses**: If prescription data is used for research, analytics, or shared with third parties, collect explicit consent
- **Implementation**:
  - Separate consent field for each purpose
  - Patients can withdraw consent at any time
  - System must honor withdrawal: stop processing for that purpose, do not use withdrawn data
  - Consent records kept for audit (when patient consented, to what, when withdrawn)
  - Granular: e.g., consent to email notifications but not SMS; consent to health research but not commercial analytics

**GDPR article reference:** Articles 7 (Conditions for consent), 9 (Processing of special categories)

---

## 7. Refined Requirements

### All Requirements (Original + New)

**FUNCTIONAL REQUIREMENTS (FR)**

| ID | Requirement | Status |
|---|---|---|
| FR-001 | Patients can view their active prescriptions pulled from EHR via FHIR API | Original |
| FR-002 | Patients can submit a refill request for any active prescription | Original |
| FR-003 | Refill request creates a task in the GP's queue | Original |
| FR-004 | GPs can approve or decline refill requests | Original |
| FR-005 | GPs can add a note when declining a refill request | Original |
| FR-006 | Patients receive notifications (email/SMS) when GP approves or declines their request | Original |
| FR-007 | [NEW — from PUC-003] Patients can download their data (refill requests, audit logs) in a portable format (CSV/JSON) | New |
| FR-008 | [NEW — from PUC-003] System provides a "View My Refill History" page showing all past requests and GP decisions | New |

**SECURITY REQUIREMENTS (SEC)**

| ID | Requirement | Status | Rationale |
|---|---|---|---|
| SEC-001 | Authentication uses existing NHS login integration (OAuth 2.0 / OpenID Connect) | Original | Inherited from portal |
| SEC-002 | [NEW — from ST-001, SAC-001] Authorization: Patients can view/modify only their own prescriptions and refill requests; GPs can view/modify only refill requests for patients in their practice | New | Prevent cross-patient unauthorized access |
| SEC-003 | [NEW — from ST-001] FHIR API enforces authorization checks at the resource level; every query validated against user's scope | New | Prevent lateral movement |
| SEC-004 | [NEW — from ST-004] All user input (patient notes, GP decline reasons) is validated against a whitelist; no SQL or HTML keywords allowed | New | Prevent injection attacks |
| SEC-005 | [NEW — from ST-005, SAC-005] Rate limiting: Max 5 refill requests per hour per patient; max 100 per hour per IP; GP queue max size 5000 | New | Prevent DoS attacks on GP workflow |
| SEC-006 | [NEW — from ST-006, SAC-006] All access to prescriptions and all refill actions are logged immutably with cryptographic signatures; logs cannot be deleted or modified without detection | New | Ensure non-repudiation and accountability |
| SEC-007 | [NEW — from ST-007, SAC-007] All communication (patient portal ↔ FHIR API, portal ↔ notification service) is encrypted with TLS 1.2+ | New | Prevent network eavesdropping |
| SEC-008 | [NEW — from ST-008] All data at rest is encrypted; database uses transparent data encryption (TDE) or KMS-managed encryption | New | Protect against physical/cloud storage breach |
| SEC-009 | [NEW — from ST-009] Session timeout: 15 minutes inactivity; absolute timeout 30 minutes; refresh tokens expire after 7 days | New | Limit impact of token theft |
| SEC-010 | [NEW — from ST-010] Error messages do not leak sensitive information (prescription IDs, NHS numbers, patient names); detailed errors logged server-side only | New | Prevent information enumeration |
| SEC-011 | [NEW — Security dependency management] All third-party libraries (FHIR client, notification SDKs) are version-pinned; security updates monitored and applied within 30 days of release | New | Reduce supply chain risk |

**PRIVACY REQUIREMENTS (PRV)**

| ID | Requirement | Status | Rationale |
|---|---|---|---|
| PRV-001 | [NEW — from PT-006, PAC-005, PUC-001] A comprehensive Privacy Notice is provided to patients before their first refill request, covering data purposes, lawful basis, retention, recipients, and GDPR rights | New | GDPR Article 13/14 transparency |
| PRV-002 | [NEW — from PT-005, PAC-004, PUC-008] Patients are asked for explicit consent before their contact details (email/phone) are used for notifications; consent can be withdrawn anytime | New | GDPR Article 7 consent |
| PRV-003 | [NEW — from PT-001, PAC-001, PUC-002] Data minimisation: Only prescription ID, medication name, request date, and GP decision are collected; no unnecessary metadata | New | GDPR Article 5(1)(c) data minimisation |
| PRV-004 | [NEW — from PT-007, PAC-006, PUC-006] Refill request records are automatically deleted after 7 years; audit logs (anonymized) kept for 10 years per NHS IG guidance, then deleted | New | GDPR Article 5(1)(e) storage limitation |
| PRV-005 | [NEW — from PT-008, PUC-003] Patients can exercise GDPR rights: right to access (view/download data), erasure (delete refill requests), portability (export data), and rectification (correct details) via the portal or SAR process | New | GDPR Articles 15–21 data subject rights |
| PRV-006 | [NEW — from PT-005, PUC-005] Any third-party service that processes patient data (email provider, SMS provider, cloud infrastructure) must have a signed Data Processing Agreement (DPA) including security obligations, sub-processor rules, and breach notification | New | GDPR Article 28 processor obligations |
| PRV-007 | [NEW — from PT-004, PAC-002, PUC-002] Purpose limitation: Refill data is used only for facilitating refill requests and audit/compliance; NOT used for secondary analytics, research, or prescribing behavior studies without separate explicit consent | New | GDPR Article 5(1)(b) purpose limitation |
| PRV-008 | [NEW — from PT-005, PAC-004, PUC-007] Incident response plan: Breach detection via SIEM alerts; if breach detected, notify ICO within 72 hours (Article 33) and affected patients within 30 days (Article 34) with clear notification template | New | GDPR Articles 33–34 breach notification |

**COMPLIANCE & REGULATORY REQUIREMENTS (COMP)**

| ID | Requirement | Status | Rationale |
|---|---|---|---|
| COMP-001 | System complies with GDPR and NHS Digital standards | Original | UK healthcare regulatory requirement |
| COMP-002 | [NEW — from PT-009, PAC-007, PUC-004] A Data Protection Impact Assessment (DPIA) is conducted per GDPR Article 35 before system launch; risk mitigation measures documented and signed off by DPO | New | GDPR Article 35 mandatory for special category data |
| COMP-003 | [NEW — NHS IG Toolkit] System is registered and passes the NHS Data Security and Protection Toolkit (DSPT) self-assessment | New | NHS Digital requirement |
| COMP-004 | [NEW — Data subject rights] The system supports documented processes for responding to Data Subject Access Requests (DSAR) within 30 days | New | GDPR Article 15 compliance |

**PERFORMANCE REQUIREMENTS (PERF)**

| ID | Requirement | Status | Rationale |
|---|---|---|---|
| PERF-001 | [NEW — Availability] System uptime: 99.5% SLA (4 hours/month maximum planned + unplanned downtime) | New | Healthcare system criticality; medications time-sensitive |
| PERF-002 | [NEW — Responsiveness] Prescription list loads in <2 seconds for typical user (100 prescriptions) | New | User experience; avoid frustration |
| PERF-003 | [NEW — GP queue responsiveness] GP queue is queryable in <1 second even with 10k pending requests | New | GP workflow efficiency |

---

## 8. Security Requirements Traceability Matrix (SRTM)

| Req ID | Requirement (brief) | Type | Use Case | Threat / Abuse Case | Control (SUC / PUC) | Test ID | Test Description | Priority |
|--------|---------------------|------|----------|---------------------|---------------------|---------|------------------|----------|
| FR-001 | Patients view active prescriptions from EHR | FR | UC-001 | ST-001 (cross-patient access) | SUC-001 (ABAC) | TA-001 | Patient can only view own prescriptions; cross-patient queries rejected | Critical |
| FR-002 | Patients submit refill request | FR | UC-002 | ST-004 (injection), ST-005 (DoS) | SUC-004, SUC-005 | TA-003, TA-004 | Input validation on patient notes; rate limiting enforced | Critical |
| FR-003 | Refill creates GP queue task | FR | UC-003 | ST-003 (tampering), ST-006 (non-repudiation) | SUC-003 | TA-005 | Refill request status cannot be modified post-creation; immutable log | Critical |
| FR-004 | GPs approve/decline refills | FR | UC-003 | ST-003, ST-006 | SUC-003 | TA-005, TA-006 | GP approval immutable; only GP can approve own queued items | Critical |
| FR-005 | GPs add notes to declined requests | FR | UC-003 | ST-004 (injection) | SUC-004 | TA-003 | GP notes validated and sanitized; no XSS/SQLi possible | High |
| FR-006 | Patients notified of status changes | FR | UC-004 | ST-007 (unencrypted), PT-005 (disclosure to 3rd party) | SUC-007, PUC-005 | TA-008, TA-014 | Notifications sent over TLS; 3rd party DPA in place | High |
| FR-007 | Patients download their data | FR | UC-001,UC-002 | PT-001, PT-006 (unawareness) | PUC-003 (data subject rights) | TA-012 | Patient can export own data in CSV/JSON; includes all refills | High |
| FR-008 | Patients view refill history | FR | UC-002, UC-003 | PT-001, PT-006 | PUC-003 | TA-012 | Patient dashboard shows all own refill requests + GP decisions | Medium |
| SEC-001 | NHS login authentication | SEC | UC-001, UC-002, UC-003 | ST-002 (session hijacking) | SUC-002 | TA-009 | NHS login tokens stored as HttpOnly cookies; HTTPS enforced | Critical |
| SEC-002 | Authorization: own data only | SEC | UC-001, UC-002, UC-003 | ST-001 (cross-patient access) | SUC-001 | TA-001, TA-002 | Patient cannot view other patient's data; GP cannot see unauthorized patients | Critical |
| SEC-003 | FHIR API enforces authorization | SEC | UC-001 | ST-001 | SUC-001 | TA-001, TA-002 | FHIR API rejects queries for unauthorized patients; 403 Forbidden | Critical |
| SEC-004 | Input validation on user input | SEC | UC-002, UC-003 | ST-004 (injection) | SUC-004 | TA-003, TA-007 | SQLi/XSS payloads rejected; invalid characters filtered | Critical |
| SEC-005 | Rate limiting on refill submission | SEC | UC-002 | ST-005 (DoS) | SUC-005 | TA-004, TA-008 | Requests >5/hour per patient blocked; 429 Too Many Requests | High |
| SEC-006 | Immutable audit logs | SEC | UC-001, UC-002, UC-003 | ST-006 (non-repudiation) | SUC-003 | TA-005, TA-010 | Audit entries cryptographically signed; deletion detected; log tamper check | Critical |
| SEC-007 | TLS encryption in transit | SEC | UC-001, UC-002, UC-003, UC-004 | ST-007 (unencrypted MITM) | SUC-007 | TA-009, TA-011 | All endpoints HTTPS only; TLS 1.2+; HSTS header set | Critical |
| SEC-008 | Encryption at rest | SEC | UC-001, UC-002, UC-003 | ST-008 (unencrypted storage) | SUC-008 | TA-010 | Database encrypted with KMS; backups encrypted; key rotation tested | High |
| SEC-009 | Session timeout | SEC | UC-001, UC-002, UC-003 | ST-002, ST-009 (long session lifetime) | SUC-002, SUC-009 | TA-009 | Session expires after 30 min absolute or 15 min inactivity; user re-auth required | High |
| SEC-010 | No sensitive data in error messages | SEC | UC-001, UC-002, UC-003 | ST-010 (information enumeration) | SUC-006 | TA-007 | Error responses generic; detailed errors logged server-side only | Medium |
| SEC-011 | Dependency security management | SEC | All | Supply chain risk | SUC-007 | TA-013 | Dependencies audited monthly; vulnerable packages identified and patched within 30 days | Medium |
| PRV-001 | Privacy Notice provided | PRV | UC-001, UC-002 | PT-006 (unawareness) | PUC-001 | TA-015 | Privacy Notice displayed before first refill; covers retention, rights, recipients | Critical |
| PRV-002 | Consent for notifications | PRV | UC-004 | PT-005 (disclosure to 3rd party) | PUC-008 | TA-014 | Patients asked for email/SMS consent; can withdraw; system honors preference | High |
| PRV-003 | Data minimisation | PRV | UC-001, UC-002, UC-003 | PT-001 (identifiability), PT-002 (linkability) | PUC-002 | TA-012 | Only essential data collected; unnecessary fields absent from database schema | High |
| PRV-004 | Data retention / deletion | PRV | UC-002, UC-003 | PT-007 (non-compliance, storage exceed NHS guidance) | PUC-006 | TA-016 | Refill records auto-deleted after 7 years; deletion tested; backups scrubbed | Critical |
| PRV-005 | Data subject rights | PRV | UC-001, UC-002, UC-003 | PT-008 (non-compliance: no rights mechanism) | PUC-003 | TA-012, TA-017 | Patient can access/export/erase own data via portal; DSAR process documented | Critical |
| PRV-006 | Third-party DPA | PRV | UC-004 | PT-005 (disclosure to uncontrolled 3rd party) | PUC-005 | TA-014, TA-018 | Email/SMS provider DPA signed; includes security, breach notification, sub-processor rules | High |
| PRV-007 | Purpose limitation | PRV | UC-001, UC-002 | PT-002 (linkability across systems for secondary use) | PUC-002 | TA-016, TA-019 | Refill data not used for analytics/research without separate consent; export audit logs on unauthorized use | High |
| PRV-008 | Breach notification process | PRV | All | PT-001, PT-004 (detectability of breach) | PUC-007 | TA-020, TA-021 | Incident response plan documented; SIEM alerts test; breach notification template reviewed | High |
| COMP-001 | GDPR + NHS Digital compliance | COMP | All | All privacy threats | All PUCs | TA-022 | Compliance checklist: DPIA completed, IG governance in place, DPA signed | Critical |
| COMP-002 | DPIA conducted | COMP | All | PT-009 (non-compliance: no DPIA) | PUC-004 | TA-022, TA-023 | DPIA document completed; DPO sign-off; risk mitigation measures linked to controls | Critical |
| COMP-003 | NHS DSPT registration | COMP | All | COMP-001 | PUC-004 | TA-024 | System registered on NHS DSPT; self-assessment completed; evidence provided | High |
| COMP-004 | DSAR response process | COMP | UC-001, UC-002 | PT-008 (non-compliance: no rights mechanism) | PUC-003, PUC-004 | TA-025 | DSAR process: acknowledge within 5 days, provide data within 30 days, documented | High |
| PERF-001 | 99.5% uptime SLA | PERF | All | Implicit: ST-005 (DoS impact), ST-008 (data loss) | (Infrastructure design) | TA-026 | Monthly uptime measured; alerting on degradation; incident response tested | Medium |
| PERF-002 | Prescription list loads <2s | PERF | UC-001 | Implicit: user frustration may lead to workarounds | (Database indexing, caching) | TA-027 | Load test: 100 prescriptions load in <2s; p95 <3s | Low |
| PERF-003 | GP queue queryable <1s at 10k items | PERF | UC-003 | Implicit: slow GP queue may encourage manual overrides/shortcuts | (Database indexing) | TA-028 | Load test: Query 10k requests in <1s; p95 <1.5s | Low |

---

## 9. Test Artifacts

### 9.1 Functional Security Tests

#### TA-001: FHIR API Authorization – Patient Isolation
**Type:** Functional Security Test
**Requirement(s):** SEC-002, SEC-003, FR-001
**Scenario:**
Verify that a patient cannot access another patient's prescriptions via the FHIR API. A patient with NHS number NHS123 attempts to query prescriptions for NHS456.

**Test approach:** Integration test
**Steps:**
1. Authenticate as patient NHS123
2. Call FHIR API: `GET /fhir/Patient/NHS456/Medication` (attempting to access another patient's data)
3. Expected: API returns 403 Forbidden with message "You do not have permission to access this resource"
4. Verify: Response does not contain any medication data for NHS456

**Expected outcome:** 403 Forbidden; no data leaked
**Automation potential:** High
**Test code example:**
```javascript
// Jest/JavaScript integration test
describe('FHIR API Authorization', () => {
  it('should deny patient access to another patient\'s prescriptions', async () => {
    const patient1Token = await getAuthToken('NHS123');
    const response = await fhirClient.get('/Patient/NHS456/Medication', {
      headers: { Authorization: `Bearer ${patient1Token}` }
    });
    expect(response.status).toBe(403);
    expect(response.body).not.toContain('NHS456');
  });
});
```

---

#### TA-002: GP Authorization – Practice Boundary
**Type:** Functional Security Test
**Requirement(s):** SEC-002
**Scenario:**
Verify that a GP from Practice A cannot access refill requests for patients not assigned to their practice.

**Test approach:** Integration test
**Steps:**
1. Create two practices: PracticeA, PracticeB
2. Create a patient assigned to PracticeB
3. Authenticate as GP from PracticeA
4. Attempt to query refill requests for PracticeB patient
5. Expected: GP gets empty list or 403

**Expected outcome:** GP's queue filtered to only their assigned patients
**Automation potential:** High

---

#### TA-003: Input Validation – SQL Injection & XSS Prevention
**Type:** Functional Security Test
**Requirement(s):** SEC-004, FR-005
**Scenario:**
Verify that malicious input (SQL injection, XSS payloads) is sanitized or rejected in patient notes and GP decline reasons.

**Test approach:** Unit test
**Steps:**
1. Submit refill request with patient notes: `'; DROP TABLE refill_requests; --`
2. Expected: Request rejected or notes sanitized; table not dropped
3. Submit refill request with notes: `<script>alert('xss')</script>`
4. Expected: Request accepted but script tag removed or encoded
5. Verify: Database query executed with parameterized statements (inspect via logging)

**Expected outcome:** Payloads blocked or sanitized; no injection executed
**Automation potential:** High
**Test code example:**
```javascript
describe('Input Validation', () => {
  it('should reject SQL injection in patient notes', async () => {
    const payload = { notes: "'; DROP TABLE refill_requests; --" };
    const response = await submitRefillRequest(payload);
    expect(response.status).toBe(400); // or sanitized
    // Verify table still exists
    const tableExists = await checkTableExists('refill_requests');
    expect(tableExists).toBe(true);
  });

  it('should sanitize XSS in patient notes', async () => {
    const payload = { notes: "<script>alert('xss')</script>" };
    const response = await submitRefillRequest(payload);
    expect(response.status).toBe(200);
    const savedNotes = await getRefillRequestNotes(response.id);
    expect(savedNotes).not.toContain('<script>');
  });
});
```

---

#### TA-004: Rate Limiting – Request Throttling
**Type:** Functional Security Test
**Requirement(s):** SEC-005
**Scenario:**
Verify that rate limiting is enforced: max 5 refill requests per hour per patient; max 100 per hour per IP.

**Test approach:** Integration test
**Steps:**
1. Submit 5 refill requests in rapid succession (different prescriptions)
2. Expected: Requests 1–5 succeed; requests 6+ return 429 Too Many Requests
3. Wait 1 hour; submit 6th request
4. Expected: Request succeeds (limit reset)

**Expected outcome:** 6th request within 1 hour returns 429; 6th request after 1 hour succeeds
**Automation potential:** High (with rate limit bypass for testing)

---

#### TA-005: Immutable Audit Logs – Tampering Detection
**Type:** Functional Security Test
**Requirement(s):** SEC-006
**Scenario:**
Verify that audit log entries are immutable and digitally signed; any tampering is detected.

**Test approach:** Integration test
**Steps:**
1. Submit refill request; log entry created: `{user=patient123, action=submit_refill, refill_id=123, signature=SHA256(...)}`
2. Attempt to modify log entry in database: `UPDATE audit_logs SET action='approve_refill' WHERE refill_id=123`
3. Run integrity check: `verify_audit_log_integrity()`
4. Expected: Tampered entry detected; signature mismatch alerts

**Expected outcome:** Tampered log detected; alert generated
**Automation potential:** Medium (requires SIEM / log monitoring setup)

---

#### TA-006: Authorization – GP Action Validation
**Type:** Functional Security Test
**Requirement(s):** SEC-002, FR-004
**Scenario:**
Verify that only the assigned GP can approve a refill request for a patient.

**Test approach:** Integration test
**Steps:**
1. Create refill request for PatientA by PracticeA-GP1
2. Authenticate as PracticeB-GP2 (different practice)
3. Attempt to approve the refill request
4. Expected: Request denied; 403 Forbidden

**Expected outcome:** GP cannot approve refills outside their practice
**Automation potential:** High

---

### 9.2 Security Attack Tests

#### TA-007: SQL Injection Attempt – OWASP Top 10 A03
**Type:** Security Attack Test
**Abuse case(s):** SAC-004
**Attack scenario:**
An attacker attempts SQL injection via the patient notes field to exfiltrate or delete data.

**Test approach:** Automated (OWASP ZAP, sqlmap, or custom script)
**Suggested tools:**
- OWASP ZAP: Automated scanning for injection points
- sqlmap: SQL injection testing framework
- Custom Python script: Fuzz endpoints with injection payloads

**Attack payload examples:**
- `'; DROP TABLE refill_requests; --`
- `' OR '1'='1`
- `' UNION SELECT * FROM users --`

**Expected outcome:** All injection attempts blocked or database unchanged; no data exfiltrated
**Verification:**
- Database integrity check post-test
- No unauthorized data in response logs
- Error messages generic (no SQLi indication)

---

#### TA-008: Rate Limit Bypass & DoS
**Type:** Security Attack Test
**Abuse case(s):** SAC-005
**Attack scenario:**
An attacker attempts to overwhelm the GP queue by submitting thousands of refill requests.

**Test approach:** Automated (Apache JMeter, LoadRunner, or custom script)
**Suggested tools:**
- Apache JMeter: Load testing with ramping
- LoadRunner: Enterprise load testing
- Custom Python script: Fast, parallel HTTP requests

**Attack steps:**
1. Send 1000 refill requests in 60 seconds (distributed across 10 concurrent threads)
2. Verify: Requests 1–5 per patient per hour succeed; 6+ return 429
3. Verify: GP queue is not overwhelmed; processing remains responsive

**Expected outcome:** DoS attack mitigated; queue protected; requests rate-limited
**Verification:**
- 429 responses received after limit exceeded
- Queue size remains <5000
- GP responsiveness maintained (<1s query time)

---

#### TA-009: Session Hijacking & Token Theft
**Type:** Security Attack Test
**Abuse case(s):** SAC-002
**Attack scenario:**
An attacker steals a patient's NHS login token and attempts to impersonate the patient.

**Test approach:** Manual / Penetration testing
**Suggested tools:**
- Browser Developer Tools: Inspect cookies, tokens
- Burp Suite: Intercept and modify requests
- Custom script: Test token reuse

**Attack steps:**
1. Obtain a valid patient token (simulate theft via XSS, MITM, etc.)
2. Use token in forged request to access another patient's data
3. Expected: Unauthorized token rejected or session invalidated

**Expected outcome:** Token theft mitigated by:
- HttpOnly flag (token not accessible via JavaScript)
- Short token lifetime (15–30 min)
- SameSite cookie attribute (prevents CSRF token reuse)
- HTTPS enforcement (prevents MITM token capture)
- Session validation: Token checked against server session state

**Verification:**
- Token not readable via XSS (HttpOnly)
- Token expires after 30 min
- Stolen token rejected after re-authentication required

---

#### TA-010: Unencrypted Data in Transit (MITM)
**Type:** Security Attack Test
**Abuse case(s):** SAC-007
**Attack scenario:**
An attacker on a network intercepts unencrypted traffic to capture patient prescription data.

**Test approach:** Network interception (MITM proxy)
**Suggested tools:**
- Burp Suite: MITM proxy to intercept HTTPS (with certificate pinning bypass for testing)
- mitmproxy: Custom MITM setup
- Wireshark: Packet sniffing

**Attack steps:**
1. Attempt to access portal via HTTP (should redirect to HTTPS)
2. Verify: All requests over HTTPS with TLS 1.2+
3. Verify: HSTS header present; browser rejects HTTP after first request

**Expected outcome:** All traffic encrypted; unencrypted requests rejected or redirected
**Verification:**
- No HTTP endpoints available for sensitive operations
- HSTS header present: `Strict-Transport-Security: max-age=31536000`
- Certificate valid and trusted
- TLS version >= 1.2

---

#### TA-011: TLS Certificate Validation
**Type:** Security Attack Test
**Abuse case(s):** SAC-007
**Attack scenario:**
An attacker attempts to use a self-signed or invalid certificate to perform MITM.

**Test approach:** Manual (browser, curl, custom script)
**Steps:**
1. Access portal with self-signed certificate
2. Expected: Browser rejects connection with certificate warning
3. Curl with `--insecure` flag should fail in production (security test)

**Expected outcome:** Invalid certificates rejected; only valid, trusted certificates accepted
**Verification:**
- Certificate signed by trusted CA
- Certificate not expired
- Domain matches certificate CN/SAN

---

### 9.3 Privacy Verification Tests

#### TA-012: Data Subject Rights – Access & Portability
**Type:** Privacy Verification
**Requirement(s):** PRV-005
**Scenario:**
Verify that a patient can access and export all their refill data.

**Test approach:** Functional + manual audit
**Steps:**
1. Patient logs in; navigates to "My Data" or "Download My Data"
2. Clicks "Download Refill History"
3. System provides CSV/JSON export with:
   - All refill requests (ID, date, medication, status)
   - All GP decisions (approval/decline, date, reason)
   - All notifications sent
4. Verify: Export is complete (matches database records)
5. Verify: Export is timely (<30 min processing time)

**Expected outcome:** Patient can download portable copy of own data
**Automation potential:** High
**Test code example:**
```javascript
describe('Data Subject Rights – Access', () => {
  it('should allow patient to download own refill data', async () => {
    const response = await downloadMyData(patientId, 'refill_data');
    expect(response.status).toBe(200);
    const csvData = parseCSV(response.body);
    expect(csvData.length).toBeGreaterThan(0);
    expect(csvData[0]).toHaveProperty('refill_id');
    expect(csvData[0]).toHaveProperty('medication');
    expect(csvData[0]).toHaveProperty('gp_decision');
  });
});
```

---

#### TA-013: Dependency Security Audit
**Type:** Privacy Verification
**Requirement(s):** SEC-011
**Scenario:**
Verify that all third-party dependencies are audited for known vulnerabilities.

**Test approach:** Automated (npm audit, OWASP Dependency-Check)
**Steps:**
1. Run `npm audit` (or equivalent for your language)
2. Identify any vulnerabilities (HIGH or CRITICAL)
3. Plan updates/patches within 30 days
4. Re-run audit after updates

**Expected outcome:** No HIGH/CRITICAL vulnerabilities; LOW/MEDIUM addressed within 90 days
**Automation potential:** High (integrate into CI/CD pipeline)

---

#### TA-014: Third-Party Data Processor Compliance
**Type:** Privacy Verification
**Requirement(s):** PRV-006
**Scenario:**
Verify that email/SMS providers are bound by a Data Processing Agreement (DPA) and comply with security obligations.

**Test approach:** Manual audit + contractual review
**Steps:**
1. Obtain copy of DPA with email provider (e.g., SendGrid)
2. Verify DPA includes:
   - Data processing scope (what data, how, how long)
   - Security obligations: TLS encryption, access controls, encryption at rest
   - Breach notification: provider notifies within 24 hours
   - Sub-processor rules: no sub-contracting without approval
   - Data subject rights: assist with access/erasure requests
3. Request provider's SOC 2 Type II or ISO 27001 certificate
4. Review certificate for relevant controls

**Expected outcome:** DPA signed and in force; provider security certified
**Automation potential:** Low (requires manual review)

---

#### TA-015: Privacy Notice Clarity & Completeness
**Type:** Privacy Verification
**Requirement(s):** PRV-001
**Scenario:**
Verify that the Privacy Notice is comprehensive, clear, and compliant with GDPR Article 13.

**Test approach:** Manual review + user testing
**Steps:**
1. Read Privacy Notice from patient's perspective
2. Checklist of required information (GDPR Article 13):
   - [ ] Identity of data controller
   - [ ] Purposes of processing
   - [ ] Lawful basis (Article 6 & 9)
   - [ ] Recipients of data (e.g., GPs, pharmacy, NHS Digital)
   - [ ] Retention period (7 years for refills; 10 years for anonymized logs)
   - [ ] Data subject rights (access, erasure, portability, rectification, objection)
   - [ ] Right to lodge complaint with ICO
   - [ ] Source of data (patient-provided)
   - [ ] Contact details (DPO, data controller)
3. Test readability: Simple language, no legal jargon, accessible formatting
4. Verify: Notice displayed before first data collection, not buried in ToS

**Expected outcome:** Privacy Notice comprehensive, clear, compliant
**Automation potential:** Low (requires manual legal review)

---

#### TA-016: Data Retention & Deletion Policy
**Type:** Privacy Verification
**Requirement(s):** PRV-004
**Scenario:**
Verify that old refill request records are automatically deleted after 7 years.

**Test approach:** Automated database audit + testing
**Steps:**
1. Create test refill request with `created_at = NOW() - 8 years` (in staging database)
2. Run deletion job: `./scripts/delete-old-refill-requests.sh`
3. Verify: Test record deleted
4. Verify: Records <7 years old NOT deleted
5. Verify: Deletion logged (audit trail of what was deleted, when, by whom)

**Expected outcome:** Records >7 years deleted; <7 years retained; deletion logged
**Automation potential:** High

---

#### TA-017: Right to Erasure (Deletion Request)
**Type:** Privacy Verification
**Requirement(s):** PRV-005
**Scenario:**
Verify that a patient can request deletion of their refill data, and the system complies.

**Test approach:** Functional + audit
**Steps:**
1. Patient submits deletion request via portal: "Delete all my refill requests"
2. System processes request:
   - Identify all refill requests for patient
   - Delete from production database
   - Verify deletion in backups (or schedule for deletion on next backup cycle)
   - Log deletion event
3. Verify: Patient data no longer accessible; deletion time <30 days

**Expected outcome:** Deletion request processed; data removed; logged
**Automation potential:** Medium (requires backup system coordination)

---

#### TA-018: Notification Consent Tracking
**Type:** Privacy Verification
**Requirement(s):** PRV-002
**Scenario:**
Verify that patient notification consent is tracked and honored.

**Test approach:** Functional test
**Steps:**
1. Patient logs in; navigates to "Notification Preferences"
2. Patient opts out of SMS notifications (email only)
3. System creates refill request; GP approves
4. Verify: Patient receives email notification
5. Verify: Patient does NOT receive SMS

**Expected outcome:** Consent preferences honored; unwanted notifications not sent
**Automation potential:** High

---

### 9.4 Penetration Testing Scenarios

#### TA-019: Cross-Patient Data Access (Manual Pen Test)
**Type:** Penetration Test Scenario
**Scope:** FHIR API, patient portal authorization
**Objectives:**
- Attempt to access prescriptions for patients other than yourself
- Enumerate valid patient IDs / NHS numbers
- Verify authorization is enforced at API layer

**Key abuse cases to validate:**
- SAC-001 (Cross-Patient Prescription Harvesting)
- ST-001 (Cross-Patient Prescription Access)

**Attack approaches:**
1. As authenticated patient, inspect FHIR API calls; attempt parameter tampering (e.g., change `patient_id` in query string)
2. Enumerate NHS numbers: try sequential queries `GET /fhir/Patient/{nhs_number}/Medication`
3. Attempt to access GP queue for another practice
4. Use authorization token from patient account; attempt to access GP endpoints

**Out of scope:**
- Attacks requiring code review (internal)
- Attacks on NHS login system itself (external service)

**Expected outcome:**
- All cross-patient queries rejected with 403
- No data leaked in error messages
- Enumeration attempts logged and flagged

---

#### TA-020: Refill Request Tampering (Manual Pen Test)
**Type:** Penetration Test Scenario
**Scope:** Refill request database, API endpoints
**Objectives:**
- Attempt to modify refill request status without GP approval
- Attempt to forge GP approval
- Verify immutability controls

**Key abuse cases to validate:**
- SAC-003 (Tampering – Refill Request Status Modification)
- ST-003 (Tampering with Refill Request Status)

**Attack approaches:**
1. Inspect HTTP requests; attempt to modify `status` parameter in refill submission or approval API call
2. Attempt to modify database directly (if access possible; simulated in staging)
3. Attempt to create a refill request with pre-approved status
4. Inspect audit logs; verify entries are signed and cannot be modified

**Out of scope:**
- Physical access to database server
- Attacks requiring database credentials (insider threat; covered in threat model)

**Expected outcome:**
- All tampering attempts detected/prevented
- Status field immutable post-creation
- Audit logs show attempted tamper with signature mismatch

---

#### TA-021: Incident Response & Breach Notification (Tabletop Pen Test)
**Type:** Penetration Test Scenario
**Scope:** Incident response process, breach notification workflow
**Objectives:**
- Test incident response team's ability to detect, contain, and notify of a breach
- Verify breach notification triggers correctly (ICO notification within 72h, patient within 30d)
- Validate incident response plan

**Key abuse cases to validate:**
- PAC-001, PAC-002, PAC-003, PAC-004 (privacy abuse cases)
- PUC-007 (Incident Response & Breach Notification)

**Scenario (tabletop exercise):**
1. Tester reports: "We detected unusual FHIR API queries accessing 1000+ patients' prescriptions via our SIEM"
2. Incident response team:
   - Convenes within 1 hour
   - Determines scope: 5000 patients' prescription data potentially accessed
   - Isolates affected systems; revokes suspicious API keys
   - Contacts DPO and legal
   - Prepares breach notification to ICO (within 72 hours)
   - Prepares patient notification (within 30 days)
3. Verifies: Breach notification sent with required info (what happened, who affected, what we're doing, patient rights)

**Out of scope:**
- Actual patient notifications (test with subset/test data)
- Public disclosure

**Expected outcome:**
- Incident response plan executed effectively
- ICO notified within 72 hours
- Patient notifications sent within 30 days with clear, actionable info
- Lessons learned documented; controls improved

---

#### TA-022: GDPR Compliance Checklist (Audit)
**Type:** Penetration Test Scenario / Audit
**Scope:** Organization, system, process level
**Objectives:**
- Verify system meets GDPR requirements end-to-end
- Identify any gaps in compliance

**Checklist:**
- [ ] DPIA completed and documented
- [ ] Data Processing Agreement signed with all processors
- [ ] Privacy Notice published and accessible
- [ ] Patient consent mechanisms in place (notification preferences)
- [ ] Data retention policy implemented (7-year automatic deletion)
- [ ] Data subject rights process documented (SAR, erasure, portability)
- [ ] Breach detection process in place (SIEM, logging)
- [ ] Data Protection Officer appointed/engaged
- [ ] Staff training on GDPR (Data Protection, Confidentiality)
- [ ] Third-party security certifications obtained (SOC 2, ISO 27001)

**Out of scope:**
- Organization-wide GDPR audit (focus on prescription module)

**Expected outcome:**
- All GDPR requirements met or documented as exceptions
- Compliance evidence stored in secure, accessible location

---

---

## Appendix A: STRIDE Reference

**Spoofing** — An attacker assumes the identity of a legitimate user or system.
*Example:* Stealing a session token and impersonating a patient.

**Tampering** — An attacker modifies data in transit or at rest.
*Example:* Changing a refill request status from pending to approved.

**Repudiation** — An attacker denies having performed an action; the system cannot prove they did.
*Example:* A GP claims they never approved a refill, but no audit trail exists.

**Information Disclosure** — Sensitive data is exposed to unauthorized parties.
*Example:* Prescription data exposed via unencrypted network traffic.

**Denial of Service** — An attacker makes the system unavailable to legitimate users.
*Example:* Flooding the GP queue with fake refill requests.

**Elevation of Privilege** — An attacker gains higher-level access than intended.
*Example:* A patient modifies another patient's refill request.

---

## Appendix B: LINDDUN Reference

**Linkability** — Data or actions linked to an individual across contexts or systems.
*Example:* Prescription patterns linked to patient identity across multiple NHS systems.

**Identifiability** — Re-identifying a person from supposedly anonymous data.
*Example:* Inferring a patient's HIV status from refill request metadata.

**Non-Repudiation** — User cannot deny an action (may harm user privacy).
*Example:* Permanent audit logs of GP decisions.

**Detectability** — Detecting that data about a person exists, without reading it.
*Example:* Logs revealing that a patient uses the refill system on specific dates.

**Disclosure** — Personal data exposed beyond intended scope.
*Example:* Patient prescriptions shared with external notification provider.

**Unawareness** — Users don't know what data is collected or how it's used.
*Example:* Patients unaware that refill requests are logged for 7 years.

**Non-Compliance** — System fails to meet privacy/regulatory obligations.
*Example:* Data retained longer than GDPR storage limitation principle allows.

---

## Appendix C: OWASP Top 10 (2021) Quick Reference

| Rank | Vulnerability | Example in RxRefill |
|---|---|---|
| A01 | Broken Access Control | Patient viewing another patient's prescriptions (ST-001) |
| A02 | Cryptographic Failures | Unencrypted data in transit (ST-007) or at rest (ST-008) |
| A03 | Injection | SQL injection in patient notes (ST-004) |
| A04 | Insecure Design | (Design level; not a specific attack in this analysis) |
| A05 | Security Misconfiguration | (Deployment level; not a specific attack) |
| A06 | Vulnerable & Outdated Components | Supply chain risk (SEC-011) |
| A07 | Identification & Authentication Failures | Session hijacking (ST-002) |
| A08 | Software & Data Integrity Failures | Audit log tampering (ST-006) |
| A09 | Logging & Monitoring Failures | Insufficient audit logging (ST-006) |
| A10 | SSRF | (Not applicable; no server-side request forgery in this design) |

---

## Appendix D: GDPR Privacy by Design Principles

**1. Proactive, not Reactive**
Address privacy risks upfront during design, not after a breach. Conduct DPIA before deployment.

**2. Privacy as Default**
Minimize data collection by default. Assume users don't consent to everything; require explicit opt-in for secondary uses.

**3. Privacy Embedded into Design**
Privacy must be integral to system architecture and operations, not bolted on. Examples:
- Encryption at design level, not added after
- Authorization checks at API layer, not just UI

**4. Full Functionality**
Privacy and security should not compromise functionality. System must be usable and secure simultaneously.

**5. End-to-End Security**
Protect data throughout its lifecycle: collection, use, retention, deletion, backup recovery. Not just in production, but in development, testing, backups, and disaster recovery.

**6. Visibility and Transparency**
Users must understand what data is collected, how it's used, and their rights. Privacy Notice is essential.

**7. Respect for User Privacy**
Keep users in control. Provide mechanisms for consent, withdrawal, data access, deletion. Users should be able to make informed choices.

---

## Appendix E: NHS Digital Standards Reference

Key NHS Digital standards referenced in this analysis:
- **Data Security and Protection Toolkit (DSPT)** — Self-assessment of IG governance and security maturity
- **IG Toolkit** — Information Governance compliance framework (deprecated but still referenced)
- **NHS Digital Data Standards** — Data retention guidance for healthcare records (typically 3–10 years depending on record type)
- **NHS Digital Security Architecture** — Guidance on API security, encryption, audit logging

---

## Conclusion

This security and privacy by design analysis has identified 25 security threats (STRIDE), 9 privacy threats (LINDDUN), 7 security abuse cases, 7 privacy abuse cases, and corresponding countermeasures (16 security use cases, 8 privacy use cases). The refined requirements include 34 security/privacy/compliance requirements not originally specified.

The most critical areas for the engineering team to prioritize:
1. **Authorization & Access Control** (SUC-001): Prevent cross-patient prescription access
2. **Audit & Non-Repudiation** (SUC-003): Immutable logging with integrity checks
3. **Rate Limiting** (SUC-005): Protect GP queue from DoS
4. **Data Retention & Deletion** (PUC-006): Comply with storage limitation principle
5. **Privacy Transparency** (PUC-001): Provide Privacy Notice and enable data subject rights

All requirements are traced to threat analysis and test artifacts in the SRTM (Section 8). The test artifacts (Section 9) provide concrete, actionable verification steps for the QA and security testing teams.

**Next steps:**
1. Review this analysis with the Data Protection Officer and clinical leadership
2. Conduct the DPIA (PUC-004, COMP-002) formally; document residual risks
3. Draft the Privacy Notice (PUC-001) for patient review
4. Negotiate and sign Data Processing Agreements with third-party providers (PUC-005)
5. Implement controls in priority order; use SRTM to track progress
6. Execute test artifacts during development and QA; verify 100% coverage of SEC/PRV requirements

---

**Document prepared:** 2026-03-30
**Analysis framework:** STRIDE (Microsoft), LINDDUN (KU Leuven), OWASP Top 10 & ASVS, GDPR & Privacy by Design
