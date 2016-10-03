--use MDW_test17_Intern_handel
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA=N'ods' and  TABLE_NAME = N'RDP_Togproduktion_Tog'--RDP_Togproduktion_Tog  TD_RDP_Togproduktion_Tog

order by COLUMN_NAME