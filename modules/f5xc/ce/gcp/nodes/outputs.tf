output "ce" {
  value = {
    for k, v in data.google_compute_instance.instances : v.name => v if data.google_compute_instance.instances[k].name != null
  }
}

output "instance_group_url" {
  description = "URL of instance group manager for use in creating google_compute_region_backend_service"
  value       = google_compute_region_instance_group_manager.instance_group_manager.instance_group
}