# Домашнее задание. Модуль_02.

## 1) Установка Postgres и DBeaver. Работа с запросами
Установил _Postgres_. Затем _DBeaver_. На рабочем компе решил попробывать _pgAdmin 4_. Значительных отличий не ощутил. Принципы работы с баой данных одинаковые.

Создал базу данных _Postgres_. Загрузил таблицы по примерам.
С SQL раньше никогда не работал, но осваивается он хорошо. Создал запросы к дашборду из Модуля 1.
#### KPI
    SELECT round(sum(o.Profit)) as "Прибыль_$",
       round(sum(o.Sales)) as "Доход_$",
       round(sum(o.Quantity)) as "Продажи_ед",
       round((sum(o.Sales)/sum(o.Quantity)),2) as "Ср.цена_$",
       round((sum(o.Profit)/sum(o.Sales)),2)*100 as "Маржа_%",
       round((avg(o.Discount)),2)*100 as "Скидка_%"
    FROM orders o
#### KPI по годам    
    SELECT round(sum(o.Profit)) as "Прибыль_$",
       round(sum(o.Sales)) as "Доход_$",
	   round(sum(o.Quantity)) as "Продажи_ед",
	   round((sum(o.Sales)/sum(o.Quantity)),2) as "Ср.цена_$",
	   round((sum(o.Profit)/sum(o.Sales)),2)*100 as "Маржа_%",
	   round((avg(o.Discount)),2)*100 as "Скидка_%",
    extract('year' from o.Ship_Date) as "год"
    FROM orders o
    WHERE o.Ship_Date < '2019-12-31'
    GROUP BY "год"
    ORDER BY "год"
#### Доля продаж (по менеджерам, продукции и потребителям)
	--Доля продаж по: менеджерам, продукции и потребителям (все в одном запросе)
	SELECT 
	    p.Person, o.Category, o.Segment,
	    round(sum(o.Sales)) as "Доход_$"
	FROM orders o
	JOIN people p
	    ON p.Region = o.Region
	GROUP BY GROUPING SETS ((p.Person), (o.Category), (o.Segment))
	ORDER BY p.Person, o.Category, o.Segment

	--Или отдельно для каждой группировки с долей в %
	select distinct
	o.Segment,
	    round(sum(o.Sales) over (partition by o.Segment)) as "Доход_$",
	    round(sum(o.Sales) over (partition by o.Segment) / (sum(o.Sales) OVER ()),2)*100 as "Доля_%"
	FROM orders o
	ORDER BY "Доля_%" desc
#### Ранжирование по прибыли
	SELECT p.Person,
		RANK() OVER(ORDER BY sum(o.Profit) desc) as "Ранг",
		round(sum(o.Profit)) as "Прибыль_$",
		round(sum(o.Sales/(1-o.Discount)-o.Sales)) as "Скидка_$",
		round(sum(o.Quantity)) as "Продажи_ед",
		round((sum(o.Sales)/sum(o.Quantity)),2) as "Ср.цена_$",
		round((sum(o.Profit)/sum(o.Sales)),2)*100 as "Маржа_%",
		round((avg(o.Discount)),2)*100 as "Скидка_%"
	FROM orders o
	JOIN people p
	        ON p.Region = o.Region
	GROUP BY p.Person
#### Индекс сезонности продаж
	SELECT distinct
		extract('MONTH' from o.Ship_Date) as "№",
		to_char(o.Ship_Date,'Month') as "месяц",
		round(sum(o.Quantity) over (partition by extract('MONTH' from o.Ship_Date))::numeric/
		(sum(o.Quantity)over()/12),2) as "Индекс сезонности"
	FROM orders o
	WHERE o.Ship_Date < '2019-12-31'
	ORDER BY "№"	
#### Факторный анализ прибыли
	SELECT 
		"Маржа_2018", "Маржа_2019",
		round("Маржа_2019"-"Маржа_2018") as "Влияние в т.ч:",
		round(("Кол_2019"-"Кол_2018")*("Маржа_2019"/"Маржа_2018")) as "объем",
		round(("Дох_2019"/"Кол_2019"-"Дох_2018"/"Кол_2018")*"Кол_2019") as "цена",
		round((("Дох_2019"/"Кол_2019"-"Маржа_2019"/"Кол_2019")-("Дох_2018"/"Кол_2018"-"Маржа_2018"/"Кол_2018"))*-Кол_2019) as "себестоимость"
	FROM (
		round(sum(case when extract('YEAR' from o.Ship_Date)=2018 then o.Profit end)) as "Маржа_2018", 
		round(sum(case when extract('YEAR' from o.Ship_Date)=2019 then o.Profit end)) as "Маржа_2019", 
		round(sum(case when extract('YEAR' from o.Ship_Date)=2018 then o.quantity end)) as "Кол_2018", 
		round(sum(case when extract('YEAR' from o.Ship_Date)=2019 then o.quantity end)) as "Кол_2019",
		round(sum(case when extract('YEAR' from o.Ship_Date)=2018 then o.sales end)) as "Дох_2018",
		round(sum(case when extract('YEAR' from o.Ship_Date)=2019 then o.sales end)) as "Дох_2019"
		FROM orders o)q
		
## 2) Модель данных
Для работы с моделью данных использовал _SqlDBM_. Сервис простой, разобраться не сложно.
 - Логическая модель данных
![Shem](https://github.com/GrygorPavlenko/DataEngineering/blob/f6238c41a6cf2109d790ac6e9fe80bdc08baf96e/DE-101/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%2002/files/shem1.jpg)
 - Физическая модель
![Shem](https://github.com/GrygorPavlenko/DataEngineering/blob/f6238c41a6cf2109d790ac6e9fe80bdc08baf96e/DE-101/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%2002/files/shem.jpg)

 - Перенос модели в базу данных. Наполнение базы данных.
 
 Я решил по максимуму сохранить сгенерированный код из _SqlDBM_ без существенных правок. Кроме всего прочего при заполнении данными новой схемы _DW_ появлялась ошибка о несоответствии типов данных по полю _postal_code_. Пришлось изменить тип данных в исходной схеме _public_. Собственно сам файл с кодом:
 [схема DW](https://github.com/GrygorPavlenko/DataEngineering/blob/8aa855d7fe12e767821123ba5ed6ab542779ae09/DE-101/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%2002/files/DW.sql)
 
 Ну и проверочная выборка:
 ![Shem](https://github.com/GrygorPavlenko/DataEngineering/blob/0af5bfc35685437dd8289893d12fb24a881cf174/DE-101/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%2002/files/%D0%9F%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0.jpg)
 
 ## 3) Модель данных в облаке
 
 В связи со сложившимися обстоятельствами доступ к облачным сервисам ограничен, поэтому наиболее простым решением есть _Yandex Cloud_.
 ![Shem](https://github.com/GrygorPavlenko/DataEngineering/blob/5563924734d506a19bb728d37b1f67e0ed45c857/DE-101/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%2002/files/%D0%91%D0%94%20%D1%8F%D0%BD%D0%B4.jpg)
 
 Подключение к базе данных _Superstore_ в облаке через _db viewer_
  ![Shem](https://github.com/GrygorPavlenko/DataEngineering/blob/6ce241846be768d9c8ef7e0c8c74999365e76f6f/DE-101/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%2002/files/%D0%91%D0%94%20%D0%BF%D0%BE%D0%B4%D0%BA%D0%BB%D1%8E%D1%87%D0%B5%D0%BD%D0%B8%D0%B5.jpg)
 По сути процессов технология создания и наполнения БД в облаке _Yandex Cloud_ аналогична localhost. Заливаем исходные таблицы, создаем новую схему и наполняем ее.
 Проверочный результат базы данных в облаке:
  ![Shem](https://github.com/GrygorPavlenko/DataEngineering/blob/bc8e1c7ad870ee0e26fdb54357ffb6f8d8264696/DE-101/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%2002/files/%D0%91%D0%94%20%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0.jpg)
 
  ## 4) Визуализация в облачном сервисе
  
  Для удобства пользования в качестве сервиса визуализации данных использовался _Yandex DataLens_.
  Имея опыт работы с такими инструментами как _Power BI_ я немного разочарован возможностями и функционалом _Yandex DataLens_.
   - подключение к облачной БД _Superstore_
   ![Shem](https://github.com/GrygorPavlenko/DataEngineering/blob/3200c373dcfc6c3a8d2e6ae7ba4fe234f05a5153/DE-101/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%2002/files/%D0%91%D0%94%20%D0%BF%D0%BE%D0%B4%D0%BA%D0%BB%D1%8E%D1%87%D0%B5%D0%BD%D0%B8%D0%B5.jpg)
   - создание датасета
   ![Shem](https://github.com/GrygorPavlenko/DataEngineering/blob/3200c373dcfc6c3a8d2e6ae7ba4fe234f05a5153/DE-101/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%2002/files/%D0%91%D0%94%20%D0%B4%D0%B0%D1%82%D0%B0%D1%81%D0%B5%D1%82.jpg) 
   - создание чартов и дашборда
   ![Shem](https://github.com/GrygorPavlenko/DataEngineering/blob/3200c373dcfc6c3a8d2e6ae7ba4fe234f05a5153/DE-101/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%2002/files/%D0%91%D0%94%20%D0%B4%D0%B0%D1%88%D0%B1.jpg)
