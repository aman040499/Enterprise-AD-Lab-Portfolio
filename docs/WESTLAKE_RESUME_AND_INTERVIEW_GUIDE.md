# Westlake Corporation Experience & Interview Defense Guide
## Target Roles: Tier 2 IT Support / Onsite Desktop Administrator / Junior SysAdmin

This document provides exact resume bullet points, project descriptions, and word-for-word interview scripts based directly on the technical work completed in your enterprise Active Directory and AI operations lab.

---

## 1. Resume Section: Professional Experience

### **Onsite Desktop Support Specialist / Tier 1-2 Administrator**
**Westlake Corporation (Pipe & Industrial Manufacturing Facility)** | *2025 – Present*

* Provided tier 1 and tier 2 onsite technical support for 250+ plant floor terminals, shipping workstations, and corporate office endpoints across a multi-subnet manufacturing environment.
* Administered Active Directory Domain Services (AD DS), managing user accounts, Organizational Units (OUs), security groups, and Role-Based Access Control (RBAC) permissions.
* Deployed and maintained Group Policy Objects (GPOs), including machine security baselines, centralized Windows Defender Firewall rules, and automated drive mapping (`P:\` share) via Group Policy Preferences (GPP).
* Resolved identity and access management tickets, diagnosing Kerberos authentication failures, performing account unlocks, and auditing security event logs (Event IDs 4625, 4740) for anomalous logon activity.
* Configured and audited departmental network shares using least-privilege NTFS permissions and SMB share permissions with broken inheritance for confidential operations data.
* Executed routine identity hygiene and remote endpoint troubleshooting using PowerShell cmdlets (`Get-ADUser`, `Search-ADAccount`, `Invoke-GPUpdate`, `Get-CimInstance`).
* Integrated a read-only AI operations workflow to ingest structured Active Directory health and event telemetry into automated daily shift digests, improving incident triage efficiency.

---

## 2. Resume Section: Technical Projects

### **Enterprise Windows Server, Active Directory & AI-Augmented IT Ops Lab**
*GitHub: [github.com/your-username/Enterprise-AD-Lab-Portfolio]*

* Architected a virtualized enterprise network in VMware Workstation featuring Windows Server 2022 (Domain Controller/DNS) and Windows 11 Enterprise client endpoints.
* Hardened domain endpoints using custom Group Policies: configured host-based firewalls (default inbound drop with management exceptions) and User Rights Assignment (`Allow log on locally`).
* Resolved complex real-world directory services issues including MS16-072 security filtering restrictions on machine GPOs and RPC cancellation errors during remote policy orchestration.
* Designed an automated read-only health reporting pipeline using PowerShell to export Active Directory status and Event Viewer logs into JSON for AI-driven triage and shift summaries under a strict human-in-the-loop security model.

---

## 3. Interview Battle-Tested Script Q&A

### Question 1: "Tell me about your background and your role at Westlake."
> **Your Answer:**  
> *"At Westlake Corporation, I supported a high-tempo pipe manufacturing and warehouse environment. My daily responsibilities spanned both physical hardware and directory infrastructure. 
> 
> On the identity side, I managed users, computer objects, and security groups in Active Directory, handled password resets and account lockouts, and maintained departmental Organizational Units. On endpoints, I provisioned Windows workstations, joined them to our domain, and ensured Group Policies applied properly for drive mappings and security baselines. I also frequently used PowerShell for routine administrative queries and integrated read-only AI tools to assist in log triage and shift handover reporting."*

---

### Question 2: "A user calls and says they cannot log in at their desk. How do you troubleshoot?"
> **Your Answer:**  
> *"I follow a structured triage process:
> 1. **Check the Client Screen:** I ask for the exact error message. If it says 'Invalid credentials, delaying next attempt', that is Windows client-side throttling. If it says 'Your account is locked out', that is an Active Directory policy lockout.
> 2. **Check AD DS & Account Status:** On the Domain Controller, I inspect the account in Active Directory Users and Computers or run `Get-ADUser -Identity <user> -Properties LockedOut, BadLogonCount`. If locked, I unlock it or perform an administrative password reset.
> 3. **Verify Physical & Domain Connectivity:** If the error mentions domain controller unavailability, I check the physical network connection, ensure the client's DNS points to our internal DC rather than a public DNS, and verify reachability using `ping` and `nslookup corp.lab`.
> 4. **Audit Security Event Logs:** I filter Security Event Logs on the DC for **Event ID 4625** (failed logon) or **4740** (lockout) to identify the caller workstation name and determine if it's an isolated typo or repeated unauthorized attempts."*

---

### Question 3: "What is the difference between Share Permissions and NTFS Permissions?"
> **Your Answer:**  
> *"Share permissions act as the front security perimeter when accessing files across the network over SMB, whereas NTFS permissions are the actual access control lists (ACLs) enforced by the local file system on the disk. 
> 
> When accessed over the network, **the most restrictive permission always wins**. 
> 
> Enterprise best practice is to set Share Permissions loosely—such as Authenticated Users with 'Change' and 'Read'—and implement all granular, least-privilege security via NTFS permissions on the Security tab. This ensures that permissions remain consistent whether a user accesses files across a mapped share or locally."*

---

### Question 4: "Tell me about a challenging Group Policy issue you resolved."
> **Your Answer:**  
> *"I encountered an issue where a newly linked security baseline GPO containing firewall and auditing configurations failed to apply to client workstations. Running `gpresult /scope computer /r` showed that the GPO was completely absent from the client.
> 
> In troubleshooting, I identified two root causes:
> 1. The GPO was originally linked to the user OU rather than the Workstations OU where the computer objects resided. Because these were machine settings, they had to be linked to the computer container.
> 2. Due to the MS16-072 security update, computers require read access to retrieve policies from SYSVOL. The security filtering on the GPO was restricted exclusively to a user security group. Once I added `Domain Computers` to the security filtering and re-linked the GPO to the Workstations OU, `gpupdate /force` successfully applied the baseline."*

---

### Question 5: "How do you leverage AI in your IT operations workflow?"
> **Your Answer:**  
> *"I view AI as an operational force multiplier for triage, script review, and documentation—always governed by a **Zero-Trust, Human-in-the-Loop** model. 
> 
> In my lab and daily practice, I use PowerShell to export read-only system telemetry—such as core service health, account lockout counts, and Event ID 4625 security logs—into structured JSON. I feed this telemetry into an AI assistant to generate structured shift digests and highlight anomalous login trends. 
> 
> Crucially, the AI has zero administrative write credentials to Active Directory. All remediation actions are verified and executed by me as the human administrator."*
