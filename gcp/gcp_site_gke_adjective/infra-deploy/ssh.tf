resource "tls_private_key" "demo" {
  algorithm = "RSA"
}

resource "null_resource" "key" {
  provisioner "local-exec" {
    # command = "echo \"${tls_private_key.demo.private_key_pem}\" > ${aws_key_pair.demo.key_name}.pem"
    command = "echo \"${tls_private_key.demo.private_key_pem}\" > ssh-key.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}
