-- COVID-19 Data Exploration
-- Utilized skills: Converting Data Types, Aggregate Functions, Joins, Temp Tables, CTEs, Window Functions, Creating Views

SELECT [location], [date], total_cases, new_cases, total_deaths, population
FROM CovidDeaths
order by 1,2


-- Looking at Total Cases vs Total Deaths
SELECT [location], [date], total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
order by 1,2


-- Shows the likelihoods of dying if you contract covid in your country
SELECT [location], [date], total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM CovidDeaths
WHERE [location] like '%mexico'
order by 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID
SELECT [location], [date], population, total_cases, (total_cases/population)*100 AS InfectedPopulationPercentage
FROM CovidDeaths
WHERE [location] like '%states%'
order by 1,2


-- Looking at Countries with highest infection rate compared to population
SELECT [location], population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPopulationPercentage
FROM CovidDeaths
Group by location, population
order by InfectedPopulationPercentage DESC


-- Showing countries with the highest death counth per population
SELECT [location], MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
Group by location
order by TotalDeathCount DESC


--Added the WHERE clause because continents were appearing under location too
SELECT [location], MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not NULL
Group by location
order by TotalDeathCount DESC


-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing the continents with the highest death count per population
SELECT [location], MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is NULL
Group by [location]
order by TotalDeathCount DESC


-- Global numbers
SELECT [date], SUM(new_cases) AS total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY [date]
ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2


-- JOINING BOTH TABLES
SELECT *
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]


-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
Where dea.continent is not NULL
ORDER BY 2,3

SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
Where dea.continent is not NULL
ORDER BY 2,3


-- Create a CTE to perform calculations with RollingPeopleVaccinated column 
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
AS (
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
Where dea.continent is not NULL
)
Select *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- Looking at Total Population vs Positive Rate
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.positive_rate
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
Where dea.continent is not NULL
ORDER BY 2,3

SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.positive_rate, SUM(vac.positive_rate) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) AS RollingPositiveRate
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
Where dea.continent is not NULL
ORDER BY 2,3


-- Same as CTE but it is a TEMP TABLE instead (same result)
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(50),
Location nvarchar(50),
Date date,
Population float,
New_vaccinations float,
RollingPeopleVaccinated FLOAT
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
Where dea.continent is not NULL

Select *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
Where dea.continent is not NULL

CREATE VIEW PositiveRates AS
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.positive_rate, SUM(vac.positive_rate) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) AS RollingPositiveRate
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
Where dea.continent is not NULL

CREATE VIEW ICUHospitilizations AS
SELECT dea.continent, dea.[location], dea.[date], dea.icu_patients, vac.total_vaccinations, SUM(vac.total_vaccinations) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
Where dea.continent is not NULL

CREATE VIEW DeathVSVacs AS
SELECT dea.continent, dea.[location], dea.[date], dea.total_deaths, vac.total_vaccinations, SUM(dea.total_deaths) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) AS RollingDeaths
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
Where dea.continent is not NULL