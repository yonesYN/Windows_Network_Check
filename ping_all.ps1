mode con: cols=38 lines=20
$servers = @(
'8.8.8.8'
'1.1.1.1'
'4.2.2.4'
'9.9.9.9'
'77.88.8.1'
'76.76.2.5'
)


$BPing = @{}

function PingServer {
	param([string]$Server)
	try {
		$response = Test-Connection -ComputerName "$Server" -Count 1 -ErrorAction Stop
		$pingTime = $response.ResponseTime
		$PPing = $BPing[$Server]

		$cr = if ($pingTime -gt 240) { 
			'[33m'
		} elseif ($PPing -and [Math]::Abs($pingTime - $PPing) -gt 15) {
			'[93m'
		} else { '[0m' }

		echo "$cr$pingTime	$Server"
		$BPing[$Server] = $pingTime
	}
	catch {
		echo "[91m$Server"
		$BPing[$Server] = $null
	}
}
echo "Loading.."
while ($true) {
	$result = foreach ($server in $servers) {
		PingServer -Server $server
	}

	Clear-Host
	Write-Host ("==" * 8) -ForegroundColor Cyan
	[Console]::Write($result -join "`n")
}
