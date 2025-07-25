/*
Covid 19 data Exploration

Skills used: Joins, CTE's, Temp Tables, Window Function, Aggregate Functions, Creating Views, Converting Data Types

*/

select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--select *
--from PortfolioProject..CovidVaccinations
--order by 3,4

-- select data that we are going to be using 

SELECT location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
Order by 1

-- Looking at total cases vs. total deaths
-- shows likelihood of dying if you contract COVID
	
SELECT location, date, total_cases, total_deaths, 
		CONCAT(ROUND((total_deaths/NULLIF(total_cases,0))*100,2),'%')as DeathPercentage
FROM PortfolioProject..CovidDeaths
--where location like '%states%'
Order by 1

-- Looking at Total cases vs. Population
-- Shows percentage of population infected by COVID
	
SELECT location, date, population,total_cases, 
		CONCAT(ROUND((total_cases/NULLIF(population,0))*100,2),'%')as InfectedPercentage
FROM PortfolioProject..CovidDeaths
--where location like '%states%'
Order by 1

-- Countries with Highest infection rate compared to Population
	
SELECT location, population,MAX(total_cases)as HighestInfectionCount, 
		CONCAT(MAX((total_cases/NULLIF(population,0)))*100,2,'%')as InfectedPercentage
FROM PortfolioProject..CovidDeaths
where continent <> ' '
Group by location, population
Order by InfectedPercentage desc

--Countries with the highest death count per population

SELECT location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent is not null
	and continent <> ' '
Group by location
Order by TotalDeathCount desc

--break things down by continent
	
--Showing the continents with the highest death count per population

SELECT continent, SUM(cast(new_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent is not null
	and continent <> ' '
Group by continent
order by TotalDeathCount desc


-- Global Numbers

SELECT date,sum(new_cases)as Total_cases, SUM(new_deaths)as Total_deaths, NULLIF(SUM(new_deaths),0)/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
where continent <> ' '
group by date
Order by 1

-- The total cases and total death count for the world
	
SELECT sum(new_cases)as Total_cases, SUM(new_deaths)as Total_deaths, NULLIF(SUM(new_deaths),0)/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
where continent <> ' '
Order by 1


--Total population vs. Vaccination 
	
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location =vac.location 
	and dea.date = vac.date
where dea.continent <> ' '
order by 2

-- Shows percentage of Population that has received at least one Covid Vaccine 
	
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location =vac.location 
	and dea.date = vac.date
where dea.continent <> ' '
order by 2

--Total number of people vaccinated per country
-- USE CTE to perform calculation on Partition By in previous query
	
with PopvsVac (Continent, Location, Date, Populaton, New_Vaccinations, RollingPeopleVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location =vac.location 
	and dea.date = vac.date
where dea.continent <> ' '
)
select *, (NULLIF(RollingPeopleVaccinated,0)/Populaton)*100 as PercentPeopleVaccinated
from PopvsVac


--Using TEMP TABLE to perform calculation on Partition By in previous query

DROP table if exists #Percent_PopulationVaccinated
Create table #Percent_PopulationVaccinated
(
Continent nvarchar(50),
Location nvarchar(50),
Date date,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #Percent_PopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, isnumeric(vac.new_vaccinations),
 SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location =vac.location 
	and dea.date = vac.date
where dea.continent <> ' '

select *, (NULLIF(RollingPeopleVaccinated,0)/population)*100 as PercentPeopleVaccinated
from #Percent_PopulationVaccinated


--Creating view to store data for visualizations

Create View Percent_PopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location =vac.location 
	and dea.date = vac.date
where dea.continent <> ' '

-- Shows Percentage of Population vaccinated using previously created View
	
select *, (NULLIF(RollingPeopleVaccinated,0)/population)*100 as PercentPeopleVaccinated
from Percent_PopulationVaccinated
