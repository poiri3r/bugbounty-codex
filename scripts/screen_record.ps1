# Local browser capture only; read RECORDING.md first.
[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('Open','Start','Stop')][string]$Action,
  [Parameter(Mandatory)][string]$SessionDirectory,
  [string]$Url = 'http://localhost/',
  [string]$CaptureDirectory = (Join-Path ([Environment]::GetFolderPath('MyVideos')) 'Captures'),
  [ValidateRange(1024,65535)][int]$Port = 9223,
  [switch]$RecordingIndicatorConfirmed
)
$ErrorActionPreference = 'Stop'
$session = [IO.Path]::GetFullPath($SessionDirectory)
$statePath = Join-Path $session 'recording-state.json'
$videoPath = Join-Path $session 'browser-recording.mp4'
function Save-State($value) {
  $value | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $statePath -Encoding UTF8
}
function Get-Captures {
  @(Get-ChildItem -LiteralPath $CaptureDirectory -Filter '*.mp4' -File -ErrorAction Stop)
}
function Focus-Browser($browserId) {
  $window = Get-Process -Id $browserId
  if ($window.ProcessName -ne 'chrome' -or $window.MainWindowHandle -eq 0) { throw 'Chrome window no longer exists.' }
  [GameBarKeys]::ShowWindow($window.MainWindowHandle, 3) | Out-Null
  (New-Object -ComObject WScript.Shell).AppActivate($browserId) | Out-Null
  [GameBarKeys]::SetForegroundWindow($window.MainWindowHandle) | Out-Null
  Start-Sleep -Milliseconds 700
  if ([GameBarKeys]::GetForegroundWindow() -ne $window.MainWindowHandle) { throw 'Chrome not foreground. No shortcut sent.' }
}
function Toggle-Recording {
  foreach ($key in 0x5B, 0x12, 0x52) { [GameBarKeys]::keybd_event($key, 0, 0, [UIntPtr]::Zero) }
  foreach ($key in 0x52, 0x12, 0x5B) { [GameBarKeys]::keybd_event($key, 0, 2, [UIntPtr]::Zero) }
}
if (-not ('GameBarKeys' -as [type])) { Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class GameBarKeys {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr handle);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr handle, int command);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern void keybd_event(byte key, byte scan, uint flags, UIntPtr extra);
}
'@
}
if ($Action -eq 'Open') {
  $parsed = [Uri]$Url
  if (-not $parsed.IsAbsoluteUri -or $parsed.Scheme -notin @('http','https') -or
      $parsed.Host -notin @('localhost','127.0.0.1','[::1]','::1') -or $parsed.UserInfo) {
    throw 'Only an explicit localhost HTTP(S) URL without credentials is allowed.'
  }
  if ((Test-Path -LiteralPath $statePath) -or (Test-Path -LiteralPath $videoPath)) { throw 'Use a new session directory. Existing evidence will not be overwritten.' }
  if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) { throw 'Debugging port occupied; close earlier browser or select another port.' }
  $chrome = @("${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") |
    Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  if (-not $chrome) { throw 'Chrome not installed in a standard location.' }
  $profile = Join-Path $session 'browser-profile'
  if ((Test-Path -LiteralPath $profile) -or $profile.Contains('"') -or $Url.Contains('"')) { throw 'Use a fresh profile path without quotes.' }
  New-Item -ItemType Directory -Path $session -Force | Out-Null
  $process = Start-Process -FilePath $chrome -ArgumentList @(
    "--user-data-dir=`"$profile`"", "--remote-debugging-port=$Port", '--remote-debugging-address=127.0.0.1',
    '--no-first-run', '--no-default-browser-check', '--new-window', "`"$Url`"") -PassThru
  $deadline = (Get-Date).AddSeconds(20)
  do { Start-Sleep -Milliseconds 300; $process.Refresh() }
  while (-not $process.HasExited -and $process.MainWindowHandle -eq 0 -and (Get-Date) -lt $deadline)
  if ($process.HasExited -or $process.MainWindowHandle -eq 0) { throw 'Chrome launch failed. No recording started.' }
  Save-State ([ordered]@{ phase='open'; browserId=$process.Id; port=$Port; profile=$profile })
  Focus-Browser $process.Id
  Write-Output 'Browser opened. Prepare the approved local demonstration, then call Start.'
  exit
}
if (-not (Test-Path -LiteralPath $statePath)) { throw 'Run Open with this session directory first.' }
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if ($Action -eq 'Stop' -and $state.phase -eq 'stop-requested' -and (Test-Path -LiteralPath $videoPath)) {
  throw 'Existing video will not be overwritten.'
}
if ($Action -eq 'Start') {
  if ($state.phase -ne 'open') { throw 'Start allowed once per session. Do not toggle blindly.' }
  if (-not (Test-Path -LiteralPath $CaptureDirectory -PathType Container)) { throw 'Configure Game Bar capture directory first.' }
  $state | Add-Member captureDirectory ([IO.Path]::GetFullPath($CaptureDirectory))
  $state | Add-Member baseline @(Get-Captures | ForEach-Object { $_.FullName })
  Focus-Browser $state.browserId
  $state.phase = 'start-requested'
  Save-State $state
  Toggle-Recording
  Write-Output 'Start requested, NOT verified. Check the recording timer/indicator before proceeding.'
  exit
}
if ($state.phase -eq 'start-requested') {
  if (-not $RecordingIndicatorConfirmed) { throw 'Stop requires visual confirmation that recording is active.' }
  Focus-Browser $state.browserId
  $state.phase = 'stop-requested'
  Save-State $state
  Toggle-Recording
} elseif ($state.phase -ne 'stop-requested') { throw 'No recording awaiting Stop.' }
# Retrying Stop collects files only; no second toggle.
$CaptureDirectory = $state.captureDirectory
$deadline = (Get-Date).AddSeconds(30)
do {
  $files = @(Get-Captures | Where-Object { $_.FullName -notin @($state.baseline) })
  if ($files.Count -gt 1) { throw 'Multiple new MP4s: ambiguous capture. Inspect originals manually.' }
  if ($files.Count -eq 1 -and $files[0].Length -gt 0) {
    try {
      $stream = [IO.File]::Open($files[0].FullName, 'Open', 'Read', 'None')
      $stream.Dispose()
      [IO.File]::Copy($files[0].FullName, $videoPath, $false)
      $state.phase = 'captured-unreviewed'
      $state | Add-Member sourceCapture $files[0].FullName
      $state | Add-Member sha256 (Get-FileHash -LiteralPath $videoPath -Algorithm SHA256).Hash
      Save-State $state
      Write-Output "Saved: $videoPath. Original preserved. Playback review still required."
      exit
    } catch [IO.IOException] { if (Test-Path -LiteralPath $videoPath) { throw } }
  }
  Start-Sleep -Seconds 1
} while ((Get-Date) -lt $deadline)
throw 'No unique closed MP4. Recording NOT complete. Check Game Bar; retry Stop to collect only.'
