-- Индексы для ускорения типовых выборок и ограничений по JSON.
-- Для PostGIS — GiST по геометрии (поиск по охвату, пересечения, ближайшие объекты).

-- Поиск регионов по стране (иерархия в отчётах).
CREATE INDEX idx_regions_country_id ON regions (country_id);

-- Все ВЛ региона — частый фильтр.
CREATE INDEX idx_power_lines_region_id ON power_lines (region_id);

-- Опоры вдоль линии: сортировка по порядковому номеру.
CREATE INDEX idx_supports_line_seq ON supports (line_id, seq_no);

-- GiST: точка базы опоры — типичные запросы «объекты в прямоугольнике / рядом с линией».
CREATE INDEX idx_supports_base_geom ON supports USING GIST (base_geom);

-- GiST по концам пролёта проводника (аналитика трасс и пересечений).
CREATE INDEX idx_conductors_end_a ON conductors USING GIST (end_a_geom);

-- Справочник марок и связи проводников.
CREATE INDEX idx_conductor_brands_material_id ON conductor_brands (material_id);
CREATE INDEX idx_conductors_brand_id ON conductors (conductor_brand_id);
CREATE INDEX idx_conductors_from_traverse ON conductors (from_traverse_id);
CREATE INDEX idx_conductors_to_traverse ON conductors (to_traverse_id);

-- Траверсы: опора и материал (подбор по линии / спецификации).
CREATE INDEX idx_traverses_support_id ON traverses (support_id);
CREATE INDEX idx_traverses_material_id ON traverses (material_id);

-- Проводники и измерения по ВЛ.
CREATE INDEX idx_conductors_line_id ON conductors (line_id);
CREATE INDEX idx_line_current_line_time ON line_current_measurements (line_id, measured_at DESC);

-- Только «активные» отключения — уменьшает размер индекса для диспетчерских экранов.
CREATE INDEX idx_outages_open ON outages (line_id) WHERE ended_at IS NULL;

-- GIN по JSONB: ускоряет поиск по ключам в extra_spec и meta (оптимизация под аналитику).
CREATE INDEX idx_power_lines_extra_spec_gin ON power_lines USING GIN (extra_spec);
CREATE INDEX idx_documents_meta_gin ON documents USING GIN (meta);

-- Комментарии к индексам.
COMMENT ON INDEX idx_outages_open IS 'Частичный индекс: только незакрытые отключения — меньше страниц при скане.';
COMMENT ON INDEX idx_supports_base_geom IS 'GiST по точке опоры — ускоряет пространственные фильтры PostGIS.';
COMMENT ON INDEX idx_conductors_end_a IS 'GiST по началу пролёта — для геозапросов по проводникам.';
