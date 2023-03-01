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
