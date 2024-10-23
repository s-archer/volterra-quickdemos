# VPC
resource "google_compute_network" "vpc-outside" {
  name                    = "${var.prefix}-vpc-outside"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet-outside" {
  name          = "${var.prefix}-subnet-outside"
  region        = var.gcp_region
  network       = google_compute_network.vpc-outside.name
  ip_cidr_range = var.outside_subnet
}

# VPC
resource "google_compute_network" "vpc-inside" {
  name                    = "${var.prefix}-vpc-inside"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet-inside" {
  name          = "${var.prefix}-subnet-inside"
  region        = var.gcp_region
  network       = google_compute_network.vpc-inside.name
  ip_cidr_range = var.inside_subnet
}