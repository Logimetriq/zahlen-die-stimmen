-- Zahlen, die stimmen – Begleitmaterial
-- Richtet die Tabellen und Ansichten des durchgehenden Falls ein (Kapitel 4, 5 und folgende).
-- Aufruf aus dem Hauptordner des Materials, in einer neuen, leeren Datenbank:
--   psql -d zahlen_die_stimmen -f einrichtung/postgresql-setup.sql
-- Alle Tabellen liegen im Schema b2b; die Datenbank sucht dort automatisch (search_path).
-- Geprüft mit PostgreSQL 16.

\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
SET DateStyle = 'ISO, YMD';
CREATE SCHEMA b2b;
SET search_path = b2b, public;
DO $$ BEGIN
  EXECUTE format('ALTER DATABASE %I SET search_path TO b2b, public', current_database());
  EXECUTE format('ALTER DATABASE %I SET timezone TO %L', current_database(), 'UTC');
  EXECUTE format('ALTER DATABASE %I SET datestyle TO %L', current_database(), 'ISO, YMD');
END $$;

CREATE TABLE customers(customer_id integer PRIMARY KEY, customer_name text NOT NULL);
CREATE TABLE products(product_id integer PRIMARY KEY, product_name text NOT NULL);
CREATE TABLE warehouses(warehouse_id integer PRIMARY KEY, warehouse_name text NOT NULL);
\copy customers FROM 'daten/customers.csv' CSV HEADER
\copy products FROM 'daten/products.csv' CSV HEADER
\copy warehouses FROM 'daten/warehouses.csv' CSV HEADER

CREATE TABLE order_revisions (
 order_id integer NOT NULL, revision_id integer NOT NULL,
 customer_id integer NOT NULL REFERENCES customers,
 warehouse_id integer NOT NULL REFERENCES warehouses,
 product_id integer NOT NULL REFERENCES products,
 order_amount_eur numeric(12,2) NOT NULL,
 currency text NOT NULL CHECK(currency = 'EUR'),
 event_at timestamptz NOT NULL, received_at timestamptz NOT NULL,
 processed_at timestamptz, available_at timestamptz NOT NULL,
 processing_group text NOT NULL,
 PRIMARY KEY(order_id, revision_id)
);
\copy order_revisions FROM 'daten/order_revisions.csv' CSV HEADER

CREATE VIEW orders AS
SELECT DISTINCT ON (order_id) *
FROM order_revisions
WHERE received_at >= TIMESTAMPTZ '2026-09-14 00:00:00+00'
  AND received_at < TIMESTAMPTZ '2026-09-15 00:00:00+00'
  AND available_at <= TIMESTAMPTZ '2026-09-15 06:00:00+00'
ORDER BY order_id, available_at DESC, revision_id DESC;

CREATE TABLE order_entry_versions (
 order_id integer NOT NULL, entry_revision_id integer NOT NULL,
 available_at timestamptz NOT NULL, processing_group text NOT NULL,
 PRIMARY KEY(order_id, entry_revision_id)
);
\copy order_entry_versions FROM 'daten/order_entry_versions.csv' CSV HEADER

CREATE TABLE inventory_snapshots (
 warehouse_id integer REFERENCES warehouses, product_id integer REFERENCES products,
 snapshot_date date, quantity integer NOT NULL,
 PRIMARY KEY(warehouse_id, product_id, snapshot_date)
);
\copy inventory_snapshots FROM 'daten/inventory_snapshots.csv' CSV HEADER
CREATE TABLE product_price_revisions (
 product_id integer REFERENCES products, price_date date, currency text,
 revision_id integer, available_at timestamptz NOT NULL,
 price numeric(12,2) NOT NULL,
 PRIMARY KEY(product_id, price_date, currency, revision_id)
);
\copy product_price_revisions FROM 'daten/product_price_revisions.csv' CSV HEADER

CREATE VIEW selected_product_prices AS
SELECT DISTINCT ON (product_id, price_date, currency) *
FROM product_price_revisions
WHERE price_date = DATE '2026-09-14' AND currency = 'EUR'
  AND available_at <= TIMESTAMPTZ '2026-09-15 06:00:00+00'
ORDER BY product_id, price_date, currency, available_at DESC, revision_id DESC;
CREATE VIEW selected_product_prices_later AS
SELECT DISTINCT ON (product_id, price_date, currency) *
FROM product_price_revisions
WHERE price_date = DATE '2026-09-14' AND currency = 'EUR'
  AND available_at <= TIMESTAMPTZ '2026-09-15 12:00:00+00'
ORDER BY product_id, price_date, currency, available_at DESC, revision_id DESC;

CREATE VIEW order_overview AS
SELECT o.*, c.customer_name, w.warehouse_name, p.product_name
FROM orders o JOIN customers c USING(customer_id)
JOIN warehouses w USING(warehouse_id) JOIN products p USING(product_id);
CREATE VIEW inventory_overview AS
SELECT s.*, w.warehouse_name, p.product_name, r.price,
       s.quantity * r.price AS inventory_value_eur
FROM inventory_snapshots s JOIN warehouses w USING(warehouse_id)
JOIN products p USING(product_id)
LEFT JOIN selected_product_prices r
 ON r.product_id=s.product_id AND r.price_date=s.snapshot_date AND r.currency='EUR';

CREATE TABLE order_duplicate_check AS SELECT * FROM orders;
INSERT INTO order_duplicate_check SELECT * FROM orders WHERE order_id = 4712;
CREATE TABLE order_reference_check AS SELECT * FROM orders;
UPDATE order_reference_check SET product_id=299 WHERE order_id=4714;
CREATE TABLE inventory_price_check(warehouse_id integer, price numeric(12,2));
INSERT INTO inventory_price_check VALUES (301,100), (302,NULL);
CREATE TABLE price_zero_check AS SELECT * FROM selected_product_prices;
INSERT INTO price_zero_check VALUES (202,'2026-09-14','EUR',1,'2026-09-14T18:00:00Z',0);
CREATE TABLE price_wrong_check AS SELECT * FROM selected_product_prices;
INSERT INTO price_wrong_check VALUES
 (202,'2026-09-14','USD',1,'2026-09-14T18:00:00Z',200),
 (202,'2026-09-13','EUR',1,'2026-09-13T18:00:00Z',200);

CREATE TABLE customer_check_customers(customer_id integer PRIMARY KEY);
CREATE TABLE customer_check_orders(order_id integer PRIMARY KEY, customer_id integer);
INSERT INTO customer_check_customers VALUES (101),(102);
INSERT INTO customer_check_orders VALUES (4811,101),(4812,NULL);

CREATE TABLE ticket_control(ticket_id text PRIMARY KEY, minutes integer NOT NULL);
\copy ticket_control FROM 'daten/pruefdaten/ticket_control.csv' CSV HEADER
CREATE TABLE peer_control(item_id text PRIMARY KEY, order_value integer, amount_eur numeric(12,2));
\copy peer_control FROM 'daten/pruefdaten/peer_control.csv' CSV HEADER
CREATE TABLE observed_values(series_id text, observation_date date, value numeric(12,2), PRIMARY KEY(series_id, observation_date));
\copy observed_values FROM 'daten/pruefdaten/observed_values.csv' CSV HEADER
CREATE TABLE last_known_price_check(product_id integer, price_date date, currency text,
 revision_id integer, available_at timestamptz, price numeric(12,2),
 PRIMARY KEY(product_id,price_date,currency,revision_id));
\copy last_known_price_check FROM 'daten/pruefdaten/last_known_price_check.csv' CSV HEADER
CREATE TABLE delivery_control(observation_id text, revision_id integer,
 available_at timestamptz, value numeric(12,2), delivery_id text PRIMARY KEY);
\copy delivery_control FROM 'daten/pruefdaten/delivery_control.csv' CSV HEADER
CREATE TABLE ambiguous_price_check AS SELECT * FROM last_known_price_check WHERE false;
INSERT INTO ambiguous_price_check VALUES
 (201,'2026-09-14','EUR',1,'2026-09-14T18:00:00Z',10),
 (201,'2026-09-14','EUR',1,'2026-09-14T18:00:00Z',11);
CREATE TABLE order_entry_time_check AS SELECT * FROM order_entry_versions;
UPDATE order_entry_time_check SET available_at='2026-09-14T12:01:00Z' WHERE order_id=4713;

CREATE TABLE ordered_amounts(sequence_no integer PRIMARY KEY, amount_eur numeric(12,2) NOT NULL);
INSERT INTO ordered_amounts VALUES (1,100),(2,200),(3,300),(4,400);
CREATE TABLE revision_example(product text, price_date date, currency text,
 revision_id integer, available_at timestamptz NOT NULL, price numeric(12,2) NOT NULL,
 PRIMARY KEY(product,price_date,currency,revision_id));
INSERT INTO revision_example VALUES
 ('Tastatur','2026-09-14','EUR',1,'2026-09-14T12:00:00Z',98),
 ('Tastatur','2026-09-14','EUR',2,'2026-09-14T18:00:00Z',100),
 ('Tastatur','2026-09-14','EUR',3,'2026-09-15T13:00:00Z',105);
