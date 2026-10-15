# MFA with Conditional Access

Business Premium includes Entra ID P1, so use Conditional Access rather than per-user MFA.

## Policy: Require MFA for all users

Entra admin center > Protection > Conditional Access > New policy

| Setting | Value |
|---|---|
| Name | `CA01 - Require MFA - All users` |
| Users | Include: All users. **Exclude: break-glass account** |
| Target resources | All cloud apps |
| Grant | Require multifactor authentication |
| Enable policy | **Report-only** first; check sign-in logs for a day, then **On** |

## Policy: Block legacy authentication

| Setting | Value |
|---|---|
| Name | `CA02 - Block legacy authentication` |
| Users | All users, exclude break-glass |
| Conditions > Client apps | Exchange ActiveSync clients, Other clients |
| Grant | Block access |

Legacy protocols (POP, IMAP, SMTP AUTH) can't do MFA, so attackers use them for password spraying.

## Help desk scenarios to practise

| Scenario | Steps | Matches ticket |
|---|---|---|
| User lost their phone | Verify identity, Entra > user > Authentication methods > delete old methods, require re-register MFA; issue a Temporary Access Pass if needed | T15 |
| User keeps getting MFA prompts they didn't start | Treat as compromise: reset password, revoke sessions, check sign-in logs for the source IP | T14 |
| Who hasn't set up MFA? | `./scripts/Get-M365AccessReport.ps1 \| Where-Object { -not $_.MfaRegistered }` | - |
