/****** Script for SelectTopNRows command from SSMS  ******/
select 
*
--Co1Refnum,sum(destcost) 
from MDW_test06.ods.td1_ft_strækningsøkonomi_SOEMABM
--where substring(Co1Refnum,1,2)='c1'
--group by Co1Refnum
--order by Co1Refnum
--except
select 
*
--Co1Refnum,sum(destcost) 
from  [MDW_test06].[ods].[td1_ft_strækningsøkonomi_test1]
--where substring(Co1Refnum,1,2)='c1'
--group by Co1Refnum
--order by Co1Refnum