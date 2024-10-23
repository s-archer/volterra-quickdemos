resource "volterra_discovery" "k8s" {
  name      = "${var.prefix}"
  namespace = "system"
  depends_on = [

  ]

  discovery_k8s {
    access_info {
      // One of the arguments from this list "kubeconfig_url connection_info in_cluster" must be set
      kubeconfig_url {
        clear_secret_info {
          url = format("string:///%s", base64encode(module.gke_auth.kubeconfig_raw))
        }
      }

      // One of the arguments from this list "isolated reachable" must be set
      reachable = true
    }

    publish_info {
      // One of the arguments from this list "disable publish publish_fqdns dns_delegation" must be set
      #disable = true
      publish {
        namespace = var.gke_k8s_namespace
      }
    }
  }
  where {
    site {
      network_type = "VIRTUAL_NETWORK_SITE_LOCAL_INSIDE"
      ref {
        name      = volterra_gcp_vpc_site.site.name
        namespace = volterra_gcp_vpc_site.site.namespace
        # tenant    = var.volt_tenant
      }
    }
  }
}

data "google_client_config" "current" {}

data "google_container_cluster" "cluster" {
  name     = google_container_cluster.primary.name
  location = var.gcp_region
}

module "gke_auth" {
  source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  project_id           = var.project_id
  cluster_name         = google_container_cluster.primary.name
  location             = var.gcp_region
  # use_private_endpoint = true
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "${path.module}/kubeconfig.yaml"
}

# output "kubeconfig" {
#   value = templatefile("${path.module}/templates/kubeconfig.tpl", {
#     endpoint               = data.google_container_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)
#     token                  = data.google_container_cluster.cluster.master_auth.0.access_token
#   })
# }