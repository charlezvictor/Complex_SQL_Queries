SELECT * 
FROM olympics_history

-- Question 1
-- Identify the sports that was played in all summer olympics
-- Solution Steps
with t1 as
	(Select count(distinct games) as no_times_played
	 from olympics_history
	where season = 'Summer'
	),
t2 as
	(SELECT distinct sport, games
	 from olympics_history
	 where season = 'Summer'
	 order by 1
	 ),
t3 as
	(select sport, count(games) as no_of_games
	 from t2
	 group by sport
	)
select *
from t3
join t1 
on t1.no_times_played = t3.no_of_games

-- Question 2
-- 5 athletes who have won the most gold medal
with t1 as
	(select distinct name, team, count(medal) as total_gold_medals
	from olympics_history
	where medal = 'Gold'
	group by 1,2
	order by 3 desc),
t2 as
	(select *, dense_rank() over (order by total_gold_medals desc)as rnk
	 from t1
	)
Select *
from t2
where rnk <= 5;


-- Question 3
--Total number of gold, silver and bronze won by each country
Select nr.region as country, medal, count(medal) as no_of_medals
from olympics_history oh
join olympics_history_noc_regions nr
on nr.noc = oh.noc
where medal <> 'NA'
group by 1,2
order by 1 desc

create extension tablefunc

select country,
coalesce (gold,0) as gold,
coalesce (silver,0) as silver,
coalesce (bronze,0) as bronze
from crosstab('Select nr.region as country, medal, count(medal) as no_of_medals
				from olympics_history oh
				join olympics_history_noc_regions nr
				on nr.noc = oh.noc
				where medal <> ''NA''
				group by 1,2
				order by 1 desc',
			 	'values (''Bronze''),(''Gold''),(''Silver'')')
			as result(country varchar, bronze bigint, gold bigint, silver bigint)
			order by gold desc, silver desc, bronze desc
			
-- Question 4
--Country that won highest gold, silver nd bronze each summer game
with temp as(
	select substring (games_country,  1, position(' - ' in games_country) -1) as games,
	substring (games_country, position(' - ' in games_country) +3) as country,
	coalesce (gold,0) as gold,
	coalesce (silver,0) as silver,
	coalesce (bronze,0) as bronze
	from crosstab('Select concat(games, '' - '', nr.region) as games_country, medal, count(medal) as no_of_medals
					from olympics_history oh
					join olympics_history_noc_regions nr
					on nr.noc = oh.noc
					where medal <> ''NA''
					group by 1,2
					order by 1 desc',
					'values (''Bronze''),(''Gold''),(''Silver'')')
				as result(games_country varchar, bronze bigint, gold bigint, silver bigint)
				order by games_country
	)
select distinct games,
concat(first_value(country) over (partition by games order by gold desc), ' - ', first_value(gold) over (partition by games order by gold desc) ) as gold,
concat(first_value(country) over (partition by games order by silver desc), ' - ', first_value(silver) over (partition by games order by silver desc) ) as silver,
concat(first_value(country) over (partition by games order by bronze desc), ' - ', first_value(bronze) over (partition by games order by bronze desc) ) as bronze
from temp
order by 1