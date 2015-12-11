--select  tmp_1.sourcereference,tmp_2.sourcereference,tmp_3.sourcereference,tmp_4.sourcereference,tmp_5.sourcereference,tmp_5.destreference,tmp_5.CalcCost*(tmp_5.Andel) DestCost from
--(select * from [ods].[TD_SOEM_ABM_ANDEL] where substring(sourcereference,1,2)='E1') tmp_1
--join
--(select * from [ods].[TD_SOEM_ABM_ANDEL]) tmp_2 on tmp_1.destreference=tmp_2.sourcereference
--join
--(select * from [ods].[TD_SOEM_ABM_ANDEL]) tmp_3 on tmp_2.destreference=tmp_3.sourcereference
--join
--(select * from [ods].[TD_SOEM_ABM_ANDEL]) tmp_4 on tmp_3.destreference=tmp_4.sourcereference
--join
--(select * from [ods].[TD_SOEM_ABM_ANDEL]) tmp_5 on tmp_4.destreference=tmp_5.sourcereference
--where tmp_1.sourcereference ='E1_120100260_U'
--order by tmp_1.sourcereference

select * from [ods].TD_SOEM_ABM