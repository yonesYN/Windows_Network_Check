# Network Diagnostics

A lightweight PowerShell script for collecting a quick snapshot of Windows network, connectivity, proxy, security, and related system settings.

## What it checks

## network_diagnostics.ps1

- **Related software** — installed applications whose names match common VPN, tunnel, proxy, TAP/TUN, and connectivity keywords.
- **UAC / privilege level** — whether the current account belongs to the local Administrators group and the current integrity level.
- **Network interfaces** — adapter status, interface description, and assigned IP addresses. The active adapter displays in green.
- **Public IP & time** — public IP and country/region code from Cloudflare's trace endpoint, plus the local clock difference from the reported timestamp.
- **DNS** — configured IPv4 DNS servers and a `google.com` resolution test.
- **Latency** — 9 ICMP tests to `8.8.8.8`, showing average latency, a simple jitter indicator, and successful replies.
- **Path MTU** — DF-bit ping test to `8.8.8.8` when the connection is sufficiently stable, then reports the estimated path MTU.
- **Proxy** — WinHTTP proxy configuration and the current user proxy settings.
- **Microsoft Defender** — real-time protection, antispyware, and antivirus status when the Defender cmdlet is available.
- **Other antivirus software** — products registered with Windows Security Center.
- **Secure Boot & TPM** — Secure Boot status and TPM `readiness`/`enabled`/`activated`
- **Services** — Required services to network and vpn work properly. **If this category is empty, it means there is no problem.**
- **Hosts & firewall** — active entries in the Windows `hosts` file and the enabled/disabled state of Windows Firewall profiles.

## ping_all.ps1
### Output
```
========
23    8.8.8.8
18    1.1.1.1
```

- The latency numbers change with each refresh, and any issues are displayed in color.
  - **Yellow:** response time is above `240 ms`.
  - **Bright yellow:** response time changed by more than `15 ms` compared with the previous successful check.
  - **Red:** the server did not respond successfully.

## Requirements

- An active network connection is recommended for the public-IP, DNS, latency, and MTU checks.
- Administrator privileges are **not strictly required**, but some system/security information may be unavailable or incomplete without elevation.

## Usage

### Run the local script

```powershell
powershell -ExecutionPolicy Bypass -File .\network_diagnostics.ps1
```

### Run directly from GitHub

```powershell
irm https://raw.githubusercontent.com/yonesYN/Windows_Network_Check/main/network_diagnostics.ps1 | iex
```

## External services contacted

The script makes network requests/tests to:

- **Cloudflare** — `https://cloudflare.com/cdn-cgi/trace` for public IP and timestamp information.
- **Google DNS** — `8.8.8.8` for ICMP latency and MTU tests.
- **google.com** — for DNS resolution testing.

> [!IMPORTANT]
> ICMP requests may be blocked by a firewall or upstream network.

## Safety / behavior

The script does not modify any system or network settings.
It reads local configuration and performs connectivity checks.
