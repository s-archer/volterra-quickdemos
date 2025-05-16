# resource "volterra_tgw_vpc_ip_prefixes" "example" {
#   name            = volterra_aws_tgw_site.tgw.name
#   namespace       = "system"

#   vpc_ip_prefixes  {
#     name = aws_vpc.tgw[1].id
#     value = ["10.1.0.0/16"]
#   }

#   vpc_ip_prefixes  {
#     name = aws_vpc.tgw[2].id
#     value = ["10.2.0.0/16"]
#   }
# }

resource "volterra_aws_tgw_site" "tgw" {
  name                    = "${var.prefix}site"
  namespace               = "system"
  direct_connect_disabled = true
  logs_streaming_disabled = true
  labels = {
    "app" = "juice-shop"
  }

  aws_parameters {
    aws_region       = var.region
    vpc_id           = aws_vpc.tgw[0].id

    disk_size        = "80"
    instance_type    = "t3.xlarge"
    aws_certified_hw = "aws-byol-multi-nic-voltmesh"

    # ssh_key          = aws_key_pair.demo.key_name
    ssh_key          = tls_private_key.demo.public_key_openssh
    no_worker_nodes  = true

    aws_cred {
      name      = var.cloud_cred_name
      namespace = "system"
      tenant    = var.volt_tenant
    }

    new_tgw {
      system_generated = true
    }

    az_nodes {
      aws_az_name = local.azs[0]

      outside_subnet {
        existing_subnet_id = aws_subnet.outside[0].id
      }

      inside_subnet {
        existing_subnet_id = aws_subnet.inside[0].id
      }

      workload_subnet {
        existing_subnet_id = aws_subnet.worker[0].id
      }
    }

    az_nodes {
      aws_az_name = local.azs[1]

      outside_subnet {
        existing_subnet_id = aws_subnet.outside[3].id
      }

      inside_subnet {
        existing_subnet_id = aws_subnet.inside[3].id
      }

      workload_subnet {
        existing_subnet_id = aws_subnet.worker[3].id
      }
    }

    az_nodes {
      aws_az_name = local.azs[2]

      outside_subnet {
        existing_subnet_id = aws_subnet.outside[6].id
      }

      inside_subnet {
        existing_subnet_id = aws_subnet.inside[6].id
      }

      workload_subnet {
        existing_subnet_id = aws_subnet.worker[6].id
      }
    }
  }

  vpc_attachments {

    vpc_list {
      vpc_id = aws_vpc.tgw[1].id
    }

    vpc_list {
      vpc_id = aws_vpc.tgw[2].id
    }

    # vpc_list {
    #   vpc_id = "vpc-076c494d0f4677ba8"
    # }

    # vpc_list {
    #   vpc_id = "vpc-021032adf7c9c1837"
    # }
  }
}


resource "volterra_api_credential" "api" {
  name                = format("%stoken", var.prefix)
  api_credential_type = "API_TOKEN"
  created_at          = timestamp()
  lifecycle {
    ignore_changes = [
      created_at
    ]
  }
}


resource "null_resource" "wait-for-site" {
  triggers = {
    depends =  volterra_aws_tgw_site.tgw.id
  }
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      x=1;
      while [ $x -le 60 ]; 
        do VALIDATION_STATE=$(curl -s --location --request GET '${var.volt_api_url}/config/namespaces/system/aws_tgw_sites/${volterra_aws_tgw_site.tgw.name}' --header 'Authorization: APIToken ${volterra_api_credential.api.data}'| jq .spec.validation_state); 
        if ( echo $VALIDATION_STATE | grep "VALIDATION_SUCCEEDED" ); 
          then break; 
        fi; 
        sleep 30; 
        x=$(( $x + 1 )); 
      done
    EOF
  }
}


resource "volterra_tf_params_action" "site" {
  depends_on      = [null_resource.wait-for-site]
  site_name       = volterra_aws_tgw_site.tgw.name
  site_kind       = "aws_tgw_site"
  action          = "apply"
  wait_for_action = true

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      x=1;
      while [ $x -le 60 ]; 
        do STATE=$(curl -s --location --request GET '${var.volt_api_url}/config/namespaces/system/aws_tgw_sites/${volterra_aws_tgw_site.tgw.name}' --header 'Authorization: APIToken ${volterra_api_credential.api.data}'| jq .spec.site_state); 
        if ( echo $STATE | grep "ONLINE" ); 
          then break; 
        fi; 
        sleep 30; 
        x=$(( $x + 1 )); 
      done
    EOF
  }
}