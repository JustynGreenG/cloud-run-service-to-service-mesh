/*
 Copyright 2026 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

resource "google_network_services_mesh" "mesh" {
  provider   = google-beta
  project    = local.project
  name       = "demo-mesh"
  depends_on = [google_project_service.required_apis]
}

resource "time_sleep" "wait_for_mesh" {
  depends_on = [
    google_network_services_mesh.mesh,
  google_dns_record_set.mesh_wildcard_a_record, ]

  create_duration = "1m"
}

resource "google_dns_managed_zone" "mesh_dns_zone" {
  provider    = google-beta
  name        = "demo-mesh"
  dns_name    = "internal."
  description = "Private DNS zone for Cloud Service Mesh internal routes"
  visibility  = "private"

  # Link the zone to the VPC defined in your networking configuration
  private_visibility_config {
    networks {
      network_url = data.google_compute_network.demo.id
    }
  }

  # Ensure the required APIs are enabled before creating the zone
  depends_on = [google_project_service.required_apis]

}

/**
 * Wildcard A record for the mesh domain.
 * This ensures that any subdomain under receiver.internal resolves to the
 * specified IP, typically used for internal load balancing or mesh routing entry points.
 */
resource "google_dns_record_set" "mesh_wildcard_a_record" {
  name         = "*.${google_dns_managed_zone.mesh_dns_zone.dns_name}"
  managed_zone = google_dns_managed_zone.mesh_dns_zone.name
  type         = "A"
  ttl          = 3600

  # The IP address for the record.
  # Note: Ensure this IP corresponds to your internal routing gateway or ILB.
  rrdatas = ["10.0.0.1"]
}



resource "google_compute_region_network_endpoint_group" "mesh_random_neg" {
  project               = local.project
  name                  = "mesh-random-neg"
  network_endpoint_type = "SERVERLESS"
  region                = local.region
  cloud_run {
    service = google_cloud_run_v2_service.mesh_random.name
  }
}

resource "google_compute_backend_service" "mesh_backend" {
  project               = local.project
  name                  = "mesh-random-us-central1"
  load_balancing_scheme = "INTERNAL_SELF_MANAGED"
  protocol              = "HTTP"

  backend {
    group = google_compute_region_network_endpoint_group.mesh_random_neg.id
  }
}
