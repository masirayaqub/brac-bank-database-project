# BRAC Bank Database Normalization & Analysis

Database audit and normalization project for BRAC Bank PLC — cleaning, normalizing to 2NF, enforcing referential integrity across 22+ tables, and generating 14 business intelligence reports.

## What the project does

- Cleans raw transactional data (duplicates, NULLs, inconsistent casing, invalid dates, non-numeric amounts)
- Fixes referential integrity issues (orphan records, wrong account prefixes, duplicate alerts)
- Standardizes data types (VARCHAR → DECIMAL/DATE/BIT, PKs to INT NOT NULL)
- Normalizes to 2NF using lookup tables (Account_Type, Account_Status, City, Month_Name, Loan_Type, etc.)
- Enforces primary and foreign keys across the schema
- Produces 14 analytical reports for operational, financial, customer, risk, and HR insights

## Reports included

1. Active vs Closed Accounts Overview
2. Total Deposits by Branch
3. Customer Distribution by Account Type
4. ATM Transaction Success Rate
5. High-Value Customers
6. Loan Default Risk Detection
7. Monthly Branch Performance Trend
8. Most Common Fraud Alert Reasons
9. Card Transaction by Category
10. Cheque Bounce Rate
11. Promotions Used vs Discount Given
12. Interest Income Potential from Active Loans
13. Employee Distribution & Salary Cost by Department
14. Cross-Selling Opportunity — Customers Without Credit Cards

## Tools

Microsoft SQL Server (T-SQL), SSMS

## Files

- `brac_bank_database_project.sql` — full cleaning and normalization script
- `analytical_reports.sql` — the 14 analytical report queries
- `brac_bank_database_report.pdf` — full project report
- `ERD.png` — entity relationship diagram

## How to run

1. Restore the source database in SQL Server
2. Run `brac_bank_database_project.sql` top to bottom
3. Run `analytical_reports.sql` to generate all 14 reports
