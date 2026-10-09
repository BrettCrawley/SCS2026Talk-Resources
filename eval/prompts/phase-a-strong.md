# Strong pipeline prompt

The full chain. Context first, threat model last. This is the prompt to show attendees.

---

Perform a full, in-depth security analysis and threat model of ./input. Use the /secure-privacy-by-design, /security-architect and /threat-modeling skills together.  
Sources: 
 - the confluence design documents that were extracted and saved in ./input.
 - the Jira PMO and PMI tickets that were extracted and saved in ./input follow children to get a complete picture.
 - the git repositories that were extracted and saved in ./input as support/reference material.

Read all docs and source-code, terraform and helm charts may contain organizational controls. Where a repository is present, use it as supporting material and report any place where the implementation and the documentation disagree.

Record existing mitigations against each threat with the relevant ticket id if there are any and set the status to (mitigated/partially mitigated/planned) rather than dropping mitigated threats. Produce the security review, use/abuse/security/privacy-use-case, security architecture document, gap analysis, Security Requirements Traceability Matrix SRTM with Test Artefact Definitions/Descriptions (Not code) and threat model in markdown, in the house style, with render-safe Mermaid diagrams and examples threats and example mitigations in the findings. 

Use Brett Crawley, Principal Application Security Engineer for the attribution section and record session participants. Run on a high-capability model.

State explicitly what context you were given and what you were not given, and list what you would need to answer the questions you could not.

Write the documents into ./output as markdown files.
