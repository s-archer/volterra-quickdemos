module "ubuntu" {
  
  depends_on      = [volterra_tf_params_action.site]

  source          = "./ubuntu_desktop_module"
  count           = 1
  subnet          = aws_subnet.volterra_worker.id
  security_groups = [aws_security_group.ubuntu.id]
  key_name        = aws_key_pair.demo.key_name
  prefix          = var.prefix
  volt_ip         = data.aws_network_interface.dns-ip.private_ip
  uk_se           = var.uk_se_name
}