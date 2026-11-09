"""Small local analysis. AI_GENERATED: Codex GPT-6 family, 2026-10-07."""
from pathlib import Path
import pandas as pd

INVENTORY_KEYS = ["warehouse_id", "product_id", "snapshot_date"]
PRICE_KEYS = ["product_id", "price_date", "currency"]
RESULT_FILES = ["inventory.csv", "exceptions.csv", "selected_prices.csv",
                "orders.csv", "summary.csv"]


def load_data(input_dir, orders_file):
    inventory = pd.read_csv(Path(input_dir) / "inventory_snapshots.csv",
        dtype={"warehouse_id": "Int64", "product_id": "Int64",
               "snapshot_date": "string", "quantity": "Int64"},
        keep_default_na=False, na_values=[""])
    prices = pd.read_csv(Path(input_dir) / "product_price_revisions.csv",
        dtype={"product_id": "Int64", "price_date": "string", "currency": "string",
               "revision_id": "Int64", "available_at": "string", "price": "Float64"},
        keep_default_na=False, na_values=[""])
    products = pd.read_csv(Path(input_dir) / "products.csv", dtype={"product_id": "Int64"})
    warehouses = pd.read_csv(Path(input_dir) / "warehouses.csv", dtype={"warehouse_id": "Int64"})
    orders = pd.read_csv(orders_file, dtype={"order_id": "Int64", "revision_id": "Int64",
        "customer_id": "Int64", "warehouse_id": "Int64", "product_id": "Int64",
        "order_amount_eur": "Float64", "currency": "string", "event_at": "string",
        "received_at": "string", "processed_at": "string", "available_at": "string",
        "processing_group": "string"}, keep_default_na=False, na_values=[""])
    inventory["snapshot_date"] = pd.to_datetime(inventory["snapshot_date"], format="%Y-%m-%d", errors="raise")
    prices["price_date"] = pd.to_datetime(prices["price_date"], format="%Y-%m-%d", errors="raise")
    prices["available_at"] = pd.to_datetime(prices["available_at"], format="ISO8601", utc=True, errors="raise")
    orders["received_at"] = pd.to_datetime(orders["received_at"], format="ISO8601", utc=True, errors="raise")
    orders["processed_at"] = pd.to_datetime(orders["processed_at"], format="ISO8601", utc=True, errors="raise")
    orders["available_at"] = pd.to_datetime(orders["available_at"], format="ISO8601", utc=True, errors="raise")
    orders["duration_min"] = (orders["processed_at"] - orders["received_at"]).dt.total_seconds() / 60
    return {"inventory": inventory, "prices": prices, "products": products,
            "warehouses": warehouses, "orders": orders}


def select_prices(prices, cutoff, currency):
    eligible = prices[(prices["available_at"] <= cutoff)
                      & (prices["currency"] == currency)].copy()
    selected = eligible.sort_values(
        ["product_id", "price_date", "currency",
         "available_at", "revision_id"]
    ).drop_duplicates(subset=PRICE_KEYS, keep="last")
    return selected


def value_inventory(inventory, selected_prices, currency):
    if selected_prices.duplicated(subset=PRICE_KEYS).any():
        raise ValueError("Preisstand: mehr als ein Preis je "
                         "Produkt, Tag und Währung.")
    work = inventory.copy()
    work["currency"] = pd.Series(currency, index=work.index, dtype="string")
    valued = work.merge(selected_prices, how="left",
        left_on=["product_id", "snapshot_date", "currency"],
        right_on=["product_id", "price_date", "currency"],
        validate="many_to_one", indicator=True)
    valued["value_eur"] = valued["quantity"] * valued["price"]
    valued["price_missing"] = valued["price"].isna()
    return valued.sort_values(INVENTORY_KEYS).reset_index(drop=True)


def check_data(data, cutoff, currency):
    inventory = data["inventory"]
    prices = data["prices"]
    orders = data["orders"]
    if currency != "EUR":
        raise ValueError("Bewertung: dieses Beispiel verlangt EUR; keine Währungsumrechnung.")
    if cutoff.tzinfo is None:
        raise ValueError("Informationsstand: Zeitzonenbezug fehlt; Z oder Offset angeben.")
    if len(inventory) == 0:
        raise ValueError("Bestand: leerer Eingang; kein Referenzlauf möglich.")
    if inventory[INVENTORY_KEYS + ["quantity"]].isna().any().any():
        raise ValueError("Bestand: Pflichtschlüssel oder Menge fehlt.")
    if inventory.duplicated(subset=INVENTORY_KEYS).any():
        raise ValueError("Bestand: Lager, Produkt und Tag sind nicht eindeutig.")
    if (inventory["quantity"] < 0).any():
        raise ValueError("Bestand: negative Menge nicht vereinbart.")
    if (~inventory["product_id"].isin(data["products"]["product_id"])).any():
        raise ValueError("Bestand: Produkt-ID fehlt im Produktverzeichnis.")
    if (~inventory["warehouse_id"].isin(data["warehouses"]["warehouse_id"])).any():
        raise ValueError("Bestand: Lager-ID fehlt im Lagerverzeichnis.")
    if prices[PRICE_KEYS + ["revision_id", "available_at"]].isna().any().any():
        raise ValueError("Preise: Pflichtschlüssel oder Kenntniszeit fehlt.")
    if prices.duplicated(subset=PRICE_KEYS + ["revision_id"]).any():
        raise ValueError("Preise: dieselbe Revision mehrfach geliefert.")
    if (~prices["product_id"].isin(data["products"]["product_id"])).any():
        raise ValueError("Preise: Produkt-ID fehlt im Produktverzeichnis.")
    if (prices["price"] < 0).any():
        raise ValueError("Preise: negativer Preis nicht vereinbart.")
    if orders[["order_id", "revision_id", "order_amount_eur", "available_at",
               "received_at", "processed_at"]].isna().any().any():
        raise ValueError("Bestellungen: Pflichtangabe fehlt.")
    if orders["order_id"].duplicated().any():
        raise ValueError("Bestellungen: vorbereitete Ansicht enthält doppelte Identitäten.")
    if (orders["available_at"] > cutoff).any():
        raise ValueError("Bestellungen: vorbereitete Ansicht passt nicht zum Informationsstand.")
    if (orders["currency"] != currency).any():
        raise ValueError("Bestellungen: Währung passt nicht zum Lauf.")
    if (orders["duration_min"] < 0).any():
        raise ValueError("Bestellungen: Abschluss liegt vor Eingang.")


def write_outputs(data, selected_prices, valued, output_dir):
    output_dir = Path(output_dir)
    # Refuse reuse: stale outputs can otherwise be mistaken for this run.
    output_dir.mkdir(parents=True, exist_ok=False)
    fields = INVENTORY_KEYS + ["quantity", "currency", "price", "value_eur", "price_missing"]
    valued[fields].to_csv(output_dir / "inventory.csv", index=False,
        na_rep="MISSING", float_format="%.2f", date_format="%Y-%m-%d", lineterminator="\n")
    valued[valued["price_missing"]][fields].to_csv(output_dir / "exceptions.csv", index=False,
        na_rep="MISSING", float_format="%.2f", date_format="%Y-%m-%d", lineterminator="\n")
    selected_prices.sort_values(PRICE_KEYS).to_csv(output_dir / "selected_prices.csv", index=False,
        na_rep="MISSING", float_format="%.2f", date_format="%Y-%m-%dT%H:%M:%S%z", lineterminator="\n")
    data["orders"].sort_values("order_id").to_csv(output_dir / "orders.csv", index=False,
        na_rep="MISSING", float_format="%.2f", date_format="%Y-%m-%dT%H:%M:%S%z", lineterminator="\n")
    known = valued["value_eur"].sum(min_count=1)
    total = known if valued["price_missing"].sum() == 0 else pd.NA
    summary = pd.DataFrame({"inventory_rows": [len(valued)],
        "priced_rows": [int(valued["price"].notna().sum())],
        "known_value_eur": [known], "total_value_eur": [total]})
    summary.to_csv(output_dir / "summary.csv", index=False,
        na_rep="MISSING", float_format="%.2f", lineterminator="\n")


def compare_runs(first_dir, second_dir):
    """Names of the result files whose bytes differ between two runs."""
    return [name for name in RESULT_FILES
            if (Path(first_dir) / name).read_bytes()
            != (Path(second_dir) / name).read_bytes()]
