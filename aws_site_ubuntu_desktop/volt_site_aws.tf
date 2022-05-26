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
    tenant    = var.volt_tenant
  }

  vpc {
    vpc_id = aws_vpc.volt.id
  }

  ingress_egress_gw {
    aws_certified_hw         = "aws-byol-multi-nic-voltmesh"
    no_forward_proxy         = false
    forward_proxy_allow_all  = true
    no_global_network        = true
    no_inside_static_routes  = true
    no_outside_static_routes = true
    no_network_policy        = true


    //Availability zones and subnet options for the Volterra Node
    az_nodes {
      //AWS AZ
      aws_az_name = format("%sa", var.region)

      //Site local outside subnet
      outside_subnet {
        existing_subnet_id = aws_subnet.volterra_outside.id
      }

      //Site local inside subnet
      inside_subnet {
        existing_subnet_id = aws_subnet.volterra_inside.id
      }

      //Workload subnet
      workload_subnet {
        existing_subnet_id = aws_subnet.volterra_worker.id
      }
    }
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

resource "volterra_tf_params_action" "site" {
  depends_on      = [null_resource.wait-for-site]
  site_name       = var.site_name
  site_kind       = "aws_vpc_site"
  action          = "apply"
  wait_for_action = true
}


data "aws_instances" "volt" {
  depends_on = [
    volterra_tf_params_action.site
  ]

  instance_tags = {
    Name = "master-0"
  }

  filter {
    name   = "subnet-id"
    values = [aws_subnet.volterra_outside.id]
  }
}

data "aws_network_interface" "dns-ip" {
  filter {
    name = "tag:ves-io-site-name" 
    values = ["arch-aws-ubuntu-site"]
  }
  filter {  
    name = "tag:ves.io/interface-type"
    values = ["site-local-inside"]
  }
}
