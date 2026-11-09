-- Kapitel 11 · Analytische Datenmodelle und gemeinsame Kennzahlen
-- Legt das kleine Star Schema in SQLite an (Dimensionen, Bestell-Fact, Bestands-Fact).
-- Aufruf im Kapitelordner:  sqlite3 modell.db < 11-00-modell.sql
-- Danach z. B.:  sqlite3 modell.db < 11-01-...sql

CREATE TABLE customer_dimension(customer_id TEXT NOT NULL PRIMARY KEY, customer_name TEXT NOT NULL);
INSERT INTO "customer_dimension" VALUES('101','Müller GmbH');
INSERT INTO "customer_dimension" VALUES('102','Schneider KG');
CREATE TABLE date_dimension(calendar_date TEXT NOT NULL PRIMARY KEY, calendar_month TEXT NOT NULL);
INSERT INTO "date_dimension" VALUES('2026-09-14','2026-09');
CREATE TABLE inventory_fact(
        warehouse_id TEXT NOT NULL REFERENCES warehouse_dimension,
        product_id TEXT NOT NULL REFERENCES product_dimension,
        snapshot_date TEXT NOT NULL REFERENCES date_dimension,
        quantity INTEGER NOT NULL, price_cent INTEGER, inventory_value_cent INTEGER,
        currency TEXT NOT NULL CHECK(currency='EUR'),
        inventory_value_eur GENERATED ALWAYS AS (inventory_value_cent / 100.0) VIRTUAL,
        PRIMARY KEY(warehouse_id, product_id, snapshot_date));
INSERT INTO "inventory_fact" VALUES('301','201','2026-09-14',10,10000,100000,'EUR');
INSERT INTO "inventory_fact" VALUES('302','202','2026-09-14',5,NULL,NULL,'EUR');
CREATE TABLE order_fact(
        order_id TEXT NOT NULL PRIMARY KEY, revision_id TEXT NOT NULL,
        customer_id TEXT NOT NULL REFERENCES customer_dimension,
        warehouse_id TEXT NOT NULL REFERENCES warehouse_dimension,
        product_id TEXT NOT NULL REFERENCES product_dimension,
        received_date TEXT NOT NULL REFERENCES date_dimension,
        processed_date TEXT NOT NULL REFERENCES date_dimension,
        received_at TEXT NOT NULL, processed_at TEXT NOT NULL, available_at TEXT NOT NULL,
        processing_group TEXT NOT NULL, currency TEXT NOT NULL CHECK(currency='EUR'),
        order_amount_cent INTEGER NOT NULL, duration_min REAL NOT NULL,
        order_amount_eur GENERATED ALWAYS AS (order_amount_cent / 100.0) VIRTUAL);
INSERT INTO "order_fact" VALUES('4711','1','101','301','201','2026-09-14','2026-09-14','2026-09-14T09:00:00Z','2026-09-14T09:30:00Z','2026-09-14T09:31:00Z','STANDARD','EUR',10000,30.0);
INSERT INTO "order_fact" VALUES('4712','1','102','301','201','2026-09-14','2026-09-14','2026-09-14T10:00:00Z','2026-09-14T11:30:00Z','2026-09-14T11:31:00Z','PRUEFBEDARF','EUR',20000,90.0);
INSERT INTO "order_fact" VALUES('4713','1','101','302','202','2026-09-14','2026-09-14','2026-09-14T12:00:00Z','2026-09-14T13:00:00Z','2026-09-14T13:01:00Z','STANDARD','EUR',30000,60.0);
INSERT INTO "order_fact" VALUES('4714','1','102','302','201','2026-09-14','2026-09-14','2026-09-14T14:00:00Z','2026-09-14T16:00:00Z','2026-09-14T16:01:00Z','PRUEFBEDARF','EUR',40000,120.0);
CREATE TABLE product_dimension(product_id TEXT NOT NULL PRIMARY KEY, product_name TEXT NOT NULL);
INSERT INTO "product_dimension" VALUES('201','Tastatur');
INSERT INTO "product_dimension" VALUES('202','Monitor');
CREATE TABLE warehouse_dimension(warehouse_id TEXT NOT NULL PRIMARY KEY, warehouse_name TEXT NOT NULL);
INSERT INTO "warehouse_dimension" VALUES('301','Lager Frankfurt');
INSERT INTO "warehouse_dimension" VALUES('302','Lager Köln');

