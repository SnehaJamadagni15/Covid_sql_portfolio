select location,date,total_cases,new_cases,total_deaths,
population from coviddeath;

select * from coviddeath;

--death percentage countrywise--
select date,location,cast((total_deaths/total_cases)*100 as numeric(10,2))as "death_percentage",total_cases,total_deaths
from coviddeath
where continent is not null
order by 2 desc;

alter table coviddeath alter column total_deaths type numeric;
alter table coviddeath alter column total_cases type numeric;

--total cases vs population---
select location,date,population,total_cases from coviddeath
order by date desc;

--what percentage of population get covid--
select date,location,population,cast((total_cases/population)*100 as numeric(10,2))as "total_cases_percentage",total_cases,total_deaths
from coviddeath
where continent is not null;


--what country having highest infection rate--
select location,population,max(total_cases)as total_cases,
max (total_cases/population)*100 as highest_infected_population
from coviddeath
where (total_cases/population)*100 is not null
and continent is not null
group by location,population
order by highest_infected_population desc;

--SHOWING COUNTRY WITH HIGHEST DEATH COUNT PER POPULATION--
select location,population,max(total_deaths) as totaldeathcount,
cast(max(total_deaths/population)*100 as numeric(10,2)) as highest_death_per_population
from coviddeath
where (total_deaths/population)*100 is not null
and continent is not null
group by location,population
order by highest_death_per_population desc;

select location,continent,max(total_deaths)as totaldeathcount
from coviddeath
where continent is   null
group by location,continent;

--showing continent with highest death count per population--
select continent,max(total_deaths) as totaldeathcount
from coviddeath
where continent is not null and (total_deaths) is not null
group by continent
order by totaldeathcount desc;

--global numbers--
select date,max(total_deaths) as totaldeathcount
from coviddeath
where continent is not null and (total_deaths) is not null
group by date
order by totaldeathcount desc;

--calculating death percentage--
select date,sum(new_cases) as totalcases,sum(new_deaths)as totaldeaths,
round(sum(cast(new_deaths as numeric))/sum(new_cases)*100 ,2) as deathpercentage
from coviddeath
where continent is not null and new_cases is not null
group by date
order by deathpercentage desc;


join table
select * from coviddeath cd 
join covidvaccination cv on
cd.location=cv.location and cd.date=cv.date;

--looing at total pupulation vs vaccination
select max(population) as total_population,cd.location,max(total_vaccinations)as total_vaccination
from coviddeath cd 
join covidvaccination cv on
cd.location=cv.location and cd.date=cv.date
where cd.location is not null and total_vaccinations is not null
group by cd.location
order by total_vaccination desc

--looking at total population vs per day vaccination--
select cd.date,population,cd.location,new_vaccinations,cd.continent
from coviddeath cd 
join covidvaccination cv on
cd.location=cv.location and cd.date=cv.date
where cd.location is not null and new_vaccinations is not null
and cd.continent is not null
order by new_vaccinations desc;




select cd.date,population,cd.location,new_vaccinations,cd.continent,
sum(cast (cv.new_vaccinations as numeric))over (partition by cd.location
order by cd.location,cd.date)as newvacbylocation,
round((sum(cast (cv.new_vaccinations as numeric))over (partition by cd.location
order by cd.location,cd.date)/population)*100,2) as vaccinationpercentage
from coviddeath cd 
join covidvaccination cv on
cd.location=cv.location and cd.date=cv.date
where cd.location is not null and new_vaccinations is not null
and cd.continent is not null 
group by cd.date,population,cd.location,new_vaccinations,cd.continent
order by  vaccinationpercentage desc;


--alternative using CTE---


with popvsvac as(
select cd.date,population,cd.location,cv.new_vaccinations,cd.continent,
sum(cast (cv.new_vaccinations as numeric))over (partition by cd.location
order by cd.location,cd.date)as newvacbylocation
--round((sum(cast (cv.new_vaccinations as numeric))over (partition by cd.location
--order by cd.location,cd.date)/population)*100,2) as vaccinationpercentage
from coviddeath cd 
join covidvaccination cv on
cd.location=cv.location and cd.date=cv.date
where cd.location is not null and new_vaccinations is not null
and cd.continent is not null 
group by cd.date,population,cd.location,new_vaccinations,cd.continent
order by newvacbylocation  desc)

select continent,location,new_vaccinations,population,
((cast(newvacbylocation as numeric )/population)*100)as rollednewvacpercentage from popvsvac ;


--Temp Table---

create table temp_popvsvac(
	continent varchar(100),location varchar(100),
	date date,
	population numeric,
	new_vaccinations numeric ,
	newvacbylocation numeric)

insert into temp_popvsvac
select cd.continent,cd.location, cd.date,  population, new_vaccinations, 
	(sum(new_vaccinations) over (partition by cd.location order by cd.location, cd.date)) 
	as newvacbylocation --- cumulative
	from coviddeath cd
join covidvaccination cv
on cd.date= cv.date and cd.location= cv.location
	where cd.location is not null and cd.continent is not null and new_vaccinations is not null 
	group by cd.continent, cd.location,cd.date, population, new_vaccinations
	order by newvacbylocation desc;

select continent,location, date,  population, new_vaccinations,
	round((newvacbylocation/population)*100,2) as rolled_new_vaccination_percent
from temp_popvsvac;


----views----


create view popvsvac_view as(
select cd.continent,cd.location, cd.date,  population, new_vaccinations, 
	(sum(new_vaccinations) over (partition by cd.location order by cd.location, cd.date)) 
	as newvacbylocation --- cumulative
	from coviddeath cd
join covidvaccination cv
on cd.date= cv.date and cd.location= cv.location
	where cd.location is not null and cd.continent is not null and new_vaccinations is not null 
	group by cd.continent, cd.location,cd.date, population, new_vaccinations
	order by newvacbylocation desc);

drop view  popvsvac_view;

select continent,location, date,  population, new_vaccinations,
	round((newvacbylocation/population)*100,2) as rolled_new_vaccination_percent
from popvsvac_view;

alter table covidvaccination alter column new_vaccinations type numeric;