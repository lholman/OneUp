Update-ExecutionPolicy Unrestricted

#Check if this workstation is a domain member, taken from http://msdn.microsoft.com/en-us/library/windows/desktop/aa394102(v=vs.85)
$computer = Get-WMIObject win32_computersystem
$memberStatus = ($computer).domainrole
$domainName = "blabla"
if ($memberStatus -eq 0 -or $memberStatus -eq 2)
{
	#Prompt the user to select whether to join the domain
	$title = "Join $domainName domain?"
	$message = "Would you like to join this computer $($env:computername) to the domain $domainName?"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
		"Select 1 to join this computer $($env:computername) to the domain $domainName."
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
		"Select 2 to NOT join this computer $($env:computername) to the domain $domainName."
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$deploymentOption = $host.ui.PromptForChoice($title, $message, $options, 1) 

	if ($deploymentOption -eq 0)
	{
		#Add the computer to the domain if it's a 'Standalone Workstation' (0) or 'Standalone Server' (2) only
		Add-Computer -DomainName $domainName -Force
		#Add 'Domain Users' to the Local Administrators group on the computer
		$group = [ADSI]"WinNT://./Administrators,group"
		$group.Add("WinNT://$domainName/Domain Users,group")

		if (Test-PendingReboot){Invoke-Reboot}
	}
}

#Copy BoxStarter function from host (to temporarily get us around an issue with mounting ISO's
#if ((Test-Path "C:\Chocolatey\chocolateyinstall\helpers\functions\Install-ChocolateyInstallPackage.ps1.old") -eq $False)
#{
#	Rename-Item "C:\Chocolatey\chocolateyinstall\helpers\functions\Install-ChocolateyInstallPackage.ps1" "C:\Chocolatey\chocolateyinstall\helpers\functions\Install-ChocolateyInstallPackage.ps1.old"
#	Copy-Item -Path "\\R9-FV2Z5\Chocolatey\chocolateyinstall\helpers\functions\Install-ChocolateyInstallPackage.ps1" -Destination "C:\Chocolatey\chocolateyinstall\helpers\functions\Install-ChocolateyInstallPackage.ps1"
#}

#Disable-UAC #Note that Windows 8 and 8.1 can not launch Windows Store applications with UAC disabled.
#Enable-RemoteDesktop

Set-WindowsExplorerOptions -DisableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar
Set-TaskbarOptions -Size Large

#Install-ChocolateyDesktopLink -TargetFilePath "\\DGLAP02\Boxstarter\Boxstarter HitachiDeveloperBaseWindows8"
#Install-ChocolateyShortcut -shortcutFilePath "C:\boxstarter.lnk" -targetPath "\\DGLAP02\Boxstarter\Boxstarter.bat" -arguments "HitachiDeveloperBaseWindows8"


cinst fiddler4
cinst notepadplusplus
cinst beyondcompare

#We have to specify the -source explicitly here as Chocolatey and BoxStarter don't seem to be honouring their secondary NuGet sources.
#cinst HitachiConsulting.VisualStudio2012Premium -source "http://r9-fv2z5-vm0/guestAuth/app/nuget/v1/FeedService.svc;http://chocolatey.org/api/v2" -force

cinst Microsoft-Hyper-V-All -source windowsFeatures
cinst IIS-WebServerRole -source windowsfeatures
cinst IIS-HttpCompressionDynamic -source windowsfeatures
cinst TelnetClient -source windowsFeatures

Install-ChocolateyPinnedTaskBarItem "$env:windir\system32\mstsc.exe"
Install-ChocolateyPinnedTaskBarItem "$env:windir\system32\cmd.exe"
Install-ChocolateyPinnedTaskBarItem "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe"

#Copy-Item (Join-Path -Path (Get-PackageRoot($MyInvocation)) -ChildPath 'console.xml') -Force $env:appdata\console\console.xml

#Install-WindowsUpdate -AcceptEula


