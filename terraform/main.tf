terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Golden Image Factory"
      Environment = "validation"
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "golden_image_test" {
  name_prefix = "golden-image-test-"
  description = "No inbound access; used for EC2 instance health validation."
  vpc_id      = data.aws_vpc.default.id

  # No ingress rules are intentionally defined. Instance health is checked
  # through the EC2 control plane, so the test instance needs no public access.
  egress {
    description = "Allow outbound traffic for package/cloud-init operations."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "test_vm" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id == null ? null : var.subnet_id
  vpc_security_group_ids      = [aws_security_group.golden_image_test.id]
  associate_public_ip_address = false
  monitoring                  = true
  ebs_optimized               = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "golden-image-validation"
    Type = "ephemeral-validation"
  }

  lifecycle {
    create_before_destroy = false
  }
}
