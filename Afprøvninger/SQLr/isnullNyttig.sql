--declare @dimension varchar(max)
--select @dimension =  isnull(@dimension+',','')+ name from syscolumns where id = object_id('ods.td0_Mxxxx_AccountCenter') and name not like 'dim1%'
--print @dimension
--select @dimension =  coalesce(@dimension+',','') + ' Dim'+convert(varchar(10), id) collate Danish_Norwegian_CI_AS + ' as ' +quotename(name,'''') from ods.td_Mxxxx_dimension a 
--print @dimension
--declare @sql varchar(max)
--print @sql
--set @sql = 'select '+@dimension+' into ods.td_Mxxxx_AccountCenter from ods.td0_Mxxxx_AccountCenter'
--print @sql

declare @varTest varchar(max)
--select @varTest = isnull(@varTest+',','')+ name from syscolumns
select @varTest = isnull(@varTest+',','')+Name from ods.td_Mxxxx_dimension
select @varTest = isnull(@varTest+',','')+'test'
--select name from syscolumns
--select @varTest
print @varTest
exec sp_columns @table_name = 'td_Mxxxx_dimension' 