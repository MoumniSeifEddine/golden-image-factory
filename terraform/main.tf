terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Security group: only allow SSH from the GitHub Actions runner IP
resource "aws_security_group" "test_vm" {
  name_prefix = "golden-test-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # For testing only - your OpenSCAP scan will flag this
    description = "SSH access (temporary for testing)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "golden-test-sg"
  }
}

# Test EC2 instance using the golden AMI
resource "aws_instance" "test_vm" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.test_vm.id]

  # Ensure we can SSH in to run OpenSCAP
  key_name = "your-key-pair-name"  # <-- CHANGE THIS to your key pair name

  tags = {
    Name = "golden-test-vm"
    Type = "validation"
  }
}