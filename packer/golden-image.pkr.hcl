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


# ============================================================
# REQUIRED PACKER PLUGINS
# ============================================================

packer {

  required_plugins {

    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }

    ansible = {
      version = ">= 1.1.0"
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


  # ----------------------------------------------------------
  # Root volume
  # ----------------------------------------------------------

  launch_block_device_mappings {

    device_name           = "/dev/sda1"
    volume_size           = 16
    volume_type           = "gp3"
    delete_on_termination = true
  }


  # ----------------------------------------------------------
  # AMI metadata
  # ----------------------------------------------------------

  ami_name = "${var.ami_name_prefix}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"

  ami_description = "Hardened Ubuntu 22.04 Golden AMI with CIS-inspired hardening, auditd, Trivy vulnerability scanning, and OpenSCAP compliance validation."


  tags = {

    Name        = "golden-image"
    Environment = "dev"
    Builder     = "Packer"
    BuildTime   = timestamp()

    OS_Version = "Ubuntu 22.04"

    Hardened = "true"
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
  # STEP 1: Install prerequisites
  # ==========================================================

  provisioner "shell" {

    inline = [

      "set -eux",

      "sudo apt-get update",

      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip python3-apt software-properties-common",

      "sudo pip3 install --no-cache-dir ansible==10.7.0"
    ]
  }


  # ==========================================================
  # STEP 2: Apply security hardening
  # ==========================================================

  provisioner "ansible-local" {

    playbook_file = "../ansible/playbook/hardening.yml"

    extra_arguments = [
      "--verbose"
    ]
  }


  # ==========================================================
  # STEP 3: Install Trivy
  # ==========================================================

  provisioner "shell" {

    inline = [

      "set -eux",

      "sudo apt-get update",

      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wget ca-certificates",

      "wget -q https://github.com/aquasecurity/trivy/releases/download/v0.50.4/trivy_0.50.4_Linux-64bit.deb",

      "sudo dpkg -i trivy_0.50.4_Linux-64bit.deb",

      "rm -f trivy_0.50.4_Linux-64bit.deb",

      "trivy --version"
    ]
  }


  # ==========================================================
  # STEP 4: Run Trivy vulnerability scan
  # ==========================================================

  provisioner "shell" {

    inline = [

      "set -eux",

      "echo 'Running Trivy filesystem vulnerability scan...'",

      "sudo trivy fs --scanners vuln --severity CRITICAL,HIGH --exit-code 1 --no-progress /",

      "echo 'Trivy scan passed.'"
    ]
  }


  # ==========================================================
  # STEP 5: Find OpenSCAP content
  # ==========================================================

  provisioner "shell" {

    inline = [

      "set -eux",

      "echo 'Checking OpenSCAP installation...'",

      "oscap --version",

      "echo 'Searching for Ubuntu 22.04 SCAP Security Guide content...'",

      "SCAP_CONTENT=$(find /usr/share -type f \\( -name 'ssg-ubuntu2204-ds.xml' -o -name 'ssg-ubuntu2204-ds.xml.bz2' \\) | head -n 1)",

      "if [ -z \"$SCAP_CONTENT\" ]; then echo 'ERROR: Ubuntu 22.04 SCAP Security Guide content not found'; exit 1; fi",

      "echo \"Using SCAP content: $SCAP_CONTENT\"",

      "if [[ \"$SCAP_CONTENT\" == *.bz2 ]]; then bunzip2 -k \"$SCAP_CONTENT\"; SCAP_CONTENT=\"${SCAP_CONTENT%.bz2}\"; fi",

      "echo \"Final SCAP content: $SCAP_CONTENT\"",

      "sudo oscap info \"$SCAP_CONTENT\""
    ]
  }


  # ==========================================================
  # STEP 6: Run OpenSCAP compliance scan
  # ==========================================================

  provisioner "shell" {

    inline = [

      "set -eux",

      "SCAP_CONTENT=$(find /usr/share -type f -name 'ssg-ubuntu2204-ds.xml' | head -n 1)",

      "if [ -z \"$SCAP_CONTENT\" ]; then echo 'ERROR: Uncompressed Ubuntu 22.04 SCAP content not found'; exit 1; fi",

      "echo \"Running OpenSCAP scan with: $SCAP_CONTENT\"",

      "sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_level1_server --results-arf /tmp/arf.xml --report /tmp/compliance_report.html \"$SCAP_CONTENT\"",

      "sudo cp /tmp/compliance_report.html /home/ubuntu/compliance_report.html",

      "sudo cp /tmp/arf.xml /home/ubuntu/arf.xml",

      "sudo chown ubuntu:ubuntu /home/ubuntu/compliance_report.html /home/ubuntu/arf.xml",

      "echo 'OpenSCAP scan completed successfully.'"
    ]
  }


  # ==========================================================
  # STEP 7: Download reports from temporary EC2 instance
  # ==========================================================

  provisioner "file" {

    direction = "download"

    source = "/home/ubuntu/compliance_report.html"

    destination = "compliance_report.html"
  }


  provisioner "file" {

    direction = "download"

    source = "/home/ubuntu/arf.xml"

    destination = "arf.xml"
  }


  # ==========================================================
  # STEP 8: Create Packer manifest
  # ==========================================================

  post-processor "manifest" {

    output = "packer-manifest.json"

    strip_path = true
  }
}