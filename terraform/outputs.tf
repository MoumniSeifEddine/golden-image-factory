output "vm_public_ip" {
  description = "Public IP of the test VM"
  value       = aws_instance.test_vm.public_ip
}

output "vm_id" {
  description = "Instance ID of the test VM"
  value       = aws_instance.test_vm.id
}