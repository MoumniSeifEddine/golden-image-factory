# Security remediation notes — 10 November 2026

This revision makes targeted corrections based on the remaining failed rules recorded in the supplied OpenSCAP assessment and the Trivy findings described in the project report.

## Changes included

- GRUB UEFI password: the build now requires `GRUB_PASSWORD_HASH`; no default or plaintext password is embedded. The Ansible playbook verifies the PBKDF2 hash format, writes the GRUB superuser entry, regenerates GRUB, and checks the generated configuration for both `password_pbkdf2` and AppArmor kernel parameters.
- PAM faillock: policy values are explicitly supplied in both `faillock.conf` and the PAM module lines to make the effective deny, interval, and unlock settings unambiguous.
- Audit: all `.rules` files in `/etc/audit/rules.d` are explicitly set to `root:root` and mode `0640` before rules are loaded.
- Logging: persistent/compressed journald remains configured; ordinary log files are restricted to mode `0640` without changing their service ownership, while `wtmp`, `btmp`, and `lastlog` retain accounting-compatible ownership and modes.
- Network: reverse-path filtering is set for all/default and each interface discovered at build time.
- nftables: syntax and boot enablement are explicitly verified.
- SSH: effective `sshd -T` output is checked against the configured cipher, KEX and MAC policy.
- Trivy: a final package update/full-upgrade/autoremove pass occurs after the hardening dependencies are installed, followed by a second Ansible pass that reapplies configuration before the filesystem scan.
- Remote logging: optional forwarding is enabled only when an approved collector is provided via `REMOTE_SYSLOG_HOST`; no fictitious destination is configured.

## Findings that remain policy/environment dependent

- `ensure_root_password_configured`: root remains locked on the Ubuntu cloud image; remote root login remains disabled. Do not add a reusable root password solely to satisfy the check.
- `set_password_hashing_algorithm_logindefs`: Ubuntu's yescrypt setting is retained rather than downgraded without policy approval. Verify the exact CIS/SSG benchmark expectation before changing the algorithm.
- `rsyslog_remote_loghost`: requires a real, approved collector endpoint. Supply `REMOTE_SYSLOG_HOST` and optionally `REMOTE_SYSLOG_PORT` if available.
- SSH crypto findings can vary with the OpenSSH version and the benchmark's accepted algorithm list. The build now asserts the effective configuration; the next OpenSCAP ARF must confirm whether the exact benchmark check passes.
- AIDE's final database is initialised in Packer after package cleanup. Packer now requires the immediate AIDE integrity check to return zero; a successful `aide --init` command alone is not proof of a passing rule.

## Required GitHub configuration

1. On a trusted machine, run `grub-mkpasswd-pbkdf2`.
2. Enter a unique, strong bootloader password and copy only the generated `grub.pbkdf2.sha512...` hash.
3. Add that hash as repository secret `GRUB_PASSWORD_HASH`.
4. If an approved remote syslog collector exists, add repository variable `REMOTE_SYSLOG_HOST`; optionally add `REMOTE_SYSLOG_PORT` (default `514`).
5. Push this revision and run the complete workflow.

Do not paste the plaintext GRUB password or its hash into chat, source files, issue comments, or build logs.

## Validation status

The repository changes require a fresh GitHub Actions run. This editing environment can perform structural checks, but it cannot build an AWS AMI or run OpenSCAP/Trivy against the resulting guest. No compliance score or CVE reduction is claimed until the new reports are available.
