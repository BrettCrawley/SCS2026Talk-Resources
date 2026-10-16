# P2P Marketplace MVP - Security & Privacy Analysis
**Focus: Highest-Priority Risks Only**

---

## Executive Summary

This P2P marketplace connects users to lend/borrow physical items with payment processing via Stripe. As a solo MVP, the priority is preventing **data breaches, financial fraud, and unsafe transactions** that could harm users or shut down the platform. Three critical areas need immediate attention: **user authentication/session security**, **payment data handling**, and **trust mechanisms to prevent scams**.

---

## 1. CRITICAL RISK: User Authentication & Session Management

### The Risk
A compromise in auth directly exposes:
- User accounts (location, phone, email, payment methods)
- Messaging/personal communication
- Ability for attackers to impersonate users and commit fraud (fake listings, fake reviews, fake requests)

### What to Implement (MVP Minimum)

**Password Security:**
- Require passwords ≥12 characters (mixed case, numbers, symbols)
- Hash with bcrypt (cost factor 12+) or Argon2 — **never store plaintext**
- Rate-limit login attempts (5 failed attempts → 15-minute lockout)

**Session Management:**
- Use secure HTTP-only cookies for session tokens (not localStorage for auth)
- Set `Secure` flag (HTTPS only) and `SameSite=Strict`
- Session timeout after 30 minutes of inactivity
- Invalidate session immediately on logout

**HTTPS Everywhere:**
- All traffic over TLS 1.2+ (your hosting provider likely enforces this)
- HSTS header with 1-year max-age to prevent downgrade attacks

**Email Verification:**
- Send confirmation link on signup; block account until verified
- Prevents typos, fake emails, and bulk account creation for spam

### Why This First
A compromised user account can do unlimited damage: rent their items to steal them, trash reviews, scam borrowers. This happens on day one of your MVP and cascades into everything else.

---

## 2. CRITICAL RISK: Payment Data & Stripe Integration

### The Risk
Handling card data (even temporarily) = PCI compliance burden, audit targets, and breaches. Stripe exists so you don't do this.

### What to Implement (MVP Minimum)

**Use Stripe Hosted Checkout or Elements:**
- Customer card data **never touches your server** — Stripe collects it
- You receive a `payment_intent_id` or `token` to charge later
- **Do not** build your own card form; use Stripe's pre-built UI

**Never Log/Store:**
- ❌ Full PAN (card numbers)
- ❌ CVC/CVV
- ❌ Unencrypted card metadata
- ✓ Stripe customer ID (payment_intent references, not card details)

**Idempotency for Payment Retries:**
- Add idempotency key to Stripe API calls (prevents double-charging if a retry happens)
- Example: `Idempotency-Key: {borrower_id}_{item_id}_{rental_start_date}`

**Immediate Escrow Model (Optional but Recommended):**
- Stripe holds money until both parties confirm transaction completion
- Reduces "lender takes payment, never delivers item" fraud
- Stripe Connect (marketplace mode) can auto-split fees

### Why This Matters
PCI DSS is complex and expensive to maintain. Any card data breach = platform shutdown + lawsuits. Stripe handles this for you; use it.

---

## 3. CRITICAL RISK: Trust & Fraud Prevention

### The Risk
Your rating system, messaging, and borrowing flow are attack surfaces:
- Fake listings (scammers list items they don't own)
- Fake reviews (buy/sell fake ratings to appear trustworthy)
- Rental fraud (borrow item, claim it was damaged/stolen, demand refund)
- Sextortion/harassment via messaging (neighbors with bad intentions)

### What to Implement (MVP Minimum)

**Verify Lenders Own Items:**
- Require photo of item with user's username/date handwritten on a card in the photo (prevents stock photos)
- Manual review of first listing from new user (yes, it's manual; automate later if needed)

**Prevent Review Manipulation:**
- Only allow ratings **after the rental period ends** (borrower returns item)
- Only lenders can rate borrowers, only borrowers can rate lenders (prevent self-dealing)
- Display on lender profile: "Member since [date]" and avg rating (e.g., 4.8/5 from 12 reviews)
- Cap visible reviews to prevent historical rewriting (e.g., always show last 10)

**Messaging Safety:**
- No real phone numbers in messages; users must start request within app
- Flag/disable accounts with repeated abuse reports (3+ reports → review before reactivating)
- Don't expose user location until request is approved by lender

**Prevent Duplicate Rentals:**
- Once an approved rental exists for an item on overlapping dates, block other requests for those dates
- Prevents "I'll rent the same tool twice and get two payments"

**Know Your User (KYC) - Basics Only:**
- For signup, require: valid email, phone number (SMS verification), first/last name
- Don't ask for SSN/tax ID yet (can add for payout later)
- Phone verification prevents burner accounts

### Why This Matters
Unlike eBay/Airbnb, you're facilitating local, in-person transactions. A bad review or fraud can spread locally and kill your platform's reputation fast. Lenders need confidence that the borrower is real.

---

## 4. High Priority: Personal Data & Privacy

### The Risk
You're collecting location (neighborhood/zip), phone, email, item photos, and messaging history. A breach = doxing risk.

### What to Implement (MVP Minimum)

**Location Privacy:**
- Store only neighborhood/zip, not exact address or GPS coordinates
- Don't show address to borrower until **after** lender approves the request
- Never broadcast all users' locations on a map at launch

**Data Minimization:**
- Collect only: email, phone, first/last name, zip, items, photos, ratings, messages
- Don't ask for birthday, SSN, address until needed (e.g., for 1099s later)

**Backups & Retention:**
- Delete user data after 90 days if account is closed (item photos, messages, etc.)
- Keep transaction history for 7 years (legal requirement for payment records)
- Backups: encrypt at rest and limit admin access

**Password Reset Security:**
- Reset link valid for 15 minutes only
- Invalidate all other sessions when password is reset (attacker loses access)
- Send email notification when password is reset

### Why This Matters
As a local marketplace, you're an attractive target for doxing/stalking if data leaks. Users trust you with their home location. Don't expand data collection past MVP minimum.

---

## 5. Medium Priority: Infrastructure & Access Control

### The Risk
If your database is misconfigured or admin accounts are weak, attackers can steal everything.

### What to Implement (MVP Minimum)

**Database Security:**
- Run on a managed database (AWS RDS, GCP Cloud SQL, Heroku Postgres, etc.) — not a VPS you manage
- Encrypt database at rest (usually default in managed options)
- Backup automatically (1 backup per day, keep 30 days)
- Use environment variables for DB credentials; **never commit to git**

**Admin/API Access:**
- Admin dashboards/APIs require multi-factor authentication (MFA)
  - Even if it's just SMS for MVP, use it
- Rotate API keys every 90 days (set a calendar reminder)
- Disable public database access; only your app can connect
- Use unique, strong passwords for admin (≥16 characters, password manager)

**Logging:**
- Log all admin actions: user suspensions, payment refunds, listing deletions, review removals
- Keep audit logs for 1 year (helps forensics if there's an incident)
- Don't log passwords, card tokens, or full emails in logs (use hashing to identify)

### Why This Matters
Your DB is the crown jewel. Weak infrastructure = everything else is pointless.

---

## 6. Lower Priority (Post-MVP): Security Hardening

These are important but not blocking MVP launch:

- **CSRF protection** on all state-changing forms (Stripe webhooks, payment processing)
- **CSP (Content Security Policy)** header to prevent XSS
- **SQL injection prevention** (use parameterized queries — all modern ORMs do this)
- **Rate limiting** on API endpoints (prevent spam/scraping)
- **Bot detection** on signup (CAPTCHA or similar)
- **Encryption of messaging** at rest (E2E encryption is nice-to-have, not MVP)

---

## 7. Implementation Checklist (MVP Phase)

Priority order for a solo developer:

### Week 1: Auth & Database
- [ ] Implement bcrypt password hashing
- [ ] Set up secure session management (HTTP-only cookies, HTTPS)
- [ ] Email verification for signup
- [ ] Use managed database with automatic backups

### Week 2: Payments
- [ ] Integrate Stripe checkout (use hosted page, not custom form)
- [ ] Never store card data; only keep payment_intent references
- [ ] Implement idempotency keys

### Week 3: Trust & Fraud Prevention
- [ ] Implement photo verification for listings (manual review first)
- [ ] Ratings only after rental ends; prevent self-dealing
- [ ] Phone verification on signup
- [ ] Block duplicate overlapping rentals

### Week 4: Data Privacy
- [ ] Store only neighborhood/zip (not exact address)
- [ ] Hide location until request is approved
- [ ] Add data retention policy (delete closed account data after 90 days)
- [ ] Send password reset notification emails

### Ongoing: Monitoring
- [ ] Review admin audit logs weekly
- [ ] Monitor for failed logins (sign of account compromise attempts)
- [ ] Check for fraud patterns in reviews (e.g., new users rating each other 5 stars)

---

## What NOT to Do in MVP

- ❌ Don't handle card payments yourself
- ❌ Don't store addresses; use ZIP code
- ❌ Don't build your own auth; use a library (bcrypt, passport.js, Django auth, etc.)
- ❌ Don't enable password reset without email verification
- ❌ Don't launch without HTTPS
- ❌ Don't expose user locations publicly (even anonymized)
- ❌ Don't allow unverified phone numbers

---

## Regulatory Notes (FYI)

- **PCI DSS**: Stripe handling card data, so you're off the hook (as long as you follow the checklist)
- **State/Federal Laws**: Liability for items borrowed; recommend Terms of Service + liability waivers (get a lawyer review before scaling)
- **Payment Reporting**: Stripe reports transactions to IRS if ≥$5K/year; users may get 1099-Ks
- **GDPR/CCPA**: If you have EU/CA users, you'll need privacy policy + right to delete (start simple, scale later)

---

## Summary: What Success Looks Like

By end of MVP:
- Users can sign up with verified email/phone
- Lenders list items with verified photos
- Borrowers search and request rentals
- Payment flows through Stripe (no card data on your servers)
- Both parties rate each other after transaction
- Admin can review fraud reports and suspend bad users
- All data encrypted at rest, backed up daily
- No significant data breaches or payment issues

Once this is solid and you have users, add:
- E2E messaging encryption
- Advanced bot detection
- Marketplace insurance or liability coverage
- KYC/AML for high-value rentals

---

## Key Takeaway

**Focus on the three critical areas first:**
1. **Authentication**: Secure logins prevent account takeovers
2. **Payments**: Never touch card data; use Stripe
3. **Trust**: Verify lenders, rate fairly, prevent fraud

These three alone eliminate 80% of the risk. Do these well, and you can iterate on the rest without exposing users to critical harm.
