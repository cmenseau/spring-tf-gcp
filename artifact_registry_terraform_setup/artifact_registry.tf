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
  workload_identity_pool_id = "github-tf"
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