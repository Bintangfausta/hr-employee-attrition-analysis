/* ============================================================================
   PROJECT   : HR Employee Attrition & Workforce Diagnostics Analysis
   FILE      : hr_data_cleaning.sql
   PURPOSE   : Clean and prepare the raw HR employee dataset for analysis
   PREREQ    : Import Human_Resources.csv into a table named `hr`
   RUN ORDER : Run this script BEFORE hr_exploratory_data_analysis.sql
   ============================================================================ */

-- ----------------------------------------------------------------------------
-- 0. DATABASE SETUP
-- ----------------------------------------------------------------------------
CREATE DATABASE projects;
USE projects;

-- Quick look at the raw, unprocessed data
SELECT * FROM hr;

-- ----------------------------------------------------------------------------
-- 1. FIX COLUMN NAME (BOM / ENCODING ARTIFACT)
-- ----------------------------------------------------------------------------
-- The source CSV was saved with a UTF-8 BOM (Byte Order Mark). When imported
-- into MySQL, this shows up as a literal "ï»¿" prefix on the first column
-- name. We rename it to a clean, human-readable column name.
ALTER TABLE hr
CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL;

-- Disable safe-update mode for this session so bulk UPDATE statements
-- (without a primary-key WHERE clause) are permitted.
SET sql_safe_updates = 0;

-- ----------------------------------------------------------------------------
-- 2. STANDARDIZE DATE FORMATS
-- ----------------------------------------------------------------------------

-- 2.1 birthdate
-- Source data mixes two formats: "MM/DD/YYYY" and "MM-DD-YYYY".
-- Convert both to a consistent ISO format ("YYYY-MM-DD").
UPDATE hr 
SET birthdate = CASE
	WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;

ALTER TABLE hr
MODIFY COLUMN birthdate DATE;

DESCRIBE hr;
SELECT birthdate FROM hr;

-- 2.2 hire_date
-- Same mixed-format issue as birthdate.
UPDATE hr 
SET hire_date = CASE
	WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE;

-- 2.3 termdate
-- Source stores either a full UTC timestamp string (e.g. "2011-05-14 00:00:00 UTC")
-- for employees who have left, or an empty string for employees who are still active.
-- Step 1: convert empty strings to true NULL first.
SELECT termdate FROM hr;
UPDATE hr
SET termdate = NULL
WHERE termdate = '';

-- Step 2: parse the remaining timestamp strings into a plain DATE.
UPDATE hr
SET termdate = date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate != '';

ALTER TABLE hr
MODIFY COLUMN termdate DATE;

-- ----------------------------------------------------------------------------
-- 3. DERIVE AGE COLUMN
-- ----------------------------------------------------------------------------
ALTER TABLE hr ADD COLUMN age INT;

UPDATE hr
SET age = timestampdiff(YEAR, birthdate, CURDATE());

-- ----------------------------------------------------------------------------
-- 4. DATA QUALITY CHECKS
-- ----------------------------------------------------------------------------
-- 4.1 Sanity check on the age range after conversion
SELECT 
	min(age) AS youngest,
    max(age) AS oldest
FROM hr;

-- 4.2 Flag records below legal working age (excluded from analysis downstream)
SELECT count(*) 
FROM hr 
WHERE age < 18;

-- 4.3 termdate should never be a future date — flag if it is
SELECT COUNT(*) 
FROM hr 
WHERE termdate > CURDATE();

-- 4.4 Number of currently active employees (no termination date on record)
SELECT COUNT(*)
FROM hr
WHERE termdate IS NULL;

-- 4.5 Final table structure check
DESCRIBE hr;
