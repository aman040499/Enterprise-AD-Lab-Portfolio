# ==============================================================================
# Script Name: New-Employee.ps1
# Purpose:     Automated employee provisioning script enforcing OU placement,
#              standardized naming, and Role-Based Access Control (RBAC)
# Environment: Corporate Enterprise / Hybrid Active Directory DS
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
    [string]$DefaultGroup = "SG-Corporate-Employees",

    [Parameter(Mandatory=$false)]
    [SecureString]$InitialPassword
)

$SamAccountName = ($FirstName.Substring(0,1) + $LastName).ToLower()
$DisplayName    = "$FirstName $LastName"
$UserPrincipal  = "$SamAccountName@corp.lab"

# If no password is provided via parameter, generate a secure random 16-character complex temporary password
if (-not $InitialPassword) {
    $Chars       = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%^&*'
    $RandomPass  = -join ((1..16) | ForEach-Object { $Chars[(Get-Random -Maximum $Chars.Length)] })
    $AccountPass = ConvertTo-SecureString $RandomPass -AsPlainText -Force
} else {
    $AccountPass = $InitialPassword
}

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
        -AccountPassword $AccountPass `
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
