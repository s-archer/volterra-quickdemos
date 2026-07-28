data "terraform_remote_state" "aws" {
  count   = var.enable_aws_remote_state ? 1 : 0
  backend = "local"

  config = {
    path = var.aws_remote_state_path
  }
}

data "terraform_remote_state" "azure" {
  count   = var.enable_azure_remote_state ? 1 : 0
  backend = "local"

  config = {
    path = var.azure_remote_state_path
  }
}
