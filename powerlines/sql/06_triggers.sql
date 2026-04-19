-- Триггеры: автоматические проверки и сопутствующие действия (вызов через BEFORE/AFTER INSERT/UPDATE/DELETE).

-- Целостность пролёта: опоры и траверсы на той же ВЛ; траверсы привязаны к своим опорам.
CREATE OR REPLACE FUNCTION tf_conductors_integrity()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_from_line  BIGINT;
  v_to_line    BIGINT;
  v_ft_support BIGINT;
  v_tt_support BIGINT;
BEGIN
  SELECT line_id INTO v_from_line FROM supports WHERE support_id = NEW.from_support_id;
  SELECT line_id INTO v_to_line FROM supports WHERE support_id = NEW.to_support_id;

  IF v_from_line IS NULL OR v_to_line IS NULL THEN
    RAISE EXCEPTION 'Опора не найдена';
  END IF;

  IF v_from_line <> NEW.line_id OR v_to_line <> NEW.line_id THEN
    RAISE EXCEPTION 'Опоры пролёта должны принадлежать той же ВЛ (line_id), что и проводник';
  END IF;

  SELECT support_id INTO v_ft_support FROM traverses WHERE traverse_id = NEW.from_traverse_id;
  SELECT support_id INTO v_tt_support FROM traverses WHERE traverse_id = NEW.to_traverse_id;

  IF v_ft_support IS NULL OR v_tt_support IS NULL THEN
    RAISE EXCEPTION 'Траверса не найдена';
  END IF;

  IF v_ft_support <> NEW.from_support_id THEN
    RAISE EXCEPTION 'Начальная траверса должна принадлежать опоре начала пролёта';
  END IF;

  IF v_tt_support <> NEW.to_support_id THEN
    RAISE EXCEPTION 'Конечная траверса должна принадлежать опоре конца пролёта';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_conductors_supports_same_line ON conductors;

CREATE TRIGGER tr_conductors_integrity
  BEFORE INSERT OR UPDATE OF line_id, from_support_id, to_support_id, from_traverse_id, to_traverse_id
  ON conductors
  FOR EACH ROW
  EXECUTE PROCEDURE tf_conductors_integrity();

COMMENT ON TRIGGER tr_conductors_integrity ON conductors IS
  'Проверяет согласование ВЛ, опор и траверс для пролёта.';

-- При изменении опор обновляем метку времени у родительской ВЛ (для кэшей и аудита).
CREATE OR REPLACE FUNCTION tf_supports_touch_power_line()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_line BIGINT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_line := OLD.line_id;
  ELSE
    v_line := NEW.line_id;
  END IF;

  UPDATE power_lines SET updated_at = now() WHERE line_id = v_line;
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_supports_touch_power_line ON supports;
CREATE TRIGGER tr_supports_touch_power_line
  AFTER INSERT OR UPDATE OR DELETE ON supports
  FOR EACH ROW
  EXECUTE PROCEDURE tf_supports_touch_power_line();

COMMENT ON TRIGGER tr_supports_touch_power_line ON supports IS
  'Пробрасывает изменение опор в updated_at ВЛ.';

-- Журнал: каждое новое отключение пишется в audit_log для последующего разбора.
CREATE OR REPLACE FUNCTION tf_outages_write_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO audit_log (table_name, record_id, action, details)
  VALUES (
    'outages',
    NEW.outage_id,
    'INSERT',
    'Отключение линии id=' || NEW.line_id::TEXT
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_outages_audit ON outages;
CREATE TRIGGER tr_outages_audit
  AFTER INSERT ON outages
  FOR EACH ROW
  EXECUTE PROCEDURE tf_outages_write_audit();

COMMENT ON TRIGGER tr_outages_audit ON outages IS 'Фиксирует факт регистрации отключения в журнале.';

-- Удаляем старую функцию с прежним именем, если осталась от прошлой версии скрипта.
DROP FUNCTION IF EXISTS tf_conductors_supports_same_line();
