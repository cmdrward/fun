<#
.SYNOPSIS
Checks pending updates on (primarily) HP vms. Version 3.2

.DESCRIPTION
Get-WUDownloadStatus remotely checks a single vm or list of vms (in this version, specifically a list of HP environment vms) for pending or needed windows updates. It's goal is to check whether updates have been successfully downloaded in preparation for their patching window.

.PARAMETER computername
Asks you for the name of a single computer to test against.

.PARAMETER itg
Runs the standard check for pending updates using the filepath for the ITG server list.

.PARAMETER dev
Runs the standard check for pending updates using the filepath for the DEV server list.

.PARAMETER prechecks
Only runs the check for the wuauserv service startup type and module filepath prerequisites.

.PARAMETER updatehistory
Asks you for the name of a single vm to retrieve the last 10 entries on it's update history.

.EXAMPLE
.\Get-WUDownloadStatus.ps1 -computername

.EXAMPLE
.\Get-WUDownloadStatus.ps1 -itg

.EXAMPLE
.\Get-WUDownloadStatus.ps1 -updatehistory

.LINK
https://one.rackspace.com/display/Armor/HP+Production+Patching+Protocol

.NOTES
Prerequisites:
1) Have the pswindowsupdate module installed at C:\program files\powershell\modules (will be checked as part of the script)
2) Have winrm enabled on all computers the script is running against 
3) Have wuauserv in a startup type other than disabled (will be checked as part of the script)

KB for common use and troubleshooting located at https://one.rackspace.com/display/Armor/HP+Production+Patching+Protocol

Plans for improvement
1) Add switch for initiating a download on a certain vm for a certain update
#> 

#Requires -Version 3.0
[CmdletBinding()] 
    Param (
	[switch]$computername,
    [switch]$itg,
    [switch]$dev,
    [switch]$prechecks,
	[switch]$updatehistory
	)


Begin {
#Generic checks and warnings
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	If ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false)
		{
		Write-Warning “You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!”
		Break
		}
	

function computerlist_defaultPRO {
	#Multiple vms for larger scale use
	$computers = Get-Content C:\Users\armoradmin.PGSPRO\Desktop\HP\hpallprod_order.txt
	Write-host "Please standby! This script can take several minutes to run depending on the number of vms being checked" -BackgroundColor Blue
	pre-checks
    WUchecks
	}

function computerlist_itg {
	#Multiple vms for larger scale use
	$computers = Get-Content C:\Users\armoradmin.PGSITG\Desktop\HP\ITG_all.txt
	Write-host "Please standby! This script can take several minutes to run depending on the number of vms being checked" -BackgroundColor Blue
    pre-checks
    WUchecks
	}

function computerlist_dev {
	#Multiple vms for larger scale use
	$computers = Get-Content C:\Users\armoradmin.PGSDEV\Desktop\HP\DEV_all.txt
	Write-host "Please standby! This script can take several minutes to run depending on the number of vms being checked" -BackgroundColor Blue
    pre-checks
    WUchecks
	}

function computerlist_single {
	#single vm for testing purposes
	$computers = Read-host "Please type the hostname of the vm you would like tested:"
    pre-checks
    WUchecks
    }

function pre-checks {
	 ForEach ($computer in $computers){
	#Ensures wuauserv service is not disabled, which would cause false results
		$wu_servicestatus = Get-Service wuauserv -ComputerName $computer
		If($wu_servicestatus.StartType -eq "Disabled")
			{
			Write-host $computer "has a disabled Windows Update Service. This service MUST be enabled to work." -ForegroundColor Red
			continue
			}
	#Ensures that the needed module is present for the commands to work
		$pathcheck = test-path \\$computer'\c$\Program Files\WindowsPowerShell\Modules\pswindowsupdate\PSWindowsUpdate.psm1'
		If($pathcheck -ne "True")
			{
			Write-host $computer "does not have the needed PSWindowsUpdate module present for this script to function. `nPlease install the PSWindowsUpdate module at 'C:\Program Files\WindowsPowerShell\Modules\'" -ForegroundColor Red
			continue
			}
		}
    Write-host "Prerequisite checks complete" -ForegroundColor Green
	}

function WUchecks {
	
	#Invokes the commands on each computer in the $computers list (results display out of order)
	Invoke-Command -ComputerName $computers -ScriptBlock {
	#Checks the windows update history for statuses indicating an update has installed and is just pending a reboot to complete    
		$remote_hostname = hostname
		$updatelist = get-wuhistory
		Foreach($update in $updatelist)
			{
			If($update.Result -eq "InProgress")
				{
				Write-host $remote_hostname 'Update installed, pending reboot ---' $update.title -ForegroundColor Yellow
				}
			Elseif($update.Result -eq "Succeeded")
				{
				#Do nothing, continue to next test
				}
			}	
	#Uses the get-windowsupdate command to pull the status of updates in "Needed" status. Gives green status for downloaded (expected condition), yellow for not downloaded (needs attention), and red for anything unexpected.		
		$windowsupdate_statuses = Get-WindowsUpdate
		If($windowsupdate_statuses.Status -eq $null)
			{
			write-host $remote_hostname "No available updates found for download" -ForegroundColor Yellow
			}
		Else
			{
			foreach($windowsupdate_status in $windowsupdate_statuses)
				{
				If($windowsupdate_status.Status -eq '-D-----')
					{
					write-host $remote_hostname "Update download complete:" $windowsupdate_status.KB $windowsupdate_status.Status $windowsupdate_status.title -ForegroundColor Green
					}
				Elseif($windowsupdate_status.Status -eq '-------')	
					{
					write-host $remote_hostname "Update not yet downloaded:" $windowsupdate_status.KB $windowsupdate_status.Status $windowsupdate_status.title -ForegroundColor Yellow
					}
				Else
					{
					Write-Host $remote_hostname "Attention needed on computer" -ForegroundColor Red
					Write-Host $windowsupdate_status -foregroundcolor Red
					}	
				}	
			}	
		}
    }

function get-wuhistory {
	$computers = Read-host "Please type the hostname of the vm to pull recent update history from:"
	pre-checks
	Invoke-Command -ComputerName $computers -ScriptBlock {get-wuhistory -last 10}
	}
	
}

Process
	{switch ($true) {
		$computername	{computerlist_single | Out-default}
		$itg			{computerlist_itg | Out-default}
		$dev		 	{computerlist_dev | Out-default}
        $prechecks		{pre-checks | Out-default}
		$updatehistory	{get-wuhistory | Out-default}
		default{
			computerlist_defaultPRO | Out-default
			}
		}
	}