#Requires -Version 7.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SqlServerLab.Common.ps1')

Assert-DockerReady
Assert-LabConfiguration
Assert-SqlServerHealthy

Write-Host 'Running SQL Server setup verification...'
Invoke-ContainerSqlCmd -SqlCmdArguments @(
    '-i'
    '/workspace/sql/05_verify_setup.sql'
)
