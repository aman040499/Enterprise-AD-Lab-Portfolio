# Enterprise Troubleshooting Case Studies (Tier 1 / Tier 2 IT Operations)

This document details the real-world operational issues diagnosed, investigated, and remediated across the `corp.lab` infrastructure. These case studies demonstrate practical troubleshooting methodology using native Windows tools, Event Viewer, and Group Policy telemetry.

---

## INCIDENT-001: Workstation Authentication Failure & Client-Side Rate-Limiting

### Ticket Summary
* **Ticket ID:** INC-2026-001
* **Reported By:** User `CORP\apsingh`
* **Affected Endpoint:** `WS01.corp.lab`
* **Reported Issue:** *"I entered my password multiple times and now the screen won't let me type. It says credentials are invalid and delaying next attempt."*

### Root Cause Analysis (RCA)
1. **Client-Side Throttling vs. AD Lockout:**
   * Initial hypothesis suspected an Active Directory Account Lockout (Event ID 4740).
   * Inspection of DC01 Event Viewer for Event ID 4740 yielded 0 events. 
   * The message *"Invalid credentials, delaying next attempt..."* was identified as Windows 11 client-side brute-force mitigation (Credential Provider rate-limiting) rather than domain lockout.
2. **Domain Controller Event Audit:**
   * Filtered Security Event Log on `DC01` for **Event ID 4625** (Failed Logon).
   * Confirmed repeated logon failures originating from Caller Computer Name: `WS01`.
   * Failure status code: `0xC000006A` (Status: Bad Password).

### Remediation
1. Navigated to Active Directory Users and Computers (`dsa.msc`) on `DC01`.
2. Verified account flags under the `Account` tab.
3. Reset user credential with a standardized complex temporary password.
4. Allowed Windows 11 client throttling window to expire on `WS01`.
5. Successfully authenticated user into domain session and confirmed Kerberos Ticket Granting Ticket (TGT) generation.

---

## INCIDENT-002: Group Policy Baseline Non-Enforcement (MS16-072 & OU Scope Mismatch)

### Ticket Summary
* **Ticket ID:** INC-2026-002
* **Target System:** `WS01.corp.lab`
* **Policy Name:** `GPO- Employees- Security baseline`
* **Reported Issue:** Hardened Windows Defender Firewall rules and Audit policies were not applying to `WS01` after domain join.

### Investigation
1. Ran `gpresult /scope computer /r` on `WS01` within an elevated administrative prompt.
2. The GPO was entirely absent—not listed under *Applied GPOs*, nor listed under *Filtered Out GPOs*.
3. Inspected Group Policy Management Console (`gpmc.msc`) on `DC01`:
   * **Issue A (OU Boundary):** The GPO contained *Computer Configuration* settings (Firewall, Auditing, User Rights). However, it was linked exclusively to `OU=Employees`, which contained only user accounts. GPOs flow down container hierarchies; they do not cross laterally into sibling OUs.
   * **Issue B (MS16-072 Security Filtering):** Microsoft Security Bulletin MS16-072 requires computer accounts to have **Read** access to GPOs to download policies from SYSVOL. Security Filtering on the GPO had been restricted strictly to `GG_EMPLOYEES` (users only), denying `WS01$` read rights.

### Remediation
1. Linked `GPO- Employees- Security baseline` directly to `OU=Workstations`.
2. Added **`Domain Computers`** to the **Security Filtering** tab in GPMC, granting `WS01$` read and apply permissions.
3. Executed `gpupdate /force` on `WS01`.
4. Re-ran `gpresult /scope computer /r` and confirmed `GPO- Employees- Security baseline` is now listed under **Applied Group Policy Objects**.

---

## INCIDENT-003: User Console Logon Blocked by User Rights Assignment

### Ticket Summary
* **Ticket ID:** INC-2026-003
* **Target User:** `CORP\apsingh`
* **Target Endpoint:** `WS01.corp.lab`
* **Reported Issue:** User greeted with: *"The sign-in method you're trying to use isn't allowed. For more info, contact your network administrator."*

### Investigation
1. Occurred immediately following the successful application of `GPO- Employees- Security baseline`.
2. Opened GPO Editor on `DC01` at `Computer Configuration ➔ Policies ➔ Windows Settings ➔ Security Settings ➔ Local Policies ➔ User Rights Assignment`.
3. Inspected the **"Allow log on locally"** policy:
   * Current list: `Administrators`, `CORP\Administrator`, `CORP\Employees - all`.
   * User `CORP\apsingh` belongs to `GG_EMPLOYEES` and `GG_IT_admins`.
   * Because User Rights Assignment replaces default local machine permissions, any group not explicitly declared in this policy is strictly denied physical/interactive logon.

### Remediation
1. Added **`GG_EMPLOYEES`**, **`GG_IT_admins`**, and **`Domain Users`** to **Allow log on locally** in GPMC.
2. Rebooted `WS01` to pull the updated computer startup security policy.
3. Successfully logged in as `CORP\apsingh`.

---

## INCIDENT-004: Remote Group Policy Update RPC Cancellation (Error 8007071a)

### Ticket Summary
* **Ticket ID:** INC-2026-004
* **Source:** `DC01.corp.lab`
* **Target:** `WS01.corp.lab`
* **Reported Issue:** Executing "Group Policy Update..." from GPMC on `DC01` resulted in: `Failed (1) - Error Code: 8007071a: The remote procedure call was cancelled`.

### Investigation
1. Remote GPUpdate from GPMC reaches across the network using Remote Procedure Call (RPC) and WMI to create a temporary scheduled task (`ForceGroupPolicyUpdate`) on the client.
2. Because `WS01` had our hardened Windows Defender Firewall baseline active ("Inbound unmatched: BLOCKED"), the incoming RPC traffic on port 135 and dynamic RPC ports was dropped.

### Remediation
1. In `GPO- Employees- Security baseline`, added predefined Inbound Firewall Rules:
   * **Remote Event Log Management** (RPC, EPMAP, NP)
   * **Remote Service Management** (RPC, EPMAP, NP)
   * **Remote Scheduled Tasks Management** (RPC, EPMAP)
   * **Windows Management Instrumentation (WMI)**
2. Refreshed policy on `WS01` to load firewall exceptions.
3. Re-ran Remote GPUpdate from `DC01` GPMC: Result showed green progress bar **`Succeeded (1 of 1)`**.
