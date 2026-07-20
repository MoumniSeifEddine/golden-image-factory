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

# Source: AWS EC2 builder
source "amazon-ebs" "golden-image" {
  region = var.aws_region
  instance_type = var.instance_type

  # Dynamically find the latest Ubuntu 22.04 LTS AMI[reference:0][reference:1]
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]  # Canonical's official AWS account ID
  }

  ssh_username = "ubuntu"
  ssh_timeout  = "10m"

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
  # PROVISIONER 1: Install prerequisites
  # ------------------------------
  provisioner "shell" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y python3 python3-pip python3-apt software-properties-common",
      # Ansible will be installed by the ansible-local provisioner
    ]
  }

  # ------------------------------
  # PROVISIONER 2: Run Ansible hardening playbook (ansible-local)
  # ------------------------------
  provisioner "ansible-local" {
    playbook_file   = "../ansible/hardening.yml"
    extra_arguments = ["--verbose"]
    # The ansible-local provisioner uploads the playbook and runs it locally on the VM
  }

  # ------------------------------
  # PROVISIONER 3: Install Trivy and scan for CVEs
  # ------------------------------
  provisioner "shell" {
    inline = [
      # Install Trivy
      "sudo apt install -y wget",
      "wget https://github.com/aquasecurity/trivy/releases/download/v0.50.4/trivy_0.50.4_Linux-64bit.deb",
      "sudo dpkg -i trivy_0.50.4_Linux-64bit.deb",
      "rm trivy_0.50.4_Linux-64bit.deb",
      
      # Run filesystem scan on root, exit with error if CRITICAL or HIGH found[reference:2]
      "echo 'Running Trivy filesystem scan...'",
      "sudo trivy fs --severity CRITICAL,HIGH --exit-code 1 / || exit 1",
      "echo 'Trivy scan passed - no CRITICAL or HIGH vulnerabilities found.'"
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