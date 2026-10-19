-- Create the dedicated SQL Server database for the Financial Performance and MI Reporting project.
CREATE DATABASE FinancialPerformanceMI;
GO

USE FinancialPerformanceMI;
GO

-- Create a staging schema for raw source data and a warehouse schema
-- for cleaned dimensional tables used by finance reporting.
CREATE SCHEMA stg;
GO

CREATE SCHEMA dw;
GO