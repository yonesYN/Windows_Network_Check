<#
.NOTES
    Author         : yonesYN
    GitHub         : https://github.com/yonesYN
    Version        : 1.3
#>

$gg = [bool](whoami /groups | findstr "S-1-5-32-544")
$ee = [bool](whoami /groups | findstr "S-1-16-12288")

$agroup = whoami /groups | Select-String "S-1-16-"
switch -Wildcard ($agroup.ToString()) {
    "*S-1-16-12288*" { $ll = "Admin" }
    "*S-1-16-8192*"  { $ll = "User" }
    "*S-1-16-16384*" { $ll = "System" }
    "*S-1-16-4096*"  { $ll = "Low" }
    "*S-1-16-20480*" { $ll = "Protected Process" }
    Default          { $ll = "Unknown" }
}

function Test-Mtu {
    param(
        [int]$Size
    )

    & ping.exe -n 1 -f -l $Size 8.8.8.8 *> $null

    return ($LASTEXITCODE -eq 0)
}

$services = @{
    'lltdio' = $true
    'MsLldp' = $true
    'NdisCap' = $true
    'Psched' = $true
    'rspndr' = $true
    'nsi' = $true
    'RpcSs' = $true
    'PlugPlay' = $true
    'Dhcp' = $true
    'NlaSvc' = $true
    'netprofm' = $true
    'wintun' = $true
    'msiserver' = $false
    'RpcLocator' = $false
    'Netman' = $false
    'WlanSvc' = $false
    'WwanSvc' = $false
    'RmSvc' = $false
    'DsmSvc' = $false
    'DeviceInstall' = $false
    'W32Time' = $false
}

Write-Host "`n=== Related Software ===" -ForegroundColor Cyan
Get-ItemProperty @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
) -ErrorAction SilentlyContinue | Where-Object {
    $_.DisplayName -match 'tunnel|vpn|proxy|wall|packet|ping|net|connect|tun|tap'
} | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.DisplayName
        Location = if ($_.InstallLocation) {
            $_.InstallLocation
        } else {
            $_.InstallationPath
        }
    }
} | Out-Host

Write-Host "`n=== UAC ===" -ForegroundColor Cyan
Write-Host "AdminGroup: $gg" -ForegroundColor $(if ($gg) { "Green" } else { "Red" })
Write-Host "elevated: $ee"
Write-Host "Level: $ll"

Write-Host "`n=== INTERFACE ===" -ForegroundColor Cyan
$adapters = Get-NetAdapter -ErrorAction SilentlyContinue

if ($adapters) {
    $adapters = $adapters | Sort-Object InterfaceIndex

    foreach ($adapter in $adapters) {
        $color = if ($adapter.Status -eq "Up") { "Green" } else { "White" }

        $ip = Get-NetIPAddress -InterfaceAlias $adapter.Name -ErrorAction SilentlyContinue
        $ipAddress = if ($ip) { ($ip.IPAddress -join ", ") } else { "No-IP" }

        Write-Host "$($adapter.Name): $ipAddress [$($adapter.InterfaceDescription)]" -ForegroundColor $color
    }
} else {
    Write-Host "No adapters found" -ForegroundColor Red
}

Write-Host "`n=== Public-IP & Time ===" -ForegroundColor Cyan
try {
    $trace = Invoke-WebRequest "https://cloudflare.com/cdn-cgi/trace" -UseBasicParsing -ErrorAction Stop
    $data = ConvertFrom-StringData $trace.Content
} catch {
    Write-Host "Unable to retrieve"
}

if ($data) {
	$unix = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $loc = if ($data.loc) { $data.loc } else { "Unknown" }
    Write-Host "IP: $($data.ip) $loc"
}

if ($data.ts -match '^\d+(\.\d+)?$') {
    $unix = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $differ = [math]::Abs([long]$data.ts - $unix)
    $color = if ($differ -gt 60) { "Yellow" } else { "Green" }
    Write-Host "Time Difference: $differ seconds" -ForegroundColor $color
}

Write-Host "`n=== DNS SETTINGS ===" -ForegroundColor Cyan
$dnsSettings = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Sort-Object InterfaceIndex | Where-Object { $_.ServerAddresses }
if ($dnsSettings) {
    foreach ($dns in $dnsSettings) {
        $dnsServer = $dns.ServerAddresses -join ', '
        Write-Host "$($dns.InterfaceAlias): $dnsServer"
    }
} else {
    Write-Host "No DNS found" -ForegroundColor Red
}

try {
    Resolve-DnsName google.com -ErrorAction Stop | Out-Null
    Write-Host "`nDNS: Working" -ForegroundColor Green
} catch {
    Write-Host "`nDNS: Failed" -ForegroundColor Red
}

Write-Host "`n=== LATENCY & MTU ===" -ForegroundColor Cyan
Write-Host "8.8.8.8"
$pingResults = @()
$a = 0
try {
    Test-Connection 8.8.8.8 -Count 1 -ErrorAction SilentlyContinue | Out-Null
    $a = 1
} catch {
    Write-Host "Unable to test" -ForegroundColor Red
}

if ($a) {
    Write-Host " Loading: " -NoNewline

    for ($i = 0; $i -lt 9; $i++) {

        $ping = Test-Connection 8.8.8.8 -Count 1 -ErrorAction SilentlyContinue

        if ($ping) {
            $pingResults += $ping
            $currentPing = $ping.ResponseTime
            $differ = [math]::Abs($currentPing - $previousPing)

            $color = if ($currentPing -gt 240 -or $differ -ge 9) {"Yellow"} else {"Green"}
            Write-Host "#" -NoNewline -ForegroundColor $color

            $previousPing = $currentPing
        }
        else {
            Write-Host "#" -NoNewline -ForegroundColor Red
        }
    }

    $successPings = @($pingResults | Where-Object { $_.ResponseTime -ne $null })
    if ($successPings.Count -eq 0) {
        Write-Host " Timeout" -ForegroundColor Red
    } else {
        $avgPing = [math]::Round(($successPings.ResponseTime | Measure-Object -Average).Average)
        $maxPing = ($successPings.ResponseTime | Measure-Object -Maximum).Maximum
        $differ = [math]::Abs($avgPing - $maxPing)
    
        Write-Host "`n   latency: ${avgPing}ms  Jitter: ${differ}ms  Success: $($successPings.Count)/9"
    }
}

Write-Host "`n Loading: " -NoNewline

$low = 8
$high = 1472
$load = -1

if ($successPings.Count -eq 9 -and $maxPing -lt 270) { while ($low -le $high) {
    $mid = [math]::Floor(($low + $high) / 2)

    if (Test-Mtu -Size $mid) {
        Write-Host "#" -NoNewline -ForegroundColor Green
        $load = $mid
        $low = $mid + 1
    }
    else {
        Write-Host "#" -NoNewline -ForegroundColor Yellow
        $high = $mid - 1
    }
}
    if ($load -ge 0) {
        Write-Host "`n   MTU: $($load+28)"
    } else { Write-Host "Unable to determine the Path MTU" -ForegroundColor Red }
} else { Write-Host "The connection is unstable for the MTU test" -ForegroundColor Yellow}

Write-Host "`n=== PROXY STATUS ===" -ForegroundColor Cyan
netsh winhttp show proxy
$Proxy = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" | Select-Object ProxyEnable,ProxyServer
if ($Proxy.ProxyEnable) { Write-Host "ProxyEnable: $($Proxy.ProxyServer)" }

Write-Host "`n=== DEFENDER STATUS ===" -ForegroundColor Cyan
if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
    try {
        $def = Get-MpComputerStatus -ErrorAction Stop
        Write-Host "Real-time Protection:" $def.RealTimeProtectionEnabled
        Write-Host "Antispyware:" $def.AntispywareEnabled
        Write-Host "Antivirus:" $def.AntivirusEnabled
    } catch {
        Write-Host "Defender module not Working" -ForegroundColor Red
    }
} else {
    Write-Host "Defender module not available"
}

Write-Host "`n=== OTHER ANTIVIRUS ===" -ForegroundColor Cyan
$otherAV = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
if ($otherAV) {
    $otherAV | ForEach-Object {
        Write-Host "AV: $($_.displayName) (State: $($_.productState))" 
    }
} else {
    Write-Host "No antivirus"
}

try {
    $secureBoot = Confirm-SecureBootUEFI -ErrorAction Stop
    $tpm = Get-Tpm
    $color = if ($secureBoot -eq "True") { "White" } else { "Red" }
    Write-Host "`nSecureBoot: $secureBoot`nTPM: $($tpm.TpmReady) $($tpm.TpmEnabled) $($tpm.TpmActivated)" -ForegroundColor $color
} catch {
    Write-Host "`nUnable to get SecureBoot" -ForegroundColor Red
}

Write-Host "`n=== SERVICES ===" -ForegroundColor Cyan

foreach ($name in $services.Keys) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.StartType -eq 'Disabled') {
            Write-Host "$($svc.DisplayName)" -ForegroundColor Red
        } elseif ($services[$name] -and $svc.Status -ne 'Running') {
            Write-Host "$($svc.DisplayName) : $($svc.Status)" -ForegroundColor Magenta
        }
    } else {
        Write-Host "XXX $name XXX" -ForegroundColor DarkRed
    }
}

Write-Host "`n=== FIREWALL ===" -ForegroundColor Cyan

$path = "C:\Windows\System32\drivers\etc\hosts"

if (Test-Path $path) {
    Get-Content $path | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }
} else {
    Write-Host "Hosts file not found" -ForegroundColor Red
}

Get-NetFirewallProfile | Select-Object Name, Enabled | Out-Host
pause
