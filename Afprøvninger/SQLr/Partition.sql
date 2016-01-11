select Abm_model, Periode from dbo.MD_Kontrol_ModelLoadInfo

declare @partition_number int
SELECT @partition_number = $PARTITION.[Periode] ('201510')
select @partition_number

select distinct ps.Name AS PartitionScheme, pf.name AS PartitionFunction,fg.name AS FileGroupName, rv.value AS PartitionFunctionValue
    from sys.indexes i  
    join sys.partitions p ON i.object_id=p.object_id AND i.index_id=p.index_id  
    join sys.partition_schemes ps on ps.data_space_id = i.data_space_id  
    join sys.partition_functions pf on pf.function_id = ps.function_id  
    left join sys.partition_range_values rv on rv.function_id = pf.function_id AND rv.boundary_id = p.partition_number
    join sys.allocation_units au  ON au.container_id = p.hobt_id   
    join sys.filegroups fg  ON fg.data_space_id = au.data_space_id  
where i.object_id = object_id('FT_Strækningsøkonomi') 

select distinct
   p.object_id,
   index_name = i.name,
   index_type_desc = i.type_desc,
   partition_scheme = ps.name,
   data_space_id = ps.data_space_id,
   function_name = pf.name,
   function_id = ps.function_id
from 
   sys.partitions p
inner join
   sys.indexes i on p.object_id = i.object_id and p.index_id = i.index_id
inner join
   sys.data_spaces ds on i.data_space_id = ds.data_space_id
inner join
   sys.partition_schemes ps on ds.data_space_id = ps.data_space_id
inner join
   sys.partition_functions pf on ps.function_id = pf.function_id 


   select count(object_id) from  
   sys.partitions
   group by object_id
   having count(object_id) >30