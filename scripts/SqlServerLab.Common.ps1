#Requires -Version 7.0

Set-StrictMode -Version Latest

$script:RepositoryRoot = Split-Path -Parent $PSScriptRoot
$script:ComposeFile = Join-Path $script:RepositoryRoot 'docker-compose.yml'
$script:EnvironmentFile = Join-Path $script:RepositoryRoot '.env'
$script:SqlRoot = Join-Path $script:RepositoryRoot 'sql'
$script:SqlServerService = 'sqlserver'
$script:SqlCmdPath = '/opt/mssql-tools18/bin/sqlcmd'

function Invoke-DockerCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [switch]$CaptureOutput
    )

    Push-Location $script:RepositoryRoot

    try {
        if ($CaptureOutput) {
            $output = @(& docker @Arguments 2>&1)
            $exitCode = $LASTEXITCODE

            if ($exitCode -ne 0) {
                $details = $output -join [Environment]::NewLine
                throw "Docker command failed with exit code $exitCode.`n$details"
            }

            return $output
        }

        & docker @Arguments
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            throw "Docker command failed with exit code $exitCode: docker $($Arguments -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-ComposeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [switch]$CaptureOutput
    )

    $composeArguments = @(
        'compose'
        '--env-file', $script:EnvironmentFile
        '-f', $script:ComposeFile
    ) + $Arguments

    Invoke-DockerCommand -Arguments $composeArguments -CaptureOutput:$CaptureOutput
}

function Assert-DockerReady {
    [CmdletBinding()]
    param()

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker CLI was not found in PATH.'
    }

    $serverVersion = Invoke-DockerCommand -Arguments @(
        'version'
        '--format', '{{.Server.Version}}'
    ) -CaptureOutput

    if ([string]::IsNullOrWhiteSpace(($serverVersion -join '').Trim())) {
        throw 'Docker Desktop is installed, but the Docker engine did not return a server version.'
    }

    Invoke-DockerCommand -Arguments @('compose', 'version') -CaptureOutput | Out-Null
}

function Get-DotEnvValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $escapedName = [Regex]::Escape($Name)
    $matchingLine = Get-Content -LiteralPath $Path |
        Where-Object { $_ -match "^\s*$escapedName\s*=" } |
        Select-Object -Last 1

    if ($null -eq $matchingLine) {
        return $null
    }

    $value = ($matchingLine -split '=', 2)[1].Trim()

    if (
        ($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))
    ) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    return $value
}

function Assert-LabConfiguration {
    [CmdletBinding()]
    param()

    if (-not (Test-Path -LiteralPath $script:ComposeFile -PathType Leaf)) {
        throw "Compose file not found: $script:ComposeFile"
    }

    if (-not (Test-Path -LiteralPath $script:EnvironmentFile -PathType Leaf)) {
        throw "Local environment file not found: $script:EnvironmentFile`nCopy .env.example to .env and set a local SQL Server password."
    }

    $password = Get-DotEnvValue -Path $script:EnvironmentFile -Name 'MSSQL_SA_PASSWORD'

    if ([string]::IsNullOrWhiteSpace($password)) {
        throw 'MSSQL_SA_PASSWORD is missing or empty in .env.'
    }

    if ($password -eq 'REPLACE_WITH_A_LOCAL_PASSWORD') {
        throw 'Replace the MSSQL_SA_PASSWORD placeholder in .env before starting the lab.'
    }

    $portText = Get-DotEnvValue -Path $script:EnvironmentFile -Name 'MSSQL_PORT'

    if (-not [string]::IsNullOrWhiteSpace($portText)) {
        $port = 0

        if (-not [int]::TryParse($portText, [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
            throw "MSSQL_PORT must be an integer between 1 and 65535. Current value: $portText"
        }
    }

    Invoke-ComposeCommand -Arguments @('config', '--quiet')
}

function Get-SqlServerContainerId {
    [CmdletBinding()]
    param()

    $containerId = Invoke-ComposeCommand -Arguments @(
        'ps'
        '-q'
        $script:SqlServerService
    ) -CaptureOutput

    return ($containerId -join '').Trim()
}

function Get-SqlServerContainerState {
    [CmdletBinding()]
    param()

    $containerId = Get-SqlServerContainerId

    if ([string]::IsNullOrWhiteSpace($containerId)) {
        return 'not-created'
    }

    $state = Invoke-DockerCommand -Arguments @(
        'inspect'
        '--format', '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}'
        $containerId
    ) -CaptureOutput

    return ($state -join '').Trim()
}

function Wait-SqlServerHealthy {
    [CmdletBinding()]
    param(
        [ValidateRange(30, 600)]
        [int]$TimeoutSeconds = 180
    )

    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $lastState = $null

    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $currentState = Get-SqlServerContainerState

        if ($currentState -ne $lastState) {
            Write-Host "SQL Server container state: $currentState"
            $lastState = $currentState
        }

        switch ($currentState) {
            'healthy' {
                return
            }
            'unhealthy' {
                Invoke-ComposeCommand -Arguments @('logs', '--tail', '80', $script:SqlServerService)
                throw 'SQL Server container reported an unhealthy state.'
            }
            'exited' {
                Invoke-ComposeCommand -Arguments @('logs', '--tail', '80', $script:SqlServerService)
                throw 'SQL Server container exited during startup.'
            }
            'dead' {
                Invoke-ComposeCommand -Arguments @('logs', '--tail', '80', $script:SqlServerService)
                throw 'SQL Server container entered a dead state.'
            }
        }

        Start-Sleep -Seconds 3
    }

    Invoke-ComposeCommand -Arguments @('logs', '--tail', '80', $script:SqlServerService)
    throw "SQL Server did not become healthy within $TimeoutSeconds seconds."
}

function Assert-SqlServerHealthy {
    [CmdletBinding()]
    param()

    $state = Get-SqlServerContainerState

    if ($state -ne 'healthy') {
        throw "SQL Server container is not healthy. Current state: $state"
    }
}

function Invoke-ContainerSqlCmd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$SqlCmdArguments
    )

    $shellCommand = 'export SQLCMDPASSWORD="$MSSQL_SA_PASSWORD"; exec /opt/mssql-tools18/bin/sqlcmd "$@"'
    $arguments = @(
        'exec'
        '-T'
        $script:SqlServerService
        '/bin/bash'
        '-lc'
        $shellCommand
        '--'
        '-S', 'localhost'
        '-U', 'sa'
        '-C'
        '-b'
        '-r1'
    ) + $SqlCmdArguments

    Invoke-ComposeCommand -Arguments $arguments
}
