#!/usr/bin/env python3
"""After full source-build PASS only: freeze replay inputs, without executing Lean."""
import argparse
import fcntl
import importlib.util
import json
from pathlib import Path
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-plan", required=True)
    parser.add_argument("--source-plan-sha256", required=True)
    parser.add_argument("--source-run", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--workspace", help="Optional exact workspace assertion")
    args = parser.parse_args()
    tools = Path(__file__).resolve().parent
    runner = tools / "guarded_vendor_fresh_replay.py"
    spec = importlib.util.spec_from_file_location("fresh_plan_helpers", runner)
    r = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(r)
    g = r.load_guard()
    r.require(g.digest(args.source_plan) == args.source_plan_sha256, "Source plan SHA256 mismatch")
    source_plan = g.read_json(args.source_plan)
    workspace = Path(source_plan["workspace"]).resolve(strict=True)
    if args.workspace:
        r.require(Path(args.workspace).resolve() == workspace, "Workspace assertion mismatch")
    # Do not freeze changing artifacts or race the ongoing source build.
    expected_lock = workspace.parent / "hilbert17-20261013/verification/runtime-compile.lock"
    r.require(source_plan["shared_lock"] == str(expected_lock), "Wrong shared compiler lock")
    lock = expected_lock.open("a")
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    run = Path(args.source_run).resolve(strict=True)
    receipt_path, journal_path = run / "summary.json", run / "completed.jsonl"
    receipt = g.read_json(receipt_path)
    r.require(receipt["plan_sha256"] == args.source_plan_sha256, "Source receipt/plan mismatch")
    g.validate_configs(source_plan)
    for record in source_plan["inputs"]:
        g.check_pin(record)
    records = r.validate_source_completion(g, source_plan, receipt, journal_path)
    output = Path(args.output).resolve()
    r.require(output.is_relative_to(tools) and not output.exists(), "Output must be new and outside frozen source workspace")
    inventory_path = output.with_name(output.stem + "-inventory.json")
    r.require(not inventory_path.exists(), "Inventory already exists")
    toolchain = Path(source_plan["lean"]["path"]).parent.parent
    roots = [str(workspace / ".lake/build/lib/lean")] + [str(workspace / "vendor" / p / ".lake/build/lib/lean") for p in source_plan["packages"]]
    builtin = str(toolchain / "lib/lean")
    artifact_paths = sorted(r.inventory_paths(roots + [builtin]))
    all_outputs = [p for record in records for p in record["outputs"]]
    by_path = {p["path"]: p for p in all_outputs}
    # Validated source outputs reuse their freshly checked pins; builtin artifacts
    # are hashed here. This inventory is evidence, never an artifact copy/cache.
    artifact_pins = [by_path[p] if p in by_path else g.pin(p) for p in artifact_paths]
    workspace_pins = [p for p in artifact_pins if Path(p["path"]).is_relative_to(workspace)]
    builtin_pins = [p for p in artifact_pins if Path(p["path"]).is_relative_to(toolchain)]
    r.require(len(workspace_pins) + len(builtin_pins) == len(artifact_pins), "External replay artifact")
    runtime_paths = sorted(set((toolchain / "lib/lean").glob("*.so")) | {
        toolchain / "src/lean/LeanChecker.lean", toolchain / "src/lean/Lean/Replay.lean"})
    inventory = {"schema": "hilbert17-vendored-fresh-inventory-v1", "roots": roots + [builtin],
                 "created_utc": g.now(), "source_config_asset_pins": source_plan["inputs"],
                 "artifact_pins": artifact_pins, "all_build_output_pins": all_outputs,
                 "toolchain_runtime_pins": [g.pin(p) for p in runtime_paths],
                 "counts": {"workspace_replay_artifacts": len(workspace_pins), "builtin_replay_artifacts": len(builtin_pins),
                            "all_build_outputs": len(all_outputs), "source_config_asset_inputs": len(source_plan["inputs"])},
                 "bytes": {"workspace_replay_artifacts": sum(p["bytes"] for p in workspace_pins),
                           "builtin_replay_artifacts": sum(p["bytes"] for p in builtin_pins)},
                 "trust_boundary": "All installed Lean/Std/Lake olean/private/server/IR files pinned as trusted prebuilt artifacts; compiler/runtime not bootstrapped"}
    g.write_json(inventory_path, inventory)
    checker = g.pin(toolchain / "bin/leanchecker")
    base = [source_plan["lake"]["path"], "--dir", str(workspace), "--no-cache", "--no-build", "env"]
    boundary = next(record for record in records if record["module"] == "BoundaryAcceptance")
    plan = {"schema": r.SCHEMA, "status": "READY_FOR_ROOT_REVIEW", "workspace": str(workspace),
            "module": "BoundaryAcceptance", "runner": g.pin(runner), "generator": g.pin(__file__),
            "guard": g.pin(tools / "guarded_source_build.py"), "source_plan": g.pin(args.source_plan),
            "source_receipt": g.pin(receipt_path), "source_journal": g.pin(journal_path),
            "lake": source_plan["lake"], "checker": checker, "libseccomp": source_plan["libseccomp"],
            "source": boundary["source"],
            "entry_olean": next(p for p in boundary["outputs"] if p["path"].endswith("/BoundaryAcceptance.olean")),
            "inventory": g.pin(inventory_path), "workspace_artifact_roots": roots, "builtin_artifact_root": builtin,
            "shared_lock": str(expected_lock), "environment_probe": base,
            "replay_command": base + [checker["path"], "--fresh", "-v", "BoundaryAcceptance"],
            "inventory_counts": inventory["counts"], "inventory_bytes": inventory["bytes"], "scope": r.SCOPE,
            "relocation_policy": "Paths must match successful source-build evidence; relocating requires a separately frozen matching plan"}
    g.write_json(output, plan)
    print(json.dumps({"status": "PREPARED_NOT_EXECUTED", "plan": g.pin(output), "inventory": plan["inventory"],
                      "counts": inventory["counts"], "bytes": inventory["bytes"]}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
