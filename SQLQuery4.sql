--Data is taken from https://ourworldindata.org/covid-deaths
--from Alex The Analyst's YouTube video:  https://youtu.be/qfyynHBFOsM?si=hBnpnlJYssFlenW-


Select *
From PortfolioProject.dbo.CovidDeaths
Order by 3,4

Select *
From PortfolioProject.dbo.CovidVaccinations
Order by 3,4

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject.dbo.CovidDeaths
Order by 1,2


Converting empty cells into Null:
Update PortfolioProject.dbo.CovidDeaths
Set total_deaths = NULLIF(total_deaths, ' ')
Where total_deaths = ' ';

Update PortfolioProject.dbo.CovidDeaths
Set total_cases = NULLIF(total_cases, ' ')
Where total_cases = ' ';

Update PortfolioProject.dbo.CovidDeaths
Set continent = NULLIF(continent, ' ')
Where continent = ' ';

Converting dates and updating them in the table in 'date' column from DD-MM-YY into YYYY-MM-DD HH:MM:SS format
UPDATE PortfolioProject.dbo.CovidDeaths
SET date = CONVERT(VARCHAR(50), CONVERT(DATETIME, date, 3), 120);


--Calculating death percentage by location
Select location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT) /CAST(total_cases AS FLOAT)*100) AS DeathPercentage
From PortfolioProject.dbo.CovidDeaths
where location = 'Uzbekistan'
Order by 1,2;

--Looking at Total Cases vs Population, shows what percentage of population got Covid
Select location, date, total_cases, population, (CAST(total_cases AS FLOAT) /CAST(population AS FLOAT)*100) AS CovidPercentage
From PortfolioProject.dbo.CovidDeaths
where location = 'United States'
Order by 1,2;

--Updating total_cases, population, total_deaths columns from varchar to float
ALTER TABLE PortfolioProject.dbo.CovidDeaths
ALTER COLUMN total_cases
FLOAT;

ALTER TABLE PortfolioProject.dbo.CovidDeaths
ALTER COLUMN population
FLOAT;

ALTER TABLE PortfolioProject.dbo.CovidDeaths
ALTER COLUMN total_deaths
FLOAT;

--Looking at countries with highest infection rate vs population
Select location, population, MAX(total_cases), MAX(total_cases/population)*100 AS PercPopInfected
From PortfolioProject.dbo.CovidDeaths
--Where location = 'United States'
Group by location, population
Order by PercPopInfected desc;

--Filtering out the continents' data
Select *
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
Order by 3,4

--Showing countries(where continent is not null) or continents(-''- is null) with the highest death count per population
Select location, MAX(total_deaths) as TotalDeathCount
From PortfolioProject.dbo.CovidDeaths
Where continent is Null
Group by location
Order by TotalDeathCount desc;

--Updating new_cases and new_deaths column from varchar to float
ALTER TABLE PortfolioProject.dbo.CovidDeaths
ALTER COLUMN new_deaths
FLOAT;

--Converting cells with 0 into Null:
Update PortfolioProject.dbo.CovidDeaths
Set new_cases = NULLIF(new_cases, 0)
Where new_cases = 0;

--Global Numbers
Select date, SUM(new_cases) as TotalCases, SUM(new_deaths) TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage --, total_deaths, (total_deaths /total_cases)*100 AS DeathPercentage
From PortfolioProject.dbo.CovidDeaths
--where location = 'Uzbekistan'
Where continent is not Null
Group by date
Order by 1,2;

----Converting dates and updating them in the table in 'date' column from DD-MM-YY into YYYY-MM-DD HH:MM:SS format
UPDATE PortfolioProject.dbo.CovidVaccinations
SET date = CONVERT(VARCHAR(50), CONVERT(DATETIME, date, 3), 120);

--Updating new_cases and new_deaths column from varchar to float
ALTER TABLE PortfolioProject.dbo.CovidVaccinations
ALTER COLUMN new_vaccinations
FLOAT;


--Joining the 2 big tables together
Select *
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not Null
Order by 2, 3

--CTE

With PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/dea.population)*100
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not Null
--Order by 2, 3
)
Select *, (RollingPeopleVaccinated/population)*100 as PercTotPopVac
From PopVsVac

--Temp Table
Drop Table if exists #PercentPopulationVaccinatedI
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/dea.population)*100
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--Where dea.continent is not Null
--Order by 2, 3

Select *, (RollingPeopleVaccinated/population)*100 as PercTotPopVac
From #PercentPopulationVaccinated


--Creating View to store data for later visualizations

Create View PercentPopulationVaccinatedI as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/dea.population)*100
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not Null
--Order by 2, 3

Select *
From PercentPopulationVaccinatedI

