-- Напишите запрос, который выводит список фильмов вместе с именами и фамилиями актеров, сыгравших в них. Отсортируйте результат по названию фильма и фамилии актера.
select m.title, a.first_name, a.last_name from movies m 
inner join movie_actors ma on m.movie_id = ma.movie_id 
inner join actors a on a.actor_id = ma.actor_id 
order by m.title, a.last_name;

-- Напишите запрос, который выводит список всех клиентов и, если они совершали аренды, то укажите дату последней аренды. Если клиент не совершал аренды, дата аренды должна быть NULL.
select c.customer_id, c.first_name, c.last_name, c.email, max(r.rental_date) from customers c 
left join rentals r on c.customer_id = r.customer_id
group by c.customer_id order by c.customer_id;

-- Напишите запрос, который выводит название фильмов, чья продолжительность больше средней продолжительности всех фильмов в базе данных.
select m.movie_id, m.title, m.duration from movies m 
where m.duration > (select avg(m2.duration) from movies m2)
order by m.movie_id;

-- Используя CTE, напишите запрос, который вычисляет количество аренд для каждого жанра и выводит жанры с общим количеством аренд, отсортированных по количеству аренд в порядке убывания.
with cte_rentals as (select r.movie_id, count(*) as count from rentals r group by r.movie_id)
select m.genre, sum(c.count) as rentals_count from movies m 
join cte_rentals c on m.movie_id = c.movie_id
group by m.genre order by rentals_count desc;

-- Напишите запрос, который выводит список всех уникальных имен актеров и клиентов в одном столбце. Укажите, что это за тип лица с помощью дополнительного столбца (например, ""Актер"" или ""Клиент"").
select distinct c.first_name, 'Клиент' as type from customers c
union
select distinct a.first_name, 'Актер' as type from actors a
order by first_name, type;