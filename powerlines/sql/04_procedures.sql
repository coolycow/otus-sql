-- Хранимые процедуры для управления данными и аналитики (вызов через CALL).

-- Регистрация нового отключения: фиксируем время начала и опционально ток до отключения.
CREATE OR REPLACE PROCEDURE sp_register_outage(
  IN p_line_id BIGINT,
  IN p_reason TEXT,
  IN p_current_before_a NUMERIC DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO outages (line_id, started_at, reason, current_before_a)
  VALUES (p_line_id, now(), p_reason, p_current_before_a);
END;
$$;

COMMENT ON PROCEDURE sp_register_outage IS 'Диспетчер вносит новое отключение по линии.';

-- Закрытие отключения по идентификатору.
CREATE OR REPLACE PROCEDURE sp_close_outage(IN p_outage_id BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE outages
  SET ended_at = now()
  WHERE outage_id = p_outage_id AND ended_at IS NULL;
END;
$$;

COMMENT ON PROCEDURE sp_close_outage IS 'Фиксирует окончание ремонта или ввода линии в работу.';

-- Добавление замера тока с привязкой ко времени (по умолчанию — текущий момент).
CREATE OR REPLACE PROCEDURE sp_add_current_measurement(
  IN p_line_id BIGINT,
  IN p_current_a NUMERIC,
  IN p_measured_at TIMESTAMPTZ DEFAULT now(),
  IN p_note TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO line_current_measurements (line_id, measured_at, current_a, note)
  VALUES (p_line_id, p_measured_at, p_current_a, p_note);
END;
$$;

COMMENT ON PROCEDURE sp_add_current_measurement IS 'Загрузка телеметрии или ручного замера тока по ВЛ.';

-- Привязка уже созданного документа к ВЛ (связь многие-ко-многим).
CREATE OR REPLACE PROCEDURE sp_link_document_to_line(
  IN p_document_id BIGINT,
  IN p_line_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO documents_power_lines (document_id, line_id)
  VALUES (p_document_id, p_line_id)
  ON CONFLICT DO NOTHING;
END;
$$;

COMMENT ON PROCEDURE sp_link_document_to_line IS 'Добавляет связь «документ — воздушная линия» без дублирования.';

-- Пересчёт поля length_km по сумме расстояний между соседними опорами (оценка трассы).
CREATE OR REPLACE PROCEDURE sp_recalculate_line_length_km(IN p_line_id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
  r_prev RECORD;
  r_curr RECORD;
  acc      NUMERIC := 0;
BEGIN
  FOR r_curr IN
    SELECT support_id, base_geom, seq_no
    FROM supports
    WHERE line_id = p_line_id
    ORDER BY seq_no
  LOOP
    IF r_prev IS NOT NULL THEN
      acc := acc + fn_distance_km_wgs84(r_prev.base_geom, r_curr.base_geom);
    END IF;
    r_prev := r_curr;
  END LOOP;

  UPDATE power_lines
  SET length_km = acc,
      updated_at = now()
  WHERE line_id = p_line_id;
END;
$$;

COMMENT ON PROCEDURE sp_recalculate_line_length_km IS 'Обновляет длину ВЛ в справочнике по координатам опор (оценка по прямым пролётам).';
