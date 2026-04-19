-- Примеры аналитических запросов и мониторинга (отдельно от DDL — по требованию курса).
-- Здесь: CTE, подзапрос, обращение к статистике для оценки нагрузки.

------------------------------------------------- Простые запросы -------------------------------------------------
-- Выборка всех ВЛ с указанием ID региона и ID страны.
SELECT pl.name AS line_name, r.name AS region_name, c.name AS country_name
FROM power_lines pl
JOIN regions r ON r.region_id = pl.region_id
JOIN countries c ON c.country_id = r.country_id;

-- Найти ВЛ по названию региона и названию страны .
SELECT pl.name AS line_name
FROM power_lines pl
JOIN regions r ON r.region_id = pl.region_id
JOIN countries c ON c.country_id = r.country_id
WHERE r.name = 'Тверская область' AND c.name = 'Россия';

-- Вывести список отключений по ID ВЛ за последние 30 дней (сортировка по убыванию времени начала отключения).
SELECT o.outage_id, o.line_id, o.started_at, o.ended_at, o.reason
FROM outages o
WHERE o.line_id = 1 AND o.started_at >= NOW() - INTERVAL '30 days'
ORDER BY o.started_at DESC;

-- Вывести список замеров тока по ID ВЛ с 01.04.2026 по 30.04.2026 (сортировка по убыванию времени замера).
SELECT m.measurement_id, m.line_id, m.measured_at, m.current_a
FROM line_current_measurements m
WHERE m.line_id = 1 AND m.measured_at BETWEEN '2026-04-01' AND '2026-04-30'
ORDER BY m.measured_at DESC;

-- Вывести список всех отключенных на текущий момент времени ВЛ с указанием названия ВЛ, времени начала отключения,
-- длительности отключения в секундах и причины отключения. Сортировка по длительности отключения в секундах.
SELECT o.line_id, pl.name AS line_name, o.started_at, o.reason, o.current_before_a, EXTRACT(EPOCH FROM NOW() - o.started_at) AS duration_seconds
FROM outages o
JOIN power_lines pl ON pl.line_id = o.line_id
WHERE o.ended_at IS NULL
ORDER BY duration_seconds DESC;

------------------------------------------------- Отчёт по регионам -------------------------------------------------
-- средняя длина ВЛ и число открытых отключений по региону.
-- Используется CTE (WITH): сначала считаем агрегаты по линиям, затем сводим по региону.
WITH line_stats AS (
  SELECT
    pl.region_id,
    pl.line_id,
    pl.length_km,
    (SELECT count(*) FROM outages o WHERE o.line_id = pl.line_id AND o.ended_at IS NULL) AS open_outages
  FROM power_lines pl
)
SELECT
  r.name AS region_name,
  round(avg(ls.length_km), 3) AS avg_line_length_km,
  sum(ls.open_outages) AS total_open_outages,
  count(*) AS lines_in_region
FROM line_stats ls
JOIN regions r ON r.region_id = ls.region_id
GROUP BY r.region_id, r.name
ORDER BY r.name;


------------------------------------------------- Подзапрос в списке выборки -------------------------------------------------
-- Подзапрос в списке выборки: для каждой ВЛ показываем последний замер тока
SELECT
  pl.name AS line_name,
  pl.voltage_kv,
  (
    SELECT m.current_a
    FROM line_current_measurements m
    WHERE m.line_id = pl.line_id
    ORDER BY m.measured_at DESC
    LIMIT 1
  ) AS last_current_a
FROM power_lines pl
ORDER BY pl.voltage_kv;

------------------------------------------------- PostGIS: опоры в радиусе 5 км от заданной точки -------------------------------------------------
-- PostGIS: опоры в радиусе 5 км от заданной точки (география, метры).
-- Подходит для выборки объектов рядом с аварией или плановым участком.
-- Индекс GiST по base_geom помогает при большом числе опор.

SELECT s.cipher, pl.name AS line_name,
  ST_Distance(s.base_geom::geography, ST_SetSRID(ST_MakePoint(34.33, 56.25), 4326)::geography) AS dist_m
FROM supports s
JOIN power_lines pl ON pl.line_id = s.line_id
WHERE ST_DWithin(
  s.base_geom::geography,
  ST_SetSRID(ST_MakePoint(34.33, 56.25), 4326)::geography,
  5000
);

------------------------------------------------- Вызов функций -------------------------------------------------
-- Вызов функции fn_distance_km_wgs84(geometry, geometry) для расстояния между двумя точками WGS84.
SELECT fn_distance_km_wgs84(ST_SetSRID(ST_MakePoint(34.33, 56.25), 4326), ST_SetSRID(ST_MakePoint(34.34, 56.26), 4326)) AS dist_km;

-- Вызов функции fn_support_count_for_line(BIGINT) для подсчета числа опор на ВЛ.
SELECT fn_support_count_for_line(1) AS support_count;

-- Вызов функции fn_document_display_title(BIGINT) для несуществующего документа.
SELECT fn_document_display_title(4) AS document_title;

------------------------------------------------- Вызов процедур -------------------------------------------------
-- Вызов процедуры sp_register_outage(BIGINT, TEXT, NUMERIC) для регистрации нового отключения.
CALL sp_register_outage(1, 'Авария', 100.0);

-- Вызов процедуры sp_close_outage(BIGINT) для закрытия отключения.
CALL sp_close_outage(1);

-- Вызов процедуры sp_add_current_measurement(BIGINT, NUMERIC, TIMESTAMPTZ, TEXT) для добавления замера тока.
CALL sp_add_current_measurement(1, 100.0, '2026-04-01 10:00:00+03', 'Замер тока');

-- Вызов процедуры sp_link_document_to_line(BIGINT, BIGINT) для привязки документа к ВЛ.
CALL sp_link_document_to_line(1, 1);

-- Вызов процедуры sp_recalculate_line_length_km(BIGINT) для пересчета длины ВЛ.
CALL sp_recalculate_line_length_km(1);

------------------------------------------------- Вызов представлений -------------------------------------------------
-- Вызов представления v_power_lines_geo для вывода всех ВЛ с указанием ID региона и ID страны.
SELECT * FROM v_power_lines_geo;

-- Вызов представления v_supports_enriched для вывода всех опор с указанием ID ВЛ, названия ВЛ, материала, шифра, номера опоры, координаты точки и числа опор на ВЛ.
SELECT * FROM v_supports_enriched;

-- Вызов представления v_open_outages для вывода всех незавершенных отключений с указанием ID ВЛ, названия ВЛ, времени начала отключения, причины отключения и тока до события.
SELECT * FROM v_open_outages;

------------------------------------------------- Мониторинг производительности -------------------------------------------------
-- Мониторинг производительности (системные представления PostgreSQL).
-- Имеет смысл выполнять под суперпользователем или ролью с правом чтения статистики.
-- Показывает объём таблиц и число обращений — для поиска «горячих» таблиц.
SELECT
  schemaname,
  relname AS table_name,
  seq_scan,
  idx_scan,
  n_live_tup AS approx_rows,
  last_vacuum,
  last_autovacuum
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY seq_scan + idx_scan DESC;

-- Активные сессии (полезно при разборе блокировок и долгих запросов).
SELECT
  pid,
  usename,
  application_name,
  state,
  query_start,
  left(query, 120) AS query_preview
FROM pg_stat_activity
WHERE datname = current_database()
ORDER BY query_start NULLS LAST;


------------------------------------------------- Пример проверки плана выполнения -------------------------------------------------
-- Пример проверки плана выполнения (оптимизация): индекс по region_id должен уменьшить стоимость выборки ВЛ региона.
-- Каждая комманда ниже выполняется вручную, для удобства проверки результатов.
-- Подход с остальными индексами аналогичен: удалили индекс, проверили план выполнения, восстанали индекс, проверили план выполнения.
-- Сравнение планов проводится вручную.

-- Удаляем индекс на region_id, чтобы проверить, как работает выборка без индекса (см. 02_indexes.sql).
DROP INDEX IF EXISTS idx_power_lines_region_id;

-- Проверяем план выполнения без индекса.
EXPLAIN ANALYZE
SELECT * FROM power_lines WHERE region_id = (SELECT min(region_id) FROM regions);

-- Восстанавливаем индекс на region_id.
CREATE INDEX IF NOT EXISTS idx_power_lines_region_id ON power_lines (region_id);

-- Повторно проверяем план выполнения с индексом.
EXPLAIN ANALYZE
SELECT * FROM power_lines WHERE region_id = (SELECT min(region_id) FROM regions);