"""One plain function test path. Expectations fixed before transform/text."""
from pathlib import Path
import json
import pandas as pd
from analysis import load_data, select_prices, value_inventory, check_data

HERE = Path(__file__).resolve().parent
EARLY = pd.Timestamp("2026-09-15T06:00:00Z")


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def fresh_data():
    return load_data(HERE / "../daten",
                     HERE / "../kapitel-07-python-import/orders.csv")


def expect_value_error(action, message):
    try:
        action()
    except ValueError as error:
        require(str(error) == message,
                "Falscher Fehlerzweck: " + str(error))
    else:
        raise AssertionError(
            "Erwarteter ValueError blieb aus: " + message)


def check_reference(valued):
    require(valued["warehouse_id"].tolist() == [301, 302], "Lageridentitäten falsch")
    require(valued["product_id"].tolist() == [201, 202],
            "Produktidentitäten falsch")
    require(valued["snapshot_date"].dt.strftime("%Y-%m-%d").tolist()
            == ["2026-09-14", "2026-09-14"], "Bestandsstichtag falsch")
    require(valued["quantity"].tolist() == [10, 5],
            "Mengen falsch zugeordnet")
    require(valued["price"].notna().tolist() == [True, False], "Preisverfügbarkeit falsch")
    require(valued["price_missing"].tolist() == [False, True], "Ausnahmemarker falsch")
    require(valued["price"].notna().sum() == 1, "Abdeckung muss 1 von 2 sein")
    require(valued["value_eur"].sum(min_count=1) == 1000, "Teilwert muss 1000 EUR sein")
    require(valued["value_eur"].isna().tolist() == [False, True], "Monitorwert muss unbekannt bleiben")


def test_reference():
    data = fresh_data()
    check_data(data, EARLY, "EUR")
    selected = select_prices(data["prices"], EARLY, "EUR")
    valued = value_inventory(data["inventory"], selected, "EUR")
    check_reference(valued)
    require(data["orders"]["order_id"].tolist() == [4711, 4712, 4713, 4714], "Bestellidentitäten")
    require(data["orders"]["order_amount_eur"].sum() == 1000, "Bestellbetrag")
    require(data["orders"]["duration_min"].tolist() == [30, 90, 60, 120], "Dauern")


def test_boundary():
    data = fresh_data()
    before = select_prices(data["prices"], pd.Timestamp("2026-09-15T09:59:59Z"), "EUR")
    at = select_prices(data["prices"], pd.Timestamp("2026-09-15T10:00:00Z"), "EUR")
    require(before["product_id"].tolist() == [201], "Preis vor Verfügbarkeit")
    require(at["product_id"].tolist() == [201, 202], "Inklusive Grenze verloren")


def test_late_revision():
    data = fresh_data()
    extra = data["prices"].iloc[[0]].copy()
    extra["revision_id"] = 2
    extra["available_at"] = pd.Timestamp("2026-09-15T13:00:00Z")
    extra["price"] = 105
    changed = pd.concat([data["prices"], extra], ignore_index=True)
    early = select_prices(changed, EARLY, "EUR")
    check_reference(value_inventory(data["inventory"], early, "EUR"))
    late = select_prices(changed, pd.Timestamp("2026-09-15T13:00:00Z"), "EUR")
    require(late["price"].tolist() == [105, 200], "Späte Revision nicht ausgewählt")


def test_duplicate_price():
    data = fresh_data()
    selected = select_prices(data["prices"], EARLY, "EUR")
    duplicate = pd.concat([selected, selected], ignore_index=True)
    def action():
        value_inventory(data["inventory"], duplicate, "EUR")
    expect_value_error(action, "Preisstand: mehr als ein Preis je Produkt, Tag und Währung.")


def test_unknown_product():
    data = fresh_data()
    data["inventory"].loc[0, "product_id"] = 299
    def action():
        check_data(data, EARLY, "EUR")
    expect_value_error(action, "Bestand: Produkt-ID fehlt im Produktverzeichnis.")


def test_duplicate_inventory():
    data = fresh_data()
    data["inventory"] = pd.concat([data["inventory"], data["inventory"].iloc[[0]]], ignore_index=True)
    def action():
        check_data(data, EARLY, "EUR")
    expect_value_error(action, "Bestand: Lager, Produkt und Tag sind nicht eindeutig.")


def test_weak_count():
    data = fresh_data()
    valued = value_inventory(data["inventory"], select_prices(data["prices"], EARLY, "EUR"), "EUR")
    valued.loc[1, "product_id"] = 201
    require(len(valued) == 2, "Gegenfall muss schwachen Count bestehen")
    try:
        check_reference(valued)
    except AssertionError as error:
        require(str(error) == "Produktidentitäten falsch", "Falscher Gegenfallzweck")
    else:
        raise AssertionError("Identitätsfehler blieb unerkannt")


def test_scale():
    data = fresh_data()
    selected = select_prices(data["prices"], EARLY, "EUR").copy()
    selected["price"] = selected["price"] * 100
    valued = value_inventory(data["inventory"], selected, "EUR")
    try:
        check_reference(valued)
    except AssertionError as error:
        require(str(error) == "Teilwert muss 1000 EUR sein", "Falscher Skalierungsfehlerzweck")
    else:
        raise AssertionError("Skalierungsfehler blieb unerkannt")


def test_new_condition():
    # Exercise: move only Monitor availability to the early boundary.
    data = fresh_data()
    data["prices"].loc[data["prices"]["product_id"] == 202, "available_at"] = EARLY
    selected = select_prices(data["prices"], EARLY, "EUR")
    valued = value_inventory(data["inventory"], selected, "EUR")
    require(valued["product_id"].tolist() == [201, 202], "Neue Bedingung: Identitäten")
    require(valued["quantity"].tolist() == [10, 5], "Neue Bedingung: Mengen")
    require(valued["price_missing"].tolist() == [False, False], "Neue Bedingung: beide Preise")
    require(valued["value_eur"].sum() == 2000, "Neue Bedingung: 2000 EUR")
    before = select_prices(data["prices"], pd.Timestamp("2026-09-15T05:59:59Z"), "EUR")
    require(before["product_id"].tolist() == [201], "Neue Bedingung: keine verfrühte Verfügbarkeit")


def run_tests():
    tests = [test_reference, test_boundary, test_late_revision, test_duplicate_price,
             test_unknown_product, test_duplicate_inventory, test_weak_count, test_scale,
             test_new_condition]
    results = []
    for test in tests:
        test()
        print("PASS:", test.__name__)
        results.append({"test": test.__name__, "result": "PASS"})
    return results


if __name__ == "__main__":
    results = run_tests()
    print(str(len(results)) + " Tests bestanden.")
