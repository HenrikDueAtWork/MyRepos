/*
USE [MDW_test07]
GO

DECLARE	@return_value int

EXEC	@return_value = [etl].[LOAD_TD_SOEM_ABM] @model = N'M1140',	@periode = N'201511'

exec [etl].[LOAD_td3_Ft_Strækningsøkonomi_SOEM_ABM] @model = N'M1140',	@periode = N'201511'

--SELECT	'Return Value' = @return_value

GO

--select * from [ods].[TD_SOEM_ABM] 
----select * from ods.dimmember_union_all_alle_modeller where model_id=79 order by membername
----select * from ods.TD_SOEM_ABM_dimmember
select 
*
--sum(destcost)
--resource1_key--,resource2_key
 from ods.td3_Ft_Strækningsøkonomi_SOEMABM 
 --where Model_id=76
 --group by resource1_key 
 --having count(resource1_key)>2
 --where resource1_key=656 and resource2_key=1813 and activity1_key=79 and activity4_key=243
 order by resource1_key,resource2_key,activity1_key,activity4_key,costobject1_key,attRessourcetype_key,AttSegment_key,AttProduktaktivitetsgruppe_key,AttProduktVariabilitet_key,AttProduktLitra_key,AttTogsystem_key
---- except
select 
* 
--sum(destcost)
--resource1_key--,resource2_key
 from ods.td3_Ft_Strækningsøkonomi 
 --where Model_id=76
 --where resource1_key=656 and resource2_key=1813 and activity1_key=79 and activity4_key=243
 --group by resource1_key 
 order by resource1_key,resource2_key,activity1_key,activity4_key,costobject1_key,attRessourcetype_key,AttSegment_key,AttProduktaktivitetsgruppe_key,AttProduktVariabilitet_key,AttProduktLitra_key,AttTogsystem_key
 */
--select distinct substring(SourceReference,1,2),substring(DestReference,1,2) første from #driver1calc
--select distinct substring(SourceReference,1,2),substring(DestReference,1,2) anden from #driver2calc
--select distinct substring(SourceReference,1,2),substring(DestReference,1,2) tredie from #driver3calc
--select distinct substring(SourceReference,1,2),substring(DestReference,1,2) fjerde from #driver4calc

:connect oesmsqlt01\soem
--use mdw_test07
--select 
--count(*) 
----top 100 *
--from edw.ft_strækningsøkonomi where Periode=201511
--order by resource1_key,resource2_key,activity1_key,activity4_key,costobject1_key,attRessourcetype_key,AttSegment_key,AttProduktaktivitetsgruppe_key,
--AttProduktVariabilitet_key,AttProduktLitra_key,AttTogsystem_key,[Omkostningssted_key],[art_hierarki_key],[ordre_key],[pspelement_key],[profitcenter_key],
--[Artsgruppe_key],[Variabilitet_key],[Reversibilitet_key],[Tidsinterval_key],[kilde_key]
select --distinct
--resource1_key
--*
sum(destcost)
--resource1_key--,resource2_key
 from mdw_test07.ods.td3_Ft_Strækningsøkonomi_SOEMABM 
 --where Model_id=76
--order by resource1_key,resource2_key,activity1_key,activity4_key,costobject1_key,attRessourcetype_key,AttSegment_key,AttProduktaktivitetsgruppe_key,AttProduktVariabilitet_key,AttProduktLitra_key,AttTogsystem_key,ceart


go
:connect oesmsqlp01\soem
use mdw
--select 
----top 100 *
--count(*) 
--from edw.ft_strækningsøkonomi where Periode=201510
--order by resource1_key,resource2_key,activity1_key,activity4_key,costobject1_key,attRessourcetype_key,AttSegment_key,AttProduktaktivitetsgruppe_key,
--AttProduktVariabilitet_key,AttProduktLitra_key,AttTogsystem_key,[Omkostningssted_key],[art_hierarki_key],[ordre_key],[pspelement_key],[profitcenter_key],
--[Artsgruppe_key],[Variabilitet_key],[Reversibilitet_key],[Tidsinterval_key],[kilde_key]
select --distinct
--resource1_key
--* 
sum(destcost)
--resource1_key--,resource2_key
 from mdw.ods.td3_Ft_Strækningsøkonomi 
 --order by resource1_key,resource2_key,activity1_key,activity4_key,costobject1_key,attRessourcetype_key,AttSegment_key,AttProduktaktivitetsgruppe_key,AttProduktVariabilitet_key,AttProduktLitra_key,AttTogsystem_key,ceart

 --where Model_id=76
go

330822,009807121
374472,921490684
1526896,82267156
2068980,89723887
2091241,51501796
7981958,63392172
11972229,0333984
13002793,8951945
34584932,265461