-- СГЕНЕРИРОВАНО ИИ-АГЕНТОМ
-- Наполнение БД искусственными данными (запускать после DDL и сидов из queries.sql).
-- Объём по умолчанию: ~8k клиентов, ~35k фильмов, ~2.5M аренд.
-- Часть аренд с rental_date в [2021-01-01, 2022-12-31] для проверки индексов на больших данных.

BEGIN;

INSERT INTO customers (first_name, last_name, email, phone_number, address, registration_date, preferences)
SELECT
    'c' || gs::text,
    'u' || gs::text,
    'c' || gs::text || '@bulk.local',
    lpad((gs % 10000000000)::text, 10, '0'),
    'addr ' || gs::text,
    DATE '2000-01-01' + ((gs * 7) % 9000),
    '{}'::jsonb
FROM generate_series(1, 8000) AS gs;

INSERT INTO movies (title, release_year, genre, rating, duration, description, additional_info)
SELECT
    'Synthetic movie ' || gs::text,
    1970 + (gs % 55),
    (ARRAY['Action', 'Drama', 'Sci-Fi', 'Comedy', 'Animation', 'Thriller', 'Romance'])[1 + (gs % 7)],
    (4.0 + (gs % 60) / 10.0)::numeric(2, 1),
    60 + (gs % 150),
    'desc ' || gs::text,
    '{}'::jsonb
FROM generate_series(1, 35000) AS gs;

WITH bounds AS (
    SELECT
        c.cmin,
        c.cmax,
        m.mmin,
        m.mmax
    FROM
        (SELECT MIN(customer_id) AS cmin, MAX(customer_id) AS cmax FROM customers) AS c,
        (SELECT MIN(movie_id) AS mmin, MAX(movie_id) AS mmax FROM movies) AS m
),
rows AS (
    SELECT
        b.cmin + floor(random() * (b.cmax - b.cmin + 1))::int AS customer_id,
        b.mmin + floor(random() * (b.mmax - b.mmin + 1))::int AS movie_id,
        CASE
            WHEN random() < 0.5 THEN
                DATE '2021-01-01'
                + floor(random() * (DATE '2022-12-31' - DATE '2021-01-01' + 1))::int
            ELSE
                DATE '2005-01-01'
                + floor(random() * (DATE '2020-12-31' - DATE '2005-01-01' + 1))::int
        END AS rental_date
    FROM
        generate_series(1, 2500000) AS g
        CROSS JOIN bounds AS b
)
INSERT INTO rentals (customer_id, movie_id, rental_date, return_date)
SELECT
    customer_id,
    movie_id,
    rental_date,
    rental_date + 1 + floor(random() * 14)::int AS return_date
FROM rows;

COMMIT;
