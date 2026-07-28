#Requires -Version 7.0

[CmdletBinding()]
param(
    [ValidateRange(30, 600)]
    [int]$TimeoutSeconds = 180,

    [switch]$SkipImagePull
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SqlServerLab.Common.ps1')

Write-Host 'Validating Docker and local configuration...'
Assert-DockerReady
Assert-LabConfiguration

if (-not $SkipImagePull) {
    Write-Host 'Pulling the configured SQL Server image...'
    Invoke-ComposeCommand -Arguments @('pull', $script:SqlServerService)
}

Write-Host 'Starting SQL Server...'
Invoke-ComposeCommand -Arguments @('up', '-d', $script:SqlServerService)
Wait-SqlServerHealthy -TimeoutSeconds $TimeoutSeconds

$coreScripts = @(
    'sql/01_create_database.sql'
    'sql/02_create_schema.sql'
    'sql/03_insert_sample_data.sql'
    'sql/07_create_reporting_model.sql'
    'sql/08_load_reporting_model.sql'
    'sql/04_analysis_queries.sql'
)

Write-Host 'Running the ordered database workflow...'
& (Join-Path $PSScriptRoot 'Invoke-SqlScript.ps1') -Path $coreScripts

Write-Host 'Verifying the resulting database state...'
& (Join-Path $PSScriptRoot 'Test-LabConnection.ps1')

Write-Host 'Testing enforced data-integrity rules...'
& (Join-Path $PSScriptRoot 'Test-DataIntegrity.ps1')

Write-Host 'Verifying the dimensional reporting model...'
& (Join-Path $PSScriptRoot 'Test-ReportingModel.ps1')

$port = Get-DotEnvValue -Path $script:EnvironmentFile -Name 'MSSQL_PORT'

if ([string]::IsNullOrWhiteSpace($port)) {
    $port = '14333'
}

Write-Host ''
Write-Host 'SQL Server lab is ready.'
Write-Host "Server: 127.0.0.1,$port"
Write-Host 'Database: dpa_training'
Write-Host 'User: sa'