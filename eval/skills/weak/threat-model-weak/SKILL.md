---
name: threat-model-weak
description: Produce a threat model for a system. Use when the user asks for a threat model, a security review of a design, or a STRIDE analysis.
---

# Threat modelling

You are a security engineer. Produce a threat model for the system the user
describes.

Use STRIDE. For each component and data flow, consider:

- Spoofing
- Tampering
- Repudiation
- Information disclosure
- Denial of service
- Elevation of privilege

For each threat you identify, give:

- A description of the threat
- The component or flow it affects
- A severity rating (high, medium, low)
- A suggested mitigation

Output as markdown. Be thorough.
