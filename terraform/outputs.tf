output "vm_id" {
  description = "Instance ID of the disposable validation VM"
  value       = aws_instance.test_vm.id
}

output "vm_private_ip" {
  description = "Private IP of the validation VM (no public IP is assigned)"
  value       = aws_instance.test_vm.private_ip
}
