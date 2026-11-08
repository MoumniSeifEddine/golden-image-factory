# Golden Image Factory — Engineering Fixes

This file records the changes made during the project hardening pass. It is not a claim that the modified pipeline has completed a new AWS build.

## Changes applied

### CI/CD and supply chain

- Added a pre-build Ansible syntax check and Terraform format/initialisation/validation checks so configuration errors are caught before the long Packer build.
- Pinned GitHub Actions to immutable commit SHAs.
- Pinned Packer to 1.11.2 and verifies the downloaded release archive against HashiCorp's published SHA-256 checksum file.
- Pinned the Packer Amazon and Ansible plugins to the versions observed in the supplied successful build log (1.3.9 and 1.1.3).
- Pinned the AWS Terraform provider to 5.100.0, the version observed in the supplied Terraform init log.
- Added workflow concurrency protection and a 90-minute job timeout.
- Changed Trivy's APT key installation from deprecated `apt-key` to a dedicated keyring with `signed-by`.
- Changed Trivy output to machine-readable JSON containing CRITICAL, HIGH and MEDIUM findings. The scan remains explicitly report-only until a vulnerability exception/remediation policy is agreed; findings are not falsely described as a clean scan.
- Removed `|| true` from OpenSCAP execution. Exit code 2 (completed evaluation with rule failures/unknowns) is retained as report evidence; operational errors and missing reports fail the build.
- Uploads the Packer manifest, AMI ID, OpenSCAP HTML/ARF, Trivy JSON and build log as CI evidence.

### Image build and hardening

- Restricted Packer's temporary SSH security-group ingress to the Packer runner's detected public IP instead of `0.0.0.0/0`.
- Requires IMDSv2 on the temporary build instance.
- Encrypts the Packer build root EBS volume at launch, avoiding a separate post-build AMI copy/encryption step.
- Applies OS package upgrades before hardening and assessment.
- Runs Ansible from an isolated Python virtual environment pinned to Ansible 10.7.0, stages its playbook under `/var/tmp` (so the hardened no-exec `/tmp` mount does not break provisioning), and removes the build-only environment.
- Consolidated SSH policy into a validated early-loaded OpenSSH drop-in: public-key authentication only, a dedicated `ssh-users` access group, root/password login disabled, hardened ciphers/MACs/key exchange, connection limits, forwarding restrictions and a login banner.
- Configured PAM faillock in the actual `common-auth` stack rather than only writing `faillock.conf`.
- Connected `pam_pwquality` and `pam_pwhistory` to the active `common-password` stack and made `pam_unix` consume the checked password token.
- Retained Ubuntu's modern yescrypt password hashing rather than downgrading to SHA-512 solely to satisfy an older compliance check. The supplied SSG profile may continue to flag its SHA-512-specific rule; the next scan must confirm this.
- Added sudo command logging and zero sudo timestamp reuse.
- Added baseline audit rules and restrictive permissions.
- Added local/remote login banners, session timeout, account inactivity defaults and an empty `sugroup` restriction for `su`.
- Added persistent/compressed journald configuration.
- Added nftables with default-deny inbound policy, allowing loopback, established traffic, ICMP and SSH. The AWS security group remains responsible for restricting the SSH source at the network boundary.
- Mounted `/tmp` as a bounded 512 MiB `tmpfs` with `nosuid,nodev,noexec`; hardened `/dev/shm` similarly.
- Added IPv6 sysctl hardening, kernel-module restrictions, core-dump limits and cron permission controls.
- Removed unused UFW and Postfix packages.
- Added AIDE monitoring entries for audit tools and initialise/test the AIDE database after Trivy is removed and before the final OpenSCAP assessment.
- Scan reports and temporary SCAP content are downloaded to the CI runner and removed from the guest before the AMI snapshot. Trivy and Ansible build-only tooling are not retained in the image.
- GRUB no longer uses a predictable hardcoded password. If bootloader authentication is required, the pipeline accepts a precomputed PBKDF2 hash through the protected `GRUB_PASSWORD_HASH` GitHub secret. If it is not configured, the GRUB password tasks are skipped.

### Terraform and lifecycle

- Replaced use of the default security group with a dedicated validation security group containing no inbound rules.
- Removed the hard-coded SSH key-pair dependency and public IP assignment from the test instance.
- Requires IMDSv2 and an encrypted root volume on the validation instance.
- Added an explicit saved Terraform plan followed by apply, EC2 status-check validation and teardown. The state file is uploaded only on failure with a three-day retention period to support recovery from partial applies.
- Improved cleanup to select only AMIs tagged `ManagedBy=GoldenImageFactory`, retain the three newest, and delete snapshots associated with deregistered images.
- Replaced the unsafe manual cleanup helper with `scripts/cleanup.sh`, which defaults to dry-run and requires `--apply` for deletion. It never deletes untagged AMIs and does not run `terraform destroy` against an arbitrary state file.
- Rewrote the README to match the actual source tree and actual pipeline behaviour; removed empty/misnamed files that were not used.

## GitHub repository secrets

Required by the current AWS Academy credential workflow:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

Optional:

- `GRUB_PASSWORD_HASH` — a precomputed `grub.pbkdf2.sha512...` hash generated on a trusted machine with `grub-mkpasswd-pbkdf2`. Do not store the plaintext password in the repository.

## Important behaviour and exceptions

- Trivy findings are collected as evidence; the current build is not blocked by the number of CVEs. A strict severity gate should be introduced only after the findings have been triaged and an exception policy exists.
- OpenSCAP rule failures do not automatically fail Packer, because the purpose is to produce and inspect a compliance report. OpenSCAP execution errors and absent reports do fail the build.
- Ubuntu's root account remains locked; the CIS check requiring a configured root password is intentionally not “fixed” by enabling a remote root password. Root SSH login remains disabled and administrative access is expected through sudo.
- No remote syslog destination is invented. The systemd journal is made persistent/compressed and the receiver package is installed, but remote log forwarding still requires an organisation-approved collector endpoint.
- The OpenSCAP check requiring a configured root password is intentionally not satisfied: the Ubuntu cloud image keeps the root account locked, root SSH is disabled, and administrative access uses the `ubuntu` account with sudo. Do not enable a reusable root password just to increase the benchmark score.
- `AllowGroups ssh-users` means any additional administrator account must be explicitly added to that group.
- The Terraform test validates EC2 system/instance status checks only. It does not yet prove SSH login, application readiness or every hardening control after boot.
- The Ubuntu source AMI and APT package versions are intentionally updated from current repositories; therefore the build is not bit-for-bit reproducible. The manifest and build logs must be retained to trace each output.

## Validation performed in this editing environment

- YAML parsing of the GitHub Actions workflow and Ansible playbook.
- Structural checks on Ansible task/handler definitions and duplicate task names.
- Shell syntax check of `scripts/cleanup.sh` and each GitHub Actions `run` block.
- HCL delimiter/quote checks for the Packer template and Terraform files.
- Secret-hygiene check confirming the old predictable GRUB password literal is absent.

## Validation still required

The current editing environment does not have Packer, Terraform or Ansible installed and has no network access to install them. Therefore the following have **not** been executed here:

- `ansible-playbook --syntax-check` (the workflow now runs it on GitHub Actions).
- `packer init`, `packer fmt`, `packer validate` and a new AWS Packer build.
- `terraform fmt`, `terraform init`, `terraform validate`, plan/apply/destroy.
- OpenSCAP and Trivy scans against the newly hardened image.
- A boot test, SSH access test and post-boot hardening verification.

A new GitHub Actions run is required before treating these changes as validated. AWS Academy's existing explicit IAM restrictions may still prevent the Terraform EC2 launch test.
