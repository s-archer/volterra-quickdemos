# Unhash the following block if you want to manage your own key, but make sure you change the `key` value
# resource "volterra_known_label_key" "key" {
#   key         = "virtual-site-terraform"
#   namespace   = "shared"
#   description = "Used to define lables for Virtual Sites "
# }

resource "volterra_known_label" "label" {
  # Unhash the following block if you want to manage your own key, but make sure you change the `key` value
  # key       = volterra_known_label_key.key.key
  key       = "virtual-site-terraform"
  namespace = "shared"
  value     = local.f5xc_sms_name
}

resource "volterra_virtual_site" "ce" {
  name      = local.f5xc_sms_name
  namespace = "shared"

  site_selector {
    # Unhash the following block if you want to manage your own key, but make sure you change the `key` value
    # expressions = [format("%s = %s", volterra_known_label_key.key.key, volterra_known_label.label.value)]
    expressions = [format("%s = %s", "virtual-site-terraform", volterra_known_label.label.value)]
  }

  site_type = "CUSTOMER_EDGE"
}