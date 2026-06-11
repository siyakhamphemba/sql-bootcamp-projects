-- Exploratory Data Analysis
-- What is EDA?
-- Before buiding dashboards or drawing conclusions, we explore the data to understand its shape,spot patterns, and find
-- anything unusual.Think of it like flipping through a book before reading it cover to cover.

-- 1.FULL TABLE PREVIEW 
-- simply shows every row and column in the dataset.
-- Good first step - get a feel for what we are working with.
-- Non-technical: "Show me everything in the spreedsheet.'


SELECT * 
FROM layoffs_staging2;

-- 2. HIGHEST SINGLE LAYOFF EVENT & HIGHEST PERCENTAGE CUT
-- MAX()finds the single biggest value in a column.
-- This tells us the worst single layoff event recorded,
-- and the highest % of a company that was ever cut at once.alter
-- Non-technical: " What is the biggest layoff number we have,
-- and what is the biggest percentage cut we have on record?"

SELECT MAX(total_laid_off),MAX(percentage_laid_off)
FROM layoffs_staging2;

-- 3. COMPANIES THAT CUT 100% OF THEIR WORKFORCE (SHUTDOWNS)
-- percentage_laid_off = 1 means 100% — the entire company.
-- Ordered by funds raised so we can see which companies
-- burned the most investor money before shutting down.
-- Non-technical: "Show me every company that completely
-- shut down, biggest spenders first."

SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC ;

-- 4. TOTAL LAYOFFS PER COMPANY (ALL TIME)
-- SUM adds up all layoffs per company across every event.
-- ORDER BY 2 means order by the second column (the SUM).
-- Non-technical: "Which companies laid off the most people
-- in total across the whole dataset?"



SELECT company,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- 5. DATE RANGE OF THE DATASET
-- MIN and MAX on the date column tells us the earliest and
-- latest events recorded — important to know the time window
-- we are actually analysing.
-- Non-technical: "How far back does this data go,
-- and how recent is it?"

SELECT MIN(`date`),MAX(`date`)
FROM layoffs_staging2;

-- 6. TOTAL LAYOFFS BY COUNTRY
-- Groups all layoff events by country and sums them up.
-- Helps identify which countries were hit hardest overall.
-- Non-technical: "Which countries had the most layoffs?"

SELECT country,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- 7. TOTAL LAYOFFS BY YEAR
-- Breaks down layoffs year by year to spot trends over time.
-- Ordered by year descending so the most recent year
-- appears at the top.
-- Non-technical:"Which year had the most layoffs?"

SELECT YEAR(`date`),SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- 8. TOTAL LAYOFFS BY FUNDING STAGE
-- Funding stage = where a company is in its growth journey
-- (e.g. Series A = early, Post-IPO = publicly listed).
-- This shows which stage of company cut the most jobs.
-- Non-technical: "Were layoffs worse at startups or
-- established public companies?

SELECT stage,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- 9. COMPANIES WITH HIGHEST TOTAL PERCENTAGE LAID OFF
-- Instead of raw numbers, this sums up percentage cuts.
-- A company that did multiple rounds each cutting 50%
-- would show a high number here.
-- Non-technical: "Which companies kept cutting over
-- and over again proportionally?"

SELECT company,SUM(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- 10. MONTHLY LAYOFF TOTALS
-- SUBSTRING pulls the YYYY-MM portion from the date column
-- giving us a clean month label (e.g. 2022-11).
-- This shows total layoffs for each calendar month.
-- Non-technical: "How many people were laid off each month?"

SELECT SUBSTRING(`date`,1,7) AS `MONTH`,SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- 11. ROLLING (CUMULATIVE) TOTAL OF LAYOFFS BY MONTH
-- This uses a CTE (a temporary named result) to first
-- calculate monthly totals, then a window function to
-- accumulate them into a running total.
--
-- Think of it like a bank statement:
-- each row shows that month's layoffs AND the grand total
-- so far since the beginning of the data.
--
-- Non-technical: "Show me each month's layoffs AND a
-- running total that keeps adding up over time."

SELECT *
FROM layoffs_staging2;

WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`,SUM(total_laid_off) AS Total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`,Total_off,
SUM(Total_off) OVER(ORDER BY `MONTH` ) AS rolling_total
FROM  Rolling_Total;

SELECT company,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- 12. COMPANY LAYOFFS BROKEN DOWN BY YEAR
-- Same as Query 4 but now split by year too,
-- so we can see each company's layoffs per year
-- rather than just their all-time total.
-- Non-technical: "Show me how many people each company
-- laid off, broken down year by year."

SELECT company,YEAR(`date`) ,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company,YEAR(`date`)
ORDER BY  3 DESC ;

-- 13. TOP 5 COMPANIES BY LAYOFFS PER YEAR (RANKED)
-- This uses TWO CTEs stacked on top of each other:
--
-- CTE 1 (company_year): aggregates total layoffs
--        per company per year — the raw numbers.
--
-- CTE 2 (Company_Year_Rank): takes those numbers and
--        applies DENSE_RANK which assigns a rank (1st, 2nd
--        3rd...) within each year separately.
--        PARTITION BY years resets the ranking for each year.
--
-- Final SELECT: filters to only show the top 5 per year.
--
-- Non-technical: "For each year, who were the 5 companies
-- that laid off the most people?"

WITH company_year(company,years,total_laid_off) AS
(
SELECT company,YEAR(`date`) ,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company,YEAR(`date`)
), Company_Year_Rank AS
(
SELECT *,DENSE_RANK()OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM company_year 
WHERE years IS NOT NULL
)
 SELECT *
 FROM Company_Year_Rank
 WHERE Ranking <= 5 ;

-- 14. TOP 5 INDUSTRIES BY LAYOFFS PER YEAR (RANKED)
-- Same logic as Query 13 but grouped by industry
-- instead of company.
-- Helps identify which sectors were struggling most
-- in each specific year.
-- Non-technical: "For each year, which 5 industries
-- cut the most jobs?"

WITH industry_year(industry,years,total_laid_off) AS
(
SELECT industry,YEAR(`date`) ,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry,YEAR(`date`)
), Industry_Year_Rank AS
(
SELECT *,DENSE_RANK()OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM industry_year 
WHERE years IS NOT NULL
)
 SELECT *
 FROM Industry_Year_Rank
 WHERE Ranking <= 5; 
 
 -- 15. ROLLING LAYOFF TOTAL PER COUNTRY OVER TIME
-- Similar to Query 11 but PARTITION BY country means
-- each country gets its own independent running total.
-- Great for comparing how layoffs built up differently
-- across countries month by month.
-- Non-technical: "For each country, show a running total
-- of layoffs building up month after month."

WITH Country_Monthly AS 
(
	SELECT country,
		SUBSTRING(`date`,1,7) AS `MONTH`,
        SUM(total_laid_off) AS total_off
	FROM layoffs_staging2
    WHERE SUBSTRING(`date`,1,7) IS NOT NULL
    GROUP BY country, `MONTH`
    )
    SELECT country, `MONTH` ,total_off,
		SUM(total_off)OVER(PARTITION BY country ORDER BY `MONTH`) AS rolling_total
	FROM Country_Monthly
    ORDER BY country,`MONTH`;
    
-- 16. TOP 5 INDUSTRIES BY FUNDS RAISED PER YEAR
-- This combines two metrics: funds raised AND layoffs.
-- The ranking here is based on total funds raised —
-- highlighting industries that attracted the most investment
-- but still ended up cutting jobs.
-- Non-technical: "Which industries raised the most money
-- each year, and how many jobs did they still cut?"
    
 WITH industry_funds AS
 (
	SELECT industry,
		YEAR(`date`) AS years,
        SUM(funds_raised_millions) AS total_funds,
        SUM(total_laid_off) AS total_laid_off
	FROM layoffs_staging2
    GROUP BY industry, YEAR(`date`)
    ),
    ranked AS 
    (
    SELECT *,
		DENSE_RANK()OVER(PARTITION BY years ORDER BY total_funds DESC) AS ranking
	FROM industry_funds
    WHERE years IS NOT NULL
    )
    SELECT * FROM ranked WHERE ranking <= 5;
    
-- 17. LAYOFFS SUMMARY BY FUNDING STAGE
-- Looks at each funding stage and calculates:
--   - How many layoff events happened
--   - Total people laid off
--   - Average % of company cut each time
--   - Average funds raised by companies at that stage
-- Helps answer: did well-funded companies cut fewer people
-- proportionally, or did money not protect jobs?
-- Non-technical: "Compare layoffs across startup stages —
-- were early startups or big public companies worse off?"
    
    SELECT stage ,
		COUNT(*) AS num_events,
        SUM(total_laid_off) AS total_laid_off,
        ROUND(AVG(percentage_laid_off)*100,2) AS avg_pct_laid_off,
        ROUND(AVG(funds_raised_millions),2) AS avg_funds_raised
	FROM layoffs_staging2
    WHERE stage IS NOT NULL
    GROUP BY stage
    ORDER BY total_laid_off DESC;
    
-- 18. COMPLETE SHUTDOWNS BY COUNTRY
-- Filters only for percentage_laid_off = 1 (100% cuts)
-- meaning the entire company closed down.
-- Groups by country to see where full collapses were
-- most common and how much funding was lost.
-- Non-technical: "Which countries had the most companies
-- fully shut down, and how much money did they burn?"
    
    SELECT country,
		COUNT(*) AS total_shutdowns,
        SUM(total_laid_off) AS total_people_laid_off,
        ROUND(AVG(funds_raised_millions),2) AS avg_funds_before_shutdown
	FROM layoffs_staging2
    WHERE percentage_laid_off = 1
    GROUP BY country
    ORDER BY total_shutdowns DESC;
    
-- 19. MONTH-OVER-MONTH LAYOFF GROWTH RATE
-- This uses THREE layers:
--
-- CTE 1 (monthly): totals layoffs per month.
--
-- CTE 2 (with_lag): uses LAG() which looks at the
--        PREVIOUS row's value — so each month can
--        compare itself to the month before it.
--
-- Final SELECT: calculates the % change between
--        this month and last month.
--        Positive % = layoffs got worse.
--        Negative % = layoffs improved.
--
-- Non-technical: "Each month, were layoffs getting better
-- or worse compared to the previous month, and by how much?"
    
    WITH monthly AS
    (
		SELECT SUBSTRING(`date`,1,7) AS `MONTH`,
			SUM(total_laid_off) AS total_off
		FROM layoffs_staging2
        WHERE SUBSTRING(`date`,1,7) IS NOT NULL
        GROUP BY `MONTH`
	),
    with_lag AS
    (
		SELECT `MONTH`,total_off,
			LAG(total_off)OVER(ORDER BY `MONTH`) AS prev_month
		FROM monthly
	)
    SELECT `MONTH`,total_off,prev_month,
		ROUND((total_off-prev_month)/prev_month*100,2) AS mom_growth_pct
	FROM with_lag
    WHERE prev_month IS NOT NULL
    ORDER BY `MONTH`
    
    
    
    
    
    
    
    

