resource "volterra_discovery" "k8s" {
  count     = var.f5xc_sms_node_count
  name      = "${var.prefix}sentence-${count.index}"
  namespace = "system"
  depends_on = [

  ]

  discovery_k8s {
    access_info {
      // One of the arguments from this list "kubeconfig_url connection_info in_cluster" must be set
      kubeconfig_url {
        clear_secret_info {
          url = format("string:///%s", base64encode(templatefile("${path.module}/templates/kubeconfig.tpl", {
            cluster_name = aws_eks_cluster.eks.arn
            ca_crt       = base64encode("${data.kubernetes_secret_v1.f5xc-secret.data["ca.crt"]}")
            server       = aws_eks_cluster.eks.endpoint
            sa_name      = var.sa_name
            token        = data.kubernetes_secret_v1.f5xc-secret.data.token
          })))
        }
      }

      // One of the arguments from this list "isolated reachable" must be set
      reachable = true
    }

    publish_info {
      // One of the arguments from this list "disable publish publish_fqdns dns_delegation" must be set
      #disable = true
      publish {
        namespace = var.eks_k8s_namespace
      }
    }
  }
  where {
    site {
      network_type = "VIRTUAL_NETWORK_SITE_LOCAL_INSIDE"
      ref {
        name      = volterra_securemesh_site_v2.site[count.index].name
        namespace = volterra_securemesh_site_v2.site[count.index].namespace
        # tenant    = var.f5xc_tenant
      }
    }
  }
}


#  The next several resources and data sources create the kubeconfig file with Service Account credentials.
#  The workflow is based on Michael O'Leary's excellent article https://community.f5.com/t5/technical-articles/using-a-kubernetes-serviceaccount-for-service-discovery-with-f5/ta-p/300225
#  The role is read only, so if you want XC to create LB (k8s svc) in k8s, then you need write permissions.

resource "kubernetes_service_account_v1" "f5xc" {
  depends_on = [
    aws_eks_node_group.eks-nodes
  ]
  metadata {
    name      = "f5xc"
    namespace = "kube-system"
  }
  automount_service_account_token = false
}

resource "kubernetes_secret_v1" "f5xc-secret" {
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = tolist(kubernetes_service_account_v1.f5xc.metadata)[0].name
    }
    name      = "f5xc-secret"
    namespace = "kube-system"
  }
  type = "kubernetes.io/service-account-token"
}

data "kubernetes_secret_v1" "f5xc-secret" {
  metadata {
    name      = tolist(kubernetes_secret_v1.f5xc-secret.metadata)[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_v1" "f5xc-service-discovery" {
  depends_on = [
    aws_eks_node_group.eks-nodes
  ]
  metadata {
    name = "f5xc-service-discovery"
  }

  # rule {
  #   api_groups = [""]
  #   resources  = ["endpoints", "namespaces", "nodes", "nodes/proxy", "pods", "services", "secrets", "serviceaccounts", "configmaps", "clusterroles"]
  #   verbs      = ["get", "list", "watch"]
  # }
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "f5xc-service-discovery" {
  metadata {
    name = "f5xc-service-discovery"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = tolist(kubernetes_cluster_role_v1.f5xc-service-discovery.metadata)[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = tolist(kubernetes_service_account_v1.f5xc.metadata)[0].name
    namespace = "kube-system"
  }
}

resource "local_file" "rendered_kubeconfig" {
  content = templatefile("${path.module}/templates/kubeconfig.tpl", {
    cluster_name = aws_eks_cluster.eks.arn
    ca_crt       = base64encode("${data.kubernetes_secret_v1.f5xc-secret.data["ca.crt"]}")
    server       = aws_eks_cluster.eks.endpoint
    sa_name      = var.sa_name
    token        = data.kubernetes_secret_v1.f5xc-secret.data.token
  })
  filename = "${path.module}/kubeconfig.yaml"
}