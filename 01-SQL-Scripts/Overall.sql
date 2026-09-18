/* =========================================================
   ADVENTUREWORKS BUSINESS ANALYSIS
   Sections:
   1. Sales Performance
   2. Product Performance
   3. Customer Analytics
   ========================================================= */


/* =========================================================
   1. SALES PERFORMANCE
   ========================================================= */

/* ---------------------------------------------------------
   Q1. What are 
   total sales, 
   total orders, 
   total quantity sold, 
   and total customers for the period covered by the data?
   --------------------------------------------------------- */

/* ---------------------------------------------------------
   A. What are total sales for the period covered by the data?
   --------------------------------------------------------- */

SELECT
	SUM(SubTotal) AS Total_Sales
FROM Sales.SalesOrderHeader;


/* ---------------------------------------------------------
   B. What is the total number of orders?
   --------------------------------------------------------- */

SELECT
	Distinct count (SalesOrderID) AS Total_orders
FROM Sales.SalesOrderHeader;


/* ---------------------------------------------------------
   C. What is the total quantity sold?
   --------------------------------------------------------- */

SELECT
	SUM(OrderQty) AS total_quantity_sold
FROM Sales.SalesOrderDetail;


/* ---------------------------------------------------------
   D. How many unique customers made a purchase?
   --------------------------------------------------------- */

SELECT
	Distinct Count(CustomerID) AS total_customers
FROM Sales.Customer;


/* ---------------------------------------------------------
   Q2. How have sales changed over time?
   
   The analysis is performed at:
   - Year level
   - Month level
   --------------------------------------------------------- */


/* --- Sales by Year --- */

SELECT
	YEAR(OrderDate) AS YEAR_,
	SUM(SubTotal) AS TOTAL_SALES
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate);


/* --- Sales by Month --- */

SELECT
	YEAR(OrderDate) AS YEAR_,
	DATENAME(MONTH, OrderDate) AS MONTH_,
	SUM(SubTotal) AS TOTAL_SALES
FROM Sales.SalesOrderHeader
GROUP BY
	YEAR(OrderDate),
	MONTH(OrderDate),
	DATENAME(MONTH, OrderDate)
ORDER BY
	YEAR(OrderDate),
	MONTH(OrderDate),
	DATENAME(MONTH, OrderDate);


/* ---------------------------------------------------------
   Q3. What are the best and worst sales periods,
       and is there a plausible explanation?
   
   The analysis identifies:
   - Month with the highest sales
   - Month with the lowest sales
   --------------------------------------------------------- */


/* --- Best Sales Period --- */

WITH over_time_Max AS
(
	SELECT
		YEAR(OrderDate) AS YEAR_,
		DATENAME(MONTH, OrderDate) AS MONTH_,
		SUM(SubTotal) AS TOTAL_SALES
	FROM Sales.SalesOrderHeader
	GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate),
		DATENAME(MONTH, OrderDate)
)
SELECT
	YEAR_,
	MONTH_,
	TOTAL_SALES
FROM over_time_Max
WHERE TOTAL_SALES =
(
	SELECT
		MAX(TOTAL_SALES)
	FROM over_time_Max
);


/* --- Worst Sales Period --- */

WITH over_time_MIN AS
(
	SELECT
		YEAR(OrderDate) AS YEAR_,
		DATENAME(MONTH, OrderDate) AS MONTH_,
		SUM(SubTotal) AS TOTAL_SALES
	FROM Sales.SalesOrderHeader
	GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate),
		DATENAME(MONTH, OrderDate)
)
SELECT
	YEAR_,
	MONTH_,
	TOTAL_SALES
FROM over_time_MIN
WHERE TOTAL_SALES =
(
	SELECT
		MIN(TOTAL_SALES)
	FROM over_time_MIN
);


/* ---------------------------------------------------------
   Q4. What is the average order value,
       and how does it vary over time?
   
   AOV = Average Order Value
   --------------------------------------------------------- */


/* --- Overall AOV --- */

SELECT
	AVG(SubTotal) AS Average_Order_Value
FROM Sales.SalesOrderHeader;


/* --- Monthly AOV --- */

SELECT
	YEAR(OrderDate) AS YEAR_,
	DATENAME(MONTH, OrderDate) AS MONTH_,
	AVG(SubTotal) AS Average_Order_Value
FROM Sales.SalesOrderHeader
GROUP BY
	YEAR(OrderDate),
	MONTH(OrderDate),
	DATENAME(MONTH, OrderDate)
ORDER BY
	YEAR(OrderDate),
	MONTH(OrderDate),
	DATENAME(MONTH, OrderDate);


/* ---------------------------------------------------------
   Q5. Are sales growing or declining across
       the most recent complete periods?
   
   LAG() is used to compare each period with
   the previous period.
   
   CHANGE_ = Current Sales - Previous Sales
   
   Note:
   For a fair comparison, complete periods should be used.
   --------------------------------------------------------- */

SELECT
	YEAR_,
	MONTH_,
	Total_Sales,

	LAG(Total_Sales)
		OVER(ORDER BY YEAR_, MONTH_NO) AS PREV_MONTH_SALES,

	Total_Sales -
	LAG(Total_Sales)
		OVER(ORDER BY YEAR_, MONTH_NO) AS CHANGE_

FROM
(
	SELECT
		YEAR(OrderDate) AS YEAR_,
		MONTH(OrderDate) AS MONTH_NO,
		DATENAME(MONTH, OrderDate) AS MONTH_,
		SUM(SubTotal) AS Total_Sales
	FROM Sales.SalesOrderHeader
	GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate),
		DATENAME(MONTH, OrderDate)
) AS Month_sales

ORDER BY
	YEAR_,
	MONTH_NO;


/* ---------------------------------------------------------
   Q6. Which periods contribute most to total revenue?
   
   Each month is ranked according to its contribution
   to total revenue.
   --------------------------------------------------------- */

WITH TOP_MONTH_SALES AS
(
	SELECT
		YEAR(OrderDate) AS YEAR_,
		MONTH(OrderDate) AS MONTH_NO,
		DATENAME(MONTH, OrderDate) AS MONTH_,
		SUM(SubTotal) AS Total_Sales
	FROM Sales.SalesOrderHeader
	GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate),
		DATENAME(MONTH, OrderDate)
)

SELECT
	RANK() OVER(ORDER BY Total_Sales DESC) AS RANK_,
	YEAR_,
	MONTH_,
	Total_Sales,
	ROUND(
		Total_Sales * 100 /
		SUM(Total_Sales) OVER(),
		2
	) AS PctOfTotalRevenue

FROM TOP_MONTH_SALES

ORDER BY Total_Sales DESC;


/* ---------------------------------------------------------
   Q7. What percentage of total sales is generated
        by the top-performing periods?
   
   Cumulative sales and cumulative percentage are used
   to identify how quickly the highest-performing periods
   account for total revenue.
   --------------------------------------------------------- */

WITH Monthly_Sales AS
(
	SELECT
		YEAR(OrderDate) AS YEAR_,
		MONTH(OrderDate) AS MONTH_NO,
		DATENAME(MONTH, OrderDate) AS MONTH_,
		SUM(SubTotal) AS Total_Sales
	FROM Sales.SalesOrderHeader
	GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate),
		DATENAME(MONTH, OrderDate)
),

RANKED_SALES AS
(
	SELECT
		RANK() OVER(ORDER BY Total_Sales DESC) AS RANK_,
		YEAR_,
		MONTH_,
		Total_Sales,
		SUM(Total_Sales) OVER() AS Grand_total
	FROM Monthly_Sales
)

SELECT
	RANK_,
	YEAR_,
	MONTH_,
	Total_Sales,

	SUM(Total_Sales)
		OVER(
			ORDER BY RANK_
			ROWS UNBOUNDED PRECEDING
		) AS Cumultive_Sales,

	ROUND(
		SUM(Total_Sales)
			OVER(
				ORDER BY RANK_
				ROWS UNBOUNDED PRECEDING
			) * 100 / Grand_total,
		2
	) AS CumulativePct

FROM RANKED_SALES

ORDER BY RANK_;



/* =========================================================
   2. PRODUCT PERFORMANCE
   ========================================================= */


/* ---------------------------------------------------------
   Q8. Which products generate the highest sales revenue?
   --------------------------------------------------------- */

SELECT
	p.Name,
	SUM(LineTotal) AS Total_sales
FROM Production.Product p
INNER JOIN Sales.SalesOrderDetail od
	ON p.ProductID = od.ProductID
INNER JOIN Sales.SalesOrderHeader o
	ON od.SalesOrderID = o.SalesOrderID
GROUP BY p.Name
ORDER BY SUM(LineTotal) DESC;


/* ---------------------------------------------------------
   Q9. Which products generate the highest quantity sold?
   --------------------------------------------------------- */

SELECT
	p.Name,
	SUM(OrderQty) AS total_quantity_sold
FROM Production.Product p
INNER JOIN Sales.SalesOrderDetail od
	ON p.ProductID = od.ProductID
GROUP BY p.Name
ORDER BY SUM(OrderQty) DESC;


/* ---------------------------------------------------------
   Q10. Which products have high sales value but relatively
        low quantity?

   Sales per unit is used as an indicator of products
   generating relatively high revenue per unit sold.
   --------------------------------------------------------- */

WITH CTE AS
(
SELECT
	NAME AS NAME_,
	SUM(OrderQty) AS total_quantity_sold,
	SUM(LineTotal) AS Total_sales,
	SUM(LineTotal) / SUM(OrderQty) AS Sales_per_Unit
FROM Production.Product p
INNER JOIN Sales.SalesOrderDetail od
	ON p.ProductID = od.ProductID
INNER JOIN Sales.SalesOrderHeader o
	ON od.SalesOrderID = o.SalesOrderID
GROUP BY p.Name
),
CTE2 AS
(
SELECT 
	NAME_,
	total_quantity_sold,
	Total_sales,
	Sales_per_Unit,
	AVG(total_quantity_sold) OVER() AS AVG_total_quantity_sold,
	AVG(Total_sales) OVER() AS AVG_Total_sales
FROM CTE
)
SELECT
	NAME_,
	total_quantity_sold,
	Total_sales
FROM CTE2
WHERE total_quantity_sold < AVG_total_quantity_sold AND Total_sales > AVG_Total_sales


/* ---------------------------------------------------------
   Q11. Which products have high quantity but relatively
        low sales value?

   These products may indicate high-volume / low-value
   patterns and should be reviewed as possible
   low-margin risks.
   --------------------------------------------------------- */

WITH CTE AS
(
SELECT
	NAME AS NAME_,
	SUM(OrderQty) AS total_quantity_sold,
	SUM(LineTotal) AS Total_sales,
	SUM(LineTotal) / SUM(OrderQty) AS Sales_per_Unit
FROM Production.Product p
INNER JOIN Sales.SalesOrderDetail od
	ON p.ProductID = od.ProductID
INNER JOIN Sales.SalesOrderHeader o
	ON od.SalesOrderID = o.SalesOrderID
GROUP BY p.Name
),
CTE2 AS
(
SELECT 
	NAME_,
	total_quantity_sold,
	Total_sales,
	Sales_per_Unit,
	AVG(total_quantity_sold) OVER() AS AVG_total_quantity_sold,
	AVG(Total_sales) OVER() AS AVG_Total_sales
FROM CTE
)
SELECT
	NAME_,
	total_quantity_sold,
	Total_sales
FROM CTE2
WHERE total_quantity_sold > AVG_total_quantity_sold AND Total_sales < AVG_Total_sales


/* ---------------------------------------------------------
   Q12. Which products are underperforming relative
        to their category?

   Products are compared with the average sales
   of products within the same category.
   --------------------------------------------------------- */

WITH ProductSales AS
(
	SELECT
		c.Name AS Category_Name,
		p.Name AS Product_Name,
		SUM(LineTotal) AS Total_Sales
	FROM Production.ProductCategory c
	INNER JOIN Production.ProductSubcategory s
		ON c.ProductCategoryID = s.ProductCategoryID
	INNER JOIN Production.Product p
		ON s.ProductSubcategoryID = p.ProductSubcategoryID
	INNER JOIN Sales.SalesOrderDetail od
		ON p.ProductID = od.ProductID
	INNER JOIN Sales.SalesOrderHeader o
		ON od.SalesOrderID = o.SalesOrderID
	GROUP BY
		c.Name,
		p.Name
),

CategoryPerformance AS
(
	SELECT
		RANK() OVER(
			PARTITION BY Category_Name
			ORDER BY Total_Sales ASC
		) AS RANK_,

		Category_Name,
		Product_Name,
		Total_Sales,

		AVG(Total_Sales) OVER(
			PARTITION BY Category_Name
		) AS avg_Total_Sales_per_Category

	FROM ProductSales
)

SELECT
	RANK_,
	Category_Name,
	Product_Name,
	Total_Sales,
	avg_Total_Sales_per_Category
FROM CategoryPerformance
WHERE Total_Sales < avg_Total_Sales_per_Category
ORDER BY
	Category_Name,
	Total_Sales ASC;


/* ---------------------------------------------------------
   Q13. Which product categories generate the most revenue?
   --------------------------------------------------------- */

SELECT
	c.NAME AS Category_Name,
	SUM(LineTotal) AS Total_Sales
FROM Production.ProductCategory c
INNER JOIN Production.ProductSubcategory s
	ON c.ProductCategoryID = s.ProductCategoryID
INNER JOIN Production.Product p
	ON s.ProductSubcategoryID = p.ProductSubcategoryID
INNER JOIN Sales.SalesOrderDetail od
	ON p.ProductID = od.ProductID
INNER JOIN Sales.SalesOrderHeader o
	ON od.SalesOrderID = o.SalesOrderID
GROUP BY c.Name
ORDER BY SUM(LineTotal) DESC;


/* ---------------------------------------------------------
   Q14. Which subcategories contribute most to sales
        within their category?

   Subcategories are ranked separately within each category.
   --------------------------------------------------------- */

WITH Category_Sub AS
(
	SELECT
		C.Name AS Category_Name,
		s.Name AS SubCategory_Name,
		SUM(LineTotal) AS Total_Sales
	FROM Production.ProductCategory c
	INNER JOIN Production.ProductSubcategory s
		ON c.ProductCategoryID = s.ProductCategoryID
	INNER JOIN Production.Product p
		ON s.ProductSubcategoryID = p.ProductSubcategoryID
	INNER JOIN Sales.SalesOrderDetail od
		ON p.ProductID = od.ProductID
	INNER JOIN Sales.SalesOrderHeader o
		ON od.SalesOrderID = o.SalesOrderID
	GROUP BY
		c.Name,
		s.Name
)

SELECT
	RANK() OVER(
		PARTITION BY Category_Name
		ORDER BY Total_Sales DESC
	) AS RANK_,
	Category_Name,
	SubCategory_Name,
	Total_Sales
FROM Category_Sub;


/* ---------------------------------------------------------
   Q15. What percentage of total sales comes from
        each category?
   --------------------------------------------------------- */

WITH PRC AS
(
	SELECT
		c.NAME AS Category_Name,
		SUM(LineTotal) AS Category_Revenue
	FROM Production.ProductCategory c
	INNER JOIN Production.ProductSubcategory s
		ON c.ProductCategoryID = s.ProductCategoryID
	INNER JOIN Production.Product p
		ON s.ProductSubcategoryID = p.ProductSubcategoryID
	INNER JOIN Sales.SalesOrderDetail od
		ON p.ProductID = od.ProductID
	INNER JOIN Sales.SalesOrderHeader o
		ON od.SalesOrderID = o.SalesOrderID
	GROUP BY c.Name
)

SELECT
	Category_Name,
	Category_Revenue,
	ROUND(
		Category_Revenue * 100 /
		SUM(Category_Revenue) OVER(),
		2
	) AS PREC_SALES_FOR_EACH_CATEGORY
FROM PRC;


/* ---------------------------------------------------------
   Q16. Are a small number of products responsible for
        a disproportionate share of revenue?

   An 80/20-style Pareto analysis is used to compare:
   - Product ranking
   - Cumulative sales
   - Cumulative percentage of revenue
   - Percentage of products represented
   --------------------------------------------------------- */

WITH PRODUCT_PARETO AS
(
	SELECT
		p.Name AS Product_Name,
		SUM(LineTotal) AS Total_Sales
	FROM Production.Product p
	INNER JOIN Sales.SalesOrderDetail od
		ON p.ProductID = od.ProductID
	INNER JOIN Sales.SalesOrderHeader o
		ON od.SalesOrderID = o.SalesOrderID
	GROUP BY p.Name
),

RANK_Product AS
(
	SELECT
		ROW_NUMBER() OVER(ORDER BY Total_Sales DESC) AS RANK_,
		Product_Name,
		Total_Sales,
		SUM(Total_Sales) OVER() AS GRAND_TOTAL
	FROM PRODUCT_PARETO
)

SELECT
	RANK_,
	Product_Name,
	Total_Sales,

	SUM(Total_Sales)
		OVER(
			ORDER BY RANK_
			ROWS UNBOUNDED PRECEDING
		) AS Cumltive_SALES,

	ROUND(
		SUM(Total_Sales)
			OVER(
				ORDER BY RANK_
				ROWS UNBOUNDED PRECEDING
			) * 100 / GRAND_TOTAL,
		2
	) AS Cumlitive_PRCE,

	COUNT(*) OVER() AS Total_Products,

	ROUND(
    CAST(
        ROW_NUMBER() OVER (ORDER BY Total_Sales DESC) * 100.0
        / COUNT(*) OVER()
        AS DECIMAL(10,2)
    ),
    2
) AS Product_Percentage

FROM RANK_Product;


/* ---------------------------------------------------------
   Q17. Based on the evidence, which products should
        management prioritize — and which should be reviewed?

   Products are classified based on whether their total
   sales are above or below the overall product average.
   --------------------------------------------------------- */

WITH ProductPerformance AS
(
	SELECT
		NAME AS Product_Name,
		SUM(OrderQty) AS total_quantity_sold,
		SUM(LineTotal) AS Total_sales,
		SUM(LineTotal) / SUM(OrderQty) AS Sales_per_Unit
	FROM Production.Product p
	INNER JOIN Sales.SalesOrderDetail od
		ON p.ProductID = od.ProductID
	INNER JOIN Sales.SalesOrderHeader o
		ON od.SalesOrderID = o.SalesOrderID
	GROUP BY p.Name
),

ProductAnalysis AS
(
	SELECT
		Product_Name,
		total_quantity_sold,
		Total_sales,
		Sales_per_Unit,

		AVG(total_quantity_sold) OVER() AS AVG_Total_Quantity,
		AVG(Total_sales) OVER() AS AVG_Total_Sales

	FROM ProductPerformance
)

SELECT
	Product_Name,
	total_quantity_sold,
	Total_sales,
	Sales_per_Unit,
	AVG_Total_Quantity,
	AVG_Total_Sales,

	CASE
		WHEN Total_sales > AVG_Total_Sales
			THEN 'Prioritize'

		WHEN Total_sales < AVG_Total_Sales
			THEN 'Review'
	END AS Management_Action

FROM ProductAnalysis;


/* =========================================================
   3. CUSTOMER ANALYTICS
   ========================================================= */


/* ---------------------------------------------------------
   Q18. How many unique customers made at least one purchase?
   --------------------------------------------------------- */

SELECT
	COUNT(DISTINCT c.CustomerID) AS CustomerNO
FROM Sales.Customer c
RIGHT JOIN Sales.SalesOrderHeader o
	ON c.CustomerID = o.CustomerID;


/* ---------------------------------------------------------
   Q19. Who are the highest-value customers by total revenue?
   
   The top 10 customers are identified based on
   total revenue generated.
   --------------------------------------------------------- */

SELECT TOP 10
	c.CustomerID,
	SUM(SubTotal) AS Total_Sales
FROM Sales.Customer c
INNER JOIN Sales.SalesOrderHeader o
	ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID
ORDER BY SUM(SubTotal) DESC;


/* ---------------------------------------------------------
   Q20. What is average customer spending,
        and how much does it vary?
   
   Customer-level total spending is calculated first.
   Then the average, minimum, and maximum customer
   spending are calculated across all customers.
   --------------------------------------------------------- */

WITH Total_sales AS
(
	SELECT
		C.CustomerID AS Customer_ID,
		SUM(SubTotal) AS Total_Sales
	FROM Sales.Customer c
	INNER JOIN Sales.SalesOrderHeader o
		ON c.CustomerID = o.CustomerID
	GROUP BY c.CustomerID
),
CTE AS
(
SELECT
	AVG(Total_sales) OVER() AS Avg_total_sales,
	MIN(Total_sales) OVER() AS MIN_total_sales,
	MAX(Total_sales) OVER() AS MAX_total_sales
FROM Total_sales
)
SELECT TOP 1
	Avg_total_sales,
	MIN_total_sales,
	MAX_total_sales
FROM CTE;

/* ---------------------------------------------------------
   Q21. How frequently do customers purchase
        (orders per customer)?
   --------------------------------------------------------- */

WITH Orders AS
(
	SELECT
		c.CustomerID AS Customer_ID,
		COUNT(o.SalesOrderID) AS Order_NO
	FROM Sales.Customer c
	INNER JOIN Sales.SalesOrderHeader o
		ON c.CustomerID = o.CustomerID
	GROUP BY c.CustomerID
)

SELECT
	AVG(CAST(Order_NO AS DECIMAL(10,2))) AS orders_per_customer
FROM Orders;


/* ---------------------------------------------------------
   Q22. Which customers generate the largest number of orders?
   --------------------------------------------------------- */

SELECT TOP 10
	c.CustomerID,
	COUNT(o.SalesOrderID) AS OrderNO
FROM Sales.Customer c
INNER JOIN Sales.SalesOrderHeader o
	ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID
ORDER BY COUNT(o.SalesOrderID) DESC;


/* ---------------------------------------------------------
   Q23. Which customers generate the highest revenue,
        and do the two rankings (frequency vs. revenue) agree?
   
   Each customer receives two rankings:
   - Ranking by number of orders
   - Ranking by total revenue
   --------------------------------------------------------- */

WITH TOTALS AS
(
	SELECT
		c.CustomerID AS Customer_id,
		SUM(SubTotal) AS Total_Sales,
		COUNT(o.SalesOrderID) AS OrderNO
	FROM Sales.Customer c
	INNER JOIN Sales.SalesOrderHeader o
		ON c.CustomerID = o.CustomerID
	GROUP BY c.CustomerID
)

SELECT TOP 20
	Customer_id,

	RANK() OVER(
		ORDER BY OrderNO DESC
	) AS RANK_Orders,

	OrderNO,

	RANK() OVER(
		ORDER BY Total_sales DESC
	) AS RANK_Renenue,

	Total_Sales

FROM TOTALS;


/* ---------------------------------------------------------
   Q24. What proportion of revenue comes from the
        top 10% / top 20% of customers?
   
   Customers are ranked by total revenue and divided into:
   - Top 10%
   - Top 20%
   - Remaining customers
   --------------------------------------------------------- */

WITH TOP_ AS
(
	SELECT
		RANK() OVER(
			ORDER BY SUM(SubTotal) DESC
		) AS RANK_,

		c.CustomerID AS Customer_ID,
		SUM(SubTotal) AS Total_Sales

	FROM Sales.Customer c
	INNER JOIN Sales.SalesOrderHeader o
		ON c.CustomerID = o.CustomerID

	GROUP BY c.CustomerID
),

TOP_2 AS
(
	SELECT
		RANK_,
		Customer_ID,
		Total_Sales,

		CASE
			WHEN RANK_ <= COUNT(*) OVER() * 0.1
				THEN 'TOP 10 %'

			WHEN RANK_ <= COUNT(*) OVER() * 0.2
				THEN 'TOP 20 %'

			ELSE 'NEITHER'
		END AS TOPS

	FROM TOP_
)

SELECT
	ROUND(
		SUM(
			CASE
				WHEN TOPS = 'TOP 10 %'
				THEN Total_Sales
			END
		) * 100 / SUM(Total_Sales),
		2
	) AS Top_10_Percentage,

	ROUND(
		SUM(
			CASE
				WHEN TOPS IN ('TOP 10 %', 'TOP 20 %')
				THEN Total_Sales
			END
		) * 100 / SUM(Total_Sales),
		2
	) AS Top_20_Percentage

FROM TOP_2;


/* ---------------------------------------------------------
   Q25. Are there customers with many purchases
        but relatively low total spending?
   
   Customers are compared against the overall averages for:
   - Total sales
   - Number of orders
   
   Target segment:
   Above-average orders + below-average spending
   --------------------------------------------------------- */

WITH CTE AS
(
	SELECT
		c.CustomerID AS Customer_ID,
		SUM(SubTotal) AS Total_Sales,
		COUNT(o.SalesOrderID) AS ORDER_NO
	FROM Sales.Customer c
	INNER JOIN Sales.SalesOrderHeader o
		ON c.CustomerID = o.CustomerID
	GROUP BY c.CustomerID
),

CTE2 AS
(
	SELECT
		Customer_ID,
		Total_Sales,
		ORDER_NO,

		AVG(
			CAST(Total_Sales AS DECIMAL(10,2))
		) OVER() AS AVG_Total_Sales,

		AVG(
			CAST(ORDER_NO AS DECIMAL(10,2))
		) OVER() AS AVG_Order_NO

	FROM CTE
)

SELECT TOP 20
	Customer_ID,
	Total_Sales,
	ORDER_NO,
	AVG_Total_Sales,
	AVG_Order_NO

FROM CTE2

WHERE
	ORDER_NO > AVG_Order_NO
	AND Total_Sales < AVG_Total_Sales

ORDER BY ORDER_NO DESC;


/* ---------------------------------------------------------
   Q26. Are there customers with few purchases
        but very high total spending?
   
   Target segment:
   Below-average orders + above-average spending
   
   This identifies customers who generate relatively high
   revenue despite purchasing infrequently.
   --------------------------------------------------------- */

WITH CTE AS
(
	SELECT
		c.CustomerID AS Customer_ID,
		SUM(SubTotal) AS Total_Sales,
		COUNT(o.SalesOrderID) AS ORDER_NO
	FROM Sales.Customer c
	INNER JOIN Sales.SalesOrderHeader o
		ON c.CustomerID = o.CustomerID
	GROUP BY c.CustomerID
),

CTE2 AS
(
	SELECT
		Customer_ID,
		Total_Sales,
		ORDER_NO,

		AVG(
			CAST(Total_Sales AS DECIMAL(10,2))
		) OVER() AS AVG_Total_Sales,

		AVG(
			CAST(ORDER_NO AS DECIMAL(10,2))
		) OVER() AS AVG_Order_NO

	FROM CTE
)

SELECT
	Customer_ID,
	Total_Sales,
	ORDER_NO,
	AVG_Total_Sales,
	AVG_Order_NO

FROM CTE2

WHERE
	ORDER_NO < AVG_Order_NO
	AND Total_Sales > AVG_Total_Sales

ORDER BY Total_Sales DESC;


/* ---------------------------------------------------------
   Q27. Based on the evidence, which customers should
        be treated as high-value — and by what definition?
   
   High-value customer definition:
   
   Primary definition:
   Customers in the top 10% by total revenue.
   
   Secondary / specific segment:
   Customers with below-average order frequency but
   above-average total spending.
   
   The first definition captures the main revenue-driving
   customer segment, while the second highlights customers
   who generate high spending despite relatively few purchases.
   --------------------------------------------------------- */


/* 
   High-value customers are customers who generate
   significantly higher-than-average revenue, with particular
   emphasis on the top 10% of customers.

   Two levels are used:

   1. Primary definition:
      Top 10% of customers by revenue.

      This segment represents the main concentration
      of customer-generated revenue.

   2. Specific high-value segment:
      Below-average number of orders +
      above-average total spending.

      This identifies customers who generate high revenue
      despite relatively low purchase frequency.
*/

