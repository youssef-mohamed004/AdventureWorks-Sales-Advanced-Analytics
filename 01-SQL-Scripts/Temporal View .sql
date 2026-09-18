/* =========================================================
   TEMPORAL VIEW

   ANALYSIS SCOPE:
   The temporal analysis focuses on 2023 and 2024 because
   they are the only complete years available in the dataset.

   2022 and 2025 are partial years:
   - 2022 starts from May 30
   - 2025 ends on June 29

   Therefore, 2023 and 2024 are used for comparable
   temporal analysis such as YoY, MoM, seasonal patterns,
   cumulative sales, and rolling trends.
   ========================================================= */


/* =========================================================
   1 - YEARLY SALES

   Note:
   2022 and 2025 are partial years and should not be
   directly compared with the complete years 2023 and 2024.
   ========================================================= */

SELECT
	YEAR(OrderDate) AS YEAR_,
	SUM(SubTotal) AS Total_Sales
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate);


/* =========================================================
   2 - QUARTERLY SALES

   Note:
   Quarterly results include all available periods.
   Comparisons involving partial years should be interpreted
   with caution.
   ========================================================= */

SELECT
	YEAR(OrderDate) AS YEAR_,
	DATEPART(QUARTER, OrderDate) AS QUARTER_,
	SUM(SubTotal) AS Total_Sales
FROM Sales.SalesOrderHeader
GROUP BY
	YEAR(OrderDate),
	DATEPART(QUARTER, OrderDate)
ORDER BY
	YEAR(OrderDate),
	DATEPART(QUARTER, OrderDate);


/* =========================================================
   3 - MONTHLY SALES

   Note:
   Monthly sales are shown for the full available period.
   2023 and 2024 are used as the complete-year basis for
   comparable temporal analysis.
   ========================================================= */

SELECT
	YEAR(OrderDate) AS YEAR_,
	DATENAME(MONTH, OrderDate) AS MONTH_NAME,
	SUM(SubTotal) AS Total_Sales
FROM Sales.SalesOrderHeader
GROUP BY
	YEAR(OrderDate),
	MONTH(OrderDate),
	DATENAME(MONTH, OrderDate)
ORDER BY
	YEAR(OrderDate),
	MONTH(OrderDate),
	DATENAME(MONTH, OrderDate);


/* =========================================================
   4 - YEAR-OVER-YEAR (YoY) GROWTH

   Analysis Period:
   2023-2024

   Only complete years are used so that each 2024 month
   can be compared with the corresponding 2023 month.
   ========================================================= */

SELECT
	YEAR_,
	MONTH_NAME,
	Total_Sales,

	LAG(Total_Sales, 12) OVER(
		ORDER BY YEAR_, MONTH_
	) AS PREV_YEAR_SALES,

	Total_Sales -
	LAG(Total_Sales, 12) OVER(
		ORDER BY YEAR_, MONTH_
	) AS CHANGE_,

	ROUND
	(
		(
			Total_Sales -
			LAG(Total_Sales, 12) OVER(
				ORDER BY YEAR_, MONTH_
			)
		) * 100
		/
		LAG(Total_Sales, 12) OVER(
			ORDER BY YEAR_, MONTH_
		)
	, 2) AS Growth_Rate

FROM
(
	SELECT
		YEAR(OrderDate) AS YEAR_,
		MONTH(OrderDate) AS MONTH_,
		DATENAME(MONTH, OrderDate) AS MONTH_NAME,
		SUM(SubTotal) AS Total_Sales
	FROM Sales.SalesOrderHeader
	WHERE YEAR(OrderDate) IN (2023, 2024)
	GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate),
		DATENAME(MONTH, OrderDate)
) AS YoY_Monthly_Sales

ORDER BY
	YEAR_,
	MONTH_;


/* =========================================================
   5 - MONTH-OVER-MONTH (MoM) GROWTH

   Analysis Period:
   2023-2024

   The comparison is sequential across months to measure
   month-to-month sales growth or decline.
   ========================================================= */

SELECT
	YEAR_,
	MONTH_NAME,
	Total_Sales,

	LAG(Total_Sales) OVER(
		ORDER BY YEAR_, MONTH_
	) AS PREV_MONTH_SALES,

	Total_Sales -
	LAG(Total_Sales) OVER(
		ORDER BY YEAR_, MONTH_
	) AS CHANGE_,

	ROUND
	(
		(
			Total_Sales -
			LAG(Total_Sales) OVER(
				ORDER BY YEAR_, MONTH_
			)
		) * 100
		/
		LAG(Total_Sales) OVER(
			ORDER BY YEAR_, MONTH_
		)
	, 2) AS Growth_Rate

FROM
(
	SELECT
		YEAR(OrderDate) AS YEAR_,
		MONTH(OrderDate) AS MONTH_,
		DATENAME(MONTH, OrderDate) AS MONTH_NAME,
		SUM(SubTotal) AS Total_Sales
	FROM Sales.SalesOrderHeader
	WHERE YEAR(OrderDate) IN (2023, 2024)
	GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate),
		DATENAME(MONTH, OrderDate)
) AS MoM_Monthly_Sales

ORDER BY
	YEAR_,
	MONTH_;


/* =========================================================
   6 - SEASONAL SALES PATTERNS

   Analysis Period:
   2023-2024

   Seasonal analysis uses the two complete years to identify
   recurring monthly sales patterns without the distortion
   caused by partial years.
   ========================================================= */

WITH Monthly_Sales AS
(
	SELECT
		YEAR(OrderDate) AS YEAR_,
		DATENAME(MONTH, OrderDate) AS MONTH_NAME,
		SUM(SubTotal) AS Total_Sales
	FROM Sales.SalesOrderHeader
	WHERE YEAR(OrderDate) IN (2023, 2024)
	GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate),
		DATENAME(MONTH, OrderDate)
),

Seasonal_Sales AS
(
	SELECT
		YEAR_,
		MONTH_NAME,
		Total_Sales,

		AVG(Total_Sales) OVER(
			PARTITION BY MONTH_NAME
		) AS AVG_TOTAL_SALES

	FROM Monthly_Sales
)

SELECT
	YEAR_,
	MONTH_NAME,
	Total_Sales,
	AVG_TOTAL_SALES

FROM Seasonal_Sales;


/* =========================================================
   7 - CUMULATIVE (RUNNING TOTAL) SALES

   Analysis Period:
   2023-2024

   The running total tracks how sales accumulate over time.
   The cumulative percentage represents the share of total
   2023-2024 sales reached at each point in time.
   ========================================================= */

WITH Monthly_Sales AS
(
	SELECT
		YEAR(OrderDate) AS YEAR_,
		DATENAME(MONTH, OrderDate) AS MONTH_NAME,
		MONTH(OrderDate) AS MONTH_,
		SUM(SubTotal) AS Total_Sales

	FROM Sales.SalesOrderHeader

	WHERE YEAR(OrderDate) IN (2023, 2024)

	GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate),
		DATENAME(MONTH, OrderDate)
),

Ranked_Monthly_Sales AS
(
	SELECT
		RANK() OVER(
			ORDER BY YEAR_, MONTH_
		) AS RANK_,

		YEAR_,
		MONTH_NAME,
		Total_Sales,

		SUM(Total_Sales) OVER() AS GRAND_TOTAL

	FROM Monthly_Sales
)

SELECT
	RANK_,
	YEAR_,
	MONTH_NAME,
	Total_Sales,

	SUM(Total_Sales) OVER(
		ORDER BY RANK_
		ROWS UNBOUNDED PRECEDING
	) AS Cumulative_Sales,

	ROUND
	(
		SUM(Total_Sales) OVER(
			ORDER BY RANK_
			ROWS UNBOUNDED PRECEDING
		) * 100
		/
		GRAND_TOTAL
	, 2) AS Cumulative_Pct

FROM Ranked_Monthly_Sales;


/* =========================================================
   8 - ROLLING TREND
       Rolling 3-Month Average

   Analysis Period:
   2023-2024

   The rolling 3-month average smooths short-term monthly
   fluctuations by averaging the current month with the
   previous two months.
   ========================================================= */

WITH Monthly_Sales AS
(
	SELECT
		YEAR(OrderDate) AS YEAR_,
		MONTH(OrderDate) AS MONTH_,
		DATENAME(MONTH, OrderDate) AS MONTH_NAME,
		DATENAME(QUARTER, OrderDate) AS QUARTER_,
		SUM(SubTotal) AS Total_Sales

	FROM Sales.SalesOrderHeader

	WHERE YEAR(OrderDate) IN (2023, 2024)

	GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate),
		DATENAME(MONTH, OrderDate),
		DATENAME(QUARTER, OrderDate)
),

Rolling_Sales AS
(
	SELECT
		YEAR_,
		MONTH_NAME,
		MONTH_,
		QUARTER_,
		Total_Sales,

		AVG(Total_Sales) OVER(
			ORDER BY YEAR_, MONTH_
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
		) AS Rolling_3_Month_Average

	FROM Monthly_Sales
)

SELECT
	YEAR_,
	MONTH_NAME,
	QUARTER_,
	Total_Sales,
	Rolling_3_Month_Average

FROM Rolling_Sales

ORDER BY
	YEAR_,
	MONTH_,
	MONTH_NAME,
	QUARTER_;