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

data "google_client_config" "current" {}


locals {
  region  = "us-central1"
  project = data.google_client_config.current.project

  service_accounts = {
    random = {
      display_name = "Random Service Account"
      roles        = ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
    },
    caller = {
      display_name = "Caller Service Account"
      roles        = ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
    },
    isolated = {
      display_name = "Isolated Service Account"
      roles        = ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
    },
    bastion = {
      display_name = "Bastion Host Service Account"
      roles        = ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
    }
  }

  role_bindings = flatten([
    for sa_key, sa in local.service_accounts : [
      for role in sa.roles : {
        sa_key = sa_key
        role   = role
      }
    ]
  ])
}

output "project" {
  value = local.project
}

output "region" {
  value = local.region

}
