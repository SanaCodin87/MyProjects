-- First , we created a database named World_layoffs:
CREATE DATABASE World_layoffs;
-- Then, we imported our data (CSV file named layoffs)

-- To do this cleaning project, I prefer, doing a copy of our data and work on it. So, the row data still exists.

CREATE TABLE layoffs_staging
LIKE layoffs;
-- Now, I will insert the data into each column:
INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- In the cleaning process, four main steps can be performed:
----- 1-Removing dublicates
----- 2-Standardizing data
----- 3-Handling NULL values or Blank values
----- 4-Removing any columns that we think not useful.

-- 1-Removing Duplicates:

-- let's first check for duplicates first:

SELECT * 
FROM layoffs_staging;

WITH duplicate_cte AS
( SELECT *,
ROW_NUMBER()OVER(PARTITION BY company, location, industry, total_laid_off, `date`) AS row_num
FROM layoffs_staging)
SELECT * 
FROM duplicate_cte
WHERE row_num>1;

-- Let's look at 'Oda' company to confirm:
SELECT * 
FROM layoffs_staging
WHERE company = 'Oda';
-- It looks that we need to look at every single row to be accurate. 
-- So we need to do the partion with every column:

WITH duplicate_cte AS
( SELECT *,
ROW_NUMBER()OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging)
SELECT * 
FROM duplicate_cte
WHERE row_num>1;
-- We can see for example that there is no rows for Oda company, that is great because accuratly the rows are different.
 -- let's try to delete these duplicates:
 
 WITH duplicate_cte AS
( SELECT *,
ROW_NUMBER()OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging)

DELETE 
FROM duplicate_cte
WHERE row_num>1;
-- Apparently, we can not delete a CTE, so, we gonna create another table that has extra rows and then deleting it where that row is equal to 2.

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO  layoffs_staging2
SELECT *,
ROW_NUMBER()OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- We can delete now the rows where the row numbers are more than one row:
DELETE
FROM layoffs_staging2
WHERE row_num>1;


-- 2-Standardizing data:

-- If we look at the first column, we can see that some company names need to be trimmed: 
SELECT DISTINCT(company)
FROM layoffs_staging2
ORDER BY 1;
-- So let's fix that:
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Now, let's look at the industry column:
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- I noticed that 'Crypto' industry has multiple different variations. Let's set them all to 'Crypto'.
SELECT DISTINCT industry
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry = ''
ORDER BY industry;

-- let's take a look at these:
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%'; 
-- Nothing wrong with this

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Airbnb%';
-- It looks that Airbnb is a Travel industry, but it is not populated.
-- I think the same for the others. So, we are going to write a query to populate automatically the industry row if there is another row with the same company name.
-- It will easier for us to convert the Blank values to NULL values:

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL;

-- Now, we need to populate those nulls if possible:
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company;
  
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;
  
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL ; 
-- It looks like Bally's Interactive company is uniquely without a populated row to populate the NULL value.

-- In the column 'country', it looks good, except we have some 'United States' and some 'United States.'  
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- We need to standardize this:
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- We need to look again to our data:
SELECT *
FROM layoffs_staging2;

-- The column `date' need to be fixed. We can use the STR_TO_DATE statement:
 UPDATE layoffs_staging2
 SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
 
 -- Also, we can modify the data type of this column to DATE.
 ALTER TABLE layoffs_staging2
 MODIFY COLUMN `date` DATE;
 
 
-- 3. Handling NULL values or Blank values:

-- I don't think we can do anything for the NULL values in columns total_laid_off and layoffs_staging2.
--  we can't do any calculations, we don't have even the total number of employees laid off. 


-- 4. Removing columns and rows we do not need:
-- I think removing the rows with NULL values in the two columns would be usefull. 
-- Normally, if it is NULL in the two columns, there is no laid_off.

 SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;

 SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off IS NULL;

-- Delete useless data then:
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 

SELECT *
FROM layoffs_staging2;

-- Drop the columns that we do not need:
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;