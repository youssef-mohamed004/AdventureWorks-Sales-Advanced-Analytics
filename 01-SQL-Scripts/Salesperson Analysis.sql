-- =========================================================
-- SALES PERSON / SALES REPRESENTATIVE ANALYSIS
-- =========================================================
-- Purpose:
-- Evaluate salesperson performance using multiple KPIs,
-- including total sales, order volume, AOV, performance
-- versus the overall salesperson average, customer
-- concentration risk, and year-over-year growth.
--
-- Important:
-- Salespeople are not evaluated based on total sales alone.
-- Performance is normalized using order volume, AOV,
-- growth rate, and customer concentration.
-- =========================================================


/* =========================================================
   1. TOTAL SALES BY SALESPERSON
   ---------------------------------------------------------
   Business Question:
   Which salespeople generate the highest total sales?

   Purpose:
   Identify the largest revenue contributors within
   the sales team.

   KPI:
   Total Sales = SUM(SubTotal)
   ========================================================= */

SELECT
    p.BusinessEntityID AS SalesPerson_ID,
    ROUND(SUM(o.SubTotal), 2) AS Total_Sales
FROM Sales.SalesPerson p
INNER JOIN Sales.SalesOrderHeader o
    ON p.BusinessEntityID = o.SalesPersonID
GROUP BY p.BusinessEntityID
ORDER BY SUM(o.SubTotal) DESC;


/* =========================================================
   2. ORDER VOLUME BY SALESPERSON
   ---------------------------------------------------------
   Business Question:
   Which salespeople generate the highest number of orders?

   Purpose:
   Measure salesperson activity and order volume.

   KPI:
   Order Volume = COUNT(DISTINCT SalesOrderID)
   ========================================================= */

SELECT
    p.BusinessEntityID AS SalesPerson_ID,
    COUNT(DISTINCT o.SalesOrderID) AS ORDER_NO
FROM Sales.SalesPerson p
INNER JOIN Sales.SalesOrderHeader o
    ON p.BusinessEntityID = o.SalesPersonID
GROUP BY p.BusinessEntityID
ORDER BY COUNT(DISTINCT o.SalesOrderID) DESC;


/* =========================================================
   3. AVERAGE ORDER VALUE BY SALESPERSON
   ---------------------------------------------------------
   Business Question:
   Which salespeople have the highest Average Order Value?

   Purpose:
   Measure the average revenue generated per order.

   KPI:
   AOV = AVG(SubTotal)

   Note:
   AOV helps distinguish between volume-driven performance
   and value-driven performance.
   ========================================================= */

SELECT
    p.BusinessEntityID AS SalesPerson_ID,
    ROUND(AVG(o.SubTotal), 2) AS AOV
FROM Sales.SalesPerson p
INNER JOIN Sales.SalesOrderHeader o
    ON p.BusinessEntityID = o.SalesPersonID
GROUP BY p.BusinessEntityID
ORDER BY AVG(o.SubTotal) DESC;


/* =========================================================
   4. PERFORMANCE VS. OVERALL SALESPERSON AVERAGE
   ---------------------------------------------------------
   Business Question:
   How does each salesperson's performance compare
   with the overall salesperson average?

   Purpose:
   Evaluate salespeople using multiple KPIs rather than
   ranking them on raw sales alone.

   KPIs:
   - Total Sales
   - AOV
   - Order Volume

   Method:
   Each salesperson is compared against the average
   performance across all salespeople.

   Performance categories:
   - Strong Performance
   - High-Value Performance
   - High-Volume Performance
   - High Activity - Low Sales
   - High Total Sales
   - High-Value Efficiency
   - High-Volume Low-Value
   - Below Average
   ========================================================= */

WITH Salesperson_Performance AS
(
    SELECT
        p.BusinessEntityID AS SalesPerson_ID,
        ROUND(SUM(o.SubTotal), 2) AS Total_Sales,
        ROUND(AVG(o.SubTotal), 2) AS AOV,
        COUNT(DISTINCT o.SalesOrderID) AS ORDER_NO
    FROM Sales.SalesPerson p
    INNER JOIN Sales.SalesOrderHeader o
        ON p.BusinessEntityID = o.SalesPersonID
    GROUP BY p.BusinessEntityID
),

Salesperson_Averages AS 
(
    SELECT
        SalesPerson_ID,
        Total_Sales,
        AOV,
        ORDER_NO,
        ROUND(AVG(Total_Sales) OVER(), 2) AS AVG_Total_Sales,
        ROUND(AVG(AOV) OVER(), 2) AS AVG_AOV,
        ROUND(AVG(ORDER_NO) OVER(), 2) AS AVG_ORDER_NO
    FROM Salesperson_Performance
),

Salesperson_Status AS
(
    SELECT
        SalesPerson_ID,
        Total_Sales,
        AOV,
        ORDER_NO,
        AVG_Total_Sales,
        AVG_AOV,
        AVG_ORDER_NO,

        CASE

            -- Total Sales ↑ | AOV ↑ | Orders ↑
            WHEN Total_Sales > AVG_Total_Sales
             AND AOV > AVG_AOV
             AND ORDER_NO > AVG_ORDER_NO
            THEN 'Strong Performance'

            -- Total Sales ↑ | AOV ↑ | Orders ↓
            WHEN Total_Sales > AVG_Total_Sales
             AND AOV > AVG_AOV
             AND ORDER_NO < AVG_ORDER_NO
            THEN 'High-Value Performance'

            -- Total Sales ↑ | AOV ↓ | Orders ↑
            WHEN Total_Sales > AVG_Total_Sales
             AND AOV < AVG_AOV
             AND ORDER_NO > AVG_ORDER_NO
            THEN 'High-Volume Performance'

            -- Total Sales ↓ | AOV ↑ | Orders ↑
            WHEN Total_Sales < AVG_Total_Sales
             AND AOV > AVG_AOV
             AND ORDER_NO > AVG_ORDER_NO
            THEN 'High Activity - Low Sales'

            -- Total Sales ↑ | AOV ↓ | Orders ↓
            WHEN Total_Sales > AVG_Total_Sales
             AND AOV < AVG_AOV
             AND ORDER_NO < AVG_ORDER_NO
            THEN 'High Total Sales'

            -- Total Sales ↓ | AOV ↑ | Orders ↓
            WHEN Total_Sales < AVG_Total_Sales
             AND AOV > AVG_AOV
             AND ORDER_NO < AVG_ORDER_NO
            THEN 'High-Value Efficiency'

            -- Total Sales ↓ | AOV ↓ | Orders ↑
            WHEN Total_Sales < AVG_Total_Sales
             AND AOV < AVG_AOV
             AND ORDER_NO > AVG_ORDER_NO
            THEN 'High-Volume Low-Value'

            -- Total Sales ↓ | AOV ↓ | Orders ↓
            WHEN Total_Sales < AVG_Total_Sales
             AND AOV < AVG_AOV
             AND ORDER_NO < AVG_ORDER_NO
            THEN 'Below Average'

        END AS Status_

    FROM Salesperson_Averages
)

SELECT
    SalesPerson_ID,
    Total_Sales,
    AOV,
    ORDER_NO,
    AVG_Total_Sales,
    AVG_AOV,
    AVG_ORDER_NO,
    Status_

    /*
    ---------------------------------------------------------
    Optional Summary:
    Count the number of salespeople in each performance
    category.
    ---------------------------------------------------------

    COUNT(CASE WHEN Status_ = 'Strong Performance'
               THEN 1 END) AS Strong_Performance_Count,

    COUNT(CASE WHEN Status_ = 'High-Value Performance'
               THEN 1 END) AS High_Value_Performance_Count,

    COUNT(CASE WHEN Status_ = 'High-Volume Performance'
               THEN 1 END) AS High_Volume_Performance_Count,

    COUNT(CASE WHEN Status_ = 'High Activity - Low Sales'
               THEN 1 END) AS High_Activity_Low_Sales_Count,

    COUNT(CASE WHEN Status_ = 'High Total Sales'
               THEN 1 END) AS High_Total_Sales_Count,

    COUNT(CASE WHEN Status_ = 'High-Value Efficiency'
               THEN 1 END) AS High_Value_Efficiency_Count,

    COUNT(CASE WHEN Status_ = 'High-Volume Low-Value'
               THEN 1 END) AS High_Volume_Low_Value_Count,

    COUNT(CASE WHEN Status_ = 'Below Average'
               THEN 1 END) AS Below_Average_Count
    */

FROM Salesperson_Status;


/* =========================================================
   5. CUSTOMER CONCENTRATION RISK
   ---------------------------------------------------------
   Business Question:
   Are any salespeople highly dependent on a small
   number of customers?

   Purpose:
   Identify revenue concentration risk at the
   salesperson level.

   Method:
   1. Calculate total sales for each salesperson/customer.
   2. Rank customers within each salesperson.
   3. Calculate each salesperson's total revenue.
   4. Calculate the percentage of revenue generated by
      each customer.

   Key KPI:
   Customer Sales Percentage =
   Customer Sales / Salesperson Total Sales

   Interpretation:
   A high percentage indicates greater dependency on
   a small number of customers.
   ========================================================= */

WITH Salesperson_Customer_Sales AS
(
    SELECT
        p.BusinessEntityID AS SalesPerson_ID,
        c.CustomerID AS CustomerID,
        ROUND(SUM(o.SubTotal), 2) AS Total_Sales
    FROM Sales.SalesPerson p
    INNER JOIN Sales.SalesOrderHeader o
        ON p.BusinessEntityID = o.SalesPersonID
    INNER JOIN Sales.Customer c
        ON o.CustomerID = c.CustomerID
    GROUP BY
        p.BusinessEntityID,
        c.CustomerID
),

Customer_Concentration AS
(
    SELECT
        RANK() OVER(
            PARTITION BY SalesPerson_ID
            ORDER BY Total_Sales DESC
        ) AS RANK_,

        SalesPerson_ID,
        CustomerID,
        Total_Sales,

        SUM(Total_Sales) OVER(
            PARTITION BY SalesPerson_ID
        ) AS GRAND_TOTAL,

        COUNT(CustomerID) OVER(
            PARTITION BY SalesPerson_ID
        ) AS [NO. OF CUSTOMER PER SALESPERSON]

    FROM Salesperson_Customer_Sales
)

SELECT
    RANK_,
    SalesPerson_ID,
    CustomerID,
    [NO. OF CUSTOMER PER SALESPERSON],
    Total_Sales,
    GRAND_TOTAL,
    ROUND(
        Total_Sales * 100 / GRAND_TOTAL,
        3
    ) AS Customer_Sales_Percentage

FROM Customer_Concentration;


/* =========================================================
   6. DATA PERIOD VALIDATION
   ---------------------------------------------------------
   Purpose:
   Identify the first and last available order dates
   before performing year-over-year growth analysis.

   This check is important because partial years should
   not be treated as complete years when comparing growth.
   ========================================================= */

SELECT
    MIN(OrderDate) AS FIRST_DATE,
    MAX(OrderDate) AS LAST_DATE
FROM Sales.SalesOrderHeader;


/* =========================================================
   7. MONTH COVERAGE BY YEAR
   ---------------------------------------------------------
   Purpose:
   Determine how many months of data are available
   in each year.

   This allows us to identify complete and partial years
   before calculating annual salesperson growth.

   Expected interpretation:
   - Partial years should not be directly compared
     with complete years.
   ========================================================= */

WITH CTE AS
(
    SELECT
        YEAR(OrderDate) AS YEAR_,
        MONTH(OrderDate) AS M_NAME
    FROM Sales.SalesOrderHeader
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate)
)

SELECT
    YEAR_,
    COUNT(M_NAME) AS NO_MONTH_PER_YEAR
FROM CTE
GROUP BY YEAR_;


/* =========================================================
   8. ANNUAL SALESPERSON GROWTH
   ---------------------------------------------------------
   Business Question:
   Which salespeople show the strongest performance trend
   over time rather than simply having the highest total sales?

   Comparison Period:
   2023 vs. 2024

   Why 2023 vs. 2024?
   - 2022 contains only partial-year data.
   - 2023 is a complete year.
   - 2024 is a complete year.
   - 2025 contains only partial-year data.

   Method:
   1. Calculate annual sales for each salesperson.
   2. Use LAG() to retrieve the previous year's sales.
   3. Calculate the absolute change in sales.
   4. Calculate the year-over-year growth rate.

   Growth Rate:
   (Current Year Sales - Previous Year Sales)
   / Previous Year Sales × 100

   Important:
   Only salespeople with sales in both 2023 and 2024
   should be used for a direct full-year comparison.
   ========================================================= */

SELECT
    YEAR_,
    SalesPerson_ID,
    Total_Sales,

    LAG(Total_Sales)
        OVER(
            PARTITION BY SalesPerson_ID
            ORDER BY YEAR_
        ) AS PREV_YEAR_SALES,

    Total_Sales
        - LAG(Total_Sales)
            OVER(
                PARTITION BY SalesPerson_ID
                ORDER BY YEAR_
            ) AS CHANGE_,

    ROUND
    (
        (
            Total_Sales
            - LAG(Total_Sales)
                OVER(
                    PARTITION BY SalesPerson_ID
                    ORDER BY YEAR_
                )
        ) * 100
        /
        LAG(Total_Sales)
            OVER(
                PARTITION BY SalesPerson_ID
                ORDER BY YEAR_
            ),
        2
    ) AS Growth_Rate

FROM
(
    SELECT
        YEAR(o.OrderDate) AS YEAR_,
        p.BusinessEntityID AS SalesPerson_ID,
        ROUND(SUM(o.SubTotal), 2) AS Total_Sales

    FROM Sales.SalesPerson p

    INNER JOIN Sales.SalesOrderHeader o
        ON p.BusinessEntityID = o.SalesPersonID

    WHERE YEAR(o.OrderDate) IN (2023, 2024)

    GROUP BY
        YEAR(o.OrderDate),
        p.BusinessEntityID

) AS YEAR_SALES

ORDER BY
    YEAR_,
    SalesPerson_ID;
