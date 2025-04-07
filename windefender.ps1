# Define Splunk HEC endpoint and token
$hecUrl = "https://yoursplunkserver:8088/services/collector"
$hecToken = "your-splunk-hec-token"

try {
    # Get Windows Defender logs
    $defenderLogs = Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 100
    if (-not $defenderLogs) {
        throw "No logs found in the Windows Defender Operational log."
    }
} catch {
    Write-Error "Failed to retrieve Windows Defender logs: $_"
    exit 1
}

try {
    # Convert logs to JSON
    $logJson = $defenderLogs | ForEach-Object {
        @{
            TimeCreated = $_.TimeCreated
            Id = $_.Id
            LevelDisplayName = $_.LevelDisplayName
            Message = $_.Message
        } | ConvertTo-Json
    }
} catch {
    Write-Error "Failed to convert logs to JSON: $_"
    exit 1
}

try {
    # Prepare the payload for Splunk
    $payload = @{
        event = $logJson
        sourcetype = "windows:defender"
    } | ConvertTo-Json
} catch {
    Write-Error "Failed to prepare payload for Splunk: $_"
    exit 1
}

try {
    # Send logs to Splunk using HEC
    $response = Invoke-RestMethod -Uri $hecUrl -Method Post -Body $payload -Headers @{
        "Authorization" = "Splunk $hecToken"
        "Content-Type" = "application/json"
    }
    Write-Host "Logs successfully sent to Splunk."
} catch {
    Write-Error "Failed to send logs to Splunk: $_"
    exit 1
}
