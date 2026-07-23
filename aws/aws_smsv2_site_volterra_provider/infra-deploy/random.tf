resource "random_id" "id" {
  byte_length = 2
}

resource "random_string" "password" {
  length  = 10
  special = false
}

resource "random_password" "tailscale_subnet_router_ipsec_psk" {
  length  = 32
  special = false
}
