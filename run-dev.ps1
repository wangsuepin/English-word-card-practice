$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$nodeRoot = Join-Path $ProjectRoot ".tools\node"
$npmCmd = Join-Path $ProjectRoot ".tools\node\npm.cmd"

if (-not (Test-Path $npmCmd)) {
  throw "Local npm was not found. Run .\setup-local-node.ps1 first."
}

$env:Path = "$nodeRoot;$env:Path"
& $npmCmd run dev -- --host 127.0.0.1
