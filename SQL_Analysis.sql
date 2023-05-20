 ----------- Making Analysis BY SQL --------------
--------------------- Measures------------------------
--- Function For Return Number Of Video_games
create function count_video_games()
returns int
begin
	declare @count int 
	select @count = count(*)
	from v_video_games
	return @count
end
select dbo.count_video_games() as #Video_Games
--------------------
-- Function For Return Total Sales Of Video_games
alter function total_sales_video_games()
returns bigint
begin
	declare @total bigint 
	select @total =   sum( cast( global_sales as bigint))    
	from v_video_games
	return @total
end
select  dbo.total_sales_video_games()  as #total_sales
--------------------- Other Measures------------------
---- Avg Of Total Sales
select cast (avg(global_sales) as decimal(10,2)) as Avg_Of_Total_Sales,
dbo.total_sales_video_games() / dbo.count_video_games()  as Avg_Of_Total_Sales
from v_video_games

--- #Genere
select count(distinct genre) as #Genre -- 12
from v_video_games
--- #Publisher
select count(distinct publisher) as #Publisher -- 579
from v_video_games

--- #Platform
select count(distinct platform) as #Platform -- 31
from v_video_games

--- #Year
select count(distinct Year) as #Year -- 40
from v_video_games

-- #Decade
select count(distinct decade) as #Decade -- 6
from v_video_games

-- Total Of North_America Sales
select sum(north_america_sales) as total_north_america_sales
from v_video_games

-- Total Of Europe Sales
select sum(Europe_Sales) as total_europe_sales
from v_video_games

-- Total Of Jpan Sales
select sum(Jpan_Sales) as total_jpan_sales
from v_video_games

-- Total Of Other Sales
select sum(Other_Sales) as total_other_sales
from v_video_games

-- % North_America Sales
select concat(sum(north_america_sales)  / dbo.total_sales_video_games() * 100 ,'%')
as [%_North_America_Sales]
from v_video_games

-- % Europe Sales
select concat(sum(europe_sales)  / dbo.total_sales_video_games() * 100 ,'%')
as [%_Europe_Sales]
from v_video_games

-- % Jpan Sales
select concat(sum(jpan_sales)  / dbo.total_sales_video_games() * 100 ,'%')
as [%_Jpan_Sales]
from v_video_games

-- % Other Sales
select concat(sum(other_sales)  / dbo.total_sales_video_games() * 100 ,'%')
as [%_Other_Sales]
from v_video_games

------------------------- Quiries ----------------------------
-- #Video_games Per Genere
select isnull(v.genre, 'Total') as Genre,count(*) #video_games
from v_video_games v
group by rollup( v.genre)
order by #video_games desc

-- Total Sales & #video_games Per Genere
select isnull(v.genre, 'Total') as Genre,sum(global_sales) Total_Sales,
count(*) as #video_games
from v_video_games v
group by rollup( v.genre)
order by Total_Sales desc

-- Total Sales Per Genere for Sales Cases

select isnull(v.genre, 'Total') as Genre ,
sum (case when  v.sales_cases ='High Sales' then global_sales end)   as High_Sales,
sum (case when  v.sales_cases ='Medium Sales' then global_sales end)   As Medium_Sales,
sum (case when  v.sales_cases ='Low Sales' then global_sales end)  as Low_Sales,
sum(global_sales) Total_Sales
from v_video_games v
group by rollup( v.genre )
order by Total_Sales desc
-- #video_games Per Genere for Sales Cases
select isnull(v.genre, '#video_games') as Genre ,
sum (case when  v.sales_cases ='High Sales' then 1 else 0 end)   as High_Sales,
sum (case when  v.sales_cases ='Medium Sales' then 1 else 0 end)   As Medium_Sales,
sum (case when  v.sales_cases ='Low Sales' then 1 else 0 end)  as Low_Sales,
count(*) as #Video_Games
from v_video_games v
group by rollup( v.genre )
order by #Video_Games desc
-----------------------------------
select isnull(v.genre, 'Total') as Genre, 
isnull(v.sales_cases , 'Total') as sales_cases ,
sum(global_sales) Total_Sales
from v_video_games v
group by rollup(  v.genre,v.sales_cases )
order by  v.genre
----------------------

------- The most profitable Video_Games for each  Genere
/*
Make Line Function with Aggregate Function For Return Total Sales 
For Video Games Inside Genere
*/
alter function genre_name()
returns table
as
return
(
select distinct  v.Genre as genre ,v.Name as name ,
sum(global_sales) over(partition by genre ,name order by genre  ) as Total_Sales
from v_video_games v
)

/*
Make Sub Quries For Return The most profitable Video_Games for each  Genere
In This Query Use (sub_query + Call Function ( genre_name()) 
+ Window Function (Row_Number()) + Filtered ( Where)
*/
select*
from(
	select genre , name , Total_Sales ,row_number() 
	over( partition by genre order by Total_sales desc) as Rank
	from(
			select *  from genre_name() 
		)as Genre_name
	) as New_Table
where rank = 1 

-- Total Sales & #video_games Per Publisher
select  isnull(v.publisher, 'Total') as Publisher,sum(global_sales) Total_Sales,
count(*) as #video_games
from v_video_games v
group by rollup( v.publisher)
order by Total_Sales desc

-- Total Sales & #video_games Per Year
select isnull(v.Year, 'Total') as Year,sum(global_sales) Total_Sales,
count(*) as #video_games
from v_video_games v
group by rollup( v.Year)
order by Total_Sales desc
------- The most profitable Video_Games for each  Year
/*
Make Multi Function with Aggregate Function For Return Total Sales 
For Video Games Inside Year
*/
alter function year_name()
returns @t table(Year varchar(20) , name varchar(200), total_sales int)
as
begin
	insert into @t
	select Distinct v.Year as Year ,v.Name as name ,
	sum(global_sales) over(partition by Year ,name order by Year  ) as Total_Sales
	from v_video_games v
	return
end
/*
Make Sub Quries For Return The most profitable Video_Games for each Year
In This Query Use (sub_query + Call Function ( genre_name()) 
+ Window Function (Row_Number()) + Filtered ( Where)
*/
 
select*
from(
	select  Year  , name   , Total_Sales   ,row_number() 
	over( partition by Year order by Total_sales desc ) as Rank
	from(
			select *  from year_name() 
		)as Year_name
	) as New_Table
where rank = 1
----------------------------------------------------
-- Total Sales & Video_Games Per Decade
select distinct v.Decade , 
sum(global_sales) over(partition by decade order by decade) as Total_sales
,count(*) over(partition by decade order by decade) as #Video_Games
from v_video_games v
order by total_sales desc
-- Total Sales By Genre Per Decade
/*
In This Query using (Piovot Table + SubQuery + aggregate Function (sum) + 
String Function(Isnull) + Sorting Date (Order )

*/
select genre ,isnull([1980] ,0) as [1980] ,isnull([1990] ,0) as [1990] ,
isnull([2000] ,0) as [2000] ,isnull([2010] ,0) as [2010] ,
isnull([2020] ,0) as [2020] ,
isnull([1980] ,0)+isnull([1990],0) + isnull([2000] ,0)
+isnull([2010],0)+isnull([2020] ,0)  as total  
from(
select  v.Genre ,  v.Decade    , Global_Sales
from v_video_games v
) as nt
pivot(
	sum(global_sales)
	for Decade  in([1980],[1990],[2000],[2010],[2020] )
) as pt
order by total desc
----------------------------------------------
-- Total Sales & Video_Games Per Decade
select coalesce(v.platform,'Total') , sum(global_sales) Total_Sales 
,count(*) #Video_Games
from v_video_games v
group by rollup(platform)
order by  Total_sales desc
-----------------------------------------------
------- The most profitable Genre for each PlatForm
/*
Make Inline Function with  Cube , Aggregate Function For Return Total Sales 
For Genre Inside Platform
Using (inline Function + Group by + Cube + Isnull() + aggregate function(sum())
*/
alter function Genre_Platform()
returns table
as
return
(
	select  v.platform  As PlatForm ,  v.Genre   As Genre , 
	sum(global_sales) as Total_sales
	from v_video_games v
	group by cube(v.platform , v.Genre )
)
/*
Make Sub Quries For Return The most profitable genre for each platform
In This Query Use (sub_query + Call Function ( platfrom_genre()) 
+ Window Function (Row_Number()) + Filtered ( Where)
*/
select *
from
(
	select Platform , genre , total_sales,DENSE_RANK()
	over(partition by Platform   order by total_sales desc) as Rank
	from
	(
		select * from Genre_Platform()
	) as Genre_Platform
) as New_Table
where   Platform is not NUll and genre is not null and rank =2  
order by total_sales desc
--------------------------------------
 