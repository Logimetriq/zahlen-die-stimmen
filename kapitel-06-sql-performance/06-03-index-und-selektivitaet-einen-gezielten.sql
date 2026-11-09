-- Kapitel 6 · SQL-Performance
-- Abschnitt „Index und Selektivität: einen gezielten Zugriff testen“ · Codeblock 3

CREATE INDEX perf_orders_received_idx ON ch06.perf_orders (received_at);
