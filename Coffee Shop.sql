-- =================================================================
-- ------------------- COFFEE SHOP SALES ANALYSIS ------------------
-- =================================================================

-- -----------------------------------------------------------------
-- 1. OVERALL DATASET & SUMMARY AGGREGATIONS
-- -----------------------------------------------------------------

-- View the raw data
select * from coffe_sales;

-- High-level business totals
select count(*) as Total_Transactions from coffe_sales;
select round(sum(money), 2) as Total_Revenue from coffe_sales;
select round(avg(money), 2) as Average_Transaction_Value from coffe_sales;


-- -----------------------------------------------------------------
-- 2. TIME-BASED TRENDS (WHEN)
-- -----------------------------------------------------------------

-- Monthly performance summary
select Monthsort, Month_name, round(sum(money)) as Total_Sales 
from coffe_sales
group by Monthsort, Month_name
order by Monthsort;

-- Weekly performance summary
select Weekdaysort, Weekday, round(sum(money)) as Total_Sales 
from coffe_sales
group by Weekdaysort, Weekday
order by Weekdaysort;


-- -----------------------------------------------------------------
-- 3. PRODUCT & CATEGORY PERFORMANCE (WHAT)
-- -----------------------------------------------------------------

-- Coffee Popularity: Best-selling beverages by revenue
select coffee_name, count(*) as Total_Orders, round(sum(money)) as Total_Revenue
from coffe_sales
group by coffee_name
order by Total_Revenue desc;


-- -----------------------------------------------------------------
-- 4. ADVANCED ANALYTICS (CTEs & WINDOW FUNCTIONS)
-- -----------------------------------------------------------------

-- A. Running Total of Revenue over Time
-- This shows how revenue accumulates day-by-day
select 
    Date, 
    round(sum(money), 2) as Daily_Revenue,
    round(sum(sum(money)) over (order by Date), 2) as Running_Total
from coffe_sales
group by Date;

-- B. Product Ranking within Time of Day
-- Using RANK() to find the #1 product for Morning, Afternoon, and Night
with ProductRank as (
    select 
        Time_of_Day, 
        coffee_name, 
        count(*) as Sales_Count,
        rank() over (partition by Time_of_Day order by count(*) desc) as Item_Rank
    from coffe_sales
    group by Time_of_Day, coffee_name
)
select * from ProductRank where Item_Rank <= 3;

-- C. Month-over-Month (MoM) Growth Percentage
-- Uses LAG() to compare current month sales to previous month
with MonthlySales as (
    select 
        Monthsort, 
        Month_name, 
        sum(money) as Total_Sales
    from coffe_sales
    group by Monthsort, Month_name
)
select 
    Month_name, 
    round(Total_Sales, 2) as Current_Month_Sales,
    round(lag(Total_Sales) over (order by Monthsort), 2) as Previous_Month_Sales,
    round(((Total_Sales - lag(Total_Sales) over (order by Monthsort)) / lag(Total_Sales) over (order by Monthsort)) * 100, 2) as MoM_Growth_Pct
from MonthlySales;

-- D. Hourly Contribution to Daily Sales
-- Calculates what % of the daily revenue happens in each specific hour
with DailyTotal as (
    select Date, sum(money) as Day_Total
    from coffe_sales
    group by Date
)
select 
    c.Date, 
    c.hour_of_day, 
    round(sum(c.money), 2) as Hourly_Rev,
    round((sum(c.money) / d.Day_Total) * 100, 2) as Pct_of_Daily_Revenue
from coffe_sales c
join DailyTotal d on c.Date = d.Date
group by c.Date, c.hour_of_day, d.Day_Total
order by c.Date, c.hour_of_day;


-- -----------------------------------------------------------------
-- 5. PAYMENT & OPERATIONAL LOGISTICS
-- -----------------------------------------------------------------

-- Payment Preference: Card vs Cash volume
select cash_type, count(*) as Total_Transactions, round(sum(money)) as Total_Revenue
from coffe_sales
group by cash_type
order by Total_Transactions desc;

-- Average Ticket Size by Payment Method
select cash_type, round(avg(money), 2) as Avg_Spend
from coffe_sales
group by cash_type;