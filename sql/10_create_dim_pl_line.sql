/* Create and maintain the management P&L reporting structure.
   DimPLLine controls the presentation order and variance behaviour of the management P&L.
   Calculated lines such as Gross Profit and EBITDA are defined as reporting lines but calculated in Power BI. 
*/
USE FinancialPerformanceMI;
GO

IF OBJECT_ID ('dw.DimPLLine','U') IS NULL
BEGIN
	CREATE TABLE dw.DimPLLine (
		pl_line_key       INT IDENTITY(1,1) PRIMARY KEY,
		pl_line_code      VARCHAR(20)  NOT NULL UNIQUE,
		pl_line_name      VARCHAR(100) NOT NULL,
		line_type         VARCHAR(20)  NOT NULL,
		sort_order        INT          NOT NULL UNIQUE,
		variance_logic    VARCHAR(20)  NOT NULL,
		
		CONSTRAINT CK_DimPLLine_LineType1 CHECK (line_type IN ('Base','Calculated')),
		
		CONSTRAINT CK_DimPLLine_VarianceLogic1 CHECK (variance_logic IN ('HigherIsBetter','LowerIsBetter'))
		);
END;

/* Load the management P&L reporting lines.*/
INSERT INTO dw.DimPLLine(
	pl_line_code,
	pl_line_name,
	line_type,
	sort_order,
	variance_logic)
VALUES
	('REV',    'Revenue',             'Base',       1, 'HigherIsBetter'),
	('COR',    'Cost of Revenue',     'Base',       2, 'LowerIsBetter'),
    ('GP',     'Gross Profit',        'Calculated', 3, 'HigherIsBetter'),
    ('OPEX',   'Operating Expenses',  'Base',       4, 'LowerIsBetter'),
    ('EBITDA', 'EBITDA',              'Calculated', 5, 'HigherIsBetter');


SELECT *
FROM dw.DimPLLine
ORDER BY sort_order;

SELECT 
	s.name AS schema_name,
	t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s
	ON t.schema_id = s.schema_id
WHERE t.name = 'DimPLLine';

SELECT DB_NAME() AS current_database;