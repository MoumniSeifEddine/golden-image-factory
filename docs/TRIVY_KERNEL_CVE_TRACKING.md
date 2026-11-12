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
2. Keep the kernel image and modules; do not remove essential kernel packages to lower scanner counts. Kernel **headers** and kernel **tools** packages are not essential at runtime (they only support compiling out-of-tree modules and debugging), so they are removed from the image — see "Remediation applied" below.
3. Keep Trivy scanning enabled and retain the full JSON report.
4. Not suppress these CVEs or mark them as fixed.
5. Re-check Ubuntu's `linux-aws-6.8` status weekly and whenever a new image build changes the kernel package version.
6. When Ubuntu publishes a Jammy `linux-aws-6.8` fix, update through the Ubuntu repository, rebuild the AMI, and confirm the new package version and Trivy results.
7. Record the tracker review date and status changes in this register.

**Current disposition:** documented and monitored; not remediated. The findings remain open until an official applicable fix is available and a new scan verifies the installed package is no longer affected.

## Remediation applied (12 November 2026)

Trivy reported each CVE against three binary packages. Only one of them (`linux-modules-6.8.0-1069-aws`) contains kernel code that is loaded at runtime; the other two are build-time headers:

| Package | Needed at runtime? | Action |
|---|---|---|
| `linux-modules-6.8.0-1069-aws` | Yes — loadable kernel modules | **Kept** |
| `linux-aws-6.8-headers-6.8.0-1069` | No — C headers for compiling modules | Removed |
| `linux-headers-6.8.0-1069-aws` | No — same | Removed |

`ansible/playbook/hardening.yml` now purges the header packages and the `linux-aws` / `linux-headers-aws` meta-packages that depend on them (and, as before, the optional kernel tools packages). `linux-image-aws` is marked manually installed first, so kernel security updates keep arriving through it. The playbook asserts that no header/tools packages remain, that `linux-image-aws` and the modules package are installed, and that the running kernel image is still in `/boot`.

**Expected effect on the next scan (to be confirmed by a new build, not yet claimed):** the Critical records should fall from 15 to 5 and the High records from 525 to 175. The five unique Critical CVEs remain open, because the affected code is in the kernel modules package for which Ubuntu has published no fix. Nothing is suppressed or marked as fixed.

### Result of the 12 November 2026 build

The next build confirmed the expected effect: Trivy reported **CRITICAL=5, HIGH=175** against Ubuntu 22.04, and the `--ignore-unfixed` CRITICAL/HIGH report was **empty**. All remaining CRITICAL/HIGH findings are kernel CVEs in `linux-modules-6.8.0-1069-aws` with no Ubuntu fix. No package update can clear them.

## Exposure reduction for unfixed CVEs (12 November 2026)

The findings stay open and reported. Every one of the 180 CRITICAL/HIGH records was mapped to the subsystem its upstream fix touches. The full per-CVE table is in [`TRIVY_KERNEL_CVE_COVERAGE.md`](TRIVY_KERNEL_CVE_COVERAGE.md).

| Category | CRITICAL | HIGH | How |
|---|---:|---:|---|
| Module blocked | 3 | 121 | `/etc/modprobe.d/98-golden-image-kernel-cve-mitigation.conf` blocks 94 modules (`install <m> /bin/false` + `blacklist`); initramfs is rebuilt |
| Restricted (sysctl/userns) | 2 | 37 | `kernel.unprivileged_bpf_disabled=1`, `net.core.bpf_jit_harden=2`, `kernel.unprivileged_userns_clone=0`, `kernel.perf_event_paranoid>=3`, `kernel.kptr_restrict=2`, `kernel.dmesg_restrict=1` |
| Code not built for x86_64 | 0 | 6 | arm64/s390 KVM, Qualcomm MSM GPU, OMAP framebuffer, Arm FF-A; Trivy matches the source package, not the compiled kernel |
| Residual | 0 | 11 | ext4 (root fs), nftables `nft_ct`/`x_tables` (firewall), `bridge` (containers), NFS client (EFS), IOMMU, fcntl, PSI |
| **Total** | **5** | **175** | |

For the five CRITICAL CVEs:

| CVE | Mitigation |
|---|---|
| CVE-2026-90162 (ksmbd) | `ksmbd` blocked |
| CVE-2026-93221 (NFS server) | `nfsd` blocked (`lockd` stays: the NFS client and EFS need it) |
| CVE-2026-68426 (XFRM/ESP GSO) | `esp4`, `esp6`, both `_offload` modules, `xfrm_user`, `xfrm_interface`, `af_key` blocked |
| CVE-2026-64523 (net/handshake) | Built in. Consumers `nfsd` and `nvmet_tcp` are blocked; NFS-client TLS could still use it |
| CVE-2026-63825 (GCOV) | Only reachable if the kernel has `CONFIG_GCOV_KERNEL`; the build log records the setting |

**Build-time checks:** the playbook unloads any blocked module that is loaded. It then classifies each one as `BLOCKED`, `BUILTIN` (cannot be blocked) or `ABSENT` (not shipped with this kernel), and fails the build if a shipped module is loadable or still loaded. It also verifies every sysctl and prints the module report and the related kernel config options. Check the `BUILTIN` lines in the next build log: those CVEs move from "Module blocked" to "Residual".

**Impact on derived images.** Remove the module from `kernel_cve_blocked_modules` in the playbook if a workload needs:

- an in-kernel SMB/NFS server, kernel IPsec (strongSwan/libreswan), or kernel TLS
- the SMB client (`cifs`, e.g. FSx for Windows)
- KVM/vhost on bare-metal instances
- `amdgpu` on G4ad instances
- SCTP, or btrfs/f2fs/other non-ext4 file systems

`kernel.unprivileged_userns_clone=0` breaks rootless containers and some browser sandboxes; root-run Docker/containerd are unaffected.

**This does not change Trivy counts.** Trivy matches package versions, not loaded modules or sysctls, so CRITICAL=5 / HIGH=175 will be reported until Ubuntu publishes a fixed `linux-aws-6.8` package and the AMI is rebuilt. Remove the mitigation file and sysctls only after a fixed kernel is installed and confirmed.

**Regenerating the coverage table** after a new scan: map each new CVE's upstream subject to a category, then update `kernel_cve_blocked_modules` and the coverage doc together.

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
