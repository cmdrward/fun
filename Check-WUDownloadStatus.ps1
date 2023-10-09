<#
Prerequisites:
1) Have the pswindowsupdate module installed at C:\program files\powershell\modules
2) Have winrm enabled on all computers the script is running against

Plans for improvement
1) Add switch for testing single vm so you don't have to edit the ps1 file.
2) Add switch for initiating a download on a certain vm for a certain update
3) Add a help file
4) Document in KB system
5) Add a switch to get the last few of the wuhistory command to confirm what has been installed
6) Look into jobs to optimize speed https://stackoverflow.com/questions/4016451/can-powershell-run-commands-in-parallel
#> 

#Multiple vms for larger scale use
$computers = Get-Content C:\Users\armoradmin.PGSITG\Desktop\ats415031\computers.txt

#single vm for testing purposes
#$computers = hostname

Write-host "Please standby! This script can take several minutes to run depending on the number of vms being checked" -BackgroundColor Blue

#Goes through each computer in the list
ForEach($computer in $computers)
{
#Invokes the commands on a specified remote computer
Invoke-Command -ComputerName $computer -ScriptBlock {
#Checks the windows update history for statuses indicating an update has installed and is just pending a reboot to complete    
	$remote_hostname = hostname
    $updatelist = get-wuhistory
	Foreach($update in $updatelist)
		{
		If($update.Result -eq "InProgress")
			{
			Write-host 'Update installed, pending reboot ---' $update.title -ForegroundColor Yellow
			}
        Elseif($update.Result -eq "Succeeded")
            {
            #Do nothing, continue to next result
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
				Write-Host "Attention needed on computer" $remote_hostname -ForegroundColor Red
				Write-Host $windowsupdate_status -foregroundcolor Red
				}	
			}	
		}	
			
    }

}