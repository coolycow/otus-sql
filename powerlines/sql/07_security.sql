-- Управление доступом: роли и привилегии (требование курса).
-- Выполнять после создания схемы и объектов. Имена ролей можно изменить при необходимости.

-- Роль «только чтение»: отчёты, аналитика, реплики приложений без права менять данные.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'powerlines_readonly') THEN
    CREATE ROLE powerlines_readonly NOLOGIN;
  END IF;
END
$$;

COMMENT ON ROLE powerlines_readonly IS 'SELECT по всем объектам схемы public для отчётов.';

-- Роль приложения: чтение и изменение данных (без DDL).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'powerlines_app') THEN
    CREATE ROLE powerlines_app NOLOGIN;
  END IF;
END
$$;

COMMENT ON ROLE powerlines_app IS 'Типичные права бэкенда: SELECT/INSERT/UPDATE/DELETE.';

-- Права на схему и существующие таблицы/последовательности.
GRANT USAGE ON SCHEMA public TO powerlines_readonly;
GRANT USAGE ON SCHEMA public TO powerlines_app;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO powerlines_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO powerlines_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO powerlines_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO powerlines_app;

-- Новые таблицы после миграций автоматически получат те же права.
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO powerlines_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO powerlines_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO powerlines_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO powerlines_app;

-- Функции: отчётные роли и приложение могут вызывать их из SELECT и процедур.
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO powerlines_readonly;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO powerlines_app;

-- Процедуры (CALL) — только у роли приложения.
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO powerlines_app;
