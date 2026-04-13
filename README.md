# Service to Service demo

This codebase is for demonstration purposes only. It is not intended for use in
production.

Note: You can also try out Cloud Service Mesh with Cloud Run by following
[Configure Cloud Service Mesh for Cloud Run](https://docs.cloud.google.com/service-mesh/docs/configure-cloud-service-mesh-for-cloud-run).

This demo consists of three Cloud Run-based services:

1. `Random`: A random-number generator service that responds to calls against
   the `/random` path and returns a random number between 1 and 100 in plain
   text.
2. `Caller`: A service that calls `Random` to get a random number and then
   displays the text "Your luck number is $number"
3. `Isolated`: A service that only returns the text `fail` - the idea is that
   this service is not allowed to be called by any other service so if you can
   access it that's a fail state.

A further set of services are deployed as part of the service mesh demo -
`mesh-random` and `mesh-caller` (the mesh equivalent of `random` and `caller`).

## Prerequisites

- A Google Cloud project
- The latest version of the `gcloud` command-line tool
- The `terraform` command-line tool

Cloud Shell in the Google Cloud Console has both `gcloud` and `terraform`
pre-installed.

## Troubleshooting

You may find that various aspects of this demo are not working as expected.
Consider the following items as you troubleshoot:

- Established organisation policies may prevent you from deploying resources to
  your project.
- Your account may not have the correct permissions to deploy or access
  resources to your project.
- The Cloud Run services may not be able to communicate with each other due to
  configuration such as VPC Service Controls.
- Sometimes it's just a timing issue and you should re-run `terraform apply` a
  few times to make sure everything gets rolled out.

If you can, use a new Google Cloud project to avoid any conflicts with existing
resources. You can then just delete the project when you're done with the demo.

## How to deploy

Prep your shell environment:

```bash
export GCLOUD_PROJECT=$(gcloud config get project)
export GCLOUD_REGION=us-central1

# Optional
# gcloud config set run/region $GCLOUD_REGION
```

Authenticate your account:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project $GCLOUD_PROJECT
```

### 1. Initialize Terraform

```bash
cd terraform
terraform init
terraform plan
```

### 2. Apply the Terraform configuration

```bash
terraform apply
```

Terraform will show you a plan of the resources that will be created. Review the
plan and type `yes` to confirm.

### 3. Verify the deployment

Once the deployment is complete, you can check the status of your Cloud Run
services in the Google Cloud Console.

## Deploying from source with gcloud

Terraform installed placeholder "Hellow, world" containers - we'll now deploy
the real services from source.

```bash
# Deploy the random service
cd ../services/random

npm install

gcloud beta run deploy random \
  --source . \
  --region $GCLOUD_REGION \
  --ingress internal \
  --service-account "random-sa@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
  --no-build \
  --command=node \
  --args=index.js \
  --base-image nodejs24 \
  --no-allow-unauthenticated
```

```bash
# Deploy the isolated service
cd ../isolated

npm install

gcloud beta run deploy isolated \
  --source . \
  --region $GCLOUD_REGION \
  --ingress internal \
  --service-account "isolated-sa@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
  --no-build \
  --command=node \
  --args=index.js \
  --base-image nodejs24 \
  --no-allow-unauthenticated
```

```bash
# Deploy the caller service
cd ../caller

npm install

RANDOM_SERVICE_URL=$(gcloud run services describe random --region $GCLOUD_REGION --format 'value(status.url)')

ISOLATED_SERVICE_URL=$(gcloud run services describe isolated  --region $GCLOUD_REGION  --format 'value(status.url)')

gcloud beta run deploy caller \
 --source . \
 --region $GCLOUD_REGION \
 --ingress internal \
 --service-account "caller-sa@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
 --no-build \
 --command=node \
 --args=index.js \
 --base-image nodejs24 \
 --no-allow-unauthenticated \
 --set-env-vars "RANDOM_SERVICE_URL=${RANDOM_SERVICE_URL},ISOLATED_SERVICE_URL=${ISOLATED_SERVICE_URL}"
```

## Test with the bastion host

The bastion host and its associated network resources are deployed via
Terraform. See `terraform/bastion.tf` and `terraform/network.tf`.

Access the bastion host:

```bash
gcloud compute ssh --zone "us-central1-a" "bastion" --tunnel-through-iap
```

Review
[Connect to Linux VMs using Identity-Aware Proxy](https://docs.cloud.google.com/compute/docs/connect/ssh-using-iap)
for more information about accessing VMs using IAP.

Remember that the bastion box runs with a service account so you may need to
`gcloud auth login` to use your account. Your account will need the
`run.invoker` role to call the services.

### Test the services

You can test the services from the bastion host.

Set the region we're using:

```bash
export GCLOUD_REGION=us-central1
```

#### Random

```bash
RANDOM_SERVICE_URL=$(gcloud run services describe random  --region $GCLOUD_REGION  --format 'value(status.url)')

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $RANDOM_SERVICE_URL
```

#### Caller

```
CALLER_SERVICE_URL=$(gcloud run services describe caller  --region $GCLOUD_REGION  --format 'value(status.url)')

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $CALLER_SERVICE_URL
```

The `caller` service cannot access the `isolated` service as it lacks the IAM
permissions.

#### Isolated

```
ISOLATED_SERVICE_URL=$(gcloud run services describe isolated  --region $GCLOUD_REGION  --format 'value(status.url)')

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $ISOLATED_SERVICE_URL
```

You are likely to be able to access the `isolated` service if you have the
`run.invoker` role for the whole project.

#### Logout

You can logout of the bastion host and move to the next section when you're
ready.

## Service Mesh

The Service Mesh additions to this demo are located in the `mesh` folder. They
assume that the tutorial has been followed to this point, including the
Terraform and service deployment.

### Apply the Terraform configuration

```bash
cd ../../mesh/terraform

terraform init

terraform apply
```

You may need to run `terraform apply` again if the first run doesn't work.

In order to provide Service Mesh support, the Terraform configuration includes:

- [apis.tf](mesh/terraform/apis.tf) - enables the additional required APIs
- [mesh.tf](mesh/terraform/mesh.tf) - creates the service mesh as well as the:
  - DNS zone
  - DNS wildcard A record
  - backend service
  - network endpoint group
- [routes.tf](mesh/terraform/routes.tf) - creates the routes for the service
  mesh, providing the `mesh-random.internal` hostname for the mesh-random
  service.

### Deploying from source with gcloud

Then, you can deploy the services

The `mesh-random` service is much the same as the `random` service, but it
returns a random number between 1000 and 2000.

```bash
# Deploy the random service
cd ../services/mesh-random

npm install

gcloud beta run deploy mesh-random \
  --source . \
  --region $GCLOUD_REGION \
  --ingress internal \
  --service-account "mesh-random-sa@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
  --no-build \
  --command=node \
  --args=index.js \
  --base-image nodejs24 \
  --no-allow-unauthenticated
```

The `mesh-caller` service does not need to explicitly provide a token to call
the `mesh-random` service - whereas the `caller` service used `GoogleAuth` to
get an ID token to use for the call. You'll also note that the `mesh-random`
service is called using the hostname `mesh-random.internal` instead of the
service URL.

```bash
# Deploy the caller service
cd ../mesh-caller

npm install

gcloud beta run deploy mesh-caller \
 --source . \
 --region $GCLOUD_REGION \
 --ingress internal \
 --service-account "mesh-caller-sa@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
 --no-build \
 --command=node \
 --args=index.js \
 --base-image nodejs24 \
 --no-allow-unauthenticated \
 --set-env-vars "RANDOM_SERVICE_URL=http://mesh-random.internal"
```

## Test with the bastion host

You can test the mesh-based services from the bastion host.

Access the bastion host:

```bash
gcloud compute ssh --zone "us-central1-a" "bastion" --tunnel-through-iap
```

Set the region we're using:

```bash
export GCLOUD_REGION=us-central1
```

Check the service:

```bash
MESH_CALLER_SERVICE_URL=$(gcloud run services describe mesh-caller  --region $GCLOUD_REGION  --format 'value(status.url)')

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $MESH_CALLER_SERVICE_URL
```

## Summary

This demo has shown how to deploy services to Cloud Run and how to secure them
using IAM. It has also shown how to use the service mesh to remove the need to
explicitly handle tokens in the calling service.
