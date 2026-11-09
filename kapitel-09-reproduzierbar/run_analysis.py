"""One explicit local entry point; no notebook state."""
from pathlib import Path
import hashlib
import json
import logging
import platform
import subprocess
import sys
from datetime import datetime, timezone
import pandas as pd
import numpy as np
from analysis import load_data, select_prices, value_inventory, check_data, write_outputs

HERE = Path(__file__).resolve().parent
# Die vorbereitete Bestellansicht (Kapitel 7) gilt für diesen Informationsstand.
PREPARED_CUTOFF = "2026-09-15T06:00:00Z"


def main(config_file):
    config_file = Path(config_file).resolve()
    config = json.loads(config_file.read_text(encoding="utf-8"))
    input_dir = (config_file.parent / config["input_dir"]).resolve()
    orders_file = (config_file.parent / config["orders_file"]).resolve()
    output_dir = (config_file.parent / config["output_dir"]).resolve()
    cutoff = pd.Timestamp(config["cutoff"])
    currency = config["currency"]
    if cutoff != pd.Timestamp(PREPARED_CUTOFF):
        raise ValueError("Bestellansicht: Informationsstand weicht vom vorbereiteten SQL-Stand ab.")
    pd.options.mode.copy_on_write = True
    logging.info("Start: Informationsstand %s, %s", cutoff, currency)
    data = load_data(input_dir, orders_file)
    check_data(data, cutoff, currency)
    selected = select_prices(data["prices"], cutoff, currency)
    valued = value_inventory(data["inventory"], selected, currency)
    missing = int(valued["price_missing"].sum())
    if missing > 0:
        logging.warning("%s von %s Beständen ohne Preis; siehe exceptions.csv.",
                        missing, len(valued))
        logging.warning("Vollständiger Wert unbekannt.")
    write_outputs(data, selected, valued, output_dir)
    files = [HERE / "analysis.py", HERE / "run_analysis.py", HERE / "test_analysis.py",
             HERE / "../requirements.txt", config_file,
             input_dir / "inventory_snapshots.csv", input_dir / "product_price_revisions.csv",
             input_dir / "products.csv", input_dir / "warehouses.csv", orders_file]
    bindings = {str(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in files}
    def git(*args):
        return subprocess.check_output(["git", *args], cwd=HERE, text=True, stderr=subprocess.DEVNULL).strip()
    code_paths = [str(path) for path in files[:4]]
    try:
        commit = git("rev-parse", "HEAD")
        dirty = bool(git("status", "--porcelain", "--", *code_paths))
    except (OSError, subprocess.CalledProcessError):
        commit, dirty = "UNAVAILABLE", True
    output_hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                     for path in sorted(output_dir.glob("*.csv"))}
    manifest = {"created_at": datetime.now(timezone.utc).isoformat(),
        "git_head": commit, "code_worktree_dirty": dirty,
        "content_binding": "SHA256 identifies executed files; HEAD alone does not identify dirty code.",
        "python": platform.python_version(), "pandas": pd.__version__, "numpy": np.__version__,
        "platform": platform.platform(), "executable": sys.executable,
        "cutoff": cutoff.isoformat(), "currency": currency,
        "input_and_code_sha256": bindings, "outputs_sha256": output_hashes,
        "orders_scope": "Vorbereitete Bestellansicht aus Kapitel 7; keine eigene Revisionsauswahl.",
        "prepared_orders_cutoff": PREPARED_CUTOFF,
        "independent_expectations": "Running-case reference and CH03 price rule; literals in test_analysis.py, not derived from transformation.",
        "contract_version": "b2b-operations-v1 / original cutoff",
        "seed": "N/A: no random operation",
        "tolerance": "Exact small integer-valued reference; no general money arithmetic guarantee",
        "inventory_grain": INVENTORY_GRAIN,
        "result": "COMPLETED_WITH_PRICE_EXCEPTION" if missing else "COMPLETED"}
    (output_dir / "run-manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    logging.info("Fertig: %s; %s Bestände, %s bewertet.", output_dir, len(valued), len(valued) - missing)


INVENTORY_GRAIN = ["warehouse_id", "product_id", "snapshot_date"]
EXPECTED_ERRORS = (ValueError, OSError, KeyError, pd.errors.MergeError)
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    config = sys.argv[1] if len(sys.argv) > 1 else HERE / "config.json"
    try:
        main(config)
    except EXPECTED_ERRORS as error:
        logging.error("Lauf abgebrochen: %s", error)
        sys.exit(1)
