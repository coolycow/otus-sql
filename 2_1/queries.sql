-- Напишите запрос, который выводит всех актеров.
SELECT * FROM actors;

-- Напишите запрос, который выводит все фильмы жанра ""Драма"", выпущенные после 2010 года.
SELECT m.* FROM movies m JOIN movies_genres mg ON m.id = mg.movie_id JOIN genres g ON mg.genre_id = g.id WHERE g.name = 'Драма' AND m.year > 2010;

-- Напишите запрос, который выводит список актеров, отсортированных по фамилии в алфавитном порядке.
SELECT * FROM actors ORDER BY last_name ASC;

-- Напишите запрос, который выводит топ 5 фильмов с самым высоким рейтингом.
SELECT * FROM movies ORDER BY rating DESC LIMIT 5;

-- Напишите запрос, который выводит следующую страницу (фильмы с 6 по 10) из отсортированного по рейтингу списка фильмов. 
SELECT * FROM movies ORDER BY rating DESC LIMIT 5 OFFSET 5;