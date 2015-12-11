use MDW_test06

IF object_id('ods.TD_SOEM_ABM_dimension') is not null DROP TABLE ods.TD_SOEM_ABM_dimension
SELECT 1000+row_number() OVER (ORDER BY der_dim.ModuleType) DimensionId,der_dim.ModuleType DimensionName 
INTO ods.TD_SOEM_ABM_dimension
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

IF object_id('tempdb..#dimension_member_atthier') is not null DROP TABLE #dimension_member_atthier
SELECT dim.DimensionId,der_member_atthier.Dimensionname,der_member_atthier.MemberName,der_member_atthier.MemberRefnum,der_member_atthier.ParentReference 
INTO #dimension_member_atthier
FROM
(
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].[ABC_G_ATTHIER_Funktionskunde]
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_ProdAktGrp
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_ProduktLitra
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_ProdVar
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_RessourceType
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_Segment
UNION
SELECT AttributeName MemberName,AttributeDimension Dimensionname,AttributeReference MemberRefnum,AttributeParentReference ParentReference
FROM [dbo].ABC_G_ATTHIER_Togsystem
) der_member_atthier 
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_atthier.Dimensionname

IF object_id('tempdb..#dimension_member_hier') is not null DROP TABLE #dimension_member_hier
SELECT dim.DimensionId,der_member_hier.DimensionName,der_member_hier.MemberName,der_member_hier.MemberRefnum,der_member_hier.ParentReference
INTO #dimension_member_hier
FROM
(
SELECT ModuleType DimensionName,Name MemberName,Reference MemberRefnum,ParentReference,Periode FROM [dbo].ABC_G_HIER_Aktivitet where periode=201510
UNION
SELECT ModuleType DimensionName,Name MemberName,Reference MemberRefnum,ParentReference,Periode FROM [dbo].ABC_G_HIER_Costobject where periode=201510
UNION
SELECT ModuleType DimensionName,Name MemberName,Reference MemberRefnum,ParentReference,Periode FROM [dbo].ABC_G_HIER_Ressource where periode=201510
) der_member_hier
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_hier.Dimensionname

IF object_id('tempdb..#dimension_member_akt') is not null DROP TABLE #dimension_member_akt
SELECT dim.DimensionId,der_member_aktivitet.DimensionName,akt.Name MemberName,der_member_aktivitet.MemberRefnum,akt.ParentReference 
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
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_aktivitet.DimensionName

IF object_id('tempdb..#dimension_member_res') is not null DROP TABLE #dimension_member_res
SELECT dim.DimensionId,der_member_res.DimensionName,res.Name MemberName,der_member_res.MemberRefnum,res.ParentReference
INTO #dimension_member_res
FROM
(
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Ressourcetype] WHERE Periode=201508 
) der_member_res 
JOIN [dbo].[ABC_G_ACC_Ressource] res on res.Reference=der_member_res.MemberRefnum and res.Periode=der_member_res.Periode
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_res.DimensionName

IF object_id('tempdb..#dimension_member_cost') is not null DROP TABLE #dimension_member_cost
SELECT dim.DimensionId,der_member_cos.DimensionName,cost.Name MemberName,der_member_cos.MemberRefnum,cost.ParentReference
INTO #dimension_member_cost
FROM
(
SELECT AccountModuleType DimensionName,AccountReference MemberRefnum,Periode FROM [dbo].[ABC_G_ATT_Togsystem] WHERE Periode=201508 
) der_member_cos 
JOIN [dbo].[ABC_G_ACC_Costobject] cost on cost.Reference=der_member_cos.MemberRefnum and cost.Periode=der_member_cos.Periode
JOIN ods.TD_SOEM_ABM_dimension dim on dim.DimensionName=der_member_cos.DimensionName

IF object_id('tempdb..#dimension_member') is not null DROP TABLE #dimension_member
SELECT 1012+row_number() OVER (ORDER BY der_dimension.MemberName) MemberId,* 
INTO #dimension_member
FROM 
(
SELECT * FROM #dimension_member_atthier
UNION
SELECT * FROM #dimension_member_hier
UNION
SELECT * FROM #dimension_member_akt
UNION
SELECT * FROM #dimension_member_res
UNION
SELECT * FROM #dimension_member_cost
) der_dimension 

IF object_id('ods.TD_SOEM_ABM_dimmember') is not null DROP TABLE ods.TD_SOEM_ABM_dimmember

SELECT a.DimensionId,a.Dimensionname,a.MemberId,a.MemberName,a.MemberRefnum,a.ParentReference,b.MemberId ParentId 
INTO ods.TD_SOEM_ABM_dimmember
FROM #dimension_member a
LEFT JOIN #dimension_member b on b.MemberRefnum=a.ParentReference

select *
	 --mem1.DimensionId,mem1.MemberRefnum
from ods.TD_SOEM_ABM_dimmember mem1
where MemberRefnum='C1_113805'