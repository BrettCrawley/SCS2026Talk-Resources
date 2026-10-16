#!/usr/bin/env python3
"""Lint a produced deliverable against references/house-style.md §1–§3 and §7, and
references/templates/threat-model-template.md.

Usage:  python3 scripts/check_deliverable.py DELIVERABLE.md [--type threat-model|srtm]
Exit 1 on any FAIL. A deliverable is not finished until this exits 0.

Checks: title form, mandatory attribution block (Prepared by + skill-author credit + AI
assistance), Version/Date/Method lines, forbidden header labels, the unified status legend,
delta section only when superseding, no invented session/participant claims in the header,
§2a section presence and order, canonical finding IDs, example lines that are only
cross-references, risk-register columns, Mermaid render safety (delegates to check_mermaid.py).
"""
import re, sys, os, subprocess

FAIL, WARN = [], []
def fail(m): FAIL.append(m)
def warn(m): WARN.append(m)

SKILL_AUTHOR = 'Brett Crawley, Principal Application Security Engineer'
LEGEND = ['Open', 'Partial / In progress', 'Planned', 'Mitigated / Live', 'Accepted']
LEGEND_BANNED = ['Partially mitigated', 'Not assessable', 'Not applicable', 'Deferred', 'Closed', 'Resolved']
HEADER_BANNED = {
    r'\*\*Author:\*\*': 'use "**Prepared by:**" with title and the attribution sentence (house style §1)',
    r'\*\*Document:\*\*': 'not house style; use **Companion:** to name sibling documents by filename (§1a)',
    r'\*\*Session participants:\*\*': 'participants and validation sessions go in Appendix G (§4), and only if a session actually happened',
    r'\*\*Reviewers?:\*\*': 'use **Prepared by:**',
}
SECTIONS = [  # (regex on heading text, required, human name)
    (r'context\s*&\s*scope|context and scope', True, 'Context & Scope'),
    (r'attack surface', True, 'Attack Surface Summary'),
    (r'existing organi[sz]ational controls', False, 'Existing Organisational Controls'),
    (r'striped analysis', True, 'STRIPED Analysis'),
    (r'additional threat surfaces', True, 'Additional Threat Surfaces'),
    (r'recovery\s*&\s*resilience|third-party dependencies|human-centered security', True, 'Recovery & Resilience / Dependencies / HCS'),
    (r'compliance summary', True, 'Compliance Summary'),
    (r'design flaw summary', True, 'Design Flaw Summary'),
    (r'risk register', True, 'Risk Register'),
    (r'merge reconciliation', False, 'Merge Reconciliation'),
    (r'assumptions', True, 'Assumptions & Limitations'),
    (r'appendi', True, 'Appendices'),
]
ID_RE = re.compile(r'^#{3,4}\s+((?:S|T|R|I|P|D|E|O|AI|CL|C|RR)\d+)\s+[—-]', re.M)
BAD_ID_RE = re.compile(r'^#{3,4}\s+((?:TM|F|V|TH|RISK|FIND|SEC|SAC)-?\d+)\b', re.M | re.I)
REG_COLS_EXT = ['ID', 'Threat', 'Category', 'Ref', 'Severity', 'Likelihood', 'Compliance', 'Mitigation', 'Status']
REG_COLS_INT = ['ID', 'Threat', 'Severity', 'Likelihood', 'Baseline', 'Compliance', 'ref', 'Mitigation', 'Jira', 'Status']

def header_block(text):
    # everything before the first '---' rule or first '## ' heading, whichever comes first
    m = re.search(r'^(---\s*$|## )', text, re.M)
    return text[:m.start()] if m else text[:3000]

def check_header(text):
    h = header_block(text)
    title = re.search(r'^#\s+(.*)$', text, re.M)
    if not title:
        fail('no H1 title')
    else:
        t = title.group(1).strip()
        if not re.search(r'—\s*(threat model|security review|gap analysis|security architecture|srtm)', t, re.I):
            fail(f'title "{t}" — must be "[System Name] — Threat Model" (template header); a bare "Threat Model" is not a title')
    if '**Prepared by:**' not in h:
        fail('missing "**Prepared by:**" line (house style §1)')
    else:
        pb = h[h.index('**Prepared by:**'):]
        pb = pb.split('\n**', 1)[0]
        if SKILL_AUTHOR not in pb:
            fail(f'attribution must credit the skill author verbatim: "{SKILL_AUTHOR}" (§1 part 2 — fixed even when someone else runs the review)')
        if not re.search(r'produced with AI assistance', pb, re.I):
            fail('attribution must state "Produced with AI assistance" and name the model (§1)')
        if not re.search(r'author of this', pb, re.I):
            fail('Prepared by line must say "author of this <document type>" (§1 template)')
        if re.search(r'security-review skill set authored by', pb, re.I) is None and pb.count(SKILL_AUTHOR) == 1 and 'facilitator' not in pb:
            warn('Prepared by line does not follow either §1 template wording closely — check it')
    for k in ('**Version:**', '**Date:**', '**Method:**'):
        if k not in h: fail(f'missing {k} in header (§1)')
    body_pre_appendix = re.split(r'^##\s+.*appendi', text, flags=re.M | re.I)[0]
    for pat, why in HEADER_BANNED.items():
        scope = body_pre_appendix if 'Session' in pat else h
        if re.search(pat, scope, re.I):
            label = pat.replace('\\*\\*', '').replace('\\', '')
            fail(f'uses "{label}" — {why}')
    # legend
    if 'Status legend' not in text:
        fail('missing "Status legend:" line (§3 unified legend)')
    else:
        leg = text[text.index('Status legend'):].split('\n', 1)[0]
        for w in LEGEND:
            if w not in leg: fail(f'status legend missing "{w}" — legend must be exactly: 🔴 Open · 🟡 Partial / In progress (issue cited) · 🔵 Planned · 🟢 Mitigated / Live · ⚪ Accepted')
        for w in LEGEND_BANNED:
            if w in leg: fail(f'status legend contains non-canonical state "{w}" (§3 — do not invent states)')
    # delta only when superseding
    has_delta = re.search(r'^##\s+.*(what changed|delta from|version history|change log)', text, re.M | re.I)
    if has_delta and '**Supersedes:**' not in h:
        fail('"What changed / Delta" section present but no **Supersedes:** in header — §2a item 1 applies only when this replaces an earlier pass; for a first version delete the section (and "No prior version exists" is the tell)')
    if re.search(r'no prior version', text, re.I) and has_delta:
        fail('delta section states there is no prior version — delete the section')
    # invented sessions
    if re.search(r'sole analyst|desk review', h, re.I):
        fail('header claims a desk review / sole analyst — do not narrate the review process in the header; if no validation session occurred, say so once in Assumptions & Limitations and omit "facilitator of the validation session" from the attribution')
    if re.search(r'facilitator of the .*validation session', h, re.I) and re.search(r'no .*(session|representative) .*(available|held|occurred)', text, re.I):
        fail('attribution claims facilitation of a validation session while the document says none was held — remove the claim (§1: cite only what actually happened)')

def check_sections(text):
    heads = [(m.start(), m.group(1).strip()) for m in re.finditer(r'^##\s+(.*)$', text, re.M)]
    pos = []
    for pat, req, name in SECTIONS:
        found = [p for p, h in heads if re.search(pat, h, re.I)]
        if not found:
            (fail if req else warn)(f'section missing: "{name}" (§2a; required sections may only be present as one-line "not applicable — reason")')
            pos.append(None)
        else:
            pos.append(found[0])
    seq = [p for p in pos if p is not None]
    if seq != sorted(seq):
        fail('sections are out of house-style §2a order — use the template numbering')
    for letter in ['Spoofing', 'Tampering', 'Repudiation', 'Information Disclosure', 'Privacy', 'Denial of Service', 'Elevation of Privilege']:
        if not re.search(r'^###\s+' + letter, text, re.M | re.I):
            fail(f'STRIPED subsection "### {letter}" missing (§2a item 5 — keep it with a one-line n/a if empty)')

def check_findings(text):
    ids = ID_RE.findall(text)
    bad = BAD_ID_RE.findall(text)
    if bad: fail(f'non-canonical finding IDs: {sorted(set(bad))[:6]} — use STRIPED letter or O/AI/CL/C/RR bucket + sequence (§3)')
    if not ids: fail('no findings found with canonical IDs (#### S1 — Title — **Severity**)')
    # prompt injection must be AI bucket
    for m in re.finditer(r'^#{3,4}\s+(T\d+)\s+[—-]\s+(.*prompt injection.*)$', text, re.M | re.I):
        fail(f'{m.group(1)} "{m.group(2)[:40]}" — prompt-injection findings are AI-bucket (AI1…), not T (§3)')
    # per-finding example lines
    blocks = re.split(r'^#{3,4}\s+(?=(?:S|T|R|I|P|D|E|O|AI|CL|C|RR)\d+\s)', text, flags=re.M)[1:]
    for b in blocks:
        fid = b.split()[0]
        for label in ('Example threat', 'Example mitigation'):
            m = re.search(r'\*\*' + label + r'\.?\*\*:?\s*(.*)', b)
            if not m:
                fail(f'{fid}: missing **{label}** line (§7)'); continue
            body = m.group(1).strip()
            words = re.findall(r'[A-Za-z]{3,}', re.sub(r'`[^`]*`', '', body))
            refs = re.findall(r'\b(?:SAC|SEC|SUC|TA|UC|REQ|SR)-?\d+', body)
            if re.match(r'^(see|refer to|as per|per)\b', body, re.I) or (refs and len(words) < 12):
                fail(f'{fid}: **{label}** is a cross-reference ("{body[:60]}…") — write the example inline; IDs go on a **Refs.** line (§7)')
            elif label == 'Example threat' and len(body.split('.')) < 2 + (1 if body.endswith('.') else 0) and len(words) < 25:
                fail(f'{fid}: **Example threat** too thin ("{body[:60]}…") — attacker, entry point, system response, consequence; two or more sentences (§7)')
            elif label == 'Example mitigation' and len(words) < 10 and '`' not in body and '```' not in b:
                fail(f'{fid}: **Example mitigation** too thin ("{body[:60]}…") — actual control, where it sits, what it checks (§7)')
        if not re.search(r'\*\*Refs?\.?\*\*', b):
            warn(f'{fid}: no **Refs.** line (SAC/SEC/TA/issue cross-references belong there)')

def check_register(text):
    m = re.search(r'^##\s+.*risk register.*$', text, re.M | re.I)
    if not m: return
    seg = text[m.end():]
    hdr = re.search(r'^\|(.+)\|\s*$', seg, re.M)
    if not hdr: fail('risk register has no table'); return
    cols = [c.strip() for c in hdr.group(1).split('|')]
    ext = all(any(c.lower().startswith(x.lower()) for c in cols) for x in REG_COLS_EXT)
    intl = all(any(x.lower() in c.lower() for c in cols) for x in REG_COLS_INT)
    if not (ext or intl):
        fail(f'risk-register columns {cols} match neither the internal nor the right-sized set (§3)')
    rows = re.findall(r'^\|\s*\**([A-Z]{1,2}\d+)\**\s*\|.*$', seg, re.M)
    for r in re.finditer(r'^\|.*🟡.*$', seg, re.M):
        if not re.search(r'#\d+|[A-Z]+-\d+|jira|issue', r.group(0), re.I):
            fail(f'🟡 status without a tracking issue cited inline (§3): {r.group(0)[:80]}')
    for r in re.finditer(r'^\|.*(In progress|Partially|Not assessable).*$', seg, re.M):
        fail(f'register uses non-canonical status wording: {r.group(0)[:80]}')
    ids_in_doc = set(ID_RE.findall(text))
    missing = [i for i in ids_in_doc if i not in set(rows)]
    if missing: fail(f'findings not in the risk register: {sorted(missing)}')


SEVERITIES = ['Critical', 'High', 'Medium', 'Low', 'Info']
WEASEL = [r'could potentially', r'may be vulnerable', r'it is recommended', r'consider implementing',
          r'should be considered', r'an attacker could exploit this', r'follow(?:ing)? best practices?',
          r'appropriate (?:controls|measures)', r'ensure that .{0,30} is secure', r'where appropriate', r'as needed']
NON_DETERMINISTIC = [r'\bmodel (?:will|should|can|is expected to) (?:refuse|reject|decline|ignore|detect|recogni[sz]e)',
                     r'\b(?:llm|assistant|agent) (?:will|should) (?:refuse|ignore|detect|not follow)',
                     r'\bclassifier (?:will|should) (?:detect|catch|flag)', r'\bguardrails? (?:will|should) (?:block|catch|prevent)',
                     r'\binstruct(?:ing)? the (?:model|llm|agent) (?:to|not to)', r'\bsystem prompt (?:tells|instructs|forbids|prohibits)',
                     r'\bprompt(?:-| )hardening\b', r'\btell the model\b']
COMPLIANCE = ['GDPR', 'NIS2', 'CRA', 'PSTI', 'PCI', 'HIPAA', 'SOC 2']

def sections(text):
    """[(level, heading, body_start, body_end)] for ## and ### headings."""
    hs = [(len(m.group(1)), m.group(2).strip(), m.start(), m.end()) for m in re.finditer(r'^(#{2,3})\s+(.*)$', text, re.M)]
    out = []
    for i, (lvl, h, st, en) in enumerate(hs):
        nxt = text.find('\n#', en)
        out.append((lvl, h, en, nxt if nxt != -1 else len(text)))
    return out

def sec_body(text, pat):
    m = re.search(r'^##\s+.*(?:' + pat + r').*$', text, re.M | re.I)
    if not m: return ''
    nxt = re.search(r'^##\s', text[m.end():], re.M)
    return text[m.end(): m.end() + nxt.start()] if nxt else text[m.end():]

def check_content(text):
    # 1. template residue
    for pat, why in [(r'<!--', 'template guidance comment left in'), (r'\[(?:System Name|Reviewer name|placeholder|YYYY|n\.n|\.\.\.|one[- ]line|Finding title|Severity\]|Client contact|Worry|ID\]|emoji\])', 'template placeholder left in'),
                     (r'\b(?:TODO|TBD|FIXME|XXX|lorem ipsum)\b', 'unfinished marker')]:
        for m in re.finditer(pat, text, re.I):
            fail(f'{why} at line {text[:m.start()].count(chr(10))+1}: {text[m.start():m.start()+50].strip()!r}')
    h = header_block(text)
    # model line: mandatory, structured, family + version (e.g. "Claude Fable 5.1", "Claude Opus 5", "GPT-5")
    ml = re.search(r'\*\*Model:\*\*\s*([^\n·|]+)', h)
    if not ml:
        fail('missing "**Model:**" header line naming the AI model used, family and version (e.g. "Claude Fable 5.1") — §1')
    else:
        mv = ml.group(1).strip()
        if not re.search(r'(?:Claude|GPT|Gemini|Llama|Mistral|Qwen|DeepSeek)[\w\s.-]*\d', mv, re.I):
            fail(f'Model "{mv}" — must name family and version (e.g. "Claude Fable 5.1", "Claude Opus 5"); a bare family name or "an LLM" is not a model')
        if re.search(r'\b(?:latest|current|various|unknown|n/?a)\b', mv, re.I):
            fail(f'Model "{mv}" — state the specific model actually used, not a placeholder')
    if re.search(r'AI assistance', h, re.I) and not ml:
        fail('attribution says "AI assistance" but the header has no **Model:** line')
    d = re.search(r'\*\*Date:\*\*\s*([^\s·|]+(?:\s+[^\s·|]+){0,2})', h)
    if d and not re.match(r'\d{4}-\d{2}-\d{2}', d.group(1)):
        fail(f'Date "{d.group(1).strip()}" — use ISO YYYY-MM-DD (template header)')
    # 2. empty / bare-n/a sections
    for lvl, head, a, b in sections(text):
        body = text[a:b].strip()
        if re.search(r'appendi', head, re.I): continue
        nxt = re.match(r'\s*(#{2,6})\s', text[b:b+10])
        if not body and nxt and len(nxt.group(1)) > lvl: continue  # parent whose content is its subsections
        if not body:
            fail(f'section "{head}" is empty — write it, or one line "not applicable — <reason>"')
        elif re.fullmatch(r'(?:n/?a|none|not applicable|nothing (?:found|identified))\.?', body, re.I):
            fail(f'section "{head}" is a bare "{body}" — a reason is required: "not applicable — <reason>"')
    # 3. finding headings: severity vocab, status emoji, tag line
    sev_of = {}
    for m in re.finditer(r'^#{3,4}\s+((?:S|T|R|I|P|D|E|O|AI|CL|C|RR)\d+)\s+[—-]\s+(.*)$', text, re.M):
        fid, rest = m.group(1), m.group(2)
        sv = re.search(r'\*\*(\w+)\*\*', rest)
        if not sv or sv.group(1) not in SEVERITIES:
            fail(f'{fid}: heading must end "— **<Severity>** <status emoji>" with Severity in {SEVERITIES}: "{rest[:60]}"')
        else:
            sev_of[fid] = sv.group(1)
        if not re.search(r'[🔴🟡🔵🟢⚪]', rest):
            fail(f'{fid}: no status emoji on the finding heading')
        nxt = text[m.end():m.end()+200].lstrip('\n').split('\n')[0]
        if not nxt.startswith('`['):
            fail(f'{fid}: line after the heading must be the tag line (`[STRIPED-X]` `[OWASP A0n]` …), got: "{nxt[:50]}"')
        if fid.startswith('AI'):
            blk = text[m.start(): text.find('\n#', m.end()) if text.find('\n#', m.end()) != -1 else len(text)]
            if 'AML.T' not in blk: fail(f'{fid}: AI finding without an ATLAS technique tag [ATLAS AML.Tnnnn] (ai-ml-atlas.md)')
            if not re.search(r'\[(?:LLM|ASI)\d\d\]', blk): fail(f'{fid}: AI finding without an OWASP LLM/ASI tag')
    ids = list(sev_of)
    dup = {i for i in ids if ids.count(i) > 1}
    if dup: fail(f'duplicate finding IDs: {sorted(dup)}')
    from collections import defaultdict
    byb = defaultdict(list)
    for i in ids: byb[re.match(r'[A-Z]+', i).group(0)].append(int(re.search(r'\d+', i).group(0)))
    for b, ns in byb.items():
        if sorted(ns) != list(range(1, len(ns)+1)): warn(f'{b} findings are not numbered 1..n without gaps: {sorted(ns)}')
    if 0 < len(ids) < 3: warn(f'only {len(ids)} findings — a real system rarely yields this few; check each STRIPED letter was actually walked')
    # 4. per-finding language
    for m in re.finditer(r'^#{3,4}\s+((?:S|T|R|I|P|D|E|O|AI|CL|C|RR)\d+)\s+[—-]', text, re.M):
        fid = m.group(1); end = text.find('\n#', m.end()); blk = text[m.start(): end if end != -1 else len(text)]
        mit = ' '.join(re.findall(r'\*\*(?:Example )?[Mm]itigation\.?\*\*:?\s*(.*)', blk))
        for p in NON_DETERMINISTIC:
            if re.search(p, mit, re.I):
                fail(f'{fid}: mitigation relies on model behaviour ("{re.search(p, mit, re.I).group(0)}") — Cox thesis: name the deterministic control outside the model; model behaviour is at most a backstop (ai-ml-threats.md §1.3)')
                break
        for p in WEASEL:
            w = re.search(p, blk, re.I)
            if w: fail(f'{fid}: vague wording "{w.group(0)}" — say the specific control/behaviour (§6 specific over generic)'); break
        iss = re.search(r'\*\*Issue\.?\*\*:?\s*(.*)', blk)
        if iss and not re.search(r'`|:\d+|#\d+|[A-Z]{2,}-\d+|\.(?:py|ts|js|go|java|yaml|yml|tf|json|md)\b|ADR|Confluence|design page|ticket|epic|story', iss.group(1), re.I):
            warn(f'{fid}: Issue line cites no evidence (file:line, ticket, ADR, doc name)')
    # 5. scope line vs surfaces
    scope = sec_body(text, r'context\s*&\s*scope')
    sl = re.search(r'\*\*Surfaces in scope:?\*\*:?\s*(.*)', scope, re.I)
    if not sl: fail('Context & Scope has no "**Surfaces in scope:**" line (STRIPED · AI/ML · Cloud · Containers)')
    else:
        v = sl.group(1)
        want = {'AI': re.search(r'AI', v) is not None, 'CL': re.search(r'cloud', v, re.I) is not None, 'C': re.search(r'container|kubernetes|k8s', v, re.I) is not None}
        surf = sec_body(text, r'additional threat surfaces')
        if want['AI']:
            EOA = ['SA','SK','SQ','SJ','S10','S9','HA','HK','HQ','HJ','H10','H9','DA','DK','DQ','DJ','D10','D9','CA','CK','CQ','CJ','C10','T7','T6','T5','T4','T3','T2','T1']
            cov = re.search(r'EoA elicitation coverage', surf, re.I)
            if not cov: fail('AI/ML in scope but no "EoA elicitation coverage" table — all 30 cards must be walked and recorded (template §6b)')
            else:
                tbl = surf[cov.start():]
                absent = [c for c in EOA if not re.search(r'^\|\s*EoA·' + re.escape(c) + r'\s*\|', tbl, re.M)]
                if absent: fail(f'EoA coverage table missing cards: {absent} — the pass is all 30, not a selection')
                for r in re.finditer(r'^\|\s*EoA·[A-Z0-9]+\s*\|[^|]*\|[^|]*\|\s*(?:\[?\.\.\.\]?)?\s*\|', tbl, re.M):
                    fail(f'EoA coverage row has an empty outcome: {r.group(0)[:50]} — a finding ID or "no exposure — reason"'); break
            if not re.search(r'AI/ML Threat Surface', surf, re.I): fail('AI/ML in scope but no "### 6b. AI/ML Threat Surface (AI)" subsection')
            if not re.search(r'ATLAS attack path', surf, re.I): fail('AI/ML in scope but no "ATLAS attack path" block (template §6b / ai-ml-atlas.md §7 step 3)')
            if not re.search(r'architectural split|cox', surf, re.I): fail('AI/ML in scope but no Cox-thesis "Architectural split" block (template §6b)')
            if not re.search(r'adversarial subspace|decision boundary|context rot', surf, re.I): fail('AI/ML in scope but the structural-hazards check (adversarial subspace, decision boundary transfer, context rot) is missing')
            if not byb.get('AI'): fail('AI/ML in scope but no AI-bucket findings')
        if want['CL'] and not re.search(r'Cloud Threat Surface', surf, re.I): fail('cloud in scope but no "### 6c. Cloud Threat Surface (CL)" subsection')
        if want['C']:
            if not re.search(r'Container', surf, re.I): fail('containers in scope but no "### 6d. Container & Orchestration Threat Surface (C)" subsection')
            elif sum(1 for w in ('image', 'registry', 'runtime', 'orchestrator') if re.search(w, surf, re.I)) < 4:
                fail('container section is not structured by layer (Image → Registry → Runtime → Orchestrator)')
            if not re.search(r'escape path|isolation boundary', surf, re.I): fail('container section missing the isolation-boundary / escape-path statements (template §6d)')
        for b, name in (('AI', 'AI/ML'), ('CL', 'Cloud'), ('C', 'Containers')):
            if byb.get(b) and not want[b]: warn(f'{b}-bucket findings exist but "{name}" is not in the Surfaces in scope line')
    # 6. attack surface tables
    asb = sec_body(text, r'attack surface')
    if asb and not re.search(r'\|\s*Confidence\s*\|', asb): fail('trust-boundary table missing the Confidence column (template §3.6)')
    if asb and not re.search(r'classification', asb, re.I): fail('Attack Surface Summary has no data classification & residency table (template §3.5)')
    if asb and '```mermaid' not in asb: warn('no Mermaid diagram in Attack Surface Summary — expected for design/architecture reviews (or reference the companion doc explicitly)')
    # 7. compliance coverage
    cb = sec_body(text, r'compliance summary')
    if cb:
        miss = [f for f in COMPLIANCE if not re.search(f.replace(' ', r'\s*'), cb, re.I)]
        if miss: fail(f'Compliance Summary does not assess {miss} — assess applicability explicitly, never silently skip (template §8)')
    # 8. design flaw summary references
    df = sec_body(text, r'design flaw summary')
    if df:
        refs = set(re.findall(r'\b((?:S|T|R|I|P|D|E|O|AI|CL|C|RR)\d+)\b', df))
        if not refs: fail('Design Flaw Summary references no finding IDs')
        bad = refs - set(ids)
        if bad: fail(f'Design Flaw Summary references non-existent findings: {sorted(bad)}')
    # 9. register cross-checks
    rb = sec_body(text, r'risk register')
    if rb:
        for r in re.finditer(r'^\|\s*\**([A-Z]{1,2}\d+)\**\s*\|(.*)$', rb, re.M):
            rid, row = r.group(1), r.group(2)
            if rid not in sev_of: fail(f'risk register row {rid} has no matching finding heading'); continue
            if sev_of[rid] not in row: fail(f'{rid}: severity in register does not match heading ({sev_of[rid]})')
        if not re.search(r'roll-?up', rb, re.I): warn('Risk Register has no "Roll-up:" line (counts by status and bucket)')
    # 10. tables: cell-count consistency; HTML in cells
    for m in re.finditer(r'(?:^\|.*\|\s*$\n?){2,}', text, re.M):
        rows = [r for r in m.group(0).strip().split('\n') if r.strip()]
        n = rows[0].count('|')
        for r in rows[1:]:
            if re.sub(r'`[^`]*`', '', r).count('|') != n:
                fail(f'table row has a different column count from its header (breaks rendering; unescaped | in a cell?): {r[:70]}'); break
    if re.search(r'<br\s*/?>|<td|<table', text, re.I): warn('raw HTML in tables — may not survive PDF export')
    # 11. heading level skips
    prev = 1
    for m in re.finditer(r'^(#{1,6})\s', text, re.M):
        l = len(m.group(1))
        if l > prev + 1: warn(f'heading level jumps from H{prev} to H{l} at line {text[:m.start()].count(chr(10))+1}')
        prev = l
    # 12a. references-unavailable excuses
    lim = sec_body(text, r'assumptions')
    if re.search(r'(reference|skill|deck|card)[^.\n]{0,80}(not (?:reachable|available|readable|accessible)|could not be (?:read|reached|loaded)|unavailable|outside (?:the|this) .{0,20}working directory)', lim + h, re.I):
        fail('document says the skill references / EoA deck were unavailable — that is not a limitation, it is an unfinished review: run scripts/fetch_references.py or obtain read access, then redo the affected passes (SKILL.md "Reference Material Is Mandatory")')
    if re.search(r'structured (?:substitute|equivalent|proxy)|substitute (?:for|covering) the (?:deck|cards)|same subject matter|could not be read in this session|deck (?:could not|was not|is not) (?:be )?(?:read|available|obtained)|no \[?EoA[^\]]*\]? (?:card )?tags have been|non-interactive', text, re.I):
        fail('document describes a substitute for the Elevation of Autonomy pass or claims the deck was unobtainable — the full deck is embedded in SKILL.md; walk all 30 cards and fill the coverage table')
    if re.search(r'only the (?:two|\d+) card tags|rather than a full elicitation|partial (?:EoA|elicitation) pass', text, re.I):
        fail('document admits a partial Elevation of Autonomy pass — walk all 30 cards; the deck is in references/elevation-of-autonomy.md')
    # 12. session claims vs appendix G
    if re.search(r'facilitator of the .*validation session', h, re.I) and not re.search(r'session validation log|appendix g', text, re.I):
        fail('attribution claims a validation session but there is no Appendix G session log (§4)')

def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if not args: print(__doc__); return 2
    path = args[0]
    text = open(path, encoding='utf-8').read()
    check_header(text); check_sections(text); check_findings(text); check_register(text); check_content(text)
    here = os.path.dirname(os.path.abspath(__file__))
    if '```mermaid' in text:
        r = subprocess.run([sys.executable, os.path.join(here, 'check_mermaid.py'), path], capture_output=True, text=True)
        if r.returncode != 0: fail('Mermaid render-safety violations:\n' + r.stdout.strip())
    for w in WARN: print('WARN  ' + w)
    for f in FAIL: print('FAIL  ' + f)
    print(f'\n{len(FAIL)} FAIL, {len(WARN)} WARN — {path}')
    if FAIL:
        print('The deliverable does not meet house style. Fix every FAIL above and re-run; do not hand this to the user until it exits 0.')
        return 1
    print('Deliverable passes house-style checks.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
