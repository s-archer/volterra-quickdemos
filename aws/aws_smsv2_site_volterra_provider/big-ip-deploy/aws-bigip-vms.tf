data "aws_ami" "f5_ami" {
  most_recent = true
  # This is the F5 Networks 'owner ID', which ensures we get an image maintained by F5.
  owners = ["679593333241"]

  filter {
    name   = "name"
    values = [var.f5_ami_search_name]
  }
}

resource "random_string" "password" {
  length  = 10
  special = false
}

resource "aws_network_interface" "mgmt" {
  subnet_id       = data.terraform_remote_state.eks.outputs.subnet_id_bip_mgmt
  private_ips     = ["10.0.16.10"]
  security_groups = [aws_security_group.mgmt.id]
}

resource "aws_network_interface" "external" {
  subnet_id = data.terraform_remote_state.eks.outputs.subnet_id_bip_outside
  #private_ips     = ["10.0.17.10", "10.0.17.101", "10.0.17.102"]
  private_ips_count = 2
  security_groups   = [aws_security_group.external.id]
}

resource "aws_network_interface" "internal" {
  subnet_id = data.terraform_remote_state.eks.outputs.subnet_id_bip_inside
  # private_ips     = ["10.0.18.10"]
  private_ips_count = 1
  security_groups   = [aws_security_group.internal.id]
}

resource "aws_eip" "mgmt" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.mgmt.id
  associate_with_private_ip = "10.0.16.10"
}

resource "aws_eip" "external-self" {
  domain            = "vpc"
  network_interface = aws_network_interface.external.id
  #associate_with_private_ip = "10.0.17.10"
  associate_with_private_ip = element(tolist(aws_network_interface.external.private_ips), 0)
}

resource "aws_eip" "external-vs1" {
  domain            = "vpc"
  network_interface = aws_network_interface.external.id
  #associate_with_private_ip = "10.0.17.101"
  associate_with_private_ip = element(tolist(aws_network_interface.external.private_ips), 1)
}

resource "aws_eip" "external-vs2" {
  domain            = "vpc"
  network_interface = aws_network_interface.external.id
  #associate_with_private_ip = "10.0.17.102"
  associate_with_private_ip = element(tolist(aws_network_interface.external.private_ips), 2)
}

resource "aws_instance" "f5" {

  ami = data.aws_ami.f5_ami.id
  user_data = templatefile("./templates/user_data_json.tpl", {
    region      = var.region
    hostname    = "mybigip.f5.com",
    admin_pass  = random_string.password.result,
    external_ip = "${aws_eip.external-self.private_ip}/24",
    internal_ip = "${aws_network_interface.internal.private_ip}/24",
    internal_gw = data.terraform_remote_state.eks.outputs.internal_gw,
    vs1_ip      = aws_eip.external-vs1.private_ip,
    app_tag     = "${var.prefix}nginx-autoscale"
  })
  iam_instance_profile = aws_iam_instance_profile.as3.name
  instance_type        = var.instance_type
  key_name             = aws_key_pair.demo.key_name
  root_block_device { delete_on_termination = true }

  network_interface {
    network_interface_id = aws_network_interface.mgmt.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.external.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.internal.id
    device_index         = 2
  }

  # Checks that AS3 API Endpoint is available
  # provisioner "local-exec" {
  #   command = "while [[ \"$(curl -skiu admin:${random_string.password.result} https://${self.public_ip}/mgmt/shared/appsvcs/declare | grep -Eoh \"^HTTP/1.1 20\")\" != \"HTTP/1.1 20\" ]]; do sleep 5; done"
  # }

  # Checks that AS3 App is available
  provisioner "local-exec" {
    command = "while [[ \"$(curl -ski http://${aws_eip.external-vs1.public_ip} | grep -Eoh \"^HTTP/1.1 200\")\" != \"HTTP/1.1 200\" ]]; do sleep 5; done"
  }

  tags = {
    Name  = "${var.prefix}f5"
    Env   = "aws"
    UK-SE = var.uk_se_name
  }
}

# For testing, writes out to file.
#
resource "local_file" "test_user_debug" {
  content = templatefile("./templates/user_data_json.tpl", {
    region      = var.region,
    hostname    = var.hostname-f5,
    admin_pass  = random_string.password.result,
    external_ip = "${aws_network_interface.external.private_ip}/24",
    internal_ip = "${aws_network_interface.internal.private_ip}/24",
    internal_gw = data.terraform_remote_state.eks.outputs.internal_gw,
    vs1_ip      = aws_eip.external-vs1.private_ip,
    app_tag     = "${var.prefix}nginx-autoscale"
  })
  filename = "${path.module}/user_data_debug.json"
}


# resource "local_file" "output_creds_for_ansible" {
#   content  = yamlencode({ bigip_user : "admin", bigip_pass : "${random_string.password.result}" })
#   filename = "../../creds/terraform_output_creds.yaml"
# }


# resource "volterra_discovery" "cbip" {
#   name      = "${var.prefix}cbip"
#   namespace = var.f5xc_namespace

#   discovery_cbip {
#     cbip_clusters {
#        metadata {
#         name = "${var.prefix}cbip-aws"
#       }
#       cbip_devices {
#         cbip_mgmt_ip = aws_network_interface.mgmt.private_ip

#         cbip_certificate_authority {
#           skip_server_verification = true
#         }
#         admin_credentials {
#           username = "admin"
#           password {
#             clear_secret_info {
#               url = "string:///${base64encode(random_string.password.result)}"
#             }
#           }
#         }
#       }
#     }
#   }
#   where {
#     # site {
#     #   network_type = "VIRTUAL_NETWORK_SITE_LOCAL_INSIDE"
#     #   ref {
#     #     name      = volterra_securemesh_site_v2.site[count.index].name
#     #     namespace = volterra_securemesh_site_v2.site[count.index].namespace
#     #     # tenant    = var.f5xc_tenant
#     #   }
#     # }
#     virtual_site {
#       ref {
#         name      = data.terraform_remote_state.eks.outputs.virtual-site-name
#         namespace = "system"
#         # tenant    = var.f5xc_tenant
#       }
#     }
#   }
# }