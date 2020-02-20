param ([string]$MGName, [string]$BackupPath, [int]$DaysToKeep)

function Write-Log([string]$Message) {
	$printDate = (get-date -F "yyyy-MM-dd HH:mm:ss.fff")
	$script:traceLog += ("{0} | {1}" -f $printDate, $Message)
}

try{
	# Set stuff
	[string]$scriptName = $MyInvocation.MyCommand.Name
	[string]$scriptVersion = 'v1.01'
	[int]$evtID = 1337
	[string[]]$script:traceLog = @()
	# type, 1=Error, 2=Warning, 4=Information
	[int]$EventType = 4

	# Start It!
	$StartTime = Get-Date
	
	Write-Log -Message ("ScriptVersion: [{0}], Running as: [{1}]" -f $scriptVersion, (whoami))
	Write-Log -Message ("Start Backup of Unsealed MPs. ManagementGroupName: [{0}] BackupPath: [{1}] DaysToKeep: [{2}]" -f $MGName, $BackupPath, $DaysToKeep)

	# Create MOM Script API and Discoverydata
	Write-Log -Message "Creating MOM Object..."
	$api = new-object -comObject 'MOM.ScriptAPI'

	# Import the OperationsManager module and connect to the management group
	try{
		Write-Log -Message ("Importing SCOM Module...")
		$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
		$SCOMModulePath = Join-Path -Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager" -ErrorAction Stop
		Import-module $SCOMModulePath -ErrorAction Stop
		New-DefaultManagementGroupConnection "localhost"
	}
	catch{
		Write-Log -Message ("ERROR: Unable to load OperationsManager module or unable to connect to Management Server.")
		Throw $Error[0].Exception.Message
	}

	# Check BackupPath
	if (-not(Test-Path -Path $BackupPath)){
		Throw ("The Backup Path is not available. Create it or/and check permissions.")
	}
		
	# Create BUP dir
	$BackupPath	= Join-Path -Path $BackupPath -ChildPath $MGName -ErrorAction Stop
	Write-Log -Message ("Creating Backup Directory {0} (if needed)..." -f $BackupPath)
	New-Item -ItemType Directory -Path $BackupPath -Force -ErrorAction Stop | Out-Null
	Write-Log -Message ("Temp Directory {0} for zip..." -f $BackupPath)
	$TmpFolder = New-Item -ItemType Directory -Path ($Env:TEMP + "\ScomMp\" + (Get-Random).ToString()) -Force -ErrorAction Stop
	$ZipFile = $BackupPath + ("\{0}_Unsealed_MPs_Backup_{1}.zip" -f $MGName, (Get-Date).ToString("yyyy-MM-dd_HHmmss"))
	
	# Export the MPs and save to disk
	Get-SCOMManagementpack | Where-Object {$_.Sealed -eq $false} | Export-SCOMManagementPack -Path $TmpFolder -ErrorAction Stop

	Write-Log -Message ("Adding files to Zip...")
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
	[System.IO.Compression.ZipFile]::CreateFromDirectory($TmpFolder, $ZipFile, $compressionLevel, $false)
		
	# All ok, delete the files...
	Write-Log -Message ("Zipfile created, removing source files...")
	Remove-Item -Path $TmpFolder -Recurse -Force

	# Do some Maintenance
	Write-Log -Message("Rinsing old folders...")
	Get-ChildItem -Path $BackupPath -Directory | 
		Where-Object {$_.CreationTime -lt (get-date).AddDays(-$DaysToKeep)} -ErrorAction Stop | 
		Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

	Write-Log -Message "Old files rinsed."

}
catch {
	Write-Log -Message ("Error!`n $_ `n")
	$EventType = 1
}
finally {
	# type, 1=Error, 2=Warning, 4=Information
	Write-Log ("Backup of unsealed Manangement Packs completed in {0} seconds." -f ((Get-date) - $StartTime).TotalSeconds)
	$api.LogScriptEvent($scriptName, $evtID, $EventType, "`n$($script:traceLog | Out-String)")
}
