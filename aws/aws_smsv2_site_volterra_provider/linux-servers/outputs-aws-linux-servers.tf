output "linux-ami" {
  value = "AMI ID: ${data.aws_ami.ubuntu.id}"
}

output "linux-username" {
  value = "admin"
}

output "linux-password" {
  value = random_string.password.result
}

output "linux-ui" {
  value = [for eip in aws_eip.mgmt : "https://${eip.public_ip}"]
}

output "linux-ssh" {
  value = [for eip in aws_eip.mgmt : "ssh ubuntu@${eip.public_ip} -i ssh-key.pem"]
}

output "linux-internal_self" {
  value = aws_network_interface.internal[*].private_ip
}

output "linux-mgmt_private" {
  value = aws_network_interface.mgmt[*].private_ip
}
