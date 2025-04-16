use Productbased_company

-- Regions table
CREATE TABLE Regions (
    RegionID INTEGER PRIMARY KEY,
    RegionName VARCHAR(100),
    Country VARCHAR(100)
);

-- Customers table
CREATE TABLE Customers (
    CustomerID INTEGER PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    RegionID INTEGER,
    FOREIGN KEY (RegionID) REFERENCES Regions(RegionID)
);

-- Products table
CREATE TABLE Products (
    ProductID INTEGER PRIMARY KEY,
    ProductName VARCHAR(100),
    Category VARCHAR(50)
);

-- Sales table
CREATE TABLE Sales (
    SaleID INTEGER PRIMARY KEY,
    ProductID INTEGER,
    CustomerID INTEGER,
    SaleDate DATE,
    Quantity INTEGER,
    TotalAmount DECIMAL(10,2),
    EmployeeID INTEGER,  -- Optional: for linking to a sales representative
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Employees table (optional)
CREATE TABLE Employees (
    EmployeeID INTEGER PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50)
);

-- ===========================
-- Insert Sample Data
-- ===========================

-- Regions Data
INSERT INTO Regions (RegionID, RegionName, Country) VALUES 
    (1, 'West Coast', 'USA'),
    (2, 'East Coast', 'USA'),
    (3, 'Europe', 'UK');

-- Customers Data
INSERT INTO Customers (CustomerID, FirstName, LastName, Email, RegionID) VALUES 
    (101, 'John', 'Doe', 'john.doe@example.com', 1),
    (102, 'Jane', 'Smith', 'jane.smith@example.com', 2),
    (103, 'Alice', 'Johnson', 'alice.johnson@example.com', 1),
    (104, 'Bob', 'Brown', 'bob.brown@example.com', 3);

-- Products Data
INSERT INTO Products (ProductID, ProductName, Category) VALUES 
    (201, 'Laptop', 'Electronics'),
    (202, 'Headphones', 'Electronics'),
    (203, 'Coffee Maker', 'Home Appliances'),
    (204, 'Desk Chair', 'Furniture');

-- Sales Data
INSERT INTO Sales (SaleID, ProductID, CustomerID, SaleDate, Quantity, TotalAmount, EmployeeID) VALUES
    (301, 201, 101, '2025-01-15', 1, 1200.00, 401),
    (302, 202, 102, '2025-02-10', 2, 300.00, 401),
    (303, 203, 103, '2025-04-05', 1, 100.00, 402),
    (304, 204, 104, '2025-05-12', 3, 450.00, 402),
    (305, 201, 101, '2025-04-20', 1, 1150.00, 402),
    (306, 203, 102, '2025-07-15', 1, 80.00, 402);

-- Employees Data
INSERT INTO Employees (EmployeeID, FirstName, LastName) VALUES 
    (401, 'David', 'White'),
    (402, 'Sara', 'Black');


--Task 1 : Calculate the total sales amount per region for each quarter of the current year.

With Core_cols as
(
Select 
r.regionname,
TotalAmount,
Year(saledate) as Year,
case 
	when month(saledate) < 3 then 'Q1'
	when month(saledate) between 4 and 6 then 'Q2'
	when month(saledate) between 7 and 9 then 'Q3'
    else 'Q4'
End  as Quarter
from products p join sales s
on p.productid = s.productid
join Customers c 
on c.customerid = s.CustomerID
join regions r
on c.RegionID = r.RegionID
),
Aggregated_cols as
(
select
regionname,
Year,
quarter ,
Sum(Totalamount) as Total_Amount
from Core_cols
group by 
regionname,
Year,
quarter
)
-- Task 2: Within each quarter, rank regions based on the aggregated sales amount computed in Task 1,showing which regions performed best
select 
regionname,
Year,
quarter ,
Total_Amount,
Rank() over(partition by quarter order by Total_amount desc) as Rank
from Aggregated_cols

--Task 3:Determine the top 5 products based on total sales amount for the region with the highest sales in Q2 (April to June, 2025).

With core_cols as
(
select 
p.ProductID, 
p.ProductName,
Regionname,
Totalamount,
case 
	when month(saledate) < 4 then 'Q1'
	when month(saledate) between 4 and 6 then 'Q2'
	when month(saledate) between 7 and 9 then 'Q3'
    else 'Q4'
End Quarters
from products p join sales s
on p.ProductID = s.ProductID
join Customers c
on c.CustomerID = s.CustomerID
join Regions r 
on c.RegionID = r.RegionID
),
Aggregate_cols as
(
select
ProductID, 
ProductName,
Regionname,
sum(Totalamount) as Total_amount,
Quarters
from core_cols
group by 
ProductID, 
ProductName,
Regionname,
Quarters
)
select * from
(select ProductID, 
ProductName,
Regionname,
Total_amount,
Quarters,
Rank() over(partition by Quarters order by Total_amount desc) rnk
from Aggregate_cols
where quarters ='Q2') x
where x.rnk <= 5

--Task 4: Month-over-Month Sales Growth Analysis

WITH MonthlySales AS (
    SELECT 
        FORMAT(s.SaleDate, 'yyyy-MM') AS YearMonth,
        SUM(s.TotalAmount) AS MonthlyTotal,
        r.RegionName
    FROM sales s
    JOIN customers c ON s.CustomerID = c.CustomerID
    JOIN regions r ON c.RegionID = r.RegionID
    WHERE r.RegionName = 'West Coast'
    GROUP BY FORMAT(s.SaleDate, 'yyyy-MM'), r.RegionName
),
SortedSales AS (
    SELECT 
        YearMonth,
        MonthlyTotal,
        LAG(MonthlyTotal) OVER (ORDER BY YearMonth) AS PrevMonthTotal
    FROM MonthlySales
),
RecentSixMonths AS (
    SELECT TOP 6 *
    FROM SortedSales
    ORDER BY YearMonth DESC
)
SELECT 
    YearMonth,
    MonthlyTotal,
    PrevMonthTotal,
    CASE 
        WHEN PrevMonthTotal = 0 THEN NULL
        ELSE ROUND(((MonthlyTotal - PrevMonthTotal) * 100.0) / PrevMonthTotal, 2)
    END AS MoM_Growth_Percent
FROM RecentSixMonths
ORDER BY YearMonth;
























