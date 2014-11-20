function Invoke-FromTask {
<#
.SYNOPSIS
Invokes a command inside of a scheduled task

.DESCRIPTION
This invokes the boxstarter scheduled task. 
The task is run in an elevated session using the provided 
credentials. If the processes started by the task become idle for 
more that the specified timeout, the task will be terminated. All 
output and any errors from the task will be streamed to the calling 
session. 

 .PARAMETER Command
 The command to run in the task.

.PARAMETER IdleTimeout
The number of seconds after which the task will be terminated if it 
becomes idle. The value 0 is an indefinite timeout and 120 is the 
default.

.PARAMETER TotalTimeout
The number of seconds after which the task will be terminated whether
it is idle or active.

.EXAMPLE
Invoke-FromTask Install-WindowsUpdate -AcceptEula

This will install Windows Updates in a scheduled task

.EXAMPLE
Invoke-FromTask "DISM /Online /Online /NoRestart /Enable-Feature /Telnet-Client" -IdleTimeout 20

This will use DISM.exe to install the telnet client and will kill 
the task if it becomes idle for more that 20 seconds.

.LINK
http://boxstarter.org
Create-BoxstarterTask
Remove-BoxstarterTask
#>
    param(
        $command, 
        $idleTimeout=60,
        $totalTimeout=3600
    )
    Write-BoxstarterMessage "Invoking $command in scheduled task" -Verbose
    Add-TaskFiles $command

    $taskProc = start-Task

    if($taskProc -ne $null){
        write-debug "Command launched in process $taskProc"
        $waitProc=get-process -id $taskProc -ErrorAction SilentlyContinue
        Write-Debug "Waiting on $($waitProc.Id)"
    }

    Wait-ForTask $waitProc $idleTimeout $totalTimeout

    try{$errorStream=Import-CLIXML $env:temp\BoxstarterError.stream} catch {$global:error.RemoveAt(0)}
    $str=($errorStream | Out-String)
    if($str.Length -gt 0){
        throw $errorStream
    }
}

function Get-ChildProcessMemoryUsage {
    param($ID=$PID)
    [int]$res=0
    Get-WmiObject -Class Win32_Process -Filter "ParentProcessID=$ID" | % { 
        if($_.ProcessID -ne $null) {
            $proc = Get-Process -ID $_.ProcessID -ErrorAction SilentlyContinue
            if($proc -ne $null){
                $res += $proc.PrivateMemorySize + $proc.WorkingSet
                Write-Debug "$($_.Name) $($proc.PrivateMemorySize + $proc.WorkingSet)"
            }
        }
    }
    Get-WmiObject -Class Win32_Process -Filter "ParentProcessID=$ID" | % { 
        if($_.ProcessID -ne $null) {
            $proc = Get-Process -ID $_.ProcessID -ErrorAction SilentlyContinue
            if($proc -ne $null){
                $res += Get-ChildProcessMemoryUsage $_.ProcessID;
                Write-Debug "$($_.Name) $($proc.PrivateMemorySize + $proc.WorkingSet)"
            }
        }
    }
    $res
}

function Add-TaskFiles($command) {
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("`$ProgressPreference='SilentlyContinue';$command"))
    $fileContent=@"
Start-Process powershell -Wait -RedirectStandardError $env:temp\BoxstarterError.stream -RedirectStandardOutput $env:temp\BoxstarterOutput.stream -ArgumentList "-noprofile -ExecutionPolicy Bypass -EncodedCommand $encoded"
Remove-Item $env:temp\BoxstarterTask.ps1 -ErrorAction SilentlyContinue
"@
    Set-Content $env:temp\BoxstarterTask.ps1 -value $fileContent -force
    new-Item $env:temp\BoxstarterOutput.stream -Type File -Force | out-null
    new-Item $env:temp\BoxstarterError.stream -Type File -Force | out-null
}

function start-Task{
    $tasks=@()
    $tasks+=gwmi Win32_Process -Filter "name = 'powershell.exe' and CommandLine like '%-EncodedCommand%'" | select ProcessId | % { $_.ProcessId }
    Write-Debug "Found $($tasks.Length) tasks already running"
    $taskResult = schtasks /RUN /I /TN 'Boxstarter Task'
    if($LastExitCode -gt 0){
        throw "Unable to run scheduled task. Message from task was $taskResult"
    }
    write-debug "Launched task. Waiting for task to launch command..."
    do{
        if(!(Test-Path $env:temp\BoxstarterTask.ps1)){
            Write-Debug "Task Completed before its process was captured."
            break
        }
        $taskProc=gwmi Win32_Process -Filter "name = 'powershell.exe' and CommandLine like '%-EncodedCommand%'" | select ProcessId | % { $_.ProcessId } | ? { !($tasks -contains $_) }

        Start-Sleep -Second 1
    }
    Until($taskProc -ne $null)

    return $taskProc
}

function Test-TaskTimeout($waitProc, $idleTimeout) {
    if($memUsageStack -eq $null){
        $script:memUsageStack=New-Object -TypeName System.Collections.Stack
    }
    if($idleTimeout -gt 0){
        $lastMemUsageCount=Get-ChildProcessMemoryUsage $waitProc.ID
        Write-Debug "Memory read: $lastMemUsageCount"
        Write-Debug "Memory count: $($memUsageStack.Count)"
        $memUsageStack.Push($lastMemUsageCount)
        if($lastMemUsageCount -eq 0 -or (($memUsageStack.ToArray() | ? { $_ -ne $lastMemUsageCount }) -ne $null)){
            $memUsageStack.Clear()
        }
        if($memUsageStack.Count -gt $idleTimeout){
            Write-BoxstarterMessage "Task has exceeded its timeout with no activity. Killing task..."
            KillTree $waitProc.ID
            throw "TASK:`r`n$command`r`n`r`nIs likely in a hung state."
        }
    }
    Start-Sleep -Second 1
}

function Wait-ForTask($waitProc, $idleTimeout, $totalTimeout){
    $reader=New-Object -TypeName System.IO.FileStream -ArgumentList @(
        "$env:temp\BoxstarterOutput.Stream",
        [system.io.filemode]::Open,[System.io.FileAccess]::ReadWrite,
        [System.IO.FileShare]::ReadWrite)
    try{
        $procStartTime = $waitProc.StartTime
        while($waitProc -ne $null -and !($waitProc.HasExited)) {
            $timeTaken = [DateTime]::Now.Subtract($procStartTime)
            if($totalTimeout -gt 0 -and $timeTaken.TotalSeconds -gt $totalTimeout){
                Write-BoxstarterMessage "Task has exceeded its total timeout. Killing task..."
                KillTree $waitProc.ID
                throw "TASK:`r`n$command`r`n`r`nIs likely in a hung state."
            }

            $byte = New-Object Byte[] 100
            $count=$reader.Read($byte,0,100)
            if($count -ne 0){
                $text = [System.Text.Encoding]::Default.GetString($byte,0,$count)
                $text | Out-File $boxstarter.Log -append
                $text | write-host -NoNewline
            }
            else {
                Test-TaskTimeout $waitProc $idleTimeout
            }
        }
        Start-Sleep -Second 1
        Write-Debug "Proc has exited: $($waitProc.HasExited) or Is Null: $($waitProc -eq $null)"
        $byte=$reader.ReadByte()
        $text=$null
        while($byte -ne -1){
            $text += [System.Text.Encoding]::Default.GetString($byte)
            $byte=$reader.ReadByte()
        }
        if($text -ne $null){
            $text | out-file $boxstarter.Log -append
            $text | write-host -NoNewline
        }
    }
    finally{
        $reader.Dispose()
        if($waitProc -ne $null -and !$waitProc.HasExited){
            KillTree $waitProc.ID
        }
    }    
}

function KillTree($id){
    Get-WmiObject -Class Win32_Process -Filter "ParentProcessID=$ID" | % { 
        if($_.ProcessID -ne $null) {
            kill $_.ProcessID -ErrorAction SilentlyContinue -Force
            Write-Debug "Killing $($_.Name)"
            KillTree $_.ProcessID
        }
    }
    Kill $id -ErrorAction SilentlyContinue -Force
}