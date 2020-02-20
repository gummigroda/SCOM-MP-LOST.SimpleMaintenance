param ()

function Write-Log([string]$Message) {
	$printDate = (get-date -F "yyyy-MM-dd HH:mm:ss.fff")
	$script:traceLog += ("{0} | {1}" -f $printDate, $Message)
}

try{
	# Set stuff
	[string]$scriptName = 'LOST.Delete.Disabled.Objects.ps1'
	[string]$scriptVersion = 'v1.01'
	[int]$evtID = 1337
	[string[]]$script:traceLog = @()
	# type, 1=Error, 2=Warning, 4=Information
	[int]$EventType = 4

	# Start It!
	$StartTime = Get-Date
	
	Write-Log -Message ("ScriptVersion: [{0}], Running as: [{1}]" -f $scriptVersion, (whoami))
	Write-Log -Message ("Start deletion of disabled class instances...")

	# Create MOM Script API and Discoverydata
	Write-Log -Message "Creating MOM Object..."
	$api = new-object -comObject 'MOM.ScriptAPI'

	Write-log -Message("Importing assemblies...")
	[Reflection.Assembly]::Load("Microsoft.EnterpriseManagement.Core, Version=7.0.5000.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")
	[Reflection.Assembly]::Load("Microsoft.EnterpriseManagement.OperationsManager, Version=7.0.5000.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")

	Write-Log -Message "Connecting to localhost SDK..."
	$mg = [Microsoft.EnterpriseManagement.ManagementGroup]::Connect("localhost")
	Write-Log -Message "Deleting disabled objects..."
	$mg.EntityObjects.DeleteDisabledObjects()
}
catch {
	Write-Log -Message ("Error!`n $_ `n")
	$EventType = 1
}
finally {
	# type, 1=Error, 2=Warning, 4=Information
	Write-Log ("Deletion of disabled objects completed in {0} seconds." -f ((Get-date) - $StartTime).TotalSeconds)
	$api.LogScriptEvent($scriptName, $evtID, $EventType, "`n$($script:traceLog | Out-String)")
}
