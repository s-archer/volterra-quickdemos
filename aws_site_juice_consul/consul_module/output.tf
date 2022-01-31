output "private_ip" {
  description = "consul IP address"
  value       = aws_instance.consul.private_ip
}