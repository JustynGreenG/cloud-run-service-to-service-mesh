# Requirements:

- All Cloud Run services will be deployed from source.
- Each service must run under its own individual service acccount.
- Each Service Account must have the correct roles to write logs and metrics
- The `Caller` service must have permission to call the `Random` service.
- The `Random` and `Isolated` services are not allowed to call any other
  service.
- All Cloud Run services must only allow `internal` ingress
- All Cloud Run service code must be written in NodeJS
- All Google Cloud resources must be deployed and configured using Terraform.

# File Structure

All code files must carry the Apache 2 license header.

All Terraform files must carry the Apache 2 license header.
