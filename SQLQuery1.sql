--viewing the Covid Deaths table
SELECT *
FROM ProjectPortfolio..CovidDeaths$
ORDER BY 3,4

----viewing the Covid Deaths table
SELECT *
FROM ProjectPortfolio..CovidVaccinations$
ORDER BY 3,4

-- Select data that we will primarily use
SELECT location, date, total_cases, new_cases, total_deaths, population 	
FROM ProjectPortfolio..CovidDeaths$ 
ORDER BY 1,2

-- Looking at Total cases vs Total deaths of all countries
SELECT location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 AS Mortality_Rate
FROM ProjectPortfolio..CovidDeaths$
ORDER BY 1,2

-- Comparing Total cases vs Total deaths of India
SELECT location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 AS Mortality_Rate
FROM ProjectPortfolio..CovidDeaths$
Where location = 'India';

-- OR 
--But here order by works 
--SELECT location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 AS Mortality_Rate
--FROM ProjectPortfolio..CovidDeaths$
--Where location like '%India%'
--Order by 1,2

--Looking at total cases vs population for India
SELECT location, date, total_cases, population,(total_cases/population)*100 AS Population_Affected
FROM ProjectPortfolio..CovidDeaths$
Where location = 'India';

--Looking at countries with highest infection rates w.r.t population
SELECT location, Max(total_cases)as Cases_till_date, population, Max((total_cases/population))*100 AS Population_Affected
FROM ProjectPortfolio..CovidDeaths$
Group by location, population
Order by Population_Affected DESC

--Looking at COUNTRIES with highest mortality count 
SELECT location, Max(cast(total_deaths as int)) as TotalDeathsCount
FROM ProjectPortfolio..CovidDeaths$
Where continent is not null
Group by location
Order by TotalDeathsCount DESC

--Looking at CONTINENTS with highest mortality count 
SELECT continent, Max(cast(total_deaths as int)) as TotalDeathsCount
FROM ProjectPortfolio..CovidDeaths$
Where continent is not null
Group by continent
Order by TotalDeathsCount DESC

-- Date wise cases and deaths data globally
-- Mortality rate measured daily. i.e. deaths vs cases on a daily basis globally
SELECT date, sum(new_cases) as Daily_Total_Cases, sum(cast(new_deaths as int)) as Daily_Total_Deaths, 
			 sum(cast(new_deaths as int))/sum(new_cases)*100 as Daily_Mortality_Rate
FROM ProjectPortfolio..CovidDeaths$
Where continent is not null
Group by date 
Order by date

--Joining the deaths and vaccination tables
--Viewing Populations and Vaccinations data
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccinations$ vac
ON dea.date = vac.date AND dea.location = vac.location
Where dea.continent is not null
Order by 2,3

--Viewing Totoal Populations vs Vaccinations data till date location wise.
SELECT dea.location, Max(dea.population) as Total_Population, Max(vac.total_vaccinations) as Total_Vaccinations
FROM ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccinations$ vac
ON dea.date = vac.date AND dea.location = vac.location
Where dea.continent is not null
Group By dea.location


--Viewing Populations and Vaccinations data
--Using the OVER clause to selectively run aggregate function and view rolling numbers of vaccinated people\
--Using a CTE or temp table to perform a calculation with the new column created
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) AS RollingVaccinations
FROM ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccinations$ vac
ON dea.date = vac.date AND dea.location = vac.location
Where dea.continent is not null


--Using a CTE or temp table to perform a calculation with the new column created above RollingVaccinations for INDIA
--Using CTE (Making sure the number of columns specified here is the same as in select clause)
With PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingVaccinations)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(cast(vac.new_vaccinations as int)) 
		   OVER (Partition by dea.location Order by dea.location, dea.date) AS RollingVaccinations
FROM ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccinations$ vac
ON dea.date = vac.date AND dea.location = vac.location
Where dea.continent is not null and dea.location = 'India' --data at the bottom shows 122 percent vac rate, that is probably due to booster doses
)
SELECT *, RollingVaccinations/Population*100 AS Vaccination_Percent
FROM PopvsVac


--Another example of a temp table but we use the create and drop table functions
-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated --A default set of code that prevent rework by emilinating the need to drop tables constantly while running the code after making some changes
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
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *, (RollingPeopleVaccinated/Population)*100 AS Vaccination_Percent
From #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From ProjectPortfolio..CovidDeaths$ dea
JOIN ProjectPortfolio..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


