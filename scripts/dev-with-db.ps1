$ErrorActionPreference = "Stop"

# Local PostgreSQL defaults for development
$containerName = "jago-postgres"
$dbUser = "jago"
$dbPassword = "jago"
$dbName = "jago_dev"
$dbPort = "5432"
$defaultDbUrl = "postgresql://${dbUser}:${dbPassword}@localhost:${dbPort}/${dbName}"
$userPgPort = "55432"

function Test-DbConnection {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ConnectionString
  )

  $env:DATABASE_URL = $ConnectionString
  node -e "const pg=require('pg'); const c=new pg.Client({connectionString:process.env.DATABASE_URL}); c.connect().then(()=>c.end()).then(()=>process.exit(0)).catch(()=>process.exit(1));" | Out-Null
  return $LASTEXITCODE -eq 0
}

function Get-PostgresToolPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ToolName
  )

  $cmd = Get-Command $ToolName -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  $candidate = Get-ChildItem "C:\Program Files\PostgreSQL" -Recurse -Filter $ToolName -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
  return $candidate
}

function Start-LocalPostgresIfPossible {
  $portOpen = (Test-NetConnection -ComputerName localhost -Port $dbPort -WarningAction SilentlyContinue).TcpTestSucceeded
  if ($portOpen) {
    return
  }

  $pgCtlPath = Get-PostgresToolPath -ToolName "pg_ctl.exe"
  if (-not $pgCtlPath) {
    return
  }

  $postgresRoot = Split-Path -Parent (Split-Path -Parent $pgCtlPath)
  $dataDir = Join-Path $postgresRoot "data"
  if (-not (Test-Path $dataDir)) {
    return
  }

  Write-Host "[dev-with-db] Starting local PostgreSQL via pg_ctl..."
  & $pgCtlPath -D $dataDir -l "$env:TEMP\postgres-local.log" start | Out-Null
  Start-Sleep -Seconds 2
}

function Start-UserOwnedPostgresFallback {
  $pgCtlPath = Get-PostgresToolPath -ToolName "pg_ctl.exe"
  $initDbPath = Get-PostgresToolPath -ToolName "initdb.exe"
  $psqlPath = Get-PostgresToolPath -ToolName "psql.exe"

  if (-not $pgCtlPath -or -not $initDbPath -or -not $psqlPath) {
    throw "PostgreSQL tools (pg_ctl/initdb/psql) were not found."
  }

  $localPgRoot = Join-Path $projectRoot ".local-postgres"
  $localPgData = Join-Path $localPgRoot "data"
  $localPgLog = Join-Path $localPgRoot "postgres.log"
  New-Item -ItemType Directory -Path $localPgRoot -Force | Out-Null

  if (-not (Test-Path $localPgData)) {
    Write-Host "[dev-with-db] Initializing private local PostgreSQL for this project..."
    & $initDbPath -D $localPgData -U $dbUser -A trust -E UTF8 | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to initialize local PostgreSQL cluster."
    }
  }

  & $pgCtlPath -D $localPgData status | Out-Null
  $alreadyRunning = $LASTEXITCODE -eq 0

  if (-not $alreadyRunning) {
    Write-Host "[dev-with-db] Starting private PostgreSQL on port $userPgPort..."
    & $pgCtlPath -D $localPgData -l $localPgLog -o "-p $userPgPort" start | Out-Null
  } else {
    Write-Host "[dev-with-db] Private PostgreSQL already running on port $userPgPort."
  }

  $maxAttempts = 30
  for ($i = 1; $i -le $maxAttempts; $i++) {
    $ready = (Test-NetConnection -ComputerName localhost -Port $userPgPort -WarningAction SilentlyContinue).TcpTestSucceeded
    if ($ready) {
      break
    }
    Start-Sleep -Seconds 1
    if ($i -eq $maxAttempts) {
      throw "Private PostgreSQL did not start in time."
    }
  }

  $dbExists = & $psqlPath -h localhost -p $userPgPort -U $dbUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${dbName}'"
  if (-not ($dbExists -and $dbExists.Trim() -eq "1")) {
    & $psqlPath -h localhost -p $userPgPort -U $dbUser -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE ${dbName};" | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to create database ${dbName} on private PostgreSQL."
    }
  }

  $fallbackDbUrl = "postgresql://${dbUser}@localhost:${userPgPort}/${dbName}"
  Write-Host "[dev-with-db] Fallback DATABASE_URL ready: $fallbackDbUrl"
  return $fallbackDbUrl
}

# Load .env.development if present so local values are available in this session.
$projectRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $projectRoot ".env.development"
if (Test-Path $envFile) {
  Write-Host "[dev-with-db] Loading $envFile"
  Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith("#")) {
      return
    }

    $parts = $line -split "=", 2
    if ($parts.Length -ne 2) {
      return
    }

    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    Set-Item -Path "Env:$key" -Value $value
  }
}

$dbUrl = $env:DATABASE_URL
if (-not $dbUrl) {
  $dbUrl = $defaultDbUrl
  $env:DATABASE_URL = $dbUrl
}

Start-LocalPostgresIfPossible

$dockerAvailable = $null -ne (Get-Command docker -ErrorAction SilentlyContinue)

if ($dockerAvailable -and $dbUrl -eq $defaultDbUrl) {
  $existing = docker ps -a --filter "name=^/${containerName}$" --format "{{.Names}}"
  if (-not $existing) {
    Write-Host "[dev-with-db] Creating PostgreSQL container '${containerName}'..."
    docker run -d --name $containerName -e POSTGRES_USER=$dbUser -e POSTGRES_PASSWORD=$dbPassword -e POSTGRES_DB=$dbName -p "${dbPort}:5432" postgres:16-alpine | Out-Null
  } else {
    $running = docker ps --filter "name=^/${containerName}$" --format "{{.Names}}"
    if (-not $running) {
      Write-Host "[dev-with-db] Starting existing PostgreSQL container '${containerName}'..."
      docker start $containerName | Out-Null
    }
  }

  Write-Host "[dev-with-db] Waiting for PostgreSQL to accept connections..."
  $maxAttempts = 30
  for ($i = 1; $i -le $maxAttempts; $i++) {
    $ready = docker exec $containerName pg_isready -U $dbUser -d $dbName 2>$null
    if ($LASTEXITCODE -eq 0) {
      break
    }
    Start-Sleep -Seconds 1
    if ($i -eq $maxAttempts) {
      throw "PostgreSQL did not become ready in time."
    }
  }
} elseif (-not $dockerAvailable) {
  Write-Host "[dev-with-db] Docker not found; using DATABASE_URL from environment/.env.development"
}

$env:NODE_ENV = "development"

Write-Host "[dev-with-db] DATABASE_URL set to $dbUrl"
Write-Host "[dev-with-db] Verifying database connectivity..."
$connected = Test-DbConnection -ConnectionString $dbUrl
if (-not $connected -and $dbUrl -eq $defaultDbUrl) {
  Write-Host "[dev-with-db] Default local DB is unavailable. Switching to private fallback database..."
  $dbUrl = Start-UserOwnedPostgresFallback
  $env:DATABASE_URL = $dbUrl
  $connected = Test-DbConnection -ConnectionString $dbUrl
}

if (-not $connected) {
  throw "Database is not reachable at DATABASE_URL."
}

Write-Host "[dev-with-db] Applying SQL migrations..."
npm.cmd run db:migrate
if ($LASTEXITCODE -ne 0) {
  throw "db:migrate failed."
}

Write-Host "[dev-with-db] Starting app in development mode..."
npm.cmd run dev
