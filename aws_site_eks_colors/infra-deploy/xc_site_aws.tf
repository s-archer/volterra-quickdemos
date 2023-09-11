resource "volterra_aws_vpc_site" "site" {
  name       = var.site_name
  namespace  = "system"
  aws_region = var.region

  instance_type = "t3.xlarge"

  logs_streaming_disabled = true
  no_worker_nodes         = true

  //AWS credentials entered in the Volterra Console
  aws_cred {
    name      = var.cloud_cred_name
    namespace = "system"
  }

  vpc {
    vpc_id = aws_vpc.volt.id
  }

  ingress_egress_gw {
    aws_certified_hw         = "aws-byol-multi-nic-voltmesh"
    no_forward_proxy         = true
    no_global_network        = true
    no_network_policy        = true
    no_outside_static_routes = true
    inside_static_routes {
      static_route_list {
        simple_static_route = "10.0.0.0/16"
      }
    }

    az_nodes {

      aws_az_name = format("%sa", var.region)

      outside_subnet {
        existing_subnet_id = aws_subnet.eks_outside.id
      }

      inside_subnet {
        existing_subnet_id = aws_subnet.eks_inside.id
      }

      workload_subnet {
        existing_subnet_id = aws_subnet.eks_worker.id
      }
    }
  }
}

resource "null_resource" "wait-for-site" {
  triggers = {
    depends = volterra_aws_vpc_site.site.id
  }
}

resource "volterra_api_credential" "api" {
  depends_on          = [null_resource.wait-for-site]
  name                = format("%s-%s-token-%s", var.uk_se_name, var.base, random_id.id.hex)
  api_credential_type = "API_TOKEN"
  expiry_days         = 90

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      #!/bin/bash
      NAME=$(curl --location --request GET 'https://f5-emea-ent.console.ves.volterra.io/api/web/namespaces/system/api_credentials' \
        --header 'Authorization: APIToken ${self.data}'| jq 'first(.items[] | select (.name | contains("${self.name}")) | .name)') 
      curl --location --request POST 'https://f5-emea-ent.console.ves.volterra.io/api/web/namespaces/system/revoke/api_credentials' \
        --header 'Authorization: APIToken ${self.data}' \
        --header 'Content-Type: application/json' \
        -d "$(jq -n --arg n "$NAME" '{"name": $n, "namespace": "system" }')"
    EOF
  }
}

resource "volterra_tf_params_action" "site" {
  depends_on      = [null_resource.wait-for-site]
  site_name       = var.site_name
  site_kind       = "aws_vpc_site"
  action          = "apply"
  wait_for_action = true

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      x=1;
      while [ $x -le 60 ]; 
        do STATE=$(curl -s --location --request GET '${var.volt_api_url}/config/namespaces/system/aws_vpc_sites/${var.site_name}' --header 'Authorization: APIToken ${volterra_api_credential.api.data}'| jq .spec.site_state); 
        if ( echo $STATE | grep "ONLINE" ); 
          then break; 
        fi; 
        sleep 30; 
        x=$(( $x + 1 )); 
      done
    EOF
  }
}
