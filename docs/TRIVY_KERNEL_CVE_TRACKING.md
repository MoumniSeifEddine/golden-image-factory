# Ubuntu 22.04 AWS Kernel — Trivy Critical CVE Tracking

**Status snapshot:** 12 November 2026  
**Scope:** Golden Image Factory, Ubuntu Server 22.04 LTS (Jammy), AWS kernel branch `linux-aws-6.8`  
**Policy decision:** Keep Ubuntu 22.04 and the current AWS kernel family. Do not migrate to Ubuntu 24.04 or replace the kernel as part of this remediation cycle.

## Executive summary

The latest supplied build evidence for AMI `ami-059d9c71b6c5c94b0` reports **15 Critical Trivy findings representing five unique CVEs**. The findings are repeated across three installed binary packages from the same AWS kernel package family:

- `linux-aws-6.8-headers-6.8.0-1069`
- `linux-headers-6.8.0-1069-aws`
- `linux-modules-6.8.0-1069-aws`

The installed package version reported by Trivy is `6.8.0-1069.74~22.04.1`. The Trivy records have no `FixedVersion`, and the separate fixable Critical/High report contains no matching entries.

The Ubuntu Security Tracker pages were reviewed on 12 November 2026. For **the specific source package `linux-aws-6.8` on Ubuntu 22.04 (Jammy)**, all five CVEs below were marked **Vulnerable** in the tracker at that review. This is a package/release-specific status; do not substitute the status of the generic `linux` source package or another kernel flavour.

## CVE register

| CVE | Affected area / short description | Ubuntu tracker: `linux-aws-6.8`, Jammy | Trivy `FixedVersion` | Current disposition |
|---|---|---|---|---|
| [CVE-2026-63825](https://ubuntu.com/security/CVE-2026-63825) | GCOV instrumentation counter race; concurrent updates can cause inconsistent bounds and memory writes | Vulnerable | Not provided | Open — monitor Ubuntu fix |
| [CVE-2026-64523](https://ubuntu.com/security/CVE-2026-64523) | Network handshake request must hold a long-lived file reference to its socket | Vulnerable | Not provided | Open — monitor Ubuntu fix |
| [CVE-2026-68426](https://ubuntu.com/security/CVE-2026-68426) | XFRM/GSO packet-list handling can retain a stale `skb->prev` pointer after async crypto takes a segment | Vulnerable | Not provided | Open — monitor Ubuntu fix |
| [CVE-2026-90162](https://ubuntu.com/security/CVE-2026-90162) | ksmbd SMB2 lock rollback can race with unlock and cause use-after-free/double-free | Vulnerable | Not provided | Open — monitor Ubuntu fix |
| [CVE-2026-93221](https://ubuntu.com/security/CVE-2026-93221) | NFS server grace-state flags have an unsynchronised concurrent access race | Vulnerable | Not provided | Open — monitor Ubuntu fix |

### Important package-specific clarification

CVE-2026-64523 has a different status for some other Ubuntu kernel source packages. The Ubuntu tracker row for `linux-aws-6.8` explicitly reports Jammy as **Vulnerable**. Use that row when evaluating this AMI; do not infer the AWS kernel status from the generic `linux` row.

## Build evidence baseline

| Field | Recorded value |
|---|---|
| AMI | `ami-059d9c71b6c5c94b0` |
| Region | `us-east-1` |
| OS | Ubuntu Server 22.04 LTS |
| AWS kernel package family | `linux-aws-6.8` |
| Kernel package version in Trivy inventory | `6.8.0-1069.74~22.04.1` |
| Critical Trivy records | 15 |
| Unique Critical CVEs | 5 |
| Affected binary package names | 3 |
| Trivy fixed versions | None reported for these records |
| Fixable Critical/High subset | No matching entries in the supplied fixable report |

The 15 records are not 15 independent CVEs: each of the five CVEs is reported against three binary packages. Trivy's package attribution does not, by itself, prove that every vulnerable code path is loaded or reachable at runtime. No runtime EC2 test is claimed because the AWS Academy account does not permit launching an instance from this custom AMI.

## Decision and risk handling

The project will:

1. Keep Ubuntu 22.04 LTS and the current supported AWS kernel family.
2. Keep the kernel image and modules; do not remove essential kernel packages to lower scanner counts.
3. Keep Trivy scanning enabled and retain the full JSON report.
4. Not suppress these CVEs or mark them as fixed.
5. Re-check Ubuntu's `linux-aws-6.8` status weekly and whenever a new image build changes the kernel package version.
6. When Ubuntu publishes a Jammy `linux-aws-6.8` fix, update through the Ubuntu repository, rebuild the AMI, and confirm the new package version and Trivy results.
7. Record the tracker review date and status changes in this register.

**Current disposition:** documented and monitored; not remediated. The findings remain open until an official applicable fix is available and a new scan verifies the installed package is no longer affected.

## Monitoring

A read-only GitHub Actions workflow, `.github/workflows/monitor-kernel-cves.yml`, checks the Ubuntu Security Tracker pages every Monday and can also be run manually. It checks the Jammy status for the exact `linux-aws-6.8` package row. It does not access AWS, modify the image, or change the kernel.

- A successful monitor run means the expected `Vulnerable` status is still present for all five CVEs.
- A changed status (for example, `Fixed in ...` or `Not affected`) causes the monitor job to flag the change for review.
- A parsing/network error also fails the job; that is not evidence of a fix. Review the job log and the official tracker page.
- After a status changes, verify the exact fixed package version and repository availability before changing the Packer/Ansible build.

## Official references

- [CVE-2026-63825 — Ubuntu Security Tracker](https://ubuntu.com/security/CVE-2026-63825)
- [CVE-2026-64523 — Ubuntu Security Tracker](https://ubuntu.com/security/CVE-2026-64523)
- [CVE-2026-68426 — Ubuntu Security Tracker](https://ubuntu.com/security/CVE-2026-68426)
- [CVE-2026-90162 — Ubuntu Security Tracker](https://ubuntu.com/security/CVE-2026-90162)
- [CVE-2026-93221 — Ubuntu Security Tracker](https://ubuntu.com/security/CVE-2026-93221)
