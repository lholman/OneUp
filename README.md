#OneUp#

##Summary##
The approach of the OneUp is to enable raw bones automation of Windows OS installation and configuration via script.  We do not start from the common and non-scalable approach of OS imagining, conversely we bootstrap a Windows ISO install from script.

##Design decisions##
There are many fully automated configuration management systems on the market, for example, but not limited to [Puppet](http://puppetlabs.com/), [Chef](http://www.getchef.com/chef/), [Microsoft System Center Configuration Manager (SCCM)](http://bit.ly/1kBugec) and [Windows Deployment Services (WDS)](http://en.wikipedia.org/wiki/Windows_Deployment_Services).  
All fully automated and distributed approaches require varying levels of infrastructure capability, configuration, deployment management and maintenance, to keep the adoption high and the technical barriers low the approach for OneUp was to architect with as few dependencies as possible, it was agreed acceptable to provide a solution where machine configuration is user initiated, i.e. OneUp can be used to provision physical or virtual machines.  
The above said, it is imperative to note that the approach and resultant architecture of OneUp is in fact a solution that could be relatively simply encompassed to be centrally managed and controlled remotely by any of the above or other enterprise configuration management solutions.

##What about Vagrant##
OneUp is a great way to provision a Windows machine from versioned script that can then be subsequently built in to a Vagrant box file.

##How can OneUp be used?##
* Automate the build of a physical Microsoft Windows 8.1 machine (suitable for then hosting Hyper-V VM's) via a USB stick and Windows ISO on DVD.
* Automate the Build of Microsoft Windows Hyper-V Virtual Machines with differing roles and configuration using the same scripts and resources as above.

##Notable technologies##
* Powershell - The go to solution for automating the Windows platform, this is a logical choice for script automation.
* [Nuget](http://www.nuget.org) - NuGet is standard for package management on the Microsoft development platform, think assembly, manifest, dependency management and versioning all rolled in to a standard.
* [Chocolatey](http://www.chocolatey.org) - Machine package manager for Windows, utilises Nuget for package distribution, open source with ever increasing community support.
* [BoxStarter](http://www.boxtsarter.org) - Repeatable, reboot resilient windows environment installations using Chocolatey packages. When its time to repave either bare metal or virtualized instances, locally or on a remote machine, Boxstarter can automate both trivial and highly complex installations. Compatible with all Windows versions from Windows 7/2008 R2 forward.
* [AutoUnattend](http://www.??) - Answer files for Windows silent installation. 

##Assumptions##
1. For provisioning VM's on a host, the host machine has a Windows 8.1 ISO called 'en-gb_windows_8_1_enterprise_x64_dvd_2971910.iso' in a 'C:\Source' folder.

##Running OneUp to build a Virtual Machine##
1. Clone OneUp to the c:\OneUp folder on your host
1. Run C:\OneUp>.\BuildVM.ps1

##More detail##

1. A CommandLine Logon script is defined within the 'AutoUnattend.xml' (see below), this kick starts the Boxstarter script
```
	<LogonCommands>
		<AsynchronousCommand wcm:action="add">
			<Description>Run BoxStarter script</Description>
			<Order>1</Order>
			<CommandLine>\\hostname\Boxstarter\Boxstarter DeveloperBaseWindows81</CommandLine>
		</AsynchronousCommand>
	</LogonCommands>
```
