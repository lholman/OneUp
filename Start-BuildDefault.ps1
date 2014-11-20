#*==========================================================================================
#* Author: Lloyd Holman
#* Company: Hitachi Consulting UK

#* Requirements:
#* 1. Install PowerShell 2.0+ on local machine
#* 2. Execute from build.bat
#*==========================================================================================
#* Purpose: Performs the grunt of the psake based build of the Hitachi applications
#*==========================================================================================
#*==========================================================================================
#* SCRIPT BODY
#*==========================================================================================
Properties { 
	$basePath = Resolve-Path .
	$basePackagePath = "$basePath\_DeployablePackages" 
}

$ErrorActionPreference = 'Stop'

Task default -depends New-AutoUnattendIsoImages

#*================================================================================================
#* Purpose: 
#*================================================================================================
Task New-AutoUnattendIsoImages {

	if ((Test-Path -path "$basePackagePath") -eq $True )
	{
		Remove-Item -path "$basePackagePath" -Force -Recurse
	}
	New-Item -ItemType directory -path "$basePackagePath"
	
	$operatingSystemFlavours = Get-ChildItem .\AutoUnattend
	foreach ($operatingSystemFlavour in $operatingSystemFlavours)
	{
		New-Item -ItemType directory -path "$basePackagePath\$operatingSystemFlavour"
		$isoFileName = "AutoUnattend.iso"
		exec { & "$basePath\lib\DiscUtilsBin-0.10\ISOCreate.exe" "$basePackagePath\$operatingSystemFlavour\$isoFileName" "$basePath\AutoUnattend\$operatingSystemFlavour"}
	}
	
}
