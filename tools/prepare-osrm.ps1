# Download and preprocess the Java OSM extract for the optional local OSRM service.
# The PBF and generated graph stay outside Git because they are large, regenerable data.
[CmdletBinding()]
param(
    [string]$DataDirectory = $env:OSRM_DATA_DIR
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($DataDirectory) -or $DataDirectory.StartsWith('./')) {
    $DataDirectory = 'D:\Commencys-Cache\OSRM\java'
}

$image = 'ghcr.io/project-osrm/osrm-backend:26.10-debian'
$pbfName = 'java-latest.osm.pbf'
$pbfPath = Join-Path $DataDirectory $pbfName
$downloadUrl = 'https://download.geofabrik.de/asia/indonesia/java-latest.osm.pbf'
$docker = Get-Command docker -ErrorAction SilentlyContinue

if ($null -eq $docker) {
    throw 'Docker CLI was not found. Install or configure an open-source-compatible container engine first.'
}

& docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw 'The container engine is not running. Start it before preparing OSRM route data.'
}

New-Item -ItemType Directory -Path $DataDirectory -Force | Out-Null
# Download to a temporary extension first so an interrupted transfer is not treated as complete.
if (-not (Test-Path -LiteralPath $pbfPath)) {
    $partialPath = "$pbfPath.part"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $partialPath
    Move-Item -LiteralPath $partialPath -Destination $pbfPath -Force
}

# Run the pinned OSRM image against the external data directory, then build the MLD routing graph.
$mountPath = $DataDirectory.Replace('\', '/')
& docker pull $image
if ($LASTEXITCODE -ne 0) { throw 'Unable to pull the pinned OSRM image.' }

# Prepare a local Java road graph; this large regional extract stays outside Git.
& docker run --rm -v "${mountPath}:/data" $image osrm-extract -p /opt/car.lua "/data/$pbfName"
if ($LASTEXITCODE -ne 0) { throw 'OSRM extraction failed.' }
& docker run --rm -v "${mountPath}:/data" $image osrm-partition /data/java-latest.osrm
if ($LASTEXITCODE -ne 0) { throw 'OSRM MLD partitioning failed.' }
& docker run --rm -v "${mountPath}:/data" $image osrm-customize /data/java-latest.osrm
if ($LASTEXITCODE -ne 0) { throw 'OSRM MLD customization failed.' }

Write-Host "OSRM data prepared at $DataDirectory"
