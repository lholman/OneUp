#*==========================================================================================
#* Author: Lloyd Holman

#* Requirements:
#* 1. Install PowerShell 2.0+ on local machine
#* 2. Execute from build.bat

#* Parameters: -task* (The build task type to run).
#*	(*) denotes required parameter, all others are optional.

#* Example use to run the default Invoke-DebugCompile task:  
#* .\Start-ScheduledTasks.ps1

#*==========================================================================================
#* Purpose: Wraps the core Start-BuildDefault.ps1 script and does the following
#* - starts by importing the psake PowerShell module (we have this in a relative path in source control) .
#* - it then invokes the default psake build script in the current working folder (i.e. Start-BuildDefault.ps1),
#* passing the first parameter passed to the batch file in as the psake task.  Start-BuildDefault.ps1 obviously does
#* all the build work for us.
#* - finally the psake PowerShell module is removed.

#*==========================================================================================
#*==========================================================================================
#* SCRIPT BODY
#*==========================================================================================
param([string]$task = "New-BoxStarterBuildPackages", [string]$configMode = "Debug", [string]$projectToBuild = "", [string]$buildCounter = "0", [string]$serverName = "$($env:computername)", [string]$environment = "Acceptance", [string]$runAsUserName = "$($env:username)", [string]$runAsUserPassword = "", [string]$forceDeploy = $false)

Write-Host "Using the following parameter values (sensible defaults used where parameter not supplied)"
Write-Host "task: $task"
Write-Host "projectToBuild: $projectToBuild"
Write-Host "configMode: $configMode"
Write-Host "buildCounter: $buildCounter"
Write-Host "serverName: $serverName"
Write-Host "environment: $environment"
Write-Host "runAsUserName : $runAsUserName "
Write-Host "runAsUserPassword: $runAsUserPassword"
Write-Host "forceDeploy: $forceDeploy"

Import-Module '.\lib\psake\psake.psm1'; 
#$psake
#$psake.use_exit_on_error = $true
Invoke-psake .\Start-BuildDefault.ps1 -t $task -framework '4.0' -parameters @{"p1"=$configMode;"p2"=$projectToBuild;"p3"=$buildCounter;"p4"=$serverName;"p5"=$environment;"p6"=$runAsUserName;"p7"=$runAsUserPassword;"p8"=$forceDeploy} 
Remove-Module [p]sake -ErrorAction 'SilentlyContinue'

