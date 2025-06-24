SET SQL_SAFE_UPDATES = 0;

CREATE DATABASE Manufacturing_Data;
USE Manufacturing_Data;

SELECT *FROM manufacturingdata;

ALTER TABLE ManufacturingData MODIFY COLUMN `Primary Date` DATETIME;
ALTER TABLE ManufacturingData MODIFY COLUMN `Wastage Qty` float;
ALTER TABLE ManufacturingData MODIFY COLUMN `Manufactured Qty` float;

UPDATE ManufacturingData
SET `Primary Date` = STR_TO_DATE(`Primary Date`, '%d-%m-%Y')
WHERE `Primary Date` IS NOT NULL AND `Primary Date` != '';

UPDATE ManufacturingData
SET `WO Date` = STR_TO_DATE(`WO Date`, '%d-%m-%Y')
WHERE `WO Date` IS NOT NULL AND `WO Date` != '';

ALTER TABLE ManufacturingData MODIFY COLUMN `WO Date` DATETIME;

UPDATE ManufacturingData
SET `Doc Date` = STR_TO_DATE(`Doc Date`, '%d-%m-%Y')
WHERE `Doc Date` IS NOT NULL AND `Doc Date` != '';

ALTER TABLE ManufacturingData MODIFY COLUMN `Doc Date` DATETIME;
DESC ManufacturingData;

SELECT DISTINCT Buyer FROM ManufacturingData;

SELECT DISTINCT `Doc Date`,`WO Date`,`Primary Date` FROM ManufacturingData;

# total KPIs 
SELECT SUM(`Manufactured Qty`) AS Total_Manufactured_Qty FROM ManufacturingData;
SELECT SUM(`Rejected Qty`) AS Total_Rejected_Qty FROM ManufacturingData;
SELECT SUM(`Processed Qty`) AS Total_Processed_Qty FROM ManufacturingData;
SELECT SUM(`Wastage Qty`) AS Total_Wastage_Qty FROM ManufacturingData;


DROP VIEW IF EXISTS vw_ManufacturedQty;
#Total Manufactured Quantity/Day 
CREATE VIEW vw_ManufacturedQty1 AS
SELECT `WO Date`,
    SUM(`Manufactured Qty`) AS Total_Manufactured_Qty
FROM ManufacturingData
GROUP BY `WO Date`;
SELECT * FROM vw_ManufacturedQty1;

#Total Rejected Quantity
CREATE VIEW vw_RejectedQty AS
SELECT `Primary Date`,
    SUM(`Rejected Qty`) AS Total_Rejected_Qty
FROM ManufacturingData
GROUP BY `Primary Date`;
SELECT * FROM vw_RejectedQty;

#Total Processed Quantity
CREATE VIEW vw_ProcessedQty AS
SELECT `Primary Date`,
    SUM(`Processed Qty`) AS Total_Processed_Qty
FROM ManufacturingData
GROUP BY `Primary Date`;
SELECT * FROM vw_ProcessedQty;

#Total Wastage Quantity
CREATE VIEW vw_WastageQty AS
SELECT `Primary Date`,
    SUM(`Wastage Qty`) AS Total_Wastage_Qty
FROM ManufacturingData
GROUP BY `Primary Date`;
SELECT * FROM vw_WastageQty;

DROP VIEW IF EXISTS vw_EmployeeRejectedQty;
#Employee-wise Rejected Quantity
CREATE VIEW vw_EmployeeRejectedQty AS
SELECT `Emp Name`, `EMP Code`,
    SUM(`Rejected Qty`) AS Rejected_By_Employee
FROM ManufacturingData
GROUP BY `Emp Name`, `EMP Code`
ORDER BY Rejected_By_Employee DESC LIMIT 5;
SELECT * FROM vw_EmployeeRejectedQty;

DROP VIEW IF EXISTS vw_MachineRejectedQty;
#Machine-wise Rejected Quantity
CREATE VIEW vw_MachineRejectedQty AS
SELECT `Machine Code`,
    SUM(`Rejected Qty`) AS Rejected_By_Machine
FROM ManufacturingData
GROUP BY `Machine Code`
ORDER BY Rejected_By_Machine DESC LIMIT 5;
SELECT * FROM vw_MachineRejectedQty;

DROP VIEW IF EXISTS vw_EmployeeMachineMapping;
#Employee Machine Mapping
CREATE VIEW vw_EmployeeMachineMapping AS
SELECT 
    `EMP Code` AS Employee_Code,
    `Emp Name` AS Employee_Name,
    `Machine Code` AS Machine_Code
FROM ManufacturingData
WHERE `EMP Code` IS NOT NULL AND `Machine Code` IS NOT NULL;
SELECT * FROM vw_EmployeeMachineMapping;

SELECT DISTINCT Employee_Name, Machine_Code
FROM vw_EmployeeMachineMapping;

DROP VIEW IF EXISTS vw_ProductionTrend;
#Production Comparison Trend
CREATE VIEW vw_ProductionTrend AS
SELECT `Primary Date`,
    SUM(`Manufactured Qty`) AS Manufactured,
    SUM(`Processed Qty`) AS Processed,
    SUM(`Rejected Qty`) AS Rejected
FROM ManufacturingData
GROUP BY `Primary Date`;
SELECT * FROM vw_ProductionTrend;

DROP VIEW IF EXISTS vw_ManufactureVsRejected;
#Manufactured vs Rejected
CREATE VIEW vw_ManufactureVsRejected AS
SELECT `Primary Date`,
    SUM(`Manufactured Qty`) AS Manufactured,
    SUM(`Rejected Qty`) AS Rejected
FROM ManufacturingData
GROUP BY `Primary Date`;
SELECT * FROM vw_ManufactureVsRejected;

DROP VIEW IF EXISTS vw_DeptWise_ManufactureVsRejected;
#Department-wise Manufactured vs Rejected
CREATE VIEW vw_DeptWise_ManufactureVsRejected AS
SELECT `Department Name`,
    SUM(`Manufactured Qty`) AS Manufactured,
    SUM(`Rejected Qty`) AS Rejected
FROM ManufacturingData
GROUP BY `Department Name`;
SELECT * FROM vw_DeptWise_ManufactureVsRejected;

#Operation wise rejected 
SELECT `Operation_Name`, SUM(`Rejected Qty`) AS Total_Rejected
FROM manufacturingdata
WHERE `Department_Name` = 'Woven Lables'
GROUP BY `Operation_Name`
ORDER BY Total_Rejected DESC;

#Item wise rejected
SELECT `Item Name`, SUM(`Rejected Qty`) AS Total_Rejected
FROM ManufacturingData
WHERE `Department_Name` = 'Woven Lables'
GROUP BY `Item Name`
ORDER BY Total_Rejected DESC;

DROP VIEW IF EXISTS vw_EmployeeRejectedQty;
#Emp-wise Rejected Qty
CREATE VIEW vw_EmployeeRejectedQty AS
SELECT  `EMP Code`,
    SUM(`Rejected Qty`) AS Rejected_By_Employee
FROM ManufacturingData
GROUP BY `Emp Name`, `EMP Code`
ORDER BY Rejected_By_Employee DESC LIMIT 5;
SELECT * FROM vw_EmployeeRejectedQty;

DROP VIEW IF EXISTS vw_WastagePercentage;
#Wastage % per day
CREATE VIEW vw_WastagePercentage AS
SELECT `Primary Date`,
    SUM(`Manufactured Qty`) AS Total_Manufactured_Qty,
    SUM(`Wastage Qty`) AS Total_Wastage_Qty,
    CASE 
        WHEN SUM(`Manufactured Qty`) = 0 THEN 0
        ELSE CONCAT(ROUND((SUM(`Wastage Qty`) / SUM(`Manufactured Qty`)) * 100, 2), '%')
    END AS Wastage_Percentage
FROM ManufacturingData GROUP BY `Primary Date` ORDER BY Wastage_Percentage DESC;
SELECT * FROM vw_WastagePercentage;

Desc ManufacturingData;

UPDATE ManufacturingData
SET `SO Expected Delivery F` = STR_TO_DATE(`SO Expected Delivery F`, '%d-%m-%Y')
WHERE `SO Expected Delivery F` IS NOT NULL AND `SO Expected Delivery F` != '';

ALTER TABLE ManufacturingData MODIFY COLUMN `SO Expected Delivery F` DATETIME;

#Estimated Days Required
CREATE VIEW Estimated_days AS
SELECT 
  `WO Number`,
  DATEDIFF(`SO Expected Delivery F`, `WO Date`) AS Estimated_Days
FROM ManufacturingData
WHERE `WO Date` IS NOT NULL AND `SO Expected Delivery F` IS NOT NULL
ORDER BY Estimated_Days DESC;
SELECT * FROM Estimated_days;

SELECT 
  ROUND(AVG(DATEDIFF(`SO Expected Delivery F`, `WO Date`)), 2) AS Avg_Estimated_Days
FROM ManufacturingData
WHERE `WO Date` IS NOT NULL AND `SO Expected Delivery F` IS NOT NULL;

#On time delivery% 
SELECT 
  ROUND(
    (COUNT(CASE 
        WHEN `U_unitdeldt` <= `SO Expected Delivery F` THEN 1 
     END) * 100.0) / COUNT(`WO Number`), 2) AS Delivery_Percentage
FROM ManufacturingData
WHERE `U_unitdeldt` IS NOT NULL AND `SO Expected Delivery F` IS NOT NULL;
