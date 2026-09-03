/* ============================================================================
   PROJECT   : HR Employee Attrition & Workforce Diagnostics Analysis
   FILE      : hr_exploratory_data_analysis.sql
   PURPOSE   : Exploratory data analysis (EDA) on the cleaned HR dataset —
               answers 11 core business questions about headcount, diversity,
               turnover, and tenure.
   PREREQ    : Run hr_data_cleaning.sql first
   SCOPE     : Unless noted otherwise, analysis is limited to employees with
               age >= 18 (legal working age). Some questions are further
               scoped to termdate IS NULL (currently active employees only).
   ============================================================================ */

USE projects;
SELECT * FROM hr;

-- ============================================================================
-- Q1. What is the gender breakdown of current employees?
-- ============================================================================
SELECT gender, COUNT(*) as count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY gender;

-- ============================================================================
-- Q2. What is the race/ethnicity breakdown of current employees?
-- ============================================================================
SELECT race, COUNT(*) as count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY race
ORDER BY count(*) DESC;

-- ============================================================================
-- Q3. What is the age distribution of current employees?
-- ============================================================================
-- 3.1 Overall min/max age
SELECT 
	min(age) AS youngest,
    max(age) AS oldest
FROM hr
WHERE age >= 18 AND termdate IS NULL;

-- 3.2 Age distribution by bucket
SELECT 
    CASE
        WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65+'
    END AS age_group,
    COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY age_group
ORDER BY age_group;

-- 3.3 Age distribution by bucket, split by gender
SELECT 
  CASE 
    WHEN age >= 18 AND age <= 24 THEN '18-24'
    WHEN age >= 25 AND age <= 34 THEN '25-34'
    WHEN age >= 35 AND age <= 44 THEN '35-44'
    WHEN age >= 45 AND age <= 54 THEN '45-54'
    WHEN age >= 55 AND age <= 64 THEN '55-64'
    ELSE '65+' 
  END AS age_group, gender,
  COUNT(*) AS count
FROM 
  hr
WHERE 
  age >= 18 AND termdate IS NULL
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- ============================================================================
-- Q4. How many employees work at headquarters versus remote locations?
-- ============================================================================
SELECT location, COUNT(*) as count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY location;

-- ============================================================================
-- Q5. What is the average length of employment for terminated employees?
-- ============================================================================
SELECT ROUND(AVG(DATEDIFF(termdate, hire_date))/365,0) AS avg_length_of_employment
FROM hr
WHERE termdate IS NOT NULL AND termdate <= CURDATE() AND age >= 18;

SELECT ROUND(AVG(DATEDIFF(termdate, hire_date)),0)/365 AS avg_length_of_employment
FROM hr
WHERE age >= 18 AND termdate IS NULL termdate <= CURDATE();

-- ============================================================================
-- Q6. How does gender distribution vary across departments?
-- ============================================================================
SELECT department, gender, COUNT(*) as count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY department, gender
ORDER BY department;

-- ============================================================================
-- Q7. What is the distribution of job titles across the company?
-- ============================================================================
SELECT jobtitle, COUNT(*) as count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY jobtitle
ORDER BY jobtitle DESC;

-- ============================================================================
-- Q8. Which department has the highest turnover rate?
-- ============================================================================
-- Turnover rate = terminated employees / total employees ever recorded
-- in that department (active + terminated), expressed as a percentage.

SELECT department, COUNT(*) as total_count, 
    SUM(CASE WHEN termdate <= CURDATE() AND termdate IS NOT NULL THEN 1 ELSE 0 END) as terminated_count, 
    SUM(CASE WHEN termdate IS NULL THEN 1 ELSE 0 END) as active_count,
    (SUM(CASE WHEN termdate <= CURDATE() AND termdate IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*)) as termination_rate
FROM hr
WHERE age >= 18
GROUP BY department
ORDER BY termination_rate DESC;

-- ============================================================================
-- Q9. What is the distribution of employees across states?
-- ============================================================================
SELECT location_state, COUNT(*) as count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY location_state
ORDER BY count DESC;

-- ============================================================================
-- Q10. How has headcount changed over time (hires vs. terminations by year)?
-- ============================================================================
SELECT 
    YEAR(hire_date) AS year, 
    COUNT(*) AS hires, 
    SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations, 
    COUNT(*) - SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS net_change,
    ROUND(((COUNT(*) - SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 ELSE 0 END)) / COUNT(*) * 100),2) AS net_change_percent
FROM 
    hr
WHERE age >= 18
GROUP BY 
    YEAR(hire_date)
ORDER BY 
    YEAR(hire_date) ASC;

--  In this modified query, a subquery is used to first calculate the terminations alias, which is then used in the calculation for the net_change and net_change_percent column in the outer query.
SELECT 
    year, 
    hires, 
    terminations, 
    (hires - terminations) AS net_change,
    ROUND(((hires - terminations) / hires * 100), 2) AS net_change_percent
FROM (
    SELECT 
        YEAR(hire_date) AS year, 
        COUNT(*) AS hires, 
        SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations
    FROM 
        hr
    WHERE age >= 18
    GROUP BY 
        YEAR(hire_date)
) subquery
ORDER BY 
    year ASC;
    
-- ============================================================================
-- Q11. What is the average tenure for each department?
-- ============================================================================
-- Tenure logic:
--   - If the employee has left (termdate is not null and has passed),
--     tenure = hire_date -> termdate.
--   - If the employee is still active, tenure = hire_date -> today.
SELECT department, ROUND(AVG(DATEDIFF(CURDATE(), termdate)/365),0) as avg_tenure
FROM hr
WHERE termdate <= CURDATE() AND termdate IS NOT NULL AND age >= 18
GROUP BY department;SELECT department,
  ROUND(AVG(
    CASE 
      WHEN termdate IS NOT NULL AND termdate <= CURDATE()   
    THEN DATEDIFF(termdate, hire_date) / 365             
  ELSE DATEDIFF(CURDATE(), hire_date) / 365            
    END
  ), 1) AS avg_tenure_years
FROM hr
WHERE age >= 18
GROUP BY department
ORDER BY avg_tenure_years DESC;
