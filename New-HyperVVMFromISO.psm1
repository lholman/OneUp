function New-HyperVVMFromISO{
<#
 
.SYNOPSIS
	Creates a new Hyper-V VM (within the local machines Hyper-V instance), uses sensible defaults that can be optionally overridden and finally boots from a defined ISO file.    
.DESCRIPTION
	Creates a new Hyper-V VM (within the local machines Hyper-V instance), uses sensible defaults that can be optionally overridden and finally boots from a defined ISO file.
	Given the -Force parameter this module will tear down any existing VM's and VHD's, prior to adding the new VM with the same name.	
	Credits: Takes inspiration from http://www.deploymentresearch.com/Research/tabid/62/EntryId/129/Script-to-build-a-VM-in-Hyper-V-and-boot-from-an-ISO.aspx and adds some more convention and error handling.
.NOTES
    Author: Lloyd Holman
    DateCreated: 10/12/2013
  Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER VMIso
	Mandatory.  The path to the ISO that the new VM should boot from.  Supports local "c:\examplefolder" or UNC style "\\exampledrive\share" style paths.  The only mandatory parameter.
.PARAMETER VMName
	Optional.  Provides the ability to set the new VM name.  The default encourages a naming convention of $env:computername + "-VM", e.g. hostserver-VM
.PARAMETER VMNameSuffix
	Optional.  Uniquely identifies the new VM whilst maintaing the VMName convention.  Defaults to "0".
.PARAMETER VMLocation
	Optional.  The parent folder under which Hyper-V will create the VM.  Defaults to "C:\VirtualMachines\".	
.PARAMETER VMStartupMemory
	Optional.  The initial amount of memory, in bytes, to be assigned to the new VM.  Dynamic memory is enabled, Minimum memory is calculated as half the value of VMStartupMemory and conversely Maximum memory is calculated as double the value of VMStartupMemory.  Defaults to 1024MB. 
.PARAMETER VMDiskSize
	Optional.  The maximum size, in bytes, of the virtual hard disk (VHD) to be created.  Defaults to 60GB. 
.PARAMETER VMNetwork
	Optional.  Specifies the friendly name of the virtual switch if you want to connect the new VM to an existing virtual switch to provide connectivity to a network. Hyper-V automatically creates a VM with one virtual network adapter, but connecting it to a virtual switch is optional.  Defaults to "External NIC"
.PARAMETER Force
	Optional.  Indicates whether to tear down any existing VM's and VHD's, prior to adding the new VM with the same name.	
.EXAMPLE 
	Import-Module .\New-HyperVVMFromISO.psm1
	Import the module
.EXAMPLE	
	New-HyperVVMFromISO -VMIso "C:\path_to_iso\en-gb_windows_8_1_enterprise_x64_dvd_2971910.iso"
	Generate a new VM, failing if an existing VM exists with the same name.
.EXAMPLE
	New-HyperVVMFromISO -VMIso "C:\path_to_iso\en-gb_windows_8_1_enterprise_x64_dvd_2971910.iso" -Force
	Generate a new VM, deleting any VM or VHD with the same name first.
.EXAMPLE 
	Remove-Module New-HyperVVMFromISO
	Remove the module	
#>
	[cmdletbinding()]
		Param(
			[Parameter(Position = 0, Mandatory = $True )]
				[string]$VMIso,				
			[Parameter(Position = 1, Mandatory = $False )]
				[string]$VMName = $env:computername + "-VM",
			[Parameter(Position = 2, Mandatory = $False )]
				[string]$VMNameSuffix = "0",				
			[Parameter(Position = 3, Mandatory = $False )]
				[string]$VMLocation = "C:\VirtualMachines\",
			[Parameter(Position = 4, Mandatory = $False )]
				[Int64]$VMStartupMemory = 1024MB,	
			[Parameter(Position = 5, Mandatory = $False )]
				[UInt64]$VMDiskSize = 60GB,
			[Parameter(Position = 6, Mandatory = $False )]
				[string]$VMNetwork = "External NIC",						
			[Parameter(Position = 7, Mandatory = $False )]
				[switch]$Force						
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				Try 
				{
					#$VMIso = "C:\Source\en-gb_windows_8_1_enterprise_x64_dvd_2971910.iso"
					$VMName = $VMName + $VMNameSuffix
					Write-Host "VMName: $VMName"
					
					#We use spaces in the path to be consistent with the 'Virtual Machines' folder Hyper-V makes at the same level :(
					$VmDisk1Name = "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"

					#Let's check whether we already have a VM with the same name before proceeding as we want this to be idempotent, otherwise
					#Hyper-V silently creates a new VM with the same name (different Id), nasty.
					$vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
					
					if ($vm -ne $null)
					{
						if ($Force)
						{	
							$vhdLocation = Get-VMHardDiskDrive -VMName $VMName
							if ($vhdLocation -eq $null)
							{
								throw "Unable to identify Hard Disk for $VMName"
							}
							Write-Warning "Removing existing primary Hard Disk from Virtual Machine with name '$VMName' as -Force parameter was specified"
							
							#We Suspend, then Stop the VM prior to attempting to Remove the VM or VHD, this should work in most cases where the VM is sitting in a non-Stoppable state. 
							Suspend-VM -Name $VMName
							Stop-VM -Name $VMName -Force
							
							$vhdPathToDelete = $vhdLocation[0].Path
							Get-VMHardDiskDrive -VMName $VMName -ControllerNumber 0 | Remove-VMHardDiskDrive
							if (Test-Path "$vhdPathToDelete")
							{
								Write-Warning "Removing existing Virtual Machine Hard Disk from location $vhdPathToDelete as -Force parameter was specified"
								Remove-Item "$vhdPathToDelete"
							}
							Write-Warning "Removing existing Virtual Machine with name $VMName as -Force parameter was specified"
							
							Remove-VM -Name $VMName -Force
						}
						else 
						{
							throw "A Virtual Machine with the name $VMName already exists.  Either set the VMName and VMId parameters accordingly to provide a unique name or specify the -Force parameter to delete any existing VM and VHD with the name $VMName."
						}
					}

					#A final catch, in case the VM has been manually deleted from 'Hyper-V Manager' but the Hard Disk remains
					if (Test-Path "$VmDisk1Name")
					{
						Write-Warning "Removing existing Virtual Machine Hard Disk from location $VmDisk1Name as -Force parameter was specified"
						Remove-Item "$VmDisk1Name"
					}

					#Create VM
					New-VM -Name $VMName -BootDevice CD -MemoryStartupBytes $VMStartupMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD -Verbose
					$VMStartupMemoryMin = $VMStartupMemory/2
					$VMStartupMemoryMax = $VMStartupMemory*2
					Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes $VMStartupMemoryMin -MaximumBytes $VMStartupMemoryMax -StartupBytes $VMStartupMemory -Buffer 20

					#Create VHD and attach to VM
					New-VHD -Path $VmDisk1Name -SizeBytes $VMDiskSize -Verbose
					Add-VMHardDiskDrive -VMName $VMName -Path $VmDisk1Name -Verbose

					#Mount the Windows ISO
					Set-VMDvdDrive -VMName $VMName -Path $VMIso -Verbose
					
					#Mount the Autounattend ISO
					Add-VMDvdDrive -VMName $VMName -Path "C:\Dropbox\Work\Datum Generics\Clients\HitachiConsulting\IaC\HitachiDeveloperBaseWindows8Autounattend.iso" -Verbose
					
					Start-VM -VMName $VMName
					
				}
				catch [Exception] {
					throw
				}

		}
}					