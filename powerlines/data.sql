-- Сгенерированные данные для демонстрации работы системы.
-- Генерация с помощью ИИ-агента (Cursor AI).
-- Наполнение БД демонстрационными данными (выполняется после выполнения скриптов sql/01 - 07).

INSERT INTO countries (name, iso_code) VALUES
  ('Россия', 'RU'),
  ('Казахстан', 'KZ');

INSERT INTO regions (country_id, name)
SELECT country_id, v.name
FROM countries c
JOIN (VALUES
  ('RU', 'Тверская область'),
  ('RU', 'Новгородская область'),
  ('KZ', 'Акмолинская область')
) AS v(iso, name) ON c.iso_code = v.iso;

INSERT INTO materials (name, application_area) VALUES
  ('Железобетон', 'support'),
  ('Сталь', 'support'),
  ('Фарфор', 'insulator'),
  ('Полимер', 'insulator'),
  ('Смешанный', 'other'),
  ('Алюминиевый сплав', 'conductor'),
  ('Сталь', 'cable');

INSERT INTO power_lines (region_id, name, description, voltage_kv, length_km, commissioned_at, extra_spec)
SELECT r.region_id, v.name, v.descr, v.u_kv, v.len_km, v.comm::DATE, v.spec::JSONB
FROM regions r
JOIN (VALUES
  ('Тверская область', 'ВЛ-110 «Ржев — Зубцов»', 'Участок с угловой опорой у реки', 110.00, 42.500, '1998-05-01',
   '{"circuits": 1, "ice_zone": 2}'),
  ('Новгородская область', 'ВЛ-220 «Чудово — Малая Вишера»', 'Магистраль с двумя цепями', 220.00, 68.200, '2005-09-15',
   '{"circuits": 2, "ice_zone": 1}'),
  ('Акмолинская область', 'ВЛ-500 «Астана — Щучинск»', 'Магистраль 500 кВ', 500.00, 120.000, '2012-03-20',
   '{"circuits": 1, "monitoring": "SCADA"}')
) AS v(region_name, name, descr, u_kv, len_km, comm, spec)
  ON r.name = v.region_name;

INSERT INTO supports (line_id, seq_no, kind, material_id, cipher, pole_number, base_geom, vertex_geom)
SELECT
  pl.line_id,
  v.seq,
  v.k::support_kind,
  m.material_id,
  v.ciph,
  v.pnum,
  ST_SetSRID(ST_MakePoint(v.lon, v.lat), 4326),
  CASE
    WHEN v.vlat IS NULL THEN NULL
    ELSE ST_SetSRID(ST_MakePoint(v.vlon, v.vlat), 4326)
  END
FROM (VALUES
  ('ВЛ-110 «Ржев — Зубцов»', 1, 'intermediate', 'Железобетон', 'ТВ-110-1', 'П1', 56.250000::DOUBLE PRECISION, 34.320000::DOUBLE PRECISION, 56.250100::DOUBLE PRECISION, 34.320050::DOUBLE PRECISION),
  ('ВЛ-110 «Ржев — Зубцов»', 2, 'anchor', 'Сталь', 'АН-110-2', 'П2', 56.255000::DOUBLE PRECISION, 34.340000::DOUBLE PRECISION, 56.255080::DOUBLE PRECISION, 34.340020::DOUBLE PRECISION),
  ('ВЛ-110 «Ржев — Зубцов»', 3, 'intermediate', 'Железобетон', 'ТВ-110-3', 'П3', 56.260000::DOUBLE PRECISION, 34.360000::DOUBLE PRECISION, NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION),
  ('ВЛ-220 «Чудово — Малая Вишера»', 1, 'anchor', 'Сталь', 'АН-220-A', 'A1', 59.120000::DOUBLE PRECISION, 31.650000::DOUBLE PRECISION, NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION),
  ('ВЛ-220 «Чудово — Малая Вишера»', 2, 'intermediate', 'Железобетон', 'ТВ-220-B', 'B2', 59.130000::DOUBLE PRECISION, 31.670000::DOUBLE PRECISION, NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION),
  ('ВЛ-220 «Чудово — Малая Вишера»', 3, 'intermediate', 'Железобетон', 'ТВ-220-C', 'C3', 59.140000::DOUBLE PRECISION, 31.690000::DOUBLE PRECISION, NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION),
  ('ВЛ-500 «Астана — Щучинск»', 1, 'intermediate', 'Сталь', 'П500-01', 'K1', 51.130000::DOUBLE PRECISION, 71.430000::DOUBLE PRECISION, NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION),
  ('ВЛ-500 «Астана — Щучинск»', 2, 'anchor', 'Сталь', 'П500-02', 'K2', 51.180000::DOUBLE PRECISION, 71.500000::DOUBLE PRECISION, NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION),
  ('ВЛ-500 «Астана — Щучинск»', 3, 'intermediate', 'Сталь', 'П500-03', 'K3', 51.220000::DOUBLE PRECISION, 71.560000::DOUBLE PRECISION, NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION)
) AS v(line_name, seq, k, mat, ciph, pnum, lat, lon, vlat, vlon)
JOIN power_lines pl ON pl.name = v.line_name
JOIN materials m ON m.name = v.mat AND m.application_area = 'support';

-- По одной траверсе на опору (металл); концы слегка смещены от базы для демонстрации геометрии.
INSERT INTO traverses (support_id, material_id, label, end_a_geom, end_b_geom, rotation_deg)
SELECT
  s.support_id,
  mt.material_id,
  'Тр-' || s.cipher,
  ST_SetSRID(ST_MakePoint(ST_X(s.base_geom::geometry) + 0.00004, ST_Y(s.base_geom::geometry)), 4326),
  ST_SetSRID(ST_MakePoint(ST_X(s.base_geom::geometry) + 0.00011, ST_Y(s.base_geom::geometry) + 0.00005), 4326),
  CASE s.cipher
    WHEN 'ТВ-110-1' THEN 12.5::NUMERIC
    WHEN 'АН-110-2' THEN 0.0::NUMERIC
    WHEN 'ТВ-220-B' THEN 8.0::NUMERIC
    ELSE 0.0::NUMERIC
  END
FROM supports s
JOIN materials mt ON mt.name = 'Сталь' AND mt.application_area = 'support';

INSERT INTO conductor_brands (material_id, name, section_mm2)
SELECT m.material_id, v.bname, v.sec
FROM (VALUES
  ('Алюминиевый сплав', 'АС-185/29', 185.0::NUMERIC),
  ('Алюминиевый сплав', 'АС-400/51', 400.0::NUMERIC),
  ('Сталь', 'АСК-600', 600.0::NUMERIC)
) AS v(mat_name, bname, sec)
JOIN materials m ON m.name = v.mat_name
  AND m.application_area = CASE WHEN v.mat_name = 'Сталь' THEN 'cable' ELSE 'conductor' END;

INSERT INTO conductors (
  conductor_brand_id,
  line_id,
  kind,
  from_support_id,
  to_support_id,
  from_traverse_id,
  to_traverse_id,
  end_a_geom,
  end_b_geom,
  sag_m
)
SELECT
  cb.brand_id,
  pl.line_id,
  v.k::conductor_kind,
  sf.support_id,
  st.support_id,
  tf.traverse_id,
  tt.traverse_id,
  sf.base_geom,
  st.base_geom,
  v.sag
FROM (VALUES
  ('ВЛ-110 «Ржев — Зубцов»', 1, 'wire', 1.2::NUMERIC, 'АС-185/29'),
  ('ВЛ-110 «Ржев — Зубцов»', 2, 'wire', 1.4::NUMERIC, 'АС-185/29'),
  ('ВЛ-220 «Чудово — Малая Вишера»', 1, 'wire', 2.1::NUMERIC, 'АС-400/51'),
  ('ВЛ-220 «Чудово — Малая Вишера»', 2, 'wire', 2.0::NUMERIC, 'АС-400/51'),
  ('ВЛ-500 «Астана — Щучинск»', 1, 'cable', 8.5::NUMERIC, 'АСК-600'),
  ('ВЛ-500 «Астана — Щучинск»', 2, 'cable', 8.2::NUMERIC, 'АСК-600')
) AS v(line_name, seq_from, k, sag, brand_name)
JOIN power_lines pl ON pl.name = v.line_name
JOIN conductor_brands cb ON cb.name = v.brand_name
JOIN supports sf ON sf.line_id = pl.line_id AND sf.seq_no = v.seq_from
JOIN supports st ON st.line_id = pl.line_id AND st.seq_no = v.seq_from + 1
JOIN traverses tf ON tf.support_id = sf.support_id
JOIN traverses tt ON tt.support_id = st.support_id;

INSERT INTO insulators (support_id, insulator_type, material_id, strings_count)
SELECT s.support_id, v.tip::insulator_type, m.material_id, v.n
FROM (VALUES
  ('ВЛ-110 «Ржев — Зубцов»', 'ТВ-110-1', 'hanging_row', 'Фарфор', 2),
  ('ВЛ-110 «Ржев — Зубцов»', 'АН-110-2', 'tension_string', 'Полимер', 2),
  ('ВЛ-220 «Чудово — Малая Вишера»', 'ТВ-220-B', 'hanging_row', 'Фарфор', 3)
) AS v(line_name, ciph, tip, mat, n)
JOIN power_lines pl ON pl.name = v.line_name
JOIN supports s ON s.line_id = pl.line_id AND s.cipher = v.ciph
JOIN materials m ON m.name = v.mat AND m.application_area = 'insulator';

INSERT INTO documents (title, doc_kind, storage_uri, valid_from, meta) VALUES
  ('Проектная документация трассы', 'project', 's3://docs/pl/110-rz-zub.pdf', '1997-01-15',
   '{"registry_number": "ПД-1997-14", "author": "Институт Энергосеть"}'),
  ('Паспорт опоры', 'passport', 's3://docs/supports/AN-110-2.pdf', '1998-06-01',
   '{"registry_number": "ПС-8821"}'),
  ('Протокол испытаний провода', 'protocol', 's3://docs/wire/test-as185.pdf', '2020-03-10',
   '{"registry_number": "ИС-220", "lab": "Центральная лаборатория"}');

INSERT INTO documents_power_lines (document_id, line_id)
SELECT d.document_id, pl.line_id
FROM documents d
CROSS JOIN power_lines pl
WHERE d.title = 'Проектная документация трассы' AND pl.name = 'ВЛ-110 «Ржев — Зубцов»';

INSERT INTO documents_supports (document_id, support_id)
SELECT d.document_id, s.support_id
FROM documents d
JOIN supports s ON s.cipher = 'АН-110-2'
WHERE d.title = 'Паспорт опоры';

INSERT INTO documents_conductors (document_id, conductor_id)
SELECT d.document_id, c.conductor_id
FROM documents d
CROSS JOIN LATERAL (
  SELECT cnd.conductor_id
  FROM conductors cnd
  JOIN conductor_brands cb ON cb.brand_id = cnd.conductor_brand_id
  WHERE cnd.kind = 'wire' AND cb.name = 'АС-185/29'
  ORDER BY cnd.conductor_id
  LIMIT 1
) c
WHERE d.title = 'Протокол испытаний провода';

INSERT INTO line_current_measurements (line_id, measured_at, current_a, frequency_hz, note)
SELECT pl.line_id, t.ts::TIMESTAMPTZ, t.ia, 50.0, t.nt
FROM (VALUES
  ('ВЛ-110 «Ржев — Зубцов»', '2026-04-01 08:00:00+03', 185.5, 'Утренний замер'),
  ('ВЛ-110 «Ржев — Зубцов»', '2026-04-01 20:00:00+03', 142.0, 'Вечерний спад нагрузки'),
  ('ВЛ-220 «Чудово — Малая Вишера»', '2026-04-01 10:30:00+03', 420.0, 'Номинальный режим'),
  ('ВЛ-500 «Астана — Щучинск»', '2026-04-01 12:00:00+03', 1150.0, 'Пик нагрузки региона')
) AS t(line_name, ts, ia, nt)
JOIN power_lines pl ON pl.name = t.line_name;

INSERT INTO outages (line_id, started_at, ended_at, reason, current_before_a)
SELECT pl.line_id, v.started::TIMESTAMPTZ, v.ended::TIMESTAMPTZ, v.reason, v.cur
FROM (VALUES
  ('ВЛ-110 «Ржев — Зубцов»', '2025-11-10 09:00:00+03', '2025-11-10 15:00:00+03', 'Плановые работы на подстанции', 90.0::NUMERIC),
  ('ВЛ-220 «Чудово — Малая Вишера»', '2026-03-20 07:00:00+03', NULL, 'Устранение повреждения изоляции (в работе)', 400.0::NUMERIC),
  ('ВЛ-500 «Астана — Щучинск»', '2025-08-01 00:00:00+03', '2025-08-02 04:00:00+03', 'Грозовое отключение', 980.0::NUMERIC)
) AS v(line_name, started, ended, reason, cur)
JOIN power_lines pl ON pl.name = v.line_name;
