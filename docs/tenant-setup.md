# Tenant setup

## 1. Get a lab tenant

Use a **Microsoft 365 Business Premium trial** (25 licenses, 1 month). It includes everything this lab needs: Exchange Online, Entra ID P1 (Conditional Access, MFA reports) and Intune. Sign up at the Microsoft 365 Business Premium page with a new `*.onmicrosoft.com` domain. Microsoft's trial terms change, so check whether a payment method is required and **set a reminder to cancel before it renews**.

Never use a work or school tenant for this lab.

## 2. Secure the admin account first

1. Register MFA for your global admin account (Microsoft Authenticator).
2. Create a second, break-glass global admin with a long random password stored offline, excluded from Conditional Access. This is standard practice so a bad policy can't lock everyone out.
3. Do day-to-day work as a separate admin with the lowest role that works (User Administrator, Exchange Administrator, Intune Administrator), not Global Administrator.

## 3. Create groups

In the Entra admin center > Groups, create security groups `Sales Team`, `Marketing Team`, `Operations Team` and a Microsoft 365 group `All Staff`. The onboarding CSV refers to them by name.

## 4. Install the PowerShell modules (PowerShell 7)

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
```

## 5. Run the onboarding

```powershell
./scripts/New-M365User.ps1 -CsvPath ./new-hires.example.csv -Domain <yourtenant>.onmicrosoft.com -WhatIf
./scripts/New-M365User.ps1 -CsvPath ./new-hires.example.csv -Domain <yourtenant>.onmicrosoft.com
```
