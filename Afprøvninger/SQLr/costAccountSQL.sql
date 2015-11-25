declare @cost_account table (
	FixedCost float,
	SourceRefnum varchar(256) ,
	DestRefnum varchar(256),
	PeriodRefnum varchar(256),
	ScenarioRefnum varchar(256),
	Artgrp varchar(256)
)

insert into @cost_account
select 
		a.FixedCost,
		Case when a.Refnum is null then b.Refnum else a.Refnum end as SourceRefnum,
		c.Refnum as DestRefnum, 
        d.Refnum as PeriodRefnum,
		'Aktual' as ScenarioRefnum,
		Case when substring(a.Refnum,1,1)='E' then substring(reverse(a.Refnum),6,1) else NULL end as Artgrp

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