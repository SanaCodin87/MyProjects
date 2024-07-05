-- We are going to explore the data and find trends or patterns or anything interesting:

SELECT *
FROM layoffs_staging2;

-- Let's look at the maximum of total employees laid off:
SELECT MAX(total_laid_off)
FROM layoffs_staging2;

SELECT MIN(total_laid_off)
FROM layoffs_staging2;

-- Let's look at percentages of  employees laid off:
SELECT MAX(percentage_laid_off), MIN(percentage_laid_off)
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL;

-- What are the companies that have 100% (1) of laid off:
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1;
-- May be those companies are startups that went out of business at that time. 
-- we can order by funds raised to see how big some of these companies were.
-- The funds_raised_millions indicates the total amount of investment a startup has received in millions of a certain currency.:
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Top 5 companies with most total laid_off:
SELECT company, total_laid_off, `date`
FROM layoffs_staging2
ORDER BY total_laid_off DESC
LIMIT 5;
-- This is just on a single day.

-- Companies that have the most total layoffs:
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;

-- we can group by location or country:
SELECT location, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;
-- It looks that chicago is the location where we have less layoffs.
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC
LIMIT 10;
-- However, the United States still the country with more layoffs.


-- Let's see the total layoffs by Year:
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;
-- We have four years layoffs in this dataset (2020, 2021, 2022, and 2023). The maximum is in 2023. 
-- It can be releavant to covid19. That is not evident.

-- lets group our data by stage and industry:
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
-- consumer, Retail industry have most layoffs
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;
-- Post_IPO is the stage where we have more layoffs. That is logical because 
-- the post-IPO phase is a critical period in a company's lifecycle, involving greater public exposure, 
-- increased scrutiny, and new opportunities and challenges related to being a publicly traded entity.

-- Let's create ranking for companies based on total layoffs per Year:
WITH company_year AS
(
SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
GROUP BY company, YEAR(date)
), 
company_year_rank AS 
(
SELECT company, years, total_off, DENSE_RANK()OVER(PARTITION BY years ORDER BY total_off DESC) AS ranking
FROM company_year
)
SELECT company, years, total_off, ranking
FROM company_year_rank
WHERE ranking<=3
AND years IS NOT NULL
ORDER BY years ASC, total_off DESC;

-- Rolling total layoffs per month:
SELECT SUBSTRING(date, 1,7) AS dates, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC;

WITH DATE_CTE AS
(
SELECT SUBSTRING(date, 1,7) AS dates, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
GROUP BY SUBSTRING(date, 1,7)
ORDER BY SUBSTRING(date, 1,7) ASC
)
SELECT dates, SUM(total_off) OVER (ORDER BY dates ASC) AS rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;




