# Troubleshooting Case Study 05: Password Hash Sync (PHS) Initial Sign-In Issue

## Overview
* **Issue:** User couldn't sign into Microsoft 365 / My Apps portal after initial hybrid sync.
* **Account:** `apsingh@aman04048989gmail.onmicrosoft.com` (On-Prem: `CORP\apsingh`)
* **Environment:** On-Prem Windows Server 2022 AD DS ⟷ Microsoft Entra Connect ⟷ Microsoft Entra ID (Azure AD)

---

## 🛑 What Happened (The Symptom)
Right after finishing the Microsoft Entra Connect setup wizard, I opened an InPrivate browser window to test cloud sign-in at `https://myapps.microsoft.com`.

When I typed the username `apsingh@aman04048989gmail.onmicrosoft.com`, Microsoft recognized the account right away. But when I typed the password, it failed with this error:
> *"Your account or password is incorrect. If you don't remember your password, reset it now."*

---

## 🔎 What I Checked (Investigation)
1. **Did the user actually sync to the cloud?**
   * I checked the **Microsoft Entra admin center** (`entra.microsoft.com`) under **Users > All users**.
   * The user `Aman Pahuja` was clearly there with **`On-premises sync enabled: Yes`**.
   * This confirmed that directory synchronization worked and the User Principal Name (UPN) matched. The problem was specifically with the password.
2. **Why didn't the password work?**
   * In Microsoft Entra Connect, user accounts (names, emails, groups) and passwords sync through two different mechanisms.
   * User attributes sync during the standard sync cycle, but **Password Hash Synchronization (PHS)** runs as a background service that reads password hashes from the on-premises Active Directory database (`NTDS.dit`).
   * Because the user account had not had a password change event since Entra Connect was installed, the cloud tenant didn't have the updated password hash yet.

---

## 🛠️ How I Fixed It (Resolution)
1. **Reset the password in Active Directory:**
   * On **DC01**, opened **Active Directory Users and Computers (ADUC)**.
   * Right-clicked `CORP\apsingh` $\rightarrow$ clicked **Reset Password**.
   * Entered a `# Strong temporary password` and made sure **"User must change password at next logon"** was unchecked.
2. **Forced an immediate Delta Sync:**
   * Instead of waiting 30 minutes for the next scheduled sync, I opened PowerShell on `DC01` as Administrator and forced an incremental sync:
     ```powershell
     Start-ADSyncSyncCycle -PolicyType Delta
     ```
   * The command returned `Result : Success`.
3. **Waited 60 seconds:**
   * Gave Microsoft Entra ID about a minute to receive and process the new password hash over HTTPS.

---

## ✅ Verification
1. Went back to the InPrivate browser window and went to `https://myapps.microsoft.com`.
2. Signed in with:
   * **Username:** `apsingh@aman04048989gmail.onmicrosoft.com`
   * **Password:** `# Strong temporary password`
3. **Result:** The login went through immediately with zero errors! The browser opened straight to the My Apps dashboard under my tenant.

---

## 💡 What I Learned
* In a hybrid enterprise setup, account creation and password sync operate on separate pipelines.
* If a newly synced user can't sign in right away, don't panic or rebuild Entra Connect. A simple password reset in Active Directory combined with a PowerShell delta sync (`Start-ADSyncSyncCycle -PolicyType Delta`) immediately pushes the fresh hash to the cloud.
