#Requires -RunAsAdministrator
# Make SSH from the Macs work on this Windows PC in one go. Safe to re-run.
# Opens SSH as widely as possible on purpose: every network profile, every source address,
# key AND password login, every account reads ~/.ssh/authorized_keys.
# Keys come from https://github.com/baleen37.keys at run time; re-run after changing them on GitHub.
$ErrorActionPreference = 'Continue'
$User = $env:USERNAME
$SshDir = "$env:ProgramData\ssh"

function Step($msg) { Write-Host "`n=== $msg" -ForegroundColor Cyan }

Step '0. Fetch keys from GitHub'
$k = (Invoke-RestMethod https://github.com/baleen37.keys).Trim()
if (-not $k) { throw 'no keys at https://github.com/baleen37.keys' }
Write-Host $k

Step '1. OpenSSH server'
if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
  try { Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' -ErrorAction Stop | Out-Null }
  catch { Write-Host "capability failed: $($_.Exception.Message) -> winget" }
}
if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
  winget install --id Microsoft.OpenSSH.Preview -e --accept-source-agreements --accept-package-agreements
}
if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) { throw 'sshd is still missing' }
Set-Service sshd -StartupType Automatic
Start-Service sshd   # first start creates $SshDir\sshd_config

Step '2. sshd_config: one key file per user, key + password login'
$cfgPath = "$SshDir\sshd_config"
$cfg = Get-Content $cfgPath
# Drop the admin-only override so admins also read ~/.ssh/authorized_keys.
$cfg = $cfg | ForEach-Object {
  if ($_ -match '^\s*Match Group administrators' -or $_ -match '^\s*AuthorizedKeysFile\s+__PROGRAMDATA__') { "# $_" } else { $_ }
}
$want = [ordered]@{
  'PubkeyAuthentication'   = 'yes'
  'PasswordAuthentication' = 'yes'
  'AuthorizedKeysFile'     = '.ssh/authorized_keys'
  'StrictModes'            = 'no'
}
foreach ($key in $want.Keys) {
  $line = "$key $($want[$key])"
  if ($cfg -match "^\s*#?\s*$key\s") { $cfg = $cfg -replace "^\s*#?\s*$key\s.*$", $line }
  else { $cfg = @($line) + $cfg }
}
Set-Content -Path $cfgPath -Value $cfg -Encoding ascii

Step '3. GitHub keys in both key files'
$userSsh = "C:\Users\$User\.ssh"
New-Item -ItemType Directory -Force -Path $userSsh | Out-Null
# WriteAllText: no BOM, LF line ending, nothing for a wrapped line to break.
[IO.File]::WriteAllText("$userSsh\authorized_keys", "$k`n")
icacls.exe "$userSsh\authorized_keys" /inheritance:r /grant "${User}:F" /grant '*S-1-5-18:F' /grant '*S-1-5-32-544:F' | Out-Null
[IO.File]::WriteAllText("$SshDir\administrators_authorized_keys", "$k`n")
icacls.exe "$SshDir\administrators_authorized_keys" /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F' | Out-Null

Step '4. Firewall: TCP 22 from anywhere, every profile'
Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'ssh' -and $_.Direction -eq 'Inbound' } |
  Set-NetFirewallRule -Enabled True -Profile Any -RemoteAddress Any -Action Allow
if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True `
    -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any | Out-Null
}
Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -Enabled True -Profile Any -RemoteAddress Any -Action Allow

Step '5. PowerShell as the SSH shell'
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell `
  -Value "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force | Out-Null

Step '6. Restart and check'
$sshdExe = (Get-CimInstance Win32_Service -Filter "Name='sshd'").PathName.Trim('"')
& $sshdExe -t; if ($LASTEXITCODE -eq 0) { Write-Host 'sshd_config OK' } else { Write-Host 'sshd_config INVALID' -ForegroundColor Red }
Restart-Service sshd
Write-Host "sshd      : $((Get-Service sshd).Status)"
Write-Host "listening : $(Test-NetConnection 127.0.0.1 -Port 22 -InformationLevel Quiet)"
Write-Host "whoami    : $(whoami)"
Write-Host "arch      : $env:PROCESSOR_ARCHITECTURE"
Write-Host "`nDone. From the Mac: ssh $User@$env:COMPUTERNAME" -ForegroundColor Green
