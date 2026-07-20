variable "ami_id" {
  description = "AMI ID of the golden image to test"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}