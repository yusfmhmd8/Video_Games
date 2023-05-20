--------------------- ETL Use Sql ----------------------------------
-- remvoe (year) From name 
update Video_Games
set name = CASE
				when Charindex ('(', name) >0
				THEN Substring (name, 1, Charindex ('(', name)-1 )
				ELSE name
		  end	  
select name
from video_games
where name like '%(%'

----- Update Year NULL To NA
--select * from video_games where year is null
alter table video_games
alter column year varchar(20)
update video_games 
set year = case
				when year ='0' then  'NA'
				else year
			end
select year
from video_games
where year ='NA'
---------------------------------

------ Remove Columns After Make ETL by SSIS
create proc remove_column
as
alter table video_games
drop column NA_Sales
go
alter table video_games
drop column EU_Sales
go
alter table video_games
drop column JP_Sales
go
alter table video_games
drop column [Data Conversion.Other_Sales]
go
alter table video_games
drop column [Data Conversion.Global_Sales]
exec remove_column

--------------- Rename Columns

create proc Rename_Columns
as
EXEC sp_rename  'Video_Games.[Excel Source.Other_Sales]' , 'Other_Sales'
EXEC sp_rename  'Video_Games.[Excel Source.Global_Sales]' , 'Global_Sales'
exec Rename_Columns

---- Delete The Bottom Row

delete from Video_Games
where rank = 16599

-------------- Make View Form Fact Table ( video_games)
-- 1. Add Decade column for knowing the decade for each year
-- 2. Add Sales_Cases Column For following up sales 
-- 3. Making Casting as Descimel For Columns (North_America_Sales , Europe_Sales , Japn_Sales)
alter view v_video_games
as
	select v.rank as Rank,v.Name,v.Platform,v.Genre , v.Year ,
	case
		when year = 'NA' Then 'NA'
		else concat (left(v.year,3),'0')
	end as Decade, 
	cast(v.North_America_Sales as decimal) as North_America_Sales, 
	cast(v.Europe_Sales as decimal) as Europe_Sales ,
	cast(v.Jpan_Sales as decimal) as Jpan_Sales,
	v.Other_Sales,v.Global_Sales,
	case 
		when Global_Sales >= 1000000 then 'High Sales'
		when Global_Sales < 1000000  and Global_Sales > 300000  then 'Medium Sales'
		else 'Low Sales'
	end as Sales_Cases
	from Video_Games v