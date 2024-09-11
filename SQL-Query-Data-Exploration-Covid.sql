--Select *
--From PortfolioProjects..CovidVaccinations
--order by 3,4


Select * 
From PortfolioProjects..CovidDeaths
where continent is not null
order by 3, 4

--Select Data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProjects..CovidDeaths
where continent is not null
order by 1, 2

-- Looking at total cases vs Total Deaths
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProjects..CovidDeaths
where continent is not null
order by 1, 2 

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    CASE 
        WHEN total_cases = 0 THEN 0 
        ELSE (total_deaths / total_cases) * 100 
    END AS DeathPercentage
FROM 
    PortfolioProjects..CovidDeaths
WHERE location like '%states%' and continent is not null
ORDER BY 1, 2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid
SELECT 
    location, 
    date, 
    total_cases, 
    population, 
    CASE 
        WHEN total_cases = 0 THEN 0 
        ELSE (total_cases / population) * 100 
    END AS PercentPopulationInfected
FROM 
    PortfolioProjects..CovidDeaths
where continent is not null
ORDER BY 1, 2

-- Looking at Countries with Highest Infection Rate Compared to Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, 
    CASE 
        WHEN MAX(total_cases) = 0 or population = 0 THEN 0 
        ELSE MAX((total_cases / population)) * 100 
    END AS PercentPopulationInfected
FROM PortfolioProjects..CovidDeaths
where continent is not null
Group by location, population
ORDER BY PercentPopulationInfected desc

--Showing countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
where continent is not null
Group by location
ORDER BY  TotalDeathCount desc

--let's break things by continent

--Showing continents with the highest death count per population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
where continent is null
Group by location
ORDER BY  TotalDeathCount desc

--correct query:
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
where continent is not null
Group by continent
ORDER BY  TotalDeathCount desc

--Global Numbers
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,  
		SUM(cast(new_deaths as int))/Sum(new_cases) *100 as DeathPercentage 

FROM    PortfolioProjects..CovidDeaths
where continent is not null
Group by date
ORDER BY 1, 2 

--first query for tableu table 1
SELECT 
   
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS int)) AS total_deaths,  
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0 
        ELSE SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 
    END AS DeathPercentage
FROM    
    PortfolioProjects..CovidDeaths
WHERE 
    continent IS NOT NULL

ORDER BY 
    1, 2

-- query 2 for tableu table 2
--European Union is part of Europe

SELECT 
    location, 
    SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM 
    PortfolioProjects..CovidDeaths
WHERE 
    continent IS NULL
    AND location NOT IN ('World', 
                         'European Union (27)', 
                         'International', 
                         'High-income countries',
                         'Upper-middle-income countries', 
                         'Lower-middle-income countries',
                         'Low-income countries')
GROUP BY 
    location
ORDER BY 
    TotalDeathCount DESC;


--query 3 for tableu table 3
SELECT location, population, MAX(total_cases) as HighestInfectionCount, 
    CASE 
        WHEN MAX(total_cases) = 0 or population = 0 THEN 0 
        ELSE MAX((total_cases / population)) * 100 
    END AS PercentPopulationInfected
FROM PortfolioProjects..CovidDeaths
Group by location, population
ORDER BY PercentPopulationInfected desc

--query 4 for tableu table 4
Select location, population, date, MAX(total_cases) as HighestInfectionCount, 
	MAX((total_cases/population)) * 100 as PercentPopulationInfected
From PortfolioProjects..CovidDeaths
Group by location, population, date
Order by PercentPopulationInfected desc
 
Select * from PortfolioProjects..CovidVaccinations



-- Looking at total population vs vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProjects..CovidDeaths dea
Join PortfolioProjects..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2 ,3 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(COALESCE(CONVERT(BIGINT, vac.new_vaccinations), 0)) OVER (Partition by dea.location order by dea.date) as cumulativeVaccinations
	
From PortfolioProjects..CovidDeaths dea
Join PortfolioProjects..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by dea.location, dea.date

--USE CTE
WITH PopVsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations, 
        SUM(COALESCE(CONVERT(BIGINT, vac.new_vaccinations), 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS cumulativeVaccinations
    FROM 
        PortfolioProjects..CovidDeaths dea
    JOIN 
        PortfolioProjects..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)

SELECT 
    continent, 
    location, 
    date, 
    population, 
    new_vaccinations, 
    CumulativeVaccinations
FROM 
    PopVsVac
ORDER BY 
    location, 
    date;


--temp table
-- Step 1: Create the temporary table
CREATE TABLE #PopVsVacTemp (
    continent NVARCHAR(50),
    location NVARCHAR(100),
    date DATE,
    population BIGINT,
    new_vaccinations BIGINT,
    CumulativeVaccinations BIGINT
);

-- Step 2: Use CTE to calculate cumulative vaccinations and insert into the temp table
WITH PopVsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations, 
        SUM(COALESCE(CONVERT(BIGINT, vac.new_vaccinations), 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS CumulativeVaccinations
    FROM 
        PortfolioProjects..CovidDeaths dea
    JOIN 
        PortfolioProjects..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
-- Insert the result of the CTE into the temporary table
INSERT INTO #PopVsVacTemp (continent, location, date, population, new_vaccinations, CumulativeVaccinations)
SELECT 
    continent, 
    location, 
    date, 
    population, 
    new_vaccinations, 
    CumulativeVaccinations
FROM 
    PopVsVac;

-- Step 3: Select data from the temporary table
SELECT 
    continent, 
    location, 
    date, 
    population, 
    new_vaccinations, 
    CumulativeVaccinations
FROM 
    #PopVsVacTemp
ORDER BY 
    location, 
    date;

-- Optional: Drop the temporary table when done
DROP TABLE #PopVsVacTemp;

-- creating view to store data for later visualizations

CREATE VIEW dbo.PopVsVacView AS
WITH PopVsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations, 
        SUM(COALESCE(CONVERT(BIGINT, vac.new_vaccinations), 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS CumulativeVaccinations
    FROM 
        PortfolioProjects..CovidDeaths dea
    JOIN 
        PortfolioProjects..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
SELECT 
    continent, 
    location, 
    date, 
    population, 
    new_vaccinations, 
    CumulativeVaccinations
FROM 
    PopVsVac;


SELECT * 
FROM dbo.PopVsVacView
WHERE continent is not null
ORDER BY location, date;









