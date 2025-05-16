data "aws_key_pair" "existing_aws_key" {
  count              = var.aws_existing_key_pair_id != null ? 1 : 0
  key_pair_id        = var.aws_existing_key_pair_id
  include_public_key = true
}

data "aws_iam_instance_profile" "existing_iam_profile" {
  count = var.aws_existing_iam_profile_name != null ? 1 : 0
  name  = var.aws_existing_iam_profile_name
}

data "aws_iam_role" "existing_iam_role" {
  count = var.aws_existing_iam_profile_name != null ? 1 : 0
  name  = data.aws_iam_instance_profile.existing_iam_profile.0.role_name
}

check "ami" {
  data "aws_ami_ids" "f5xc_check" {
    owners = var.aws_ami_owner_ids

    filter {
      name = "name"
      values = [var.aws_ami_name]
    }
  }

  assert {
    condition     = length(data.aws_ami_ids.f5xc.ids) > 0
    error_message = "${var.aws_ami_name} not found in region ${var.aws_region}."
  }
}

data "aws_ami_ids" "f5xc" {
  owners = var.aws_ami_owner_ids

  filter {
    name = "name"
    values = [var.aws_ami_name]
  }
}