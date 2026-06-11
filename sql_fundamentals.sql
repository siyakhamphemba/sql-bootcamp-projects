
-- This script covers the foundational SQL commands used to
-- query, filter, sort, and summarise data from a database.
-- These are the building blocks of all SQL analysis.

-- SELECT is the most fundamental SQL command.
-- It tells the database which columns you want to see.

-- SELECT ALL COLUMNS
-- The * means "give me every column in the table."
-- Good for a quick first look at the data but avoid using
-- it in production — always name the columns you actually need.
-- Non-technical: "Show me everything in the employee table."

SELECT *
FROM employee_demographics;

-- SELECT SPECIFIC COLUMNS + CALCULATED COLUMN
-- You can pick only the columns you need and even create
-- new calculated columns on the fly inside the SELECT.
-- Here (age + 10) * 10 is calculated for every row.
-- No new column is created in the database — it only shows
-- in the results.
--
-- SQL follows PEMDAS (order of operations):
--   Parentheses → Exponents → Multiply/Divide → Add/Subtract
--   So (age + 10) happens FIRST, then × 10.
--   Without the brackets it would be age + (10 × 10) = age + 100
--   which gives a completely different answer.
--
-- Non-technical: "Show me names, birth date, age, and also
-- calculate a custom number based on their age."

SELECT first_name,
last_name,
birth_date,
age,
(age+10)*10
FROM employee_demographics;

-- SELECT DISTINCT — UNIQUE VALUES ONLY
-- DISTINCT removes duplicate values from the results.
-- Without it, the same birth date would appear once for
-- every employee who shares it.
-- Non-technical: "Show me each unique date of birth once —
-- no repeats."

SELECT DISTINCT birth_date
FROM employee_demographics;

-- WHERE filters rows based on a condition.
-- Only rows where the condition is TRUE are returned.
-- Think of it like a sieve — only matching rows get through.

-- FILTER BY EXACT TEXT MATCH
-- = checks for an exact match. Case sensitivity depends on
-- your database settings — in MySQL it is usually not
-- case-sensitive for text.
-- Non-technical: "Show me only the employee named Leslie."-- FILTER BY EXACT TEXT MATCH
-- = checks for an exact match. Case sensitivity depends on
-- your database settings — in MySQL it is usually not
-- case-sensitive for text.
-- Non-technical: "Show me only the employee named Leslie."

SELECT *
FROM employee_salary
WHERE first_name = 'Leslie';

-- FILTER BY NUMBER — LESS THAN OR EQUAL TO
-- Comparison operators work on numbers and dates:
--   =   equal to
--   !=  not equal to
--   >   greater than
--   <   less than
--   >=  greater than or equal to
--   <=  less than or equal to
-- Non-technical: "Show me only employees earning
-- £50,000 or less."

SELECT *
FROM employee_salary
WHERE salary <= 50000;

-- Logical operators let you combine multiple conditions.
--   AND  → BOTH conditions must be true
--   OR   → AT LEAST ONE condition must be true
--   NOT  → reverses/excludes the condition

-- AND — BOTH CONDITIONS MUST BE TRUE
-- Returns only rows where the employee was born before
-- 1985 AND is male. If either condition is false the row
-- is excluded.
-- Non-technical: "Show me male employees born before 1985."

SELECT *
FROM employee_demographics
WHERE birth_date < '1985-01-01'
AND gender = 'male';

-- AND NOT — COMBINE AND WITH EXCLUSION
-- Returns employees born after 1985 who are NOT male.
-- NOT gender = 'male' is the same as gender = 'female'
-- here, but NOT is useful when exclusions are more complex.
-- Non-technical: "Show me non-male employees born after 1985."

SELECT *
FROM employee_demographics
WHERE birth_date > '1985-01-01'
AND NOT gender = 'male';

-- LIKE lets you filter text by partial matches using
-- two wildcard characters:
--   %  → any number of characters (including zero)
--   _  → exactly ONE character

-- LIKE WITH % — STARTS WITH 'A'
-- 'a%' means: starts with 'a', followed by anything.
-- Matches: Andy, Ann, Angela, Aaron etc.
-- Non-technical: "Show me employees whose first name
-- starts with the letter A.

SELECT *
FROM employee_salary
WHERE first_name LIKE 'a%';

-- LIKE WITH MULTIPLE _ UNDERSCORES — MINIMUM LENGTH
-- 'a___%' means: starts with 'a', then at least 3 more
-- characters, then anything after.
-- So the name must be at least 4 characters long.
-- Matches: Andy, Anna, Angela but NOT Ann (too short).
-- Non-technical: "Show me employees whose name starts with A
-- and is at least 4 characters long."

SELECT *
FROM employee_salary
WHERE first_name LIKE 'a___%';

-- LIKE ON DATES — FILTER BY YEAR
-- Even though date is stored as a date type, LIKE can
-- match the text representation. '1989%' matches any date
-- that starts with 1989 — i.e. any date in the year 1989.
-- Non-technical: "Show me employees born in 1989."

SELECT *
FROM employee_demographics
WHERE birth_date LIKE '1989%';

-- GROUP BY groups rows that share the same value in a column
-- so we can run aggregate functions (AVG, MAX, MIN, COUNT,
-- SUM) on each group separately rather than the whole table.
-- Any column in SELECT that is NOT being aggregated must
-- appear in the GROUP BY clause.

-- AVERAGE AGE BY GENDER
-- Groups all employees by gender (male/female) and calculates
-- the average age within each group.
-- Non-technical: "What is the average age of male employees
-- vs female employees?"

SELECT gender, AVG(age)
FROM employee_demographics
GROUP BY gender;

-- LIST UNIQUE OCCUPATIONS USING GROUP BY
-- GROUP BY can be used as an alternative to DISTINCT.
-- Returns one row per unique occupation.
-- Non-technical: "What are all the different job titles
-- in the company?"

SELECT occupation
FROM employee_salary
GROUP BY occupation;

-- MULTIPLE AGGREGATE FUNCTIONS IN ONE QUERY
-- We can run several aggregations at the same time.
-- AVG = average, MAX = highest, MIN = lowest, COUNT = total.
-- All calculated per gender group in a single query.
-- Non-technical: "For each gender, show the average,
-- oldest, youngest age, and how many employees there are."

SELECT gender, AVG(age), MAX(age),MIN(age),COUNT(age)
FROM employee_demographics
GROUP BY gender;

-- ORDER BY sorts the results. Default is ASC (low to high).
-- Use DESC for high to low.
-- You can sort by multiple columns — SQL sorts by the first,
-- then uses the second to break ties.

-- SORT BY MULTIPLE COLUMNS
-- First sorts by gender (alphabetically A-Z).
-- Within each gender group, sorts by age high to low (DESC).
-- Non-technical: "Show all employees sorted by gender,
-- and within each gender show oldest first.

SELECT *
FROM employee_demographics
ORDER BY gender ,age DESC;

-- This is a commonly confused concept:
--
--   WHERE  → filters BEFORE grouping (filters raw rows)
--   HAVING → filters AFTER grouping (filters aggregated results)
--
-- You CANNOT use aggregate functions (AVG, SUM etc.) in WHERE.
-- That is what HAVING is for.

-- ❌ INCORRECT — WHERE WITH AN AGGREGATE FUNCTION
-- This query will throw an error. You cannot use AVG(age)
-- inside a WHERE clause because WHERE runs before GROUP BY
-- and the average hasn't been calculated yet at that point.
-- Non-technical: "This is the WRONG way to filter by
-- an average — shown here as a learning example."

-- SELECT gender, AVG(age)
-- FROM employee_demographics
-- WHERE AVG(age) > 40       -- ❌ This will error
-- GROUP BY gender;

-- ✅ CORRECT — HAVING WITH AN AGGREGATE FUNCTION
-- HAVING filters AFTER the GROUP BY has run, so the average
-- already exists by the time the filter is applied.
-- Only gender groups with an average salary above 75000
-- appear in the results.
-- Non-technical: "Show me manager job titles where the
-- average salary is above $75,000."

SELECT gender ,AVG(age)
FROM employee_demographics 
WHERE AVG(age) > 40
GROUP BY  gender;

SELECT occupation,AVG (salary)
FROM employee_Salary 
WHERE occupation LIKE '%manager%'
GROUP by occupation
HAVING AVG(salary) > 75000;

-- LIMIT — RESTRICT HOW MANY ROWS ARE RETURNED
-- LIMIT 3 returns only the first 3 rows of the result.
-- Combined with ORDER BY age DESC this gives us the
-- 3 oldest employees in the company.
-- Non-technical: "Show me only the 3 oldest employees."


SELECT *
FROM employee_demographics
ORDER BY age DESC
LIMIT 3; 

-- ALIAS WITH AS — RENAME A COLUMN IN RESULTS
-- AS gives a column a custom display name in the output.
-- avg_age is cleaner and more readable than AVG(age).
-- The alias can also be used in the HAVING clause to filter,
-- which is cleaner than repeating AVG(age) twice.
-- NOTE: Aliases cannot be used in WHERE — only in HAVING
-- and ORDER BY.
-- Non-technical: "Show average age per gender but only
-- for groups with an average age over 40, with a clean
-- column name in the results."

SELECT gender, AVG(age) AS avg_age
FROM employee_demographics
GROUP BY gender 
HAVING avg_age > 40;

-- SELECT   → choose which columns to show
-- FROM     → which table to pull from
-- WHERE    → filter rows BEFORE grouping (no aggregates)
-- GROUP BY → group rows to run aggregate functions on
-- HAVING   → filter AFTER grouping (can use aggregates)
-- ORDER BY → sort the results (ASC default, DESC for reverse)
-- LIMIT    → restrict how many rows are returned
-- DISTINCT → return only unique values
-- LIKE     → pattern match text (% = anything, _ = one char)
-- AS       → rename a column in the output (alias)
-- AND/OR/NOT → combine or reverse filter condition














