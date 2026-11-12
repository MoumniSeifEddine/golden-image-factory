# Golden Image Factory

**Automated security-hardened Ubuntu Server 22.04 AMI build pipeline**

Golden Image Factory builds an AWS AMI from a Canonical Ubuntu 22.04 LTS source image. GitHub Actions orchestrates Packer; Packer runs Ansible hardening, Trivy vulnerability assessment and OpenSCAP CIS Level 1 Server assessment, then publishes the AMI manifest and scan evidence. Terraform defines a disposable boot-validation instance.

## Implemented components

| Component | Responsibility |
|---|---|
| GitHub Actions | CI orchestration, AWS authentication, build, evidence upload, Terraform validation/deployment and managed-image retention |
| Packer (`packer/golden-image.pkr.hcl`) | Creates the temporary EC2 build host and registers the hardened AMI |
| Ansible (`ansible/playbook/hardening.yml`) | Applies Ubuntu security configuration |
| Trivy | Generates a machine-readable vulnerability report (report-only gate pending policy tuning) |
| OpenSCAP + SCAP Security Guide | Evaluates the CIS Level 1 Server profile and writes HTML/ARF reports |
| Terraform (`terraform/`) | Creates a disposable, no-inbound validation instance with IMDSv2 and encrypted root storage |

Only AWS AMI output is implemented. Azure image builds, a separate lint job, and Ansible Galaxy roles are not implemented in this repository.

## Prerequisites

- GitHub repository with Actions enabled.
- AWS credentials stored as repository secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` (the current AWS Academy workflow uses temporary credentials).
- Permissions for the Packer EC2/AMI/EBS operations and Terraform test-instance lifecycle. AWS Academy policies may deny some of these operations.
- Required GitHub secret `GRUB_PASSWORD_HASH`. Generate a PBKDF2 hash with `grub-mkpasswd-pbkdf2` on a trusted machine and store only the resulting `grub.pbkdf2.sha512...` value as the secret. No plaintext/default password is embedded in source. The workflow fails early if this secret is absent or malformed, rather than silently producing an image that fails the High-severity UEFI bootloader-password rule.
- Optional GitHub Actions repository variable `REMOTE_SYSLOG_HOST` and `REMOTE_SYSLOG_PORT` (default `514`) for an organisation-approved remote syslog collector. If no approved endpoint is provided, remote forwarding remains deliberately unconfigured and is reported as an environmental/policy dependency.

To create the required GRUB secret, run `grub-mkpasswd-pbkdf2` on a trusted Linux/WSL machine (install `grub-common` first if needed), enter a unique strong password, and copy the generated `grub.pbkdf2.sha512...` hash into **GitHub → Settings → Secrets and variables → Actions → New repository secret** with the exact name `GRUB_PASSWORD_HASH`. Never paste the plaintext password or hash into the repository or chat.

Packer discovers the build runner's public IP and restricts its temporary SSH security-group ingress to that address rather than opening port 22 to `0.0.0.0/0`.

## Run

Push to `main` or use **Actions → Build Hardened Golden AMI → Run workflow**. The workflow validates the Packer template, builds the AMI, uploads the manifest and scan reports, then attempts a disposable Terraform boot test. The test instance has no inbound rules or public IP; validation uses EC2 system/instance status checks. If a workflow fails, the Terraform state is uploaded as a short-lived (three-day) recovery artifact so partially created test resources can be cleaned up. Treat this artifact as internal infrastructure metadata.
The hardened SSH policy permits public-key access only for members of the `ssh-users` group. The default `ubuntu` account is added automatically; any additional administrative account must also be added to this group.

A successful image build does not imply that the Terraform test succeeded. The AWS principal must separately be authorised for `ec2:RunInstances`, security-group creation and the related cleanup operations.
The build also needs the EC2/EBS permissions required to create and tag the temporary instance, key pair, security group, AMI and snapshots, plus permission to use the EBS encryption key. The template deliberately no longer calls `ec2:ModifyImageAttribute`, because that operation was explicitly denied by the supplied AWS Academy policy. An explicit deny on `ec2:RunInstances` cannot be repaired in Packer or Terraform code; it requires an account/policy with the necessary permission.

## Evidence artefacts

The `golden-image-build-evidence` artifact contains the Packer manifest, AMI ID, OpenSCAP HTML/ARF, the complete Trivy JSON report, a separate fixable CRITICAL/HIGH Trivy report (`--ignore-unfixed`), and the Packer output log when those files exist. Scan reports are downloaded to the runner and removed from the guest before the AMI snapshot. The Trivy and Ansible build tools, kernel headers and kernel tools packages are removed before image finalisation; OpenSCAP remains available for future local compliance checks. The AIDE baseline is created after Trivy is removed and before the final OpenSCAP assessment.

## Cleanup

`scripts/cleanup.sh` performs a dry run by default and only selects images tagged `ManagedBy=GoldenImageFactory`. Review the proposed deletions, then run:

```bash
AWS_REGION=us-east-1 KEEP_GOLDEN_AMIS=3 ./scripts/cleanup.sh --apply
```

The script deregisters only images beyond the retention count and deletes their associated EBS snapshots. It does not destroy Terraform-managed resources; use the matching Terraform state and explicit `terraform destroy` for the disposable test instance.

## Security notes

- Packer and Ansible plugin versions are pinned to the versions validated in the supplied successful build logs.
- The Packer release archive is checksum-verified before installation.
- The build host firewall uses nftables with default-deny inbound policy and permits SSH; Packer restricts the temporary AWS security group to the build host public IP. The final deployment security group must still enforce the intended management-source policy.
- `/tmp` and `/dev/shm` are mounted with restrictive execution and device options; `/tmp` uses a bounded 512 MiB tmpfs.
- The Trivy repository uses a dedicated APT keyring and `signed-by`, not deprecated `apt-key`.
- A final APT update/full-upgrade/autoremove pass runs after hardening dependencies are installed. Ansible is then run a second time to reapply security configuration after package post-install scripts, before the Trivy filesystem scan, reducing findings caused by stale package versions. It does not guarantee that every CVE has an available Ubuntu fix.
- Every generated audit `.rules` file is explicitly set to `root:root 0640`; ordinary log files receive restrictive `0640` modes while accounting-log ownership and write permissions are preserved.
- The effective SSH daemon crypto configuration, generated GRUB AppArmor/password entries, nftables syntax and service enablement, and runtime reverse-path-filter values are checked during provisioning.
- Vulnerability findings are currently recorded in JSON without failing the image build. A severity gate should be enabled only after a documented exception/remediation policy is agreed.
- OpenSCAP rule failures are retained as assessment findings. Scanner execution errors and missing report files fail the build.
- Ubuntu's root account remains locked; do not set a reusable root password merely to satisfy a benchmark check. Administrative access is expected through the `ubuntu` account and sudo.
- Ubuntu's yescrypt password hashing default is retained rather than downgraded to SHA-512; the CIS/SSG rule result must be reviewed as a possible benchmark-version exception.
- Remote syslog forwarding is not configured without an organisation-approved collector endpoint.
- Terraform test instances use a dedicated security group with no ingress, no public IP, IMDSv2 required and encrypted root storage.

## Validation status

Cloud build and deployment results must be taken from the current workflow run. The previously supplied evidence records a successful AMI build but a Terraform launch blocked by the AWS Academy explicit IAM deny. No claim of a successful post-hardening runtime/SSH test is made.


## Outstanding kernel CVEs

The `linux-aws-6.8` build had five outstanding Critical CVEs, reported as 15 Trivy records across three binary packages. The two header packages are now removed from the image because they contain no runtime kernel code, so the next scan is expected to show 5 Critical records (kernel modules package only) until Ubuntu publishes a fix. They are documented in [`docs/TRIVY_KERNEL_CVE_TRACKING.md`](docs/TRIVY_KERNEL_CVE_TRACKING.md). The repository includes a read-only weekly GitHub Actions monitor for the exact Ubuntu Security Tracker package row (`linux-aws-6.8`, Jammy). It does not change the kernel, build an AMI, or access AWS credentials.
