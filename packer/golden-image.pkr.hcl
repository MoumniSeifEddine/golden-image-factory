variable "aws_region" {
  type        = string
  description = "AWS region where the AMI will be created."
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "Temporary EC2 instance used by Packer."
  default     = "t3.small"
}

variable "ami_name_prefix" {
  type        = string
  description = "Prefix used for the generated AMI name."
  default     = "golden-image"
}

variable "trivy_severities" {
  type        = string
  description = "Severities included in the Trivy report."
  default     = "CRITICAL,HIGH"
}

packer {
  required_version = ">= 1.11.0"
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.8, < 2.0.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.0, < 2.0.0"
    }
  }
}

source "amazon-ebs" "golden-image" {
  region        = var.aws_region
  instance_type = var.instance_type
  ssh_username  = "ubuntu"
  ssh_timeout   = "20m"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 16
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  ami_name        = "${var.ami_name_prefix}-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  ami_description = "Ubuntu 22.04 LTS image hardened with Ansible and assessed with Trivy and OpenSCAP. CIS-inspired; assessment results are provided as build artifacts."

  tags = {
    Name        = var.ami_name_prefix
    Environment = "dev"
    Builder     = "Packer"
    OS          = "Ubuntu 22.04"
    Hardening   = "Ansible"
    BuildTime   = timestamp()
    Project     = "Golden Image Factory"
  }
}

build {
  name    = "golden-image"
  sources = ["source.amazon-ebs.golden-image"]

  provisioner "shell" {
    inline_shebang = "#!/bin/bash -euo pipefail"
    inline = [
      "set -eu",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo apt-get clean",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip python3-apt software-properties-common",
      "sudo python3 -m pip install --no-cache-dir \"ansible==10.7.0\""
    ]
  }

  provisioner "ansible-local" {
    playbook_file = "../ansible/playbook/hardening.yml"
    extra_arguments = ["--diff"]
  }

  # Install Trivy from its signed APT repository. Avoid the deprecated apt-key command.
  provisioner "shell" {
    inline_shebang = "#!/bin/bash -euo pipefail"
    inline = [
      "set -eu",
      "sudo apt-get update",
      "sudo apt-get install -y wget gnupg",
      "wget -qO- https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg >/dev/null",
      "echo 'deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main' | sudo tee /etc/apt/sources.list.d/trivy.list",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y trivy",
      "trivy --version"
    ]
  }

  # Findings are reported but do not block image creation by default. A scanner
  # execution/download error still fails the provisioner.
  provisioner "shell" {
    inline_shebang = "#!/bin/bash -euo pipefail"
    inline = [
      "set -eu",
      "echo 'Running Trivy filesystem vulnerability scan...'",
      "sudo trivy fs --scanners vuln --severity ${var.trivy_severities} --format json --output /home/ubuntu/trivy-report.json --exit-code 0 --no-progress /",
      "sudo chown ubuntu:ubuntu /home/ubuntu/trivy-report.json",
      "echo 'Trivy scan completed; findings are recorded in the JSON report.'"
    ]
  }

  provisioner "shell" {
    inline_shebang = "#!/bin/bash -euo pipefail"
    inline = [
      "set -eu",
      "sudo apt-get install -y curl unzip",
      "cd /tmp",
      "curl --fail --location --retry 3 --retry-delay 2 -o scap-security-guide.zip https://github.com/ComplianceAsCode/content/releases/download/v0.1.76/scap-security-guide-0.1.76.zip",
      "unzip -oq scap-security-guide.zip",
      "SCAP_CONTENT=$(find /tmp -type f -name 'ssg-ubuntu2204-ds.xml' -print -quit)",
      "test -n \"$SCAP_CONTENT\"",
      "sudo oscap info \"$SCAP_CONTENT\""
    ]
  }

  # OpenSCAP returns exit code 2 when evaluation completes and rules fail.
  # That is a valid assessment result, not a scanner execution failure.
  provisioner "shell" {
    inline_shebang = "#!/bin/bash -euo pipefail"
    inline = [
      "set -eu",
      "SCAP_CONTENT=$(find /tmp -type f -name 'ssg-ubuntu2204-ds.xml' -print -quit)",
      "if [ -z \"$SCAP_CONTENT\" ]; then echo 'SCAP content not found'; exit 1; fi",
      "set +e",
      "sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_level1_server --results-arf /home/ubuntu/arf.xml --report /home/ubuntu/compliance_report.html \"$SCAP_CONTENT\"",
      "OSCAP_STATUS=$?",
      "set -e",
      "if [ \"$OSCAP_STATUS\" -ne 0 ] && [ \"$OSCAP_STATUS\" -ne 2 ]; then echo \"OpenSCAP execution error: $OSCAP_STATUS\"; exit \"$OSCAP_STATUS\"; fi",
      "sudo chown ubuntu:ubuntu /home/ubuntu/arf.xml /home/ubuntu/compliance_report.html",
      "echo \"OpenSCAP assessment completed with status $OSCAP_STATUS (0=pass, 2=completed with findings).\""
    ]
  }

  provisioner "file" {
    direction    = "download"
    source       = "/home/ubuntu/compliance_report.html"
    destination  = "compliance_report.html"
  }

  provisioner "file" {
    direction    = "download"
    source       = "/home/ubuntu/arf.xml"
    destination  = "arf.xml"
  }

  provisioner "file" {
    direction    = "download"
    source       = "/home/ubuntu/trivy-report.json"
    destination  = "trivy-report.json"
  }

  # Reports have been copied to the Packer host. Remove build-time scanners
  # and temporary content from the image so the delivered AMI stays smaller.
  provisioner "shell" {
    inline_shebang = "#!/bin/bash -euo pipefail"
    inline = [
      "sudo apt-get purge -y trivy openscap-scanner libopenscap8",
      "sudo apt-get autoremove -y",
      "sudo python3 -m pip uninstall -y ansible ansible-core",
      "sudo rm -f /etc/apt/sources.list.d/trivy.list /usr/share/keyrings/trivy.gpg",
      "sudo rm -rf /tmp/scap-security-guide.zip /tmp/scap-security-guide-* /root/.cache/trivy",
      "sudo rm -f /home/ubuntu/trivy-report.json /home/ubuntu/compliance_report.html /home/ubuntu/arf.xml",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }

  # Initialize AIDE after all package/configuration changes so the stored
  # baseline corresponds to the final image state.
  provisioner "shell" {
    inline_shebang = "#!/bin/bash -euo pipefail"
    inline = [
      "set -eu",
      "sudo aideinit -y -f",
      "if [ -f /var/lib/aide/aide.db.new ]; then sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db; elif [ -f /var/lib/aide/aide.db.new.gz ]; then sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz; else echo 'AIDE database was not generated'; exit 1; fi"
    ]
  }

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
