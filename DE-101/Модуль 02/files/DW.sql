-- create schema DW!
CREATE SCHEMA DW 

-- create dim tables (Ship,Product,Customer,Region,People,Returns,Calendar)
-- T.Ship
DROP TABLE IF EXISTS DW.SHIP;
CREATE TABLE DW.SHIP (
SHIP_ID serial NOT NULL,
SHIP_MODE VARCHAR(50) NOT NULL,
CONSTRAINT PK_1 PRIMARY KEY (SHIP_ID)
);
--deleting rows
TRUNCATE TABLE DW.SHIP;
--generating ship_id and inserting ship_mode from orders
insert into dw.ship
select 100+row_number() over(), ship_mode from (select distinct ship_mode from public.orders) a;
--checking
select * from dw.ship;

-- T.Product
DROP TABLE IF EXISTS dw.product;
CREATE TABLE dw.product
(
 Product_ID   serial NOT NULL,
 Product_Name varchar(150) NOT NULL,
 Sub_Category varchar(50) NOT NULL,
 Category     varchar(50) NOT NULL,
 CONSTRAINT PK_2 PRIMARY KEY ( Product_ID )
);
TRUNCATE TABLE dw.product;
	insert into dw.product
	select 100+row_number() over(), Product_Name, Subcategory, Category
	from (select distinct Product_Name, Subcategory, Category from public.orders) a;
select * from dw.product;

-- T.Customer
DROP TABLE IF EXISTS dw.customer;
CREATE TABLE dw.customer
(
 customer_id   serial NOT NULL,
 Customer_Name varchar(50) NOT NULL,
 Segment       varchar(50) NOT NULL,
 CONSTRAINT PK_3 PRIMARY KEY ( customer_id )
);
TRUNCATE TABLE dw.customer;
	insert into dw.customer
	select 100+row_number() over(), Customer_Name, Segment
	from (select distinct Customer_Name, Segment from public.orders) a;
select * from dw.customer;

-- T.People
DROP TABLE IF EXISTS dw.people;
CREATE TABLE dw.people
(
 Region varchar(15) NOT NULL,
 Person varchar(50) NOT NULL,
 CONSTRAINT PK_5 PRIMARY KEY ( Region )
);
TRUNCATE TABLE dw.people;
	insert into dw.people
	select Region, Person
	from (select distinct Region, Person from public.people) a;
select * from dw.people;

-- T.Region
DROP TABLE IF EXISTS dw.region CASCADE;
CREATE TABLE dw.region
(
 geo_id      serial NOT NULL,
 City        varchar(50) NOT NULL,
 Region      varchar(20) NOT NULL,
 State       varchar(50) NOT NULL,
 Country     varchar(50) NOT NULL,
 Postal_Code varchar(20) NULL,
 CONSTRAINT PK_4 PRIMARY KEY ( geo_id ),
 CONSTRAINT FK_1 FOREIGN KEY ( Region ) REFERENCES dw.people ( Region )
);

CREATE INDEX FK_1 ON dw.region
(Region);
TRUNCATE TABLE dw.region CASCADE;
	insert into dw.region
	select 100+row_number() over(), City, Region, State, Country, Postal_Code
	from (select distinct City, Region, State, Country, Postal_Code from public.orders) a;
select * from dw.region;

--data quality check
select distinct country, city, state, postal_code from dw.region
where country is null or city is null or postal_code is null;
	update dw.region
	set postal_code = '05401'
	where city = 'Burlington'  and postal_code is null;
		update public.orders
		set postal_code = '05401'
		where city = 'Burlington'  and postal_code is null;
select * from dw.region
where city = 'Burlington'

-- T.Returns
DROP TABLE IF EXISTS dw.returns CASCADE;
CREATE TABLE dw.returns
(
 Order_ID varchar(15) NOT NULL,
 Returned varchar(5) NULL,
 CONSTRAINT PK_6 PRIMARY KEY ( Order_ID )
);
TRUNCATE TABLE dw.returns CASCADE;
	insert into dw.returns
	select distinct o.Order_ID, r.returned
	from public.orders o
left join (select distinct r.Order_ID, r.returned from public.returns r) r
on r.Order_ID = o.Order_ID;
select * from dw.returns;

-- T.Calendar
DROP TABLE IF EXISTS dw.calendar;
CREATE TABLE dw.calendar
(
 date     date NOT NULL,
 year     int NOT NULL,
 quartal  int NOT NULL,
 mounth   int NOT NULL,
 week     int NOT NULL,
 week_day varchar(20) NOT NULL,
 leap  varchar(20) NOT NULL,
 CONSTRAINT PK_7 PRIMARY KEY ( date )
);
TRUNCATE TABLE dw.calendar;
	insert into dw.calendar 
select 
	   date::date,  
       extract('year' from date)::int as year,
       extract('quarter' from date)::int as quarter,
       extract('month' from date)::int as month,
       extract('week' from date)::int as week,
       to_char(date, 'dy') as week_day,
       extract('day' from
               (date + interval '2 month - 1 day')
              ) = 29
       as leap
  from generate_series(date '2010-01-01',
                       date '2030-01-01',
                       interval '1 day')
       as t(date);     
select * from dw.calendar;

-- create metrics table Sales
DROP TABLE IF EXISTS dw.sales;
CREATE TABLE dw.sales
(
 row_id      serial NOT NULL,
 Ship_id     integer NOT NULL,
 Order_ID    varchar(15) NOT NULL,
 Ship_Date   date NOT NULL,
 Order_Date  date NOT NULL,
 Product_ID  integer NOT NULL,
 Customer_ID integer NOT NULL,
 geo_id      integer NOT NULL,
 Sales       numeric(10,4) NOT NULL,
 Quantity    int4 NOT NULL,
 Discount    numeric(4,2) NOT NULL,
 Profit      numeric(10,4) NOT NULL,
 CONSTRAINT PK_sales PRIMARY KEY ( row_id ),
	 CONSTRAINT FK_2 FOREIGN KEY ( geo_id ) REFERENCES dw.region ( geo_id ),
	 CONSTRAINT FK_3 FOREIGN KEY ( Customer_ID ) REFERENCES dw.Customer ( customer_id ),
	 CONSTRAINT FK_4 FOREIGN KEY ( Product_ID ) REFERENCES dw.Product ( Product_ID ),
	 CONSTRAINT FK_5 FOREIGN KEY ( Order_Date ) REFERENCES dw.Calendar ( date ),
	 CONSTRAINT FK_6 FOREIGN KEY ( Ship_Date ) REFERENCES dw.Calendar ( date ),
	 CONSTRAINT FK_7 FOREIGN KEY ( Ship_id ) REFERENCES dw.Ship ( Ship_id ),
	 CONSTRAINT FK_8 FOREIGN KEY ( Order_ID ) REFERENCES dw.Returns ( Order_ID )
);
	CREATE INDEX FK_2 ON dw.sales (geo_id);
	CREATE INDEX FK_3 ON dw.sales (Customer_ID);
	CREATE INDEX FK_4 ON dw.sales (Product_ID);
	CREATE INDEX FK_5 ON dw.sales (Order_Date);
	CREATE INDEX FK_6 ON dw.sales (Ship_Date);
	CREATE INDEX FK_7 ON dw.sales (Ship_id);
	CREATE INDEX FK_8 ON dw.sales (Order_ID);
TRUNCATE TABLE dw.sales;

insert into dw.sales 
select
	 row_number() over() as row_id,
	 s.ship_id,
	 o.order_id,
	 o.ship_date,
	 o.order_date,
	 p.Product_ID,
	 cd.customer_id,
	 g.geo_id,
	 sales,
	 quantity,
	 discount,
	 profit
from public.orders o
inner join dw.ship s on o.ship_mode = s.ship_mode
inner join dw.product p on o.product_name = p.product_name and o.subcategory=p.sub_category and o.category=p.category
inner join dw.customer cd on cd.customer_name=o.customer_name and cd.Segment=o.Segment
inner join dw.region g on o.postal_code = g.postal_code and g.region=o.region and g.country=o.country and g.city = o.city and o.state = g.state

select count(*) from dw.sales sf
inner join dw.ship s on sf.ship_id=s.ship_id
inner join dw.region r on sf.geo_id=r.geo_id
inner join dw.product p on sf.Product_ID=p.Product_ID
inner join dw.customer cd on sf.customer_id=cd.customer_id
inner join dw.returns r2 on sf.order_id =r2.order_id 