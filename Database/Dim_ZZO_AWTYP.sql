select
	case when (der_tmp.ZZO_AWTYP='') then 'QQQQ' else coalesce(ZZO_AWTYP,'QQQQ') end ZZO_AWTYP 
into [DIRK_Prototype01].dimension.Dim_ZZO_AWTYP
from
(	 
select [MirrorCOData].[ZHUPCAD02_10].ZZO_AWTYP
from [MirrorCOData].[ZHUPCAD02_10]
union
select [MirrorCOData].[ZHUPCAF0X2_10].ZZO_AWTYP
from [MirrorCOData].[ZHUPCAF0X2_10]
) as der_tmp
