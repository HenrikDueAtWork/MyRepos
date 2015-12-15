USE [MDW_test07]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
alter PROCEDURE [etl].[LOAD_TD_Ft_Strækningsøkonomi_SOEM_ABM] @model varchar(50) = '2222', @periode varchar(50) = '201509'
AS
BEGIN
--##################### KONTO DIMENSION ##########################
/*
Opret midlertidig tabel med samtlige dimensioner
*/
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
/*
Opret temp tabel med hierarki på dimensionsmedlemmer (parent/child). Ikke aktivitets,ressource og costobjekt dimensioner
*/
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
/*
Opret temp tabel med hierarki af medlemmer på aktivitets,ressource og costobjekt dimensioner
*/
IF object_id('tempdb..#dimension_member_hier') is not null DROP TABLE #dimension_member_hier
SELECT dim.DimensionId,CAST(null AS VARCHAR) AttributeDimension,CAST(null AS VARCHAR(256)) Attribute,CAST(null AS int) AttributeId,der_member_hier.DimensionName,der_member_hier.MemberName,der_member_hier.MemberRefnum,der_member_hier.ParentReference
INTO #dimension_member_hier
FROM
(
SELECT ModuleType DimensionName,Name MemberName,Reference MemberRefnum,ParentReference,Periode FROM [dbo].ABC_G_HIER_Aktivitet where periode=@periode
UNION
SELECT ModuleType DimensionName,Name MemberName,Reference MemberRefnum,ParentReference,Periode FROM [dbo].ABC_G_HIER_Costobject where periode=@periode
UNION
SELECT ModuleType DimensionName,Name MemberName,Reference MemberRefnum,ParentReference,Periode FROM [dbo].ABC_G_HIER_Ressource where periode=@periode
) der_member_hier
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_hier.Dimensionname
/*
Opret temp tabel med attributter på aktivitets dimension og medlemmer
*/
IF object_id('tempdb..#dimension_member_akt') is not null DROP TABLE #dimension_member_akt
SELECT dim.DimensionId,CAST(AttributeDimension AS VARCHAR) AttributeDimension,CAST(Attribute AS VARCHAR(256)) Attribute,CAST(null AS int) AttributeId,der_member_aktivitet.DimensionName,akt.Name MemberName,der_member_aktivitet.MemberRefnum,akt.ParentReference 
INTO #dimension_member_akt
FROM
(
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Funktionskunde] WHERE Periode=@periode 
UNION 
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_ProdAktGrp] WHERE Periode=@periode
UNION 
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_ProduktLitra] WHERE Periode=@periode
UNION 
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_ProdVar] WHERE Periode=@periode
UNION 
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Segment] WHERE Periode=@periode
UNION 
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_TidDr] WHERE Periode=@periode
) der_member_aktivitet 
JOIN [dbo].[ABC_G_ACC_Aktivitet] akt on akt.Reference=der_member_aktivitet.MemberRefnum and akt.Periode=der_member_aktivitet.Periode
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_aktivitet.DimensionName
/*
Opret temp tabel med NULL attributter på ressourcer dimension og medlemmer
*/
IF object_id('tempdb..#dimension_member_res') is not null DROP TABLE #dimension_member_res
SELECT dim.DimensionId,CAST(res.AttributeDimension AS VARCHAR) AttributeDimension,CAST(res.AttributeReference AS VARCHAR(256)) Attribute,CAST(null AS int) AttributeId,der_member_res.ModuleType DimensionName,der_member_res.Name MemberName,der_member_res.Reference,der_member_res.ParentReference
INTO #dimension_member_res
FROM 
(
SELECT ModuleType,Name,Reference,ParentReference,Periode FROM [dbo].[ABC_G_ACC_Ressource] WHERE Periode=201508 
--SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Ressourcetype] WHERE Periode=201508 
) der_member_res  
LEFT JOIN [dbo].[ABC_G_ATT_Ressourcetype] res on res.AccountReference=der_member_res.Reference and res.Periode=der_member_res.Periode
--RIGHT JOIN [dbo].[ABC_G_ACC_Ressource] res on res.Reference=der_member_res.MemberRefnum and res.Periode=der_member_res.Periode
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_res.ModuleType
/*
Opret temp tabel med attributter på costobjekt dimension og medlemmer
*/
IF object_id('tempdb..#dimension_member_cost') is not null DROP TABLE #dimension_member_cost
SELECT dim.DimensionId,CAST(AttributeDimension AS VARCHAR) AttributeDimension,CAST(Attribute AS VARCHAR(256)) Attribute,CAST(null AS int) AttributeId,der_member_cos.DimensionName,cost.Name MemberName,der_member_cos.MemberRefnum,cost.ParentReference
INTO #dimension_member_cost
FROM
(
SELECT AttributeDimension,AttributeReference Attribute,AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Togsystem] WHERE Periode=@periode 
) der_member_cos 
JOIN [dbo].[ABC_G_ACC_Costobject] cost on cost.Reference=der_member_cos.MemberRefnum and cost.Periode=der_member_cos.Periode
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_cos.DimensionName
/*
Opret temp tabel med alle dimensionsmedlemmer og tildel tifældig ID
*/
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
/*
Opret midlertidig tabel med dimensionsmedlemmer og tilføj reference (parent) til hierarki
*/
IF object_id('ods.TD_SOEM_ABM_dimmember') is not null DROP TABLE ods.TD_SOEM_ABM_dimmember
SELECT a.DimensionId,a.Attribute,a.AttributeDimension,CAST(null AS int) AttributeId,a.Dimensionname,a.MemberId,a.MemberName,a.MemberRefnum,a.ParentReference,COALESCE(b.MemberId,0) ParentId 
INTO ods.TD_SOEM_ABM_dimmember
FROM #dimension_member a
LEFT JOIN #dimension_member b on b.MemberRefnum=a.ParentReference and a.DimensionId=b.DimensionId
/*
Tilføj "All" og "None" dimensionsmedlem
*/
INSERT INTO ods.TD_SOEM_ABM_dimmember 
	(DimensionId,Attribute,AttributeDimension,AttributeId,DimensionName,MemberId,MemberName,MemberRefnum,ParentReference,ParentId) 
	VALUES 
	(0,null,null,null,'',0,'All','All','',0)
INSERT INTO ods.TD_SOEM_ABM_dimmember 
	(DimensionId,Attribute,AttributeDimension,AttributeId,DimensionName,MemberId,MemberName,MemberRefnum,ParentReference,ParentId) 
	VALUES 
	(0,null,null,null,'',1,'None','None','',0)
/*
Opdater attribut ID med reference til attribut af samme type
*/
UPDATE ods.TD_SOEM_ABM_dimmember SET AttributeId=(SELECT TOP 1 a.MemberId FROM ods.TD_SOEM_ABM_dimmember a WHERE ods.TD_SOEM_ABM_dimmember.Attribute=a.MemberRefnum and
		ods.TD_SOEM_ABM_dimmember.AttributeDimension=a.Dimensionname)
--####################### DRIVER DIMENSION ######################
/*
Opret temp tabel med source drivere
*/
IF object_id('tempdb..#driver_source') is not null DROP TABLE #driver_source
SELECT *
INTO #driver_source
FROM
(select SourceReference,DriverName,Periode from dbo.ABC_G_SDL_Activities
union all
select SourceReference,DriverName,Periode from dbo.ABC_G_SDL_Ressourcer
) driver_source

/*
Opret temp tabel med destination drivere og summer driverværdi
*/
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

/*
Opret temp tabel med source og destionations reference på driver joined på drivernavn og periode
*/
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

/*
Tilføj evenly assigned driver
*/
INSERT INTO #driver
SELECT *
FROM
(select 'Evenly Assigned' DriverName,SourceReference,DestReference,1 DriverQuantityFixed,1 sumDriverQuantityFixed,Periode from dbo.ABC_G_EA_Activities 
union all
select 'Evenly Assigned' DriverName,SourceReference,DestReference,1 DriverQuantityFixed,1 sumDriverQuantityFixed,Periode from dbo.ABC_G_EA_Ressourcer
) driver_event_assigned

/*
Opret temp tabel med cost elementer og grupper og summer cost element
cost element*/
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

/*
1. beregning. Beregner forholdstallet på drivere (også "Evenly Assigned") driverværdi på enkelte driver/summen af driverværdi (beregnet tidligere) 
R1 -> R2
R1 -> A1
R1 -> A4
R1 -> (C1) 
*/
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

/*
2. beregning, som ovenstående, men på næste niveau af resultatet (destination) af 1. kørsel
R2 -> A1
A1 -> A4 
A4 -> C1
*/
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

/*
3. beregning, se 2. beregning
A1 -> A4
A4 -> C1
*/
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

/*4. og sidste beregning, se 2. beregning
A4 -> C1
*/
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
/*
Opret midlertidig ABM tabel og summer cost 
*/
IF object_id('[ods].[TD_SOEM_ABM]') is not null DROP TABLE [ods].[TD_SOEM_ABM]
SELECT 
	Model,
	SourceReference SourceRefnum,
	DestReference DestRefnum,
	Periode PeriodRefnum,
	SUM(CalcCost) FixedCost, 
	'Aktual' as ScenarioRefnum,
	Case when substring(SourceReference,1,1)='E' then substring(reverse(SourceReference),6,1) else NULL end as Artgrp,
	DriverName
INTO [ods].[TD_SOEM_ABM] 
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
GROUP BY tmp_TD_SOEM_ABM.Model,tmp_TD_SOEM_ABM.SourceReference,tmp_TD_SOEM_ABM.DestReference,tmp_TD_SOEM_ABM.Periode,tmp_TD_SOEM_ABM.DriverName

END
