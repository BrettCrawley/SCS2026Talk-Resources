#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Brett Crawley
"""Make the skill's reference material available INSIDE the current working directory.

Usage:  python3 <skill>/scripts/fetch_references.py [DEST]     (DEST default: ./.threat-modeling-refs)

Run this when the skill's own `references/` directory cannot be read from the session (it sits
outside the permitted working directory, a read was denied, or a tool reports it missing).
It (1) copies the skill's references/ and templates/ into DEST if they are readable, and
(2) fetches the upstream sources from GitHub as a fallback / supplement:
  - Elevation of Autonomy deck, companion guide, runbook  (BrettCrawley/elevation-of-autonomy)
  - MITRE ATLAS data                                        (mitre-atlas/atlas-data)
Prints what it obtained and what it could not. Never proceed with the analysis on a partial set:
if this script cannot obtain the references, stop and ask the user (see SKILL.md).
"""
import os, sys, shutil, subprocess, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = os.path.dirname(HERE)
DEST = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.getcwd(), '.threat-modeling-refs')
RAW = 'https://raw.githubusercontent.com'
UPSTREAM = {
    'eoa/elevation-of-autonomy-print-and-play.md': f'{RAW}/BrettCrawley/elevation-of-autonomy/main/elevation-of-autonomy-print-and-play.md',
    'eoa/elevation-of-autonomy-companion-guide.md': f'{RAW}/BrettCrawley/elevation-of-autonomy/main/elevation-of-autonomy-companion-guide.md',
    'eoa/ai-threat-modelling-runbook.md': f'{RAW}/BrettCrawley/elevation-of-autonomy/main/ai-threat-modelling-runbook.md',
    'eoa/threat-modelling-ai-llm-agentic.md': f'{RAW}/BrettCrawley/elevation-of-autonomy/main/threat-modelling-ai-llm-agentic.md',
    'atlas/ATLAS-latest.yaml': f'{RAW}/mitre-atlas/atlas-data/main/dist/ATLAS-latest.yaml',
}
ok, missing = [], []
os.makedirs(DEST, exist_ok=True)

src = os.path.join(SKILL, 'references')
try:
    if os.path.isdir(src):
        shutil.copytree(src, os.path.join(DEST, 'references'), dirs_exist_ok=True)
        ok.append('skill references/ (copied)')
    else:
        missing.append(f'skill references/ not readable at {src}')
except Exception as e:
    missing.append(f'skill references/ copy failed: {e}')

for rel, url in UPSTREAM.items():
    out = os.path.join(DEST, rel); os.makedirs(os.path.dirname(out), exist_ok=True)
    try:
        urllib.request.urlretrieve(url, out); ok.append(rel)
    except Exception as e:
        missing.append(f'{rel} ({e.__class__.__name__})')

print(f'Reference material in: {DEST}')
for o in ok: print('  OK      ' + o)
for m in missing: print('  MISSING ' + m)
if not any('references/' in o for o in ok):
    print('\nThe skill references are still not available. Ask the user to grant read access to the skill '
          'directory (Claude Code: /add-dir <skill path>, or approve the read prompt) before continuing. '
          'Do not run a partial analysis and note it as a limitation.')
    sys.exit(1)
print('\nRead from this directory for the rest of the session.')
