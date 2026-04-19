-- Пользовательские функции для упрощения запросов и аналитики (вызов через CALL).

-- Расстояние между двумя точками WGS84 в километрах (эллипсоид WGS84 через geography).
-- Обёртка над PostGIS вместо ручной формулы гаверсинусов.
CREATE OR REPLACE FUNCTION fn_distance_km_wgs84(p_geom1 geometry, p_geom2 geometry)
RETURNS NUMERIC
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
  SELECT round((ST_Distance(p_geom1::geography, p_geom2::geography) / 1000.0)::NUMERIC, 6);
$$;

COMMENT ON FUNCTION fn_distance_km_wgs84(geometry, geometry) IS
  'Расстояние между точками SRID 4326 в км (ST_Distance по geography — современный учёт эллипсоида).';

-- Сколько опор числится на указанной ВЛ.
CREATE OR REPLACE FUNCTION fn_support_count_for_line(p_line_id BIGINT)
RETURNS BIGINT
LANGUAGE SQL
STABLE
AS $$
  SELECT count(*)::BIGINT FROM supports WHERE line_id = p_line_id;
$$;

COMMENT ON FUNCTION fn_support_count_for_line IS 'Быстрый подсчёт опор по линии для карточек ВЛ и проверок полноты данных.';

-- Заголовок документа с подстановкой номера из JSON meta, если он задан (для печати списков).
CREATE OR REPLACE FUNCTION fn_document_display_title(p_document_id BIGINT)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_title TEXT;
  v_reg   TEXT;
  v_meta  JSONB;
BEGIN
  SELECT title, meta INTO v_title, v_meta FROM documents WHERE document_id = p_document_id;
  IF v_title IS NULL THEN
    RETURN NULL;
  END IF;
  v_reg := v_meta ->> 'registry_number';
  IF v_reg IS NOT NULL AND v_reg <> '' THEN
    RETURN v_title || ' № ' || v_reg;
  END IF;
  RETURN v_title;
END;
$$;

COMMENT ON FUNCTION fn_document_display_title IS 'Человекочитаемый заголовок: название и регистрационный номер из JSON при наличии.';
