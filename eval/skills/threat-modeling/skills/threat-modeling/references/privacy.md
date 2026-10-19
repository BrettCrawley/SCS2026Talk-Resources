<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Brett Crawley -->

# Human-Centered Security & Privacy Dark Patterns Reference

---

## Human-Centered Security

Security fails when it's designed around a theoretical ideal user who always reads warnings, never reuses passwords, and makes perfect decisions under no time pressure. Real users are busy, distracted, and will take the path of least resistance.

Human-Centered Security means designing systems where:
1. **The secure option is the easiest option.** Secure defaults, not opt-in security.
2. **Friction matches risk.** Extra steps belong on risky actions (large transfers, privilege changes), not routine ones (login with a trusted device).
3. **Warnings are meaningful.** Users ignore warnings that cry wolf. Reserve security prompts for genuine threats.
4. **Errors help users, not attackers.** "Incorrect username or password" not "Username not found."
5. **Users aren't blamed for system failures.** Don't design a system that requires perfect user behaviour and then blame breaches on users.

### Checklist

Work through this for any user-facing security control:

**Defaults**
- [ ] Is the system secure by default, without requiring user action?
- [ ] Are permissions denied by default (allowlist, not denylist)?
- [ ] Are new user accounts created with minimum necessary permissions?

**Friction & Effort**
- [ ] Does completing the secure path require significantly more effort than the insecure alternative?
- [ ] Are MFA prompts targeted to risk (new device, unusual location) rather than every login?
- [ ] Is session length appropriate — not so long that it's always logged in, not so short that users disable it?

**Error Messages & Prompts**
- [ ] Do error messages avoid revealing system internals (stack traces, DB errors, enumerable usernames)?
- [ ] Are permission prompts specific — explaining exactly what access is requested and why?
- [ ] Is security-critical information presented at the point of decision, not buried elsewhere?

**Recovery**
- [ ] Is account recovery secure but accessible? (Recovering a locked account should not be easier than the original auth)
- [ ] Are users notified of security events (new device login, password change) via out-of-band channel?

**Trust & Transparency**
- [ ] Are users told what data is collected and why, in plain language?
- [ ] Is consent obtained before collecting sensitive data, and is it meaningful (not pre-ticked)?
- [ ] Can users see and revoke what access they've granted?

---

## Privacy Dark Patterns

Privacy Dark Patterns are interface or system design choices that manipulate users into sharing more data than they would if making a fully informed, uncoerced choice. They are ethically wrong, increasingly illegal (GDPR, CCPA enforcement, FTC actions), and a threat to user trust.

**Never implement these patterns. Flag them immediately when found.**

### The Dark Pattern Catalogue

#### 1. Misleading Choices (Trick Questions)
- Confusingly worded consent options where accepting and declining look the same
- Double negatives: "Uncheck this box to not receive marketing emails"
- Mismatched visual prominence — "Accept All" is large and highlighted; "Manage Preferences" is small grey text

**Correct design**: Consent options should be equal in visual weight. "Accept" and "Decline" should look the same.

#### 2. Hidden Costs / Default Opt-In
- Pre-ticked checkboxes for optional data sharing or marketing
- Consent bundled into terms of service — users "agree" to data collection just by using the service
- Automatically enrolling users in data sharing when upgrading or updating

**Correct design**: Opt-in for anything beyond what's strictly necessary to deliver the service. Unbundle consent.

#### 3. Privacy Maze (Impossible Opt-Out)
- Settings buried 4+ clicks deep in account preferences
- "Opt out" buttons that don't work or reset on next visit
- Requiring users to contact support to delete their account
- Providing an opt-out that only applies to one channel while data continues to be collected elsewhere

**Correct design**: Privacy controls must be as accessible as the data collection mechanism. If you can enable it in two clicks, disabling it must also take two clicks.

#### 4. Drip Pricing / Drip Privacy
- Revealing data practices gradually, only disclosing the concerning parts after the user has invested effort
- Showing a simple privacy notice at signup, then revealing the full scope of data use only in a long document nobody reads

**Correct design**: Material data practices disclosed upfront, prominently, before commitment.

#### 5. Confirmation Shaming
- "No thanks, I don't want to protect my privacy"
- "I prefer to share my data with third parties"
- Decline options that imply the user is foolish or making a bad choice

**Correct design**: Declining a data collection request should be neutral and non-judgmental.

#### 6. Disguised Ads / False Context
- Presenting targeted ads as organic recommendations
- Personalisation framed as "we care about you" without disclosing it's powered by tracking
- Using "performance cookies" language to obscure what's really advertising profiling

**Correct design**: Advertising and tracking must be clearly labelled as such.

#### 7. Forced Registration / Forced Action
- Requiring account creation (and thus data collection) for actions that don't need it
- "Continue with Google/Facebook" as the only option, forcing social login and data sharing
- Blocking functionality unless the user consents to optional data collection

**Correct design**: Guest checkout / anonymous use must be available for core functionality. Optional consent must be genuinely optional.

#### 8. Interface Interference
- Cookie banners that make "Accept All" one click but "Reject All" requires navigating nested menus
- Consent modals that appear repeatedly until the user accepts
- Dark visual design that makes the privacy-preserving choice harder to find

**Correct design**: Equivalent choices must have equivalent UX effort.

---

## Reporting Privacy Issues

When identifying Human-Centered Security failures or Privacy Dark Patterns in the threat report, use this format:

```
### [Pattern Name]
**Location**: [Where in the UI/code]
**Issue**: [What the pattern is and why it's problematic]
**Severity**: [High/Medium/Low — note: Dark Patterns are at minimum Medium, regulatory exposure makes them High]
**Remediation**: [What to do instead]
```

For Human-Centered Security issues, be specific about what behaviour the flawed design will produce. E.g., "Users will disable MFA because the current implementation prompts on every login, even from trusted devices — replacing high-frequency prompts with risk-based triggers will improve compliance."
