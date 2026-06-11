-- This script covers advanced SQL concepts:
--   1. CTEs (Common Table Expressions)
--   2. Temporary Tables
--   3. Stored Procedures
--   4. Triggers
--   5. Events

-- A CTE is a temporary named result set that exists only
-- for the duration of a single query.
-- Written using WITH ... AS ( ) before the main SELECT.
--
-- Think of it like a sticky note — you write something down,
-- use it once in the query below it, then it disappears.
--
-- Benefits over subqueries:
--   - Much easier to read and maintain
--   - Can be referenced multiple times in the same query
--   - Can be stacked (one CTE building on another)

-- Step 1 (inside WITH): joins demographics + salary and
--   calculates AVG, MAX, MIN, COUNT grouped by gender.
-- Step 2 (SELECT below): queries the CTE result like a table.
--
-- The CTE only exists while this query is running.
-- You cannot reference CTE_Example in a separate query later.
--
-- Non-technical: "First summarise salary stats by gender,
-- then show those results cleanly."

WITH CTE_Example AS
(SELECT
	gender ,
	AVG(salary) AS avg_salary,
	MAX(salary) AS max_salary,
	MIN(salary) AS min_salary,
	COUNT(salary) AS salary_count
FROM  employee_demographics dem
JOIN employee_salary sal
	ON dem.employee_id = sal.employee_id 
GROUP BY gender
)
SELECT *
FROM CTE_Example;

-- A temporary table is a table that:
--   - Only exists for your current session
--   - Is automatically deleted when you close the connection
--   - Can be queried, updated, and joined like a real table
--   - Is useful for storing intermediate results in
--     multi-step analysis or complex transformations
--
-- Two ways to create them:
--   A) Define the structure manually then INSERT data
--   B) CREATE TEMPORARY TABLE ... SELECT (copies data directly)

-- TEMP TABLE METHOD A — MANUAL STRUCTURE + INSERT
-- First we define the columns and their data types manually.
-- Then we INSERT rows one by one (or in bulk).
-- Useful when building a custom table that doesn't mirror
-- an existing table's structure.
-- Non-technical: "Create a blank custom table, then add rows."

-- Create the empty temp table
CREATE TEMPORARY TABLE temp_table
(first_name varchar(50),
last_name varchar(50),
favorite_movie varchar(100)
);

-- Confirm it exists and is empty:
SELECT *
FROM temp_table;

-- Insert a row of data:
INSERT INTO temp_table
VALUES('Siyakha','Ntuli','Jerusalema');

-- Confirm the row was inserted:
SELECT *
FROM temp_table;

-- TEMP TABLE METHOD B — CREATE FROM A SELECT QUERY
-- Much faster when you want to snapshot a filtered version
-- of an existing table for further analysis.
-- Here we pull all employees earning over 50k directly
-- into a new temp table in one step.
-- Non-technical: "Save the results of a query into a
-- temporary table I can keep querying."

-- Preview the source data first:
SELECT *
FROM employee_salary;

-- Create temp table directly from a query:
CREATE TEMPORARY TABLE salary_over_50k
SELECT *
FROM employee_salary
WHERE salary > 50000;

-- Query the temp table:
SELECT *
FROM salary_over_50k;

-- A stored procedure is a saved SQL routine — a block of
-- SQL code given a name so it can be run again and again
-- with a single CALL statement.
--
-- Benefits:
--   - Write complex logic once, reuse it many times
--   - Reduces errors from retyping the same queries
--   - Can accept parameters (like a function in coding)
--   - Speeds up repetitive tasks
--
-- DELIMITER changes the statement terminator temporarily.
-- Normally SQL uses ; to end statements, but inside a
-- procedure we need ; for individual queries. So we change
-- the outer terminator to $$ so SQL knows where the whole
-- procedure ends, then change it back to ; afterwards.

-- STORED PROCEDURE — RETURN TWO SALARY RESULT SETS
-- This procedure runs TWO SELECT queries back to back.
-- When called, it returns both result sets at once.
--
-- NOTE: salary is stored as INT so the quotes around
-- '50000' and '10000' are unnecessary — works fine but
-- best practice is to write them without quotes: >= 50000
--
-- To run this procedure after creating it:
--   CALL large_Salaries();
--
-- Non-technical: "Save these two salary queries under a name
-- so I can run them both any time with one command."

DELIMITER $$

CREATE PROCEDURE large_Salaries ()
BEGIN
-- Returns employees earning 50k or more:
	SELECT *
	FROM employee_salary
	WHERE salary >= '50000';
    -- Returns employees earning 10k or more:
    SELECT *
FROM employee_salary
WHERE salary >= '10000';
END $$
DELIMITER ;

-- To execute the stored procedure:
-- CALL large_Salaries();

-- A trigger is SQL code that runs AUTOMATICALLY when a
-- specific event happens on a table (INSERT, UPDATE, DELETE).
-- You don't call a trigger manually — it fires on its own.
--
-- Trigger timing:
--   BEFORE → runs before the event completes
--   AFTER  → runs after the event completes
--
-- NEW → refers to the new row being inserted
-- OLD → refers to the row being updated or deleted
--
-- Use cases: keeping tables in sync, audit logging,
-- enforcing business rules automatically. ;

-- To execute the stored procedure:
-- CALL large_Salaries();

-- PREVIEW TABLES BEFORE SETTING UP THE TRIGGER
-- Non-technical: "Check both tables before we link them."

SELECT * 
FROM employee_demographics;

SELECT *
FROM employee_salary;

-- TRIGGER — AUTO-INSERT INTO DEMOGRAPHICS AFTER SALARY INSERT
-- When a new row is inserted into employee_salary, this
-- trigger automatically inserts the employee's ID, first name,
-- and last name into employee_demographics as well.
--
-- This keeps both tables in sync without needing to manually
-- insert into demographics every time — the trigger handles it.
--
-- NEW.employee_id → the employee_id value from the new row
-- NEW.first_name  → the first_name value from the new row
--
-- Non-technical: "Whenever a new employee is added to salary,
-- automatically add their basic info to demographics too."-- PREVIEW TABLES BEFORE SETTING UP THE TRIGGER
-- Non-technical: "Check both tables before we link them."

DELIMITER $$
CREATE TRIGGER employee_insert
	AFTER INSERT ON employee_salary
	FOR EACH ROW 
BEGIN
	INSERT  INTO employee_demographics (employee_id,first_name,last_name)
    VALUES (NEW .employee_id, NEW.first_name ,NEW.last_name);
END $$
DELIMITER ;

-- TEST THE TRIGGER — INSERT A NEW EMPLOYEE INTO SALARY
-- After this INSERT runs, the trigger should automatically
-- insert Jean-Raphio's details into employee_demographics.
-- Check employee_demographics after running to confirm.
-- NOTE: 'Exntertainment' looks like a typo — likely
-- 'Entertainment 720 CEO'
-- Non-technical: "Add a new employee and watch the trigger
-- automatically update the demographics table."

INSERT INTO employee_salary(employee_id,first_name,last_name,occupation,salary,dept_id)
VALUES (13,'Jean-Raphio','Saperstein','Exntertainment 720 CEO',1000000,NULL);

-- Verify the trigger fired — Jean-Raphio should now appear
SELECT * 
FROM employee_demographics;

-- An event is a scheduled task — SQL code that runs
-- automatically at a set time or on a repeating schedule.
-- Think of it like a recurring calendar reminder but for
-- database operations.
--
-- Use cases: archiving old records, refreshing summary tables,
-- sending scheduled reports, cleaning up expired data.
--
-- Events require the MySQL event scheduler to be turned on.
-- Check with: SHOW VARIABLES LIKE 'event%';
-- Turn on with: SET GLOBAL event_scheduler = ON;

-- EVENT — DELETE RETIRED EMPLOYEES EVERY 6 MONTHS
-- This event runs automatically every 6 months and deletes
-- any employee aged 60 or over from the demographics table.
-- Automates the retirement data cleanup without anyone
-- needing to remember to run it manually.
--
-- ON SCHEDULE EVERY 6 MONTH → repeats every 6 months
-- DO BEGIN ... END          → the SQL to run each time
--
-- NOTE: Original code had DELIMITER ); at the end which is
-- a typo — corrected to DELIMITER ;
--
-- Non-technical: "Every 6 months, automatically remove
-- employees aged 60+ from the system."

DELIMITER $$

CREATE EVENT  delete_retirees
ON SCHEDULE EVERY 6 MONTH
DO
BEGIN
	DELETE 
    FROM employee_demographics
    WHERE age >= 60 ;
END $$
DELIMITER );   

-- CHECK IF THE EVENT SCHEDULER IS ENABLED
-- Events only run if the MySQL event scheduler is active.
-- This query checks whether it is ON or OFF.
-- If it shows OFF, run: SET GLOBAL event_scheduler = ON;
-- Non-technical: "Check whether the automatic scheduler
-- is switched on so our event will actually run."

SHOW VARIABLES LIKE 'event%';

-- CTE              → temporary named result, lives for one query
--                    written with WITH ... AS ( )
-- Temp Table       → session-only table, deleted on disconnect
--                    good for storing intermediate results
-- Stored Procedure → saved SQL routine, called with CALL name()
--                    write once, reuse many times
-- Trigger          → auto-runs on INSERT/UPDATE/DELETE events
--                    BEFORE or AFTER the event
--                    NEW = new row values, OLD = old row values
-- Event            → scheduled task, runs on a time/interval
--                    requires event scheduler to be ON
-- DELIMITER        → changes statement terminator temporarily
--                    needed when writing multi-statement blocks

