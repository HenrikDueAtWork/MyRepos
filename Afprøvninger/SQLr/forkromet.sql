/****** Script for SelectTopNRows command from SSMS  ******/
use MDW--_test06
/*drivers*/
declare @drvlist table (
	DriverName varchar(256),
	DestRefnum varchar(256),
	DriverQuantityFixed float,
	Periode varchar(50),
	sumDriverQuantityFixed float)

insert into @drvlist
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
--select * from @drvlist where  DriverName='R2_6201800'-- where DriverQuantityFixed is null
--delete from @drvlist where DriverQuantityFixed is null or DriverQuantityFixed=0

declare @sdl table (
	SourceRefnum varchar(256),
	DriverName varchar(50),
	Periode varchar(50))

insert into @sdl
select 
	SourceReference,
	DriverName,
	Periode
from dbo.ABC_G_SDL_Activities
union all
select 
	SourceReference,
	DriverName,
	Periode
from dbo.ABC_G_SDL_Ressourcer
--select * from @sdl where SourceRefnum='A4_4620000' and periode=201510
--###driver
declare @driver table (
	DriverName varchar(256),
	SourceRefnum varchar(256),
	DestRefnum varchar(256),
	DriverQuantityFixed float,
	sumDriverQuantityFixed float,
	Periode varchar(59))

insert into @driver
select 
	sdl.DriverName,
	sdl.SourceRefnum,
	drv.DestRefnum,
	drv.DriverQuantityFixed,
	drv.sumDriverQuantityFixed,
	drv.Periode
from @sdl sdl
join @drvlist drv on sdl.DriverName=drv.DriverName and sdl.Periode=drv.Periode
--select * from @driver where SourceRefnum='A4_4620000' and periode=201510
--select * from @driver where DriverName='DR_Delrejser_Stog' order by Periode desc-- and periode=201510
--where sdl.periode=201510--order by sdl.DriverName,sdl.Periode-- SourceRef-- DriverName,Periode

insert into @driver
select 'ActEventAssign' DriverName,SourceReference,DestReference,1 DriverQuantityFixed,1 sumDriverQuantityFixed,Periode from dbo.ABC_G_EA_Activities 
union all
select 'ResEventAssign' DriverName,SourceReference,DestReference,1 DriverQuantityFixed,1 sumDriverQuantityFixed,Periode from dbo.ABC_G_EA_Ressourcer 

--select * from @driver where DriverName like 'act%'
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
where der_R1.Periode=201510 and der_R1.AccountReference='R1_135186011_U'
group by der_R1.AccountReference,der_R1.Periode
select * from @r1
--select distinct substring(Refnum,1,2) from @r1

declare @level1cost table (
	--SourceRef varchar(256),
	DestRef varchar(256),
	Periode varchar(50),
	CalcCost float)

insert into @level1cost
select
	drv.DestRefnum,
	drv.Periode,
	(r1.Cost )*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
from @r1 r1
join @driver drv on r1.Refnum=drv.SourceRefnum and r1.Periode=drv.Periode
--select distinct substring(DestRef,1,2) from @level1cost
select destref,periode,CalcCost,sum(CalcCost) over (partition by periode) from @level1cost

declare @level2cost table (
	--SourceRef varchar(256),
	DestRef varchar(256),
	Periode varchar(50),
	CalcCost float)

insert into @level2cost
select
	drv.DestRefnum,
	drv.Periode,
	(lvl1.CalcCost )*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
from @level1cost lvl1
join @driver drv on lvl1.DestRef=drv.SourceRefnum and lvl1.Periode=drv.Periode
select destref,periode,CalcCost,sum(CalcCost) over (partition by periode) from @level2cost

declare @level3cost table (
	--SourceRef varchar(256),
	DestRef varchar(256),
	Periode varchar(50),
	CalcCost float)

insert into @level3cost
select
	drv.DestRefnum,
	drv.Periode,
	(lvl2.CalcCost )*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
from @level2cost lvl2
join @driver drv on lvl2.DestRef=drv.SourceRefnum and lvl2.Periode=drv.Periode
select destref,periode,CalcCost,sum(CalcCost) over (partition by periode) from @level3cost

declare @level4cost table (
	--SourceRef varchar(256),
	DestRef varchar(256),
	Periode varchar(50),
	CalcCost float)

insert into @level4cost
select
	drv.DestRefnum,
	drv.Periode,
	(lvl3.CalcCost )*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
from @level3cost lvl3
join @driver drv on lvl3.DestRef=drv.SourceRefnum and lvl3.Periode=drv.Periode
select destref,periode,CalcCost,sum(CalcCost) over (partition by periode) from @level4cost --sum(calccost)

--select distinct substring(DestRef,1,2) from @level2cost
	
--select * from @driver where SourceRefnum in ('A4_4620000',
--'A4_4620001',
--'A4_4620002',
--'A4_4620003',
--'A4_4620004',
--'A4_4620005',
--'A4_4620006',
--'A4_4620008',
--'A4_4620009',
--'A4_5300001') and Periode=201510 order by SourceRefnum
--declare @ea table (
--	SourceRef varchar(256),
--	DestRef varchar(256),
--	Periode varchar(50))

--insert into @ea
--select 
--	eaact.SourceReference,
--	eaact.DestReference,
--	eaact.Periode
--from dbo.ABC_G_EA_Activities eaact
--union all
--select 
--	eares.SourceReference,
--	eares.DestReference,
--	eares.Periode
--from dbo.ABC_G_EA_Ressourcer eares
----########
--select distinct substring(DestRef,1,2) from @ea where substring(SourceRef,1,2)='a4'--  periode=201510 order by SourceRef
----select count(*) from @ea where substring(destref,1,2)='c1'

--insert into @ea
--select 
--	ea1.DestRef,
--	ea2.DestRef,
--	ea2.Periode
--from @ea ea1
--join @ea ea2 on ea1.DestRef=ea2.SourceRef and ea1.Periode=ea2.Periode
----join dbo.ABC_G_EA_Ressourcer eares on ea.DestRef=eares.SourceReference

--select * from @ea where periode=201510 order by SourceRef-- substring(destref,1,2)='c1'

--insert into @ea
--select 
--	ea1.DestRef,
--	ea2.DestRef,
--	ea2.Periode
--from @ea ea1
--join @ea ea2 on ea1.DestRef=ea2.SourceRef and ea1.Periode=ea2.Periode
--select count(*) from @ea where substring(destref,1,2)='c1'

----insert into @ea
----select 
----	ea1.DestRef,
----	ea2.DestRef,
----	ea2.Periode
----from @ea ea1
----join @ea ea2 on ea1.DestRef=ea2.SourceRef and ea1.Periode=ea2.Periode
----select count(*) from @ea where substring(destref,1,2)='c1'

--declare @costelement table (
--	DestRef varchar(256),
--	Periode varchar(50),
--	Cost float)

--insert into @costelement
--select 
--	r1.Refnum,
--	r1.Periode,
--	r1.Cost
--from @r1 r1 where not exists(select 1 from @ea ea where r1.Refnum=ea.SourceRef and r1.Periode=ea.Periode)
--union all
--select 
--	ea.DestRef,
--	r1.Periode,
--	r1.Cost
--from @r1 r1
--join @ea ea on r1.Refnum=ea.SourceRef and r1.Periode=ea.Periode

--select * from @costelement

--select * from @drvlist where periode=201510 and DriverName='DR_M2_Ejendomme_Egne'-- order by DriverName,Periode
--select * from @sdl where periode=201510 order by DriverName,Periode



--select * from @drvlist where substring(DestRefnum,1,2)='C1' and Periode=201510
--select * from @driver  where substring(DestRefnum,1,2)='C1'

--declare @calc1cost table (
--	DestRefnum varchar(256),
--	Periode varchar(50),
--	CalcCost float)

--insert into @calc1cost
--select 
--	drv.DestRefnum,
--	drv.Periode,
--	(cost.Cost )*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
--from @driver drv
--join @costelement cost on drv.SourceRefnum=cost.DestRef and drv.Periode=cost.Periode -- and DestRefnum='A1_134_061'--and substring(drv.DestRefnum,1,2)='C1'

--select * from @calc1cost
--select * from @driver where SourceRefnum='A1_134_061'

--declare @calc2cost table (
--	DestRefnum varchar(256),
--	Periode varchar(50),
--	CalcCost float)

--insert into @calc2cost
--select 
--	drv.DestRefnum,
--	drv.Periode,
--	(cost.CalcCost)*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
--from @driver drv
--join @calc1cost cost on drv.SourceRefnum=cost.DestRefnum and drv.Periode=cost.Periode

--declare @calc3cost table (
--	DestRefnum varchar(256),
--	Periode varchar(50),
--	CalcCost float)

--insert into @calc3cost
--select 
--	drv.DestRefnum,
--	drv.Periode,
--	(cost.CalcCost)*(drv.DriverQuantityFixed/drv.sumDriverQuantityFixed) CalcCost
--from @driver drv
--join @calc2cost cost on drv.SourceRefnum=cost.DestRefnum and drv.Periode=cost.Periode

--select * from @driver where SourceRefnum='R2_6201800'
--select * from @driver where DestRefnum='R2_6201800'
----select * from @calc1cost-- where substring(DestRefnum,1,2)='a4'
--select * from @costelement
--select * from @calc1cost
--select * from @calc2cost
--select sum(CalcCost) from @calc3cost --where substring(DestRefnum,1,2)='a4'
--select * from @sdl where DriverName='DR_M2_Ejendomme_FK1000' and periode=201510 order by SourceRefnum
--select * from @drvlist where DriverName='DR_M2_Ejendomme_FK1000' and periode=201510 order by DestRefnum
--select * from @driver where SourceRefnum='R2_6201800'-- and periode=201510 order by DestRefnum ---DriverName='DR_M2_Ejendomme_FK1000'
--select * from @ea where SourceRef='R2_6201800'
--select 
--*
--from @driver dr1
--join @driver dr2 on dr1.DestRefnum=dr2.SourceRefnum

/*
declare @r1ea2r2 table (
	SourceRef varchar(256),
	DestRef varchar(256),
	Periode varchar(50),
	Cost float)
	
insert into @r1ea2r2
select 
	r1.Refnum,
	ea.DestRef,
	r1.Periode,
	r1.Cost
from @r1 r1
join @ea ea on r1.Refnum=ea.SourceRef and r1.Periode=ea.Periode and substring(ea.DestRef,1,2)='R2'

select * from @r1ea2r2

declare @r1ea2a1 table (
	SourceRef varchar(256),
	DestRef varchar(256),
	Periode varchar(50),
	Cost float)
	
insert into @r1ea2a1
select 
	r1.Refnum,
	ea.DestRef,
	r1.Periode,
	r1.Cost
from @r1 r1
join @ea ea on r1.Refnum=ea.SourceRef and r1.Periode=ea.Periode and substring(ea.DestRef,1,2)='A1'

select * from @r1ea2a1

declare @r1ea2a4 table (
	SourceRef varchar(256),
	DestRef varchar(256),
	Periode varchar(50),
	Cost float)
	
insert into @r1ea2a4
select 
	r1.Refnum,
	ea.DestRef,
	r1.Periode,
	r1.Cost
from @r1 r1
join @ea ea on r1.Refnum=ea.SourceRef and r1.Periode=ea.Periode and substring(ea.DestRef,1,2)='A4'

select * from @r1ea2a4 		

*/

--select count(*) from @r1 r1
--where  exists(select 1 from @ea ea where r1.Refnum=ea.SourceRef and r1.Periode=ea.Periode)

/*
select 
--* 
distinct
substring(DestRef,1,2)
from @ea where 
SourceRef like 'A4%' 
--and 
--DestRef like 'a1%'
and 
Periode=201510
*/
/*
select
--count(*)
--drv.DriverName,
--drv.DestRefnum
eares.DestReference 
from 
@r1 r1
join dbo.ABC_G_EA_Ressourcer eares on r1.Refnum=eares.SourceReference and r1.Periode=eares.Periode and substring(eares.DestReference ,1,2)='C1'

--join [dbo].[ABC_G_SDL_Ressourcer] sdlres on r1.Refnum=sdlres.SourceReference and r1.Periode=sdlres.Periode 
--join @drvlist drv on r1.Refnum=drv.DriverName and r1.Periode=drv.Periode
*/
/*
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
*/

--select 
----count(*) 
--distinct
--substring(drv.DriverName,1,4)
--from @drvlist drv where substring(drv.DestRefnum ,1,2)='A4'
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