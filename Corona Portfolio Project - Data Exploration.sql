/*
Corona Data Exploration using SQL

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM CovidDeaths
WHERE continent is not null 
ORDER BY 3,4


SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null 
ORDER BY 1,2

-- Looking at Total Cases vs. Total Deaths
-- Shows likelihood of dying if you contract covid in Israel
SELECT Location, date, total_cases,total_deaths,
ROUND((Total_deaths/total_cases * 100),2, 0) as DeathPercantage
FROM CovidDeaths
WHERE continent is not null and Location = 'Israel'
ORDER BY 2


-- Looking at Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT Location, date, total_cases,population,
ROUND((total_cases/population * 100),2, 0) as CovidPercantage
FROM CovidDeaths
WHERE continent is not null and Location = 'Israel'
ORDER BY 2


-- Looking at Countries with Hightest Infection Rate Compared to Population
SELECT Location, population, Max(total_cases) as HighestInfectionCount,
MAX(ROUND((total_cases/population * 100),2, 0)) as PercantagePopulationInfected
FROM CovidDeaths
GROUP BY Location, population
ORDER BY PercantagePopulationInfected DESC

-- Showing Countries with Highest Death Count per Population

SELECT Location, Max(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC


--Breaking things down by Contient 
-- Showing Contintents with the Highest Death Count per Population
SELECT Location, Max(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is  null
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- Global Numbers
SELECT SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths as int)) as TotalNewDeaths,
ROUND(SUM(cast(new_deaths as int)) / SUM(new_cases) * 100, 2, 0) as DeathPercentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Looking at Total Populations vs. Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population
,vac.new_vaccinations, Sum(CONVERT(int,vac.new_vaccinations)) OVER(Partition by dea.location ORDER BY  
dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3

--Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac(Continent, location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population
,vac.new_vaccinations, Sum(CONVERT(int,vac.new_vaccinations)) OVER(Partition by dea.location ORDER BY  
dea.location, dea.date) as RollingPeopleVaccinated 
--(RollingPeopleVaccinated/Population) * 100
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, ROUND(RollingPeopleVaccinated/population * 100, 2, 0) as RollingPeopleVaccinatedPercentage
FROM PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths as dea
Join CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100 as RollingPeopleVaccinatedPercentage
FROM #PercentPopulationVaccinated





-- Creating View to store data for visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths as dea
Join CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 


