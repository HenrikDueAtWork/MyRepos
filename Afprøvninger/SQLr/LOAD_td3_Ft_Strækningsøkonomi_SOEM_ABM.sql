USE [MDW_test07]
GO
/****** Object:  StoredProcedure [etl].[LOAD_td3_Ft_Strækningsøkonomi_SOEM_ABM]    Script Date: 10-12-2015 13:48:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


alter proc [etl].[LOAD_td3_Ft_Strækningsøkonomi_SOEM_ABM]  @model varchar(50) = 'M1140', @periode varchar(50) = '201511'--, @sasabmmodelsdatabase sysname = 'SASABMMODELS_TEST05'
as
begin 
set  nocount on



select @model = upper(@model)
print 'Model: '+@model
print 'Periode: '+@periode
declare @model_id int
declare @aktiv bit

--TEST
--insert into adhoc.test_modelogperiode select  @model as model, @periode as periode 
--return

if not exists (select 'x' from edw.dim_model b where b.model  = @model and b.år = @periode)
begin
	insert into edw.dim_model  (model, år, aktiv) select @model, @periode, 1 
	update edw.dim_model set aktiv = 0 where år = @periode and model <> @model
	update edw.dim_model set periode = år, dataserie = 'R' where model  = @model and år = @periode
end 
else
begin
	update edw.dim_model set aktiv = 1 where år = @periode and model = @model and aktiv <> 1
end

--Opdatere UnaryOperator så nyeste periode for hvert år (substring(periode,1,4)) får '+', hvilket betyder, at de medtages i total for året. Andre (tidligere) perioder får '~', hvilket betyder at de ikke medregnes i total

update edw.dim_model 
set UnaryOperator = '+' 
where periode in (select max(periode) from edw.dim_Model group by substring(Periode,1,4)) 
		and aktiv = 1

update edw.dim_model 
set UnaryOperator = '~' 
where periode not in (select max(periode) from edw.dim_Model group by substring(Periode,1,4))
		or aktiv = 0

select @model_id = pk_id, @aktiv = aktiv from edw.dim_model where model = @model and år = @periode

print 'Model_Id: '+convert(varchar(9),@model_id)
print 'Aktiv: '+convert(char(1),@aktiv)
--select * from edw.dim_model
--exec script_table 'ods.td_Mxxxx_costelement'

 
------------ Hent @model+_dimension fra SASABMMODELS ------------ 
/*ERSTATTET AF SOEM_ABM*/

--IF object_id('ods.td_Mxxxx_dimension') is not null
--DROP TABLE ods.td_Mxxxx_dimension
 
--CREATE TABLE ods.td_Mxxxx_dimension(
--	[Id] int NULL,
--	[Name] varchar(64) NULL,
--	[OdbcColumnName] varchar(64) NULL,
--	[Refnum] varchar(64) NULL,
--	[ShortRefnum] varchar(18) NULL,
--	[Icon] int NULL,
--	[Description] text NULL
--)

--exec ('insert into ods.td_Mxxxx_dimension select [Id],[Name],[OdbcColumnName],[Refnum],[Refnum] as [ShortRefnum],[Icon],[Description] from '+@sasabmmodelsdatabase+'.dbo.'+@model+'_dimension' )
--select * from ods.td_Mxxxx_dimension



--IF object_id('ods.td_Mxxxx_dimmember') is not null
--DROP TABLE ods.td_Mxxxx_dimmember

--CREATE TABLE ods.td_Mxxxx_dimmember(
--	[Id] int NULL,
--	[DimensionId] int NULL,
--	[ParentId] int NULL,
--	[Name] varchar(64) NULL,
--	[Refnum] varchar(64) NULL,
--	[LevelId] smallint NULL,
--	[DisplayOrder] float NULL
--)
--exec ('insert into ods.td_Mxxxx_dimmember select * from '+@sasabmmodelsdatabase+'.dbo.'+@model+'_dimmember' )

--IF object_id('ods.td_SASABMMODELSDYN_PeriodDefinition') is not null
--DROP TABLE [ods].[td_SASABMMODELSDYN_PeriodDefinition]


--CREATE TABLE [ods].[td_SASABMMODELSDYN_PeriodDefinition](
--	[Id] [smallint]  NOT NULL,
--	[Name] [nvarchar](64) NULL,
--	[ParentId] [smallint] NULL,
--	[LevelId] [smallint] NULL,
--	[StartDate] [smalldatetime] NULL,
--	[EndDate] [smalldatetime] NULL,
--	[Description] [ntext] NULL,
--	[Refnum] [nvarchar](256) NULL
--) 

--exec ('insert into ods.td_SASABMMODELSDYN_PeriodDefinition select * from '+@sasabmmodelsdatabase+'.dbo.PeriodDefinition' )


------------------------------------------------------------------------------------------------
--	Flyt accountcenter ods.td0_Mxxxx_AccountCenter tabel over i 
--	ny tabel ods.td_Mxxxx_AccountCenter, hvor dim1001, dim1002 osv. bliver
--	erstattet af kolonner, der er navngivet ud fra dimensionsnavnet (Activity,
--  CostObject,ExternalUnit,MængdeEnhed,Resource,DRIVER,PRODAKT,PRODVAR,RESVAR,...)

--declare @dimension varchar(max)
--select @dimension =  isnull(@dimension+',','')+ name from syscolumns where id = object_id('ods.td0_Mxxxx_AccountCenter') and name not like 'dim1%'
--select @dimension =  coalesce(@dimension+',','') + ' Dim'+convert(varchar(10), id) collate Danish_Norwegian_CI_AS + ' as ' +quotename(name,'''') from ods.td_Mxxxx_dimension a 
--declare @sql varchar(max)

/*ERSTATTET AF [ods].[TD_SOEM_ABM]*/
--if object_id('tempdb..#TD_delmodel_costelement') is not null drop table #TD_delmodel_costelement
--select 
--		a.FixedCost,
--		Case when a.Refnum is null then b.Refnum else a.Refnum end as SourceRefnum,
--		c.Refnum as DestRefnum, 
--        d.Refnum as PeriodRefnum,
--		'Aktual' as ScenarioRefnum,
--		Case when substring(a.Refnum,1,1)='E' then substring(reverse(a.Refnum),6,1) else NULL end as Artgrp
--into 
--		#TD_delmodel_costelement
--from	
--		ods.td_Mxxxx_costelement a
--			left join 
--		ods.td_Mxxxx_AccountCenter b on a.sourceId = b.Id  
--			left join 
--		ods.td_Mxxxx_AccountCenter c on a.DestinationId = c.Id
--			left join 
--		[ods].[td_SASABMMODELSDYN_PeriodDefinition] d on a.PeriodId = d.Id
--order by 
--		sourcerefnum


--2
if object_id('tempdb..#totaldest') is not null drop table #totaldest

SELECT DISTINCT 
	ce.destrefnum,
	Sum(ce.FixedCost) AS TotalDestinationCost 
INTO 
	#totaldest  
FROM 
	[ods].[TD_SOEM_ABM] ce
GROUP BY 
	ce.destrefnum

--3
if object_id('tempdb..#Assignment') is not null drop table #Assignment
SELECT 
	ce.destrefnum,
	ce.sourcerefnum,
	ce.Periodrefnum,
	ce.scenariorefnum,
	ce.artgrp,
	ce.FixedCost,
	td.TotalDestinationCost,
	case when td.TotalDestinationCost = 0 then 0 else ce.FixedCost/td.TotalDestinationCost end as Andel
INTO 
	#Assignment
FROM 
	[ods].[TD_SOEM_ABM] ce
left join
	#totaldest td ON convert(varchar(50),td.destrefnum) collate Danish_Norwegian_CI_AS =ce.destrefnum
WHERE 
	ce.FixedCost NOT in (0)

--4
/*danner niveau 0 Costelement og niveau 1*/
if object_id('tempdb..#data1') is not null drop table #data1

SELECT ast.sourcerefnum as level0,
ast.destrefnum as level1,
ast.Periodrefnum,
ast.Scenariorefnum,
ast.artgrp,
ast.FixedCost as destcost,
ast.andel
INTO #data1
FROM #assignment ast
WHERE substring(ast.sourcerefnum,1,1)='E'
if object_id('tempdb..#data2') is not null drop table #data2
/*danner niveau 2*/
SELECT 
#data1.level0,
#data1.level1,
#data1.andel*ast.andel as nextandel,
ast.destrefnum as level2,
ast.Periodrefnum,
ast.Scenariorefnum,
#data1.artgrp,
ast.FixedCost,
ast.andel,
ast.fixedcost*#data1.Andel as Destcost
INTO #data2
FROM #data1
left join 
#assignment ast
ON
#data1.level1= ast.sourcerefnum

/*danner niveau 3*/
if object_id('tempdb..#data3') is not null drop table #data3
SELECT
#data2.level0,
#data2.level1,
#data2.level2,
#data2.nextandel*ast.andel as nextandel,
ast.destrefnum as level3,
ast.Periodrefnum,
ast.Scenariorefnum,
#data2.artgrp,
ast.FixedCost,
ast.andel,
ast.fixedcost*#data2.nextAndel as Destcost
INTO #data3
FROM #data2
left join 
#assignment ast
ON
#data2.level2= ast.sourcerefnum

/*danner niveau 4 */
if object_id('tempdb..#data4') is not null drop table #data4
SELECT
#data3.level0, 
#data3.level1,
#data3.level2,
#data3.level3,
#data3.artgrp,
ast.destrefnum as level4,
#data3.Periodrefnum,
#data3.Scenariorefnum,
ast.FixedCost,
ast.andel,
#data3.nextandel*ast.andel as nextandel,
Destcost=
CASE 
	WHEN ast.FixedCost IS NULL THEN #data3.destcost
    else
         ast.fixedcost*#data3.nextandel 
END
INTO #data4
FROM #data3
left join 
#assignment ast
ON
#data3.level3= ast.sourcerefnum

/*danner niveau 5*/
if object_id('tempdb..#data5') is not null drop table #data5
SELECT
#data4.level0,
#data4.level1,
#data4.level2,
#data4.level3,
#data4.level4,
#data4.artgrp,
ast.destrefnum as level5,
#data4.Periodrefnum,
#data4.Scenariorefnum,
ast.andel,
#data4.nextandel*ast.andel as nextandel,
ast.FixedCost,
Destcost=
CASE 
	WHEN ast.FixedCost IS NULL THEN #data4.destcost
    else
         ast.fixedcost*#data4.nextandel 
END
INTO #data5
FROM #data4
left join 
#assignment ast
ON
#data4.level4= ast.sourcerefnum

/*danner niveau 6*/
if object_id('tempdb..#data6') is not null drop table #data6
SELECT 
#data5.level0,
#data5.level1,
#data5.level2,
#data5.level3,
#data5.level4,
#data5.level5,
#data5.artgrp,
ast.destrefnum as level6,
#data5.Periodrefnum,
#data5.Scenariorefnum,
ast.andel,
#data5.nextandel*ast.andel as nextandel,
ast.FixedCost,
Destcost=
CASE 
	WHEN ast.FixedCost IS NULL THEN #data5.destcost
    else
		ast.fixedcost*#data5.nextandel 
END
INTO #data6
FROM #data5
left join 
#assignment ast
ON
#data5.level5= ast.sourcerefnum




/*
danner niveau 7*/
if object_id('tempdb..#data7') is not null drop table #data7
SELECT
#data6.level0,
#data6.level1,
#data6.level2,
#data6.level3,
#data6.level4,
#data6.level5,
#data6.level6,
#data6.artgrp,
ast.destrefnum as level7,
#data6.Periodrefnum,
#data6.Scenariorefnum,
ast.andel,
#data6.nextandel*ast.andel as nextandel,
ast.FixedCost,
Destcost=
CASE 
	WHEN ast.FixedCost IS NULL THEN #data6.destcost
    else
		ast.fixedcost*#data6.nextandel 
END,
@model as Model,
@model_id as Model_Id
INTO #data7
FROM #data6
left join 
#assignment ast
ON
#data6.level6= ast.sourcerefnum
--select dbo.getRessource_2013(2,'R2_6161860', null, null, null, null, null)
--select * from #data7

--select top 100 * from ods.x order by level1, level2, level3

if object_id('ods.td1_ft_strækningsøkonomi_SOEMABM') is not null drop table ods.td1_ft_strækningsøkonomi_SOEMABM

select 
	level0,
	'R1Refnum' = level1,
	'R2Refnum' = dbo.getRessource_2013(2, level2, null, null, null, null, null),
	'A1Refnum' = dbo.getActivity_2013(1, level2, null, null, null,null,null),
	'A2Refnum' = dbo.getActivity_2013(2, level2, null, null, null,null,null),
	'A3Refnum' = dbo.getActivity_2013(3, level2, null, null, null,null,null),
	'A4Refnum' = dbo.getActivity_2013(4, level2, null, null, null,null,null),
	artgrp,
	'Co1Refnum' = level3,
   -- level3 As Co1Refnum,
	Periodrefnum,
	Scenariorefnum,
	andel,
	nextandel,
	FixedCost,
	Destcost,
	Model,
	Model_Id
into 
	ods.td1_ft_strækningsøkonomi_SOEMABM
from 
	#data7 
where 
	level3 is not null and level4 is null
union all
select 
	level0,
	'R1Refnum' = level1,
	'R2Refnum' = dbo.getRessource_2013(2, level2, null, null, null, null, null),
	'A1Refnum' = dbo.getActivity_2013(1, level2, level3, null, null,null,null),
	'A2Refnum' = dbo.getActivity_2013(2, level2, level3, null, null,null,null),
	'A3Refnum' = dbo.getActivity_2013(3, level2, level3, null, null,null,null),
	'A4Refnum' = dbo.getActivity_2013(4, level2, level3, null, null,null,null),
	artgrp,
	'Co1Refnum' = level4,
    --level4 As Co1Refnum,
	Periodrefnum,
	Scenariorefnum,
	andel,
	nextandel,
	FixedCost,
	Destcost,
	Model,
	Model_Id
from 
	#data7
where 
	level4 is not null and level5 is null
union all
select
	level0,
	'R1Refnum' = level1,
	'R2Refnum' = dbo.getRessource_2013(2, level2, null, null, null, null, null),
	'A1Refnum' = dbo.getActivity_2013(1, level2, level3, level4, null,null,null),
	'A2Refnum' = dbo.getActivity_2013(2, level2, level3, level4, null,null,null),
	'A3Refnum' = dbo.getActivity_2013(3, level2, level3, level4, null,null,null),
	'A4Refnum' = dbo.getActivity_2013(4, level2, level3, level4, null,null,null),
	artgrp,
	'Co1Refnum' = level5,
	--level5 As Co1Refnum,
	Periodrefnum,
	Scenariorefnum,
	andel,
	nextandel,
	FixedCost,
	Destcost,
	Model,
	Model_Id
from 
	#data7 
where 
	level5 is not null and level6 is null
union all
select 
	level0,
	'R1Refnum' = level1,
	'R2Refnum' = dbo.getRessource_2013(2, level2, null, null, null, null, null),
	'A1Refnum' = dbo.getActivity_2013(1, level2, level3, level4, level5,null,null),
	'A2Refnum' = dbo.getActivity_2013(2, level2, level3, level4, level5,null,null),
	'A3Refnum' = dbo.getActivity_2013(3, level2, level3, level4, level5,null,null),
	'A4Refnum' = dbo.getActivity_2013(4, level2, level3, level4, level5,null,null),
	artgrp,
	'Co1Refnum' = level6,
    --level6 As Co1Refnum,
	Periodrefnum,
	Scenariorefnum,
	andel,
	nextandel,
	FixedCost,
	Destcost,
	Model,
	Model_Id
from 
	#data7 
where 
	level6 is not null and level7 is null
union all
select 
	level0,
	'R1Refnum' = level1,
	'R2Refnum' = dbo.getRessource_2013(2, level2, null, null, null, null, null),
	'A1Refnum' = dbo.getActivity_2013(1, level2, level3, level4, level5,level6,null),
	'A2Refnum' = dbo.getActivity_2013(2, level2, level3, level4, level5,level6,null),
	'A3Refnum' = dbo.getActivity_2013(3, level2, level3, level4, level5,level6,null),
	'A4Refnum' = dbo.getActivity_2013(4, level2, level3, level4, level5,level6,null),
	artgrp,
	'Co1Refnum' = level7,
--  level7 As Co1Refnum,
	Periodrefnum,
	Scenariorefnum,
	andel,
	nextandel,
	FixedCost,
	Destcost,
	Model,
	Model_Id
from 
	#data7 
where 
	level7 is not null
-- Unassigned (Maries request)
union all
select 
	level0,
	'R1Refnum' = level1,
	'R2Refnum' = dbo.getRessource_2013(2, level2, null, null, null, null, null),
	'A1Refnum' = dbo.getActivity_2013(1, level2, level3, null, null,null,null),
	'A2Refnum' = dbo.getActivity_2013(2, level2, level3, null, null,null,null),
	'A3Refnum' = dbo.getActivity_2013(3, level2, level3, null, null,null,null),
	'A4Refnum' = dbo.getActivity_2013(4, level2, level3, null, null,null,null),
	artgrp,
	'Co1Refnum' = level4,
	Periodrefnum,
	Scenariorefnum,
	andel,
	nextandel,
	FixedCost,
	Destcost,
	Model,
	Model_Id
from 
	#data7
where 
	level3 is null and level4 is null and level5 is null and level6 is null and level7 is null 
/*CREATE TABLE [ods].[Key_Dim_Member](
	[Pk_Key] [int] IDENTITY(1,1) NOT NULL,
	[DimensionName] [varchar](256) NULL,
	[MemberRefnum] [varchar](256) NULL,
	[Created] [datetime] NULL DEFAULT (getdate())
) ON [PRIMARY]
*/
create clustered index co1refnum on ods.td1_ft_strækningsøkonomi_SOEMABM (co1refnum)
create index a1refnum on ods.td1_ft_strækningsøkonomi_SOEMABM (a1refnum)
create index a2refnum on ods.td1_ft_strækningsøkonomi_SOEMABM (a2refnum)
create index a3refnum on ods.td1_ft_strækningsøkonomi_SOEMABM (a3refnum)
create index a4refnum on ods.td1_ft_strækningsøkonomi_SOEMABM (a4refnum)
create index r1refnum on ods.td1_ft_strækningsøkonomi_SOEMABM (r1refnum)
create index r2refnum on ods.td1_ft_strækningsøkonomi_SOEMABM (r2refnum)

insert into ods.key_dim_member (dimensionname, memberrefnum)
select 
	a.DimensionName as Dimensionname,
	b.MemberRefnum as MemberRefnum
from 
	ods.TD_SOEM_ABM_dimension a
		inner join 
	ods.TD_SOEM_ABM_dimmember b on a.DimensionId = b.dimensionid
except 
select 
	dimensionname, 
	memberrefnum
from 
	ods.key_dim_member


--Indsæt nye rækker
--OBS ods.dim_dimensionmembers har identity(1,1) kolonne (pk_key)



delete from ods.dimmember_union_all_alle_modeller where model_id = @model_id 

insert into ods.dimmember_union_all_alle_modeller
(
Model_Id,
DimensionId,
Dimensionname,
MemberId,
MemberKey,
ParentId,
ParentKey,
MemberName,
MemberRefnum,
--MemberLevelId, HDJ
--MemberDisplayOrder, HDJ
Drivername
)
select distinct
	@model_id,
	Dimension.dimensionid as DimensionId,
	Dimension.Dimensionname as Dimensionname,
	--Dimension.OdbcColumnName,
	--Dimension.Refnum,
	--Dimension.Icon,
	--Dimension.Description,
	Member.memberid as MemberId, 
	k.pk_key as MemberKey,
	Member.ParentId,
	kparent.pk_key as ParentKey,
	Member.MemberName as MemberName,
	Member.MemberRefnum as MemberRefnum,
	--Member.levelId as MemberLevelId, HDJ
	--Member.DisplayOrder as MemberDisplayOrder, HDJ
	account.Drivername 
from 
	ods.TD_SOEM_ABM_dimension dimension
		inner join 
	ods.TD_SOEM_ABM_dimmember Member on Dimension.dimensionid = Member.dimensionid
		left outer join
	ods.TD_SOEM_ABM_dimmember MemberParent on Dimension.dimensionid = MemberParent.dimensionid and Member.parentid = MemberParent.memberid
		left outer join 
	ods.key_dim_member k on Dimension.Dimensionname = k.Dimensionname and Member.memberrefnum = k.memberrefnum
		left outer join
	ods.key_dim_member kParent on Dimension.Dimensionname = kParent.Dimensionname and MemberParent.memberrefnum = kParent.memberrefnum
		left outer join 
	[ods].[TD_SOEM_ABM] account on member.memberrefnum = account.Sourcerefnum


--indsæt nye


insert into [edw].[dim_member]
(PK_Key,
Parent_key,
Dimensionname,
MemberName,
MemberRefnum,
MemberLevelId,
MemberDisplayOrder,
Drivername
)
select
m.memberkey,
m.parentkey,
m.Dimensionname,
m.MemberName,
m.MemberRefnum,
m.MemberLevelId,
m.MemberDisplayOrder,
m.Drivername
from 
		ods.dimmember_union_all_alle_modeller m
			left outer join 
		[edw].[dim_member] f on m.Dimensionname = f.Dimensionname and m.memberrefnum = f.memberrefnum 
where 
	f.Dimensionname is null --tilfældig kolonne (der ikke kan være null), blot for at kontrollere at række ikke findes i forvejen i f


--opdater eksisterende
update f
set  f.membername = m.membername,
	f.MemberLevelId = m.MemberLevelId,
	f.MemberDisplayOrder = m.MemberDisplayOrder,
	f.Parent_Key = m.parentkey,
	f.Drivername = m.Drivername
	
from 
		[edw].[dim_member] f
			left outer join 
		ods.dimmember_union_all_alle_modeller m on m.Dimensionname = f.Dimensionname and m.memberrefnum = f.memberrefnum 
where 
	m.model_id = @model_id and
	(f.MemberName <> m.MemberName or
	--f.MemberLevelId <> m.MemberLevelId or
	--f.MemberDisplayOrder <> m.MemberDisplayOrder or
	isnull(f.parent_key,'') <>  isnull(m.parentkey,'') or
	isnull(f.Drivername,'') <> isnull(m.Drivername,''))
	

insert into edw.dim_member (pk_key, dimensionname)
select distinct -1, dimensionname from edw.dim_member
except 
select pk_key, dimensionname from edw.dim_member where pk_key = -1

Insert into edw.dim_member_slettede (
	[PK_Key],
	[DimensionName],
	[MemberName],
	[MemberRefnum],
	[MemberLevelId],
	[MemberDisplayOrder],
	[Parent_Key],
	[Drivername],
	[indlæstTidspunkt],
	[indlæstAf],
	[opdateretTidspunkt],
	[opdateretAf]
)
SELECT 
 [PK_Key],   ---PK_Key
 [DimensionName],   ---DimensionName
 [MemberName],   ---MemberName
 [MemberRefnum],   ---MemberRefnum
 [MemberLevelId],   ---MemberLevelId
 [MemberDisplayOrder],   ---MemberDisplayOrder
 [Parent_Key],   ---Parent_Key
 [Drivername],   ---Drivername
 [indlæstTidspunkt],   ---indlæstTidspunkt
 [indlæstAf],   ---indlæstAf
 [opdateretTidspunkt],   ---opdateretTidspunkt
 [opdateretAf]   ---opdateretAf
From
	edw.dim_member dim
where 
	dim.memberrefnum not in (select memberrefnum from ods.dimmember_union_all_alle_modeller)
	
delete from edw.dim_member
where 
	memberrefnum not in (select memberrefnum from ods.dimmember_union_all_alle_modeller)



--tjek at dim_member og dim_member_model ikke er ud af sync på pk_key
if object_id('tempdb..#fejl') is not null drop table #fejl
select 'Fejl pk_key <> pk_key' as Fejlbeskrivelse, f.Dimensionname, f.memberrefnum  
into #fejl
from edw.dim_member f
		inner join 
ods.dimmember_union_all_alle_modeller m on  m.Dimensionname = f.Dimensionname and m.memberrefnum = f.memberrefnum 
where m.memberkey <> f.pk_key
if @@rowcount > 0 select * from #fejl




--lav tabel til opslag af pk_key med rækker kun for den aktuelle model af hensyn til performance
if object_id('tempdb..#tempdimfælles') is not null drop table #tempdimfælles
select fælles.memberrefnum, fælles.Dimensionname, fælles.memberkey as k, fælles.memberid as id
into #tempdimfælles
from ods.dimmember_union_all_alle_modeller fælles where model_id =  @model_id


--declare @model_id int 
--set @model_id = 4
if object_id('ods.td3_Ft_Strækningsøkonomi_SOEMABM') is not null drop table ods.td3_Ft_Strækningsøkonomi_SOEMABM --Skal 
select DISTINCT --############################## ER IKKE HELT GLAD FOR DISTINCT HER
	f.Model_id,
	f.Destcost * convert(float,-1) as Destcost,
	isnull(r1.k, -1) as resource1_key,
	isnull(r2.k, -1) as resource2_key,
	isnull(a1.k, -1) as activity1_key,
	isnull(a2.k, -1) as activity2_key,
	isnull(a3.k, -1) as activity3_key,
	isnull(a4.k, -1) as activity4_key,
	isnull(c1.k, -1) as costobject1_key,
	isnull(ATTressourcetype.k, -1) as attRessourcetype_key,
	isnull(ATTFunkkunde.k, -1) as attFunktionskunde_key,
	isnull(ATTSegment.k, -1) as AttSegment_key,
	isnull(ATTProduktaktivitetsgruppe.k, -1) as AttProduktaktivitetsgruppe_key,
	isnull(ATTProduktVariabilitet.k, -1) as AttProduktVariabilitet_key,
	isnull(ATTProduktLitra.k, -1) as AttProduktLitra_key,
	isnull(ATTTogsystem.k, -1) as AttTogsystem_key,
	right(level0,1) as CEArt

into 
	ods.td3_Ft_Strækningsøkonomi_SOEMABM
from 
 	ods.td1_ft_strækningsøkonomi_SOEMABM f
		left outer join 
	#tempdimfælles r1								on f.r1refnum = r1.memberrefnum 
		left outer join 
	[ods].td_soem_abm_dimmember r1att				on f.r1refnum = r1att.memberrefnum and r1att.attributedimension='ressourcetyp' -- refnum  ---for at få link til attributten ressourcetype
		left outer join 
	#tempdimfælles r2								on f.r2refnum = r2.memberrefnum
		left outer join 
	#tempdimfælles a1								on f.a1refnum = a1.memberrefnum
		left outer join 
	[ods].td_soem_abm_dimmember a1Att				on f.a1refnum = a1Att.memberrefnum and a1att.AttributeDimension='Funktionskun' ---for at få link til attributten Funktionskunde
		left outer join 
	#tempdimfælles a2								on f.a2refnum = a2.memberrefnum
		left outer join 
	#tempdimfælles a3								on f.a3refnum = a3.memberrefnum
		left outer join 
	#tempdimfælles a4								on f.a4refnum = a4.memberrefnum
		left outer join 
	[ods].td_soem_abm_dimmember a4AttSeg				on f.a4refnum = a4AttSeg.memberrefnum and a4attSeg.AttributeDimension='Segment'  ---for at få link til attributterne Segment og Produktaktivitetsgruppe
		left outer join 
	[ods].td_soem_abm_dimmember a4AttGrp				on f.a4refnum = a4AttGrp.memberrefnum and a4AttGrp.AttributeDimension='ProdGruppe'
		left outer join 
	[ods].td_soem_abm_dimmember a4AttVar				on f.a4refnum = a4AttVar.memberrefnum and a4AttVar.AttributeDimension='Produktvaria'
		left outer join 
	[ods].td_soem_abm_dimmember a4AttLit				on f.a4refnum = a4AttLit.memberrefnum and a4AttLit.AttributeDimension='Produktlitra'
		left outer join 
	#tempdimfælles c1								on f.co1refnum = c1.memberrefnum
		left outer join 
	[ods].td_soem_abm_dimmember c1Att				on f.co1refnum = c1Att.memberrefnum and c1att.AttributeDimension='Togsystem'	---for at få link til attributten Togsystem
		left outer join
	#tempdimfælles ATTressourcetype					on ATTressourcetype.id = r1Att.AttributeId 
		left outer join
	#tempdimfælles ATTFunkkunde						on ATTFunkkunde.id = a1Att.AttributeId
		left outer join
	#tempdimfælles ATTSegment						on ATTSegment.id = a4AttSeg.AttributeId
		left outer join
	#tempdimfælles ATTProduktaktivitetsgruppe		on ATTProduktaktivitetsgruppe.id = a4AttGrp.AttributeId
		left outer join
	#tempdimfælles ATTProduktVariabilitet			on ATTProduktVariabilitet.id = a4AttVar.AttributeId
		left outer join
	#tempdimfælles ATTProduktLitra					on ATTProduktLitra.id = a4AttLit.AttributeId
		left outer join
	#tempdimfælles ATTTogsystem						on ATTTogsystem.id = c1Att.AttributeId
	




goto theend 



theend:



end --proc
