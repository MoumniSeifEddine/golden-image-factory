output "instance_id" {
  description = "ID of the temporary validation instance."
  value       = aws_instance.test_vm.id
}

output "private_ip" {
  description = "Private IP assigned to the temporary validation instance."
  value       = aws_instance.test_vm.private_ip
}

output "security_group_id" {
  description = "Security group attached to the temporary validation instance."
  value       = aws_security_group.golden_image_test.id
}
