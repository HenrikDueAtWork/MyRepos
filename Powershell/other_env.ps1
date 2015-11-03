function other_env
{
   get-wmiObject win32_environment |
	where {$_.username -ne "<System>"}
}