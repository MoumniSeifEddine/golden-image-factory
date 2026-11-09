# ============================================================================
# BASELINE SCAN (unhardened reference) - Golden Image Factory
#
# Purpose: measure the STOCK Canonical Ubuntu 22.04 image with exactly the same
# scanners and settings as the hardened pipeline, so the effect of the
# hardening can be compared (before / after).
#
# What is deliberately NOT done here:
#   - no apt upgrade, no Ansible, no hardening of any kind
#   - no AMI is created (skip_create_ami = true) and nothing is registered
#
# The only changes made to the instance are the installation of the two
# scanners (Trivy, OpenSCAP) and the download of the SCAP content, which the
# hardened build also needs.
# ============================================================================

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

packer {
  required_plugins {
    amazon = {
      version = "= 1.3.9"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "baseline" {
  region        = var.aws_region
  instance_type = var.instance_type

  # Same source image selection as the hardened build.
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  ssh_username = "ubuntu"
  ssh_timeout  = "10m"

  temporary_security_group_source_public_ip = true

  # Same instance settings as the hardened build, so only the OS configuration differs.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 16
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # Scan only: do not create an AMI or snapshot.
  skip_create_ami = true
  ami_name        = "baseline-scan-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
}

build {
  sources = ["source.amazon-ebs.baseline"]

  # Scanner prerequisites only (no upgrade).
  provisioner "shell" {
    inline_shebang  = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "cloud-init status --wait || true",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl gnupg unzip libopenscap8",
      "oscap --version"
    ]
  }

  # Trivy via the official APT repository (identical to the hardened build).
  provisioner "shell" {
    inline_shebang  = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "sudo install -d -m 0755 /etc/apt/keyrings",
      "curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/trivy.gpg",
      "sudo chmod 0644 /etc/apt/keyrings/trivy.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main' | sudo tee /etc/apt/sources.list.d/trivy.list",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y trivy",
      "trivy --version"
    ]
  }

  # Same Trivy command as the hardened build.
  provisioner "shell" {
    inline_shebang  = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "sudo trivy fs --scanners vuln --severity CRITICAL,HIGH,MEDIUM --exit-code 0 --format json --output /tmp/trivy-results.json --no-progress /",
      "sudo chmod 0644 /tmp/trivy-results.json"
    ]
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/trivy-results.json"
    destination = "trivy-results.json"
  }

  # Same SCAP Security Guide release and profile as the hardened build.
  provisioner "shell" {
    inline_shebang  = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "mkdir -p /tmp/scap-content",
      "curl -fL --retry 3 --retry-all-errors -o /tmp/scap-security-guide.zip https://github.com/ComplianceAsCode/content/releases/download/v0.1.76/scap-security-guide-0.1.76.zip",
      "SCAP_ENTRY=$(unzip -Z1 /tmp/scap-security-guide.zip | grep -m1 -E '(^|/)ssg-ubuntu2204-ds.xml$' || true)",
      "if [ -z \"$SCAP_ENTRY\" ]; then echo 'ERROR: Ubuntu 22.04 SCAP content not found in release archive'; exit 1; fi",
      "unzip -p /tmp/scap-security-guide.zip \"$SCAP_ENTRY\" > /tmp/scap-content/ssg-ubuntu2204-ds.xml",
      "test -s /tmp/scap-content/ssg-ubuntu2204-ds.xml",
      "rm -f /tmp/scap-security-guide.zip",
      "sudo oscap info /tmp/scap-content/ssg-ubuntu2204-ds.xml"
    ]
  }

  provisioner "shell" {
    inline_shebang  = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euo pipefail",
      "set +e",
      "sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_level1_server --results-arf /tmp/arf.xml --report /tmp/compliance_report.html /tmp/scap-content/ssg-ubuntu2204-ds.xml",
      "OSCAP_RC=$?",
      "set -e",
      "if [ ! -s /tmp/arf.xml ] || [ ! -s /tmp/compliance_report.html ]; then echo 'ERROR: OpenSCAP did not produce both reports'; exit 1; fi",
      "echo \"$OSCAP_RC\" > /tmp/oscap_exit_code",
      "echo \"OpenSCAP evaluation completed (exit $OSCAP_RC; 0 = all pass, 2 = some rules failed).\"",
      "if [ \"$OSCAP_RC\" -ne 0 ] && [ \"$OSCAP_RC\" -ne 2 ]; then echo 'ERROR: OpenSCAP failed to run'; exit \"$OSCAP_RC\"; fi",
      "sudo chmod 0644 /tmp/arf.xml /tmp/compliance_report.html /tmp/oscap_exit_code"
    ]
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/compliance_report.html"
    destination = "compliance_report.html"
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/arf.xml"
    destination = "arf.xml"
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/oscap_exit_code"
    destination = "oscap_exit_code.txt"
  }
}