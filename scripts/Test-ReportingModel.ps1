#Requires -Version 7.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SqlServerLab.Common.ps1')

Assert-DockerReady
Assert-LabConfiguration
Assert-SqlServerHealthy

Write-Host 'Running reporting-model reconciliation checks...'
Invoke-ContainerSqlCmd -SqlCmdArguments @(
    '-i'
    '/workspace/sql/09_verify_reporting_model.sql'
)