-- Why do we clean data?
-- Raw data from the real world is messy. It can have duplicate
-- rows, inconsistent spellings, wrong formats, and missing
-- values. If we analyse dirty data we get wrong answers.
-- Cleaning first means our analysis can be trusted.
--
-- Our cleaning plan (in order):
--   1. Remove duplicates
--   2. Standardize the data
--   3. Handle NULL and blank values
--   4. Remove unnecessary rows and columns

-- PREVIEW THE RAW DATA
-- Always look at the original data before touching anything.
-- Gives us a feel for what we are working with.
-- NOTE: 'worls_layoffs' is a typo — should be 'world_layoffs'
-- Non-technical: "Show me everything in the original table.

SELECT *
FROM worls_layoffs.layoffs;

-- CREATE A STAGING TABLE (WORKING COPY)
-- Golden rule: NEVER edit raw data directly.
-- We create a staging table — an identical empty copy —
-- so the original data is always safe and untouched.
-- LIKE layoffs copies the structure (columns) but not the data.
-- Non-technical: "Make a blank copy of the table to work on."

CREATE TABLE layoffs_staging
LIKE layoffs;

-- CONFIRM THE EMPTY STAGING TABLE EXISTS
-- Non-technical: "Check the blank copy was created."

SELECT *
FROM layoffs_staging;

-- COPY ALL DATA INTO THE STAGING TABLE
-- Now we fill the staging table with all the original data.
-- NOTE: 'INSERT INTO' is the correct syntax — INTO is required.
-- Non-technical: "Fill the working copy with all the data."

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- QUICK DUPLICATE PREVIEW (SIMPLIFIED VERSION)
-- ROW_NUMBER() assigns a number to each row within a group.
-- If a row is unique it gets 1. If it is a duplicate of
-- another row it gets 2, 3, etc.
-- This version uses fewer columns — it is a rough first look.
-- The full accurate version is in the CTE below.
-- NOTE: Original code was missing SELECT * and AS row_num.
-- Non-technical: "Give each row a number — duplicates get 2+."

SELECT *,
ROW_NUMBER OVER(
 PARTITION BY company,industry,total_laid_off,percentage_laid_off,`date`) AS row_num 
FROM layoffs_staging;

-- FULL DUPLICATE CHECK USING A CTE
-- This is the proper check — it uses EVERY identifying column
-- in the PARTITION BY. Two rows are only flagged as duplicates
-- if they match on ALL columns simultaneously.
--
-- We use a CTE (WITH ...) because ROW_NUMBER() is a window
-- function and cannot be filtered with WHERE directly.
-- Wrapping it in a CTE lets us treat the result like a table
-- and then filter it with WHERE row_num > 1.
--
-- row_num = 1 → original row (keep)
-- row_num > 1 → duplicate (to be deleted)
--
-- Non-technical: "Find every row that is an exact copy of
-- another row across every single column."

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
 PARTITION BY company,location,
 industry,total_laid_off,
 percentage_laid_off,`date`,
 stage,country,
 funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- SPOT CHECK — MANUALLY VERIFY A SPECIFIC COMPANY
-- Before deleting anything, always check at least one
-- flagged company by eye to confirm it is a true duplicate
-- and not just similar-looking data.
-- NOTE: Missing semicolon added at the end.
-- Non-technical: "Let me look at Casper manually to confirm
-- what we flagged is actually a duplicate before deleting."

SELECT *
FROM layoffs_staging
WHERE company = 'Casper'

-- CREATE layoffs_staging2 WITH A PERMANENT row_num COLUMN
-- We cannot DELETE directly from a CTE — they are temporary.
-- Solution: create a new table that includes row_num as a
-- real permanent column so we can delete from it normally.
-- Non-technical: "Build a second working table that includes
-- the duplicate-flagging number as a proper column."

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

-- CONFIRM layoffs_staging2 EXISTS AND IS EMPTY
-- Non-technical: "Check the new table was created correctly."

SELECT *
FROM layoffs_staging2;

-- POPULATE layoffs_staging2 WITH DATA + ROW NUMBERS
-- Inserts all data from staging1 into staging2,
-- and generates the row_num duplicate flag at the same time.
-- Non-technical: "Fill the new table with all data and
-- include the duplicate number column."

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
 PARTITION BY company,location,
 industry,total_laid_off,
 percentage_laid_off,`date`,
 stage,country,
 funds_raised_millions) AS row_num
FROM layoffs_staging;

-- OPTIONAL: SAVE A CLEAN BACKUP (UNIQUE ROWS ONLY)
-- Creates a separate table containing only unique rows.
-- Useful as a safety net before we delete from staging2.
-- Non-technical: "Save a clean no-duplicates version
-- as a backup just in case."

CREATE TABLE layoffs_singles AS
SELECT *
FROM layoffs_staging2
WHERE row_num = 1;

-- DELETE THE DUPLICATE ROWS
-- Now that row_num is a real column we can filter by it.
-- Any row with row_num > 1 is a duplicate — safe to remove.
-- We keep row_num = 1 (the first occurrence of each record).
-- Non-technical: "Delete all the duplicate rows, keeping
-- only the first version of each."

SET SQL_SAFE_UPDATES = 0;
-- SQL safe mode blocks bulk deletes without a key filter.
-- We turn it off temporarily to allow our cleaning operations.
-- Remember to turn it back on after cleaning is complete.

delete
FROM layoffs_staging2
WHERE row_num > 1;

-- Standardizing means making sure the same thing is always
-- written the same way throughout the dataset.
-- Examples: extra spaces, 'Crypto' vs 'CryptoCurrency',
-- 'United States' vs 'United States.' (with a full stop).

-- PREVIEW TRIM ON COMPANY NAMES
-- TRIM() removes invisible leading and trailing spaces.
-- "  Apple" and "Apple" look the same to us but SQL treats
-- them as completely different values without trimming.
-- This SELECT previews what will change before we apply it.
-- Non-technical: "Show me company names before and after
-- removing accidental spaces."

SELECT(TRIM(company))
FROM layoffs_staging2;

-- APPLY TRIM TO COMPANY NAMES
-- Makes the trim permanent by updating the actual column.
-- Non-technical: "Remove all accidental spaces from
-- company names across the whole table."

UPDATE layoffs_staging2
SET company = TRIM(company);

-- CONFIRM THE TRIM WORKED
-- Non-technical: "Show me the table after the fix."

SELECT *
FROM layoffs_staging2;

-- CHECK ALL DISTINCT INDUSTRY VALUES
-- ORDER BY 1 sorts alphabetically so similar values
-- appear next to each other, making inconsistencies easy
-- to spot (e.g. 'Crypto', 'Crypto Currency', 'CryptoCurrency').
-- Non-technical: "List all unique industry categories —
-- do any look like duplicates under different names?"

SELECT DISTINCT industry
FROM layoffs_staging2 
ORDER BY 1;

-- PREVIEW CRYPTO INDUSTRY VARIATIONS
-- Confirms how many different versions of 'Crypto' exist
-- before we standardize them all to one consistent label.
-- Non-technical: "Show me all the different ways
-- Crypto is written in the data."

SELECT *
FROM layoffs_staging2 
WHERE industry LIKE 'Crypto%';

-- STANDARDIZE ALL CRYPTO VARIATIONS TO 'Crypto'
-- LIKE 'Crypto%' catches everything starting with 'Crypto'
-- regardless of what comes after it.
-- Non-technical: "Rename all Crypto variations to just
-- 'Crypto' so they are consistent."

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE'Crypto%';

-- CHECK COUNTRY NAME INCONSISTENCIES
-- Shows each country name alongside a trimmed version.
-- TRIM(TRAILING '.' FROM country) removes any full stops
-- from the end of the value.
-- e.g. 'United States.' becomes 'United States'
-- Non-technical: "Check if any country names have a stray
-- full stop at the end."

SELECT DISTINCT country ,TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- FIX COUNTRY NAMES WITH TRAILING FULL STOPS
-- Applies the fix only to rows starting with 'United States'
-- since that is the affected country we identified above.
-- Non-technical: "Remove the stray full stop from the end
-- of any United States entries."

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE  country LIKE 'United States%'; 

-- PREVIEW DATE FORMAT CONVERSION
-- The date column was imported as TEXT (e.g. '03/15/2022')
-- rather than a proper DATE value SQL can understand.
-- STR_TO_DATE() converts text into a real date.
-- '%m/%d/%Y' tells SQL the format: month/day/4-digit-year.
-- This SELECT previews the conversion before applying it.
-- Non-technical: "Show me the dates before and after
-- converting them from text into real calendar dates."

SELECT 
`date`,
STR_TO_DATE(`date`,'%m/%d/%Y')
FROM layoffs_staging2 ;

-- APPLY DATE FORMAT CONVERSION
-- Updates every row to store the date as a proper date value
-- instead of a text string.
-- Non-technical: "Convert all the date text into real dates."

UPDATE layoffs_staging2 
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');

-- CHANGE THE DATE COLUMN TYPE TO DATE
-- Even after converting the values, the column is still
-- technically a TEXT column. This changes the column's
-- data type permanently so SQL treats it as real dates.
-- This enables date filtering, sorting, and calculations.
-- Non-technical: "Tell the database this column is now
-- officially a date column, not just text."

ALTER TABLE layoffs_staging2 
MODIFY COLUMN `date` DATE;

SET SQL_SAFE_UPDATES= 0;

-- NULL = no value recorded at all.
-- Blank ('') = an empty string was entered.
-- They behave differently in SQL so we standardise blanks
-- to NULL first, then try to fill NULLs where possible

-- FIND ROWS WITH NULL INDUSTRY
-- Identifies which companies are missing an industry value.
-- Non-technical: "Which companies have no industry listed?"

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- FIND ROWS MISSING ALL KEY NUMERIC FIELDS
-- If total_laid_off, percentage_laid_off AND funds_raised
-- are all NULL, the row has almost no useful data for analysis.
-- Non-technical: "Find rows where all the important numbers
-- are completely missing."

SELECT *
FROM layoffs_staging2
WHERE totaL_laid_off IS NULL
AND percentage_laid_off IS NULL
AND funds_raised_millions IS NULL ;

-- CONVERT BLANK INDUSTRY VALUES TO NULL
-- SQL handles NULLs much better than empty strings for
-- comparisons, joins, and filtering.
-- We standardise all blanks to NULL before attempting
-- to fill them in.
-- Non-technical: "Change any empty industry fields to a
-- proper NULL so SQL treats them consistently."

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- VERIFY ALL BLANKS ARE NOW NULL
-- Confirms the update above worked correctly.
-- After the update, the OR industry = '' should return
-- nothing — only NULLs should remain.
-- Non-technical: "Confirm there are no more blank
-- industry fields — only proper NULLs."

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- PREVIEW THE SELF JOIN — FIND FILLABLE NULLS
-- If a company appears multiple times and one row has an
-- industry but another doesn't, we can borrow the known value.
-- This JOIN matches the table to itself (t1 = missing industry,
-- t2 = has industry) on company + location.
-- This preview shows us exactly what will be filled in.
-- Non-technical: "Find cases where we can fill in a missing
-- industry by looking at another row for the same company."



SELECt t1.company,t1.industry,t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- APPLY THE SELF JOIN FIX — FILL IN MISSING INDUSTRIES
-- Takes the industry value from t2 (the row that has it)
-- and copies it into t1 (the row that is missing it).
-- Only fills rows where t1 is NULL and t2 is not NULL.
-- NOTE: SET must come after all JOIN/ON clauses in MySQL.
-- Non-technical: "Fill in the missing industry values using
-- information from other rows of the same company."

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
    SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

-- DELETE ROWS WHERE CORE LAYOFF DATA IS ENTIRELY MISSING
-- If both total_laid_off AND percentage_laid_off are NULL
-- then this row tells us nothing about actual layoffs.
-- There is no way to use these rows in any analysis so
-- we remove them to keep the dataset clean and lean.
-- Non-technical: "Delete rows where we have no layoff
-- numbers at all — they are useless for analysis."

DELETE
FROM layoffs_staging2
WHERE totaL_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- FINAL PREVIEW — CONFIRM THE CLEANED DATASET
-- Last check to make sure everything looks correct before
-- we use this table for analysis.
-- Non-technical: "Show me the final cleaned table."

SELECT *
FROM layoffs_staging2;

-- DROP THE row_num HELPER COLUMN
-- row_num was only created to help us identify and remove
-- duplicates. Now that cleaning is complete it is no longer
-- needed and should be removed — it is not real data.
-- Non-technical: "Delete the temporary numbering column
-- we used to find duplicates — job done, no longer needed."

ALTER TABLE layoffs_staging2
DROP COLUMN `row_num`;

-- CLEANING COMPLETE
-- layoffs_staging2 is now the clean analysis-ready table.
--
-- Summary of everything fixed:
--   ✅ Staging table created to protect raw data
--   ✅ Duplicates identified with ROW_NUMBER()
--   ✅ Duplicates removed via layoffs_staging2
--   ✅ Company names trimmed of whitespace
--   ✅ Crypto industry variations unified to 'Crypto'
--   ✅ Country names fixed (trailing full stops removed)
--   ✅ Date column converted from text to proper DATE type
--   ✅ Blank industry values converted to NULL
--   ✅ Missing industries filled via self join where possible
--   ✅ Rows with no layoff data removed
--   ✅ Helper column row_num dropped











