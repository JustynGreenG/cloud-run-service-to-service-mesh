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


resource "google_cloud_run_v2_service" "random" {
  name                 = "random"
  project              = local.project
  location             = local.region
  ingress              = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  default_uri_disabled = false

  template {

    service_account = google_service_account.service_accounts["random"].email
    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder, will be replaced by build from source
    }
  }

  lifecycle {
    ignore_changes = [template[0].containers[0]]
  }
}

resource "google_cloud_run_v2_service" "caller" {
  name                 = "caller"
  project              = local.project
  location             = local.region
  ingress              = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  default_uri_disabled = false

  template {

    service_account = google_service_account.service_accounts["caller"].email
    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder, will be replaced by build from source
      env {
        name  = "RANDOM_SERVICE_URL"
        value = google_cloud_run_v2_service.random.uri
      }
      env {
        name  = "ISOLATED_SERVICE_URL"
        value = google_cloud_run_v2_service.isolated.uri
      }
    }

    vpc_access {
      egress = "ALL_TRAFFIC"
      network_interfaces {
        network    = google_compute_network.demo.id
        subnetwork = google_compute_subnetwork.demo_subnet.id
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].containers[0]]
  }
}

resource "google_cloud_run_v2_service" "isolated" {
  name                 = "isolated"
  project              = local.project
  location             = local.region
  ingress              = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  default_uri_disabled = false

  template {

    service_account = google_service_account.service_accounts["isolated"].email
    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder, will be replaced by build from source
    }

  }
  lifecycle {
    ignore_changes = [template[0].containers[0]]
  }

}
