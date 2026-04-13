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

resource "google_cloud_run_v2_service" "mesh_random" {
  provider             = google-beta
  launch_stage         = "BETA"
  name                 = "mesh-random"
  project              = local.project
  location             = local.region
  ingress              = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  default_uri_disabled = false
  deletion_protection  = false

  depends_on = [
    time_sleep.wait_for_mesh,
    google_project_iam_member.service_account_roles,
  ]

  template {

    service_account = google_service_account.service_accounts["mesh-random"].email
    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder, will be replaced by build from source
    }
    service_mesh {
      mesh = google_network_services_mesh.mesh.id
    }
    vpc_access {
      egress = "ALL_TRAFFIC"
      network_interfaces {
        network    = data.google_compute_network.demo.id
        subnetwork = data.google_compute_subnetwork.demo_subnet.id
      }
    }
  }
  lifecycle {
    ignore_changes = [template[0].containers[0]]
  }
}

resource "google_cloud_run_v2_service" "mesh_caller" {
  provider     = google-beta
  launch_stage = "BETA"
  name         = "mesh-caller"
  project      = local.project
  location     = local.region
  ingress      = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  depends_on = [
    time_sleep.wait_for_mesh,
    google_project_iam_member.service_account_roles,
    google_cloud_run_v2_service.mesh_random,
  ]
  deletion_protection = false

  template {

    service_account = google_service_account.service_accounts["mesh-caller"].email
    service_mesh {
      mesh = google_network_services_mesh.mesh.id
    }
    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder, will be replaced by build from source
      env {
        name  = "RANDOM_SERVICE_URL"
        value = google_network_services_http_route.mesh_route.hostnames[0]
      }

    }
    vpc_access {
      egress = "ALL_TRAFFIC"
      network_interfaces {
        network    = data.google_compute_network.demo.id
        subnetwork = data.google_compute_subnetwork.demo_subnet.id
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].containers[0]]
  }
}
