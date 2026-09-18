--==============================================================
-- CUSTOMER SEGMENTATION
-- Segmentation Method:
-- Behavioral Pattern Matching
-- Primary Dimensions:
-- Frequency + Monetary Value
-- Supporting Metrics:
-- AOV + Total Quantity Purchased
--==============================================================


--==============================================================
-- 1. CUSTOMER-LEVEL METRICS
--==============================================================

WITH Sales_CTE AS
(
    SELECT
        c.CustomerID AS Customer_ID,
        SUM(o.SubTotal) AS Total_Sales,
        COUNT(o.SalesOrderID) AS Order_No
    FROM Sales.Customer c
    INNER JOIN Sales.SalesOrderHeader o
        ON c.CustomerID = o.CustomerID
    GROUP BY
        c.CustomerID
),

Quantity_CTE AS
(
    SELECT
        o.CustomerID AS Customer_ID,
        SUM(od.OrderQty) AS Total_QTY
    FROM Sales.SalesOrderHeader o
    INNER JOIN Sales.SalesOrderDetail od
        ON o.SalesOrderID = od.SalesOrderID
    GROUP BY
        o.CustomerID
),

Customer_Metrics AS
(
    SELECT
        s.Customer_ID,
        s.Total_Sales,
        s.Order_No,
        q.Total_QTY
    FROM Sales_CTE s
    INNER JOIN Quantity_CTE q
        ON s.Customer_ID = q.Customer_ID
),

Customer_Averages AS
(
    SELECT
        Customer_ID,
        Total_Sales,
        Order_No,
        Total_QTY,

        AVG(CAST(Total_Sales AS DECIMAL(10,2))) OVER() AS Avg_Total_Sales,

        AVG(CAST(Order_No AS DECIMAL(10,2))) OVER() AS Avg_Order_No

    FROM Customer_Metrics
),

Customer_Segments AS
(
    SELECT
        Customer_ID,
        Total_Sales,
        Order_No,
        Total_QTY,
        Avg_Total_Sales,
        Avg_Order_No,

        CASE
            WHEN Order_No > Avg_Order_No
             AND Total_Sales > Avg_Total_Sales
                THEN 'High-Value / Loyal'

            WHEN Order_No > Avg_Order_No
             AND Total_Sales < Avg_Total_Sales
                THEN 'Frequent Low-Value'

            WHEN Order_No < Avg_Order_No
             AND Total_Sales > Avg_Total_Sales
                THEN 'Occasional High-Spenders'

            ELSE 'Low-Value / Low-Frequency'
        END AS Segment

    FROM Customer_Averages
)


--==============================================================
-- 2. NUMBER OF CUSTOMERS IN EACH SEGMENT
--==============================================================

/*
SELECT
    Segment,
    COUNT(*) AS Customer_Count
FROM Customer_Segments
GROUP BY Segment
ORDER BY Customer_Count DESC;
*/


--==============================================================
-- 3. CUSTOMER SHARE BY SEGMENT
--==============================================================

/*
SELECT
    Segment,

    COUNT(*) AS Customer_Count,

    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()
        AS DECIMAL(10,2)
    ) AS Customer_Share_PCT

FROM Customer_Segments
GROUP BY Segment
ORDER BY Customer_Share_PCT DESC;
*/


--==============================================================
-- 4. REVENUE SHARE BY SEGMENT
--==============================================================

/*
SELECT
    Segment,

    SUM(Total_Sales) AS Segment_Sales,

    CAST(
        SUM(Total_Sales) * 100.0
        / SUM(SUM(Total_Sales)) OVER()
        AS DECIMAL(10,2)
    ) AS Revenue_Share_PCT

FROM Customer_Segments
GROUP BY Segment
ORDER BY Revenue_Share_PCT DESC;
*/


--==============================================================
-- 5. AVERAGE ORDER VALUE (AOV) BY SEGMENT
--==============================================================

/*
SELECT
    Segment,

    ROUND(
        SUM(Total_Sales) * 1.0
        / SUM(Order_No),
        2
    ) AS AOV

FROM Customer_Segments
GROUP BY Segment
ORDER BY AOV DESC;
*/


--==============================================================
-- 6. TOTAL QUANTITY PURCHASED BY SEGMENT
--==============================================================
/*
SELECT
    Segment,

    SUM(Total_QTY) AS Total_Quantity_Purchased

FROM Customer_Segments
GROUP BY Segment
ORDER BY Total_Quantity_Purchased DESC;*/
