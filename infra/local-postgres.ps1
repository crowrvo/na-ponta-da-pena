param(
    [Parameter(Mandatory)]
    [ValidateSet('Initialize', 'Start', 'Stop', 'Status', 'Migrate', 'Backup', 'VerifyRestore')]
    [string]$Action,

    [string]$BackupPath
)

$ErrorActionPreference = 'Stop'

$localRoot = Join-Path $env:LOCALAPPDATA 'VmsFinance'
$postgresRoot = Join-Path $localRoot 'postgresql-17.11-portable'
$postgresBin = Join-Path $postgresRoot 'bin'
$dataDirectory = Join-Path $localRoot 'postgres-data-17'
$logDirectory = Join-Path $localRoot 'logs'
$backupDirectory = Join-Path $localRoot 'backups'
$secretDirectory = Join-Path $localRoot 'secrets'
$encryptedPasswordPath = Join-Path $secretDirectory 'postgres-password.dpapi'
$port = 5432
$database = 'vms_finance'
$databaseUser = 'vms_finance'

function Get-PostgresExecutable([string]$Name) {
    $path = Join-Path $postgresBin "$Name.exe"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "PostgreSQL executable not found: $path"
    }
    return $path
}

function Get-DatabasePassword {
    New-Item -ItemType Directory -Force -Path $secretDirectory | Out-Null
    if (-not (Test-Path -LiteralPath $encryptedPasswordPath)) {
        $bytes = [byte[]]::new(32)
        [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
        $plainText = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        $secure = ConvertTo-SecureString $plainText -AsPlainText -Force
        ConvertFrom-SecureString $secure | Set-Content -LiteralPath $encryptedPasswordPath -NoNewline
    }

    $encrypted = Get-Content -Raw -LiteralPath $encryptedPasswordPath
    $securePassword = ConvertTo-SecureString $encrypted
    return [System.Net.NetworkCredential]::new('', $securePassword).Password
}

function Invoke-WithDatabasePassword([scriptblock]$Command) {
    $previous = $env:PGPASSWORD
    try {
        $env:PGPASSWORD = Get-DatabasePassword
        & $Command
    }
    finally {
        $env:PGPASSWORD = $previous
    }
}

function Test-ClusterInitialized {
    return Test-Path -LiteralPath (Join-Path $dataDirectory 'PG_VERSION')
}

function Test-ServerReady {
    if (-not (Test-ClusterInitialized)) { return $false }
    $pgIsReady = Get-PostgresExecutable 'pg_isready'
    & $pgIsReady --host 127.0.0.1 --port $port --username $databaseUser --dbname postgres --quiet
    return $LASTEXITCODE -eq 0
}

function Initialize-Cluster {
    if (Test-ClusterInitialized) { return }

    New-Item -ItemType Directory -Force -Path $localRoot | Out-Null
    $passwordFile = Join-Path $localRoot ("initdb-password-{0}.tmp" -f [Guid]::NewGuid())
    try {
        Get-DatabasePassword | Set-Content -LiteralPath $passwordFile -NoNewline
        $initdb = Get-PostgresExecutable 'initdb'
        & $initdb --pgdata $dataDirectory --username $databaseUser --pwfile $passwordFile `
            --auth-host scram-sha-256 --auth-local scram-sha-256 --encoding UTF8 --locale C
        if ($LASTEXITCODE -ne 0) { throw "initdb failed with exit code $LASTEXITCODE." }
    }
    finally {
        if (Test-Path -LiteralPath $passwordFile) {
            Remove-Item -LiteralPath $passwordFile -Force
        }
    }
}

function Start-Server {
    Initialize-Cluster
    if (-not (Test-ServerReady)) {
        $portOwner = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($portOwner) {
            throw "Port $port is already in use by another process."
        }

        New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
        $pgCtl = Get-PostgresExecutable 'pg_ctl'
        $logPath = Join-Path $logDirectory 'postgres.log'
        & $pgCtl --pgdata $dataDirectory --log $logPath --options "-h 127.0.0.1 -p $port" --wait start
        if ($LASTEXITCODE -ne 0) { throw "pg_ctl start failed with exit code $LASTEXITCODE." }
    }

    Invoke-WithDatabasePassword {
        $psql = Get-PostgresExecutable 'psql'
        $databaseExists = @(& $psql --host 127.0.0.1 --port $port --username $databaseUser `
            --dbname postgres --tuples-only --no-align `
            --command "SELECT 1 FROM pg_database WHERE datname = '$database';") -contains '1'
        if ($LASTEXITCODE -ne 0) { throw 'Could not inspect local databases.' }
        if (-not $databaseExists) {
            $createdb = Get-PostgresExecutable 'createdb'
            & $createdb --host 127.0.0.1 --port $port --username $databaseUser $database
            if ($LASTEXITCODE -ne 0) { throw 'Could not create the development database.' }
        }
    }
}

function Stop-Server {
    if (-not (Test-ServerReady)) { return }
    $pgCtl = Get-PostgresExecutable 'pg_ctl'
    & $pgCtl --pgdata $dataDirectory --mode fast --wait stop
    if ($LASTEXITCODE -notin @(0, 3)) { throw "pg_ctl stop failed with exit code $LASTEXITCODE." }
}

function Get-ConnectionString {
    $password = Get-DatabasePassword
    return "Host=127.0.0.1;Port=$port;Database=$database;Username=$databaseUser;Password=$password"
}

function Invoke-Migrations {
    Start-Server
    $previous = $env:ConnectionStrings__VmsFinance
    try {
        $env:ConnectionStrings__VmsFinance = Get-ConnectionString
        dotnet tool restore
        if ($LASTEXITCODE -ne 0) { throw 'dotnet tool restore failed.' }
        dotnet tool run dotnet-ef database update `
            --project src/backend/VmsFinance.Infrastructure `
            --startup-project src/backend/VmsFinance.Api
        if ($LASTEXITCODE -ne 0) { throw 'EF Core database update failed.' }
    }
    finally {
        $env:ConnectionStrings__VmsFinance = $previous
    }
}

function New-Backup {
    Start-Server
    New-Item -ItemType Directory -Force -Path $backupDirectory | Out-Null
    $path = Join-Path $backupDirectory ("vms-finance-{0}.dump" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Invoke-WithDatabasePassword {
        $pgDump = Get-PostgresExecutable 'pg_dump'
        & $pgDump --host 127.0.0.1 --port $port --username $databaseUser `
            --dbname $database --format custom --file $path
        if ($LASTEXITCODE -ne 0) { throw 'pg_dump failed.' }
    }
    Write-Output $path
}

function Test-BackupRestore {
    Start-Server
    $path = $BackupPath
    if ([string]::IsNullOrWhiteSpace($path)) {
        $path = Get-ChildItem -LiteralPath $backupDirectory -Filter '*.dump' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)) {
        throw 'No backup file was found to verify.'
    }

    $restoreDatabase = 'vms_finance_restore_check'
    Invoke-WithDatabasePassword {
        $dropdb = Get-PostgresExecutable 'dropdb'
        $createdb = Get-PostgresExecutable 'createdb'
        $pgRestore = Get-PostgresExecutable 'pg_restore'
        $psql = Get-PostgresExecutable 'psql'
        try {
            & $dropdb --host 127.0.0.1 --port $port --username $databaseUser `
                --if-exists --force $restoreDatabase
            & $createdb --host 127.0.0.1 --port $port --username $databaseUser $restoreDatabase
            if ($LASTEXITCODE -ne 0) { throw 'Could not create restore-check database.' }
            & $pgRestore --host 127.0.0.1 --port $port --username $databaseUser `
                --dbname $restoreDatabase --exit-on-error $path
            if ($LASTEXITCODE -ne 0) { throw 'pg_restore failed.' }
            $tables = @(& $psql --host 127.0.0.1 --port $port --username $databaseUser `
                --dbname $restoreDatabase --tuples-only --no-align `
                --command "SELECT to_regclass('public.households');")
            if ($LASTEXITCODE -ne 0 -or $tables -notcontains 'households') {
                throw 'Restored schema validation failed.'
            }
        }
        finally {
            & $dropdb --host 127.0.0.1 --port $port --username $databaseUser `
                --if-exists --force $restoreDatabase
        }
    }
    Write-Output "Restore verified from $path"
}

switch ($Action) {
    'Initialize' { Initialize-Cluster }
    'Start' { Start-Server }
    'Stop' { Stop-Server }
    'Status' {
        if (Test-ServerReady) { Write-Output 'PostgreSQL is ready on 127.0.0.1:5432.' }
        else { Write-Output 'PostgreSQL is stopped.' }
    }
    'Migrate' { Invoke-Migrations }
    'Backup' { New-Backup }
    'VerifyRestore' { Test-BackupRestore }
}
