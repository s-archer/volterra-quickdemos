#  The next several resources and data sources create the kubeconfig file with Service Account credentials.
#  The workflow is based on Michael O'Leary's excellent article https://community.f5.com/t5/technical-articles/using-a-kubernetes-serviceaccount-for-service-discovery-with-f5/ta-p/300225


resource "kubernetes_service_account_v1" "f5xc-xxx" {
  metadata {
    name      = "f5xc-xxx"
    namespace = "kube-system"
  }
  automount_service_account_token =  false
}

resource "kubernetes_secret_v1" "f5xc-secret-xxx" {
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = "f5xc-xxx"
    }
    name      = "f5xc-secret-xxx"
    namespace = "kube-system"
  }
  type = "kubernetes.io/service-account-token"
}

data "kubernetes_secret_v1" "f5xc-secret-xxx" {
  depends_on = [
    aws_eks_node_group.arch-eks-nodes
  ]
  metadata {
    name      = "f5xc-secret-xxx"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_v1" "f5xc-service-discovery-xxx" {
  metadata {
    name = "f5xc-service-discovery-xxx"
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints", "namespaces", "nodes", "nodes/proxy", "pods", "services"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "f5xc-service-discovery-xxx" {
  metadata {
    name      = "f5xc-service-discovery-xxx"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "f5xc-service-discovery-xxx"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "f5xc-xxx"
    namespace = "kube-system"
  }
}

resource "local_file" "rendered_kubeconfig" {
  content = templatefile("${path.module}/k8s-templates/kubeconfig.tpl", {
    cluster_name = aws_eks_cluster.arch-eks.arn
    ca_crt       = base64encode("${data.kubernetes_secret_v1.f5xc-secret-xxx.data["ca.crt"]}")
    server       = aws_eks_cluster.arch-eks.endpoint
    sa_name      = var.sa_name
    token        = data.kubernetes_secret_v1.f5xc-secret-xxx.data.token
  })
  filename = "${path.module}/rendered_kubeconfig.yaml"
}

resource "volterra_discovery" "k8s" {
  # name      = "${var.prefix}k8s"
  name       = "aws-sentence"
  namespace = "system"

  discovery_k8s {
    access_info {
      // One of the arguments from this list "kubeconfig_url connection_info in_cluster" must be set
      kubeconfig_url {
        clear_secret_info {
          url = format("string:///%s", base64encode(templatefile("${path.module}/k8s-templates/kubeconfig.tpl", {
            cluster_name = aws_eks_cluster.arch-eks.arn
            ca_crt       = base64encode("${data.kubernetes_secret_v1.f5xc-secret-xxx.data["ca.crt"]}")
            server       = aws_eks_cluster.arch-eks.endpoint
            sa_name      = var.sa_name
            token        = data.kubernetes_secret_v1.f5xc-secret-xxx.data.token
          })))
        }
      }

      // One of the arguments from this list "isolated reachable" must be set
      reachable = true
    }

    publish_info {
      // One of the arguments from this list "disable publish publish_fqdns dns_delegation" must be set
      disable = true
    }
  }
  where {
    site {
      network_type = "VIRTUAL_NETWORK_SITE_LOCAL_INSIDE"
      ref {
        name      = volterra_aws_vpc_site.site.name
        namespace = volterra_aws_vpc_site.site.namespace
        # tenant    = var.volt_tenant
      }
    }
  }
}