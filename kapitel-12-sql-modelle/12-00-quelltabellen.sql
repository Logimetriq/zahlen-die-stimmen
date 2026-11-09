-- Kapitel 12 · SQL-Analysemodelle wiederverwenden und kontrolliert ändern
-- Schritt 1: Quelltabellen im Schema m04 anlegen (vorbereitete Bestellungen und Bestände des frühen Stands).
-- Aufruf aus dem Hauptordner:  psql -d zahlen_die_stimmen -f kapitel-12-sql-modelle/12-00-quelltabellen.sql

\set ON_ERROR_STOP on
CREATE SCHEMA m04;
SET search_path TO m04;
SET TIME ZONE 'UTC';
CREATE TABLE src_orders(order_id text NOT NULL PRIMARY KEY, revision_id text NOT NULL, customer_id text NOT NULL, warehouse_id text NOT NULL, product_id text NOT NULL, order_amount_eur numeric(14, 2) NOT NULL, currency text NOT NULL, event_at timestamptz NOT NULL, received_at timestamptz NOT NULL, processed_at timestamptz NOT NULL, available_at timestamptz NOT NULL, processing_group text NOT NULL);
INSERT INTO src_orders VALUES ('4711', '1', '101', '301', '201', '100.00', 'EUR', '2026-09-14T09:00:00Z', '2026-09-14T09:00:00Z', '2026-09-14T09:30:00Z', '2026-09-14T09:31:00Z', 'STANDARD');
INSERT INTO src_orders VALUES ('4712', '1', '102', '301', '201', '200.00', 'EUR', '2026-09-14T10:00:00Z', '2026-09-14T10:00:00Z', '2026-09-14T11:30:00Z', '2026-09-14T11:31:00Z', 'PRUEFBEDARF');
INSERT INTO src_orders VALUES ('4713', '1', '101', '302', '202', '300.00', 'EUR', '2026-09-14T12:00:00Z', '2026-09-14T12:00:00Z', '2026-09-14T13:00:00Z', '2026-09-14T13:01:00Z', 'STANDARD');
INSERT INTO src_orders VALUES ('4714', '1', '102', '302', '201', '400.00', 'EUR', '2026-09-14T14:00:00Z', '2026-09-14T14:00:00Z', '2026-09-14T16:00:00Z', '2026-09-14T16:01:00Z', 'PRUEFBEDARF');
CREATE TABLE src_inventory(warehouse_id text NOT NULL, product_id text NOT NULL, snapshot_date date NOT NULL, quantity integer NOT NULL, price numeric(14, 2), inventory_value_eur numeric(14, 2), PRIMARY KEY(warehouse_id, product_id, snapshot_date));
INSERT INTO src_inventory VALUES ('301', '201', '2026-09-14', '10', '100.00', '1000.00');
INSERT INTO src_inventory VALUES ('302', '202', '2026-09-14', '5', NULL, NULL);
CREATE TABLE src_products(product_id text NOT NULL PRIMARY KEY, product_name text NOT NULL);
INSERT INTO src_products VALUES ('201', 'Tastatur');
INSERT INTO src_products VALUES ('202', 'Monitor');
CREATE TABLE src_warehouses(warehouse_id text NOT NULL PRIMARY KEY, warehouse_name text NOT NULL);
INSERT INTO src_warehouses VALUES ('301', 'Lager Frankfurt');
INSERT INTO src_warehouses VALUES ('302', 'Lager Köln');
CREATE TABLE src_customers(customer_id text NOT NULL PRIMARY KEY, customer_name text NOT NULL);
INSERT INTO src_customers VALUES ('101', 'Müller GmbH');
INSERT INTO src_customers VALUES ('102', 'Schneider KG');
