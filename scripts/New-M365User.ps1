<#
.SYNOPSIS
    Onboards new hires into Microsoft 365 from a CSV: account, license, groups.

.DESCRIPTION
    For each row in the CSV this script:
      1. Creates the Entra ID user with a random temporary password that must be changed at first sign-in.
      2. Sets usage location (required before a license can be assigned), department and job title.
      3. Assigns the license named in the CSV (by SKU part number, e.g. SPB = Microsoft 365 Business Premium).
      4. Adds the user to each group listed (semicolon-separated).
    Users that already exist are skipped, so the script is safe to re-run. Supports -WhatIf.

    Temporary passwords are written to the console only. Deliver them to the manager by phone or
    another approved channel, never in a ticket or email.

.EXAMPLE
    ./scripts/New-M365User.ps1 -CsvPath ./new-hires.csv -Domain contoso.onmicrosoft.com -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string] $CsvPath,
    [Parameter(Mandatory)] [string] $Domain,
    [string] $UsageLocation = 'CA'
)

$ErrorActionPreference = 'Stop'

function Get-RandomPassword {
    # 16 characters from an unambiguous set, with at least one of each required type.
    # Uses the OS cryptographic RNG; Get-Random is not suitable for passwords.
    $rng = { param($max) [System.Security.Cryptography.RandomNumberGenerator]::GetInt32($max) }
    $sets = 'ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnopqrstuvwxyz', '23456789', '!@#$%*?'
    $chars = [System.Collections.Generic.List[char]]::new()
    foreach ($s in $sets) { $chars.Add($s[(& $rng $s.Length)]) }
    $all = -join $sets
    1..12 | ForEach-Object { $chars.Add($all[(& $rng $all.Length)]) }
    # Fisher-Yates shuffle so the required characters aren't always first.
    for ($i = $chars.Count - 1; $i -gt 0; $i--) {
        $j = & $rng ($i + 1)
        $chars[$i], $chars[$j] = $chars[$j], $chars[$i]
    }
    -join $chars
}

Connect-MgGraph -Scopes 'User.ReadWrite.All', 'Group.ReadWrite.All', 'Organization.Read.All' -NoWelcome

$skus = Get-MgSubscribedSku -All
$hires = Import-Csv $CsvPath

foreach ($h in $hires) {
    $alias = ("$($h.FirstName).$($h.LastName)".ToLower() -replace '[^a-z.]', '')
    $upn = "$alias@$Domain"

    if (Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue) {
        Write-Warning "$upn already exists; skipping."
        continue
    }
    if (-not $PSCmdlet.ShouldProcess($upn, 'Create user, assign license, add groups')) { continue }

    $password = Get-RandomPassword
    $user = New-MgUser -DisplayName "$($h.FirstName) $($h.LastName)" -GivenName $h.FirstName -Surname $h.LastName `
        -UserPrincipalName $upn -MailNickname $alias -AccountEnabled `
        -UsageLocation $UsageLocation -Department $h.Department -JobTitle $h.JobTitle `
        -PasswordProfile @{ Password = $password; ForceChangePasswordNextSignIn = $true }

    $sku = $skus | Where-Object SkuPartNumber -EQ $h.License
    if (-not $sku) {
        Write-Warning "License '$($h.License)' not found in this tenant; $upn created without a license."
    }
    elseif ($sku.PrepaidUnits.Enabled - $sku.ConsumedUnits -lt 1) {
        Write-Warning "No free '$($h.License)' licenses left; $upn created without a license."
    }
    else {
        Set-MgUserLicense -UserId $user.Id -AddLicenses @(@{ SkuId = $sku.SkuId }) -RemoveLicenses @() | Out-Null
    }

    foreach ($groupName in ($h.Groups -split ';' | Where-Object { $_ })) {
        $group = Get-MgGroup -Filter "displayName eq '$($groupName.Trim())'"
        if ($group) { New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id }
        else { Write-Warning "Group '$groupName' not found; $upn not added." }
    }

    [pscustomobject]@{ UserPrincipalName = $upn; TemporaryPassword = $password; License = $h.License; Groups = $h.Groups }
}
