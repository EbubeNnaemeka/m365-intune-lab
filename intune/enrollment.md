# Enrolling a Windows 11 device in Intune

## Lab device

- **Apple Silicon Mac:** Windows 11 on ARM in [UTM](https://mac.getutm.app/) (free) or Parallels. 4 GB RAM, 64 GB disk.
- **Intel/AMD PC:** Windows 11 Enterprise evaluation in Hyper-V or VirtualBox.

## Steps

1. Intune admin center > Devices > Enrollment > Windows: confirm **MDM user scope = All** (Automatic enrollment).
2. On the VM: Settings > Accounts > Access work or school > Connect > **Join this device to Microsoft Entra ID**, sign in as a lab user (e.g. jordan.patel).
3. Back in Intune > Devices > Windows: the device appears within a few minutes. Record the device name and compliance state in the results table.

## Optional: Windows Autopilot

Export the VM's hardware hash and upload it so a reset device sets itself up with the company profile:

```powershell
Install-Script -Name Get-WindowsAutopilotInfo -Scope CurrentUser
Get-WindowsAutopilotInfo -OutputFile C:\autopilot.csv
```

Upload at Devices > Enrollment > Windows > Devices (Windows Autopilot) > Import, assign a deployment profile, then reset the VM and watch the out-of-box experience.
