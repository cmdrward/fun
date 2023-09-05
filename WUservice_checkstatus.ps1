#Version 3 of the Windows Update Service status check script

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] “Administrator”))
{
    Write-Warning “You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!”
    Break
}
$servers = @(Get-Content C:\Users\armoradmin.PGSPRO\Desktop\HP\hpallprod_order.txt)
$counter = 0
$started_service = 0
$stopped_service = 0
$needs_attention = 0
write-host "Hostname     Status"
foreach($server in $servers)
{
    $counter++
# Get-Service *wuauserv* -computername $server | Select name,status,machinename,startuptype |sort machinename |format-table -autosize
    $stored_service = Get-Service *wuauserv* -computername $server
    $stored_status = $stored_service.Status
    $stored_computername = $stored_service.MachineName
    If($stored_status -eq "Running")
	{
        Write-host "$stored_computername $stored_status" -ForegroundColor Green
        $started_service++
	}
    Elseif($stored_status -eq "Stopped")
	{
        Write-host "$stored_computername $stored_status" -ForegroundColor Yellow
        $stopped_service++
	}
    Else{
        Write-Host "Service Needs Attention: $stored_computername $stored_status" -ForegroundColor Red
        $needs_attention++
	}
} 

Write-host -NoNewline "There are $started_service vms with the wuauserv service" ; Write-host " Started" -ForegroundColor Green
Write-host -NoNewline "There are $stopped_service vms with the wuauserv service" ; Write-host " Stopped" -ForegroundColor Yellow
Write-host -NoNewline "And there are $Needs_attention vms with a service in" ; Write-host " neither state." -ForegroundColor Red

