resource "kubernetes_service_account_v1" "f5xc-xxx" {
  metadata {
    name      = "f5xc-xxx"
    namespace = "kube-system"
  }
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

resource "kubernetes_role_binding_v1" "f5xc-service-discovery-xxx" {
  metadata {
    name      = "f5xc-service-discovery-xxx"
    namespace = "kube-system"
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