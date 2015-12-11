use MDW_test06
--select 
--	a.Name as Dimensionname,
--	b.refnum as MemberRefnum
--from 
--	ods.td_Mxxxx_dimension a
--		inner join 
--	ods.td_Mxxxx_dimmember b on a.id = b.dimensionid
--order by a.Name,b.refnum
IF object_id('tempdb..#dimension') is not null DROP TABLE #dimension
SELECT 1000+row_number() OVER (ORDER BY der_dim.ModuleType) DimensionId,der_dim.ModuleType DimensionName 
	--der_member.MemberName,
	--der_member.MemberRefnum
INTO #dimension
FROM
(  
SELECT ModuleType
FROM [dbo].[ABC_G_ACC_Aktivitet]
UNION
SELECT ModuleType
FROM [dbo].ABC_G_ACC_Costobject
UNION
SELECT ModuleType
FROM [dbo].ABC_G_ACC_Ressource
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_Funktionskunde
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_ProdAktGrp
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_ProduktLitra
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_ProdVar
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_Ressourcetype
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_Ressourcetype
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_Segment
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_TidDr
UNION
SELECT [AttributeDimension]
FROM [dbo].ABC_G_ATT_Togsystem
UNION
SELECT 'ExternalUnit' ModuleType
UNION 
SELECT 'MængdeEnhed' ModuleType
) der_dim
select * from #dimension --1012+row_number() OVER (ORDER BY der_member_t1.MemberName) MemberId,

IF object_id('tempdb..#dimension_member_hier') is not null DROP TABLE #dimension_member_hier
SELECT dim.DimensionId,der_member_hier.Dimensionname,der_member_hier.MemberName,der_member_hier.MemberRefnum 
INTO #dimension_member_hier
FROM
(
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum
FROM [dbo].[ABC_G_ATTHIER_Funktionskunde]
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum
FROM [dbo].ABC_G_ATTHIER_ProdAktGrp
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum
FROM [dbo].ABC_G_ATTHIER_ProduktLitra
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum
FROM [dbo].ABC_G_ATTHIER_ProdVar
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum
FROM [dbo].ABC_G_ATTHIER_RessourceType
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum
FROM [dbo].ABC_G_ATTHIER_Segment
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum
FROM [dbo].ABC_G_ATTHIER_Togsystem
) der_member_hier 
JOIN #dimension dim on dim.DimensionName=der_member_hier.Dimensionname
--select * from #dimension_member_hier

IF object_id('tempdb..#dimension_member_akt') is not null DROP TABLE #dimension_member_akt
SELECT dim.DimensionId,der_member_aktivitet.DimensionName,akt.Name MemberName,der_member_aktivitet.MemberRefnum 
INTO #dimension_member_akt
FROM
(
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Funktionskunde] WHERE Periode=201508 
UNION
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_ProdAktGrp] WHERE Periode=201508
UNION
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_ProduktLitra] WHERE Periode=201508
UNION
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_ProdVar] WHERE Periode=201508
UNION
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_ProdVar] WHERE Periode=201508
UNION
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Segment] WHERE Periode=201508
UNION
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_TidDr] WHERE Periode=201508
) der_member_aktivitet 
JOIN [dbo].[ABC_G_ACC_Aktivitet] akt on akt.Reference=der_member_aktivitet.MemberRefnum and akt.Periode=der_member_aktivitet.Periode
JOIN #dimension dim on dim.DimensionName=der_member_aktivitet.DimensionName

IF object_id('tempdb..#dimension_member_res') is not null DROP TABLE #dimension_member_res
SELECT dim.DimensionId,der_member_res.DimensionName,res.Name MemberName,der_member_res.MemberRefnum 
INTO #dimension_member_res
FROM
(
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Ressourcetype] WHERE Periode=201508 
) der_member_res 
JOIN [dbo].[ABC_G_ACC_Ressource] res on res.Reference=der_member_res.MemberRefnum and res.Periode=der_member_res.Periode
JOIN #dimension dim on dim.DimensionName=der_member_res.DimensionName

IF object_id('tempdb..#dimension_member_cost') is not null DROP TABLE #dimension_member_cost
SELECT dim.DimensionId,der_member_cos.DimensionName,cost.Name MemberName,der_member_cos.MemberRefnum 
INTO #dimension_member_cost
FROM
(
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Togsystem] WHERE Periode=201508 
) der_member_cos 
JOIN [dbo].[ABC_G_ACC_Costobject] cost on cost.Reference=der_member_cos.MemberRefnum and cost.Periode=der_member_cos.Periode
JOIN #dimension dim on dim.DimensionName=der_member_cos.DimensionName

--select * from #dimension_member_cost
IF object_id('ods.Dimension_SOEMAMB') is not null DROP TABLE ods.Dimension_SOEMAMB
SELECT 1012+row_number() OVER (ORDER BY der_dimension.MemberName) MemberId,* 
INTO ods.Dimension_SOEMAMB
FROM 
(SELECT * FROM #dimension_member_hier
UNION
SELECT * FROM #dimension_member_akt
UNION
SELECT * FROM #dimension_member_res
UNION
SELECT * FROM #dimension_member_cost
) der_dimension 

select * from ods.Dimension_SOEMAMB
--except
--select Dimensionname,MemberRefnum from ods.Key_Dim_Member