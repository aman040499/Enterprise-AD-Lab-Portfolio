# Lab 2: Enterprise Hybrid Identity & Microsoft Entra ID Sync

## 🎯 Objective
Extend the on-premises Active Directory Domain Services infrastructure (`corp.lab`) into a modern **Hybrid Cloud Identity** architecture by synchronizing directory objects, security groups, and password hashes with a live **Microsoft Entra ID (formerly Azure AD)** tenant.

---

## 🏛️ Topology & Cloud Prerequisites

* **On-Premises Hypervisor:** VMware Workstation (Subnet: `192.168.105.0/24`)
* **Domain Controller (DC01):** Windows Server 2022 Standard (`192.168.105.129`), Active Directory Domain Services, DNS (`corp.lab`)
* **Client Workstation (WS01):** Windows 11 Pro x64 (`192.168.105.130`), Domain-Joined
* **Cloud Tenant:** Microsoft Entra ID Free
  * **Primary Cloud Domain:** `aman04048989gmail.onmicrosoft.com`
  * **Tenant ID:** `5541e0cd-39eb-48f5-a815-14c6b99436a6`
  * **Dedicated Cloud Admin:** `cloudadmin@aman04048989gmail.onmicrosoft.com` (Global Administrator)

![Enterprise Hybrid Cloud Topology](../architecture/hybrid-architecture.png)

---

## 🛠️ Implementation Progress

### Milestone 1: Alternative UPN Suffix Configuration
* **Challenge:** The on-premises forest uses a non-routable top-level domain (`.lab`). Public cloud identity services cannot route or federate non-routable domains, which would cause Entra ID to assign unexpected fallback routing aliases (`@*.onmicrosoft.com`).
* **Implementation:** Configured `aman04048989gmail.onmicrosoft.com` as an Alternative User Principal Name (UPN) suffix in **Active Directory Domains and Trusts** on `DC01`.
* **Verification:** Verified that the custom UPN suffix is globally available across the forest schema for user object assignment.

![Alternative UPN Suffix in AD Domains and Trusts](../images/lab2/01_ad_upn_suffix.png)

---

### Milestone 2: User Identity UPN Alignment
* **Implementation:** Updated the target production user account (`CORP\apsingh` - Aman Singh) within `OU=Employees,DC=corp,DC=lab` using Active Directory Users and Computers (ADUC).
* **Configuration:** Replaced the legacy logon suffix `@corp.lab` with the cloud-routable UPN `@aman04048989gmail.onmicrosoft.com`.
* **Result:** User identity is aligned with the cloud tenant namespace prior to directory synchronization, ensuring clean identity matching and single-identity logon.

![User Assigned Cloud-Compatible UPN](../images/lab2/02_user_upn_assigned.png)

---

### ⏳ Current Status: Milestone 3 (In Progress)
* **Next Task:** Deploying **Microsoft Entra Connect** (`AzureADConnect.msi`) on `DC01`.
* **Target Sync Settings:**
  * Password Hash Synchronization (PHS)
  * Seamless Single Sign-On (SSO)
  * Targeted OU Filtering (`OU=Employees`, `OU=IT`)
