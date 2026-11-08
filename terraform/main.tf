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

# Use the DEFAULT VPC that AWS Academy automatically created (No creation)
data "aws_vpc" "default" {
  default = true
}

# Use the DEFAULT security group that already exists (NO creation required!)
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

# Test EC2 instance using the golden AMI
resource "aws_instance" "test_vm" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.default.id]
  key_name               = "vockey"

  tags = {
    Name = "golden-test-vm"
    Type = "validation"
  }
}