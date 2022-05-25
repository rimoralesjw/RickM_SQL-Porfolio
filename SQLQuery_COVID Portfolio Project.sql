-- Select Data that we are going to be using

Select * 
FROM Portfolio_RMorales..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 2

Select Location, date, total_cases, new_cases, total_deaths, population 
FROM Portfolio_RMorales..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases) *100 as DeathPercentage
FROM Portfolio_RMorales..CovidDeaths
WHERE location like '%states%' AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at the Total of Cases vs Population
-- Show what percentage of population got COVID
SELECT Location, date, population, total_cases, (total_cases/population) *100 as PercentPopulationInfectedUSA
FROM Portfolio_RMorales..CovidDeaths
WHERE location like '%states%' AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at Countries with Highest Infection Rate compared to population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected 
FROM Portfolio_RMorales..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Top 10 Countries with Highest Death Count per Population

SELECT TOP 10 Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM Portfolio_RMorales..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

-- Braking things down by Continent

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM Portfolio_RMorales..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Total of people vaccinated by country

SELECT location, MAX(CAST(people_fully_vaccinated AS int)) AS TotalVaccinated
FROM Portfolio_RMorales.dbo.CovidVaccination
WHERE people_fully_vaccinated IS NOT NULL AND continent IS NOT NULL
GROUP BY location
ORDER BY TotalVaccinated DESC

-- Total of people vaccinated by country

SELECT location, MAX(CAST(people_fully_vaccinated AS int)) AS TotalVaccinated
FROM Portfolio_RMorales.dbo.CovidVaccination
WHERE people_fully_vaccinated IS NOT NULL AND continent IS NOT NULL
GROUP BY location
ORDER BY TotalVaccinated DESC

-- Global Numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, sum(cast
(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
From Portfolio_RMorales..CovidDeaths
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
GROUP BY date
ORDER BY 4 DESC

-- Looking at Total Population vs Vaccination

SELECT TOP 1000 dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM Portfolio_RMorales..CovidDeaths dea
JOIN Portfolio_RMorales..CovidVaccination vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 1,2

-- Getting Population Percentage using CTE

WITH PopsVac (location, date, population, new_vaccinations, RollingPeopleVaccinated) 
AS
(
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM Portfolio_RMorales..CovidDeaths dea
JOIN Portfolio_RMorales..CovidVaccination vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PopulationPercentage
FROM PopsVac 
ORDER BY location, date

-- Creating Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM Portfolio_RMorales..CovidDeaths dea
JOIN Portfolio_RMorales..CovidVaccination vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
SELECT *,
(RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


-- Creating Views to store data for later visualizations

CREATE VIEW GlobalNumbers AS
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, sum(cast
(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
From Portfolio_RMorales..CovidDeaths
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
GROUP BY date

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM Portfolio_RMorales..CovidDeaths dea
JOIN Portfolio_RMorales..CovidVaccination vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
SELECT *,
(RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated
