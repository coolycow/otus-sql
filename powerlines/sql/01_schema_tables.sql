-- Схема БД информационной системы электросетевой компании (PostgreSQL 18).
-- Таблицы приведены к 3НФ: справочники вынесены, повторяющиеся данные не дублируются.
-- Геоданные — PostGIS: точки в SRID 4326 (WGS84), тип geometry(Point, 4326).
-- Расширенные атрибуты линии — в JSONB.
-- Требуется расширение PostGIS.
-- Ко всем таблицам добавлены комментарии, описывающие их назначение (чтобы не забыть, плюс удобно смотреть в том же DBeaver).
-- Дополнительно комментарии добавлены к сложным столбцам (чтобы не забыть, плюс удобно смотреть в том же DBeaver).

-------------------------------------------------- Создание пользователя (код из pgAdmin 4) --------------------------------------------------
-- DROP ROLE IF EXISTS powerlines;

CREATE ROLE powerlines WITH
  LOGIN
  SUPERUSER
  INHERIT
  CREATEDB
  CREATEROLE
  NOREPLICATION
  BYPASSRLS
  ENCRYPTED PASSWORD 'SCRAM-SHA-256$4096:5JJ8nfMbtAFXNXqicMCfdw==$VixJsiOWTQ/gromhBzyAWbWjamB9jFFukKk7sC+Bczo=:vjsQ4TDARnHynG+Pay+JOhBahEnbCffLoNLMhy3Ni1M=';

-------------------------------------------------- Создание базы данных (код из pgAdmin 4) --------------------------------------------------
-- DROP DATABASE IF EXISTS powerlines;

CREATE DATABASE powerlines
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Russia.1251'
    LC_CTYPE = 'Russian_Russia.1251'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

GRANT TEMPORARY, CONNECT ON DATABASE powerlines TO PUBLIC;

GRANT ALL ON DATABASE powerlines TO postgres;

GRANT TEMPORARY ON DATABASE powerlines TO powerlines;

-------------------------------------------------- Установка расширений --------------------------------------------------

-- Установка расширения PostGIS.
CREATE EXTENSION IF NOT EXISTS postgis;

-------------------------------------------------- Домены (чтобы не плодить ненужные таблицы) --------------------------------------------------
-- Типы опор: промежуточная / анкерная.
CREATE DOMAIN support_kind AS TEXT
  CHECK (VALUE IN ('intermediate', 'anchor'));

-- Тип проводника: провод или трос.
CREATE DOMAIN conductor_kind AS TEXT
  CHECK (VALUE IN ('wire', 'cable'));

-- Тип документа: проект, паспорт, протокол и т.п.
CREATE DOMAIN document_kind AS TEXT
  CHECK (VALUE IN ('project', 'passport', 'protocol', 'other'));

-- Тип изолятора: подвесной ряд, натяжной, штыревой и т.п.
CREATE DOMAIN insulator_type AS TEXT
  CHECK (VALUE IN ('hanging_row', 'tension_string', 'post', 'other'));

-------------------------------------------------- Страна и регионы --------------------------------------------------
CREATE TABLE countries (
  country_id   BIGSERIAL PRIMARY KEY, -- идентификатор страны
  name         TEXT NOT NULL UNIQUE, -- название страны
  iso_code     CHAR(2) NOT NULL UNIQUE, -- код страны по ISO 3166-1
  UNIQUE (name, iso_code) -- уникальность страны по названию и коду
);

CREATE TABLE regions (
  region_id    BIGSERIAL PRIMARY KEY,
  country_id   BIGINT NOT NULL REFERENCES countries (country_id) ON DELETE RESTRICT, -- страна региона
  name         TEXT NOT NULL, -- название региона
  UNIQUE (country_id, name) -- уникальность региона в стране
);

COMMENT ON TABLE countries IS 'Справочник стран для привязки линий к территории.';
COMMENT ON TABLE regions IS 'Регионы внутри страны; у одной страны названия регионов не повторяются.';

------------------------------------------------- Материалы -------------------------------------------------
CREATE TABLE materials (
  material_id       BIGSERIAL PRIMARY KEY, -- идентификатор материала
  name              TEXT NOT NULL, -- железобетон, сталь, фарфор, полимер, смешанный и т.п.
  application_area  TEXT NOT NULL CHECK (application_area IN ('support', 'insulator', 'conductor', 'cable', 'other')), -- область применения материала
  UNIQUE (name, application_area) -- уникальность материала в области применения
);

COMMENT ON TABLE materials IS 'Материалы конструкций; область: опора, изолятор или прочее.';

------------------------------------------------- Воздушные линии электропередачи (ВЛ) -------------------------------------------------
CREATE TABLE power_lines (
  line_id          BIGSERIAL PRIMARY KEY, -- идентификатор линии
  region_id        BIGINT NOT NULL REFERENCES regions (region_id) ON DELETE RESTRICT, -- регион линии
  name             TEXT NOT NULL, -- имя линии
  description      TEXT, -- описание линии
  voltage_kv       NUMERIC(6, 2) NOT NULL CHECK (voltage_kv > 0), -- класс напряжения
  length_km        NUMERIC(10, 3), -- длина линии (статистический параметр, оценка по координатам опор)
  commissioned_at  DATE, -- дата ввода в эксплуатацию
  extra_spec       JSONB DEFAULT '{}'::JSONB, -- дополнительные параметры в JSON
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(), -- дата создания
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(), -- дата последнего обновления
  UNIQUE (region_id, name) -- уникальность линии в регионе
);

COMMENT ON TABLE power_lines IS 'ВЛ: регион, имя, описание, класс напряжения; extra_spec — доп. параметры в JSON.';
COMMENT ON COLUMN power_lines.extra_spec IS 'Гибкие атрибуты (количество цепей, особенности) без лишних столбцов.';

------------------------------------------------- Опоры на трассе ВЛ -------------------------------------------------
CREATE TABLE supports (
  support_id    BIGSERIAL PRIMARY KEY, -- идентификатор опоры
  line_id       BIGINT NOT NULL REFERENCES power_lines (line_id) ON DELETE CASCADE, -- линия, к которой принадлежит опора
  material_id   BIGINT NOT NULL REFERENCES materials (material_id) ON DELETE RESTRICT, -- материал опоры
  seq_no        INTEGER NOT NULL CHECK (seq_no > 0), -- порядковый номер опоры вдоль линии
  kind          support_kind NOT NULL, -- тип опоры (промежуточная/анкерная)
  cipher        TEXT NOT NULL, -- шифр опоры
  pole_number   TEXT, -- номер опоры (написан на самой опоре, например 12А, 17Б, 157В и т.п.)
  base_geom     geometry(Point, 4326) NOT NULL, -- координаты базовой точки опоры (точка WGS84)
  vertex_geom   geometry(Point, 4326), -- координаты вершины опоры (точка WGS84)
  note          TEXT, -- примечание (например, дата последнего ремонта, отметка о пожаре и т.п.)
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(), -- дата создания
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(), -- дата последнего обновления
  UNIQUE (line_id, seq_no), -- уникальность опоры по линии и порядковому номеру
  UNIQUE (line_id, cipher) -- уникальность опоры по линии и шифру
);

COMMENT ON TABLE supports IS 'Опоры ВЛ: тип, материал, шифр, номер; геометрия точек в PostGIS (SRID 4326).';
COMMENT ON COLUMN supports.base_geom IS 'Координаты базы опоры (точка WGS84).';
COMMENT ON COLUMN supports.vertex_geom IS 'Вершина головы опоры, если учитывается в модели.';

------------------------------------------------- Траверсы на опоре -------------------------------------------------
CREATE TABLE traverses (
  traverse_id   BIGSERIAL PRIMARY KEY, -- идентификатор траверсы
  support_id    BIGINT NOT NULL REFERENCES supports (support_id) ON DELETE CASCADE, -- опора, к которой принадлежит траверса
  material_id   BIGINT NOT NULL REFERENCES materials (material_id) ON DELETE RESTRICT, -- материал траверсы
  label         TEXT, -- метка траверсы (например, ТВ-110-1, АН-110-2, ТВ-220-B и т.п.)
  end_a_geom    geometry(Point, 4326) NOT NULL, -- координаты начала траверсы (точка WGS84)
  end_b_geom    geometry(Point, 4326) NOT NULL, -- координаты конца траверсы (точка WGS84)
  rotation_deg  NUMERIC(6, 2), -- угол разворота траверсы относительно трассы (в градусах)
  UNIQUE (support_id, label) -- уникальность траверсы по опоре и метке
);

COMMENT ON TABLE traverses IS 'Траверса на опоре: концы в WGS84 и угол разворота относительно трассы.';

------------------------------------------------- Марки проводов и тросов -------------------------------------------------
CREATE TABLE conductor_brands (
  brand_id    BIGSERIAL PRIMARY KEY, -- идентификатор марки проводника
  material_id BIGINT NOT NULL REFERENCES materials (material_id) ON DELETE RESTRICT, -- материал проводника
  name        TEXT NOT NULL, -- название марки проводника (например, АС-185/29, АСК-600 и т.п.)
  section_mm2 NUMERIC(8, 2) NOT NULL, -- сечение проводника (в квадратных миллиметрах)
  UNIQUE (name) -- уникальность марки проводника по названию
);

COMMENT ON TABLE conductor_brands IS 'Марки проводников: уникальные названия без лишних столбцов.';

------------------------------------------------- Провода и тросы на пролёте между двумя опорами -------------------------------------------------
CREATE TABLE conductors (
  conductor_id    BIGSERIAL PRIMARY KEY, -- идентификатор проводника
  conductor_brand_id BIGINT NOT NULL REFERENCES conductor_brands (brand_id) ON DELETE RESTRICT, -- марка проводника
  line_id         BIGINT NOT NULL REFERENCES power_lines (line_id) ON DELETE CASCADE, -- линия, к которой принадлежит проводник
  from_support_id BIGINT NOT NULL REFERENCES supports (support_id) ON DELETE RESTRICT, -- опора, с которой начинается проводник
  to_support_id   BIGINT NOT NULL REFERENCES supports (support_id) ON DELETE RESTRICT, -- опора, на которой заканчивается проводник
  from_traverse_id BIGINT NOT NULL REFERENCES traverses (traverse_id) ON DELETE CASCADE, -- траверса, с которой начинается проводник
  to_traverse_id   BIGINT NOT NULL REFERENCES traverses (traverse_id) ON DELETE CASCADE, -- траверса, на которой заканчивается проводник
  kind            conductor_kind NOT NULL, -- тип проводника (провод или трос)
  end_a_geom      geometry(Point, 4326) NOT NULL, -- координаты начала проводника (точка WGS84)
  end_b_geom      geometry(Point, 4326) NOT NULL, -- координаты конца проводника (точка WGS84)
  sag_m           NUMERIC(8, 3), -- стрела провеса проводника (в метрах)
  CHECK (from_support_id <> to_support_id AND from_traverse_id <> to_traverse_id) -- проверка, что опора начала не равна опоре конца и траверса начала не равна траверсе конца  
);

COMMENT ON TABLE conductors IS 'Провод или трос: пролёт между опорами той же ВЛ; концы пролёта — точки WGS84, стрела провеса, марка.';

------------------------------------------------- Изоляторы на опоре -------------------------------------------------
CREATE TABLE insulators (
  insulator_id    BIGSERIAL PRIMARY KEY, -- идентификатор изолятора
  support_id      BIGINT NOT NULL REFERENCES supports (support_id) ON DELETE CASCADE, -- опора, к которой принадлежит изолятор
  insulator_type  insulator_type NOT NULL, -- тип изолятора
  material_id     BIGINT NOT NULL REFERENCES materials (material_id) ON DELETE RESTRICT, -- материал изолятора
  strings_count   INTEGER NOT NULL DEFAULT 1 CHECK (strings_count > 0), -- количество гирлянд/цепочек изоляторов
  note            TEXT -- примечание (например, дата последнего ремонта, отметка о пожаре и т.п.)
);

COMMENT ON TABLE insulators IS 'Изоляторы на опоре: тип, материал, число гирлянд/цепочек.';

------------------------------------------------- Документы -------------------------------------------------
CREATE TABLE documents (
  document_id   BIGSERIAL PRIMARY KEY, -- идентификатор документа
  title         TEXT NOT NULL, -- название документа
  doc_kind      document_kind NOT NULL, -- тип документа (например, проект, паспорт, протокол и т.п.)
  storage_uri   TEXT, -- URI хранилища (например, s3://docs/pl/110-rz-zub.pdf)
  valid_from    DATE, -- дата начала действия документа
  meta          JSONB DEFAULT '{}'::JSONB, -- дополнительные метаданные в формате JSON
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now() -- дата создания
);

COMMENT ON TABLE documents IS 'Учёт документации: заголовок, тип, ссылка на хранилище, произвольные поля в JSON.';
COMMENT ON COLUMN documents.meta IS 'Доп. атрибуты (номер дела, регистрация) в формате JSON.';

------------------------------------------------- Связи документов с ВЛ, опорами и проводниками -------------------------------------------------
CREATE TABLE documents_power_lines (
  document_id  BIGINT NOT NULL REFERENCES documents (document_id) ON DELETE CASCADE,
  line_id      BIGINT NOT NULL REFERENCES power_lines (line_id) ON DELETE CASCADE,
  PRIMARY KEY (document_id, line_id)
);

COMMENT ON TABLE documents_power_lines IS 'Связь документов с ВЛ (многие ко многим).';

CREATE TABLE documents_supports (
  document_id  BIGINT NOT NULL REFERENCES documents (document_id) ON DELETE CASCADE,
  support_id   BIGINT NOT NULL REFERENCES supports (support_id) ON DELETE CASCADE,
  PRIMARY KEY (document_id, support_id)
);

COMMENT ON TABLE documents_supports IS 'Связь документов с опорами.';

CREATE TABLE documents_conductors (
  document_id   BIGINT NOT NULL REFERENCES documents (document_id) ON DELETE CASCADE,
  conductor_id  BIGINT NOT NULL REFERENCES conductors (conductor_id) ON DELETE CASCADE,
  PRIMARY KEY (document_id, conductor_id)
);

COMMENT ON TABLE documents_conductors IS 'Связь документов с проводами/тросами.';

------------------------------------------------- Замеры тока по ВЛ и учёт отключений -------------------------------------------------
CREATE TABLE line_current_measurements (
  measurement_id BIGSERIAL PRIMARY KEY, -- идентификатор замера тока
  line_id        BIGINT NOT NULL REFERENCES power_lines (line_id) ON DELETE CASCADE, -- линия, по которой замеряется ток
  measured_at    TIMESTAMPTZ NOT NULL DEFAULT now(), -- дата и время замера
  current_a      NUMERIC(12, 3) NOT NULL, -- ток в амперах
  frequency_hz   NUMERIC(5, 2) DEFAULT 50, -- частота в герцах
  note           TEXT -- примечание (например, дата последнего ремонта, отметка о пожаре и т.п.)
);

COMMENT ON TABLE line_current_measurements IS 'Параметры режима: ток по ВЛ, время замера, примечание.';

CREATE TABLE outages (
  outage_id        BIGSERIAL PRIMARY KEY, -- идентификатор отключения
  line_id          BIGINT NOT NULL REFERENCES power_lines (line_id) ON DELETE CASCADE, -- линия, на которой произошло отключение
  started_at       TIMESTAMPTZ NOT NULL, -- дата и время начала отключения, не может быть NULL
  ended_at         TIMESTAMPTZ, -- дата и время окончания отключения, может быть NULL если отключение не завершено
  reason           TEXT, -- причина отключения (например, плановые работы, авария, пожаром и т.п.)
  current_before_a NUMERIC(12, 3), -- ток до события (для анализа)
  CHECK (ended_at IS NULL OR ended_at >= started_at) -- проверка, что дата окончания не меньше даты начала
);

COMMENT ON TABLE outages IS 'Отключения ВЛ: интервал, причина, ток до события (для анализа).';

------------------------------------------------- Журнал событий для аудита -------------------------------------------------
-- Самостоятельная таблица для журнала событий для аудита.
-- Никак не связана с другими таблицами, в неё триггер пишет текстовые записи о событиях.
CREATE TABLE audit_log (
  log_id       BIGSERIAL PRIMARY KEY, -- идентификатор события
  event_time   TIMESTAMPTZ NOT NULL DEFAULT now(), -- дата и время события
  table_name   TEXT NOT NULL, -- название таблицы
  record_id    BIGINT, -- идентификатор записи
  action       TEXT NOT NULL, -- действие (INSERT, UPDATE, DELETE)
  details      TEXT -- примечание (например, дата последнего ремонта, отметка о пожаре и т.п.)
);

COMMENT ON TABLE audit_log IS 'Простой журнал изменений для контроля и отладки интеграций.';
