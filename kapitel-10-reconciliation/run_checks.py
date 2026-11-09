"""AI_GENERATED: CH10 reconciliation; author context, no framework or new source selection."""
from pathlib import Path
from decimal import Decimal
from datetime import datetime, timezone
import argparse
import copy
import csv
import hashlib
import json
import math
import platform
import subprocess
import sys
import pandas as pd

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent  # Hauptordner des Begleitmaterials
ORDER_KEYS = ["order_id"]
ORDER_FIELDS = ["revision_id", "customer_id", "warehouse_id", "product_id",
                "order_amount_eur", "currency", "duration_min"]
INV_KEYS = ["warehouse_id", "product_id", "snapshot_date"]
INV_FIELDS = ["quantity", "currency", "price", "value_eur"]
NUMERIC = {"order_amount_eur", "duration_min", "quantity", "price", "value_eur"}

def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))

def digest(path, lf=False):
    raw = path.read_bytes()
    if lf:
        raw = raw.replace(b"\r\n", b"\n")
    return hashlib.sha256(raw).hexdigest()

def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))

def instant(text):
    value = datetime.fromisoformat(text.replace("Z", "+00:00"))
    if value.tzinfo is None or value.utcoffset() is None:
        raise ValueError("timestamp requires explicit UTC offset")
    return value.astimezone(timezone.utc)

def normalize(rows):
    rows = copy.deepcopy(rows)
    for row in rows:
        for field, value in row.items():
            if value in ("", "MISSING"):
                row[field] = None
        # Prepared SQL order export has timestamps but no derived duration column.
        if "order_id" in row and "duration_min" not in row:
            try:
                row["duration_min"] = str(Decimal(str((instant(row["processed_at"])
                    - instant(row["received_at"])).total_seconds())) / Decimal("60"))
            except (ValueError, TypeError, AttributeError, KeyError):
                row["duration_min"] = None  # Controlled schema/time finding in check.
        if "inventory_value_eur" in row:
            row["value_eur"] = row.pop("inventory_value_eur")
        if "snapshot_date" in row and "currency" not in row:
            row["currency"] = "EUR"  # Explicit target contract, not inferred from missing price.
    return rows

def same(a, b, numeric=False):
    if a is None or b is None:
        return a is None and b is None
    return Decimal(str(a)) == Decimal(str(b)) if numeric else a == b

def outer_pairs(expected, actual, keys):
    expected = pd.DataFrame(expected)
    actual = pd.DataFrame(actual, columns=expected.columns)
    # block: outer
    paired = expected.merge(actual, on=keys, how="outer",
                            validate="one_to_one", indicator=True,
                            suffixes=("_soll", "_ist"))
    # endblock: outer
    return paired

def detail(expected, actual, keys, fields):
    paired = outer_pairs(expected, actual, keys)
    rows = []
    for _, pair in paired.iterrows():
        row = {key: pair[key] for key in keys}
        merge_status = str(pair["_merge"])
        mismatch = []
        if merge_status == "left_only":
            status = "missing"
        elif merge_status == "right_only":
            status = "unexpected"
        else:
            for field in fields:
                a, b = pair[field + "_soll"], pair[field + "_ist"]
                a = None if pd.isna(a) else a
                b = None if pd.isna(b) else b
                if not same(a, b, field in NUMERIC):
                    mismatch.append(field)
            status = "value_mismatch" if mismatch else "matched"
        row.update(status=status, mismatch_fields=mismatch)
        for field in fields:
            a, b = pair[field + "_soll"], pair[field + "_ist"]
            row[field + "_soll"] = None if pd.isna(a) else a
            row[field + "_ist"] = None if pd.isna(b) else b
            if field in NUMERIC:
                row[field + "_difference"] = str(Decimal(str(b))-Decimal(str(a))) if not pd.isna(a) and not pd.isna(b) else "not_applicable"
        rows.append(row)
    return rows

def check(soll, actual, contract, kind):
    expected = soll[kind]
    keys = ORDER_KEYS if kind == "orders" else INV_KEYS
    fields = ORDER_FIELDS if kind == "orders" else INV_FIELDS
    baseline = soll["contract" if kind == "orders" else "inventory_contract"]
    report, details = [], []
    def record(rule, status, goal, found, deviation, severity="NONE"):
        report.append({"purpose":rule, "status":status, "population":baseline["population"],
                       "expected":goal, "finding":found, "deviation":deviation,
                       "severity":severity, "tolerance":"exact keys/counts/reference values; no missing valuation for full value", "owner":"Aylin prüft und dokumentiert; Leon klärt Lieferung; Mara entscheidet Nutzung",
                       "reaction": "Betroffene Nutzung sperren; Leon klärt Quelle, Aylin prüft Korrektur; Mara entscheidet Nutzung. Keine Nachricht ausgeführt." if severity == "HARD"
                       else "Aylin soll Lücke vor Veröffentlichung an Leon und Mara melden; Leon soll bis 08:00 Uhr Zuständigkeit/nächste Rückmeldung bestätigen; sonst soll Aylin an Mara eskalieren. Teilwert kennzeichnen, Vollwert zurückhalten; keine Nachricht ausgeführt."
                       if severity == "WARNING" else "Prüfergebnis dokumentieren"})
    differences = [name for name in baseline if baseline[name] != contract.get(name)]
    if differences:
        record("comparison_contract", "NOT_COMPARABLE", baseline, contract, differences, "HARD")
        return {"status":"NOT_COMPARABLE", "report":report, "details":details}
    record("comparison_contract", "PASS", baseline, contract, [], "NONE")
    time_fields = ["event_at", "received_at", "processed_at", "available_at"] if kind == "orders" else []
    required = keys + fields + time_fields
    missing_cols = sorted({field for row in actual for field in required if field not in row})
    if not actual:
        # Empty declared table retains the schema known from its CSV header; population will fail below.
        missing_cols = []
    if missing_cols:
        record("schema", "FAIL", required, missing_cols, missing_cols, "HARD")
        return {"status":"FAIL", "report":report, "details":details}
    signatures = [tuple(row[key] for key in keys) for row in actual]
    missing_keys = sum(any(value is None for value in key) for key in signatures)
    duplicate_surplus = len(signatures) - len(set(signatures))
    invalid_refs = []
    invalid_types = []
    range_flags = []
    for row in actual:
        for ref, allowed in soll["references"].items():
            if ref in row and row[ref] not in allowed:
                invalid_refs.append({"keys":[row[k] for k in keys], "field":ref, "value":row[ref]})
        for field in fields:
            if row[field] is None:
                if kind == "orders" or field in {"quantity", "currency"}:
                    invalid_types.append(field)
            elif field in NUMERIC:
                try:
                    value = Decimal(str(row[field]))
                    if not value.is_finite():
                        invalid_types.append(field)
                    # Only this fixture's nonnegative quantity/duration convention; amount plausibility not truth.
                    if field in {"quantity", "duration_min"} and value < 0:
                        range_flags.append(field)
                except Exception:
                    invalid_types.append(field)
        parsed_times = {}
        for field in time_fields:
            try:
                parsed_times[field] = instant(row[field])
            except (ValueError, TypeError, AttributeError):
                invalid_types.append(field)
        if "available_at" in parsed_times and parsed_times["available_at"] > instant(contract["cutoff"]):
            range_flags.append("revision_available_after_cutoff")
        # UTC execution semantics of the retained case; completion may be on a later day.
        for field in ["event_at", "received_at"]:
            if field in parsed_times and parsed_times[field].date().isoformat() != contract["business_date"]:
                range_flags.append(field + "_outside_business_date")
        if kind == "inventory" and row["snapshot_date"] != contract["business_date"]:
            range_flags.append("snapshot_date")
        if row.get("currency") != contract["currency"]:
            range_flags.append("currency")
    hard = missing_keys + duplicate_surplus + len(invalid_refs) + len(invalid_types) + len(range_flags)
    record("schema_keys_references", "FAIL" if hard else "PASS",
           "0 missing keys;0 duplicate surplus;valid references/types/ranges/time", 
           {"missing_keys":missing_keys,"duplicate_surplus":duplicate_surplus,"invalid_refs":invalid_refs,
            "invalid_types":invalid_types,"range_flags":range_flags}, hard, "HARD" if hard else "NONE")
    if hard:
        return {"status":"FAIL", "report":report, "details":details}
    expkeys = {tuple(row[k] for k in keys) for row in expected}
    actkeys = set(signatures)
    missing, unexpected = sorted(expkeys-actkeys), sorted(actkeys-expkeys)
    record("population", "FAIL" if missing or unexpected else "PASS", sorted(expkeys), sorted(actkeys),
           {"missing":missing,"unexpected":unexpected}, "HARD" if missing or unexpected else "NONE")
    details = detail(expected, actual, keys, fields)
    failures = [row for row in details if row["status"] != "matched"]
    record("detail_reconciliation", "FAIL" if failures else "PASS", "all expected keys and values equal",
           {s:sum(row["status"] == s for row in details) for s in ["missing","unexpected","value_mismatch","matched"]},
           len(failures), "HARD" if failures else "NONE")
    value_field = "order_amount_eur" if kind == "orders" else "value_eur"
    total = sum((Decimal(row[value_field]) for row in actual if row[value_field] is not None), Decimal("0"))
    goal = soll["aggregate"]["order_sum_eur" if kind == "orders" else "known_value_eur"]
    aggregate_failure = total != Decimal(goal) or len(actual) != len(expected)
    record("aggregate_diagnostic", "FAIL" if aggregate_failure else "PASS", {"rows":len(expected),"known_sum":goal},
           {"rows":len(actual),"known_sum":str(total)}, str(total-Decimal(goal)), "HARD" if aggregate_failure else "NONE")
    if kind == "orders":
        groups = {warehouse:str(sum((Decimal(row["order_amount_eur"]) for row in actual
                  if row["warehouse_id"] == warehouse), Decimal("0"))) for warehouse in ["301","302"]}
        group_failure = any(Decimal(groups[k]) != Decimal(v) for k,v in soll["aggregate"]["warehouse_sums"].items())
        record("warehouse_sums", "FAIL" if group_failure else "PASS", soll["aggregate"]["warehouse_sums"], groups,
               "group value mismatch" if group_failure else 0, "HARD" if group_failure else "NONE")
    else:
        valued = sum(row["price"] is not None and row["value_eur"] is not None for row in actual)
        record("valuation_coverage", "KNOWN_EXCEPTION" if valued < len(actual) else "PASS", "complete valuation needs 2/2",
               {"valued":valued,"rows":len(actual),"full_value":str(total) if valued == len(actual) else None},
               len(actual)-valued, "WARNING" if valued < len(actual) else "NONE")
    status = "FAIL" if any(row["severity"] == "HARD" for row in report) else "LIMITED" if kind == "inventory" else "PASS"
    return {"status":status,"report":report,"details":details}

def git_head():
    try:
        return subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True,stderr=subprocess.DEVNULL).strip()
    except (OSError, subprocess.CalledProcessError):
        return "UNAVAILABLE"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="execution.json")
    parser.add_argument("--output-dir", help="New result directory relative to this package; refuses an existing directory")
    args = parser.parse_args()
    # Active reader runs retain every historical scenario and evidence file.
    # The legacy invocation without --output-dir keeps its original paths.
    if args.output_dir is not None:
        out = (HERE/args.output_dir).resolve()
        if not out.is_relative_to(HERE.resolve()):
            parser.error("--output-dir muss innerhalb von kapitel-10-reconciliation liegen")
        if out.exists() or out.is_symlink():
            parser.error("Ergebnisordner existiert bereits; bitte einen neuen --output-dir waehlen")
        if Path(args.output).name != args.output or args.output in (".", ".."):
            parser.error("With --output-dir, --output must be a single file name")
        report_path = out/args.output
    else:
        out = HERE/"outputs"
        report_path = HERE/args.output
    soll = read_json(HERE/"independent-soll.json")
    sql_dir = ROOT/"kapitel-07-python-import"  # vorbereitete SQL-Ausgaben (frueher Stand)
    py_dir = ROOT/"kapitel-09-reproduzierbar/outputs/reference"  # erst Kapitel 9 ausfuehren
    sql_manifest = read_json(HERE/"eingaben/sql-export-manifest.json")
    py_manifest = read_json(py_dir/"run-manifest.json")
    # Check actual existing predecessor bytes. Never manufacture fresh predecessor execution.
    for name in ["orders.csv", "inventory_overview.csv"]:
        if digest(sql_dir/name, True) != sql_manifest["prepared_sha256"][name]:
            raise ValueError("SQL prepared export identity changed: " + name)
    for name in ["orders.csv", "inventory.csv"]:
        if digest(py_dir/name) != py_manifest["outputs_sha256"][name]:
            raise ValueError("Python predecessor output identity changed: " + name)
    sql_contract = copy.deepcopy(soll["contract"])
    py_contract = copy.deepcopy(soll["contract"])
    sql_contract["cutoff"] = instant(sql_manifest["cutoff"]).isoformat().replace("+00:00", "Z")
    py_contract["cutoff"] = instant(py_manifest["cutoff"]).isoformat().replace("+00:00", "Z")
    sql_inv_contract = copy.deepcopy(soll["inventory_contract"])
    py_inv_contract = copy.deepcopy(soll["inventory_contract"])
    sql_inv_contract["cutoff"] = sql_contract["cutoff"]
    py_inv_contract["cutoff"] = py_contract["cutoff"]
    py_contract["currency"] = py_manifest["currency"]
    py_inv_contract["currency"] = py_manifest["currency"]
    sql_orders, py_orders = normalize(read_csv(sql_dir/"orders.csv")), normalize(read_csv(py_dir/"orders.csv"))
    sql_inv, py_inv = normalize(read_csv(sql_dir/"inventory_overview.csv")), normalize(read_csv(py_dir/"inventory.csv"))
    scenarios = {}
    for side, orders, inventory, order_contract, inv_contract in [("sql",sql_orders,sql_inv,sql_contract,sql_inv_contract),("python",py_orders,py_inv,py_contract,py_inv_contract)]:
        scenarios[side+"_orders"] = check(soll,orders,order_contract,"orders")
        scenarios[side+"_inventory"] = check(soll,inventory,inv_contract,"inventory")
    paired = detail(sql_orders,py_orders,ORDER_KEYS,ORDER_FIELDS)
    scenarios["sql_python_agreement"] = {"status":"PASS" if all(row["status"] == "matched" for row in paired) else "FAIL", "details":paired}
    paired_inventory = detail(sql_inv,py_inv,INV_KEYS,INV_FIELDS)
    scenarios["sql_python_inventory_agreement"] = {"status":"PASS" if all(row["status"] == "matched" for row in paired_inventory) else "FAIL", "details":paired_inventory}
    variants = {}
    for name in ["false_identity","false_assignment","fanout","missing_population","scaling100","later_revision","unknown_reference"]:
        variants[name] = copy.deepcopy(py_orders)
    variants["false_identity"][-1]["order_id"] = "4799"
    variants["false_assignment"][0]["order_amount_eur"], variants["false_assignment"][1]["order_amount_eur"] = "200.00", "100.00"
    variants["fanout"].append(copy.deepcopy(py_orders[1]))
    variants["missing_population"].pop()
    variants["scaling100"][0]["order_amount_eur"] = "10000.00"
    variants["later_revision"][2].update(revision_id="2", duration_min="90.00", available_at="2026-09-16T10:00:00Z")
    variants["unknown_reference"][0]["product_id"] = "299"
    for name in ["wrong_order_business_day", "wrong_received_day", "naive_available", "invalid_available_type"]:
        variants[name] = copy.deepcopy(py_orders)
    for field in ["event_at", "received_at", "processed_at", "available_at"]:
        variants["wrong_order_business_day"][0][field] = variants["wrong_order_business_day"][0][field].replace("2026-09-14", "2026-09-13")
    variants["wrong_received_day"][0]["received_at"] = "2026-09-13T09:00:00Z"
    variants["naive_available"][0]["available_at"] = "2026-09-15T06:00:00"
    variants["invalid_available_type"][0]["available_at"] = "not-a-time"
    for name, rows in variants.items():
        scenarios[name] = check(soll, rows, soll["contract"], "orders")
    for name, timestamp in [("same_instant_offset", "2026-09-15T08:00:00+02:00"), ("at_cutoff", "2026-09-15T06:00:00Z")]:
        rows = copy.deepcopy(py_orders)
        rows[0]["available_at"] = timestamp
        scenarios[name] = check(soll, rows, soll["contract"], "orders")
    both_wrong = variants["false_assignment"]
    scenarios["both_wrong_technical_agreement"] = {"status":"PASS", "details":detail(both_wrong,copy.deepcopy(both_wrong),ORDER_KEYS,ORDER_FIELDS)}
    scenarios["both_wrong_fachlich"] = check(soll,both_wrong,soll["contract"],"orders")
    scaled_inventory = copy.deepcopy(py_inv)
    scaled_inventory[0].update(price="10000.00",value_eur="100000.00")
    scenarios["price_scaling100"] = check(soll,scaled_inventory,soll["inventory_contract"],"inventory")
    scenarios["empty_population"] = check(soll,[],soll["contract"],"orders")
    later = copy.deepcopy(soll["inventory_contract"])
    later["cutoff"] = "2026-09-15T12:00:00Z"
    scenarios["cutoff12"] = check(soll,py_inv,later,"inventory")
    scenarios["both_cutoff12_sql"] = check(soll,sql_inv,later,"inventory")
    scenarios["both_cutoff12_python"] = check(soll,py_inv,later,"inventory")
    missing_zero = copy.deepcopy(py_inv)
    missing_zero[1].update(price="0",value_eur="0")
    scenarios["missing_not_zero"] = check(soll,missing_zero,soll["inventory_contract"],"inventory")
    scenarios["rounding_probe"] = {"status":"PASS", "checks":{
        "tiny_representation_difference":math.isclose(0.1+0.2,0.3,rel_tol=0,abs_tol=1e-12),
        "one_cent_not_tolerated":not math.isclose(100.01,100.00,rel_tol=0,abs_tol=1e-12),
        "scaling_not_tolerated":not math.isclose(10000,100,rel_tol=0,abs_tol=1e-12)}}
    expected_status = {"sql_orders":"PASS","python_orders":"PASS","sql_inventory":"LIMITED","python_inventory":"LIMITED",
                       "sql_python_agreement":"PASS","cutoff12":"NOT_COMPARABLE","rounding_probe":"PASS"}
    for name in list(variants)+["missing_not_zero"]:
        expected_status[name] = "FAIL"
    expected_status.update(sql_python_inventory_agreement="PASS",both_wrong_technical_agreement="PASS",both_wrong_fachlich="FAIL",price_scaling100="FAIL",empty_population="FAIL",both_cutoff12_sql="NOT_COMPARABLE",both_cutoff12_python="NOT_COMPARABLE")
    expected_status.update(same_instant_offset="PASS", at_cutoff="PASS")
    checks = {name:scenarios[name]["status"] == status for name,status in expected_status.items()}
    checks["rounding_decisions"] = all(scenarios["rounding_probe"]["checks"].values())
    checks["same_count_sum_false_identity"] = scenarios["false_identity"]["report"][4]["status"] == "PASS"
    checks["same_count_sum_false_assignment"] = scenarios["false_assignment"]["report"][4]["status"] == "PASS"
    checks["complete_outer_statuses"] = {row["status"] for row in scenarios["false_identity"]["details"]} == {"matched","missing","unexpected"}
    for name, field in [("wrong_order_business_day", "event_at_outside_business_date"), ("wrong_received_day", "received_at_outside_business_date")]:
        checks[name + "_diagnosed"] = field in scenarios[name]["report"][1]["finding"]["range_flags"]
    for name in ["naive_available", "invalid_available_type"]:
        checks[name + "_diagnosed"] = "available_at" in scenarios[name]["report"][1]["finding"]["invalid_types"]
    if args.output_dir is not None and args.output in {name+".json" for name in scenarios}:
        parser.error("--output must differ from every scenario file name")
    out.mkdir(parents=True, exist_ok=args.output_dir is None)
    output_files = {}
    for name,result in scenarios.items():
        path = out/(name+".json")
        path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
        output_files[path.relative_to(ROOT).as_posix()] = digest(path)
    inputs = [HERE/"independent-soll.json", sql_dir/"orders.csv",sql_dir/"inventory_overview.csv",HERE/"eingaben/sql-export-manifest.json",
              py_dir/"orders.csv",py_dir/"inventory.csv",py_dir/"run-manifest.json"]
    evidence = {"executed_at":datetime.now(timezone.utc).isoformat(),"executed_by":"local run",
                "input_commit":git_head(),
                "binding":"working tree inputs and code identified by hashes; HEAD alone is insufficient",
                "runtime":{"python":platform.python_version(),"pandas":pd.__version__,"platform":platform.platform(),"executable":sys.executable},
                "input_sha256_lf":{p.relative_to(ROOT).as_posix():digest(p,True) for p in inputs},
                "code_sha256":{p.relative_to(ROOT).as_posix():digest(p) for p in [HERE/"run_checks.py",ROOT/"requirements.txt"]},
                "output_sha256":output_files,"checks":checks,"expected_status":expected_status,
                "scenarios":{name:{"status":result["status"],"result_file":(out/(name+".json")).relative_to(ROOT).as_posix()} for name,result in scenarios.items()},
                "result":"PASS" if all(checks.values()) else "FAIL"}
    report_path.write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
    print(json.dumps({"result":evidence["result"],"checks":checks,"statuses":{name:r["status"] for name,r in scenarios.items()}},indent=2))
    if not all(checks.values()):
        raise AssertionError("Control outcomes differ from independently fixed expectations")

if __name__ == "__main__":
    main()
