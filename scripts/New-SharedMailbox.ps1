<#
.SYNOPSIS
    Creates a shared mailbox (e.g. support@) and gives a team Full Access and Send As.

.DESCRIPTION
    Shared mailboxes don't need a license (under 50 GB). Full Access lets members open the mailbox;
    Send As lets them send mail that appears to come from it. Members already granted are skipped.
    Supports -WhatIf.

.EXAMPLE
    ./scripts/New-SharedMailbox.ps1 -Name 'Support' -Alias support `
        -Members tom.reid@contoso.onmicrosoft.com, aisha.bello@contoso.onmicrosoft.com
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string] $Name,
    [Parameter(Mandatory)] [string] $Alias,
    [Parameter(Mandatory)] [string[]] $Members
)

$ErrorActionPreference = 'Stop'
Connect-ExchangeOnline -ShowBanner:$false

$mailbox = Get-Mailbox -Identity $Alias -ErrorAction SilentlyContinue
if (-not $mailbox -and $PSCmdlet.ShouldProcess($Alias, 'Create shared mailbox')) {
    $mailbox = New-Mailbox -Shared -Name $Name -Alias $Alias -DisplayName $Name
    Write-Output "Created shared mailbox $($mailbox.PrimarySmtpAddress)"
}

foreach ($m in $Members) {
    if ($PSCmdlet.ShouldProcess($m, "Grant Full Access and Send As on $Alias")) {
        if (-not (Get-MailboxPermission -Identity $Alias -User $m -ErrorAction SilentlyContinue)) {
            Add-MailboxPermission -Identity $Alias -User $m -AccessRights FullAccess -AutoMapping $true | Out-Null
        }
        if (-not (Get-RecipientPermission -Identity $Alias -Trustee $m -ErrorAction SilentlyContinue)) {
            Add-RecipientPermission -Identity $Alias -Trustee $m -AccessRights SendAs -Confirm:$false | Out-Null
        }
        Write-Output "Granted Full Access and Send As to $m"
    }
}
