resource "volterra_known_label_key" "key" {
    key = local.f5xc_sms_name
    namespace = "shared"  
    description = "Used to define lables for Virtual Sites "  
}

resource "volterra_known_label" "label" {
  key = volterra_known_label_key.key.key
  namespace = "shared"
  value       = local.f5xc_sms_name
}

resource "volterra_virtual_site" "ce" {
  name      = local.f5xc_sms_name
  namespace = "shared"

  site_selector {
    expressions = [format("%s = %s", volterra_known_label_key.key.key, volterra_known_label.label.value)]
  }

  site_type = "CUSTOMER_EDGE"
}