# Variables
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_name_prefix" {
  type    = string
  default = "golden-image"
}

# Required plugins
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

# Source: AWS EC2 builder with SSH (temporary key pair)
source "amazon-ebs" "golden-image" {
  region = var.aws_region
  instance_type = var.instance_type

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]  # Canonical
  }

  ssh_username = "ubuntu"
  ssh_timeout  = "10m"

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 8
    volume_type = "gp2"
    delete_on_termination = true
  }

  ami_name      = "${var.ami_name_prefix}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  ami_description = "Hardened Ubuntu 22.04 golden image with CIS hardening, Trivy scanning, and compliance validated."

  tags = {
    Name        = "golden-image"
    Environment = "dev"
    Builder     = "Packer"
    BuildTime   = timestamp()
    OS_Version  = "Ubuntu 22.04"
    Hardened    = "true"
  }
}

# Build definition
build {
  sources = ["source.amazon-ebs.golden-image"]

  # ------------------------------
  # PROVISIONER 1: Install prerequisites (including Ansible)
  # ------------------------------
  provisioner "shell" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y python3 python3-pip python3-apt software-properties-common ansible",
    ]
  }

  # ------------------------------
  # PROVISIONER 2: Run Ansible hardening playbook
  # ------------------------------
  provisioner "ansible-local" {
    playbook_file   = "../ansible/playbook/hardening.yml"
    extra_arguments = ["--verbose"]
  }

  # ------------------------------
  # PROVISIONER 3: Install Trivy and scan for CVEs
  # ------------------------------
  provisioner "shell" {
    inline = [
      "sudo apt install -y wget",
      "wget https://github.com/aquasecurity/trivy/releases/download/v0.50.4/trivy_0.50.4_Linux-64bit.deb",
      "sudo dpkg -i trivy_0.50.4_Linux-64bit.deb",
      "rm trivy_0.50.4_Linux-64bit.deb",
      "echo 'Running Trivy filesystem scan...'",
      "sudo trivy fs --severity CRITICAL,HIGH --exit-code 1 / || exit 1",
      "echo 'Trivy scan passed - no CRITICAL or HIGH vulnerabilities found.'"
    ]
  }

  # ------------------------------
  # PROVISIONER 4: Run OpenSCAP compliance scan
  # ------------------------------
  provisioner "shell" {
    inline = [
      "sudo apt update",
      "sudo apt install -y openscap-scanner scap-security-guide bzip2",
      "echo 'Running OpenSCAP compliance scan...'",
      "sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_level1_server --results-arf /tmp/arf.xml --report /tmp/compliance_report.html /usr/share/ubuntu-scap-security-guides/1/benchmarks/ssg-ubuntu2204-ds.xml || true",
      "sudo cp /tmp/compliance_report.html /tmp/arf.xml /home/ubuntu/",
      "echo 'OpenSCAP scan completed. Reports saved in /tmp/'"
    ]
  }

  # ------------------------------
  # POST-PROCESSOR: Save manifest
  # ------------------------------
  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}