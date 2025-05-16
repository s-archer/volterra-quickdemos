# GKE cluster
data "google_container_engine_versions" "gke_version" {
  location       = var.gcp_region
  version_prefix = "1.28."
}

resource "google_container_cluster" "primary" {
  name                = "${var.prefix}-gke"
  location            = var.gcp_region
  deletion_protection = false

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc-inside.name
  subnetwork = google_compute_subnetwork.subnet-inside.name

  # private_cluster_config {
  #   enable_private_endpoint = true
  #   enable_private_nodes    = true
  #   master_ipv4_cidr_block  = "10.0.3.0/28"
  # }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.master_authorized_networks_cidr
    }
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name     = google_container_cluster.primary.name
  location = var.gcp_region
  cluster  = google_container_cluster.primary.name

  version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = "n1-standard-8"
    tags         = ["gke-node", "${var.prefix}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}