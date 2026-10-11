# File-handling regression tests only. Dummy bytes are NOT video evidence.
$ErrorActionPreference = 'Stop'
$recorder = Join-Path $PSScriptRoot '..\screen_record.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('recording-test-' + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $testRoot | Out-Null
function Expect-Failure([scriptblock]$operation, [string]$message) {
    try { & $operation } catch {
        if ($_.Exception.Message -notlike "*$message*") { throw }
        return
    }
    throw "Expected failure: $message"
}
try {
    $session = Join-Path $testRoot 'session'
    $captures = Join-Path $testRoot 'captures'
    New-Item -ItemType Directory -Path $session,$captures | Out-Null
    $statePath = Join-Path $session 'recording-state.json'
    $output = Join-Path $session 'browser-recording.mp4'
    Expect-Failure { & $recorder -Action Open -SessionDirectory $session -Url 'https://example.com/' } 'localhost'
    Expect-Failure { & $recorder -Action Stop -SessionDirectory $session } 'Run Open'
    @{ phase='start-requested'; browserId=0 } | ConvertTo-Json | Set-Content $statePath
    Expect-Failure { & $recorder -Action Start -SessionDirectory $session } 'once per session'
    Expect-Failure { & $recorder -Action Stop -SessionDirectory $session } 'visual confirmation'
    $original = Join-Path $captures 'new.mp4'
    [IO.File]::WriteAllBytes($original, [byte[]](1,2,3,4))
    @{ phase='stop-requested'; captureDirectory=$captures; baseline=@(); browserId=0 } |
        ConvertTo-Json | Set-Content $statePath
    $extra = Join-Path $captures 'other.mp4'
    [IO.File]::WriteAllBytes($extra, [byte[]](5))
    Expect-Failure { & $recorder -Action Stop -SessionDirectory $session } 'ambiguous capture'
    Remove-Item -LiteralPath $extra
    & $recorder -Action Stop -SessionDirectory $session | Out-Null
    if (-not (Test-Path $original) -or -not (Test-Path $output)) { throw 'Original or collected copy missing.' }
    $state = Get-Content $statePath -Raw | ConvertFrom-Json
    if ($state.phase -ne 'captured-unreviewed') { throw 'Must not auto-approve video.' }
    if ($state.sha256 -ne (Get-FileHash $original).Hash) { throw 'Hash mismatch.' }
    Expect-Failure { & $recorder -Action Stop -SessionDirectory $session } 'No recording awaiting'
    Expect-Failure { & $recorder -Action Open -SessionDirectory $session } 'new session directory'
    # Even stale stop state must never overwrite an existing artifact.
    $state.phase = 'stop-requested'
    $state | ConvertTo-Json | Set-Content $statePath
    Expect-Failure { & $recorder -Action Stop -SessionDirectory $session } 'Existing video'
    Write-Output 'screen recorder file-handling tests PASS (no GUI recording performed)'
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
