# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
resource "google_network_services_http_route" "mesh_route" {
  provider = google-beta
  name     = "mesh-random-route"
  meshes   = [google_network_services_mesh.mesh.id]

  hostnames = ["mesh-random.internal"]

  rules {
    action {
      destinations {
        service_name = google_compute_backend_service.mesh_backend.id
        weight       = 100
      }
    }
  }
}
