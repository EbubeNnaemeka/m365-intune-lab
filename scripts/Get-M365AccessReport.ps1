<#
.SYNOPSIS
    One report for the questions a help desk gets asked most: who has which license,
    who hasn't registered MFA, and which accounts are disabled but still licensed.

.DESCRIPTION
    Outputs one row per user. Pipe to Export-Csv for the ticket or an audit.
    Reading MFA registration needs an Entra ID P1/P2 license in the tenant
    (included in Microsoft 365 Business Premium and E5 trials).

.EXAMPLE
    ./scripts/Get-M365AccessReport.ps1 | Export-Csv access-report.csv -NoTypeInformation

.EXAMPLE
    ./scripts/Get-M365AccessReport.ps1 | Where-Object { -not $_.MfaRegistered }
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'User.Read.All', 'Organization.Read.All', 'AuditLog.Read.All', 'UserAuthenticationMethod.Read.All' -NoWelcome

$skuNames = @{}
Get-MgSubscribedSku -All | ForEach-Object { $skuNames[$_.SkuId] = $_.SkuPartNumber }

$mfa = @{}
Get-MgReportAuthenticationMethodUserRegistrationDetail -All |
    ForEach-Object { $mfa[$_.Id] = $_ }

Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AccountEnabled, Department, AssignedLicenses, SignInActivity |
    ForEach-Object {
        $licenses = @($_.AssignedLicenses.SkuId | ForEach-Object { $skuNames[$_] })
        $reg = $mfa[$_.Id]
        [pscustomobject]@{
            UserPrincipalName   = $_.UserPrincipalName
            DisplayName         = $_.DisplayName
            Department          = $_.Department
            Enabled             = $_.AccountEnabled
            Licenses            = $licenses -join ', '
            MfaRegistered       = [bool]$reg.IsMfaRegistered
            MfaMethods          = ($reg.MethodsRegistered -join ', ')
            LastSignIn          = $_.SignInActivity.LastSignInDateTime
            DisabledButLicensed = (-not $_.AccountEnabled) -and $licenses.Count -gt 0
        }
    }
