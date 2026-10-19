USE FinancialPerformanceMI;
GO

-- Create the Budget fact table at monthly planning grain.
-- Source business keys are replaced by warehouse surrogate keys.
CREATE TABLE dw.FactBudget (
	budget_key           BIGINT IDENTITY(1,1) PRIMARY KEY,
	budget_id            VARCHAR(30) NOT NULL,

	date_key             INT NOT NULL,
	account_key          INT NOT NULL,
	cost_centre_key      INT NOT NULL,
	product_key          INT NOT NULL,
	entity_key           INT NOT NULL,
	region_key           INT NOT NULL,
	
	budget_version       VARCHAR(50) NOT NULL,
	budget_currency      CHAR(3) NOT NULL,
	budget_amount        DECIMAL(18,2) NOT NULL,

	source_system        VARCHAR(50),
	load_date            DATE,

	CONSTRAINT UQ_FactBudget_BudgeID UNIQUE (budget_id),

	CONSTRAINT UQ_FactBudget_Grain UNIQUE (date_key,account_key,cost_centre_key,product_key,entity_key,region_key,budget_version),
	
	CONSTRAINT FK_FactBudget_Date FOREIGN KEY (date_key) REFERENCES dw.DimDate(date_key),

	CONSTRAINT FK_FactBudget_Account FOREIGN KEY (account_key) REFERENCES dw.DimAccount(account_key),

	CONSTRAINT FK_FactBudget_CostCentre FOREIGN KEY (cost_centre_key) REFERENCES dw.DimCostCentre(cost_centre_key),

	CONSTRAINT FK_FactBudget_Product FOREIGN KEY (product_key) REFERENCES dw.DimProduct(product_key),

	CONSTRAINT FK_FactBudget_Entity FOREIGN KEY (entity_key) REFERENCES dw.DimEntity (entity_key),

	CONSTRAINT FK_FactBudget_Region FOREIGN KEY (region_key) REFERENCES dw.DimRegion (region_key)
	);
GO

SELECT
	s.name AS schema_name,
	t.name AS table_name
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
	ON t.schema_id = s.schema_id
WHERE t.name = 'FactBudget';


-- Reload the Budget fact table from the validated staging dataset.
TRUNCATE TABLE dw.FactBudget;

INSERT INTO dw.FactBudget (
	budget_id,
    date_key,
    account_key,
    cost_centre_key,
    product_key,
    entity_key,
    region_key,
    budget_version,
    budget_currency,
    budget_amount,
    source_system,
    load_date
	)
SELECT 
	b.budget_id,
    d.date_key,
    acc.account_key,
    cc.cost_centre_key,
    p.product_key,
    e.entity_key,
    r.region_key,
    b.budget_version,
    b.budget_currency,
    b.budget_amount,
    b.source_system,
    b.load_date

FROM stg.Budget AS b

INNER JOIN dw.DimDate AS d
	ON b.budget_month = d.full_date
INNER JOIN dw.DimAccount AS acc
	ON b.account_code = acc.account_code
INNER JOIN dw.DimCostCentre AS cc
	ON b.cost_centre_code = cc.cost_centre_code
INNER JOIN dw.DimProduct AS p
	ON b.product_code = p.product_code
INNER JOIN dw.DimEntity AS e
	ON b.entity_code = e.entity_code
INNER JOIN dw.DimRegion AS r
	on b.region_code = r.region_code;

GO

SELECT COUNT(*) AS fact_budget_count
FROM dw.FactBudget;

SELECT 
	(SELECT COUNT(*) FROM stg.Budget) AS staging_budget_rows,
	(SELECT COUNT(*) FROM dw.FactBudget) AS warehouse_budget_rows;

SELECT TOP 10 *
FROM dw.FactBudget;
	
/*=====================================================
  FactBudget Post-load Financial Reconciliation
  =====================================================*/
  -- Reconcile Budget financial values between staging and warehouse
  -- to confirm that surrogate-key transformation has not altered amounts.

WITH SourceTotals AS (
	SELECT 
		YEAR(budget_month) AS reporting_year,

		SUM(CASE WHEN LEFT(account_code,1) = '4' THEN budget_amount ELSE 0 END) AS revenue,

		SUM(CASE WHEN LEFT(account_code,1) = '5' THEN budget_amount ELSE 0 END) AS cost_of_revenue,

		SUM(CASE WHEN LEFT(account_code,1) = '6' THEN budget_amount ELSE 0 END) AS operating_expenses

	FROM stg.Budget 
	GROUP BY YEAR(budget_month)),

WarehouseTotals AS (
	SELECT 
	d.calendar_year AS reporting_year,

	SUM(CASE WHEN LEFT(acc.account_code,1) = '4' THEN b.budget_amount ELSE 0 END) AS revenue,

	SUM(CASE WHEN LEFT(acc.account_code,1) = '5' THEN b.budget_amount ELSE 0 END) AS cost_of_revenue,

	SUM(CASE WHEN LEFT(acc.account_code,1) = '6' THEN b.budget_amount ELSE 0 END) AS operating_expenses

	FROM dw.FactBudget AS b
	
	INNER JOIN dw.DimDate AS d
		ON b.date_key = d.date_key

	INNER JOIN dw.DimAccount AS acc
		ON b.account_key = acc.account_key

	GROUP BY d.calendar_year )

SELECT
	s.reporting_year,

	s.revenue AS source_revenue,
	w.revenue AS warehouse_revenue,
	w.revenue - s.revenue AS revenue_difference,

	s.cost_of_revenue AS source_cost_of_revenue,
	w.cost_of_revenue AS warehouse_cost_of_revenue,
	w.cost_of_revenue - s.cost_of_revenue AS cost_of_revenue_difference,

	s.operating_expenses AS source_opex,
	w.operating_expenses AS warehouse_opex,
	w.operating_expenses - s.operating_expenses AS opex_difference,

	s.revenue - s.cost_of_revenue AS source_gross_profit,
	w.revenue - w.cost_of_revenue AS warehouse_gross_profit,

	s.revenue - s.cost_of_revenue - s.operating_expenses AS source_ebitda,
	w.revenue - w.cost_of_revenue - w.operating_expenses AS warehouse_ebitda

FROM SourceTotals AS s
INNER JOIN WarehouseTotals AS w
	ON s.reporting_year = w.reporting_year;

SELECT SUM(budget_amount) 
FROM dw.FactBudget;

/* ========================================================================
FactBudget VS FY26 Approved Management Targets
   ======================================================================== */

 -- Reconcile the final FY26 Approved warehouse Budget against the original 
 -- management P&L targets. A £100 tolerance is retained for transaction-level rounding difference.

 WITH ExpectedTargets AS (
	SELECT *
	FROM (
		VALUES (
			2026,
			'FY26 Approved',
			80000000.00, -- Revenue
			19200000.00, -- Cost of Revenue
			47200000.00 -- Operating Expenses
			)) AS t (
				reporting_year,
				budget_version,
				expected_revenue,
				expected_cost_of_revenue,
				expected_operating_expenses)
				),

WarehouseTotals AS (
	SELECT 
	d.calendar_year AS reporting_year,
	b.budget_version,

	SUM(CASE WHEN LEFT(acc.account_code,1) = '4' THEN b.budget_amount ELSE 0 END) AS actual_revenue,

	SUM(CASE WHEN LEFT(acc.account_code,1) = '5' THEN b.budget_amount ELSE 0 END) AS actual_cost_of_revenue,

	SUM(CASE WHEN LEFT(acc.account_code,1) = '6' THEN b.budget_amount ELSE 0 END) AS actual_operating_expenses

	FROM dw.FactBudget AS b
	
	INNER JOIN dw.DimDate AS d
		ON b.date_key = d.date_key

	INNER JOIN dw.DimAccount AS acc
		ON b.account_key = acc.account_key

	WHERE b.budget_version = 'FY26 Approved'

	GROUP BY d.calendar_year, b.budget_version)

SELECT 
	w.reporting_year,
    w.budget_version,

	t.expected_revenue,
    w.actual_revenue,
    w.actual_revenue - t.expected_revenue AS revenue_difference,

	t.expected_cost_of_revenue,
    w.actual_cost_of_revenue,
    w.actual_cost_of_revenue - t.expected_cost_of_revenue AS cost_of_revenue_difference,

	t.expected_revenue - t.expected_cost_of_revenue AS expected_gross_profit,
	
	w.actual_revenue - w.actual_cost_of_revenue AS actual_gross_profit,

	 (w.actual_revenue - w.actual_cost_of_revenue) - (t.expected_revenue - t.expected_cost_of_revenue) AS gross_profit_difference,

	t.expected_operating_expenses,
    w.actual_operating_expenses,
    w.actual_operating_expenses - t.expected_operating_expenses AS operating_expenses_difference,

	t.expected_revenue - t.expected_cost_of_revenue - t.expected_operating_expenses AS expected_ebitda,

	w.actual_revenue - w.actual_cost_of_revenue - w.actual_operating_expenses AS actual_ebitda,

	(w.actual_revenue - w.actual_cost_of_revenue - w.actual_operating_expenses)
    -
    (t.expected_revenue - t.expected_cost_of_revenue - t.expected_operating_expenses) AS ebitda_difference,

	CASE WHEN ABS(w.actual_revenue - t.expected_revenue) <= 100 
		  AND ABS(w.actual_cost_of_revenue - t.expected_cost_of_revenue) <= 100 
		  AND ABS((w.actual_revenue - w.actual_cost_of_revenue) - (t.expected_revenue - t.expected_cost_of_revenue)) <= 100
		  AND ABS((w.actual_revenue - w.actual_cost_of_revenue - w.actual_operating_expenses)
                -
                (t.expected_revenue - t.expected_cost_of_revenue - t.expected_operating_expenses)) <= 100
		THEN 'PASS'
		ELSE 'FAIL'
	END AS reconciliation_status

FROM WarehouseTotals AS w
INNER JOIN ExpectedTargets AS t
	ON w.reporting_year = t.reporting_year AND w.budget_version = t.budget_version;