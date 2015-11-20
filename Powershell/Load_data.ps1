#The default path to the modules folder is $home\Documents\WindowsPowerShell\Modules
cls
write-host "Script startet" (Get-Date).ToString("dd.MM.yyyy hh:mm:ss")
$path =  Resolve-Path .\ 
Import-Module Functions.psm1
Import-Module SQLPS -WarningAction SilentlyContinue
Import-module sqlascmdlets
c:
# Functions
Function StoredProcResult{param ([string]$result)
	if ($result="TRUE"){
		write-host -BackgroundColor Green -ForegroundColor Black "Afsluttet uden fejl"
	}
	else {
		write-host -BackgroundColor White -ForegroundColor Red "Kørsel fejlet"
	}
}
# Log

$log = "\Log"
$logPath = "$path\Log" 
if (!(Test-Path -Path $logPath) ) { New-Item -ItemType directory -Path $logPath }
$logFile ="$logPath\Log_$((get-date).ToString("yyyyMMdd hhmmss")).txt"
# Konfiguration
$storedProcMain = "etl.run_etl_Togpersonale_FR_PDS"
$storedProcPDS = "etl.loadperiod_PDS"
$cfgfil = resolve-path("..\Konfiguration\ServerOgDatabase.cfg")
$xmldoc = [xml] (get-content $cfgfil)
$database = $xmldoc.DTSConfiguration.Database
$server = $xmldoc.DTSConfiguration.Server
# Sql statements
$sqlPeriodeAlle = "select Value from ods.CTL_Dataload where kilde_system = 'Alle' and Variable = 'Master_periode'"
$sqlPeriodePDS = "select Value from ods.CTL_Dataload where kilde_system = 'PDS' and Variable = 'Last_Period_Load'"
$sqlMessageSSISDB = "select * from etl.ssisdb_messages"
# Sql kørsel
$periodeAlle = Invoke-Sqlcmd -Query $sqlPeriodeAlle -ServerInstance $server -Database $database
$periodePDS = Invoke-Sqlcmd -Query $sqlPeriodePDS -ServerInstance $server -Database $database
$messageSSISDB = Invoke-Sqlcmd -Query $sqlMessageSSISDB -ServerInstance $server -Database $database
write-host *  'Master LoadPeriode:  --->' $periodeAlle.Value.ToString() '<--- Tjek periode her.'
write-host *  'PDS FR LoadPeriode: ' $periodePDS.Value.ToString()

# $start = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
# $slut = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
# $options = [System.Management.Automation.Host.ChoiceDescription[]]($start, $slut)
# $result = $host.ui.PromptForChoice("", "", $options, 0) 
do{
#"Tast 1: Start med master loadperiode, 2: Indtast Ny dato eller 3: Fortryd og afslut"
		write-host "1 - Start med master loadperiode"
		write-host "2 - Indtast ny periode"
		write-host "3 - Fortryd og afslut"
		$choice = read-host
		$ok = @("1","2","3") -contains $choice
		if ( -not $ok) { write-host "Valg ikke tilladt" }
}
until ( $ok )
switch ( $choice ) {
	"1"{
	write-host "Starter med master loadperiode:"$periodeAlle.Value.ToString()
	$return = ExecStoredProc $Server $Database $storedProcPDS
	$return = ExecStoredProc $Server $Database $storedProcMain
	StoredProcResult $return
	$messageSSISDB
	break
	}
	"2"{
	$nyPeriode = read-host "Indtast ny loadperiode yyyymm FOR Protal "
	$storedProcPDS = $storedProcPDS+"'"+$nyPeriode+"01"+"'"
	$return = ExecStoredProc $Server $Database $storedProcPDS
		if ($return="TRUE") {
			write-host "Starter med PDS periode:"$nyPeriode 			
			$return = ExecStoredProc $Server $Database $storedProcMain
			StoredProcResult $return
			$messageSSISDB
		}
		else {
		break
		}
		
	break
	}
	"3"{
	write-host "Afslutter"
	break
	}
}
  
	
# Skriv til logfil
Add-content $logFile "Periode"
Add-content $logFile $periodeAlle.Value.ToString()
$logEntry = "Script afsluttet "+(Get-Date).ToString("dd.MM.yyyy hh:mm:ss") 
Add-content $logFile $logEntry
write-host "Script afsluttet" (Get-Date).ToString("dd.MM.yyyy hh:mm:ss")