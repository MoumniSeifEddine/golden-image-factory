# ============================================================
# VARIABLES
# ============================================================

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ami_name_prefix" {
  type    = string
  default = "golden-image"
}

variable "grub_password_hash" {
  type        = string
  description = "Optional precomputed GRUB PBKDF2 hash supplied through PKR_VAR_grub_password_hash / a CI secret."
  default     = ""
  sensitive   = true
}


# ============================================================
# REQUIRED PACKER PLUGINS
# ============================================================

packer {

  required_plugins {

    amazon = {
      version = "= 1.3.9"
      source  = "github.com/hashicorp/amazon"
    }

    ansible = {
      version = "= 1.1.3"
      source  = "github.com/hashicorp/ansible"
    }

  }
}


# ============================================================
# AMAZON EBS SOURCE
# ============================================================

source "amazon-ebs" "golden-image" {

  region        = var.aws_region
  instance_type = var.instance_type


  # ----------------------------------------------------------
  # Ubuntu 22.04 LTS
  # ----------------------------------------------------------

  source_ami_filter {

    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }

    most_recent = true

    owners = [
      "099720109477"
    ]
  }


  # ----------------------------------------------------------
  # SSH configuration
  # ----------------------------------------------------------

  ssh_username = "ubuntu"
  ssh_timeout  = "10m"

  # Ask Packer to discover its own public IP and allow only that address
  # into the temporary build security group (instead of 0.0.0.0/0).
  temporary_security_group_source_public_ip = true

  # Require IMDSv2 on the temporary build instance.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }


  # ----------------------------------------------------------
  # Root volume
  # ----------------------------------------------------------

  launch_block_device_mappings {

    device_name           = "/dev/sda1"
    volume_size           = 16
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }


  # ----------------------------------------------------------
  # AMI metadata
  # ----------------------------------------------------------

  ami_name = "${var.ami_name_prefix}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"

  # NOTE: do NOT set ami_description (or ami_users/ami_groups/snapshot_users).
  # Packer applies them via ec2:ModifyImageAttribute, which the AWS Academy
  # (voclabs) service control policy explicitly denies. Use a tag instead.


  tags = {

    Name        = "golden-image"
    Environment = "dev"
    Builder     = "Packer"
    BuildTime   = timestamp()

    OS_Version = "Ubuntu 22.04"

    Hardened = "true"
    ManagedBy = "GoldenImageFactory"

    Description = "Hardened Ubuntu 22.04 Golden AMI - CIS-inspired hardening, auditd, Trivy, OpenSCAP"
  }
}


# ============================================================
# BUILD
# ============================================================

build {

  sources = [
    "source.amazon-ebs.golden-image"
  ]


  # ==========================================================
  # STEP 1: Clean APT cache and install prerequisites
  # ==========================================================

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",

      # Clean corrupted APT cache (fixes "can not open" error)
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo apt-get clean",

      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y",
      "sudo apt-get autoremove -y",

      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv python3-apt software-properties-common",

      "sudo python3 -m venv /opt/ansible-venv",
      "sudo /opt/ansible-venv/bin/pip install --no-cache-dir ansible==10.7.0"
    ]
  }


  # ==========================================================
  # STEP 2: Apply security hardening
  # ==========================================================

  provisioner "ansible-local" {

    command          = "/opt/ansible-venv/bin/ansible-playbook"
    staging_directory       = "/var/tmp/packer-provisioner-ansible-local"
    clean_staging_directory = true
    playbook_file           = "../ansible/playbook/hardening.yml"

    extra_arguments = [
      "--verbose",
      "--extra-vars",
      "grub_password_hash=${var.grub_password_hash}"
    ]
  }

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "sudo rm -rf /opt/ansible-venv"
    ]
  }


  # ==========================================================
  # STEP 3: Install Trivy via official APT repository
  # ==========================================================

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",

      "sudo apt-get update",

      "sudo apt-get install -y wget curl gnupg",

      "sudo install -d -m 0755 /etc/apt/keyrings",
      "curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/trivy.gpg",
      "sudo chmod 0644 /etc/apt/keyrings/trivy.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main' | sudo tee /etc/apt/sources.list.d/trivy.list",

      "sudo apt-get update",

      "sudo apt-get install -y trivy",

      "trivy --version"
    ]
  }


  # ==========================================================
  # STEP 4: Run Trivy vulnerability scan
  # ==========================================================

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",

      "echo 'Running Trivy filesystem vulnerability scan...'",

      "sudo trivy fs --scanners vuln --severity CRITICAL,HIGH,MEDIUM --exit-code 0 --format json --output /tmp/trivy-results.json --no-progress /",
      "sudo chmod 0644 /tmp/trivy-results.json",
      "echo 'Trivy scan completed; review trivy-results.json for findings (report-only policy).'"
    ]
  }

  # Download the vulnerability report immediately so it is preserved
  # even if the later OpenSCAP assessment fails.
  provisioner "file" {
    direction   = "download"
    source      = "/tmp/trivy-results.json"
    destination = "trivy-results.json"
  }

  # ==========================================================
  # STEP 5: Download SCAP Security Guide
  # ==========================================================

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"

    inline = [

      "set -euxo pipefail",

      "echo 'Checking OpenSCAP installation...'",

      "oscap --version",

      "echo 'Downloading SCAP Security Guide...'",

      "mkdir -p /tmp/scap-content",

      "curl -fL --retry 3 --retry-all-errors -o /tmp/scap-security-guide.zip https://github.com/ComplianceAsCode/content/releases/download/v0.1.76/scap-security-guide-0.1.76.zip",

      "unzip -o /tmp/scap-security-guide.zip -d /tmp/scap-content",

      "SCAP_CONTENT=$(find /tmp/scap-content -type f -name 'ssg-ubuntu2204-ds.xml' | head -n 1)",

      "if [ -z \"$SCAP_CONTENT\" ]; then echo 'ERROR: Ubuntu 22.04 SCAP content not found'; exit 1; fi",

      "echo \"Using SCAP content: $SCAP_CONTENT\"",

      "sudo oscap info \"$SCAP_CONTENT\""
    ]
  }


  # ==========================================================
  # STEP 6: Remove Trivy build tooling and initialise final AIDE database
  # ==========================================================

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "sudo apt-get purge -y trivy",
      "sudo rm -f /etc/apt/sources.list.d/trivy.list /etc/apt/keyrings/trivy.gpg",
      "sudo rm -rf /root/.cache/trivy",
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo aideinit -y -f",
      "sudo test -s /var/lib/aide/aide.db.new",
      "sudo install -o root -g root -m 0600 /var/lib/aide/aide.db.new /var/lib/aide/aide.db",
      "sudo aide --config=/etc/aide/aide.conf --check"
    ]
  }

  # ==========================================================
  # STEP 7: Run OpenSCAP compliance scan and preserve rule-failure evidence
  # ==========================================================

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euo pipefail",
      "SCAP_CONTENT=$(find /tmp/scap-content -type f -name 'ssg-ubuntu2204-ds.xml' | head -n 1)",
      "if [ -z \"$SCAP_CONTENT\" ]; then echo 'ERROR: Ubuntu 22.04 SCAP content not found'; exit 1; fi",
      "echo \"Running OpenSCAP scan with: $SCAP_CONTENT\"",
      "set +e",
      "sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_level1_server --results-arf /tmp/arf.xml --report /tmp/compliance_report.html \"$SCAP_CONTENT\"",
      "OSCAP_RC=$?",
      "set -e",
      "if [ ! -s /tmp/arf.xml ] || [ ! -s /tmp/compliance_report.html ]; then echo 'ERROR: OpenSCAP did not produce both reports'; exit 1; fi",
      "printf '%s' \"$OSCAP_RC\" | sudo tee /tmp/oscap_exit_code >/dev/null",
      "sudo chmod 0644 /tmp/arf.xml /tmp/compliance_report.html /tmp/oscap_exit_code",
      "echo \"OpenSCAP evaluation completed (exit $OSCAP_RC; status will be evaluated after reports are downloaded).\""
    ]
  }


  # ==========================================================
  # STEP 8: Download assessment reports to the CI runner
  # ==========================================================

  provisioner "file" {

    direction = "download"

    source = "/tmp/compliance_report.html"

    destination = "compliance_report.html"
  }


  provisioner "file" {

    direction = "download"

    source = "/tmp/arf.xml"

    destination = "arf.xml"
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/oscap_exit_code"
    destination = "oscap_exit_code.txt"
  }


  # ==========================================================
  # STEP 9: Remove temporary assessment files from the image
  # ==========================================================

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    execute_command = "/bin/bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "OSCAP_RC=$(cat /tmp/oscap_exit_code)",
      "sudo rm -rf /tmp/scap-content /tmp/scap-security-guide.zip /tmp/trivy-results.json /tmp/arf.xml /tmp/compliance_report.html /tmp/oscap_exit_code",
      "if [ \"$OSCAP_RC\" -ne 0 ] && [ \"$OSCAP_RC\" -ne 2 ]; then echo \"ERROR: OpenSCAP execution error (exit $OSCAP_RC); reports were downloaded for diagnosis.\"; exit \"$OSCAP_RC\"; fi"
    ]
  }

  # ==========================================================
  # STEP 10: Create Packer manifest
  # ==========================================================

  post-processor "manifest" {

    output = "packer-manifest.json"

    strip_path = true
  }
}