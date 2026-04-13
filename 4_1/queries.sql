-- ИСХОДНЫЙ ЗАПРОС
SELECT 
    Customer.first_name, 
    Customer.last_name, 
    Movie.title,
    COUNT(Rental.rental_id) AS rental_count, 
    MAX(Rental.rental_date) AS last_rental_date
FROM 
    Customer
JOIN 
    Rental ON Customer.customer_id = Rental.customer_id
JOIN 
    Movie ON Rental.movie_id = Movie.movie_id
WHERE 
    Movie.genre = 'Action'
    AND Rental.rental_date BETWEEN '2021-01-01' AND '2022-12-31'
GROUP BY 
    Customer.first_name,
    Customer.last_name, 
    Movie.title
ORDER BY 
    rental_count DESC, 
    last_rental_date DESC
LIMIT 10;

-- ВЫПОЛНЕННОЕ ЗАДАНИЕ
-- 0. Исходный запрос в правильном виде (исправлены названия таблиц, добавлены синонимы, соответствие PostgresSQL).
EXPLAIN ANALYZE SELECT 
    c.first_name, 
    c.last_name, 
    m.title,
    COUNT(r.rental_id) AS rental_count, 
    MAX(r.rental_date) AS last_rental_date
FROM 
    customers c
JOIN 
    rentals r  ON c.customer_id = r.customer_id
JOIN 
    movies m ON r.movie_id = m.movie_id
WHERE 
    m.genre = 'Action'
    AND r.rental_date BETWEEN '2021-01-01' AND '2022-12-31'
GROUP BY 
    c.first_name,
    c.last_name, 
    m.title
ORDER BY 
    rental_count DESC, 
    last_rental_date DESC
LIMIT 10;

-- 1. План исходного запроса.
QUERY PLAN                                                                                                                                                   |
-------------------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=51.09..51.09 rows=1 width=964) (actual time=0.080..0.082 rows=5.00 loops=1)                                                                     |
  Buffers: shared hit=17                                                                                                                                     |
  ->  Sort  (cost=51.09..51.09 rows=1 width=964) (actual time=0.080..0.081 rows=5.00 loops=1)                                                                |
        Sort Key: (count(r.rental_id)) DESC, (max(r.rental_date)) DESC                                                                                       |
        Sort Method: quicksort  Memory: 25kB                                                                                                                 |
        Buffers: shared hit=17                                                                                                                               |
        ->  GroupAggregate  (cost=51.05..51.08 rows=1 width=964) (actual time=0.074..0.076 rows=5.00 loops=1)                                                |
              Group Key: c.first_name, c.last_name, m.title                                                                                                  |
              Buffers: shared hit=17                                                                                                                         |
              ->  Sort  (cost=51.05..51.06 rows=1 width=960) (actual time=0.071..0.072 rows=5.00 loops=1)                                                    |
                    Sort Key: c.first_name, c.last_name, m.title                                                                                             |
                    Sort Method: quicksort  Memory: 25kB                                                                                                     |
                    Buffers: shared hit=17                                                                                                                   |
                    ->  Nested Loop  (cost=0.14..51.04 rows=1 width=960) (actual time=0.029..0.062 rows=5.00 loops=1)                                        |
                          Buffers: shared hit=17                                                                                                             |
                          ->  Nested Loop  (cost=0.00..46.73 rows=1 width=528) (actual time=0.020..0.048 rows=5.00 loops=1)                                  |
                                Join Filter: (m.movie_id = r.movie_id)                                                                                       |
                                Rows Removed by Join Filter: 145                                                                                             |
                                Buffers: shared hit=7                                                                                                        |
                                ->  Seq Scan on movies m  (cost=0.00..11.12 rows=1 width=520) (actual time=0.014..0.017 rows=5.00 loops=1)                   |
                                      Filter: ((genre)::text = 'Action'::text)                                                                               |
                                      Rows Removed by Filter: 25                                                                                             |
                                      Buffers: shared hit=2                                                                                                  |
                                ->  Seq Scan on rentals r  (cost=0.00..35.50 rows=8 width=16) (actual time=0.001..0.003 rows=30.00 loops=5)                  |
                                      Filter: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))                                  |
                                      Buffers: shared hit=5                                                                                                  |
                          ->  Index Scan using customers_pkey on customers c  (cost=0.14..4.16 rows=1 width=440) (actual time=0.002..0.002 rows=1.00 loops=5)|
                                Index Cond: (customer_id = r.customer_id)                                                                                    |
                                Index Searches: 5                                                                                                            |
                                Buffers: shared hit=10                                                                                                       |
Planning Time: 0.156 ms                                                                                                                                      |
Execution Time: 0.106 ms                                                                                                                                     |


-- 2. Проблемы исходного запроса:
-- 2.1. Используется Seq Scan на таблицах movies и rentals.
-- 2.2. Используется Index Scan на таблице customers.
-- 2.3. Стоимость запроса: 51.09.
-- 2.4. Время выполнения запроса: 0.110 ms.

-- 3. Добавляем индексы на столбцы, которые используются в запросе (удаление в drop_index.sql):
-- 3.1. Индекс на столбец genre в таблице movies.
CREATE INDEX idx_movies_genre ON movies (genre);

-- 3.2. Индекс на столбец rental_date в таблице rentals.
CREATE INDEX idx_rentals_rental_date ON rentals (rental_date);

-- 3.3. Индекс на столбец customer_id в таблице rentals.
CREATE INDEX idx_rentals_customer_id ON rentals (customer_id);

-- 3.4. Индекс на столбец movie_id в таблице rentals.
CREATE INDEX idx_rentals_movie_id ON rentals (movie_id);

-- 3.5. Частичный индекс на столбцы movie_id и customer_id в таблице rentals, 
-- где rental_date >= '2021-01-01' AND rental_date <= '2022-12-31'.
CREATE INDEX idx_rentals_2021_2022
  ON rentals (movie_id, customer_id)
  WHERE rental_date >= '2021-01-01' AND rental_date <= '2022-12-31';

-- 4. План запроса с индексами:
QUERY PLAN                                                                                                                                                          |
--------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=12.36..12.36 rows=1 width=964) (actual time=0.184..0.185 rows=5.00 loops=1)                                                                            |
  Buffers: shared hit=121                                                                                                                                           |
  ->  Sort  (cost=12.36..12.36 rows=1 width=964) (actual time=0.184..0.185 rows=5.00 loops=1)                                                                       |
        Sort Key: (count(r.rental_id)) DESC, (max(r.rental_date)) DESC                                                                                              |
        Sort Method: quicksort  Memory: 25kB                                                                                                                        |
        Buffers: shared hit=121                                                                                                                                     |
        ->  GroupAggregate  (cost=12.32..12.35 rows=1 width=964) (actual time=0.178..0.180 rows=5.00 loops=1)                                                       |
              Group Key: c.first_name, c.last_name, m.title                                                                                                         |
              Buffers: shared hit=121                                                                                                                               |
              ->  Sort  (cost=12.32..12.32 rows=1 width=960) (actual time=0.175..0.176 rows=5.00 loops=1)                                                           |
                    Sort Key: c.first_name, c.last_name, m.title                                                                                                    |
                    Sort Method: quicksort  Memory: 25kB                                                                                                            |
                    Buffers: shared hit=121                                                                                                                         |
                    ->  Nested Loop  (cost=0.14..12.31 rows=1 width=960) (actual time=0.036..0.165 rows=5.00 loops=1)                                               |
                          Join Filter: (r.movie_id = m.movie_id)                                                                                                    |
                          Rows Removed by Join Filter: 135                                                                                                          |
                          Buffers: shared hit=121                                                                                                                   |
                          ->  Nested Loop  (cost=0.14..9.92 rows=1 width=448) (actual time=0.022..0.049 rows=30.00 loops=1)                                         |
                                Buffers: shared hit=61                                                                                                              |
                                ->  Seq Scan on rentals r  (cost=0.00..1.45 rows=1 width=16) (actual time=0.012..0.014 rows=30.00 loops=1)                          |
                                      Filter: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))                                         |
                                      Buffers: shared hit=1                                                                                                         |
                                ->  Index Scan using customers_pkey on customers c  (cost=0.14..8.16 rows=1 width=440) (actual time=0.001..0.001 rows=1.00 loops=30)|
                                      Index Cond: (customer_id = r.customer_id)                                                                                     |
                                      Index Searches: 30                                                                                                            |
                                      Buffers: shared hit=60                                                                                                        |
                          ->  Seq Scan on movies m  (cost=0.00..2.38 rows=1 width=520) (actual time=0.001..0.002 rows=4.67 loops=30)                                |
                                Filter: ((genre)::text = 'Action'::text)                                                                                            |
                                Rows Removed by Filter: 23                                                                                                          |
                                Buffers: shared hit=60                                                                                                              |
Planning Time: 0.187 ms                                                                                                                                             |
Execution Time: 0.209 ms                                                                                                                                            |


-- 4. Выводы
-- 1. Снизилась стоимость запроса с 51.09 до 12.36;
-- 2. Увеличилось использование буферов (чтение из кэша) с 17 до 121;
-- 3. Особого изменения в производительности не наблюдается.

-- ЭКСПЕРИМЕНТАЛЬНЫЕ ДАННЫЕ (см. generate_data.sql)
-- Добавлено данных (количество записей в таблицах):
-- Customers: 8031;
-- Movies: 35030;
-- Rentals: 2500030.

-- Без индексов:
QUERY PLAN                                                                                                                                                              |
------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=34355.05..34355.07 rows=10 width=964) (actual time=3936.834..3940.863 rows=10.00 loops=1)                                                                  |
  Buffers: shared hit=550515 read=3900 dirtied=10873 written=490, temp read=1172 written=1175                                                                           |
  ->  Sort  (cost=34355.05..34355.21 rows=67 width=964) (actual time=3936.832..3940.860 rows=10.00 loops=1)                                                             |
        Sort Key: (count(r.rental_id)) DESC, (max(r.rental_date)) DESC                                                                                                  |
        Sort Method: top-N heapsort  Memory: 27kB                                                                                                                       |
        Buffers: shared hit=550515 read=3900 dirtied=10873 written=490, temp read=1172 written=1175                                                                     |
        ->  GroupAggregate  (cost=34344.29..34353.60 rows=67 width=964) (actual time=3662.479..3914.338 rows=178643.00 loops=1)                                         |
              Group Key: c.first_name, c.last_name, m.title                                                                                                             |
              Buffers: shared hit=550515 read=3900 dirtied=10873 written=490, temp read=1172 written=1175                                                               |
              ->  Gather Merge  (cost=34344.29..34352.09 rows=67 width=960) (actual time=3662.471..3857.087 rows=179063.00 loops=1)                                     |
                    Workers Planned: 2                                                                                                                                  |
                    Workers Launched: 2                                                                                                                                 |
                    Buffers: shared hit=550515 read=3900 dirtied=10873 written=490, temp read=1172 written=1175                                                         |
                    ->  Sort  (cost=33344.26..33344.33 rows=28 width=960) (actual time=3602.879..3630.765 rows=59687.67 loops=3)                                        |
                          Sort Key: c.first_name, c.last_name, m.title                                                                                                  |
                          Sort Method: external merge  Disk: 3648kB                                                                                                     |
                          Buffers: shared hit=550515 read=3900 dirtied=10873 written=490, temp read=1172 written=1175                                                   |
                          Worker 0:  Sort Method: external merge  Disk: 3056kB                                                                                          |
                          Worker 1:  Sort Method: external merge  Disk: 2672kB                                                                                          |
                          ->  Nested Loop  (cost=476.66..33343.59 rows=28 width=960) (actual time=6.396..3347.908 rows=59687.67 loops=3)                                |
                                Buffers: shared hit=550501 read=3898 dirtied=10873 written=490                                                                          |
                                ->  Hash Join  (cost=476.39..33334.45 rows=28 width=528) (actual time=6.376..3257.494 rows=59687.67 loops=3)                            |
                                      Hash Cond: (r.movie_id = m.movie_id)                                                                                              |
                                      Buffers: shared hit=13310 read=3898 dirtied=10873 written=490                                                                     |
                                      ->  Parallel Seq Scan on rentals r  (cost=0.00..32843.25 rows=5640 width=16) (actual time=2.265..3202.371 rows=416967.00 loops=3) |
                                            Filter: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))                                       |
                                            Rows Removed by Filter: 416376                                                                                              |
                                            Buffers: shared hit=12026 read=3898 dirtied=10873 written=490                                                               |
                                      ->  Hash  (cost=476.15..476.15 rows=19 width=520) (actual time=4.097..4.098 rows=5005.00 loops=3)                                 |
                                            Buckets: 8192 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 357kB                                             |
                                            Buffers: shared hit=1284                                                                                                    |
                                            ->  Seq Scan on movies m  (cost=0.00..476.15 rows=19 width=520) (actual time=0.050..3.533 rows=5005.00 loops=3)             |
                                                  Filter: ((genre)::text = 'Action'::text)                                                                              |
                                                  Rows Removed by Filter: 30025                                                                                         |
                                                  Buffers: shared hit=1284                                                                                              |
                                ->  Index Scan using customers_pkey on customers c  (cost=0.27..0.33 rows=1 width=440) (actual time=0.001..0.001 rows=1.00 loops=179063)|
                                      Index Cond: (customer_id = r.customer_id)                                                                                         |
                                      Index Searches: 179063                                                                                                            |
                                      Buffers: shared hit=537191                                                                                                        |
Planning:                                                                                                                                                               |
  Buffers: shared hit=51 read=6                                                                                                                                         |
Planning Time: 8.854 ms                                                                                                                                                 |
Execution Time: 3941.510 ms                                                                                                                                             |

-- С индексами:
QUERY PLAN                                                                                                                                                                       |
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=71267.16..71267.18 rows=10 width=43) (actual time=651.888..653.829 rows=10.00 loops=1)                                                                              |
  Buffers: shared hit=17035 read=506 written=3, temp read=1172 written=1174                                                                                                      |
  ->  Sort  (cost=71267.16..71708.18 rows=176409 width=43) (actual time=651.887..653.827 rows=10.00 loops=1)                                                                     |
        Sort Key: (count(r.rental_id)) DESC, (max(r.rental_date)) DESC                                                                                                           |
        Sort Method: top-N heapsort  Memory: 27kB                                                                                                                                |
        Buffers: shared hit=17035 read=506 written=3, temp read=1172 written=1174                                                                                                |
        ->  GroupAggregate  (cost=42940.08..67455.02 rows=176409 width=43) (actual time=410.798..631.279 rows=178643.00 loops=1)                                                 |
              Group Key: c.first_name, c.last_name, m.title                                                                                                                      |
              Buffers: shared hit=17035 read=506 written=3, temp read=1172 written=1174                                                                                          |
              ->  Gather Merge  (cost=42940.08..63485.82 rows=176409 width=39) (actual time=410.789..581.825 rows=179063.00 loops=1)                                             |
                    Workers Planned: 2                                                                                                                                           |
                    Workers Launched: 2                                                                                                                                          |
                    Buffers: shared hit=17035 read=506 written=3, temp read=1172 written=1174                                                                                    |
                    ->  Sort  (cost=41940.06..42123.82 rows=73504 width=39) (actual time=311.966..329.965 rows=59687.67 loops=3)                                                 |
                          Sort Key: c.first_name, c.last_name, m.title                                                                                                           |
                          Sort Method: external merge  Disk: 4152kB                                                                                                              |
                          Buffers: shared hit=17035 read=506 written=3, temp read=1172 written=1174                                                                              |
                          Worker 0:  Sort Method: external merge  Disk: 2688kB                                                                                                   |
                          Worker 1:  Sort Method: external merge  Disk: 2536kB                                                                                                   |
                          ->  Hash Join  (cost=891.67..33986.40 rows=73504 width=39) (actual time=3.703..101.485 rows=59687.67 loops=3)                                          |
                                Hash Cond: (r.customer_id = c.customer_id)                                                                                                       |
                                Buffers: shared hit=17020 read=505 written=3                                                                                                     |
                                ->  Hash Join  (cost=611.97..33513.66 rows=73504 width=33) (actual time=2.120..89.113 rows=59687.67 loops=3)                                     |
                                      Hash Cond: (r.movie_id = m.movie_id)                                                                                                       |
                                      Buffers: shared hit=16723 read=505 written=3                                                                                               |
                                      ->  Parallel Seq Scan on rentals r  (cost=0.00..31549.19 rows=515173 width=16) (actual time=0.056..58.019 rows=416967.00 loops=3)          |
                                            Filter: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))                                                |
                                            Rows Removed by Filter: 416376                                                                                                       |
                                            Buffers: shared hit=15425 read=499 written=3                                                                                         |
                                      ->  Hash  (cost=549.50..549.50 rows=4998 width=25) (actual time=2.039..2.040 rows=5005.00 loops=3)                                         |
                                            Buckets: 8192  Batches: 1  Memory Usage: 357kB                                                                                       |
                                            Buffers: shared hit=1298 read=6                                                                                                      |
                                            ->  Bitmap Heap Scan on movies m  (cost=59.02..549.50 rows=4998 width=25) (actual time=0.191..1.569 rows=5005.00 loops=3)            |
                                                  Recheck Cond: ((genre)::text = 'Action'::text)                                                                                 |
                                                  Heap Blocks: exact=428                                                                                                         |
                                                  Buffers: shared hit=1298 read=6                                                                                                |
                                                  ->  Bitmap Index Scan on idx_movies_genre  (cost=0.00..57.77 rows=4998 width=0) (actual time=0.120..0.120 rows=5005.00 loops=3)|
                                                        Index Cond: ((genre)::text = 'Action'::text)                                                                             |
                                                        Index Searches: 3                                                                                                        |
                                                        Buffers: shared hit=14 read=6                                                                                            |
                                ->  Hash  (cost=179.31..179.31 rows=8031 width=14) (actual time=1.561..1.562 rows=8031.00 loops=3)                                               |
                                      Buckets: 8192  Batches: 1  Memory Usage: 441kB                                                                                             |
                                      Buffers: shared hit=297                                                                                                                    |
                                      ->  Seq Scan on customers c  (cost=0.00..179.31 rows=8031 width=14) (actual time=0.037..0.821 rows=8031.00 loops=3)                        |
                                            Buffers: shared hit=297                                                                                                              |
Planning:                                                                                                                                                                        |
  Buffers: shared hit=193 read=28 dirtied=2                                                                                                                                      |
Planning Time: 6.198 ms                                                                                                                                                          |
Execution Time: 654.635 ms                                                                                                                                                       |

-- Что видно по большим данным:
-- Реальное время запроса сильно улучшилось (~3941 ms → ~655 ms) при том же результате (~178 643 групп до LIMIT 10).
-- Решающее изменение — отказ от Nested Loop с ~179 тыс. поисков по customers_pkey в пользу Hash Join с одним сканом customers.
-- Индекс по genre на movies виден в плане и используется (bitmap по idx_movies_genre).
-- rentals по-прежнему читаются последовательным параллельным сканом; индекс по дате в этом плане не задействован. Большая разница во времени скана может быть смесью плана и кэша.
-- Рост cost при падении Execution Time показывает, что нельзя судить об ускорении только по числу cost — важны actual time и Buffers.