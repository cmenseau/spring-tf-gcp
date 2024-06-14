docker compose up --build
http://localhost:8080/todos-db

./mvnw verify

docker run --name local-postgres -p 5432:5432 -e POSTGRES_USER=cycy -e POSTGRES_PASSWORD=mysecretpassword -e POSTGRES_DB=todo_db -v ./docker-entrypoint-initdb.d/init.sql:/docker-entrypoint-initdb.d/init.sql -d postgres
docker logs local-postgres
docker start postgres

psql -h localhost -p 5432 -U myuser -d todo_db
SELECT * FROM todo;

# Configuring access between GCP and Github Actions
## With gcloud

Enable Direct Workload Identity Federation (reference : https://github.com/google-github-actions/auth with Workload Identity Federation through a Service Account)

We need a service account to use oauth2 access tokens, create it :

```
gcloud iam service-accounts create "my-github-service-account"
  --project "java-with-db-terraform"

// my-github-service-account@java-with-db-terraform.iam.gserviceaccount.com
 ```

Create a workload identity pool for GitHub and get its ID :

```
gcloud iam workload-identity-pools create "github" \
  --project="java-with-db-terraform" \
  --location="global" \
  --display-name="GitHub Actions Pool"

gcloud iam workload-identity-pools describe "github" \
  --project="java-with-db-terraform" \
  --location="global" \
  --format="value(name)"

Output ID : projects/198800315981/locations/global/workloadIdentityPools/github
```

Create a workload identity provider in that pool and get its ID :

```
gcloud iam workload-identity-pools providers create-oidc "my-repo" \
  --project="java-with-db-terraform" \
  --location="global" \
  --workload-identity-pool="github" \
  --display-name="My GitHub repo Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == 'cmenseau'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

gcloud iam workload-identity-pools providers describe "my-repo" \
  --project="java-with-db-terraform" \
  --location="global" \
  --workload-identity-pool="github" \
  --format="value(name)"

Output ID : projects/198800315981/locations/global/workloadIdentityPools/github/providers/my-repo
```


Grant the workload identity pool a role to give it permissions on the service account :

```
gcloud iam service-accounts add-iam-policy-binding "my-github-service-account@java-with-db-terraform.iam.gserviceaccount.com" \
  --project="java-with-db-terraform" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/198800315981/locations/global/workloadIdentityPools/github/attribute.repository/cmenseau/spring-tf-gcp"
```

Grant the service account a role to give it permissions on the Artifact Registry resource :

```
gcloud artifacts repositories add-iam-policy-binding todo-app-image-repo \
    --location='us-east1' \
    --member='serviceAccount:my-github-service-account@java-with-db-terraform.iam.gserviceaccount.com' \
    --role='roles/artifactregistry.writer'
```

gcloud reference page on artifact registry :
https://cloud.google.com/sdk/gcloud/reference/artifacts/repositories/add-iam-policy-binding?hl=en

If the service account isn't granted this role, you'll get this error : Permission "artifactregistry.repositories.uploadArtifacts" denied on resource "projects/java-with-db-terraform/locations/us-east1/repositories/todo-app-image-repo" (or it may not exist)


## With Terraform

```
variable gcp_project_name {
  type = string
  default = "java-with-db-terraform"
}

provider "google" {
    project     = var.gcp_project_name
    region      = "us-east1"
}

data "google_project" "project" {}

resource "google_artifact_registry_repository" "artifact_registry" {
  location      = "us-east1"
  repository_id = "todo-app-image-repo"
  format        = "DOCKER"
}

resource "google_service_account" "service_account" {
  account_id   = "my-github-service-account"
  display_name = "Service Account for Github"
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-wip"
  disabled = false
  display_name = "GitHub Actions Pool"
}

resource "google_iam_workload_identity_pool_provider" "my-repo" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "my-repo"
  display_name = "My GitHub repo Provider"
  attribute_mapping = {
    "google.subject":"assertion.sub",
    "attribute.actor":"assertion.actor",
    "attribute.repository":"assertion.repository",
    "attribute.repository_owner":"assertion.repository_owner"
  }
  attribute_condition = "assertion.repository_owner == 'cmenseau'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_binding" "admin-account-iam" {
  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/cmenseau/spring-tf-gcp",
  ]
}

resource "google_artifact_registry_repository_iam_binding" "iam_binding_service_account_role" {
  project = google_artifact_registry_repository.artifact_registry.project
  location = google_artifact_registry_repository.artifact_registry.location
  repository = google_artifact_registry_repository.artifact_registry.name
  role = "roles/artifactregistry.writer"
  members = [
    google_service_account.service_account.member,
  ]
}
```

# Deploy on Compute Engine

Installing Docker on Compute Engine instance

Pulling image from artifact Registry and starting it



https://github.com/google-github-actions/ssh-compute



# TODO List

- [x] Set up Artifact Registry and workload identity pool (manually in GCP console), create a Github pipeline to push container image to Artifact Registry
- [x] Create Terraform script for Artifact Registry / Workload identity pool
- [x] Set up a postresql DB in GCP Compute Engine using Terraform
- [x] Set up a Compute Engine instance for the app using Terraform
- [x] Deploy the app manually on CE instance, by pulling it from Artifact Registry (basic level)
- [ ] Update Github Actions so that a push to main automatically deploys the app on GCP Compute Engine https://github.com/google-github-actions/ssh-compute
- [ ] Best practices and hiding of passwords / identifiers
- [ ] Create a cloud endpoint to make the API online : https://cloud.google.com/endpoints/docs/openapi/get-started-compute-engine-docker
- [ ] Add a graph