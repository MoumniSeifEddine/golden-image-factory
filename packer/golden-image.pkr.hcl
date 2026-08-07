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

source "amazon-ebs" "golden-image" {
  region        = var.aws_region
  instance_type = var.instance_type

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  ssh_username = "ec2-user"
  ssh_timeout  = "10m"

  ami_name      = "${var.ami_name_prefix}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  ami_description = "Golden AMI (Amazon Linux 2) - WIP"

  tags = {
    Name        = "golden-image"
    Environment = "dev"
    Builder     = "Packer"
    BuildTime   = timestamp()
    OS_Version  = "Amazon Linux 2"
    Hardened    = "true"
  }
}

build {
  sources = ["source.amazon-ebs.golden-image"]

  # Provisioners temporarily disabled for testing.
  # Re‑enable and adapt them for Amazon Linux later.

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}