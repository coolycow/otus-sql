-- Напишите запрос, который выводит название фильма и список языков, на которых доступен фильм. Используйте функции работы с JSON для извлечения массива языков из поля additional_info.
select m.title, m.additional_info -> 'languages' as languages from movies m;

-- Напишите запрос, который выводит список фильмов, бюджет которых превышает 100 миллионов долларов. Бюджет хранится в поле additional_info внутри ключа budget.
select m.title, m.additional_info -> 'budget' as budget from movies m where (m.additional_info ->> 'budget')::numeric > 100000000;

-- Напишите запрос, который для каждого клиента создаёт JSON-объект с полями full_name (содержащим полное имя клиента) и contact (содержащим email и номер телефона). Выведите customer_id и созданный JSON-объект.
select c.customer_id, jsonb_build_object(
    'full_name', concat(c.first_name, ' ', c.last_name),
    'contact', jsonb_build_object('email', c.email, 'phone_number', c.phone_number)
) from customers c;

-- Напишите запрос, который добавляет новый предпочитаемый жанр ""Drama"" в список preferred_genres для всех клиентов, которые подписаны на рассылку новостей (ключ newsletter имеет значение true).
update customers
set preferences = jsonb_set(preferences, '{preferred_genres}', (preferences -> 'preferred_genres') || '["Drama"]')
where (preferences -> 'newsletter')::bool = true;

-- Напишите запрос, который вычисляет средний бюджет фильмов по жанрам. Учтите, что жанр хранится в поле genre таблицы Movie, а бюджет — внутри JSON-поля additional_info.
select m.genre, round(avg((m.additional_info -> 'budget')::numeric), 2)
from movies m
group by m.genre order by m.genre;

-- Напишите запрос, который выводит список клиентов, у которых в preferences указан предпочитаемый актёр ""Leonardo DiCaprio"".
select c.customer_id, c.first_name, c.last_name, c.preferences -> 'preferred_actors' as preferred_actors
from customers c
where (c.preferences -> 'preferred_actors') ? 'Leonardo DiCaprio';

-- Напишите запрос, который выводит список фильмов, отсортированных по значению кассовых сборов box_office из поля additional_info в порядке убывания.
select m.title, m.additional_info -> 'box_office' as box_office 
from movies m 
order by (m.additional_info ->> 'box_office')::numeric desc;

-- Напишите запрос, который выводит название фильма, его жанр и количество наград (awards) из additional_info.
select m.title, m.genre, jsonb_array_length(m.additional_info -> 'awards') as awards_count 
from movies m order by m.title;

-- Напишите запрос, который подсчитывает количество фильмов, имеющих более чем одну награду в поле awards внутри additional_info.
select count(*) as movies_count from movies m
where jsonb_array_length(m.additional_info -> 'awards') > 1;

-- Напишите запрос, который удаляет ключ preferred_actors из поля preferences для всех клиентов.
    -- Если просто посмотреть на возможный результат удаления
    select c.preferences #- '{preferred_actors}' from customers c;

    -- Если реально нужно удалить
    update customers set preferences = preferences #- '{preferred_actors}';
