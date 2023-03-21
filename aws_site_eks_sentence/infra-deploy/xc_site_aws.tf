resource "volterra_aws_vpc_site" "site" {
  name       = var.site_name
  namespace  = "system"
  aws_region = var.region

  assisted      = false
  instance_type = "t3.xlarge"

  //AWS credentials entered in the Volterra Console
  aws_cred {
    name      = var.cloud_cred_name
    namespace = "system"
    # tenant    = var.volt_tenant
  }

  vpc {
    vpc_id = aws_vpc.volt.id
  }

  ingress_egress_gw {
    aws_certified_hw = "aws-byol-multi-nic-voltmesh"
    # no_forward_proxy         = false
    no_forward_proxy = true
    # forward_proxy_allow_all  = true
    no_global_network = true
    inside_static_routes {
      static_route_list {
        simple_static_route = "10.0.0.0/16"
      }
    }
    no_outside_static_routes = true
    no_network_policy        = true


    //Availability zones and subnet options for the Volterra Node.
    az_nodes {
      //AWS AZ
      aws_az_name = format("%sa", var.region)

      //Site local outside subnet
      outside_subnet {
        existing_subnet_id = aws_subnet.eks_outside.id
      }

      //Site local inside subnet
      inside_subnet {
        existing_subnet_id = aws_subnet.eks_inside.id
      }

      //Workload subnet
      workload_subnet {
        existing_subnet_id = aws_subnet.eks_worker.id
      }
    }
    # az_nodes {
    #   //AWS AZ
    #   aws_az_name = format("%sb", var.region)

    #   //Site local outside subnet
    #   outside_subnet {
    #     existing_subnet_id = aws_subnet.eks_outside_1.id
    #   }

    #   //Site local inside subnet
    #   inside_subnet {
    #     existing_subnet_id = aws_subnet.eks_inside_1.id
    #   }

    #   //Workload subnet
    #   workload_subnet {
    #     existing_subnet_id = aws_subnet.eks_worker_1.id
    #   }
    # }
    # az_nodes {
    #   //AWS AZ
    #   aws_az_name = format("%sc", var.region)

    #   //Site local outside subnet
    #   outside_subnet {
    #     existing_subnet_id = aws_subnet.eks_outside_2.id
    #   }

    #   //Site local inside subnet
    #   inside_subnet {
    #     existing_subnet_id = aws_subnet.eks_inside_2.id
    #   }

    #   //Workload subnet
    #   workload_subnet {
    #     existing_subnet_id = aws_subnet.eks_worker_2.id
    #   }
    # }
  }

  //Mandatory
  logs_streaming_disabled = true

  //Mandatory
  no_worker_nodes = true
}

resource "null_resource" "wait-for-site" {
  triggers = {
    depends = volterra_aws_vpc_site.site.id
  }
}

resource "volterra_api_credential" "api" {
  name                = format("%s-%s-api-token", var.uk_se_name, var.base)
  api_credential_type = "API_TOKEN"

  # provisioner "local-exec" {
  #   when    = destroy
  #   command = <<-EOF
  #     #!/bin/bash
  #     NAME=$(curl --location --request GET 'https://f5-emea-ent.console.ves.volterra.io/api/web/namespaces/system/api_credentials' \
  #       --header 'Authorization: APIToken ${self.data}'| jq 'first(.items[] | select (.name | contains("${self.name}")) | .name)') 
  #     curl --location --request POST 'https://f5-emea-ent.console.ves.volterra.io/api/web/namespaces/system/revoke/api_credentials' \
  #       --header 'Authorization: APIToken ${self.data}' \
  #       --header 'Content-Type: application/json' \
  #       -d "$(jq -n --arg n "$NAME" '{"name": $n, "namespace": "system" }')"
  #   EOF
  # }
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      #!/bin/bash
      NAME=$(curl --location --request GET 'https://f5-spda-emea.console.ves.volterra.io/api/web/namespaces/system/api_credentials' \
        --header 'Authorization: APIToken ${self.data}'| jq 'first(.items[] | select (.name | contains("${self.name}")) | .name)') 
      curl --location --request POST 'https://f5-spda-emea.console.ves.volterra.io/api/web/namespaces/system/revoke/api_credentials' \
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