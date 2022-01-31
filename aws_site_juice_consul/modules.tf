
module "consul" {
  depends_on      = [volterra_tf_params_action.site]
  source          = "./consul_module"
  count           = 1
  subnet          = aws_subnet.volterra_worker.id
  security_groups = [aws_security_group.consul.id]
  key_name        = aws_key_pair.demo.key_name
  prefix          = var.prefix
  uk_se           = var.uk_se_name
}

module "nginx" {
  depends_on       = [volterra_tf_params_action.site]
  source           = "./nginx_module"
  count            = 1
  desired_capacity = 2
  subnets          = [aws_subnet.volterra_worker.id]
  security_groups  = [aws_security_group.nginx.id]
  key_name         = aws_key_pair.demo.key_name
  prefix           = var.prefix
  uk_se            = var.uk_se_name
}