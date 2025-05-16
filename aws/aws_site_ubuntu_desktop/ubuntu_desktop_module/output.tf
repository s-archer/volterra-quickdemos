output "private_ip" {
  description = "ubuntu IP address"
  value       = aws_instance.ubuntu.private_ip
}

output "ubuntu_password" {
  description = "ubuntu instance ID (password)"
  value       = one(data.aws_instances.ubuntu.ids)
}