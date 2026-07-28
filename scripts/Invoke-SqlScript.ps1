#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SqlServerLab.Common.ps1')

Assert-DockerReady
Assert-LabConfiguration
Assert-SqlServerHealthy

$sqlRootFullPath = [IO.Path]::GetFullPath($script:SqlRoot)

foreach ($item in $Path) {
    $candidatePath = if ([IO.Path]::IsPathRooted($item)) {
        $item
    }
    else {
        Join-Path $script:RepositoryRoot $item
    }

    if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
        throw "SQL script not found: $candidatePath"
    }

    $resolvedPath = (Resolve-Path -LiteralPath $candidatePath).Path
    $relativePath = [IO.Path]::GetRelativePath($sqlRootFullPath, $resolvedPath)

    if ($relativePath -eq '..' -or $relativePath.StartsWith("..$([IO.Path]::DirectorySeparatorChar)")) {
        throw "SQL scripts must be located inside $script:SqlRoot. Rejected path: $resolvedPath"
    }

    $containerPath = '/workspace/sql/' + ($relativePath -replace '\\', '/')

    Write-Host "Running $relativePath..."
    Invoke-ContainerSqlCmd -SqlCmdArguments @('-i', $containerPath)
}
