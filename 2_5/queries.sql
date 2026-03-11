-- ИСХОДНЫЕ ДАННЫЕ

-- Создание расширения PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- Создание таблицы для достопримечательностей (landmarks)
CREATE TABLE landmarks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location GEOMETRY(POINT, 4326) NOT NULL,
    boundary GEOMETRY(POLYGON, 4326)
);

-- Создание таблицы для маршрутов (routes)
CREATE TABLE routes (
    id SERIAL PRIMARY KEY,
    start_location GEOMETRY(POINT, 4326) NOT NULL,
    end_location GEOMETRY(POINT, 4326) NOT NULL,
    route GEOMETRY(LINESTRING, 4326) NOT NULL
);

-- Вставка данных в таблицу landmarks
INSERT INTO landmarks (name, location, boundary)
VALUES
('Эйфелева башня', ST_SetSRID(ST_MakePoint(2.2943506, 48.8588443), 4326), ST_SetSRID(ST_GeomFromText('POLYGON((2.2940 48.8586, 2.2950 48.8586, 2.2950 48.8590, 2.2940 48.8590, 2.2940 48.8586))'), 4326)),
('Лувр', ST_SetSRID(ST_MakePoint(2.337644, 48.860611), 4326), ST_SetSRID(ST_GeomFromText('POLYGON((2.3376 48.8606, 2.3387 48.8606, 2.3387 48.8599, 2.3376 48.8599, 2.3376 48.8606))'), 4326)),
('Собор Парижской Богоматери', ST_SetSRID(ST_MakePoint(2.3499, 48.8529), 4326), NULL),
('Триумфальная арка', ST_SetSRID(ST_MakePoint(2.2950, 48.8738), 4326), NULL),
('Мулен Руж', ST_SetSRID(ST_MakePoint(2.3322, 48.8841), 4326), NULL),
('Опера Гарнье', ST_SetSRID(ST_MakePoint(2.3319, 48.8704), 4326), NULL),
('Башня Монпарнас', ST_SetSRID(ST_MakePoint(2.3212, 48.8422), 4326), NULL),
('Музей Орсе', ST_SetSRID(ST_MakePoint(2.3266, 48.8599), 4326), NULL),
('Площадь Конкорд', ST_SetSRID(ST_MakePoint(2.3215, 48.8656), 4326), NULL),
('Дворец Версаль', ST_SetSRID(ST_MakePoint(2.1204, 48.8049), 4326), NULL),
('Базилика Сакре-Кёр', ST_SetSRID(ST_MakePoint(2.3431, 48.8867), 4326), NULL),
('Бульвар Сен-Жермен', ST_SetSRID(ST_MakePoint(2.3405, 48.8531), 4326), NULL),
('Центр Помпиду', ST_SetSRID(ST_MakePoint(2.3522, 48.8606), 4326), NULL),
('Дом инвалидов', ST_SetSRID(ST_MakePoint(2.3122, 48.8566), 4326), NULL),
('Музей Родена', ST_SetSRID(ST_MakePoint(2.3162, 48.8555), 4326), NULL),
('Музей Пикассо', ST_SetSRID(ST_MakePoint(2.3617, 48.8594), 4326), NULL),
('Пантеон', ST_SetSRID(ST_MakePoint(2.3464, 48.8462), 4326), NULL),
('Библиотека Франсуа Миттерана', ST_SetSRID(ST_MakePoint(2.3767, 48.8336), 4326), NULL),
('Сен-Шапель', ST_SetSRID(ST_MakePoint(2.3445, 48.8550), 4326), NULL),
('Парк Монсо', ST_SetSRID(ST_MakePoint(2.3086, 48.8792), 4326), NULL);

-- Вставка данных в таблицу routes
INSERT INTO routes (start_location, end_location, route)
VALUES
(ST_SetSRID(ST_MakePoint(2.2943506, 48.8588443), 4326), ST_SetSRID(ST_MakePoint(2.337644, 48.860611), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.2943506, 48.8588443), ST_MakePoint(2.337644, 48.860611)), 4326)),
(ST_SetSRID(ST_MakePoint(2.2943506, 48.8588443), 4326), ST_SetSRID(ST_MakePoint(2.3499, 48.8529), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.2943506, 48.8588443), ST_MakePoint(2.3499, 48.8529)), 4326)),
(ST_SetSRID(ST_MakePoint(2.337644, 48.860611), 4326), ST_SetSRID(ST_MakePoint(2.2950, 48.8738), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.337644, 48.860611), ST_MakePoint(2.2950, 48.8738)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3499, 48.8529), 4326), ST_SetSRID(ST_MakePoint(2.3322, 48.8841), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3499, 48.8529), ST_MakePoint(2.3322, 48.8841)), 4326)),
(ST_SetSRID(ST_MakePoint(2.2950, 48.8738), 4326), ST_SetSRID(ST_MakePoint(2.3212, 48.8422), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.2950, 48.8738), ST_MakePoint(2.3212, 48.8422)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3322, 48.8841), 4326), ST_SetSRID(ST_MakePoint(2.3266, 48.8599), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3322, 48.8841), ST_MakePoint(2.3266, 48.8599)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3212, 48.8422), 4326), ST_SetSRID(ST_MakePoint(2.337644, 48.860611), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3212, 48.8422), ST_MakePoint(2.337644, 48.860611)), 4326)),
(ST_SetSRID(ST_MakePoint(2.337644, 48.860611), 4326), ST_SetSRID(ST_MakePoint(2.3215, 48.8656), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.337644, 48.860611), ST_MakePoint(2.3215, 48.8656)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3215, 48.8656), 4326), ST_SetSRID(ST_MakePoint(2.1204, 48.8049), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3215, 48.8656), ST_MakePoint(2.1204, 48.8049)), 4326)),
(ST_SetSRID(ST_MakePoint(2.1204, 48.8049), 4326), ST_SetSRID(ST_MakePoint(2.3499, 48.8529), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.1204, 48.8049), ST_MakePoint(2.3499, 48.8529)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3431, 48.8867), 4326), ST_SetSRID(ST_MakePoint(2.2943506, 48.8588443), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3431, 48.8867), ST_MakePoint(2.2943506, 48.8588443)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3499, 48.8529), 4326), ST_SetSRID(ST_MakePoint(2.3215, 48.8656), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3499, 48.8529), ST_MakePoint(2.3215, 48.8656)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3215, 48.8656), 4326), ST_SetSRID(ST_MakePoint(2.3431, 48.8867), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3215, 48.8656), ST_MakePoint(2.3431, 48.8867)), 4326)),
(ST_SetSRID(ST_MakePoint(2.1204, 48.8049), 4326), ST_SetSRID(ST_MakePoint(2.337644, 48.860611), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.1204, 48.8049), ST_MakePoint(2.337644, 48.860611)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3215, 48.8656), 4326), ST_SetSRID(ST_MakePoint(2.2950, 48.8738), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3215, 48.8656), ST_MakePoint(2.2950, 48.8738)), 4326)),
(ST_SetSRID(ST_MakePoint(2.2950, 48.8738), 4326), ST_SetSRID(ST_MakePoint(2.3499, 48.8529), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.2950, 48.8738), ST_MakePoint(2.3499, 48.8529)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3499, 48.8529), 4326), ST_SetSRID(ST_MakePoint(2.337644, 48.860611), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3499, 48.8529), ST_MakePoint(2.337644, 48.860611)), 4326)),
(ST_SetSRID(ST_MakePoint(2.337644, 48.860611), 4326), ST_SetSRID(ST_MakePoint(2.3431, 48.8867), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.337644, 48.860611), ST_MakePoint(2.3431, 48.8867)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3431, 48.8867), 4326), ST_SetSRID(ST_MakePoint(2.3322, 48.8841), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3431, 48.8867), ST_MakePoint(2.3322, 48.8841)), 4326)),
(ST_SetSRID(ST_MakePoint(2.3215, 48.8656), 4326), ST_SetSRID(ST_MakePoint(2.2943506, 48.8588443), 4326), ST_SetSRID(ST_MakeLine(ST_MakePoint(2.3215, 48.8656), ST_MakePoint(2.2943506, 48.8588443)), 4326));

-- ВЫПОЛНЕННОЕ ЗАДАНИЕ

-- Напишите запрос, который выводит названия всех достопримечательностей и их координаты (широту и долготу).
--Используйте функцию ST_X() для извлечения долготы и ST_Y() для широты из поля location.
select id, name, ST_X(location) as X, ST_Y(location) as y from landmarks;

-- Напишите запрос, который выводит все маршруты, начинающиеся в радиусе 5 км от точки с координатами 48.8566, 2.3522 (центр Парижа).
-- Используйте функцию ST_DWithin() для фильтрации маршрутов по расстоянию.
select * from routes r where ST_DWithin(
    r.start_location::geography,
    ST_SetSRID(ST_MakePoint(2.3522, 48.8566), 4326)::geography,
    5000
);

-- Напишите запрос, который выводит названия достопримечательностей, полностью находящихся внутри границ территории Лувра.
-- Координаты полигона Лувра уже записаны в таблице landmarks в поле boundary.
select name from landmarks l where ST_Within(l.boundary, (select boundary from landmarks where name = 'Лувр'));

-- Напишите запрос, который добавляет новую достопримечательность ""Музей Луи Виттона"" с координатами (48.864716, 2.349014) в таблицу landmarks.
-- Укажите её местоположение как геометрию типа POINT.
insert into landmarks (name, location) values ('Музей Луи Виттона', ST_SetSRID(ST_MakePoint(2.349014, 48.864716), 4326));

-- Напишите запрос, который выводит длину маршрута, соединяющего Эйфелеву башню и Лувр.
-- Для этого используйте функцию ST_Length() для поля route в таблице routes.
select ST_Length(route::geography) as length_meters
from routes
where ST_Equals(start_location, (select location from landmarks where name = 'Эйфелева башня'))
  and ST_Equals(end_location, (select location from landmarks where name = 'Лувр'));

-- Напишите запрос, который выводит все маршруты, пересекающие радиус 2 км от точки с координатами (48.8588443, 2.2943506) (Эйфелева башня).
-- Используйте функцию ST_Intersects() для определения пересечений.
select *
from routes r
where ST_DWithin(
    r.route::geography,
    ST_SetSRID(ST_MakePoint(2.2943506, 48.8588443), 4326)::geography,
    2000
);

-- Напишите запрос, который добавляет границы для новой достопримечательности ""Парк Монсо""
-- (координаты по углам полигона: (48.8792, 2.3086), (48.8794, 2.3086), (48.8794, 2.3090), (48.8792, 2.3090)).
-- Убедитесь, что границы правильно заносятся в поле boundary таблицы landmarks.
insert into landmarks (name, location, boundary)
values (
    'Парк Монсо',
    ST_SetSRID(ST_MakePoint(2.3086, 48.8792), 4326),
    ST_SetSRID(
        ST_MakePolygon(
            ST_GeomFromText('LINESTRING(2.3086 48.8792, 2.3086 48.8794, 2.3090 48.8794, 2.3090 48.8792, 2.3086 48.8792)')
        ),
        4326
    )
);

-- Напишите запрос, который выводит все маршруты между достопримечательностями, находящимися в пределах города Париж (границы города заданы как полигон).
-- Координаты полигона предоставлены:
-- Min X (Долгота): 2.22
-- Max X (Долгота): 2.45
-- Min Y (Широта): 48.81
-- Max Y (Широта): 48.91
select * from routes r
where ST_Intersects(r.route, ST_SetSRID(
    ST_GeomFromText('POLYGON((2.22 48.81, 2.45 48.81, 2.45 48.91, 2.22 48.91, 2.22 48.81))'),
    4326
));

-- Напишите запрос, который выводит топ-3 самых длинных маршрута между достопримечательностями.
-- Используйте функцию ST_Length() и сортировку по убыванию длины маршрута.
select *, ST_Length(r.route::geography) as length from routes r order by ST_Length(r.route) desc limit 3;

-- Напишите запрос, который выводит названия всех достопримечательностей, находящихся в пределах 10 км от центра Парижа (координаты 48.8566, 2.3522).
-- Используйте функцию ST_Distance() для измерения расстояний.
select name from landmarks l where ST_Distance(l.location::geography , ST_SetSRID(ST_MakePoint(2.3522, 48.8566), 4326)::geography) <= 10000;
