# Third-Party Dependency Evaluation Reference

Before adopting any external library, framework, or service, apply this evaluation. The goal is not to avoid all external dependencies — that's impractical and often counterproductive. The goal is to make a deliberate, documented decision about the tradeoffs.

---

## Evaluation Checklist

### 1. Security

**Vulnerability history**
- Search the package name on [OSV.dev](https://osv.dev), [Snyk Advisor](https://snyk.io/advisor), [deps.dev](https://deps.dev), or [NVD](https://nvd.nist.gov)
- How many CVEs in the past 2 years?
- What was the mean time to patch? Weeks is acceptable; months is a concern; years or "still open" is a blocker.

**Open vulnerabilities**
- Are there any unpatched CVEs with CVSS ≥ 7 (High/Critical)?
- If yes: is there a workaround, and is the severity relevant to this use case?

**Security posture**
- Does the project have a `SECURITY.md` or disclosed vulnerability policy?
- Does it use dependency scanning (Dependabot, Renovate) and publish a software bill of materials (SBOM)?
- Were past vulnerabilities handled responsibly (CVEs published, patches released promptly)?

**Hard blocks**:
- Any unpatched Critical CVE with no workaround → **Do not adopt**
- No security policy and history of ignored vulnerability reports → **Strong concern**

---

### 2. Maintenance & Freshness

- When was the last release? (>12 months for a dependency that's not intentionally stable is a yellow flag; >24 months is a red flag)
- When was the last commit to the main branch?
- Are there maintainers actively responding to issues and PRs?
- Is there a changelog / release notes history?
- Is the project in maintenance-only mode or actively developed?
- Does it have a bus factor of 1 (single maintainer with no succession plan)?

---

### 3. Adoption & Reputation

- What are the weekly download numbers (npm, PyPI, Maven Central)?
- What's the GitHub star count and fork count (relative to the category — a niche tool with 500 stars may be fine)?
- Is it used by recognisable projects or companies?
- Is it recommended by the framework or language community?
- Are there well-known alternatives and, if so, why is this one preferred?

---

### 4. Fitness for Purpose

- Does this library do what's needed with the minimum attack surface?
- Are unused features (and their dependencies) excluded?
- Is the API stable, or is it frequently making breaking changes?
- Is the documentation complete enough to use securely?
- Does it handle error cases appropriately, or does it swallow exceptions silently?

---

### 5. Licensing — HARD REQUIREMENT

Verify the license before any adoption. **Libraries with copy-left licenses that affect the end product MUST NOT be used.**

| License | Status | Notes |
|---------|--------|-------|
| MIT | ✅ Approved | No restrictions on use |
| Apache 2.0 | ✅ Approved | Requires attribution and notice |
| BSD 2/3-Clause | ✅ Approved | Permissive |
| ISC | ✅ Approved | Equivalent to MIT |
| LGPL 2.1/3 | ⚠️ Review | OK if linked dynamically; may require open-sourcing if statically linked or modified. Get legal sign-off. |
| GPL 2/3 | ❌ Blocked | Copy-left propagates to the entire product |
| AGPL | ❌ Blocked | Copy-left extends to network use — highly restrictive |
| Commons Clause | ❌ Blocked | Restricts commercial use |
| SSPL | ❌ Blocked | Highly restrictive, used by MongoDB |
| Proprietary / Commercial | ⚠️ Review | Requires explicit licence agreement and commercial terms review |

**Action**: Check the `LICENSE` file in the repository, not just the package metadata (they can differ). If transitive dependencies introduce copy-left licences, flag them.

Tools to check: `license-checker` (npm), `pip-licenses` (Python), `license-maven-plugin` (Java).

---

## Evaluation Summary Template

Use this when reporting a dependency evaluation in the threat report:

```
### Dependency: [package-name@version]
**Purpose**: Why this library is being considered

| Criterion | Status | Notes |
|-----------|--------|-------|
| Open CVEs | ✅/⚠️/❌ | [detail] |
| Vuln history | ✅/⚠️/❌ | [detail] |
| Last release | ✅/⚠️/❌ | [date] |
| Maintainer activity | ✅/⚠️/❌ | [detail] |
| Adoption | ✅/⚠️/❌ | [download stats, stars] |
| Fitness | ✅/⚠️/❌ | [detail] |
| License | ✅/⚠️/❌ | [license name] |

**Recommendation**: Adopt / Adopt with conditions / Do not adopt
**Reason**: [one sentence summary]
```

---

## JavaScript/TypeScript-Specific Risk Patterns

When evaluating npm packages, check for these attack classes beyond what CVE databases cover:

**Prototype Pollution**
JavaScript's prototypal inheritance means that if a library lets user-controlled keys reach `Object.prototype` (e.g., via `obj[key] = value` where `key` can be `__proto__`), an attacker can corrupt shared state across the application. This affects many utility libraries that do deep merging, cloning, or path-based property access (lodash `_.merge`, `_.set`, `_.unset`; jQuery `$.extend`; etc.).

- Check the library's CVE history for "prototype pollution"
- Even if patched, verify the version being pinned includes the fix
- When using utility libraries with user-supplied paths or keys, validate inputs before passing them

**Template String Injection (RCE)**
Libraries that compile template strings at runtime (lodash `_.template`, handlebars, pug, etc.) can execute arbitrary code if templates are constructed from user input. This is equivalent to `eval()`.

- Check whether the library exposes a template/compile function
- Ensure it is never called with user-controlled strings in production code

**Unsafe Deserialisation**
Any library that deserialises binary or JSON data in a way that can invoke code (Java serialisation, Python pickle, node-serialize IIFE pattern) is a critical risk when processing untrusted input.

**Supply Chain / Typosquatting**
Verify the exact package name on the registry. Search for similarly-named packages with higher download counts that could be the legitimate package. Check whether the package has recently changed ownership.

---

## Dependency Update Strategy

Even approved dependencies become risks over time. Flag if the project lacks:
- Automated dependency scanning (Dependabot, Renovate, Snyk)
- A policy for applying security patches (should be within 2 weeks for High/Critical)
- A regular update cadence (major version upgrades should happen at least annually)

Lock files (`package-lock.json`, `poetry.lock`, `Pipfile.lock`, `pom.xml` with exact versions) are required to prevent supply chain attacks via version floating.
