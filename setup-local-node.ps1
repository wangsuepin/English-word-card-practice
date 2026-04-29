$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolsDir = Join-Path $ProjectRoot ".tools"
$DownloadDir = Join-Path $ToolsDir "downloads"
$NodeRoot = Join-Path $ToolsDir "node"
$NodeLatestUrl = "https://nodejs.org/dist/latest-v24.x"
$ShasumsUrl = "$NodeLatestUrl/SHASUMS256.txt"

New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null

Write-Host "Reading Node.js release metadata from $ShasumsUrl"
$shasums = Invoke-WebRequest -UseBasicParsing -Uri $ShasumsUrl
$zipName = ($shasums.Content -split "`n" |
  Where-Object { $_ -match "node-v.+-win-x64\.zip" } |
  Select-Object -First 1) -replace "^[a-fA-F0-9]+\s+", ""

if (-not $zipName) {
  throw "Could not find a Windows x64 Node.js zip in SHASUMS256.txt."
}

$zipUrl = "$NodeLatestUrl/$zipName"
$zipPath = Join-Path $DownloadDir $zipName

if (-not (Test-Path $zipPath)) {
  Write-Host "Downloading $zipUrl"
  Invoke-WebRequest -UseBasicParsing -Uri $zipUrl -OutFile $zipPath
}

if (Test-Path $NodeRoot) {
  Remove-Item -Recurse -Force $NodeRoot
}

Write-Host "Extracting Node.js to $ToolsDir"
Expand-Archive -Force -Path $zipPath -DestinationPath $ToolsDir

$extractedDir = Get-ChildItem -Path $ToolsDir -Directory |
  Where-Object { $_.Name -like "node-v*-win-x64" } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $extractedDir) {
  throw "Could not find extracted Node.js directory."
}

Move-Item -Force -Path $extractedDir.FullName -Destination $NodeRoot

$nodeExe = Join-Path $NodeRoot "node.exe"
$npmCmd = Join-Path $NodeRoot "npm.cmd"
$env:Path = "$NodeRoot;$env:Path"

Write-Host "Node version:"
& $nodeExe --version

Write-Host "npm version:"
& $npmCmd --version

Write-Host "Installing project dependencies..."
& $npmCmd install
if ($LASTEXITCODE -ne 0) {
  throw "npm install failed with exit code $LASTEXITCODE."
}

Write-Host ""
Write-Host "Environment is ready."
Write-Host "Start the project with:"
Write-Host "  .\.tools\node\npm.cmd run dev"
