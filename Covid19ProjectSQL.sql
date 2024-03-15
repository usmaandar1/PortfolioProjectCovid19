
--INTRODUCTION


select*
from SQLProjectPortfolio..[Covid Deaths]
order by 3,4


select*
from SQLProjectPortfolio..[Covid Vaccinations]
order by 3,4

--Quick note to say; since I do not have an excel licence nor will Excel online permit file editing exceeding 25MB...
--I've had to learn how to get my OpenOffice files into SQL SSMS; what would normally have taken 10 minutes took 2 hours in total...
--This is bc of size of the files (>100MB), using software which is rarely used in industry (OpenOffice) and learning how to import CSV files into SSMS (bc the route is different than for standard Excel files).
-- In all, I took a very new and longer route to getting to the start position. A highly frustrating but great learning route so far...



-- START OF PROJECT 

-- Selecting data we are using
select location, date, total_cases, new_cases, total_deaths, population
from SQLProjectPortfolio..[Covid Deaths]
order by 1,2


--Looking at total_cases v total_deaths
select location, date, total_cases, total_deaths, try_cast(total_deaths as int) / try_cast(total_cases as int)
from [Covid Deaths]
order by 1,2

SELECT
      Location, [date], total_cases, total_deaths, (TRY_CAST(total_deaths AS NUMERIC(10, 2)) / NULLIF(TRY_CAST(total_cases AS NUMERIC(10, 2)), 0)) * 100.0 AS DeathPercentage
FROM [Covid Deaths]
ORDER BY
      Location
    , [date]


-- Checking the USA
SELECT
      Location, [date], total_cases, total_deaths, (TRY_CAST(total_deaths AS NUMERIC(10, 2)) / NULLIF(TRY_CAST(total_cases AS NUMERIC(10, 2)), 0)) * 100.0 AS DeathPercentage
FROM [Covid Deaths]
WHERE location like '%states%'
ORDER BY
      Location
    , [date]


-- LOOKING AT TOTAL CASES V POPULATION
select location, date, population, (try_cast(total_cases as numeric)/ try_cast(population as numeric))*100 as percetage_infected
from [Covid Deaths]
order by location, date


-- who has the highest infection rate compared to population?
select location, population, MAX(total_cases) as highest_infection_count, MAX(TRY_CAST(total_cases as numeric) / TRY_CAST(population as numeric))*100 as percentage_infected
from [Covid Deaths]
group by location, population
order by percentage_infected desc


-- Countries with the highest death count per population 
select location, population, TRY_CAST(max(total_deaths) as numeric) as highest_death_count, MAX(TRY_CAST(total_deaths as numeric))/MAX(TRY_CAST(total_cases as numeric))*100 as percent_death_rate_of_infected, MAX(TRY_CAST(total_deaths as numeric))/MAX(TRY_CAST(population as numeric))*100 as percent_of_population_dead
from [Covid Deaths]
where continent is not null 
and not location in ('Africa', 'North America', 'European Union', 'South America', 'Europe', 'World', 'Oceania', 'Asia') 
and not location like '%income'
group by location, population
order by highest_death_count desc

-- Notes
--A. even though the first where statement removed the continents from interfering with the data,
--B. there were continents listed in the location column alongside other wildcards like World or high income or middle income
--C. I would first need to individually list out the continents in the second where column to remove them from the location column
--D. I would then need to include a third where statement which specifically dealt with the rows that grouped nations as high middle or low income
--E. Issues with the data when ordering by population. I would need to Try_cast(population as numeric) to make this work.
--F. The data is now clean 



-- CONTINENTS WITH THE HIGHEST DEATH COUNT PER POPULATION
select continent, max(TRY_CAST(total_deaths as numeric)) as total_deaths
from [Covid Deaths]
where continent is not null
and not continent like ''
group by continent
order by total_deaths desc


-- Notes
--A. Null continent value still present even after where statement presented so additional where statement added to remove the null value.



-- GLOBAL NUMBERS INCL NO OF INFECTED AND NO OF DEATHS AND DEATH RATE
select date, sum(try_cast(new_cases as numeric)) as total_cases, sum(try_cast(new_deaths as numeric)) as total_deaths, try_cast(new_deaths as numeric)/ nullif(try_cast(new_cases as numeric(10,2)),0)*100 as death_percentage
from [Covid Deaths]
where location like 'world'
group by date, new_cases, new_deaths
order by death_percentage asc



-- TOTAL WORLD CASES AND DEATHS
--select sum(try_cast(new_cases as numeric)) as total_cases, sum(try_cast(new_deaths as numeric)) as total_deaths, try_cast(new_deaths as numeric)/ nullif(try_cast(new_cases as numeric),0)*100 as death_percentage
--from [Covid Deaths]
--where location like 'world'
--group by new_cases, new_deaths


select location, sum(try_cast(new_cases as numeric)) as total_cases, sum(try_cast(new_deaths as numeric)) as total_deaths, sum(try_cast(new_deaths as numeric))/sum(try_cast(new_cases as numeric))*100 as Death_Percentage
from [Covid Deaths]
where location like 'world'
group by location


--Notes
-- so this code does work but the problem is that I was only supposed to have one line showing me the global cases and global deaths and global death percentage. 
-- Why is it giving me death percentages for every country? 
-- Right, after checking the original Deaths table, it turns out there are lots of rows called 'World'. It is giving the numbers as they were recorded at that date in time. 
-- I have to group the location and date. I have done neither.
-- No, this doesn't work so what do I do? I've just tried grouping the location and dates (no change)
-- I tried looking at just the new_cases on its own with the sum function but it keeps giving me an error 'Incorrect syntax near the keyword 'from'.
-- I will come back to this. 
-- Ok, it turns out intellisense is not working and is a known bug/error with SSMS 18.9 and 19 (the one I have). The invalid column names which actually are valid still run fine so I will try to run the code without intellisense. 
-- To clarify intellisense tells me the columns names are invalid but I'll try to ignore these and see if the error reappears.
-- I figured it out - it took a whole damn week but it worked! Essentially, the code was fine but it was the SSMS 19.0 that was the issue. The problem had lasted a week but I had no idea. 
-- I just had to keep trying until the SQL SSMS finally sorted itself out.



-- JOINING THE DEATHS TABLE AND VACCINATIONS TABLE
select *
from [Covid Deaths] as dea
join [Covid Vaccinations] as vac
	on dea.location = vac.location
	and dea.date = vac.date



-- LOOKING AT TOTAL POPULATION V VACCINATIONS
select dea.continent, dea.location, dea.date, population, vac.total_vaccinations
from [Covid Deaths] as dea
join [Covid Vaccinations] as vac
	on dea.location = vac.location
	and dea.date = vac.date
order by 2, 3



-- using partition by to create a rolling count of new vaccinations for each country, for each day, in a separate column
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations, sum(try_cast(vac.new_vaccinations as numeric)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from [Covid Deaths] as dea
join [Covid Vaccinations] as vac
	on dea.location = vac.location
	and dea.date = vac.date
order by 2, 3



--Notes
-- Once I've joined the tables I don't need to keep including the join function in each query. I've only done so for my own understanding.
-- Each query is kept separate from the last so I can understand any errors which many arise.



-- creating a CTE to carry out further calculations.
with PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations, sum(try_cast(vac.new_vaccinations as numeric)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from [Covid Deaths] as dea
join [Covid Vaccinations] as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)

select *, (rolling_people_vaccinated / population)*100 as percentage_vaccinated
from PopvsVac



--Notes
-- So, the above select statement cannot run without the CTE query being run as well. 
-- The With statement defines the table name and in brackets are the columns I will use. 
-- I simply copy the prior query I was using i.e. It's like I've created a duplicate table. 
-- I have to keep executing the same query though bc the CTE is not stored anywhere. It's erased once I'm done a calculation for e.g.



-- creating a temp table
drop table if exists #PercentagePopulationVaccinated
create table #PercentagePopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

insert into #PercentagePopulationVaccinated
select dea.continent, dea.location, dea.date, try_cast(population as numeric), try_cast(vac.new_vaccinations as numeric), sum(try_cast(vac.new_vaccinations as numeric)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from [Covid Deaths] as dea
join [Covid Vaccinations] as vac
	on dea.location = vac.location
	and dea.date = vac.date

select *, (try_cast(rolling_people_vaccinated as numeric)/try_cast(population as numeric))*100 as percentage_vaccinated
from #PercentagePopulationVaccinated



--Notes 
-- This took a shorter while to understand, but a while nonetheless. I narrowed the 'Error converting data type varchar to numeric' to the values I wanted to insert into the new temp table.
-- In my temp table I wanted my population data, for example, to be numeric, but in the original table they are varchar (variable characters) so the error appears. 
-- Therefore, I had to cast all columns as numeric where they are labelled as numeric in my new temp table. 
-- The temp table now works fine. 


--A CTE (common table expression) and temp table are very similar with few key differences. 
--A CTE exists only within the query itself i.e. from select to the ending(;). Outside of this, you have to re-run the whole query plus whatever additional queries you wanted to make. 
--Since you have to keep rerunning the same query it is slower than using a temp table. 
--Using a CTE is beneficial if you wanted to run a query but didn not want to save the result i.e. once the query is complete the data is not stored and is erased till you run the same query again. 

--A temp table differs from a CTE whereby; once you have created the temporary table, it will exist until the end of the session unlike a CTE which lasts till the end of the query itself. 
--This is beneficial since you can create an additional table where you commit detailed queries without touching the original data. Once the session is complete, the temp table is automatically erased. 
--Since you do not have to re-run the same query to create the temp table, it is quicker than using a CTE. The former is therefore unlikely to be used as much as a temp table. 



--USING 'CREATE VIEW' TO STORE DATA FOR LATER VISUALISATIONS
create view PercentagePopulationVaccinated as
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations, sum(try_cast(vac.new_vaccinations as numeric)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from [Covid Deaths] as dea
join [Covid Vaccinations] as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3



--Notes
-- Creating a view is a good way to hide all the complexities of querying data. 
-- So, as a way to avoid re writing or showcasing everything we've done above, creating a view is almost like creating a new table
-- All the data we want to use later we can create a view which is permanent i.e. we have to manually delete this unlike a CTE or temp table. 
-- All we do next is take the view and upload it to Tableau, for example, where we can create visualisations.
-- We can create multiple views to create multiple visualisations.




-- End of project
