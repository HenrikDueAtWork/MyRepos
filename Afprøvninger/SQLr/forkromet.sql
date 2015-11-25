/****** Script for SelectTopNRows command from SSMS  ******/
use MDW

/*queries ikke fuldstændige*/

declare @r1 table (
	Refnum varchar(256),
	Periode varchar(50))

insert into @r1

SELECT
	AccountReference,
	Periode
FROM [dbo].[ABC_R_CE_anlæg]
where Periode=201510
union all
SELECT
	AccountReference,
	Periode
FROM [dbo].[ABC_R_CE_Drift]
where Periode=201510
select * from @r1

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


select * from @r1tilr2

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

declare @drv1tildrv2 table (
	SourceRefnum varchar(256),
	Periode varchar(50),
	DestRefnum varchar(256))

insert into @drv1tildrv2
select 
	drv1.DestRefnum,
	drv1.Periode,
	drv2.DestReference
from @r2tildrv1 drv1
join ABC_R_DR_Moms drv2 on drv1.DestRefnum=drv2.DriverName and drv1.Periode=drv2.Periode
select * from @drv1tildrv2