-- Напишите запрос, который выводит список фильмов, где рейтинг является NULL, и заменяет NULL на значение 0.
select m.movie_id, m.title, m.release_year, coalesce(m.rating, 0) as rating from movies m where m.rating is null;

-- Напишите запрос, который выводит название фильма и округленное вверх значение рейтинга до ближайшего целого числа.
select m.title, ceiling(m.rating) as rating from movies m;

-- Выведите список клиентов, которые зарегистрировались в последний месяц.
select * from customers c where c.registration_date between now() - interval '1 month' and now();

-- Выведите количество дней, в течение которых каждый клиент держал у себя фильм.
select *, r.return_date - r.rental_date as duration  from rentals r;

-- Напишите запрос, который выводит название фильма в верхнем регистре.
select upper(m.title) as title from movies m;

-- Выведите первые 50 символов описания фильма.
select left(m.description, 50) as short_description from movies m;

-- Напишите запрос, который выводит жанр и общее количество фильмов в каждом жанре.
select m.genre, count(*) as count from movies m group by m.genre order by m.genre;

-- Напишите запрос, который выводит название фильма, его рейтинг и место в рейтинге по убыванию рейтинга.
select m.title, m.rating, row_number() over (order by m.rating desc) as place from movies m;

-- Напишите запрос, который выводит название фильма, его рейтинг и рейтинг предыдущего фильма в списке по убыванию рейтинга.
select m.title, m.rating, lag(m.rating) over (order by m.rating desc) as prev_rating from movies m;

-- Напишите запрос, который для каждого жанра выводит средний рейтинг фильмов в этом жанре, округленный до двух знаков после запятой.
select m.genre, round(avg(m.rating), 2) as avg_rating from movies m group by m.genre;