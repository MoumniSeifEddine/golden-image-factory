# OpenSCAP baseline review

## Source report

The supplied report was generated on 2026-09-30 against Ubuntu 22.04 using SCAP Security Guide 0.1.76 and profile `xccdf_org.ssgproject.content_profile_cis_level1_server`.

| Result | Count |
|---|---:|
| Pass | 189 |
| Fail | 52 |
| Not checked / other | 6 |
| Score | 83.87% |

This is a historical baseline from the supplied archive. It is not a result from a build of the revised files.

## Remediation approach

The updated Ansible playbook now implements a number of low-risk controls highlighted by the baseline: sudo logging and shorter credential caching, login banners, account aging defaults, shell inactivity timeout, a consistent umask, persistent/compressed journald storage, SSH MAC restrictions and configuration permissions, cron file permissions, core-dump limits, audit rules, and additional IPv4/IPv6 sysctl settings. AIDE is initialized after the image's provisioning steps so its baseline reflects the final configured filesystem.

Some checks are intentionally not auto-remediated because a generic cloud image cannot safely assume the required operational policy:

- **PAM lockout (`pam_faillock`)**: adding modules directly to Ubuntu's shared PAM stack can lock out the default cloud user or break authentication. A dedicated PAM profile and recovery test are required before enabling it.
- **Root password and `pam_wheel`**: the Ubuntu cloud image normally keeps direct root login disabled and uses the `ubuntu` cloud account with SSH keys and sudo. A generic image should not set a shared root password or invent an operator group policy.
- **Separate `/tmp` partition**: this requires storage/layout decisions at image-build time and should be designed rather than simulated with a bind mount.
- **Firewall (`nftables`/UFW)**: enabling a host firewall with a guessed default policy can block Packer, cloud-init, or operational access. The current Terraform validation security group has no inbound rules; a production host-firewall policy needs explicit application/network requirements.
- **Remote logging**: no log collector endpoint or credentials were provided. The image enables local persistent journald and audit logging; remote forwarding needs a real destination and trust configuration.
- **Kernel module restrictions and service removals**: controls such as disabling USB storage or removing packages should be applied only after confirming they are not required by the target workload.

## Failed rules from the supplied report

The following 52 rule IDs were marked `fail` in the supplied ARF. They should be used as the remediation backlog and rechecked after a new image build.

```text
aide_build_database
aide_check_audit_tools
partition_for_tmp
sudo_custom_logfile
sudo_require_reauthentication
banner_etc_issue
banner_etc_issue_net
accounts_passwords_pam_faillock_deny
accounts_passwords_pam_faillock_interval
accounts_passwords_pam_faillock_unlock_time
set_password_hashing_algorithm_logindefs
account_disable_post_pw_expiration
ensure_pam_wheel_group_empty
ensure_root_password_configured
use_pam_wheel_group_for_su
accounts_tmout
accounts_umask_etc_bashrc
accounts_umask_etc_profile
grub2_enable_apparmor
package_systemd-journal-remote_installed
journald_compress
journald_storage
rsyslog_remote_loghost
sysctl_net_ipv6_conf_all_accept_ra
sysctl_net_ipv6_conf_all_accept_redirects
sysctl_net_ipv6_conf_all_accept_source_route
sysctl_net_ipv6_conf_all_forwarding
sysctl_net_ipv6_conf_default_accept_ra
sysctl_net_ipv6_conf_default_accept_redirects
sysctl_net_ipv6_conf_default_accept_source_route
sysctl_net_ipv4_conf_all_accept_source_route
sysctl_net_ipv4_conf_all_rp_filter
sysctl_net_ipv4_conf_default_rp_filter
service_nftables_enabled
nftables_rules_permanent
package_ufw_removed
permissions_local_var_log
kernel_module_cramfs_disabled
kernel_module_usb-storage_disabled
disable_users_coredumps
file_permissions_cron_d
file_permissions_cron_daily
file_permissions_cron_hourly
file_permissions_cron_monthly
file_permissions_cron_weekly
file_permissions_crontab
has_nonlocal_mta
postfix_network_listening_disabled
file_permissions_sshd_config
sshd_limit_user_access
sshd_use_strong_macs
file_permissions_etc_audit_rulesd
```

The OpenSCAP HTML report and ARF XML contain the detailed check descriptions, rationale, and remediation references. Review the full rule detail before marking any item as resolved.
