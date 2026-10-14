$ErrorActionPreference = 'Stop'
$taskAppDirectory = Split-Path -Parent $PSScriptRoot
$taskAppUrl = 'http://127.0.0.1:8787'
if (-not (Test-Path -LiteralPath (Join-Path $taskAppDirectory 'build\web\index.html'))) {
    throw 'La versione per PC deve essere compilata prima di aprirla.'
}
$taskServerReady = $false
try {
    $taskHealth = Invoke-RestMethod -Uri "$taskAppUrl/_diario_health" -TimeoutSec 2
    $taskServerReady = $taskHealth.app -eq 'diario-sogni'
} catch {}
if (-not $taskServerReady) {
    $taskPythonPath = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
    if (-not (Test-Path -LiteralPath $taskPythonPath)) {
        $taskPythonPath = (Get-Command python -ErrorAction Stop).Source
    }
    $taskServerPath = Join-Path $PSScriptRoot 'serve_pc.py'
    Start-Process -FilePath $taskPythonPath -ArgumentList @('-u', ('"' + $taskServerPath + '"')) -WindowStyle Hidden
    for ($taskAttempt = 0; $taskAttempt -lt 20; $taskAttempt++) {
        try {
            $taskHealth = Invoke-RestMethod -Uri "$taskAppUrl/_diario_health" -TimeoutSec 1
            if ($taskHealth.app -eq 'diario-sogni') { $taskServerReady = $true; break }
        } catch {}
        Start-Sleep -Milliseconds 200
    }
}
if (-not $taskServerReady) { throw 'Non riesco ad avviare il diario sul PC. La porta 8787 potrebbe essere occupata.' }
$taskEdgePath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'
if (Test-Path -LiteralPath $taskEdgePath) {
    Start-Process -FilePath $taskEdgePath -ArgumentList "--app=$taskAppUrl"
} else {
    Start-Process $taskAppUrl
}
