-- Исходный запрос (приведенный к правильному виду для PostgreSQL)
SELECT DISTINCT 
    c.customer_id,
    c.first_name, 
    c.last_name, 
    c.email, 
    c.registration_date,
    COALESCE(SUM(CASE WHEN r.return_date IS NULL THEN 1 ELSE 0 END), 0) AS active_rentals,
    (SELECT COUNT(DISTINCT m.movie_id) 
     FROM movies m
     JOIN rentals r2 ON m.movie_id = r2.movie_id
     WHERE r2.customer_id = c.customer_id
       AND m.genre = 'Drama') AS drama_movies_rented,
    (SELECT AVG(m2.rating) 
     FROM movies m2 
     JOIN rentals r3 ON m2.movie_id = r3.movie_id
     WHERE r3.customer_id = c.customer_id) AS avg_rating,
    (SELECT COUNT(r4.rental_id) 
     FROM rentals r4 
     WHERE r4.customer_id = c.customer_id 
       AND r4.rental_date BETWEEN '2021-01-01' AND '2022-12-31') AS rentals_last_two_years,
    MAX(r.return_date) AS last_rental_date,
    COUNT(r.rental_id) AS total_rentals,
    SUM(CASE WHEN m.genre = 'Action' THEN 1 ELSE 0 END) AS action_movies_rented
FROM 
    customers c
JOIN rentals r ON c.customer_id = r.customer_id
JOIN movies m ON r.movie_id = m.movie_id
WHERE 
    c.registration_date <= '2022-12-31'
    AND r.rental_date BETWEEN '2020-01-01' AND '2022-12-31'
GROUP BY 
    c.customer_id, c.first_name, c.last_name, c.email, c.registration_date
HAVING 
    COUNT(r.rental_id) > 10
ORDER BY 
    total_rentals DESC, last_rental_date DESC
LIMIT 50;

-- План выполнения исходного запроса
QUERY PLAN                                                                                                                                                                                                                                                     |
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=184.31..184.35 rows=1 width=1036) (actual time=0.111..0.112 rows=0.00 loops=1)                                                                                                                                                                    |
  Buffers: shared hit=62                                                                                                                                                                                                                                       |
  ->  Unique  (cost=184.31..184.35 rows=1 width=1036) (actual time=0.110..0.111 rows=0.00 loops=1)                                                                                                                                                             |
        Buffers: shared hit=62                                                                                                                                                                                                                                 |
        ->  Sort  (cost=184.31..184.32 rows=1 width=1036) (actual time=0.110..0.111 rows=0.00 loops=1)                                                                                                                                                         |
              Sort Key: (count(r.rental_id)) DESC, (max(r.return_date)) DESC, c.customer_id, c.first_name, c.last_name, c.email, c.registration_date, (COALESCE(sum(CASE WHEN (r.return_date IS NULL) THEN 1 ELSE 0 END), '0'::bigint)), ((SubPlan 1)), ((SubPl|
              Sort Method: quicksort  Memory: 25kB                                                                                                                                                                                                             |
              Buffers: shared hit=62                                                                                                                                                                                                                           |
              ->  GroupAggregate  (cost=46.73..184.30 rows=1 width=1036) (actual time=0.102..0.103 rows=0.00 loops=1)                                                                                                                                          |
                    Group Key: c.customer_id                                                                                                                                                                                                                   |
                    Filter: (count(r.rental_id) > 10)                                                                                                                                                                                                          |
                    Rows Removed by Filter: 30                                                                                                                                                                                                                 |
                    Buffers: shared hit=62                                                                                                                                                                                                                     |
                    ->  Nested Loop  (cost=46.73..59.30 rows=3 width=1186) (actual time=0.052..0.086 rows=30.00 loops=1)                                                                                                                                       |
                          Buffers: shared hit=62                                                                                                                                                                                                               |
                          ->  Merge Join  (cost=46.59..46.73 rows=3 width=972) (actual time=0.043..0.054 rows=30.00 loops=1)                                                                                                                                   |
                                Merge Cond: (c.customer_id = r.customer_id)                                                                                                                                                                                    |
                                Buffers: shared hit=2                                                                                                                                                                                                          |
                                ->  Sort  (cost=10.97..11.01 rows=17 width=960) (actual time=0.025..0.026 rows=31.00 loops=1)                                                                                                                                  |
                                      Sort Key: c.customer_id                                                                                                                                                                                                  |
                                      Sort Method: quicksort  Memory: 27kB                                                                                                                                                                                     |
                                      Buffers: shared hit=1                                                                                                                                                                                                    |
                                      ->  Seq Scan on customers c  (cost=0.00..10.62 rows=17 width=960) (actual time=0.014..0.018 rows=31.00 loops=1)                                                                                                          |
                                            Filter: (registration_date <= '2022-12-31'::date)                                                                                                                                                                  |
                                            Buffers: shared hit=1                                                                                                                                                                                              |
                                ->  Sort  (cost=35.62..35.64 rows=8 width=16) (actual time=0.017..0.018 rows=30.00 loops=1)                                                                                                                                    |
                                      Sort Key: r.customer_id                                                                                                                                                                                                  |
                                      Sort Method: quicksort  Memory: 25kB                                                                                                                                                                                     |
                                      Buffers: shared hit=1                                                                                                                                                                                                    |
                                      ->  Seq Scan on rentals r  (cost=0.00..35.50 rows=8 width=16) (actual time=0.009..0.012 rows=30.00 loops=1)                                                                                                              |
                                            Filter: ((rental_date >= '2020-01-01'::date) AND (rental_date <= '2022-12-31'::date))                                                                                                                              |
                                            Buffers: shared hit=1                                                                                                                                                                                              |
                          ->  Index Scan using movies_pkey on movies m  (cost=0.14..4.16 rows=1 width=222) (actual time=0.001..0.001 rows=1.00 loops=30)                                                                                                       |
                                Index Cond: (movie_id = r.movie_id)                                                                                                                                                                                            |
                                Index Searches: 30                                                                                                                                                                                                             |
                                Buffers: shared hit=60                                                                                                                                                                                                         |
                    SubPlan 1                                                                                                                                                                                                                                  |
                      ->  Aggregate  (cost=42.49..42.50 rows=1 width=8) (never executed)                                                                                                                                                                       |
                            ->  Sort  (cost=42.48..42.49 rows=1 width=4) (never executed)                                                                                                                                                                      |
                                  Sort Key: m_1.movie_id                                                                                                                                                                                                       |
                                  ->  Nested Loop  (cost=0.00..42.48 rows=1 width=4) (never executed)                                                                                                                                                          |
                                        Join Filter: (m_1.movie_id = r2.movie_id)                                                                                                                                                                              |
                                        ->  Seq Scan on movies m_1  (cost=0.00..11.12 rows=1 width=4) (never executed)                                                                                                                                         |
                                              Filter: ((genre)::text = 'Drama'::text)                                                                                                                                                                          |
                                        ->  Seq Scan on rentals r2  (cost=0.00..31.25 rows=8 width=4) (never executed)                                                                                                                                         |
                                              Filter: (customer_id = c.customer_id)                                                                                                                                                                            |
                    SubPlan 2                                                                                                                                                                                                                                  |
                      ->  Aggregate  (cost=42.65..42.66 rows=1 width=32) (never executed)                                                                                                                                                                      |
                            ->  Hash Join  (cost=31.35..42.63 rows=8 width=12) (never executed)                                                                                                                                                                |
                                  Hash Cond: (m2.movie_id = r3.movie_id)                                                                                                                                                                                       |
                                  ->  Seq Scan on movies m2  (cost=0.00..10.90 rows=90 width=16) (never executed)                                                                                                                                              |
                                  ->  Hash  (cost=31.25..31.25 rows=8 width=4) (never executed)                                                                                                                                                                |
                                        ->  Seq Scan on rentals r3  (cost=0.00..31.25 rows=8 width=4) (never executed)                                                                                                                                         |
                                              Filter: (customer_id = c.customer_id)                                                                                                                                                                            |
                    SubPlan 3                                                                                                                                                                                                                                  |
                      ->  Aggregate  (cost=39.75..39.76 rows=1 width=8) (never executed)                                                                                                                                                                       |
                            ->  Seq Scan on rentals r4  (cost=0.00..39.75 rows=1 width=4) (never executed)                                                                                                                                                     |
                                  Filter: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date) AND (customer_id = c.customer_id))                                                                                                      |
Planning:                                                                                                                                                                                                                                                      |
  Buffers: shared hit=99                                                                                                                                                                                                                                       |
Planning Time: 0.702 ms                                                                                                                                                                                                                                        |
Execution Time: 0.211 ms                                                                                                                                                                                                                                       |

-- Узкие места в производительности запроса:
-- 1. Seq Scan по rentals с фильтром по rental_date. На небольших таблицах не так страшно, но если количество аренд вырастет, то начнутся проблемы.
-- 2. Seq Scan по customers с фильтром registration_date. Как и в случае с rentals, на небольших таблицах не так страшно, но для больших - проблематично.
-- 3. Merge Join с двумя Sort по customer_id. Тут лишниые сортировки, опять же из-за отсутствия индекса на rentals (можно просто по customer_id, а лучше по customer_id и rental_date).
-- 4. Подзапросы SubPlan (1, 2, 3). Видим Seq Scan rentals по customer_id и Seq Scan movies по genre — без индексов.

-- Добавление индексов для решения проблемы производительности
-- Индекс для таблицы rentals по дате аренды (решение проблемы 1)
CREATE INDEX IF NOT EXISTS idx_rentals_rental_date ON rentals (rental_date);

-- Индекс для таблицы customers по дате регистрации (решение проблемы 2)
CREATE INDEX IF NOT EXISTS idx_customers_registration_date ON customers (registration_date);

-- Индекс для таблицы rentals по customer_id и дате аренды (решение проблемы 3)
CREATE INDEX IF NOT EXISTS idx_rentals_customer_rental_date ON rentals (customer_id, rental_date);

-- Индекс для таблицы rentals по customer_id и movie_id (решение проблемы 4)
CREATE INDEX IF NOT EXISTS idx_rentals_customer_movie ON rentals (customer_id, movie_id);

-- Индекс для таблицы movies по жанру (решение проблемы 4)
CREATE INDEX IF NOT EXISTS idx_movies_genre ON movies (genre);

-- План выполнения запроса после добавления индексов:
QUERY PLAN                                                                                                                                                                                                                                                     |
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=14.54..14.57 rows=1 width=1036) (actual time=0.102..0.103 rows=0.00 loops=1)                                                                                                                                                                      |
  Buffers: shared hit=4                                                                                                                                                                                                                                        |
  ->  Unique  (cost=14.54..14.57 rows=1 width=1036) (actual time=0.101..0.102 rows=0.00 loops=1)                                                                                                                                                               |
        Buffers: shared hit=4                                                                                                                                                                                                                                  |
        ->  Sort  (cost=14.54..14.54 rows=1 width=1036) (actual time=0.101..0.102 rows=0.00 loops=1)                                                                                                                                                           |
              Sort Key: (count(r.rental_id)) DESC, (max(r.return_date)) DESC, c.customer_id, c.first_name, c.last_name, c.email, c.registration_date, (COALESCE(sum(CASE WHEN (r.return_date IS NULL) THEN 1 ELSE 0 END), '0'::bigint)), ((SubPlan 1)), ((SubPl|
              Sort Method: quicksort  Memory: 25kB                                                                                                                                                                                                             |
              Buffers: shared hit=4                                                                                                                                                                                                                            |
              ->  GroupAggregate  (cost=5.34..14.53 rows=1 width=1036) (actual time=0.094..0.095 rows=0.00 loops=1)                                                                                                                                            |
                    Group Key: c.customer_id                                                                                                                                                                                                                   |
                    Filter: (count(r.rental_id) > 10)                                                                                                                                                                                                          |
                    Rows Removed by Filter: 30                                                                                                                                                                                                                 |
                    Buffers: shared hit=4                                                                                                                                                                                                                      |
                    ->  Sort  (cost=5.34..5.35 rows=1 width=1186) (actual time=0.079..0.081 rows=30.00 loops=1)                                                                                                                                                |
                          Sort Key: c.customer_id                                                                                                                                                                                                              |
                          Sort Method: quicksort  Memory: 27kB                                                                                                                                                                                                 |
                          Buffers: shared hit=4                                                                                                                                                                                                                |
                          ->  Hash Join  (cost=2.91..5.33 rows=1 width=1186) (actual time=0.065..0.073 rows=30.00 loops=1)                                                                                                                                     |
                                Hash Cond: (m.movie_id = r.movie_id)                                                                                                                                                                                           |
                                Buffers: shared hit=4                                                                                                                                                                                                          |
                                ->  Seq Scan on movies m  (cost=0.00..2.30 rows=30 width=222) (actual time=0.018..0.020 rows=30.00 loops=1)                                                                                                                    |
                                      Buffers: shared hit=2                                                                                                                                                                                                    |
                                ->  Hash  (cost=2.90..2.90 rows=1 width=972) (actual time=0.040..0.041 rows=30.00 loops=1)                                                                                                                                     |
                                      Buckets: 1024  Batches: 1  Memory Usage: 11kB                                                                                                                                                                            |
                                      Buffers: shared hit=2                                                                                                                                                                                                    |
                                      ->  Hash Join  (cost=1.46..2.90 rows=1 width=972) (actual time=0.025..0.034 rows=30.00 loops=1)                                                                                                                          |
                                            Hash Cond: (c.customer_id = r.customer_id)                                                                                                                                                                         |
                                            Buffers: shared hit=2                                                                                                                                                                                              |
                                            ->  Seq Scan on customers c  (cost=0.00..1.39 rows=10 width=960) (actual time=0.007..0.010 rows=31.00 loops=1)                                                                                                     |
                                                  Filter: (registration_date <= '2022-12-31'::date)                                                                                                                                                            |
                                                  Buffers: shared hit=1                                                                                                                                                                                        |
                                            ->  Hash  (cost=1.45..1.45 rows=1 width=16) (actual time=0.014..0.014 rows=30.00 loops=1)                                                                                                                          |
                                                  Buckets: 1024  Batches: 1  Memory Usage: 10kB                                                                                                                                                                |
                                                  Buffers: shared hit=1                                                                                                                                                                                        |
                                                  ->  Seq Scan on rentals r  (cost=0.00..1.45 rows=1 width=16) (actual time=0.005..0.009 rows=30.00 loops=1)                                                                                                   |
                                                        Filter: ((rental_date >= '2020-01-01'::date) AND (rental_date <= '2022-12-31'::date))                                                                                                                  |
                                                        Buffers: shared hit=1                                                                                                                                                                                  |
                    SubPlan 1                                                                                                                                                                                                                                  |
                      ->  Aggregate  (cost=3.78..3.79 rows=1 width=8) (never executed)                                                                                                                                                                         |
                            ->  Sort  (cost=3.77..3.78 rows=1 width=4) (never executed)                                                                                                                                                                        |
                                  Sort Key: m_1.movie_id                                                                                                                                                                                                       |
                                  ->  Nested Loop  (cost=0.00..3.76 rows=1 width=4) (never executed)                                                                                                                                                           |
                                        Join Filter: (m_1.movie_id = r2.movie_id)                                                                                                                                                                              |
                                        ->  Seq Scan on movies m_1  (cost=0.00..2.38 rows=1 width=4) (never executed)                                                                                                                                          |
                                              Filter: ((genre)::text = 'Drama'::text)                                                                                                                                                                          |
                                        ->  Seq Scan on rentals r2  (cost=0.00..1.38 rows=1 width=4) (never executed)                                                                                                                                          |
                                              Filter: (customer_id = c.customer_id)                                                                                                                                                                            |
                    SubPlan 2                                                                                                                                                                                                                                  |
                      ->  Aggregate  (cost=3.81..3.82 rows=1 width=32) (never executed)                                                                                                                                                                        |
                            ->  Hash Join  (cost=1.39..3.81 rows=1 width=12) (never executed)                                                                                                                                                                  |
                                  Hash Cond: (m2.movie_id = r3.movie_id)                                                                                                                                                                                       |
                                  ->  Seq Scan on movies m2  (cost=0.00..2.30 rows=30 width=16) (never executed)                                                                                                                                               |
                                  ->  Hash  (cost=1.38..1.38 rows=1 width=4) (never executed)                                                                                                                                                                  |
                                        ->  Seq Scan on rentals r3  (cost=0.00..1.38 rows=1 width=4) (never executed)                                                                                                                                          |
                                              Filter: (customer_id = c.customer_id)                                                                                                                                                                            |
                    SubPlan 3                                                                                                                                                                                                                                  |
                      ->  Aggregate  (cost=1.53..1.54 rows=1 width=8) (never executed)                                                                                                                                                                         |
                            ->  Seq Scan on rentals r4  (cost=0.00..1.52 rows=1 width=4) (never executed)                                                                                                                                                      |
                                  Filter: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date) AND (customer_id = c.customer_id))                                                                                                      |
Planning Time: 0.398 ms                                                                                                                                                                                                                                        |
Execution Time: 0.196 ms                                                                                                                                                                                                                                       |

-- Результаты:
-- 1. Снизилась оценка стоимости запроса с 184.31 до 14.54.
-- 2. Уменьшилось использование буферов (чтение из кэша) с 62 до 4.
-- 3. Уменьшилось время выполнения запроса с 0.211 ms до 0.196 ms.
-- 4. Вместо связи Nested Loop + Merge Join (таблицы rentals и customers) мы видим Hash Join, что значительно улучшает производительность. Видимо из-за этого и снизилось использование буферов.

-- Осталсь проблема использования Seq Scan по таблицам rentals и customers.
-- Это не проблема неправильного добавления индексов, а просто следствие того, что таблицы rentals и customers слишком маленькие.
-- На больших таблицах ситуация будет другой.