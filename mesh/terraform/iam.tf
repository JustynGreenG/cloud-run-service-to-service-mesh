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
resource "google_service_account" "service_accounts" {
  project = local.project

  for_each     = local.service_accounts
  account_id   = "${each.key}-sa"
  display_name = each.value.display_name
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_iam_member" "service_account_roles" {
  for_each = { for i, binding in local.role_bindings : "${binding.sa_key}-${replace(binding.role, "roles/", "")}" => binding }
  project  = local.project
  role     = each.value.role
  member   = "serviceAccount:${google_service_account.service_accounts[each.value.sa_key].email}"
}



resource "google_cloud_run_v2_service_iam_member" "invoker" {
  project  = local.project
  location = google_cloud_run_v2_service.mesh_random.location
  name     = google_cloud_run_v2_service.mesh_random.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.service_accounts["mesh-caller"].email}"
}
