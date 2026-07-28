#Requires -Version 7.0

[CmdletBinding()]
param(
    [switch]$RemoveContainer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SqlServerLab.Common.ps1')

Assert-DockerReady
Assert-LabConfiguration

if ($RemoveContainer) {
    Write-Host 'Stopping and removing the lab container. The named database volume is preserved.'
    Invoke-ComposeCommand -Arguments @('down', '--remove-orphans')
    return
}

Write-Host 'Stopping the SQL Server container. The container and named database volume are preserved.'
Invoke-ComposeCommand -Arguments @('stop', $script:SqlServerService)
