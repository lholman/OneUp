﻿function Invoke-BoxStarterBuild {
<#
.SYNOPSIS
Packs a specific package or all packages in the Boxstarter Repository

.DESCRIPTION
Invoke-BoxStarterBuild packs either a single package or all packages
in the local repository. The packed .nupkg is placed in the root of
the LocalRepo and is then able to be consumed by 
Invoke-ChocolateyBoxstarter.

.PARAMETER Name
The name of the package to pack

.PARAMETER All
Indicates that all package directories in the repository should be packed

.LINK
http://boxstarter.org
about_boxstarter_chocolatey
Invoke-BoxstarterBuild
New-BoxstarterPackage
#>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ParameterSetName='name')]
        [string]$name,
        [Parameter(Position=0,ParameterSetName='all')]
        [switch]$all,
        [switch]$quiet
    )
    Check-Chocolatey
    $choco="$env:ChocolateyInstall\chocolateyinstall\chocolatey.ps1"
    if(!$boxstarter -or !$boxstarter.LocalRepo){
        throw "No Local Repository has been set in `$Boxstarter.LocalRepo."
    }
    pushd $Boxstarter.LocalRepo
    try{
        if($name){
            $searchPath = join-path $name "$name.nuspec"
            Write-BoxstarterMessage "Searching for $searchPath" -Verbose
            if(!(Test-Path $searchPath)){
                throw "Cannot find $($Boxstarter.LocalRepo)\$searchPath"
            }
            .$choco Pack (join-path $name "$name.nuspec") | out-null
            if(!$quiet){
                Write-BoxstarterMessage "Your package has been built. Using Boxstarter.bat $name or Install-BoxstarterPackage $name will run this package." -nologo
            }
        } else {
             if($all){
                Write-BoxstarterMessage "Scanning $($Boxstarter.LocalRepo) for package folders"
                Get-ChildItem . | ? { $_.PSIsContainer } | % {
                    $directoriesExist=$true
                    Write-BoxstarterMessage "Found directory $($_.name). Looking for $($_.name).nuspec"
                    if(Test-Path (join-path $_.name "$($_.name).nuspec")){
                        .$choco Pack (join-path . "$($_.Name)\$($_.Name).nuspec") | out-null
                        if(!$quiet){
                            Write-BoxstarterMessage "Your package has been built. Using Boxstarter.bat $($_.Name) or Install-BoxstarterPackage $($_.Name) will run this package." -nologo                        
                        }
                    }
                }
                if($directoriesExist -eq $null){
                    Write-BoxstarterMessage "No Directories exist under $($boxstarter.LocalRepo)"
                }
            }
        }
    }
    finally {
        popd    
    }
}