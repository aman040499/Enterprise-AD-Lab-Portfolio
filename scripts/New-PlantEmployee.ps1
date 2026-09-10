# ==============================================================================
# Script Name: New-PlantEmployee.ps1
# Purpose:     Automated employee provisioning script enforcing OU placement,
#              standardized naming, and Role-Based Access Control (RBAC)
# Environment: Westlake Pipe & Industrial Operations
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FirstName,

    [Parameter(Mandatory=$true)]
    [string]$LastName,

    [Parameter(Mandatory=$true)]
    [string]$Department,

    [Parameter(Mandatory=$false)]
    [string]$TargetOU = "OU=Employees,DC=corp,DC=lab",

    [Parameter(Mandatory=$false)]
    [string]$DefaultGroup = "GG_EMPLOYEES"
)

$SamAccountName = ($FirstName.Substring(0,1) + $LastName).ToLower()
$DisplayName    = "$FirstName $LastName"
$UserPrincipal  = "$SamAccountName@corp.lab"
$DefaultPass    = ConvertTo-SecureString "WestlakeWelcome2026!" -AsPlainText -Force

Write-Host "[*] Provisioning directory account for $DisplayName ($SamAccountName)..." -ForegroundColor Cyan

try {
    # 1. Create Active Directory User
    New-ADUser `
        -Name $DisplayName `
        -GivenName $FirstName `
        -Surname $LastName `
        -SamAccountName $SamAccountName `
        -UserPrincipalName $UserPrincipal `
        -DisplayName $DisplayName `
        -Department $Department `
        -Path $TargetOU `
        -AccountPassword $DefaultPass `
        -Enabled $true `
        -ChangePasswordAtLogon $true -ErrorAction Stop

    Write-Host "[+] User object successfully created under $TargetOU" -ForegroundColor Green

    # 2. Enforce Role-Based Group Membership
    Add-ADGroupMember -Identity $DefaultGroup -Members $SamAccountName -ErrorAction Stop
    Write-Host "[+] Added $SamAccountName to security group: $DefaultGroup" -ForegroundColor Green

    Write-Host "[✓] Provisioning complete. User must change password upon first interactive logon." -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to provision user: $_"
}
