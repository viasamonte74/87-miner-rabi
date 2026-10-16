#!/usr/bin/env python3
"""Score Rabi methods against published golden truth + divergence variants (no private oracle)."""

from __future__ import annotations

import json
import sys
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "sn87-provenonce-public"
sys.path.insert(0, str(ROOT / "src"))

from sn87_provenonce.baselines import ic_approval_applicability, type_c_release
from sn87_provenonce.canonical import evidence_commitment
from sn87_provenonce.institutional_v02 import contracts as ic
from sn87_provenonce.institutional_v02.fixtures import build_case
from sn87_provenonce.miners.rabi_ic import rabi_approval_witness
from sn87_provenonce.miners.rabi_type_c import rabi_type_c
from sn87_provenonce.miners.witness_ic import approval_witness
from sn87_provenonce.pilot import contracts as tc
from sn87_provenonce.simulation.type_c import FIXTURES

GOLDEN = ROOT / "protocol" / "golden_truth"


def _ic_published() -> list[tuple[str, dict, dict]]:
    doc = json.loads((GOLDEN / "ic_fixture_set.json").read_text(encoding="utf-8"))
    out = []
    for case in doc["cases"]:
        if case["case_id"].startswith("default/"):
            family = case["case_id"].split("/", 1)[1]
            capsule = build_case(family)
            assert evidence_commitment(capsule) == case["capsule_commitment"], case["case_id"]
            out.append((case["case_id"], capsule, case["truth"]))
    return out


def _check_ic() -> int:
    fails = 0
    print("== IC published defaults ==")
    for case_id, capsule, truth in _ic_published():
        rabi = rabi_approval_witness(capsule)
        stock = approval_witness(capsule)
        base = ic_approval_applicability(capsule)
        ok = rabi["state"] == truth["state"] == stock["state"] == base["state"]
        if truth["state"] == "FINDINGS":
            required = sorted(truth["defects"][0]["required_refs"])
            ok = ok and sorted(rabi["findings"][0]["evidence_refs"]) == required
        if not ok:
            fails += 1
        print(f"  {'OK' if ok else 'FAIL'} {case_id}: rabi={rabi['state']} truth={truth['state']}")
    return fails


def _check_tc() -> int:
    fails = 0
    print("== TYPE-C public FIXTURES (vs baseline codes + tighter refs) ==")
    for fixture in FIXTURES:
        capsule = tc.capsule_from_fixture(fixture)
        rabi = rabi_type_c(capsule)
        base = type_c_release(capsule)
        codes_r = sorted(f["code"] for f in rabi["findings"])
        codes_b = sorted(f["code"] for f in base["findings"])
        ok = rabi["state"] == base["state"] and codes_r == codes_b
        if rabi["state"] == "FINDINGS":
            for finding in rabi["findings"]:
                base_refs = set(
                    next(f for f in base["findings"] if f["code"] == finding["code"])[
                        "evidence_refs"
                    ]
                )
                cited = set(finding["evidence_refs"])
                ok = ok and cited <= base_refs
                # non-MISSING codes drop $completeness vs cite-all baseline
                if not finding["code"].startswith("MISSING_"):
                    ok = ok and len(cited) < len(base_refs)
        if not ok:
            fails += 1
        print(
            f"  {'OK' if ok else 'FAIL'} {fixture.fixture_id}: "
            f"rabi={rabi['state']} codes={codes_r}"
        )
    return fails


def _divergence() -> None:
    print("== Divergence variants (no oracle; informational) ==")

    def expired(c: dict) -> None:
        action = next(e for e in c["events"] if e["kind"] == "ACTION")
        links = [
            e
            for e in c["events"]
            if e["kind"] == "APPROVAL_LINK" and e["local_token"] == action["approval_token"]
        ]
        by_id = {e["event_id"]: e for e in c["events"]}
        by_id[links[0]["approval_ref"]]["valid_until"] = action["at"]

    def same_actor(c: dict) -> None:
        action = max((e for e in c["events"] if e["kind"] == "ACTION"), key=lambda e: e["at"])
        links = [
            e
            for e in c["events"]
            if e["kind"] == "APPROVAL_LINK" and e["local_token"] == action["approval_token"]
        ]
        by_id = {e["event_id"]: e for e in c["events"]}
        approval = by_id[links[0]["approval_ref"]]
        review = by_id[approval["review_ref"]]
        approval["actor_id"] = review["actor_id"]

    def ungoverned(c: dict) -> None:
        action = max((e for e in c["events"] if e["kind"] == "ACTION"), key=lambda e: e["at"])
        links = [
            e
            for e in c["events"]
            if e["kind"] == "APPROVAL_LINK" and e["local_token"] == action["approval_token"]
        ]
        by_id = {e["event_id"]: e for e in c["events"]}
        approval = by_id[links[0]["approval_ref"]]
        review = by_id[approval["review_ref"]]
        review["condition_commitment"] = "sha256:" + "a" * 64

    for name, edit in (
        ("approval_expired", expired),
        ("same_actor", same_actor),
        ("ungoverned_review", ungoverned),
    ):
        capsule = build_case("stale_authority")
        edit(capsule)
        capsule["evidence_commitment"] = evidence_commitment(capsule)
        try:
            ic.validate_capsule(deepcopy(capsule))
        except Exception as exc:  # noqa: BLE001
            print(f"  skip {name}: not contract-valid ({exc})")
            continue
        states = {
            "rabi": rabi_approval_witness(capsule)["state"],
            "stock": approval_witness(capsule)["state"],
            "base": ic_approval_applicability(capsule)["state"],
        }
        print(f"  {name}: {states}")


def main() -> int:
    fails = _check_ic() + _check_tc()
    _divergence()
    print(f"\nRESULT: {'PASS' if fails == 0 else f'FAIL ({fails})'}")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
