use FinalProject

Select*from Accounts

select * into Accounts_backup from Accounts;
select*from Accounts_backup;

--find duplicate account_numbers
select account_number,count(*)
from accounts_backup group by account_number
having count(*)>1;


--corect erroneous data 
update Accounts_backup
set status ='Active'
where status = 'active'
and status = 'ACTIVE';

--delete duplicates
delete from accounts_backup
where account_id NOT IN (select min(account_id)
from accounts_backup group by account_number);

--HANDLE MISSING DATA LOGICALLY
update Accounts_backup set customer_id=0 where customer_id is null;
ALTER TABLE ACCOUNTS_BACKUP
ALTER COLUMN CUSTOMER_ID INT NOT NULL;
ALTER TABLE ACCOUNTS_BACKUP
ALTER COLUMN BRANCH_ID INT NOT NULL; 

--fix data type
alter table Accounts_backup
alter column balance decimal (18,2) not null;
alter table Accounts_backup add open_date_temp date;
update Accounts_backup set open_date_temp = open_date;
alter table accounts_backup drop column open_date;
exec sp_rename 'Accounts_backup.open_date_temp','open_date','column';

--remove redundant columns(2nf)
alter table Accounts_backup drop column currency;

--fix table name 
IF EXISTS (SELECT*FROM sys.tables where name = 'TableName')
begin
exec sp_rename 'TableName','accounts_backup';
end

--add pk
alter table accounts_backup
alter column account_id int not null;
alter table accounts_backup
add constraint PK_Accounts_backup PRIMARY KEY (account_id);

--add unique constraint
alter table accounts_backup
add constraint UQ_Accounts_backup_AccountNumber UNIQUE (account_number);


--normalize account type
--create lookup table for account types
create table Account_Type 
(type_id INT PRIMARY KEY,
type_name varchar(20) );

--Insert the 4 types
insert into Account_Type values (1, 'Savings');
insert into Account_Type values (2, 'Current');
insert into Account_Type values (3, 'Credit');
insert into Account_Type values (4, 'Fixed Deposit');

--Add new column to accounts_backup
alter table accounts_backup add type_id INT;

--Update the new column
update accounts_backup set type_id = 1 where account_type = 'Savings';
update accounts_backup set type_id = 2 where account_type = 'Current';
update accounts_backup set type_id = 3 where account_type = 'Credit';
update accounts_backup set type_id = 4 where account_type = 'Fixed Deposit';

--Drop the old column
alter table accounts_backup drop column account_type;

--rename new column
exec sp_rename 'accounts_backup.type_id', 'account_type', 'COLUMN';
--Add foreign key
alter table accounts_backup
add constraint FK_Accounts_AccountType 
FOREIGN KEY (account_type) references Account_Type(type_id);

--normalize status
--create lookup table for status
create table Account_Status
(status_id INT PRIMARY KEY,
status_name varchar(20) );

--insert the 3 statuses
insert into Account_Status values (1, 'Active');
insert into Account_Status values (2, 'Closed');
insert into Account_Status values (3, 'Dormant');

--add new column to accounts_backup
alter table accounts_backup 
add status_id INT;

--update the new column
update accounts_backup set status_id = 1 where status = 'Active';
update accounts_backup set status_id = 2 where status = 'Closed';
update accounts_backup set status_id = 3 where status = 'Dormant';

--drop the old column
alter table accounts_backup drop column status;

--rename new column
exec sp_rename 'accounts_backup.status_id', 'status', 'COLUMN';

--add foreign key
alter table accounts_backup
add constraint FK_Accounts_Status 
FOREIGN KEY (status) references Account_Status(status_id);

--see the data with lookup values 
select top 5 
a.account_id,
a.account_number,
t.type_name AS account_type,
s.status_name AS status
from accounts_backup a
join Account_Type t on a.account_type = t.type_id
join Account_Status s on a.status = s.status_id;

select * from Accounts; 
select * from Accounts_backup;


select * from ATMTtransactions;

select * into ATMTtransactions_backup from ATMTtransactions;
select * from ATMTtransactions_backup;


--fix data type
--fix amount from varchar to decimal
alter table ATMTtransactions_backup
alter column amount decimal (18,2) not null;

--fix transaction_date - convert to DATE
alter table ATMTtransactions_backup add transaction_date date;

update ATMTtransactions_backup
set transaction_date = transaction_date_str
where ISDATE(transaction_date_str) = 1;

--drop old string column
alter table ATMTtransactions_backup drop column transaction_date_str;

--rename new column
exec sp_rename 'ATMTtransactions_backup.transaction_date', 'transaction_date', 'COLUMN';

--fix table name 
IF EXISTS (SELECT*FROM sys.tables where name = 'TableName')
begin
exec sp_rename 'TableName','ATMTtransactions_backup';
end

--HANDLE MISSING DATA 
update ATMTtransactions_backup 
set account_number = 'BBL0000000000' 
where account_number is null;

update ATMTtransactions_backup 
set amount = 0 
where amount is null;

update ATMTtransactions_backup 
set status = 'Pending' 
where status is null;

update ATMTtransactions_backup 
set transaction_type = 'Other' 
where transaction_type is null;

update ATMTtransactions_backup 
set atm_location = 'Unknown' 
where atm_location is null;

--make columns not null
alter table ATMTtransactions_backup
alter column atm_transaction_id int not null;

alter table ATMTtransactions_backup
alter column account_number nvarchar(40) not null;

alter table ATMTtransactions_backup
alter column amount decimal(18,2) not null;

alter table ATMTtransactions_backup
alter column transaction_type nvarchar(100) not null;

alter table ATMTtransactions_backup
alter column atm_location nvarchar(200) not null;

alter table ATMTtransactions_backup
alter column status nvarchar(40) not null;

--add pk
-- Make atm_transaction_id not nll
alter table ATMTtransactions_backup
alter column  atm_transaction_id int NOT NULL;

alter table ATMTtransactions_backup
add constraint PK_ATMTtransactions_backup primary key (atm_transaction_id);


--create lookup table
create table Transaction_Type 
(type_id int primary key,
type_name varchar(30) );

--insert values
insert into Transaction_Type values (1, 'Cash Withdrawal');
insert into Transaction_Type values (2, 'Balance Inquiry');
insert into Transaction_Type values (3, 'Mini Statement');

--add new column
alter table ATMTtransactions_backup 
add type_id int;

--update
update ATMTtransactions_backup set type_id = 1 
where transaction_type = 'Cash Withdrawal';
update ATMTtransactions_backup set type_id = 2 
where transaction_type = 'Balance Inquiry';
update ATMTtransactions_backup set type_id = 3 
where transaction_type = 'Mini Statement';

--drop old column
alter table ATMTtransactions_backup 
drop column transaction_type;

--rename
exec sp_rename 'ATMTtransactions_backup.type_id', 'transaction_type', 'COLUMN';

--add foreign key
alter table ATMTtransactions_backup
add constraint FK_ATMTtransactions_Type 
foreign key (transaction_type) references Transaction_Type(type_id);

--create lookup table
create table ATM_Status 
(status_id int primary key,
status_name varchar(20) );

--insert values
insert into ATM_Status values (1, 'Completed');
insert into ATM_Status values (2, 'Failed');

--add new column
alter table ATMTtransactions_backup 
add status_id int;

--update
update ATMTtransactions_backup set status_id = 1 
where status = 'Completed';
update ATMTtransactions_backup set status_id = 2 
where status = 'Failed';

--drop old column
alter table ATMTtransactions_backup 
drop column status;

--rename
exec sp_rename 'ATMTtransactions_backup.status_id', 'status', 'COLUMN';

--add foreign key
alter table ATMTtransactions_backup
add constraint FK_ATMTtransactions_Status 
foreign key (status) references ATM_Status(status_id);

--create lookup table
create table ATM_Location 
(location_id int primary key,
location_name varchar(50) );

-- Insert values
insert into ATM_Location values (1, 'Dhaka Main Branch');
insert into ATM_Location values (2, 'Gulshan Branch');
insert into ATM_Location values (3, 'Chittagong Main Branch');
insert into ATM_Location values (4, 'Rajshahi Branch');
insert into ATM_Location values (5, 'Khulna Branch');
insert into ATM_Location values (6, 'Sylhet Branch');

--add new column
alter table ATMTtransactions_backup 
add location_id int;

--update
update ATMTtransactions_backup set location_id = 1
where atm_location = 'Dhaka Main Branch';
update ATMTtransactions_backup set location_id = 2 
where atm_location = 'Gulshan Branch';
update ATMTtransactions_backup set location_id = 3 
where atm_location = 'Chittagong Main Branch';
update ATMTtransactions_backup set location_id = 4 
where atm_location = 'Rajshahi Branch';
update ATMTtransactions_backup set location_id = 5 
where atm_location = 'Khulna Branch';
update ATMTtransactions_backup set location_id = 6 
where atm_location = 'Sylhet Branch';

--drop old column
alter table ATMTtransactions_backup 
drop column atm_location;

--rename
exec sp_rename 'ATMTtransactions_backup.location_id', 'atm_location', 'COLUMN';

--add foreign key
alter table ATMTtransactions_backup
add constraint FK_ATMTtransactions_Location 
foreign key (atm_location) references ATM_Location(location_id);


select * from BillPayments;
select * into BillPayments_bakup from BillPayments;
select * from BillPayments_bakup;

--fix data types
alter table BillPayments_bakup
alter column amount decimal(18,2) not null;

--fxx payment_date to date
alter table BillPayments_bakup 
add payment_date date;

update BillPayments_bakup
set payment_date = payment_date_str;

--drop old string column
alter table BillPayments_bakup 
drop column payment_date_str;

--rename new column
exec sp_rename 'BillPayments_bakup.payment_date', 'payment_date', 'COLUMN';

--handle MISSING DATA
update BillPayments_bakup 
set account_number = 'BBL0000000000' 
where account_number is null;

update BillPayments_bakup 
set bill_number = 0 
where bill_number is null;

update BillPayments_bakup 
set amount = 0 
where amount is null;

update BillPayments_bakup 
set status = 'Pending' 
where status is null;

update BillPayments_bakup 
set bill_type = 'Other' 
where bill_type is null;

--make columns NOT NULL so that to alter 
alter table BillPayments_bakup 
alter column bill_payment_id int not null;

alter table BillPayments_bakup 
alter column account_number nvarchar(40) not null;

alter table BillPayments_bakup 
alter column bill_number bigint not null;

alter table BillPayments_bakup 
alter column amount decimal(18,2) not null;

alter table BillPayments_bakup 
alter column payment_date date not null;

alter table BillPayments_bakup 
alter column status nvarchar(40) not null;

alter table BillPayments_bakup 
alter column bill_type nvarchar(40) not null;

--add pk
alter table BillPayments_bakup
add constraint PK_BillPayments_backup primary key (bill_payment_id);

--normalize bill_type
create table Bill_Type (type_id int primary key, 
type_name varchar(30));

insert into Bill_Type values (1, 'Internet'), (2, 'Electricity'), (3, 'Gas'), (4, 'Water'), (5, 'TV');

alter table BillPayments_bakup 
add type_id int;

update BillPayments_bakup 
set type_id = 1 
where bill_type = 'Internet';
update BillPayments_bakup 
set type_id = 2 
where bill_type = 'Electricity';
update BillPayments_bakup set type_id = 3 
where bill_type = 'Gas';
update BillPayments_bakup 
set type_id = 4 
where bill_type = 'Water';
update BillPayments_bakup set type_id = 5 
where bill_type = 'TV';

alter table BillPayments_bakup 
drop column bill_type;

exec sp_rename 'BillPayments_bakup.type_id', 'bill_type', 'COLUMN';

alter table BillPayments_bakup
add constraint FK_BillPayments_Type 
foreign key (bill_type) references Bill_Type(type_id);

--normalize status
create table Bill_Status 
(status_id int primary key,
status_name varchar(20));

insert into Bill_Status values (1, 'Completed'), (2, 'Failed');

alter table BillPayments_bakup add status_id int;

update BillPayments_bakup 
set status_id = 1 where status = 'Completed';
update BillPayments_bakup 
set status_id = 2 where status = 'Failed';

alter table BillPayments_bakup drop column status;

exec sp_rename 'BillPayments_bakup.status_id', 'status', 'COLUMN';

alter table BillPayments_bakup
add constraint FK_BillPayments_Status 
foreign key (status) references Bill_Status(status_id);


select * from Branches;
select * into Branches_backup from Branches;
select *from Branches_backup;


--make colm not null
alter table Branches_backup alter column branch_id int not null;
alter table Branches_backup alter column branch_name nvarchar(100) not null;
alter table Branches_backup alter column city nvarchar(50) not null;

--add pk
alter table Branches_backup
add constraint PK_Branches_backup primary key (branch_id);

--add uniquw constraint on branch_name
alter table Branches_backup
add constraint UQ_Branches_backup_BranchName unique (branch_name);

--normalize city
create table City (city_id int primary key, 
city_name varchar(50));

insert into City values (1, 'Dhaka'), (2, 'Chittagong'), (3, 'Sylhet'), (4, 'Khulna'), (5, 'Rajshahi');

alter table Branches_backup 
add city_id int;

update Branches_backup set city_id = 1 
where city = 'Dhaka';
update Branches_backup 
set city_id = 2 where city = 'Chittagong';
update Branches_backup 
set city_id = 3 where city = 'Sylhet';
update Branches_backup 
set city_id = 4 where city = 'Khulna';
update Branches_backup 
set city_id = 5 where city = 'Rajshahi';

alter table Branches_backup 
drop column city;

exec sp_rename 'Branches_backup.city_id', 'city', 'COLUMN';

alter table Branches_backup
add constraint FK_Branches_City
foreign key (city) references City(city_id);


select * from BranchPerformance;
select * into BranchPerformance_backup from BranchPerformance;
select*from BranchPerformance_backup;


--fix data types
alter table BranchPerformance_backup 
alter column performance_id int not null;
alter table BranchPerformance_backup 
alter column branch_id int not null;
alter table BranchPerformance_backup 
alter column total_customers int not null;
alter table BranchPerformance_backup 
alter column total_deposits decimal(18,2) not null;
alter table BranchPerformance_backup
alter column total_loans decimal(18,2) not null;
alter table BranchPerformance_backup 
alter column revenue decimal(18,2) not null;

--month_year from varchar to date
alter table BranchPerformance_backup 
add month_year_date date;
update BranchPerformance_backup 
set month_year_date = month_year + '-01';
alter table BranchPerformance_backup 
drop column month_year;
exec sp_rename 'BranchPerformance_backup.month_year_date', 'month_year', 'COLUMN';

alter table BranchPerformance_backup 
alter column month_year date not null;

--add pk
alter table BranchPerformance_backup
add constraint PK_BranchPerformance_backup 
primary key (performance_id);


-- Normalize month_year (extract year and month into separate columns)
alter table BranchPerformance_backup 
add year int;
alter table BranchPerformance_backup 
add month int;

update BranchPerformance_backup 
set year = year(month_year), 
month = month(month_year);

--create Month lookup table
create table Month_Name (month_id int primary key, 
month_name varchar(20) );

insert into Month_Name values 
(1, 'January'), (2, 'February'), (3, 'March'), 
(4, 'April'), (5, 'May'), (6, 'June'), 
(7, 'July'), (8, 'August'), (9, 'September'), 
(10, 'October'), (11, 'November'), (12, 'December');

--sdd month_id column
alter table BranchPerformance_backup 
add month_id int;

update BranchPerformance_backup 
set month_id = month;

alter table BranchPerformance_backup 
add constraint FK_BranchPerformance_Month 
foreign key (month_id) references Month_Name(month_id);

--drop original month_year column
alter table BranchPerformance_backup 
drop column month_year;

alter table BranchPerformance_backup
add constraint FK_BranchPerformance_Branch 
foreign key (branch_id) references Branches_backup(branch_id);


select * from ChequeTransactions;
select * into ChequeTransactions_backup from ChequeTransactions;
select * from ChequeTransactions_backup;


--fix data types
alter table ChequeTransactions_backup 
alter column cheque_id int not null;
alter table ChequeTransactions_backup 
alter column account_number nvarchar(20) not null;
alter table ChequeTransactions_backup 
alter column cheque_number bigint not null;
alter table ChequeTransactions_backup 
alter column amount decimal(18,2) not null;

--fix issue_date
alter table ChequeTransactions_backup
add issue_date date;
update ChequeTransactions_backup 
set issue_date = issue_date_str;
alter table ChequeTransactions_backup 
drop column issue_date_str;
exec sp_rename 'ChequeTransactions_backup.issue_date', 'issue_date', 'COLUMN';
alter table ChequeTransactions_backup 
alter column issue_date date not null;

--cleaning_date (allow nulls since some are NULL in data)
exec sp_rename 'ChequeTransactions_backup.clearing_date_str', 'clearing_date', 'COLUMN';

select account_number from ChequeTransactions_backup;
select account_number from Accounts_backup; 

--EB 9862139468 = 12 BBL 1000507468 = 13 -- 
-- checking if the numeric parts matches or not -- 

SELECT COUNT(*) AS matched_by_last_10_digits
FROM ChequeTransactions_backup c
JOIN Accounts_backup a
ON RIGHT(c.account_number, 10) = RIGHT(a.account_number, 10);

-- change chequeTransactions_backup table's account number prefix 
UPDATE ChequeTransactions_backup
SET account_number = 'BBL' + RIGHT(account_number, 10)
WHERE account_number LIKE 'EB%';

-- count orphan rows -- 
SELECT COUNT(*) AS orphan_rows
FROM ChequeTransactions_backup c
LEFT JOIN Accounts_backup a
ON c.account_number = a.account_number
WHERE a.account_number IS NULL; 


-- Add PRIMARY KEY
alter table ChequeTransactions_backup
add constraint PK_ChequeTransactions_backup primary key (cheque_id);

--normalize status
create table Cheque_Status (status_id int primary key, status_name varchar(20));

insert into Cheque_Status values (1, 'Cleared'), (2, 'Pending'), (3, 'Bounced'), (4, 'Cancelled');

alter table ChequeTransactions_backup add status_id int;

update ChequeTransactions_backup set status_id = 1 where status = 'Cleared';
update ChequeTransactions_backup set status_id = 2 where status = 'Pending';
update ChequeTransactions_backup set status_id = 3 where status = 'Bounced';
update ChequeTransactions_backup set status_id = 4 where status = 'Cancelled';

alter table ChequeTransactions_backup drop column status;

exec sp_rename 'ChequeTransactions_backup.status_id', 'status', 'COLUMN';

alter table ChequeTransactions_backup
add constraint FK_ChequeTransactions_Status 
foreign key (status) references Cheque_Status(status_id);


select * from CreditCards;
select * into CreditCards_backup from CreditCards;
select * from CreditCards_backup;


--fix data types
alter table CreditCards_backup alter column card_id int not null;
alter table CreditCards_backup alter column customer_id int not null;
alter table CreditCards_backup alter column account_id int not null;
alter table CreditCards_backup alter column card_number varchar(60) not null;
alter table CreditCards_backup alter column credit_limit decimal(18,2) not null;
alter table CreditCards_backup alter column open_date_str date not null;

--rname open_date_str to open_date
exec sp_rename 'CreditCards_backup.open_date_str', 'open_date', 'COLUMN';

--add pk
alter table CreditCards_backup
add constraint PK_CreditCards_backup primary key (card_id);

-- Normalize card_type
create table Card_Type 
(type_id int primary key, type_name varchar(20));

insert into Card_Type values (1, 'Classic'), (2, 'Gold'), (3, 'Platinum');

alter table CreditCards_backup add card_type_id int;

update CreditCards_backup 
set card_type_id = 1 where card_type = 'Classic';
update CreditCards_backup 
set card_type_id = 2 
where card_type = 'Gold';
update CreditCards_backup set card_type_id = 3 
where card_type = 'Platinum';

alter table CreditCards_backup
drop column card_type;

exec sp_rename 'CreditCards_backup.card_type_id', 'card_type', 'COLUMN';

alter table CreditCards_backup
add constraint FK_CreditCards_Type 
foreign key (card_type) references Card_Type(type_id);

--nrmalize status
create table Card_Status 
(status_id int primary key, status_name varchar(20));

insert into Card_Status values (1, 'Active'), (2, 'Closed'), (3, 'Suspended');

alter table CreditCards_backup 
add status_id int;

update CreditCards_backup set status_id = 1 
where status = 'Active';
update CreditCards_backup set status_id = 2
where status = 'Closed';
update CreditCards_backup set status_id = 3 
where status = 'Suspended';

alter table CreditCards_backup drop column status;

exec sp_rename 'CreditCards_backup.status_id', 'status', 'COLUMN';

alter table CreditCards_backup
add constraint FK_CreditCards_Status 
foreign key (status) references Card_Status(status_id);


select * from CreditCardTransactions;

select * into CreditCardTransactions_backup from CreditCardTransactions;
select * from CreditCardTransactions_backup;

--fix data types
alter table CreditCardTransactions_backup 
alter column cc_transaction_id int not null;
alter table CreditCardTransactions_backup 
alter column card_number nvarchar(60) not null;
alter table CreditCardTransactions_backup 
alter column amount decimal(18,2) not null;
alter table CreditCardTransactions_backup 
alter column merchant_name nvarchar(200) not null;

--fix transaction_date (column name is transaction_date_str, not transaction_date_stamp)
alter table CreditCardTransactions_backup 
add transaction_date date;
update CreditCardTransactions_backup 
set transaction_date = transaction_date_str;
alter table CreditCardTransactions_backup 
drop column transaction_date_str;
exec sp_rename 'CreditCardTransactions_backup.transaction_date', 'transaction_date', 'COLUMN';
alter table CreditCardTransactions_backup 
alter column transaction_date date not null;

--add pk
alter table CreditCardTransactions_backup
add constraint PK_CreditCardTransactions_backup primary key (cc_transaction_id);

-- Normalize status
create table CC_Status 
(status_id int primary key, status_name varchar(20));

insert into CC_Status values (1, 'Completed'), (2, 'Failed'), (3, 'Refunded');

alter table CreditCardTransactions_backup 
add status_id int;

update CreditCardTransactions_backup 
set status_id = 1 where status = 'Completed';
update CreditCardTransactions_backup 
set status_id = 2 where status = 'Failed';
update CreditCardTransactions_backup 
set status_id = 3 where status = 'Refunded';

alter table CreditCardTransactions_backup 
drop column status;

exec sp_rename 'CreditCardTransactions_backup.status_id', 'status', 'COLUMN';

alter table CreditCardTransactions_backup
add constraint FK_CCTransactions_Status 
foreign key (status) references CC_Status(status_id);

-- Normalize category
create table Category 
(category_id int primary key, category_name varchar(30));

insert into Category values (1, 'Entertainment'), (2, 'Food'), (3, 'Bills'), (4, 'Shopping'), (5, 'Travel');

alter table CreditCardTransactions_backup 
add category_id int;

update CreditCardTransactions_backup 
set category_id = 1 where category = 'Entertainment';
update CreditCardTransactions_backup 
set category_id = 2 where category = 'Food';
update CreditCardTransactions_backup 
set category_id = 3 where category = 'Bills';
update CreditCardTransactions_backup 
set category_id = 4 where category = 'Shopping';
update CreditCardTransactions_backup 
set category_id = 5 where category = 'Travel';

alter table CreditCardTransactions_backup 
drop column category;

exec sp_rename 'CreditCardTransactions_backup.category_id', 'category', 'COLUMN';

alter table CreditCardTransactions_backup
add constraint FK_CCTransactions_Category 
foreign key (category) references Category(category_id);

-- Customers Table -- 
select * from Customers; 

-- checking null values in customers table 
SELECT *
FROM Customers
WHERE name IS NULL
   OR Phone IS NULL
   OR Email IS NULL
   OR nid IS NULL
   OR Address IS NULL
   OR City IS NULL
   OR customer_type_id IS NULL
   OR registration_date IS NULL
   OR Status IS NULL;

-- removing extra spaces from text column 
UPDATE customers
SET 
    name = LTRIM(RTRIM(name)),
    phone = LTRIM(RTRIM(phone)),
    email = LTRIM(RTRIM(email)),
    nid = LTRIM(RTRIM(nid)),
    address = LTRIM(RTRIM(address)),
    city = LTRIM(RTRIM(city)),
    status = LTRIM(RTRIM(status));

-- making email lowercase 
UPDATE customers
SET email = LOWER(email)
WHERE email IS NOT NULL;

-- finding invalid emails 
SELECT *
FROM customers
WHERE email IS NOT NULL
  AND email NOT LIKE '%_@_%._%';

-- Update the existing 'email' column based on the domain extension

UPDATE Customers
SET email = REPLACE(email, '@example.org', '@microsoft.org')
WHERE email LIKE '%@example.org'; 

UPDATE Customers
SET email = REPLACE(email, '@example.com', '@gmail.com')
WHERE email LIKE '%@example.com'; 

UPDATE Customers
SET email = REPLACE(email, '@example.net', '@yahoo.net')
WHERE email LIKE '%@example.net';


-- check duplicate email 
SELECT email, COUNT(*) AS duplicate_count
FROM customers
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1;

-- standardize status 
UPDATE customers
SET status = 'Active'
WHERE status IN ('active', 'ACTIVE', 'Actve', 'actve');

UPDATE customers
SET status = 'Suspended'
WHERE status IN ('suspended', 'SUSPENDED', 'Suspend', 'suspend');

UPDATE customers
SET status = 'Closed'
WHERE status IN ('closed', 'CLOSED', 'Close', 'close');

-- Update the existing 'city' column in place
UPDATE Customers 
SET city = UPPER(LTRIM(RTRIM(city)));

-- making important columns NOT Null 
ALTER TABLE customers
ALTER COLUMN name VARCHAR(100) NOT NULL;

ALTER TABLE customers
ALTER COLUMN phone VARCHAR(20) NOT NULL;

ALTER TABLE customers
ALTER COLUMN address VARCHAR(255) NOT NULL;

ALTER TABLE customers
ALTER COLUMN city VARCHAR(50) NOT NULL;

ALTER TABLE customers
ALTER COLUMN customer_type_id INT NOT NULL;

ALTER TABLE customers
ALTER COLUMN registration_date DATE NOT NULL;

ALTER TABLE customers
ALTER COLUMN status VARCHAR(20) NOT NULL;

-- Add unique constraints 
ALTER TABLE customers
ADD CONSTRAINT UQ_customers_phone UNIQUE (phone);

CREATE UNIQUE INDEX UX_customers_nid
ON customers(nid)
WHERE nid IS NOT NULL; 

-- Customers 
ALTER TABLE Customers
ALTER COLUMN customer_id INT NOT NULL; 

ALTER TABLE Customers
ADD CONSTRAINT PK_Customers
PRIMARY KEY (customer_id); 


-- Performing 1NF 

-- Add first_name & last_name 

ALTER TABLE customers
ADD first_name VARCHAR(50),
    last_name VARCHAR(50);

-- Split name into first_name and last_name 
UPDATE customers
SET 
    first_name = LEFT(name, CHARINDEX(' ', name + ' ') - 1),
    last_name = LTRIM(SUBSTRING(name,CHARINDEX(' ', name + ' ') + 1,LEN(name)));

-- check -- 
SELECT customer_id, name, first_name, last_name
FROM customers;
-- Drop Name column 
ALTER TABLE customers DROP COLUMN name;
select * from Customers;

-- 2NF on customers table 
-- creating seperate table for customer status 
CREATE TABLE customer_status (
    status_id INT IDENTITY(1,1) PRIMARY KEY,
    status_name VARCHAR(20) NOT NULL UNIQUE
);

INSERT INTO customer_status (status_name)
SELECT DISTINCT status
FROM customers
WHERE status IS NOT NULL;

ALTER TABLE customers
ADD status_id INT;

UPDATE c
SET c.status_id = cs.status_id
FROM customers c
INNER JOIN customer_status cs
    ON c.status = cs.status_name;

ALTER TABLE customers
ADD CONSTRAINT FK_customers_customer_status
FOREIGN KEY (status_id) REFERENCES customer_status(status_id);

ALTER TABLE Customers DROP COLUMN status;

-- CustomerTypes -- 

ALTER TABLE CustomerTypes
ALTER COLUMN type_id INT NOT NULL; 

ALTER TABLE CustomerTypes
ADD CONSTRAINT PK_CustomerTypes
PRIMARY KEY (type_id);


ALTER TABLE customers
ADD CONSTRAINT FK_customers_customer_type
FOREIGN KEY (customer_type_id) REFERENCES customerTypes(type_id);


-- Credit Scores Table 
-- Creating Backup before cleaning 
select * from CreditScores;
select * into CreditScores_backup from CreditScores;

-- Finding Null values  
SELECT *
FROM CreditScores
WHERE score_id IS NULL
   OR customer_id IS NULL
   OR credit_score IS NULL
   OR calculated_at IS NULL;

-- score id holds value of customer id where it should hold a unique value for every customers
SELECT COUNT(*) AS same_scoreid_customerid_count
FROM CreditScores
WHERE score_id = customer_id;

-- dropping score_id  
ALTER TABLE CreditScores
DROP COLUMN score_id;

ALTER TABLE CreditScores
ALTER COLUMN customer_id INT NOT NULL; 
-- 
ALTER TABLE CreditScores
ADD CONSTRAINT CHK_CreditScores_Range
CHECK (credit_score BETWEEN 300 AND 850);

-- Employees Table -- 

select * from Employees;
SELECT * INTO Employees_Backup FROM Employees;

-- Remove text extra spaces
UPDATE Employees
SET 
    name = LTRIM(RTRIM(name)),
    phone = LTRIM(RTRIM(phone)),
    email = LTRIM(RTRIM(email)),
    department = LTRIM(RTRIM(department)),
    designation = LTRIM(RTRIM(designation)),
    status = LTRIM(RTRIM(status));

-- check email -- 
UPDATE Employees
SET email = LOWER(email)
WHERE email IS NOT NULL;


-- Adding Constraints -- 

ALTER TABLE Employees
ALTER COLUMN employee_id INT NOT NULL;

ALTER TABLE Employees
ALTER COLUMN branch_id INT NOT NULL;

ALTER TABLE Employees
ALTER COLUMN hire_date DATE NOT NULL;

ALTER TABLE Employees
ALTER COLUMN salary DECIMAL(12,2) NOT NULL;

ALTER TABLE Employees
ADD CONSTRAINT PK_Employees
PRIMARY KEY (employee_id); 

select * from Branches
select * from Employees 


-- 1NF -- 
-- split name 
ALTER TABLE Employees
ADD first_name VARCHAR(50),
    last_name VARCHAR(50); 



UPDATE Employees
SET 
    first_name = LEFT(name, CHARINDEX(' ', name + ' ') - 1),
    last_name = LTRIM(SUBSTRING name, CHARINDEX(' ', name + ' ') + 1, LEN(name)));
  
ALTER TABLE Employees
DROP COLUMN name; 
-- since the employee have only one phone number and one email address this was kept in main table. 
-- Though there is inconsistency in phone numbers. But there can be foreign employees as well. 

--2NF -- 
-- create table departments -- 
CREATE TABLE Departments (
    department_id INT IDENTITY(1,1) PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO Departments (department_name)
SELECT DISTINCT department
FROM Employees
WHERE department IS NOT NULL;

-- Add department_id to Employees -- 

ALTER TABLE Employees
ADD department_id INT;

UPDATE e
SET e.department_id = d.department_id
FROM Employees e
INNER JOIN Departments d
    ON e.department = d.department_name;

-- Drop department columns --  
ALTER TABLE Employees
DROP COLUMN department;

-- create designations table --

CREATE TABLE Designations (
    designation_id INT IDENTITY(1,1) PRIMARY KEY,
    designation_name VARCHAR(50) NOT NULL UNIQUE
); 

INSERT INTO Designations (designation_name)
SELECT DISTINCT designation
FROM Employees
WHERE designation IS NOT NULL; 

ALTER TABLE Employees
ADD designation_id INT; 

UPDATE e
SET e.designation_id = d.designation_id
FROM Employees e
INNER JOIN Designations d
    ON e.designation = d.designation_name; 

ALTER TABLE Employees
DROP COLUMN designation;


-- Create employee status table -- 
CREATE TABLE Employee_Status (
    status_id INT IDENTITY(1,1) PRIMARY KEY,
    status_name VARCHAR(30) NOT NULL UNIQUE
); 

INSERT INTO Employee_Status (status_name)
SELECT DISTINCT status
FROM Employees
WHERE status IS NOT NULL; 

ALTER TABLE Employees
ADD status_id INT; 

UPDATE e
SET e.status_id = s.status_id
FROM Employees e
INNER JOIN Employee_Status s
    ON e.status = s.status_name; 

ALTER TABLE Employees
DROP COLUMN status; 

ALTER TABLE Employees
ADD CONSTRAINT FK_Employees_Departments
FOREIGN KEY (department_id) REFERENCES Departments(department_id); 

ALTER TABLE Employees
ADD CONSTRAINT FK_Employees_Designations
FOREIGN KEY (designation_id) REFERENCES Designations(designation_id); 

ALTER TABLE Employees
ADD CONSTRAINT FK_Employees_Status
FOREIGN KEY (status_id) REFERENCES Employee_Status(status_id);  

ALTER TABLE Employees
ADD CONSTRAINT FK_Employees_Branches
FOREIGN KEY (branch_id) REFERENCES Branches_backup(branch_id); 

select * from Employees;

-- Fixed Deposits -- 
select * from FixedDeposits; 

SELECT *
INTO FixedDeposits_Backup
FROM FixedDeposits; 

-- Remove extra spaces -- 
UPDATE FixedDeposits
SET 
    open_date_str = LTRIM(RTRIM(open_date_str)),
    maturity_date_str = LTRIM(RTRIM(maturity_date_str)),
    status = LTRIM(RTRIM(status));
-- Add proper Date columns -- 
ALTER TABLE FixedDeposits
ADD open_date DATE,
    maturity_date DATE;

-- Convert string dates into real date columns 
UPDATE FixedDeposits
SET 
    open_date = TRY_CONVERT(DATE, open_date_str),
    maturity_date = TRY_CONVERT(DATE, maturity_date_str);

-- check -- 
SELECT fd_id, open_date_str, open_date, maturity_date_str, maturity_date
FROM FixedDeposits;

-- drop old string date columns -- 
ALTER TABLE FixedDeposits
DROP COLUMN open_date_str;

ALTER TABLE FixedDeposits
DROP COLUMN maturity_date_str; 

-- Add constraints -- 
ALTER TABLE FixedDeposits
ALTER COLUMN fd_id INT NOT NULL;

ALTER TABLE FixedDeposits
ALTER COLUMN customer_id INT NOT NULL;

ALTER TABLE FixedDeposits
ALTER COLUMN account_id INT NOT NULL;

ALTER TABLE FixedDeposits
ALTER COLUMN deposit_amount DECIMAL(12,2) NOT NULL;

ALTER TABLE FixedDeposits
ALTER COLUMN interest_rate DECIMAL(5,2) NOT NULL;

ALTER TABLE FixedDeposits
ALTER COLUMN open_date DATE NOT NULL;

ALTER TABLE FixedDeposits
ALTER COLUMN maturity_date DATE NOT NULL;

ALTER TABLE FixedDeposits
ALTER COLUMN status VARCHAR(20) NOT NULL; 

ALTER TABLE FixedDeposits
ADD CONSTRAINT PK_FixedDeposits
PRIMARY KEY (fd_id);  

ALTER TABLE FixedDeposits
ADD CONSTRAINT FK_FixedDeposits_Customers
FOREIGN KEY (customer_id) REFERENCES Customers(customer_id);  

ALTER TABLE FixedDeposits
ADD CONSTRAINT FK_FixedDeposits_Accounts
FOREIGN KEY (account_id) REFERENCES Accounts_backup(account_id); 

-- Fraud Alerts -- 
select * from FraudAlerts;
select * from Accounts; 
select * from Transactions; 

-- clean extra spaces -- 
UPDATE FraudAlerts
SET
    account_number = LTRIM(RTRIM(account_number)),
    reason = LTRIM(RTRIM(reason)),
    raised_at_str = LTRIM(RTRIM(raised_at_str)); 

-- convert raised_at_str to proper DATETIME -- 
ALTER TABLE FraudAlerts
ADD raised_at DATETIME; 

UPDATE FraudAlerts
SET raised_at = TRY_CONVERT(DATETIME, raised_at_str);

ALTER TABLE FraudAlerts
DROP COLUMN raised_at_str;
-- As the time is always 00:00 we remove that. -- 
ALTER TABLE FraudAlerts
ALTER COLUMN raised_at DATE;

-- check duplicate transaction ids -- 
SELECT transaction_id, COUNT(*) AS alert_count
FROM FraudAlerts
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- This is a data flaw. There are 8 records with repetitive transaction IDs.

-- Add constraints -- 
ALTER TABLE FraudAlerts
ALTER COLUMN alert_id INT NOT NULL;

ALTER TABLE FraudAlerts
ALTER COLUMN transaction_id INT NOT NULL;

ALTER TABLE FraudAlerts
ALTER COLUMN account_number VARCHAR(20) NOT NULL;

ALTER TABLE FraudAlerts
ALTER COLUMN reason VARCHAR(50) NOT NULL;

ALTER TABLE FraudAlerts
ALTER COLUMN raised_at DATE NOT NULL;

ALTER TABLE FraudAlerts
ALTER COLUMN resolved BIT NOT NULL; 

ALTER TABLE FraudAlerts
ADD CONSTRAINT PK_FraudAlerts
PRIMARY KEY (alert_id);

-- InterestRates Table -- 
-- remove extra spaces 
UPDATE InterestRates
SET
    branch_name = LTRIM(RTRIM(branch_name)),
    account_type = LTRIM(RTRIM(account_type)),
    effective_date_str = LTRIM(RTRIM(effective_date_str)),
    status = LTRIM(RTRIM(status));  

-- convert effective_date_str to proper date -- 
ALTER TABLE InterestRates
ADD effective_date DATE; 

UPDATE InterestRates
SET effective_date = TRY_CONVERT(DATE, effective_date_str); 

ALTER TABLE InterestRates
DROP COLUMN effective_date_str;

-- Add constraints -- 
ALTER TABLE InterestRates
ALTER COLUMN rate_id INT NOT NULL;

ALTER TABLE InterestRates
ALTER COLUMN branch_name VARCHAR(100) NOT NULL;

ALTER TABLE InterestRates
ALTER COLUMN account_type VARCHAR(50) NOT NULL;

ALTER TABLE InterestRates
ALTER COLUMN effective_date DATE NOT NULL;

ALTER TABLE InterestRates
ALTER COLUMN status VARCHAR(20) NOT NULL;

ALTER TABLE InterestRates
ADD CONSTRAINT PK_InterestRates
PRIMARY KEY (rate_id); 

ALTER TABLE InterestRates
ADD CONSTRAINT FK_InterestRates_Branches
FOREIGN KEY (branch_id) REFERENCES Branches_backup(branch_id); 

-- Add branch ID -- 
ALTER TABLE InterestRates
ADD branch_id INT; 

UPDATE ir
SET ir.branch_id = b.branch_id
FROM InterestRates ir
INNER JOIN Branches b
    ON ir.branch_name = b.branch_name; 

ALTER TABLE InterestRates
DROP COLUMN branch_name;

drop table Employees_Invalid_HireDates;


-- Drop the existing primary key from customer_id
ALTER TABLE CreditScores
DROP CONSTRAINT PK_CreditScores;

-- Add score_id as primary key 

ALTER TABLE CreditScores
ADD score_id INT IDENTITY(1,1) NOT NULL; 

ALTER TABLE CreditScores
ADD CONSTRAINT PK_CreditScores
PRIMARY KEY (score_id);

--

select * from Account_Type;
select * from InterestRates; 

-- Add new column
ALTER TABLE InterestRates
ADD account_type_id INT ;

UPDATE ir
SET ir.account_type_id = at.type_id
FROM InterestRates ir
JOIN Account_Type at
ON ir.account_type = at.type_name;

-- add foreign key 

ALTER TABLE InterestRates
ADD CONSTRAINT FK_InterestRates_AccountType
FOREIGN KEY (account_type_id)
REFERENCES Account_Type(type_id); 

ALTER TABLE InterestRates
DROP COLUMN account_type;

select * into KYC_backup from KYCDocuments;
select * from KYC_backup;

-- Fix data types
alter table KYC_backup alter column doc_id int not null;
alter table KYC_backup alter column customer_id int not null;
alter table KYC_backup alter column doc_number bigint not null;
alter table KYC_backup alter column verified_at date not null;
alter table KYC_backup alter column is_valid bit not null;

-- Add PRIMARY KEY
alter table KYC_backup
add constraint PK_KYC_backup primary key (doc_id);

-- Normalize doc_type
alter table KYC_backup add doc_type_id int;

update KYC_backup set doc_type_id = 1 where doc_type = 'Passport';
update KYC_backup set doc_type_id = 2 where doc_type = 'NID';
update KYC_backup set doc_type_id = 3 where doc_type = 'Driving License';
update KYC_backup set doc_type_id = 4 where doc_type = 'Utility Bill';

select * from KYC_backup; 

-- creating kyc_doc_type Table -- 

CREATE TABLE KYC_Doc_Type (
    doc_type_id INT PRIMARY KEY not null,
    doc_type_name VARCHAR(50) NOT NULL UNIQUE); 

INSERT INTO KYC_Doc_Type (doc_type_id, doc_type_name)
SELECT DISTINCT doc_type_id, doc_type
FROM KYC_backup
WHERE doc_type_id IS NOT NULL
AND doc_type IS NOT NULL; 

SELECT * FROM KYC_Doc_Type;

alter table KYC_backup drop column doc_type;


select * into LoanPayments_backup from LoanPayments;

-- Fix data types
alter table LoanPayments_backup alter column payment_id int not null;
alter table LoanPayments_backup alter column loan_id int not null;
alter table LoanPayments_backup alter column amount_paid decimal(18,2) not null;

-- Fix payment_date
alter table LoanPayments_backup add payment_date date;
update LoanPayments_backup set payment_date = payment_date_str;
alter table LoanPayments_backup drop column payment_date_str;
alter table LoanPayments_backup alter column payment_date date not null;

-- Add PRIMARY KEY
alter table LoanPayments_backup add constraint PK_LoanPayments_backup primary key (payment_id);

select * from loanPayments_backup;


-- Normalize payment_method (Payment_Method table already exists)
alter table LoanPayments_backup add method_id int;
update LoanPayments_backup set method_id = 1 where payment_method = 'Cash';
update LoanPayments_backup set method_id = 2 where payment_method = 'Cheque';
update LoanPayments_backup set method_id = 3 where payment_method = 'Transfer';

-- create loan payment method table -- 

CREATE TABLE Loan_Payment_Method (
    method_id INT PRIMARY KEY not null,
    method_name VARCHAR(30) NOT NULL UNIQUE); 

INSERT INTO Loan_Payment_Method (method_id, method_name)
SELECT DISTINCT method_id, payment_method
FROM LoanPayments_backup
WHERE method_id IS NOT NULL
AND payment_method IS NOT NULL; 

SELECT * FROM Loan_Payment_Method;

alter table LoanPayments_backup drop column payment_method;

exec sp_rename 'LoanPayments_backup.method_id', 'payment_method', 'COLUMN';

-- create loanPayment_status table 

CREATE TABLE LoanPayment_Status (
    status_id INT PRIMARY KEY not null,
    status_name VARCHAR(30) NOT NULL UNIQUE);

alter table LoanPayments_backup add status_id int;
update LoanPayments_backup set status_id = 1 where status = 'Completed';

INSERT INTO LoanPayment_Status (status_id, status_name)
VALUES
(1, 'Completed'),
(2, 'Pending'),
(3, 'Failed'),
(4, 'Cancelled');

alter table LoanPayments_backup drop column status; 

exec sp_rename 'LoanPayments_backup.status_id', 'status', 'COLUMN';

select * from LoanPayment_Status;
select * from LoanPayments_backup;
select * from Loan_Payment_Method;

-- ADD FK -- 

ALTER TABLE LoanPayments_backup
ADD CONSTRAINT FK_LoanPaymentsBackup_Loans
FOREIGN KEY (loan_id)
REFERENCES Loans_backup(loan_id); 

ALTER TABLE LoanPayments_backup
ADD CONSTRAINT FK_LoanPaymentsBackup_Method
FOREIGN KEY (payment_method)
REFERENCES Loan_Payment_Method(method_id); 

ALTER TABLE LoanPayments_backup
ADD CONSTRAINT FK_LoanPaymentsBackup_Status
FOREIGN KEY (status)
REFERENCES LoanPayment_Status(status_id);


-- Fix data types
alter table Promotions_backup alter column promo_id int not null;
alter table Promotions_backup alter column promo_code nvarchar(50) not null;
alter table Promotions_backup alter column description nvarchar(500) not null;
alter table Promotions_backup alter column discount_percent int not null;
alter table Promotions_backup alter column min_amount decimal(18,2) not null;
alter table Promotions_backup alter column valid_from date not null;
alter table Promotions_backup alter column valid_to date not null;
alter table Promotions_backup alter column applicable_account_types nvarchar(100) not null;

-- Add PRIMARY KEY
alter table Promotions_backup add constraint PK_Promotions_backup primary key (promo_id);

select * from Promotions_backup;
select * from Account_Type;

-- Normalize applicable_account_types
ALTER TABLE Promotions_backup ADD account_type_id INT; 

UPDATE p
SET p.account_type_id = at.type_id
FROM Promotions_backup p
JOIN Account_Type at
ON p.applicable_account_types = at.type_name; 

ALTER TABLE Promotions_backup
ADD CONSTRAINT FK_PromotionsBackup_AccountType
FOREIGN KEY (account_type_id)
REFERENCES Account_Type(type_id);

ALTER TABLE Promotions_backup
DROP COLUMN applicable_account_types; 

SELECT *FROM Promotions_backup;

exec sp_rename 'Promotions_backup.account_type_id', 'applicable_account_types', 'COLUMN';

-- 1. Create backup
SELECT * INTO Transactions_backup 
FROM Transactions;  

-- 2. Verify backup
SELECT * FROM Transactions_backup;


-- 1. Fix data type for amount (convert from VARCHAR to DECIMAL)
-- First, handle any non-numeric values by setting them to 0
UPDATE Transactions_backup 
SET amount = '0' 
WHERE ISNUMERIC(amount) = 0 OR amount IS NULL;

-- Now alter the column
ALTER TABLE Transactions_backup 
ALTER COLUMN amount DECIMAL(18,2) NOT NULL;

-- 2. Fix transaction_date - convert from string to DATE
-- Add a new date column
ALTER TABLE Transactions_backup ADD transaction_date DATE;

-- Update with valid dates (using TRY_CONVERT to avoid errors)
UPDATE Transactions_backup 
SET transaction_date = TRY_CONVERT(DATE, transaction_date_str);

-- Set any NULL dates to a default (e.g., '1900-01-01')
UPDATE Transactions_backup 
SET transaction_date = '1900-01-01' 
WHERE transaction_date IS NULL;

-- Drop the old string column
ALTER TABLE Transactions_backup DROP COLUMN transaction_date_str;

-- 3. Handle missing data (set defaults for NULL values)
UPDATE Transactions_backup SET account_id = 0 WHERE account_id IS NULL;
UPDATE Transactions_backup SET type_id = 0 WHERE type_id IS NULL;
UPDATE Transactions_backup SET description = 'No Description' WHERE description IS NULL;
UPDATE Transactions_backup SET status = 'Pending' WHERE status IS NULL;
UPDATE Transactions_backup SET channel = 'Unknown' WHERE channel IS NULL;
UPDATE Transactions_backup SET teller_id = 0 WHERE teller_id IS NULL;

-- 4. Make all columns NOT NULL
ALTER TABLE Transactions_backup ALTER COLUMN transaction_id INT NOT NULL;
ALTER TABLE Transactions_backup ALTER COLUMN account_id INT NOT NULL;
ALTER TABLE Transactions_backup ALTER COLUMN type_id INT NOT NULL;
ALTER TABLE Transactions_backup ALTER COLUMN description NVARCHAR(400) NOT NULL;
ALTER TABLE Transactions_backup ALTER COLUMN status NVARCHAR(40) NOT NULL;
ALTER TABLE Transactions_backup ALTER COLUMN channel NVARCHAR(40) NOT NULL;
ALTER TABLE Transactions_backup ALTER COLUMN teller_id INT NOT NULL;

-- 5. Add PRIMARY KEY
ALTER TABLE Transactions_backup 
ADD CONSTRAINT PK_Transactions_backup PRIMARY KEY (transaction_id);

-- NORMALIZE Transactions TABLE


-- STEP 1: Create lookup table for Transaction Types 

-- Already created transaction type 
CREATE TABLE Transaction_Type (
    type_id INT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL
);

INSERT INTO Transaction_Type VALUES 
(1, 'Deposit'),
(2, 'Withdrawal'),
(3, 'Transfer'),
(4, 'Payment'),
(5, 'Fee');
select * from transactiontypes;
------------------------------------

-- STEP 2: Create lookup table for Status
CREATE TABLE Transaction_Status (
    status_id INT PRIMARY KEY,
    status_name VARCHAR(30) NOT NULL
);

INSERT INTO Transaction_Status VALUES 
(1, 'Pending'),
(2, 'Completed'),
(3, 'Failed'),
(4, 'Cancelled');

-- STEP 3: Create lookup table for Channel
CREATE TABLE Transaction_Channel (
    channel_id INT PRIMARY KEY,
    channel_name VARCHAR(30) NOT NULL
);

INSERT INTO Transaction_Channel VALUES 
(1, 'Branch'),
(2, 'ATM'),
(3, 'Online'),
(4, 'Mobile'),
(5, 'IVR'),
(6, 'Unknown');

-- STEP 4: Add foreign key columns to Transactions table
ALTER TABLE Transactions ADD type_id_ref INT;
ALTER TABLE Transactions ADD status_id_ref INT;
ALTER TABLE Transactions ADD channel_id_ref INT;

-- STEP 5: Map existing values to lookup table IDs
UPDATE Transactions SET type_id_ref = type_id;

UPDATE Transactions SET status_id_ref = 1 WHERE status = 'Pending';

UPDATE Transactions SET status_id_ref = 2 WHERE status = 'Completed';

UPDATE Transactions SET status_id_ref = 3 WHERE status = 'Failed';

UPDATE Transactions SET status_id_ref = 4 WHERE status = 'Cancelled';

UPDATE Transactions SET channel_id_ref = 1 WHERE channel = 'Branch';

UPDATE Transactions SET channel_id_ref = 2 WHERE channel = 'ATM';

UPDATE Transactions SET channel_id_ref = 3 WHERE channel = 'Online';

UPDATE Transactions SET channel_id_ref = 4 WHERE channel = 'Mobile';

UPDATE Transactions SET channel_id_ref = 5 WHERE channel = 'IVR';

UPDATE Transactions SET channel_id_ref = 6 
WHERE channel NOT IN ('Branch', 'ATM', 'Online', 'Mobile', 'IVR') OR channel IS NULL;

-- STEP 6: Drop old columns
ALTER TABLE Transactions DROP COLUMN type_id;
ALTER TABLE Transactions DROP COLUMN status;
ALTER TABLE Transactions DROP COLUMN channel;

-- STEP 7: Rename new columns
EXEC sp_rename 'Transactions.type_id_ref', 'type_id', 'COLUMN';
EXEC sp_rename 'Transactions.status_id_ref', 'status', 'COLUMN';
EXEC sp_rename 'Transactions.channel_id_ref', 'channel', 'COLUMN';


-- Drop existing constraint if it exists
ALTER TABLE Transactions DROP CONSTRAINT IF EXISTS FK_Transactions_Type;

-- Insert all missing type_id values from Transactions
INSERT INTO Transaction_Type (type_id, type_name)
SELECT DISTINCT type_id, 'Type_' + CAST(type_id AS VARCHAR)
FROM Transactions 
WHERE type_id NOT IN (SELECT type_id FROM Transaction_Type);

-- Add foreign key constraint
ALTER TABLE Transactions 
ADD CONSTRAINT FK_Transactions_Type 
FOREIGN KEY (type_id) REFERENCES Transaction_Type(type_id);


ALTER TABLE Transactions 
ADD CONSTRAINT FK_Transactions_Status 
FOREIGN KEY (status) REFERENCES Transaction_Status(status_id);

ALTER TABLE Transactions 
ADD CONSTRAINT FK_Transactions_Channel 
FOREIGN KEY (channel) REFERENCES Transaction_Channel(channel_id);

-- STEP 9: Make new columns NOT NULL
ALTER TABLE Transactions ALTER COLUMN type_id INT NOT NULL;
ALTER TABLE Transactions ALTER COLUMN status INT NOT NULL;
ALTER TABLE Transactions ALTER COLUMN channel INT NOT NULL;

-- Fix the generic type names to proper ones
UPDATE Transaction_Type 
SET type_name = 'Cash Withdrawal' 
WHERE type_id = 6;

UPDATE Transaction_Type 
SET type_name = 'Balance Inquiry' 
WHERE type_id = 7;

-- STEP 10: Verify normalization
SELECT 
    t.transaction_id,
    tt.type_name AS transaction_type,
    ts.status_name AS status,
    tc.channel_name AS channel,
    t.amount,
    t.transaction_date_str,
    t.description
FROM Transactions t
JOIN Transaction_Type tt ON t.type_id = tt.type_id
JOIN Transaction_Status ts ON t.status = ts.status_id
JOIN Transaction_Channel tc ON t.channel = tc.channel_id;

select * into SupportTickets_backup from SupportTickets;

-- Fix data types
alter table SupportTickets_backup alter column ticket_id int not null;
alter table SupportTickets_backup alter column customer_id int not null;
alter table SupportTickets_backup alter column account_number nvarchar(20) not null;
alter table SupportTickets_backup alter column description nvarchar(max) not null;
alter table SupportTickets_backup alter column resolved bit not null;

-- Fix logged_at
alter table SupportTickets_backup add logged_at datetime;
update SupportTickets_backup set logged_at = logged_at_str;
alter table SupportTickets_backup drop column logged_at_str;
exec sp_rename 'SupportTickets_backup.logged_at', 'logged_at', 'COLUMN';
alter table SupportTickets_backup alter column logged_at datetime not null;

-- Fix resolved_at
alter table SupportTickets_backup add resolved_at date;
update SupportTickets_backup set resolved_at = resolved_at_str;
alter table SupportTickets_backup drop column resolved_at_str;
exec sp_rename 'SupportTickets_backup.resolved_at', 'resolved_at', 'COLUMN';

-- Add PRIMARY KEY
alter table SupportTickets_backup add constraint PK_SupportTickets_backup primary key (ticket_id);

-- Normalize issue_type (Issue_Type table already exists)
alter table SupportTickets_backup add issue_type_id int;

select * from SupportTickets_backup;

-- create support_issue_type table -- 

CREATE TABLE Support_Issue_Type (
    issue_type_id INT PRIMARY KEY,
    issue_type_name VARCHAR(30) NOT NULL UNIQUE); 

INSERT INTO Support_Issue_Type (issue_type_id, issue_type_name)
VALUES
(1, 'Account'),
(2, 'ATM'),
(3, 'Card'),
(4, 'Loan'),
(5, 'Other'),
(6, 'Transaction'); 

UPDATE st
SET st.issue_type_id = sit.issue_type_id
FROM SupportTickets_backup st
JOIN Support_Issue_Type sit
ON st.issue_type = sit.issue_type_name; 

-- ADD FK -- 

ALTER TABLE SupportTickets_backup
ADD CONSTRAINT FK_SupportTickets_Customers
FOREIGN KEY (customer_id)
REFERENCES Customers(customer_id);

ALTER TABLE SupportTickets_backup
ADD CONSTRAINT FK_SupportTickets_AccountsBackup
FOREIGN KEY (account_number)
REFERENCES Accounts_backup(account_number); 

ALTER TABLE SupportTickets_backup
ADD CONSTRAINT FK_SupportTickets_IssueType
FOREIGN KEY (issue_type_id)
REFERENCES Support_Issue_Type(issue_type_id); 

-- Drop old column - 

ALTER TABLE SupportTickets_backup DROP COLUMN issue_type;


select * into Loans_backup from Loans;


-- Fix data types
alter table Loans_backup alter column loan_id int not null;
alter table Loans_backup alter column customer_id int not null;
alter table Loans_backup alter column account_id int not null;
alter table Loans_backup alter column amount_sanctioned decimal(18,2) not null;
alter table Loans_backup alter column interest_rate decimal(5,2) not null;
alter table Loans_backup alter column tenure_months int not null;
alter table Loans_backup alter column disbursed_date date not null;
alter table Loans_backup alter column monthly_installment decimal(18,2) not null;

-- Add PRIMARY KEY
alter table Loans_backup add constraint PK_Loans_backup primary key (loan_id);

-- Create lookup tables
create table Loan_Type (type_id int primary key, type_name varchar(30));
insert into Loan_Type values (1, 'Agriculture'), (2, 'Business'), (3, 'Car'), (4, 'Education'), (5, 'Home'), (6, 'Personal');

create table Loan_Status (status_id int primary key, status_name varchar(20));
insert into Loan_Status values (1, 'Active'), (2, 'Defaulted'), (3, 'Repaid');

-- Add and update loan_type_id
alter table Loans_backup add loan_type_id int;
update Loans_backup set loan_type_id = 1 where loan_type = 'Agriculture';
update Loans_backup set loan_type_id = 2 where loan_type = 'Business';
update Loans_backup set loan_type_id = 3 where loan_type = 'Car';
update Loans_backup set loan_type_id = 4 where loan_type = 'Education';
update Loans_backup set loan_type_id = 5 where loan_type = 'Home';
update Loans_backup set loan_type_id = 6 where loan_type = 'Personal';

-- Drop old loan_type and rename
alter table Loans_backup drop column loan_type;
exec sp_rename 'Loans_backup.loan_type_id', 'loan_type', 'COLUMN';

-- Add foreign key for loan_type
alter table Loans_backup add constraint FK_Loans_Type foreign key (loan_type) references Loan_Type(type_id);

-- Add and update status
alter table Loans_backup add status_id int;
update Loans_backup set status_id = 1 where status = 'Active';
update Loans_backup set status_id = 2 where status = 'Defaulted';
update Loans_backup set status_id = 3 where status = 'Repaid';

-- Drop old status and rename
alter table Loans_backup drop column status;
exec sp_rename 'Loans_backup.status_id', 'status', 'COLUMN';

-- Add foreign key for status
alter table Loans_backup add constraint FK_Loans_Status foreign key (status) references Loan_Status(status_id);

-- Verify final structure
select COLUMN_NAME, DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'Loans_backup';
select CONSTRAINT_NAME, CONSTRAINT_TYPE from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where TABLE_NAME = 'Loans_backup';

-- Accounts_backup table FK fix-- 

select * from Accounts_backup;
-- Account_number must be unique 
ALTER TABLE Accounts_backup
ADD CONSTRAINT UQ_AccountsBackup_AccountNumber
UNIQUE (account_number); 

-- customer_id as foreign key 

ALTER TABLE Accounts_backup
ADD CONSTRAINT FK_AccountsBackup_Customers
FOREIGN KEY (customer_id)
REFERENCES Customers(customer_id);  

-- branch_id as foreign key  

ALTER TABLE Accounts_backup
ADD CONSTRAINT FK_AccountsBackup_BranchesBackup
FOREIGN KEY (branch_id)
REFERENCES Branches_backup(branch_id);


-- ATM_Transactions_backup 
EXEC sp_rename 'ATMTtransactions_backup', 'ATM_Transactions_backup';

select * from ATM_Transactions_backup; 

-- Add foreign key account_number from accounts_backup 

ALTER TABLE ATM_Transactions_backup
ALTER COLUMN account_number NVARCHAR(20) NOT NULL;


ALTER TABLE ATM_transactions_backup
ADD CONSTRAINT FK_ATMTransactionsBackup_AccountsBackup
FOREIGN KEY (account_number)
REFERENCES Accounts_backup(account_number);

EXEC sp_rename 'Transaction_Type', 'ATM_transaction_type';

DELETE FROM ATM_transaction_type
WHERE type_id IN (4, 5, 6, 7);

select * from ATM_Transaction_Type;

-- Bill Payments Backup -- 
select * from BillPayments_bakup 

ALTER TABLE BillPayments_bakup
ALTER COLUMN account_number NVARCHAR(20) NOT NULL; 

ALTER TABLE BillPayments_bakup
ADD CONSTRAINT FK_BillPaymentsbakup_AccountsBackup
FOREIGN KEY (account_number)
REFERENCES Accounts_backup(account_number); 

-- BranchPerformance_backup 
select * from BranchPerformance_backup;
select * from Month_Name;

ALTER TABLE BranchPerformance_backup
DROP COLUMN month;

-- creditcards_backup 
select * from CreditCards_backup;
select * from Card_Status; 
select * from Card_Type;

-- fk for customer_id 
ALTER TABLE CreditCards_backup
ADD CONSTRAINT FK_CreditCardsBackup_Customers
FOREIGN KEY (customer_id)
REFERENCES Customers(customer_id);

-- fk for account_id 
ALTER TABLE CreditCards_backup
ADD CONSTRAINT FK_CreditCardsBackup_AccountsBackup
FOREIGN KEY (account_id)
REFERENCES Accounts_backup(account_id);

-- kyc_backup -- 

select * from KYCDocuments;
select * from KYC_backup;

-- loans_backup --
select * from Loans_backup;
select * from Loan_Status;
select * from Loan_Type;

-- fk customer_id & account_id 

ALTER TABLE Loans_backup
ADD CONSTRAINT FK_LoansBackup_Customers
FOREIGN KEY (customer_id)
REFERENCES Customers(customer_id); 

ALTER TABLE Loans_backup
ADD CONSTRAINT FK_LoansBackup_AccountsBackup
FOREIGN KEY (account_id)
REFERENCES Accounts_backup(account_id);

-- support tickets -- 

select * from SupportTickets_backup;
select * from SupportTickets;

-- Transactions -- 

select * from Transactions_backup; 
select * from Transaction_Channel; 
select * from Transaction_Status; 
select * from TransactionTypes; 

-- add fk column -- 
ALTER TABLE transactions_backup ADD status_id INT ;

ALTER TABLE transactions_backup ADD channel_id INT ; 

UPDATE t
SET t.status_id = s.status_id
FROM transactions_backup t
JOIN transaction_status s
ON t.status = s.status_name; 

UPDATE t
SET t.channel_id = c.channel_id
FROM transactions_backup t
JOIN transaction_channel c
ON t.channel = c.channel_name;


-- Add fk -- 
ALTER TABLE transactions_backup
ADD CONSTRAINT FK_TransactionsBackup_Status
FOREIGN KEY (status_id)
REFERENCES transaction_status(status_id); 

ALTER TABLE transactions_backup
ADD CONSTRAINT FK_TransactionsBackup_Channel
FOREIGN KEY (channel_id)
REFERENCES transaction_channel(channel_id); 

-- Add primary key in TransactionTypes  
ALTER TABLE TransactionTypes
ALTER COLUMN type_id INT NOT NULL; 

ALTER TABLE TransactionTypes
ADD CONSTRAINT PK_TransactionTypes
PRIMARY KEY (type_id);

-- ADD FK 

ALTER TABLE transactions_backup
ADD CONSTRAINT FK_TransactionsBackup_Type
FOREIGN KEY (type_id)
REFERENCES transactionTypes(type_id);

-- Drop columns -- 
ALTER TABLE transactions_backup DROP COLUMN status;

ALTER TABLE transactions_backup DROP COLUMN channel;


select * from Transactions_backup;
select * from FraudAlerts;


-- ADD FK 

ALTER TABLE FraudAlerts
ADD CONSTRAINT FK_FraudAlerts_Transactions
FOREIGN KEY (transaction_id)
REFERENCES transactions_backup(transaction_id);

-- ADD FK to kyc_backup 
ALTER TABLE kyc_backup
ADD CONSTRAINT FK_kyc_backup_customers
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id); 

ALTER TABLE kyc_backup
ADD CONSTRAINT FK_kyc_backup_doc_type
FOREIGN KEY (doc_type_id)
REFERENCES kyc_doc_type(doc_type_id);

