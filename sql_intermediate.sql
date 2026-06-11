-- This script covers intermediate SQL concepts:
--   1. Joins        - combining data from multiple tables
--   2. Unions       - stacking results from multiple queries
--   3. String Functions - manipulating text data
--   4. Case Statements  - conditional logic inside SQL
--   5. Subqueries   - queries nested inside other queries
--   6. Window Functions - advanced calculations across rows

-- Joins combine rows from two or more tables based on a
-- related column between them (usually an ID column).
-- Think of it like using VLOOKUP in Excel but more powerful.

-- PREVIEW BOTH TABLES BEFORE JOINING
-- Always good practice to look at both tables separately
-- first so you understand what data each one holds and
-- which column links them together.
-- Non-technical: "Show me each table on its own before
-- we combine them."

 SELECT * 
 FROM employee_demographics;
 
 SELECT *
 FROM employee_salary;
 
-- INNER JOIN — ONLY MATCHING ROWS FROM BOTH TABLES
-- Returns rows where the employee_id exists in BOTH tables.
-- If an employee appears in demographics but NOT in salary
-- (or vice versa) they are excluded from the results.
-- This is the most commonly used join type.
--
-- AS dem / AS sal are aliases — short nicknames for the
-- table names so we don't have to type the full name every time.
--
-- Non-technical: "Show me only employees who appear in
-- BOTH the demographics and salary tables."

 SELECT * 
 FROM employee_demographics AS dem
 INNER JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id;
    
-- LEFT JOIN — ALL ROWS FROM LEFT TABLE + MATCHES FROM RIGHT
-- Returns every row from the LEFT table (employee_demographics)
-- and fills in matching data from the right table (salary).
-- If no match exists in salary, those columns show NULL.
-- Use this when you want to keep all records from one table
-- even if they don't have a match in the other.
--
-- Non-technical: "Show me ALL employees from demographics,
-- and add salary info where it exists — leave blank if not."
 
SELECT * 
 FROM employee_demographics AS dem
 LEFT JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id;
    
-- RIGHT JOIN — ALL ROWS FROM RIGHT TABLE + MATCHES FROM LEFT
-- The opposite of LEFT JOIN. Returns every row from the
-- RIGHT table (salary) and fills in demographics where it
-- matches. Rows in salary with no demographics match show NULL.
-- RIGHT JOIN is less commonly used — most people flip the
-- table order and use LEFT JOIN instead for readability.
--
-- Non-technical: "Show me ALL employees from salary,
-- and add demographics info where it exists."
 
    SELECT * 
 FROM employee_demographics AS dem
 RIGHT JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id;
    
    -- SELF JOIN — A TABLE JOINED TO ITSELF
-- A self join links a table back to itself using two aliases
-- (emp1 and emp2) to treat it as if it were two separate tables.
-- Here we match each employee to the employee with the NEXT
-- employee_id (emp1.id + 1 = emp2.id).
-- Classic use case: Secret Santa assignments, org charts,
-- finding next/previous records.
-- Non-technical: "Match each employee to the employee with
-- the next ID number — like assigning Secret Santa pairs."
    
    SELECT 	
		emp1.employee_id AS emp_santa,
		emp1.first_name AS first_name_santa,
		emp1.last_name AS last_name_santa,
		emp2.employee_id AS emp_id,
		emp2.first_name AS first_name_emp,
		emp2.last_name AS last_name_emp
    FROM employee_salary AS emp1
    JOIN employee_salary AS emp2
		ON emp1.employee_id + 1 = emp2.employee_id ;
        
-- JOINING MULTIPLE TABLES
-- You can chain as many JOINs as you need.
-- Here we join three tables:
--   1. employee_demographics (personal info)
--   2. employee_salary (pay + department ID)
--   3. parks_departments (department name)
-- Each JOIN adds another layer of information to the results.
-- Non-technical: "Combine personal info, salary, AND
-- department name all in one result." 
        
        SELECT * 
 FROM employee_demographics AS dem
 INNER JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
    INNER JOIN parks_departments AS pd 
    ON sal.dept_id = pd.department_id;
    
-- PREVIEW DEPARTMENTS TABLE
-- Non-technical: "Show me the departments table."
    
    SELECT *
    FROM parks_departments;
    
--  UNION stacks the results of two SELECT queries on top of
-- each other vertically (adding rows, not columns).
-- Rules:
--   - Both queries must have the same number of columns
--   - Columns should be compatible data types
--   - UNION removes duplicates by default
--   - UNION ALL keeps all rows including duplicates

-- BASIC UNION — STACKING TWO RESULT SETS
-- This stacks age+gender from demographics ON TOP OF
-- first_name+last_name from salary.
-- The column headers come from the FIRST query.
-- NOTE: This is a demonstration — in practice you would
-- only UNION columns that represent the same type of data.
-- Mixing age with first_name is not meaningful here but
-- shows how the syntax works.
-- Non-technical: "Stack two sets of results into one list."

    SELECT age,gender
    FROM employee_demographics
    UNION
    SELECT first_name,last_name
    FROM employee_salary;
    
-- UNION WITH LABELS — CATEGORISING EMPLOYEES
-- A much more practical use of UNION.
-- Each SELECT adds a fixed label column ('Old Man', 'Old Lady',
-- 'Highly Paid Employee') so we can identify which category
-- each row came from after combining.
-- The ORDER BY at the end sorts the entire combined result.
-- Non-technical: "Build a single list of notable employees
-- with a label showing why they are notable."
    
    SELECT first_name,last_name, 'Old Man' AS Label
    FROM employee_demographics
    WHERE age > 40 AND gender = 'Male'
    UNION 
    SELECT first_name,last_name ,'Old Lady'AS Label
    FROM employee_demographics
    WHERE age > 40 AND gender = 'Female'
    UNION 
    SELECT first_name,last_name,'Highly Paid Employee' AS Label
    FROM employee_salary
    WHERE salary > 70000
	ORDER BY first_name,last_name;
    
-- String functions let us manipulate and inspect text data.
-- Useful for cleaning names, extracting parts of strings,
-- combining columns, and finding characters within text.

-- LENGTH() — COUNT CHARACTERS IN A STRING
-- Returns the number of characters in the text.
-- Non-technical: "How many letters are in this word
   
    SELECT LENGTH('skyfall');
    
    SELECT first_name,LENGTH(first_name)
    FROM employee_demographics
    ORDER BY 2;
    
-- UPPER() AND LOWER() — CHANGE TEXT CASE
-- UPPER converts all letters to capitals.
-- LOWER converts all letters to lowercase.
-- Useful for standardising text before comparisons.
-- Non-technical: "Convert text to ALL CAPS or all lowercase."
    
    SELECT UPPER('sky');
    SELECT LOWER('SKY');
  
-- TRIM() — REMOVE LEADING AND TRAILING SPACES
-- Removes invisible spaces from the start and end of text.
-- Important for cleaning data where extra spaces were entered.
-- Non-technical: "Remove any accidental spaces around text."
  
  SELECT TRIM('          sky          ');
  
-- LEFT(), RIGHT(), SUBSTRING() — EXTRACT PARTS OF TEXT
-- LEFT(col, n)         → first n characters from the left
-- RIGHT(col, n)        → last n characters from the right
-- SUBSTRING(col, start, length) → extract from any position
--   SUBSTRING(first_name, 3, 3) → start at character 3,
--   take 3 characters
--
-- Here we also extract the month from birth_date:
-- SUBSTRING(birth_date, 6, 2) → characters 6 and 7 = the month
-- e.g. '1985-04-15' → '04'
--
-- Non-technical: "Slice and dice text to extract just the
-- part we need."
  
  SELECT first_name,
  LEFT(first_name,4),
  RIGHT(first_name,4),
  SUBSTRING(first_name,3,3),
  birth_date,
  SUBSTRING(birth_date,6,2)
  FROM employee_demographics;
  
-- REPLACE() — SWAP ONE CHARACTER FOR ANOTHER
-- Replaces every occurrence of one string with another.
-- Here every 'a' in first_name is replaced with 'z'.
-- Useful for bulk text fixes in data cleaning.
-- Non-technical: "Find and replace within text values."
  
  SELECT first_name,REPLACE(first_name,'a','z')
    FROM employee_demographics;
    
-- LOCATE() — FIND POSITION OF A CHARACTER
-- Returns the position number where a character/string
-- first appears. Returns 0 if not found.
-- LOCATE('x', 'Alexander') → returns 4 (x is the 4th character)
-- Non-technical: "Tell me where this letter appears in the word."
    
    SELECT LOCATE('x','Alexander');
    
-- CONCAT() — COMBINE COLUMNS INTO ONE STRING
-- Joins multiple text values together into a single string.
-- Here we combine first_name + two spaces + last_name
-- into a full_name column.
-- Non-technical: "Merge first name and last name into
-- one full name column."
    
    SELECT first_name,last_name,
    CONCAT(first_name,'  ',last_name) AS full_name
    FROM employee_demographics;
    
-- CASE is SQL's version of IF/ELSE logic.
-- It evaluates conditions in order and returns the value
-- for the FIRST condition that is TRUE.

-- CASE — AGE BRACKET LABELS
-- Assigns a text label to each employee based on their age.
-- Conditions are checked top to bottom — the first TRUE
-- match is used and the rest are skipped.
-- Non-technical: "Put each employee into an age category."
   
SELECT first_name,last_name,age,
	CASE
		WHEN age <= 30 THEN 'Young'
        WHEN age BETWEEN 31 AND 50 THEN 'Old'
        WHEN age >= 50 THEN "On Death's Door"
        END AS age_bracket
	FROM employee_demographics
    ORDER BY age;
        
- CASE — CALCULATE PAY INCREASES
-- Uses CASE to apply different percentage increases based
-- on current salary. The result is the new salary after
-- the raise is applied.
--
-- Business rules:
--   Salary <= 50,000 → 5% increase  (salary * 1.05)
--   Salary >  50,000 → 7% increase  (salary * 1.07)
--   Finance dept     → 10% increase (would need a JOIN
--                       to apply — shown as a comment below)
-- Non-technical: "Calculate each employee's new salary
-- after their pay rise."
    
    SELECT first_name,last_name,salary,
		CASE
			WHEN salary <=50000 THEN salary + salary * .05
            WHEN salary > 50000 THEN salary + salary * .07
		END AS new_salary
    FROM employee_salary;
    
    
    SELECT * 
    FROM employee_salary;
    
    SELECT *
    FROM parks_departments;
    
  -- A subquery is a query nested inside another query.
-- The inner query runs first and its result is used by
-- the outer query.
-- Think of it like solving the inside of brackets first
-- in a maths equation.

-- SUBQUERY IN WHERE — FILTER USING ANOTHER TABLE'S RESULTS
-- The inner query finds all employee_ids in dept_id = 1.
-- The outer query then uses those IDs to filter demographics.
-- IN checks whether a value exists in a list of results.
-- This achieves the same as a JOIN but written differently.
-- Non-technical: "Show me the personal details of everyone
-- who works in department 1."
    
    SELECT *
    FROM employee_demographics
    WHERE employee_id IN
						(SELECT employee_id
							FROM employee_salary
							WHERE  dept_id = 1);
                            
-- SUBQUERY IN SELECT — ADD A CALCULATED BENCHMARK COLUMN
-- The inner query calculates the overall average salary once.
-- That single number is then shown next to every employee's
-- salary so you can instantly compare them to the average.
-- Non-technical: "Show each employee's salary alongside
-- the company-wide average salary for comparison." 
                            
SELECT first_name,
salary,
(SELECT AVG(salary) 
FROM employee_salary)AS avg_salary
FROM employee_salary;

-- SUBQUERY IN FROM — USE A QUERY RESULT AS A TABLE
-- The inner query summarises age statistics by gender.
-- The outer query then calculates the average of those
-- averages (average across gender groups).
-- When used in FROM the subquery must be given an alias
-- (here: agg_table) so SQL can reference it.
-- Non-technical: "First summarise by gender, then calculate
-- the overall average of those group averages."

SELECT gender ,
	AVG( age) AS avg_age,
	MIN(age) AS min_age,
	MAX(age) AS max_age,
	COUNT(age) AS age_count
FROM employee_demographics
GROUP BY gender;

-- Window functions perform calculations ACROSS rows related
-- to the current row WITHOUT collapsing them into groups.
--
-- Key difference vs GROUP BY:
--   GROUP BY  → collapses rows, one result per group
--   OVER()    → keeps all rows, adds a calculated column
--
-- PARTITION BY divides rows into groups (like GROUP BY)
-- but keeps every individual row visible.

SELECT  AVG(avg_age)
FROM
(SELECT gender ,
	AVG( age) AS avg_age ,
	MIN(age) AS min_age,
	MAX(age) AS max_age,
	COUNT(age)  
FROM employee_demographics
GROUP BY gender) AS agg_table;

-- Window functions perform calculations ACROSS rows related
-- to the current row WITHOUT collapsing them into groups.
--
-- Key difference vs GROUP BY:
--   GROUP BY  → collapses rows, one result per group
--   OVER()    → keeps all rows, adds a calculated column
--
-- PARTITION BY divides rows into groups (like GROUP BY)
-- but keeps every individual row visible.

-- AVERAGE SALARY BY GENDER — GROUP BY VERSION
-- This collapses all rows into just two rows (Male/Female).
-- We lose the individual employee detail.
-- Non-technical: "Show me the average salary for each gender
-- — but we only see 2 summary rows.

SELECT gender,AVG(salary)
FROM employee_demographics  dem
JOIN employee_salary sal
	ON dem.employee_id = sal.employee_id
GROUP BY gender;

-- AVERAGE SALARY BY GENDER — WINDOW FUNCTION VERSION
-- OVER(PARTITION BY gender) calculates the average salary
-- within each gender group BUT keeps every row intact.
-- Every employee now shows their own salary AND their
-- gender group's average side by side for easy comparison.
-- Non-technical: "Show every employee with their salary AND
-- the average salary for their gender group next to it."
        
SELECT  dem.first_name, dem.last_name,sal.salary, AVG(salary)OVER(PARTITION BY gender)
FROM employee_demographics  dem
JOIN employee_salary sal
	ON dem.employee_id = sal.employee_id;
    
-- ROW_NUMBER vs RANK vs DENSE_RANK
-- All three rank rows within each gender partition by salary.
-- The difference shows when there are TIED salary values:
--
-- ROW_NUMBER()  → always unique — tied rows get different numbers
--                 e.g. 1, 2, 3, 4
--
-- RANK()        → tied rows get the SAME rank, then SKIPS numbers
--                 e.g. 1, 2, 2, 4  (no 3rd place)
--
-- DENSE_RANK()  → tied rows get the SAME rank, NO skipping
--                 e.g. 1, 2, 2, 3  (3rd place still exists)
--
-- Non-technical: "Rank every employee by salary within their
-- gender group using three different ranking methods so we
-- can see how they handle ties differently."
    
    
SELECT  dem.first_name, dem.last_name,sal.salary,
ROW_NUMBER() OVER(PARTITION BY gender ORDER BY salary DESC) AS row_num,
RANK () OVER(PARTITION BY gender ORDER BY salary DESC) AS rank_num,
DENSE_RANK() OVER(PARTITION BY gender ORDER BY salary DESC) AS dense_rank_num
FROM employee_demographics  dem
JOIN employee_salary sal
	ON dem.employee_id = sal.employee_id;
    
-- INNER JOIN   → only rows matching in BOTH tables
-- LEFT JOIN    → all rows from left + matches from right
-- RIGHT JOIN   → all rows from right + matches from left
-- SELF JOIN    → table joined to itself (next/prev rows)
-- UNION        → stack two result sets vertically (no dupes)
-- UNION ALL    → stack two result sets (keep duplicates)
-- LENGTH()     → count characters in text
-- TRIM()       → remove leading/trailing spaces
-- UPPER/LOWER  → change text case
-- SUBSTRING()  → extract part of a string
-- REPLACE()    → swap one character/string for another
-- LOCATE()     → find position of a character in text
-- CONCAT()     → combine multiple text columns into one
-- CASE         → IF/ELSE conditional logic in SQL
-- Subquery     → query nested inside another query
-- OVER()       → window function — calculate without collapsing
-- PARTITION BY → divide window function into groups
-- ROW_NUMBER() → unique rank (no ties)
-- RANK()       → rank with ties, skips numbers after tie
-- DENSE_RANK() → rank with ties, no numbers skipped



    
    