USE [MDW_test06]
GO
/****** Object:  StoredProcedure [etl].[LOAD_TD_Ft_Strækningsøkonomi_CALC]    Script Date: 03-12-2015 09:44:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [etl].[LOAD_TD_Ft_Strækningsøkonomi_SOEM_ABM] @model varchar(50) = '1043', @periode varchar(50) = '201508'
AS
BEGIN
--#####################DIMENSION##########################
IF object_id('ods.TD_SOEM_ABM_dimension') is not null DROP TABLE ods.TD_SOEM_ABM_dimension
SELECT 1000+row_number() OVER (ORDER BY der_dim.ModuleType) DimensionId,der_dim.ModuleType DimensionName 
INTO ods.TD_SOEM_ABM_dimension
FROM
(  
SELECT ModuleType
FROM [dbo].[ABC_G_ACC_Aktivitet]
UNION
SELECT ModuleType
FROM [dbo].ABC_G_ACC_Costobject
UNION
SELECT ModuleType
FROM [dbo].ABC_G_ACC_Ressource
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_Funktionskunde
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_ProdAktGrp
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_ProduktLitra
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_ProdVar
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_Ressourcetype
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_Ressourcetype
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_Segment
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_TidDr
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_Togsystem
UNION
SELECT 'ExternalUnit' ModuleType
UNION 
SELECT 'MængdeEnhed' ModuleType
) der_dim

IF object_id('tempdb..#dimension_member_atthier') is not null DROP TABLE #dimension_member_atthier
SELECT dim.DimensionId,CAST(null AS VARCHAR) AttributeDimension,CAST(null AS VARCHAR(256)) Attribute,CAST(null AS int) AttributeId,der_member_atthier.Dimensionname,der_member_atthier.MemberName,der_member_atthier.MemberRefnum,der_member_atthier.ParentReference 
INTO #dimension_member_atthier
FROM
(
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].[ABC_G_ATTHIER_Funktionskunde]
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_ProdAktGrp
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_ProduktLitra
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_ProdVar
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_RessourceType
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_Segment
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_Togsystem
) der_member_atthier 
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_atthier.Dimensionname

IF object_id('tempdb..#dimension_member_hier') is not null DROP TABLE #dimension_member_hier
SELECT dim.DimensionId,CAST(null AS VARCHAR) AttributeDimension,CAST(null AS VARCHAR(256)) Attribute,CAST(null AS int) AttributeId,der_member_hier.DimensionName,der_member_hier.MemberName,der_member_hier.MemberRefnum,der_member_hier.ParentReference
INTO #dimension_member_hier
FROM
(
SELECT ModuleType DimensionName,Name MemberName,Reference MemberRefnum,ParentReference,Periode FROM [dbo].ABC_G_HIER_Aktivitet where periode=201510
UNION
SELECT ModuleType DimensionName,Name MemberName,Reference MemberRefnum,ParentReference,Periode FROM [dbo].ABC_G_HIER_Costobject where periode=201510
UNION
SELECT ModuleType DimensionName,Name MemberName,Reference MemberRefnum,ParentReference,Periode FROM [dbo].ABC_G_HIER_Ressource where periode=201510
) der_member_hier
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_hier.Dimensionname

IF object_id('tempdb..#dimension_member_akt') is not null DROP TABLE #dimension_member_akt
SELECT dim.DimensionId,CAST(AttributeDimension AS VARCHAR) AttributeDimension,CAST(Attribute AS VARCHAR(256)) Attribute,CAST(null AS int) AttributeId,der_member_aktivitet.DimensionName,akt.Name MemberName,der_member_aktivitet.MemberRefnum,akt.ParentReference 
INTO #dimension_member_akt
FROM
(
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Funktionskunde] WHERE Periode=201508 
UNION 
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_ProdAktGrp] WHERE Periode=201508
UNION 
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_ProduktLitra] WHERE Periode=201508
UNION 
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_ProdVar] WHERE Periode=201508
UNION 
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Segment] WHERE Periode=201508
UNION 
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_TidDr] WHERE Periode=201508
) der_member_aktivitet 
JOIN [dbo].[ABC_G_ACC_Aktivitet] akt on akt.Reference=der_member_aktivitet.MemberRefnum and akt.Periode=der_member_aktivitet.Periode
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_aktivitet.DimensionName

IF object_id('tempdb..#dimension_member_res') is not null DROP TABLE #dimension_member_res
SELECT dim.DimensionId,CAST(null AS VARCHAR) AttributeDimension,CAST(null AS VARCHAR(256)) Attribute,CAST(null AS int) AttributeId,res.ModuleType DimensionName,res.Name MemberName,res.Reference,res.ParentReference
INTO #dimension_member_res
FROM [dbo].[ABC_G_ACC_Ressource] res --ON res.Reference=der_member_res.MemberRefnum and res.Periode=der_member_res.Periode
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=res.ModuleType and res.Periode=201508

IF object_id('tempdb..#dimension_member_cost') is not null DROP TABLE #dimension_member_cost
SELECT dim.DimensionId,CAST(AttributeDimension AS VARCHAR) AttributeDimension,CAST(Attribute AS VARCHAR(256)) Attribute,CAST(null AS int) AttributeId,der_member_cos.DimensionName,cost.Name MemberName,der_member_cos.MemberRefnum,cost.ParentReference
INTO #dimension_member_cost
FROM
(
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Togsystem] WHERE Periode=201508 
) der_member_cos 
JOIN [dbo].[ABC_G_ACC_Costobject] cost on cost.Reference=der_member_cos.MemberRefnum and cost.Periode=der_member_cos.Periode
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_cos.DimensionName

IF object_id('tempdb..#dimension_member') is not null DROP TABLE #dimension_member
SELECT 1012+row_number() OVER (ORDER BY der_dimension.MemberName) MemberId,* 
INTO #dimension_member
FROM 
(
SELECT * FROM #dimension_member_atthier
UNION 
SELECT * FROM #dimension_member_hier
UNION 
SELECT * FROM #dimension_member_akt
UNION 
SELECT * FROM #dimension_member_res
UNION 
SELECT * FROM #dimension_member_cost
) der_dimension 
--select * from #dimension_member where substring(memberrefnum,1,2)='A4'
IF object_id('ods.TD_SOEM_ABM_dimmember') is not null DROP TABLE ods.TD_SOEM_ABM_dimmember

SELECT a.DimensionId,a.Attribute,a.AttributeDimension,CAST(null AS int) AttributeId,a.Dimensionname,a.MemberId,a.MemberName,a.MemberRefnum,a.ParentReference,COALESCE(b.MemberId,0) ParentId 
INTO ods.TD_SOEM_ABM_dimmember
FROM #dimension_member a
LEFT JOIN #dimension_member b on b.MemberRefnum=a.ParentReference and a.DimensionId=b.DimensionId
--select * from ods.TD_SOEM_ABM_dimmember where substring(memberrefnum,1,2)='A4'
INSERT INTO ods.TD_SOEM_ABM_dimmember 
	(DimensionId,Attribute,AttributeDimension,AttributeId,DimensionName,MemberId,MemberName,MemberRefnum,ParentReference,ParentId) 
	VALUES 
	(0,null,null,null,'',0,'All','All','',0)
INSERT INTO ods.TD_SOEM_ABM_dimmember 
	(DimensionId,Attribute,AttributeDimension,AttributeId,DimensionName,MemberId,MemberName,MemberRefnum,ParentReference,ParentId) 
	VALUES 
	(0,null,null,null,'',1,'None','None','',0)

UPDATE ods.TD_SOEM_ABM_dimmember SET AttributeId=(SELECT TOP 1 a.MemberId FROM ods.TD_SOEM_ABM_dimmember a WHERE ods.TD_SOEM_ABM_dimmember.Attribute=a.MemberRefnum and
		ods.TD_SOEM_ABM_dimmember.AttributeDimension=a.Dimensionname)
--UPDATE ods.TD_SOEM_ABM_dimmember SET AttributeDimension=(SELECT TOP 1 a.DimensionName FROM ods.TD_SOEM_ABM_dimmember a WHERE ods.TD_SOEM_ABM_dimmember.Attribute=a.MemberRefnum) 
--########################################################
/*driver source*/
IF object_id('tempdb..#driver_source') is not null DROP TABLE #driver_source
SELECT *
INTO #driver_source
FROM
(select SourceReference,DriverName,Periode from dbo.ABC_G_SDL_Activities
union all
select SourceReference,DriverName,Periode from dbo.ABC_G_SDL_Ressourcer
) driver_source

/*driver destination*/
IF object_id('tempdb..#driver_destination') is not null DROP TABLE #driver_destination
SELECT *
INTO #driver_destination
FROM
(select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed from dbo.ABC_R_DR_Baneafgifter_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_Lokoførertid_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed from dbo.ABC_R_DR_Lokoførertid_STog
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed from dbo.ABC_R_DR_Manuelle
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_Moms
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_PersonaleData
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_RejserIndtægter_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_RejserIndtægter_Stog
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_RejserIndtægter_Togsystem_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_Togførertid_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_Togproduktion_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_Togproduktion_Stog
) as driver_destination

/*driver*/
IF object_id('tempdb..#driver') is not null DROP TABLE #driver
SELECT *
INTO #driver
FROM
(select 
	sdl.DriverName,
	sdl.SourceReference,
	drv.DestReference,
	drv.DriverQuantityFixed,
	drv.sumDriverQuantityFixed,
	drv.Periode
from #driver_source sdl
join #driver_destination drv on sdl.DriverName=drv.DriverName and sdl.Periode=drv.Periode
) driver

/*tilføj event assigned til drivere*/
INSERT INTO #driver
SELECT *
FROM
(select 'ActEventAssign' DriverName,SourceReference,DestReference,1 DriverQuantityFixed,1 sumDriverQuantityFixed,Periode from dbo.ABC_G_EA_Activities 
union all
select 'ResEventAssign' DriverName,SourceReference,DestReference,1 DriverQuantityFixed,1 sumDriverQuantityFixed,Periode from dbo.ABC_G_EA_Ressourcer
) driver_event_assigned

--select * from #driver where SourceReference in ('A4_5300002','R1_9343250_X','A4_5201500','R1_9343250_U') and periode=201508

/*cost element*/
IF object_id('tempdb..#cost_element') is not null DROP TABLE #cost_element
SELECT *
INTO #cost_element
FROM
(SELECT Name,Reference,AccountReference,Periode,SUM(cost_element.EnteredCost) Cost FROM
(SELECT Name,EnteredCost,Reference,AccountReference,Periode FROM [dbo].[ABC_R_CE_anlæg]
union all
SELECT Name,EnteredCost,Reference,AccountReference,Periode FROM [dbo].[ABC_R_CE_Drift]
) cost_element 
WHERE cost_element.Periode=@periode
GROUP BY cost_element.Name,cost_element.AccountReference,cost_element.Reference,cost_element.Periode
) coel

--select distinct substring(Reference,1,2),substring(AccountReference,1,2) from #cost_element

/*1. driver beregning*/
IF object_id('tempdb..#driver1calc') is not null DROP TABLE #driver1calc
SELECT * 
INTO #driver1calc
FROM
(select
	drv.DriverName,
	ce.AccountReference SourceReference,
	drv.DestReference,
	drv.Periode,
	(ce.Cost )*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
from #cost_element ce
join #driver drv on ce.AccountReference=drv.SourceReference and ce.Periode=drv.Periode
) driver1calc 

--select distinct substring(SourceReference,1,2)calc1,substring(DestReference,1,2) from #driver1calc
/*2. driver beregning*/
IF object_id('tempdb..#driver2calc') is not null DROP TABLE #driver2calc
SELECT * 
INTO #driver2calc
FROM
(select
	drv.DriverName,
	drvcalc.DestReference SourceReference,
	drv.DestReference,
	drv.Periode,
	(drvcalc.CalcCost )*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
from #driver1calc drvcalc
join #driver drv on drvcalc.DestReference=drv.SourceReference and drvcalc.Periode=drv.Periode
) driver2calc 

--select distinct substring(SourceReference,1,2) calc2,substring(DestReference,1,2) from #driver2calc

/*3. driver beregning*/
IF object_id('tempdb..#driver3calc') is not null DROP TABLE #driver3calc
SELECT * 
INTO #driver3calc
FROM
(select
	drv.DriverName,
	drvcalc.DestReference SourceReference,
	drv.DestReference,
	drv.Periode,
	(drvcalc.CalcCost )*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
from #driver2calc drvcalc
join #driver drv on drvcalc.DestReference=drv.SourceReference and drvcalc.Periode=drv.Periode
) driver3calc 

--select distinct substring(SourceReference,1,2),substring(DestReference,1,2) from #driver3calc

/*4. og sidste driver beregning*/
IF object_id('tempdb..#driver4calc') is not null DROP TABLE #driver4calc
SELECT * 
INTO #driver4calc
FROM
(select
	drv.DriverName,
	drvcalc.DestReference SourceReference,
	drv.DestReference,
	drv.Periode,
	(drvcalc.CalcCost)*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
from #driver3calc drvcalc
join #driver drv on drvcalc.DestReference=drv.SourceReference and drvcalc.Periode=drv.Periode
) driver4calc 

--select distinct substring(SourceReference,1,2),substring(DestReference,1,2) from #driver4calc

IF object_id('ods.TD_SOEM_ABM_ACCOUNT_ATTRIB') is not null DROP TABLE ods.TD_SOEM_ABM_ACCOUNT_ATTRIB
SELECT * 
INTO ods.TD_SOEM_ABM_ACCOUNT_ATTRIB
FROM
(
SELECT AttributeReference,AttributeDimension,AccountReference FROM [dbo].ABC_G_ATT_Funktionskunde WHERE Periode=201508
UNION
SELECT AttributeReference,AttributeDimension,AccountReference FROM [dbo].ABC_G_ATT_ProdAktGrp WHERE Periode=201508
UNION
SELECT AttributeReference,AttributeDimension,AccountReference FROM [dbo].ABC_G_ATT_ProduktLitra WHERE Periode=201508
UNION
SELECT AttributeReference,AttributeDimension,AccountReference FROM [dbo].ABC_G_ATT_ProdVar WHERE Periode=201508
UNION
SELECT AttributeReference,AttributeDimension,AccountReference FROM [dbo].ABC_G_ATT_Ressourcetype WHERE Periode=201508
UNION
SELECT AttributeReference,AttributeDimension,AccountReference FROM [dbo].ABC_G_ATT_Segment WHERE Periode=201508
UNION
SELECT AttributeReference,AttributeDimension,AccountReference FROM [dbo].ABC_G_ATT_TidDr WHERE Periode=201508
UNION
SELECT AttributeReference,AttributeDimension,AccountReference FROM [dbo].ABC_G_ATT_Togsystem WHERE Periode=201508
) der_acc_att

IF object_id('tempdb..#td_soem_abm') is not null DROP TABLE #td_soem_abm
SELECT 
	Model,
	SourceReference SourceRefnum,
	DestReference DestRefnum,
	Periode PeriodRefnum,
	SUM(CalcCost) FixedCost, 
	'Aktual' as ScenarioRefnum,
	Case when substring(SourceReference,1,1)='E' then substring(reverse(SourceReference),6,1) else NULL end as Artgrp
INTO #td_soem_abm
FROM
(
SELECT Name DriverName,@model Model,Reference SourceReference,AccountReference DestReference,Periode,Cost CalcCost FROM #cost_element
UNION ALL
SELECT DriverName,@model Model,SourceReference,DestReference,Periode,CalcCost FROM #driver1calc
UNION ALL
SELECT DriverName,@model Model,SourceReference,DestReference,Periode,CalcCost FROM #driver2calc
UNION ALL
SELECT DriverName,@model Model,SourceReference,DestReference,Periode,CalcCost FROM #driver3calc
UNION ALL
SELECT DriverName,@model Model,SourceReference,DestReference,Periode,CalcCost FROM #driver4calc
) tmp_TD_SOEM_ABM
GROUP BY tmp_TD_SOEM_ABM.Model,tmp_TD_SOEM_ABM.SourceReference,tmp_TD_SOEM_ABM.DestReference,tmp_TD_SOEM_ABM.Periode

IF object_id('[ods].[TD_SOEM_ABM]') is not null DROP TABLE [ods].[TD_SOEM_ABM]
SELECT der_td_soem_abm.*

INTO [ods].[TD_SOEM_ABM] 
FROM
(
SELECT * FROM #td_soem_abm
) der_td_soem_abm

--IF object_id('[ods].[TD_SOEM_ABM_ANDEL]') is not null DROP TABLE [ods].[TD_SOEM_ABM_ANDEL]
--SELECT Model,SourceReference,DestReference,Periode,CalcCost,CASE WHEN CalcCost=0 THEN 0 ELSE CalcCost/(SUM(CalcCost) OVER (PARTITION BY DestReference)) END Andel 
--INTO [ods].[TD_SOEM_ABM_ANDEL]
--FROM [ods].[TD_SOEM_ABM]


--select * from [ods].[TD_SOEM_ABM_ANDEL] where substring(SourceReference,1,2)='E1'

--IF object_id('[ods].[TD_FACT_SOEM_ABM]') is not null DROP TABLE [ods].[TD_FACT_SOEM_ABM]
--SELECT level0
--INTO [ods].[TD_FACT_SOEM_ABM]
--(
--SELECT SourceReference level0 FROM 
--) tmp_TD_FACT_SOEM_ABM
END
