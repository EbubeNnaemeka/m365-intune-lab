# Compliance policy and BitLocker

## Compliance policy: `Windows 11 - Baseline`

Intune admin center > Devices > Compliance > Create policy > Windows 10 and later

| Setting | Value | Why |
|---|---|---|
| Require BitLocker | Require | Lost or stolen laptops don't leak data |
| Require Secure Boot | Require | Blocks boot-level malware |
| Minimum OS version | 10.0.26100 (Windows 11 24H2) | Unsupported builds stop getting security fixes |
| Require password | Require, minimum 8 characters | |
| Firewall | Require | |
| Microsoft Defender Antimalware | Require | |
| Actions for noncompliance | Mark noncompliant after 1 day; email the user | Gives users time to fix it themselves |

Assign to **All devices** (or a pilot group first).

Then add a Conditional Access policy **Require compliant device** for Exchange Online and SharePoint, in report-only first, so a noncompliant laptop can't reach company data.

## BitLocker: `Windows 11 - BitLocker`

Endpoint security > Disk encryption > Create policy > Windows > BitLocker

| Setting | Value |
|---|---|
| Require device encryption | Enabled |
| Allow warning for other disk encryption | Disabled (silent encryption) |
| Allow standard user encryption | Enabled |
| OS drive: recovery key backup to Entra ID | Required before enabling BitLocker |
| Encryption method (OS drive) | XTS-AES 256-bit |

## Help desk task: retrieve a recovery key (ticket T22)

1. **Verify the caller's identity** per policy. Recovery keys unlock all data on the drive.
2. Ask for the **Key ID** shown on the recovery screen (first 8 characters are enough).
3. Intune > Devices > [device] > Recovery keys, or Entra ID > Devices > [device] > BitLocker keys. Match the Key ID.
4. Read the 48-digit key to the user; viewing it is audited.
5. Note in the ticket why it happened (BIOS/firmware update, TPM change) and, after the user is back in, rotate the key: Intune > device > **BitLocker key rotation**.
