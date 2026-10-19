#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Brett Crawley
"""Grade eval outputs against assertions using text search."""
import json
import re
import os

def read_file(path):
    if not os.path.exists(path):
        return None
    with open(path) as f:
        return f.read().lower()

def check_assertion(name, content):
    """Returns (passed, evidence)"""
    if content is None:
        return False, "File not found"

    # Pre-compute counts to avoid backslash-in-fstring issues
    st_count = len(re.findall(r'st-0\d\d', content))
    pt_count = len(re.findall(r'pt-0\d\d', content))
    sac_count = len(re.findall(r'sac-0\d\d', content))
    pac_count = len(re.findall(r'pac-0\d\d', content))
    ta_count = len(re.findall(r'ta-0\d\d', content))
    suc_count = len(re.findall(r'suc-0\d\d', content))
    puc_count = len(re.findall(r'puc-0\d\d', content))

    checks = {
        # Eval 0 - SaaS task app
        "contains-srtm-table": (
            bool(re.search(r'\|\s*req\s*id', content)) or 'srtm' in content or '| req id' in content,
            "Searching for SRTM table (| Req ID header)"
        ),
        "contains-stride-analysis": (
            st_count >= 3,
            "Found ST-0XX IDs: " + str(st_count)
        ),
        "contains-linddun-analysis": (
            pt_count >= 1,
            "Found PT-0XX IDs: " + str(pt_count)
        ),
        "contains-security-abuse-cases": (
            sac_count >= 1,
            "Found SAC-0XX IDs: " + str(sac_count)
        ),
        "contains-privacy-abuse-cases": (
            pac_count >= 1,
            "Found PAC-0XX IDs: " + str(pac_count)
        ),
        "contains-new-requirements": (
            '[new]' in content or 'new —' in content or '[new -' in content or 'new:' in content,
            "Searching for [NEW] requirement markers"
        ),
        "contains-test-artifacts": (
            ta_count >= 1,
            "Found TA-0XX IDs: " + str(ta_count)
        ),
        "contains-counter-use-cases": (
            suc_count >= 1 and puc_count >= 1,
            "SUC IDs: " + str(suc_count) + ", PUC IDs: " + str(puc_count)
        ),
        # Eval 1 - Healthcare
        "references-gdpr-special-category": (
            'article 9' in content or 'art. 9' in content or 'art.9' in content or 'special category' in content,
            "Searching for GDPR Art. 9 or 'special category'"
        ),
        "identifies-fhir-api-threat": (
            'fhir' in content and ('threat' in content or 'st-0' in content or 'attack' in content or 'abuse' in content),
            "Searching for FHIR-related threat/abuse content"
        ),
        "identifies-cross-patient-access-risk": (
            'cross-patient' in content or 'idor' in content or 'insecure direct object' in content or
            ('another patient' in content and ('access' in content or 'view' in content)),
            "Searching for IDOR or cross-patient access risk"
        ),
        "contains-notification-privacy-risk": (
            ('sms' in content or 'email' in content) and 'notification' in content and
            ('privacy' in content or 'disclosure' in content or 'health' in content),
            "Searching for notification channel privacy risk"
        ),
        "references-nhs-or-uk-standards": (
            'nhs' in content or 'nhs digital' in content or 'dspt' in content or 'nhs ig' in content,
            "Searching for NHS or UK-specific standards reference"
        ),
        # Eval 2 - P2P marketplace
        "identifies-location-privacy-risk": (
            'location' in content and ('privacy' in content or 'dox' in content or 'profil' in content or 'identif' in content),
            "Searching for location privacy risk"
        ),
        "identifies-stripe-webhook-security": (
            'stripe' in content and ('webhook' in content or 'signature' in content or 'payment' in content),
            "Searching for Stripe webhook/payment security"
        ),
        "identifies-xss-or-ugc-risk": (
            'xss' in content or 'cross-site scripting' in content or
            ('user-generated' in content and ('inject' in content or 'script' in content)),
            "Searching for XSS or user-generated content injection risk"
        ),
        "calibrated-to-mvp-scope": (
            ('priorit' in content or 'focus' in content or 'mvp' in content or 'highest' in content) and
            st_count <= 20,
            "Priority/focus language present and ST count is: " + str(st_count)
        ),
    }

    if name not in checks:
        return False, "Unknown assertion: " + name

    passed, evidence = checks[name]
    return bool(passed), evidence


def grade_run(eval_id, eval_name, assertions, output_path, run_type):
    content = read_file(output_path)
    results = []
    for assertion in assertions:
        name = assertion["name"]
        description = assertion["description"]
        passed, evidence = check_assertion(name, content)
        results.append({
            "text": description,
            "passed": passed,
            "evidence": evidence
        })

    total = len(results)
    passes = sum(1 for r in results if r["passed"])
    grading = {
        "eval_id": eval_id,
        "eval_name": eval_name,
        "run_type": run_type,
        "output_file": output_path,
        "expectations": results,
        "pass_count": passes,
        "total_count": total,
        "pass_rate": round(passes / total, 3) if total else 0
    }
    return grading


WORKSPACE = "/sessions/focused-dazzling-meitner/secure-privacy-by-design-workspace"

with open(os.path.join(WORKSPACE, "evals", "evals.json")) as f:
    evals_data = json.load(f)

runs = [
    (0, "saas-task-app", "with_skill",
     os.path.join(WORKSPACE, "iteration-1/eval-0-saas-task-app/with_skill/outputs/saas-task-app-security-privacy-analysis.md")),
    (0, "saas-task-app", "without_skill",
     os.path.join(WORKSPACE, "iteration-1/eval-0-saas-task-app/without_skill/outputs/saas-task-app-security-privacy-analysis.md")),
    (1, "healthcare-prescriptions", "with_skill",
     os.path.join(WORKSPACE, "iteration-1/eval-1-healthcare-prescriptions/with_skill/outputs/healthcare-prescriptions-security-privacy-analysis.md")),
    (1, "healthcare-prescriptions", "without_skill",
     os.path.join(WORKSPACE, "iteration-1/eval-1-healthcare-prescriptions/without_skill/outputs/healthcare-prescriptions-security-privacy-analysis.md")),
    (2, "p2p-marketplace", "with_skill",
     os.path.join(WORKSPACE, "iteration-1/eval-2-p2p-marketplace/with_skill/outputs/p2p-marketplace-security-privacy-analysis.md")),
    (2, "p2p-marketplace", "without_skill",
     os.path.join(WORKSPACE, "iteration-1/eval-2-p2p-marketplace/without_skill/outputs/p2p-marketplace-security-privacy-analysis.md")),
]

for eval_id, eval_name, run_type, output_path in runs:
    eval_def = next(e for e in evals_data["evals"] if e["id"] == eval_id)
    assertions = eval_def["assertions"]

    grading = grade_run(eval_id, eval_name, assertions, output_path, run_type)

    out_dir = os.path.join(WORKSPACE, "iteration-1", "eval-" + str(eval_id) + "-" + eval_name, run_type)
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "grading.json"), "w") as f:
        json.dump(grading, f, indent=2)

    rate = grading["pass_rate"]
    status = "OK" if rate == 1.0 else ("PARTIAL" if rate >= 0.5 else "FAIL")
    print(status + " eval-" + str(eval_id) + " (" + eval_name + ") [" + run_type + "]: " +
          str(grading["pass_count"]) + "/" + str(grading["total_count"]) + " passed (" +
          str(round(rate * 100)) + "%)")
    for r in grading["expectations"]:
        mark = "  PASS" if r["passed"] else "  FAIL"
        print(mark + " " + r["text"])
        if not r["passed"]:
            print("       Evidence: " + r["evidence"])
    print()

print("Grading complete.")
