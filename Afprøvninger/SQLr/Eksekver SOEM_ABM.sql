USE [MDW_test07]
GO

DECLARE	@return_value int

EXEC	@return_value = [etl].[LOAD_TD_Ft_Strækningsøkonomi_SOEM_ABM]

exec [etl].[LOAD_td3_Ft_Strækningsøkonomi_SOEM_ABM]

--SELECT	'Return Value' = @return_value

GO


select * from ods.dimmember_union_all_alle_modeller
--select * from ods.TD_SOEM_ABM_dimmember
select 
--*
sum(destcost)
--resource1_key--,resource2_key
 from ods.td3_Ft_Strækningsøkonomi_SOEMABM 
 where Model_id=76
 --group by resource1_key 
 --having count(resource1_key)>2
 --where resource1_key=656 and resource2_key=1813 and activity1_key=79 and activity4_key=243
-- order by resource1_key,resource2_key,activity1_key,activity4_key,costobject1_key,attRessourcetype_key,AttSegment_key,AttProduktaktivitetsgruppe_key,AttProduktVariabilitet_key,AttProduktLitra_key,AttTogsystem_key
-- except
select 
--* 
sum(destcost)
--resource1_key--,resource2_key
 from ods.td3_Ft_Strækningsøkonomi 
 where Model_id=76
 --where resource1_key=656 and resource2_key=1813 and activity1_key=79 and activity4_key=243
 --group by resource1_key 
-- order by resource1_key,resource2_key,activity1_key,activity4_key,costobject1_key,attRessourcetype_key,AttSegment_key,AttProduktaktivitetsgruppe_key,AttProduktVariabilitet_key,AttProduktLitra_key,AttTogsystem_key

 
--select distinct substring(SourceReference,1,2),substring(DestReference,1,2) første from #driver1calc
--select distinct substring(SourceReference,1,2),substring(DestReference,1,2) anden from #driver2calc
--select distinct substring(SourceReference,1,2),substring(DestReference,1,2) tredie from #driver3calc
--select distinct substring(SourceReference,1,2),substring(DestReference,1,2) fjerde from #driver4calc