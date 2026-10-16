#!/usr/bin/env python3
"""Lint Mermaid code fences in markdown for the render-safe rules in references/house-style.md §5.

Usage:  python3 scripts/check_mermaid.py FILE.md [FILE2.md ...]
Exit 1 if any violation is found. Run this on every deliverable before shipping.
"""
import re, sys

BANNED_FLOW = {';': 'semicolon', '(': 'parenthesis', ')': 'parenthesis',
               '→': 'arrow glyph', '←': 'arrow glyph', '⇒': 'arrow glyph',
               '·': 'middle-dot', '⚠': 'warning glyph', '①': 'circled number',
               '②': 'circled number', '③': 'circled number', '④': 'circled number', '⑤': 'circled number'}
EMOJI_VS = re.compile(r'[\u2600-\u27BF]\uFE0F|\U0001F300-\U0001FAFF')

def fences(text):
    for m in re.finditer(r'```mermaid\s*\n(.*?)```', text, re.S):
        yield text[:m.start()].count('\n') + 2, m.group(1)

def strip_quoted(s):
    return re.sub(r'"[^"]*"', '""', s)

def check_flowchart(lines, base, out):
    for i, raw in enumerate(lines):
        line = raw.strip()
        if not line or line.startswith('%%') or line.startswith('classDef') or line.startswith('class ') or line.startswith('style'):
            continue
        if line.startswith('subgraph'):
            # quoted titles are safe; unquoted titles follow node-label rules
            if '"' in line:
                continue
        # remove shape delimiters that are syntax, not label text: [( )] and ([ ])
        s = line.replace('[(', '[').replace(')]', ']').replace('([', '[').replace('])', ']')
        s = strip_quoted(s)
        for ch, name in BANNED_FLOW.items():
            if ch in s:
                out.append(f'line {base+i}: {name} {ch!r} in flowchart label/edge -> {raw.strip()}')
        if EMOJI_VS.search(s):
            out.append(f'line {base+i}: variation-selector emoji in flowchart -> {raw.strip()}')
        if '&' in s and '-->' in s and s.count('-->') > 1:
            out.append(f'line {base+i}: & multi-target combined with chaining -> {raw.strip()}')

def check_sequence(lines, base, out):
    for i, raw in enumerate(lines):
        line = raw.strip()
        if ';' in strip_quoted(line):
            out.append(f'line {base+i}: semicolon in sequence diagram -> {raw.strip()}')

def check_er(lines, base, out):
    for i, raw in enumerate(lines):
        line = raw.strip()
        m = re.match(r'^\s*[A-Za-z_]+\s+[A-Za-z_]+\s+[A-Za-z_]+\s+[A-Za-z_]+', raw)
        if m and '{' not in line and '}' not in line and '"' not in line and not re.search(r'\|\||o\{|\}o|\|o|o\|', line):
            out.append(f'line {base+i}: attribute name with spaces in erDiagram -> {raw.strip()}')
        if re.search(r':\s*[^"]*\(', line) and re.search(r'\|\||o\{|\}o|\|o|o\|', line):
            out.append(f'line {base+i}: parenthesis in erDiagram relationship label -> {raw.strip()}')

def main(paths):
    problems = []
    for p in paths:
        text = open(p, encoding='utf-8').read()
        for base, body in fences(text):
            lines = body.split('\n')
            head = lines[0].strip().lower() if lines else ''
            if head.startswith(('flowchart', 'graph')):
                check_flowchart(lines[1:], base + 1, problems)
            elif head.startswith('sequencediagram'):
                check_sequence(lines[1:], base + 1, problems)
            elif head.startswith('erdiagram'):
                check_er(lines[1:], base + 1, problems)
            else:
                problems.append(f'line {base}: unrecognised diagram type "{lines[0].strip()}" — check manually')
        if problems:
            print(f'{p}:')
            for x in problems: print('  ' + x)
    if problems:
        print(f'\n{len(problems)} Mermaid render-safety violation(s). Fix before shipping (house style §5).')
        return 1
    print('Mermaid: no render-safety violations found.')
    return 0

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(2)
    sys.exit(main(sys.argv[1:]))
