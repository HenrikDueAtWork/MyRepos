/****** Script for SelectTopNRows command from SSMS  ******/
use MDW_test06
/*drivers*/
declare @drvlist table (
	DriverName varchar(256),
	DestRefnum varchar(256),
	DriverQuantityFixed float,
	Periode varchar(50),
	sumDriverQuantityFixed float)

insert into @drvlist
select SourceReference,DestReference,1,Periode,1 as sumDriverQuantityFixed from dbo.ABC_G_EA_Activities
union all
select SourceReference,DestReference,1,Periode,1 as sumDriverQuantityFixed  from dbo.ABC_G_EA_Ressourcer
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed from dbo.ABC_R_DR_Baneafgifter_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_Lokoførertid_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed from dbo.ABC_R_DR_Lokoførertid_STog
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_Manuelle
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_Moms
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_PersonaleData
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_RejserIndtægter_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_RejserIndtægter_Stog
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_RejserIndtægter_Togsystem_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_Togførertid_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_Togproduktion_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_Togproduktion_Stog
--select * from @drvlist where DriverQuantityFixed is null
delete from @drvlist where DriverQuantityFixed is null

declare @drvlist_2 table (
	DriverName varchar(256),
	DestRefnum varchar(256),
	DriverQuantityFixed float,
	Periode varchar(50),
	sumDriverQuantityFixed float)

insert into @drvlist_2
--select SourceReference,DestReference,1,Periode,1 as sumDriverQuantityFixed from dbo.ABC_G_EA_Activities
--union all
--select SourceReference,DestReference,1,Periode,1 as sumDriverQuantityFixed  from dbo.ABC_G_EA_Ressourcer
--union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed from dbo.ABC_R_DR_Baneafgifter_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_Lokoførertid_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed from dbo.ABC_R_DR_Lokoførertid_STog
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed  from dbo.ABC_R_DR_Manuelle
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_Moms
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_PersonaleData
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_RejserIndtægter_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_RejserIndtægter_Stog
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_RejserIndtægter_Togsystem_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_Togførertid_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_Togproduktion_FR
union all
select DriverName,DestReference,DriverQuantityFixed,Periode,sum(DriverQuantityFixed) over (partition by drivername, periode) as sumDriverQuantityFixed   from dbo.ABC_R_DR_Togproduktion_Stog
--select * from @drvlist where DriverQuantityFixed is null
-- delete from @drvlist where DriverQuantityFixed is null

/*queries ikke fuldstændige*/

declare @r1 table (
	Cost float,
	Refnum varchar(256),
	Periode varchar(50))

insert into @r1

select sum(der_R1.EnteredCost) Cost,AccountReference,Periode from
(
SELECT
	EnteredCost,
	AccountReference,
	Periode
FROM [dbo].[ABC_R_CE_anlæg]
union all
SELECT
	EnteredCost,
	AccountReference,
	Periode
FROM [dbo].[ABC_R_CE_Drift]
) der_R1
where der_R1.Periode=201510
group by der_R1.AccountReference,der_R1.Periode
--select * from @r1

select-- top 10
	r1.Cost level0Cost,
	--drv.DriverName,drvl.DriverName,
	--drvl.DriverQuantityFixed,
	drvl_1.DestRefnum level1drv,
	--sum(cost) over (partition by Refnum) as Costsum,
	--drvl.DriverQuantityFixed/(drvl.sumDriverQuantityFixed) calcdrv,
	(Cost)*(drvl_1.DriverQuantityFixed/drvl_1.sumDriverQuantityFixed) level2calcCost
	,drv_1.DriverName
from @r1 r1
join [dbo].[ABC_G_SDL_Ressourcer] drv on r1.Refnum=drv.SourceReference and r1.Periode=drv.Periode --and r1.Periode=201510
join @drvlist drvl_1 on drv.DriverName=drvl_1.DriverName and r1.Periode=drvl_1.Periode and substring(drvl_1.DestRefnum,1,2)='R2'
left join [dbo].[ABC_G_SDL_Ressourcer] drv_1 on drvl_1.DestRefnum=drv_1.SourceReference and drvl_1.Periode=drv_1.Periode
--join @drvlist_2 drvl_2 on drv_1.DriverName=drvl_2.DriverName and drv_1.Periode=drvl_2.Periode
--order by r1.Refnum

/*
declare @r1tilr2 table (
	SourceRefnum varchar(256),
	Periode varchar(50),
	DestRefnum varchar(256))

insert into @r1tilr2
select
	r1.Refnum,
	r1.Periode,
	coalesce(r2.DestReference,r1.Refnum)
from @r1 r1
left join [dbo].[ABC_G_EA_Ressourcer] r2 on r1.Refnum=r2.SourceReference and r1.Periode=r2.Periode where r1.Refnum='R1_59050001000_U'


--select * from @r1tilr2

declare @r2tildrv1 table (
	SourceRefnum varchar(256),
	Periode varchar(50),
	DestRefnum varchar(256))

insert into @r2tildrv1
select
	r2.DestRefnum,
	r2.Periode,
	drv.DriverName

from @r1tilr2 r2
join [dbo].[ABC_G_SDL_Ressourcer] drv on r2.DestRefnum=drv.SourceReference and r2.Periode=drv.Periode
select * from @r2tildrv1

declare @drv1tila1 table (
	SourceRefnum varchar(256),
	Periode varchar(50),
	DestRefnum varchar(256),
	DriverQuantityFixed float)

insert into @drv1tila1
select 
	drv1.DestRefnum,
	drv1.Periode,
	a1.DestReference,
	a1.DriverQuantityFixed
from @r2tildrv1 drv1
join ABC_R_DR_Moms a1 on drv1.DestRefnum=a1.DriverName and drv1.Periode=a1.Periode
select * from @drv1tila1 where DestRefnum='A1_1350111'

declare @a1tila4 table (
	SourceRefnum varchar(256),
	Periode varchar(50),
	DestRefnum varchar(256),
	DriverQuantityFixed float)

insert into @a1tila4
select 
	a1.DestRefnum,
	a1.Periode,
	a4.DestReference,
	a1.DriverQuantityFixed
from @drv1tila1 a1
join dbo.ABC_G_EA_Activities a4 on a1.DestRefnum=a4.SourceReference and a1.Periode=a4.Periode
select * from @a1tila4 where SourceRefnum='A1_1350111'

declare @a4tilc1 table (
	SourceRefnum varchar(256),
	Periode varchar(50),
	DestRefnum varchar(256),
	DriverQuantityFixed float)

insert into @a4tilc1
select
	a4.DestRefnum,
	a4.Periode,
	c1.DestReference,
	a4.DriverQuantityFixed
from @a1tila4 a4
join dbo.ABC_G_EA_Activities c1 on  a4.DestRefnum=c1.SourceReference and a4.Periode=c1.Periode
select * from @a4tilc1 where SourceRefnum='A4_4630111'

select * from 
(
	select r1.Periode,r1.Refnum R1ref,r2.DestRefnum R2ref,drv.DestRefnum DRVref,a1.DestRefnum A1ref,a4.DestRefnum A4ref,c1.DestRefnum C1ref,c1.DriverQuantityFixed from @r1 r1 
	join @r1tilr2 r2 on r1.Refnum=r2.SourceRefnum and r1.Periode=r2.Periode
	join @r2tildrv1 drv on r2.DestRefnum=drv.SourceRefnum and r2.Periode=drv.Periode
	join @drv1tila1 a1 on drv.DestRefnum=a1.SourceRefnum and drv.Periode=a1.Periode
	join @a1tila4 a4 on a1.DestRefnum=a4.SourceRefnum and a1.Periode=a4.Periode
	join @a4tilc1 c1 on a4.DestRefnum=c1.SourceRefnum and a4.Periode=c1.Periode
	where r1.Refnum='R1_59050001000_U'
) der_tbl
*/


/*
select top 30000 100 amount, [DriverName]
      ,[DestModuleType]
      ,[DestReference]
      ,[DriverQuantityFixed]
      ,[DriverWeightFixed]
      ,[Periode],
	  [DriverQuantityFixed]/(sum([DriverQuantityFixed]) over (partition by drivername)) calcdrv,
	  [DriverQuantityFixed]/(sum([DriverQuantityFixed]) over (partition by drivername))*100 calcamount
  FROM [MDW].[dbo].[ABC_R_DR_Baneafgifter_FR] where Periode= 201510
  order by DriverName, DestReference
*/

/*
select top 30000 [level0]
      ,[R1Refnum]
      ,[R2Refnum]
      ,[A1Refnum]
      ,[A2Refnum]
      ,[A3Refnum]
      ,[A4Refnum]
      ,[artgrp]
      ,[Co1Refnum]
      ,[Periodrefnum]
      ,[Scenariorefnum]
      ,[andel]
      ,[nextandel]
      ,[FixedCost]
      ,[Destcost]
      ,[Model]
      ,[Model_Id]
  FROM [MDW].[ods].[td1_ft_strækningsøkonomi_test1]where R1Refnum='R1_59050001000_U' and A1Refnum='A1_1350111'
  order by A1Refnum
*/