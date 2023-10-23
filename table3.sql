CREATE TABLE main_table (
    "Row ID" INT,
    "Order ID" VARCHAR(255),
    "Order Date" TIMESTAMP,
    "Ship Date" TIMESTAMP,
    "Ship Mode" VARCHAR(255),
    "Customer ID" VARCHAR(255),
    "Customer Name" VARCHAR(255),
    "Segment" VARCHAR(255),
    "Country" VARCHAR(255),
    "City" VARCHAR(255),
    "State" VARCHAR(255),
    "Postal Code" INTEGER,
    "Region" VARCHAR(255),
    "Product ID" VARCHAR(255),
    "Category" VARCHAR(255),
    "Sub-Category" VARCHAR(255),
    "Product Name" VARCHAR(255),
    "Sales" NUMERIC,
    "Quantity" INTEGER,
    "Discount" NUMERIC,
    "Profit" NUMERIC
);
SELECT * FROM main_table
----------
--Import Data
COPY main_table FROM 'C:\Users\seyed\Downloads\BI_Test_Dataset.csv' DELIMITER ',' CSV HEADER;
----------
-- Creating INT in new table
CREATE TABLE main_table_2 AS
SELECT *,
       CAST(SUBSTRING("Customer ID" FROM 4) AS INTEGER) AS "customer_ID"
FROM main_table;
----------
 
-- Customer Table
CREATE TABLE Customers (
    Customer_ID INT Primary Key,
    First_Name VARCHAR(50),
    Last_Name VARCHAR(50),
    Email VARCHAR(100),
    Address VARCHAR(200),
    City VARCHAR(50),
    State VARCHAR(50),
    Zip_Code VARCHAR(20)
);

INSERT INTO Customers (Customer_ID, First_Name, Last_Name, Email, Address, City, State, Zip_Code)
SELECT Customer_ID, First_Name, Last_Name, Email, Address, "City", "State", "Postal Code"
FROM (
SELECT
    Distinct Customer_ID,
    SPLIT_PART("Customer Name", ' ', 1) AS First_Name,
    SPLIT_PART("Customer Name", ' ', 2) AS Last_Name,
    NULL AS Email,
    NULL AS Address,
    "City",
    "State",
    "Postal Code",
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY RANDOM()) AS row_num
FROM main_table_2
) AS numbered_rows
WHERE row_num =1;

SELECT * FROM Customers
LIMIT 5;
------
-- Changing the String to INT on Order ID 
ALTER TABLE main_table_2
ADD COLUMN Order_ID INTEGER;

UPDATE main_table_2
SET Order_ID = CAST(translate(regexp_replace("Order ID", '[^0-9]', '', 'g'), '-', '') AS INTEGER);
------
--Orders Table
CREATE TABLE Orders (
    Order_ID INT PRIMARY KEY,
    Customer_ID INT REFERENCES Customers(Customer_ID),
    Order_Date TIMESTAMP,
    Total_Amount DECIMAL(18, 2)
);

-- Insert or update data from main_table_2 into Orders2
INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Total_Amount)
SELECT
    Order_ID,
    Customer_ID,
    TO_TIMESTAMP("Order Date"::text, 'YYYY-MM-DD') AS Order_Date,
    SUM("Sales") AS Total_Amount
FROM main_table_2
GROUP BY Order_ID, Customer_ID, Order_Date
ON CONFLICT (Order_ID) DO UPDATE
SET 
    Order_Date = EXCLUDED.Order_Date,
    Total_Amount = EXCLUDED.Total_Amount;


SELECT * FROM Orders
LIMIT 5;
	
-----
--Order Items table

CREATE TABLE Order_Items (
    Order_Item_ID SERIAL PRIMARY KEY,
    Order_ID INT,
    Product_Name VARCHAR(200),
    Quantity INT,
    Price DECIMAL(18, 2),
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID)
);

INSERT INTO Order_Items(Order_ID,Product_Name,Quantity,Price)
SELECT 
    Order_ID,
	"Product Name",
	"Quantity",
	"Sales"
From main_table_2
------
-- Changing the String to INT on Product ID 
ALTER TABLE main_table_2
ADD COLUMN Product_ID INTEGER;

UPDATE main_table_2
SET Product_ID =  CAST(SUBSTRING("Product ID" FROM 8) AS INTEGER);


SELECT * FROM Order_Items
LIMIT 5;
------
--Products table
CREATE TABLE Products (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(200),
    Unit_Price DECIMAL(18, 2),
    Units_In_Stock INT
);

INSERT INTO Products (Product_ID, Product_Name, Unit_Price, Units_In_Stock)
SELECT Product_ID, "Product Name", Unit_Price, NULL
FROM (
    SELECT
        Product_ID,
        "Product Name",
        "Sales" / "Quantity" AS Unit_Price,
        ROW_NUMBER() OVER (PARTITION BY Product_ID ORDER BY RANDOM()) AS row_num
    FROM main_table_2
) AS numbered_rows
WHERE row_num = 1;


SELECT * FROM Products
LIMIT 5;
----------
select distinct "Category"
FROM main_table_2
--- We have Furniture, Office Supplies, Technology as Unique values

-- Create the Categories table
CREATE TABLE Categories (
    Category_ID SERIAL PRIMARY KEY,
    Category_Name VARCHAR(50),
    Description VARCHAR(200)
);

INSERT INTO Categories (Category_Name, Description)
SELECT
    DISTINCT "Category",
    NULL AS "Description"
FROM main_table_2;

SELECT DISTINCT "Category"
FROM main_table_2;


SELECT * FROM Categories
LIMIT 5;
---------------

-- Product Categories Table
CREATE TABLE Product_Categories (
    Product_ID INT,
    Category_ID INT,
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID),
    FOREIGN KEY (Category_ID) REFERENCES Categories(Category_ID)
);

INSERT INTO Product_Categories (Product_ID,Category_ID)
SELECT
    Products.Product_ID,
    Categories.Category_ID
FROM main_table_2
JOIN Products ON main_table_2.Product_ID = Products.Product_ID
JOIN Categories ON main_table_2."Category" = Categories.Category_Name;


SELECT * FROM Product_Categories
LIMIT 5;

--------------------------------------
-- 4.a.	What was the total revenue generated in the last quarter?

SELECT *
FROM Orders
ORDER BY Order_Date DESC;
-- most recent date: 2017-12-30

SELECT SUM(Total_Amount) AS "Total Revenue" FROM Orders
WHERE Order_Date Between '2017-10-01' AND '2017-12-30';


-- 4.b.	Which products have the highest sales volume?

SELECT Product_Name, SUM(Quantity) AS "Highest Sales Volume" FROM Order_Items
GROUP BY Product_Name
ORDER BY "Highest Sales Volume" DESC
LIMIT 5;
-----------------------------------
-- As a bridge table in star schema table
CREATE TABLE Categories_Orders (
    Category_ID INT,
    Order_ID INT,
    FOREIGN KEY (Category_ID) REFERENCES Categories(Category_ID),
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID)
);

INSERT INTO Categories_Orders (Category_ID, Order_ID)
SELECT
    Categories.Category_ID,
    Orders.Order_ID
FROM main_table_2
JOIN Categories ON main_table_2."Category" = Categories.Category_Name
JOIN Orders ON main_table_2.Order_ID = Orders.Order_ID;

----------------------------------- 




