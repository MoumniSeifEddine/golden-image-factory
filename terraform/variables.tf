variable "ami_id" {
  description = "AMI ID of the Golden Image Factory image to validate"
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "ami_id must be a valid AWS AMI identifier (ami-...)."
  }
}

variable "instance_type" {
  description = "Small EC2 instance type used for disposable boot validation"
  type        = string
  default     = "t2.micro"
}

variable "aws_region" {
  description = "AWS region containing the golden AMI"
  type        = string
  default     = "us-east-1"
}
