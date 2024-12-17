resource "tls_private_key" "demo" {
  algorithm = "RSA"
}

resource "null_resource" "priv-key" {
  provisioner "local-exec" {
    command = "echo \"${trimspace(tls_private_key.demo.private_key_pem)}\" > ssh-key.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }
}

resource "null_resource" "pub-key" {
  provisioner "local-exec" {
    command = "echo \"${trimspace(tls_private_key.demo.public_key_openssh)}\" > ssh-key.pub"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pub"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pub"
  }
}