use FinalProject

--Report 1: Active vs Closed Accounts Overview (Operational Performance)

select
s.status_name as account_status,
count(*) as total_accounts,
sum(a.balance) as total_balance
from Accounts_backup a
join Account_Status s on a.status = s.status_id
group by s.status_name
order by total_accounts DESC;

--Report 2: Total Deposits by Branch (Financial Trend)

SELECT 
b.branch_name,
c.city_name AS city,
SUM(a.balance) AS total_deposits
FROM Accounts_backup a
JOIN Branches_backup b ON a.branch_id = b.branch_id
JOIN City c ON b.city = c.city_id
GROUP BY b.branch_name, c.city_name
ORDER BY total_deposits DESC;

--Report 3: Customer Distribution by Account Type (Customer Behavior)

select 
t.type_name as account_type,
count(*) as number_of_accounts,
avg(a.balance) as avg_balance
from Accounts_backup a
join Account_Type t on a.account_type = t.type_id
group by t.type_name
order by number_of_accounts desc;

--Report 4: ATM Transaction Success Rate (Operational Efficiency)

select 
l.location_name as atm_location,
count(*) as total_transactions
from ATM_Transactions_backup a
join ATM_Status s on a.status = s.status_id
join ATM_Location l on a.atm_location = l.location_id
where s.status_name = 'Completed'
group by l.location_name
order by total_transactions asc;

--Report 5: High-Value Customers (Customer Insights)

select TOP 10
c.customer_id,
c.first_name,
c.last_name,
sum(a.balance) as total_balance
from Customers c
join Accounts_backup a on c.customer_id = a.customer_id
group by c.customer_id, c.first_name, c.last_name
order by total_balance desc;

--Report 6: Loan Default Risk Detection (Risk/Anomaly)

select 
s.status_name as loan_status,
count(*) as total_loans,
sum(l.amount_sanctioned) as total_amount_at_risk
from Loans_backup l
join Loan_Status s on l.status = s.status_id
where s.status_name IN ('Defaulted', 'Active')
group by s.status_name;

--Report 7: Monthly Branch Performance Trend (Growth Indicator)

select 
m.month_name,
sum(bp.total_deposits) as total_deposits,
sum(bp.revenue) as total_revenue
from BranchPerformance_backup bp
join Month_Name m on bp.month_id = m.month_id
group by m.month_name, m.month_id
order by m.month_id;

--Report 8: Most Common Fraud Alert Reasons (Risk Detection)

select 
reason,
count(*) as total_alerts
from FraudAlerts
where resolved = 0
group by reason
order by total_alerts desc;

--Report 9: Card Transaction by Category (Customer Spending Behavior)

select 
cat.category_name,
count(*) as transaction_count,
sum(cc.amount) as total_spent
from CreditCardTransactions_backup cc
join Category cat on cc.category = cat.category_id
group by cat.category_name
order by total_spent desc;

--Report 10: Cheque Bounce Rate (Risk Indicator)

select 
s.status_name,
count(*) as total_cheques
from ChequeTransactions_backup c
join Cheque_Status s on c.status = s.status_id
group by s.status_name
order by total_cheques desc;

--Report 11: Promotions Used vs Discount Given (Marketing Efficiency)

select top 10
promo_code,
description,
discount_percent,
count(*) as times_used
from Promotions_backup
group by promo_code, description, discount_percent
order by times_used desc;

--Report 12: Interest Income Potential from Active Loans

select 
lt.type_name as loan_type,
count(*) as active_loans,
sum(l.amount_sanctioned) as total_principal,
avg(l.interest_rate) as avg_interest_rate
from Loans_backup l
join Loan_Type lt on l.loan_type = lt.type_id
join Loan_Status ls on l.status = ls.status_id
where ls.status_name = 'Active'
group by lt.type_name
order by total_principal desc;

--Report 13: Employee Distribution & Salary Cost by Department

select 
d.department_name,
count(*) as total_employees,
sum(e.salary) as total_monthly_salary_cost,
avg(e.salary) as avg_salary_per_employee
from Employees e
join Departments d on e.department_id = d.department_id
join Employee_Status es on e.status_id = es.status_id
where es.status_name = 'Active'
group by d.department_name
order by total_monthly_salary_cost desc;

--Report 14: Cross-Selling Opportunity - Customers Without Credit Cards

select top 10
c.customer_id,
c.first_name,
c.last_name,
sum(a.balance) as total_balance
from Customers c
join Accounts_backup a on c.customer_id = a.customer_id
join Account_Status ast on a.status = ast.status_id
where ast.status_name = 'Active'
group by c.customer_id, c.first_name, c.last_name
having sum(a.balance) > 50000
order by total_balance desc;