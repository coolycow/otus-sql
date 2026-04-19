-- Представления для отчётов и упрощения запросов (вызов через SELECT).

-- ВЛ с полным географическим контекстом: страна и регион в одной строке.
CREATE OR REPLACE VIEW v_power_lines_geo AS
SELECT
  pl.line_id,
  pl.name AS line_name,
  pl.voltage_kv,
  pl.length_km,
  c.name AS country_name,
  r.name AS region_name,
  pl.commissioned_at,
  pl.extra_spec
FROM power_lines pl
JOIN regions r ON r.region_id = pl.region_id
JOIN countries c ON c.country_id = r.country_id;

COMMENT ON VIEW v_power_lines_geo IS 'Карточка ВЛ с названием страны и региона для отчётов и экспорта.';

-- Опоры с материалом и краткой сводкой по линии (без лишних JOIN в каждом отчёте).
CREATE OR REPLACE VIEW v_supports_enriched AS
SELECT
  s.support_id,
  s.line_id,
  pl.name AS line_name,
  s.seq_no,
  s.kind,
  m.name AS material_name,
  s.cipher,
  s.pole_number,
  ST_Y(s.base_geom) AS base_latitude,
  ST_X(s.base_geom) AS base_longitude,
  s.base_geom,
  fn_support_count_for_line(s.line_id) AS supports_on_line
FROM supports s
JOIN power_lines pl ON pl.line_id = s.line_id
JOIN materials m ON m.material_id = s.material_id;

COMMENT ON VIEW v_supports_enriched IS 'Опоры с названием ВЛ, материалом и числом опор на той же линии.';

-- Незавершённые отключения с именем линии (диспетчерская сводка).
CREATE OR REPLACE VIEW v_open_outages AS
SELECT
  o.outage_id,
  o.line_id,
  pl.name AS line_name,
  o.started_at,
  o.reason,
  o.current_before_a
FROM outages o
JOIN power_lines pl ON pl.line_id = o.line_id
WHERE o.ended_at IS NULL;

COMMENT ON VIEW v_open_outages IS 'Только активные отключения — для мониторинга и SLA.';
