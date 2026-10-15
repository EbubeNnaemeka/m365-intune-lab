<#
.SYNOPSIS
    Offboards a leaver from Microsoft 365 in the order that protects data and access.

.DESCRIPTION
    Steps, in order:
      1. Block sign-in and revoke all active sessions (refresh tokens), so access stops immediately.
      2. Convert the mailbox to a shared mailbox and give the manager Full Access, so email is kept
         without needing a paid license (shared mailboxes under 50 GB are free).
      3. Turn on an automatic reply pointing senders to the manager.
      4. Remove the user from all groups.
      5. Remove licenses (only after step 2, otherwise the mailbox is deleted after 30 days).
    Every step is logged to the console for the ticket. Supports -WhatIf.

.EXAMPLE
    ./scripts/Remove-M365User.ps1 -UserPrincipalName chris.wong@contoso.onmicrosoft.com `
        -ManagerUpn priya.shah@contoso.onmicrosoft.com -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string] $UserPrincipalName,
    [Parameter(Mandatory)] [string] $ManagerUpn
)

$ErrorActionPreference = 'Stop'
function Step([string] $Message) { Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm')] $Message" }

Connect-MgGraph -Scopes 'User.ReadWrite.All', 'Group.ReadWrite.All', 'Directory.AccessAsUser.All' -NoWelcome
Connect-ExchangeOnline -ShowBanner:$false

$user = Get-MgUser -UserId $UserPrincipalName -Property Id, DisplayName, AssignedLicenses
$manager = Get-MgUser -UserId $ManagerUpn -Property DisplayName, Mail

if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Block sign-in and revoke sessions')) {
    Update-MgUser -UserId $user.Id -AccountEnabled:$false
    Revoke-MgUserSignInSession -UserId $user.Id | Out-Null
    Step "Blocked sign-in and revoked sessions for $UserPrincipalName"
}

if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Convert mailbox to shared and grant manager access')) {
    Set-Mailbox -Identity $UserPrincipalName -Type Shared
    Add-MailboxPermission -Identity $UserPrincipalName -User $ManagerUpn -AccessRights FullAccess -AutoMapping $true | Out-Null
    Step "Converted mailbox to shared; $($manager.DisplayName) has Full Access"
}

if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Set automatic reply')) {
    $message = "$($user.DisplayName) is no longer with the company. Please contact $($manager.DisplayName) at $($manager.Mail)."
    Set-MailboxAutoReplyConfiguration -Identity $UserPrincipalName -AutoReplyState Enabled `
        -InternalMessage $message -ExternalMessage $message -ExternalAudience All
    Step 'Automatic reply enabled'
}

$groups = Get-MgUserMemberOf -UserId $user.Id -All |
    Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group' }
foreach ($g in $groups) {
    $name = $g.AdditionalProperties['displayName']
    if ($PSCmdlet.ShouldProcess($name, "Remove $UserPrincipalName from group")) {
        try {
            Remove-MgGroupMemberByRef -GroupId $g.Id -DirectoryObjectId $user.Id
            Step "Removed from group '$name'"
        }
        catch {
            # Dynamic groups and mail-enabled security groups can't be edited through this call.
            Write-Warning "Could not remove from '$name' (dynamic or Exchange-managed group?): $($_.Exception.Message)"
        }
    }
}

$skuIds = @($user.AssignedLicenses.SkuId)
if ($skuIds.Count -and $PSCmdlet.ShouldProcess($UserPrincipalName, "Remove $($skuIds.Count) license(s)")) {
    Set-MgUserLicense -UserId $user.Id -AddLicenses @() -RemoveLicenses $skuIds | Out-Null
    Step "Removed $($skuIds.Count) license(s)"
}

Step "Offboarding complete for $UserPrincipalName. Next: collect the device and wipe it from Intune."
