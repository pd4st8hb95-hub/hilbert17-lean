#!/usr/bin/env python3
"""Extract fresh acceptance type/axiom outputs and compare prior logs; never execute Lean."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

EXPECTED_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}
MODULES = ["FinalTargetContract", "BoundaryAcceptance"]


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def pin(path):
    path = Path(path).resolve(strict=True)
    return {"path": str(path), "bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def commands(source):
    checks, axioms = [], []
    for number, line in enumerate(Path(source).read_text().splitlines(), 1):
        if match := re.fullmatch(r"\s*#check\s+@?([A-Za-z0-9_.]+)\s*", line):
            checks.append({"line": number, "name": match.group(1)})
        if match := re.fullmatch(r"\s*#print\s+axioms\s+([A-Za-z0-9_.]+)\s*", line):
            axioms.append({"line": number, "name": match.group(1)})
    require(len(checks) == len(axioms) == 7, "Expected seven type and seven axiom checks per acceptance source")
    return checks, axioms


def info_blocks(log, module):
    text = Path(log).read_text()
    # Lean's Lake output prefixes one source position, followed by indented type
    # lines. Exclude inherited warnings, progress captions, and other modules.
    starts = list(re.finditer(r"^info:\s+[^\n]*?checks/" + re.escape(module) + r"\.lean:(\d+):\d+:\s?", text, re.M))
    blocks = {}
    for match in starts:
        tail = text[match.end():]
        boundary = re.search(r"^(?:info:|warning:|error:|[⚠ℹ✔✖]|Build completed|Some required builds logged)", tail, re.M)
        body = tail[:boundary.start()] if boundary else tail
        number = int(match.group(1))
        require(number not in blocks, "Duplicate acceptance output position")
        blocks[number] = body.strip()
    return blocks


def extract(log, module, expected_checks, expected_axioms):
    blocks = info_blocks(log, module)
    checks, axioms = [], []
    for expected in expected_checks:
        body = blocks.get(expected["line"], "")
        require(re.match(r"@?" + re.escape(expected["name"]) + r"(?:\.\{[^}]*\})?(?:\s|:)", body),
                "Missing/mismatched #check output: " + expected["name"])
        normalized = " ".join(body.split())
        checks.append({**expected, "type_text": body, "normalized_sha256": hashlib.sha256(normalized.encode()).hexdigest()})
    for expected in expected_axioms:
        body = blocks.get(expected["line"], "")
        match = re.fullmatch(r"'" + re.escape(expected["name"]) + r"' depends on axioms:\s*\[(.*?)\]", body, re.S)
        require(match is not None, "Missing/mismatched #print axioms output: " + expected["name"])
        tokens = re.sub(r"\.\{[^}]*\}", "", match.group(1))
        actual = [part.strip() for part in tokens.split(",") if part.strip()]
        require(set(actual) == EXPECTED_AXIOMS and len(actual) == 3,
                "Unexpected recursive axiom footprint: " + expected["name"] + " " + repr(actual))
        axioms.append({**expected, "axioms": actual, "raw_text": body})
    return {"log": pin(log), "type_check_count": len(checks), "axiom_check_count": len(axioms),
            "types": checks, "axioms": axioms}


def successful_log(run, module, completion):
    attempt = run / f"attempt-{completion['attempt']:03d}"
    candidates = []
    for status in attempt.glob("*-" + module + "_olean.json"):
        result = json.loads(status.read_text())
        if result.get("label") == module + ":olean" and result.get("status") == "PASS":
            candidates.append((status, result))
    require(len(candidates) == 1, "Missing/ambiguous successful source-build log: " + module)
    status, result = candidates[0]
    return Path(result["stdout"]), pin(status)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-run", required=True)
    parser.add_argument("--source-plan", required=True)
    parser.add_argument("--source-plan-sha256", required=True)
    parser.add_argument("--prior-final-log", required=True)
    parser.add_argument("--prior-boundary-log", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    require(pin(args.source_plan)["sha256"] == args.source_plan_sha256, "Source plan SHA256 mismatch")
    plan = json.loads(Path(args.source_plan).read_text())
    run = Path(args.source_run).resolve(strict=True)
    receipt = json.loads((run / "summary.json").read_text())
    require(receipt["status"] == "ALL_FROM_SOURCE_OFFLINE_LAKE_BUILDS_PASS" and receipt.get("inputs_unchanged") is True,
            "Full source build has not passed")
    require(receipt["plan_sha256"] == args.source_plan_sha256 and receipt["completed_modules"] == 3136,
            "Source build/plan mismatch")
    journal = [json.loads(line) for line in (run / "completed.jsonl").read_text().splitlines()]
    require([row["module"] for row in journal] == [job["module"] for job in plan["jobs"]], "Incomplete source-build journal")
    workspace = Path(plan["workspace"])
    output = Path(args.output).resolve()
    require(not output.is_relative_to(workspace) and not output.exists(), "Audit output must be new and outside frozen workspace")
    report = {"schema": "hilbert17-vendored-acceptance-log-audit-v1", "status": "AUDIT_PENDING",
              "source_receipt": pin(run / "summary.json"), "source_plan": pin(args.source_plan),
              "source_journal": pin(run / "completed.jsonl"), "extractor": pin(__file__), "modules": [],
              "scope": "Post-build extraction of fourteen exact theorem-type reports and fourteen recursive axiom reports; not a new Lean execution or replacement for fresh kernel replay"}
    prior_paths = {"FinalTargetContract": args.prior_final_log, "BoundaryAcceptance": args.prior_boundary_log}
    for module in MODULES:
        job = next(job for job in plan["jobs"] if job["module"] == module)
        source = Path(job["source"]["path"])
        require(pin(source) == job["source"], "Acceptance source differs from compiled pin")
        completed = next(row for row in journal if row["module"] == module)
        require(completed["source"] == job["source"], "Journal acceptance source mismatch")
        for artifact in completed["outputs"]:
            require(pin(artifact["path"]) == artifact, "Acceptance compiled output changed")
        expected_checks, expected_axioms = commands(source)
        log, status = successful_log(run, module, completed)
        fresh = extract(log, module, expected_checks, expected_axioms)
        prior = extract(prior_paths[module], module, expected_checks, expected_axioms)
        same_types = [x["normalized_sha256"] for x in fresh["types"]] == [x["normalized_sha256"] for x in prior["types"]]
        same_axioms = [{**x, "raw_text": ""} for x in fresh["axioms"]] == [{**x, "raw_text": ""} for x in prior["axioms"]]
        report["modules"].append({"module": module, "source": job["source"], "build_status": status,
                                  "fresh": fresh, "prior_log": prior["log"],
                                  "normalized_type_outputs_match_prior": same_types,
                                  "axiom_outputs_match_prior": same_axioms})
    report["type_check_count"] = sum(row["fresh"]["type_check_count"] for row in report["modules"])
    report["axiom_check_count"] = sum(row["fresh"]["axiom_check_count"] for row in report["modules"])
    report["all_expected_axioms_only"] = True
    report["all_prior_type_outputs_match"] = all(row["normalized_type_outputs_match_prior"] for row in report["modules"])
    report["all_prior_axiom_outputs_match"] = all(row["axiom_outputs_match_prior"] for row in report["modules"])
    report["status"] = "FOURTEEN_TYPES_AND_AXIOM_FOOTPRINTS_MATCH_PRIOR" if report["all_prior_type_outputs_match"] and report["all_prior_axiom_outputs_match"] else "REVIEW_REQUIRED_OUTPUT_DIFFERENCE"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"status": report["status"], "report": pin(output), "type_check_count": report["type_check_count"],
                      "axiom_check_count": report["axiom_check_count"], "all_expected_axioms_only": True}, indent=2))
    return 0 if report["status"] == "FOURTEEN_TYPES_AND_AXIOM_FOOTPRINTS_MATCH_PRIOR" else 1


if __name__ == "__main__":
    sys.exit(main())
