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

