terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.100.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

# The validation instance needs no inbound access: EC2 status checks are
# evaluated through the AWS control plane. Avoid reusing the permissive
# default security group and avoid a hard-coded SSH key pair.
resource "aws_security_group" "validation" {
  name_prefix = "golden-image-validation-"
  description = "No-ingress security group for disposable Golden Image Factory validation"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Allow outbound package/service traffic during boot validation"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "golden-image-validation"
    ManagedBy = "GoldenImageFactory"
  }
}

resource "aws_instance" "test_vm" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.validation.id]
  associate_public_ip_address = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name      = "golden-test-vm"
    Type      = "validation"
    ManagedBy = "GoldenImageFactory"
  }
}

