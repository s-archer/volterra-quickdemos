output "ssh-access" {
  value = (
    length(aws_eip.f5xc-outside) == 0
    ? ["n/a"]
    : [for count in range(length(aws_eip.f5xc-outside)) : "ssh admin@${aws_eip.f5xc-outside[count].public_ip} -i ./ssh-key.pem"]
  )
}
