use KPI
SELECT        
	maal.kpi_id, 
	maal.vaerdi AS Måltal, 
	rel.vaerdi as realiseretNaaet,
	rel2.vaerdi as rel2Vaerdi,
	CASE WHEN (rel.vaerdi>=maal.vaerdi) THEN rel.vaerdi ELSE maal.vaerdi END AS RealiseretIkkeNaaet, 
	CASE WHEN (rel.vaerdi<maal.vaerdi) THEN rel.vaerdi ELSE maal.vaerdi END AS Fyld,
	per.maanedsnavn,
	per.måned, 
	UPPER(Kpi.Retning) AS retning
FROM Maaltal AS maal 
INNER JOIN periode AS per ON maal.periode_id = per.periode_id 
INNER JOIN realiseret AS rel ON maal.kpi_id = rel.kpi_id AND maal.periodevisning_id = rel.periodevisning_id AND maal.periode_id = rel.periode_id 
left Join realiseret rel2 on rel.kpi_id=rel2.kpi_id and rel.periodevisning_id=rel2.periodevisning_id and rel.periode_id=(rel2.periode_id+100)
INNER JOIN Kpi ON maal.kpi_id = Kpi.Kpi_id
WHERE (per.år = 2016) AND (maal.periodevisning_id = 1) AND (maal.kpi_id = 1020)
select * from
(
select * from dbo.realiseret
union all
select * from dbo.realiseret
) x where left(x.periode_id,4)=2016 and x.kpi_id=1020 and periodevisning_id=1


/*
=iif(fields!kilde.Value = "R",
IIF(Variables!maalJanVaerdi.Value <> "0,00",
IIF(((Variables!maalJanVaerdi.Value < Fields!Januar.Value and UCase(Fields!Retning.Value) = "OP") or (Variables!maalJanVaerdi.Value > Fields!Januar.Value and UCase(Fields!Retning.Value) = "NED")), "Green", "Red"), "White"), "White")
*/