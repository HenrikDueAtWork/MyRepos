use MDW_test06
if object_id('tempdb..#TD_delmodel_costelement') is not null drop table #TD_delmodel_costelement
select 
		a.FixedCost,
		Case when a.Refnum is null then b.Refnum else a.Refnum end as SourceRefnum,
		c.Refnum as DestRefnum, 
        d.Refnum as PeriodRefnum,
		'Aktual' as ScenarioRefnum,
		Case when substring(a.Refnum,1,1)='E' then substring(reverse(a.Refnum),6,1) else NULL end as Artgrp
into 
		#TD_delmodel_costelement
from	
		ods.td_Mxxxx_costelement a
			left join 
		ods.td_Mxxxx_AccountCenter b on a.sourceId = b.Id  
			left join 
		ods.td_Mxxxx_AccountCenter c on a.DestinationId = c.Id
			left join 
		[ods].[td_SASABMMODELSDYN_PeriodDefinition] d on a.PeriodId = d.Id
order by 
		sourcerefnum


--2
if object_id('tempdb..#totaldest') is not null drop table #totaldest

SELECT DISTINCT 
	ce.destrefnum,
	Sum(ce.FixedCost) AS TotalDestinationCost 
INTO 
	#totaldest  
FROM 
	#TD_delmodel_costelement ce
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
	#TD_delmodel_costelement ce
left join
	#totaldest td ON convert(varchar(50),td.destrefnum) collate Danish_Norwegian_CI_AS =ce.destrefnum
WHERE 
	ce.FixedCost NOT in (0)

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

select * from #data1 where level0 in ('E1_120100260_U','R1_120100260_U','R2_2000020','A1_2121000')
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
select * from #data2 where level0 in ('E1_120100260_U','R1_120100260_U','R2_2000020','A1_2121000')
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
select * from #data3 where level0 in ('E1_120100260_U','R1_120100260_U','R2_2000020','A1_2121000')
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
select * from #data4 where level0 in ('E1_120100260_U','R1_120100260_U','R2_2000020','A1_2121000')

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
select * from #data4 where level0 in ('E1_120100260_U','R1_120100260_U','R2_2000020','A1_2121000')

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
select * from #data6 where level0 in ('E1_120100260_U','R1_120100260_U','R2_2000020','A1_2121000')




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
END
--@model as Model,
--@model_id as Model_Id
INTO #data7
FROM #data6
left join 
#assignment ast
ON
#data6.level6= ast.sourcerefnum
select * from #data7 where level0 in ('E1_120100260_U','R1_120100260_U','R2_2000020','A1_2121000')

--select * from #Assignment where sourcerefnum in ('E1_120100260_U','R1_120100260_U','R2_2000020','A1_2121000')

--select * from [ods].TD_SOEM_ABM where SourceReference in ('E1_120100260_U','R1_120100260_U','R2_2000020','A1_2121000')

select * from [ods].[TD_SOEM_ABM_ANDEL] where SourceReference in ('E1_120100260_U','R1_120100260_U','R2_2000020','A1_2121000')