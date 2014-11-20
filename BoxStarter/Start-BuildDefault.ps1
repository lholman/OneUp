#*==========================================================================================
#* Author: Lloyd Holman

#* Requirements:
#* 1. Install PowerShell 2.0+ on local machine
#* 2. Execute from build.bat
#*==========================================================================================
#* Purpose: Performs the grunt of the psake based build
#*==========================================================================================
#*==========================================================================================
#* SCRIPT BODY
#*==========================================================================================
Properties { 

}

$ErrorActionPreference = 'Stop'

Task default -depends New-BoxStarterBuildPackages

#*================================================================================================
#* Purpose: 
#*================================================================================================
Task New-BoxStarterBuildPackages {

	Remove-Item ".\BuildPackages\*.nupkg" -force 

	Import-Module .\Boxstarter.Chocolatey
	$buildPackages = Get-ChildItem .\BuildPackages
	
	foreach ($buildPackage in $buildPackages)
	{
		
		Invoke-BoxStarterBuild $buildPackage.Name
	}
	
	Remove-Module Boxstarter.Chocolatey
}
