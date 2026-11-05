variable "ami_id" {
  description = "AMI ID produced by the Packer build."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "ami_id must be a valid AWS AMI identifier."
  }
}

variable "instance_type" {
  description = "Small EC2 instance type used for boot validation."
  type        = string
  default     = "t3.small"
}

variable "aws_region" {
  description = "AWS region containing the AMI."
  type        = string
  default     = "us-east-1"
}

variable "subnet_id" {
  description = "Optional subnet ID in the default VPC. Leave null to let AWS select a default subnet."
  type        = string
  default     = null
  nullable    = true
}
