#Requires -Version 7.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SqlServerLab.Common.ps1')

Assert-DockerReady
Assert-LabConfiguration
Assert-SqlServerHealthy

Write-Host 'Running executable data-integrity tests...'
Invoke-ContainerSqlCmd -SqlCmdArguments @(
    '-i'
    '/workspace/sql/06_test_integrity_rules.sql'
)
