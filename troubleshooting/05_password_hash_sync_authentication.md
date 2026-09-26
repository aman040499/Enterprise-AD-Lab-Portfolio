# Troubleshooting Case Study 05: Password Hash Synchronization (PHS) Initial Authentication Failure

## 🔍 Incident Overview
* **System Affected:** Microsoft Entra ID Cloud Authentication / Identity Federation
* **User Account:** `apsingh@aman04048989gmail.onmicrosoft.com` (`CORP\apsingh`)
* **Environment:** Hybrid Active Directory DS (`corp.lab`) ⟷ Microsoft Entra Connect ⟷ Microsoft Entra ID
* **Severity:** Medium (User unable to authenticate to cloud SaaS portal)

---

## 🛑 Problem / Symptom
Following the successful initial export of Active Directory users to Microsoft Entra ID via Microsoft Entra Connect, an authentication attempt was conducted at `https://myapps.microsoft.com`.

While the cloud platform successfully resolved the user principal name (`apsingh@aman04048989gmail.onmicrosoft.com`), password submission was immediately rejected with the following error:
> *"Your account or password is incorrect. If you don't remember your password, reset it now."*

---

## 🔎 Investigation
1. **Cloud Identity Verification:**
   * Inspected the user object in the Microsoft Entra admin center (`entra.microsoft.com`).
   * Confirmed the identity existed with `On-premises sync enabled: Yes` and `User type: Member`.
   * This confirmed that directory synchronization of the user object itself had succeeded, eliminating UPN mismatch as the root issue.
2. **Replication Architecture Analysis:**
   * In Microsoft Entra Connect architecture, object synchronization (attributes, names, group memberships) operates on the standard sync schedule, whereas **Password Hash Synchronization (PHS)** relies on a dedicated directory replication channel via Remote Procedure Call (RPC) targeting the Active Directory Security Accounts Manager (SAM).
   * If a user account has not triggered a password change event since Entra Connect's initial installation, or if the initial hash replication batch has not traversed the queue, the cloud directory possesses no corresponding password hash.
3. **Account State Inspection:**
   * Checked the account attributes in Active Directory Users and Computers (ADUC) on `DC01`. Verified the account was unlocked and the password was not expired.

---

## 🎯 Root Cause
The initial synchronization export created the cloud identity object before the Password Hash Synchronization agent completed the cryptographic hash extraction and transport cycle from `NTDS.dit`. Consequently, Entra ID had no synchronized hash against which to validate the credential attempt.

---

## 🛠️ Resolution & Remediation
1. **Triggered an Explicit Password Change Event:**
   * On `DC01`, opened **Active Directory Users and Computers**.
   * Right-clicked `CORP\apsingh` $\rightarrow$ **Reset Password**.
   * Set a strong password (`Canada2026!#`) and ensured **"User must change password at next logon"** was **unchecked**.
2. **Forced Immediate Delta Replication:**
   * Opened PowerShell as Administrator on `DC01` and manually triggered an incremental synchronization cycle:
     ```powershell
     Start-ADSyncSyncCycle -PolicyType Delta
     ```
   * Monitored the sync cycle execution until it reported `Result : Success`.
3. **Propagation Buffer:**
   * Allowed a 60-second propagation window for the encrypted hash to traverse HTTPS port 443 to the Entra ID authentication endpoints.

---

## ✅ Verification
* Opened an InPrivate browser session and navigated to `https://myapps.microsoft.com`.
* Submitted credentials:
  * Username: `apsingh@aman04048989gmail.onmicrosoft.com`
  * Password: `Canada2026!#`
* **Result:** Authentication succeeded immediately with zero credential warnings.
* The user successfully accessed the **My Apps** enterprise dashboard under the tenant `Default Directory` with the profile card confirming active session context.

---

## 🛡️ Preventive Action & Best Practices
* **Initial Onboarding Procedure:** When deploying Microsoft Entra Connect in production, include an automated password hash sync check or instruct helpdesk staff that newly synced accounts require either a delta sync trigger or a 15–30 minute replication window before end-user notification.
* **Audit Telemetry:** Monitor Windows Event Viewer on the synchronization server under `Application > Directory Synchronization` for Event ID 656 and 657 (PHS heartbeat and password batch export status).
