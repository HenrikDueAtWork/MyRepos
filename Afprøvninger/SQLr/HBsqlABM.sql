select 
		a.FixedCost,
		Case when a.Refnum is null then b.Refnum else a.Refnum end as SourceRefnum,
		c.Refnum as DestRefnum, 
        d.Refnum as PeriodRefnum,
		'Aktual' as ScenarioRefnum,
		Case when substring(a.Refnum,1,1)='E' then substring(reverse(a.Refnum),6,1) else NULL end as Artgrp,
		sum(fixedcost) over () as summen

from	
		ods.td_Mxxxx_costelement a
			left join 
		ods.td_Mxxxx_AccountCenter b on a.sourceId = b.Id  
			left join 
		ods.td_Mxxxx_AccountCenter c on a.DestinationId = c.Id
			left join 
		[ods].[td_SASABMMODELSDYN_PeriodDefinition] d on a.PeriodId = d.Id
		where c.Refnum  = 'A1_1110016'
order by 
		sourcerefnum



select 
		a.FixedCost,
		Case when a.Refnum is null then b.Refnum else a.Refnum end as SourceRefnum,
		c.Refnum as DestRefnum, 
        d.Refnum as PeriodRefnum,
		'Aktual' as ScenarioRefnum,
		Case when substring(a.Refnum,1,1)='E' then substring(reverse(a.Refnum),6,1) else NULL end as Artgrp,
			sum(fixedcost) over () as summen

from	
		ods.td_Mxxxx_costelement a
			left join 
		ods.td_Mxxxx_AccountCenter b on a.sourceId = b.Id  
			left join 
		ods.td_Mxxxx_AccountCenter c on a.DestinationId = c.Id
			left join 
		[ods].[td_SASABMMODELSDYN_PeriodDefinition] d on a.PeriodId = d.Id
		where Case when a.Refnum is null then b.Refnum else a.Refnum end = 'A1_1110016'
order by 
		sourcerefnum



		select 
		a.FixedCost,
		Case when a.Refnum is null then b.Refnum else a.Refnum end as SourceRefnum,
		c.Refnum as DestRefnum, 
        d.Refnum as PeriodRefnum,
		'Aktual' as ScenarioRefnum,
		Case when substring(a.Refnum,1,1)='E' then substring(reverse(a.Refnum),6,1) else NULL end as Artgrp,
			sum(fixedcost) over () as summen

from	
		ods.td_Mxxxx_costelement a
			left join 
		ods.td_Mxxxx_AccountCenter b on a.sourceId = b.Id  
			left join 
		ods.td_Mxxxx_AccountCenter c on a.DestinationId = c.Id
			left join 
		[ods].[td_SASABMMODELSDYN_PeriodDefinition] d on a.PeriodId = d.Id
		where c.Refnum = 'A4_4510030'
order by 
		sourcerefnum



		select * from ods.td_Mxxxx_costelement a where refnum like 'E%'
select 
		a.FixedCost,
		Case when a.Refnum is null then b.Refnum else a.Refnum end as SourceRefnum,
		c.Refnum as DestRefnum, 
        d.Refnum as PeriodRefnum,
		'Aktual' as ScenarioRefnum,
		Case when substring(a.Refnum,1,1)='E' then substring(reverse(a.Refnum),6,1) else NULL end as Artgrp,
			sum(fixedcost) over (partition by Case when a.Refnum is null then b.Refnum else a.Refnum end) as summen,
		a.*, b.*, c.*

from	
		ods.td_Mxxxx_costelement a
			left join 
		ods.td_Mxxxx_AccountCenter b on a.sourceId = b.Id  
			left join 
		ods.td_Mxxxx_AccountCenter c on a.DestinationId = c.Id
			left join 
		[ods].[td_SASABMMODELSDYN_PeriodDefinition] d on a.PeriodId = d.Id
		where Case when a.Refnum is null then b.Refnum else a.Refnum end in  ('A4_4510030','A4_4510040','A4_4510050')
order by 
		sourcerefnum

