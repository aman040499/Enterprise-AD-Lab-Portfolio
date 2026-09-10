# ==============================================================================
# Script Name: Export-ITHealthTelemetry.ps1
# Purpose:     Collects Active Directory health, locked accounts, and security logs
#              into structured JSON for AI IT Operations analysis (Read-Only)
# Environment: Westlake Pipe & Industrial Operations / Enterprise AD DS
# ==============================================================================

[CmdletBinding()]
param(
    [string]$OutputPath = "$PSScriptRoot\IT-Health-Snapshot.json"
)

Write-Host "[*] Initiating Enterprise Health Telemetry Collection..." -ForegroundColor Cyan

# 1. Query Locked Out Accounts (Identity Hygiene)
$LockedAccounts = Search-ADAccount -LockedOut | Select-Object Name, SamAccountName

# 2. Query Inactive Accounts (>90 Days - Security Compliance)
$InactiveAccounts = Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly | 
    Select-Object Name, SamAccountName, LastLogonDate

# 3. Query Recent Failed Logons (Event ID 4625 - Last 24 Hours)
$FailedLogons = Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    Id        = 4625
    StartTime = (Get-Date).AddDays(-1)
} -MaxEvents 10 -ErrorAction SilentlyContinue | ForEach-Object {
    [xml]$xml = $_.ToXml()
    [PSCustomObject]@{
        TimeCreated = $_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
        TargetUser  = ($xml.Event.EventData.Data | Where-Object {$_.Name -eq "TargetUserName"}).'#text'
        Workstation = ($xml.Event.EventData.Data | Where-Object {$_.Name -eq "WorkstationName"}).'#text'
        IpAddress   = ($xml.Event.EventData.Data | Where-Object {$_.Name -eq "IpAddress"}).'#text'
        Status      = ($xml.Event.EventData.Data | Where-Object {$_.Name -eq "Status"}).'#text'
        SubStatus   = ($xml.Event.EventData.Data | Where-Object {$_.Name -eq "SubStatus"}).'#text'
    }
}

# 4. Inspect Core Domain Services Status
$CoreServices = Get-Service -Name NTDS, DNS, Netlogon, WinRM | 
    Select-Object Name, DisplayName, Status

# 5. Assemble Structured Snapshot Object
$TelemetrySnapshot = [PSCustomObject]@{
    ReportTimestamp    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Domain             = "corp.lab"
    DomainController   = $env:COMPUTERNAME
    ActiveDirectory    = @{
        TotalLockedOutCount = ($LockedAccounts | Measure-Object).Count
        LockedOutUsers      = $LockedAccounts
        InactiveUsers90d    = $InactiveAccounts
    }
    SecurityAudits     = @{
        RecentFailedLogons24h = $FailedLogons
    }
    CoreServicesHealth = $CoreServices
}

# 6. Export to JSON for AI / SIEM Ingestion
$TelemetrySnapshot | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "[+] Telemetry snapshot successfully exported to: $OutputPath" -ForegroundColor Green
