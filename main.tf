variable gcp_project_name {
  type = string
  default = "java-with-db-terraform"
}

variable region {
  type = string
  default = "us-east1"
}

provider "google" {
    project     = var.gcp_project_name
    region      = var.region
}

# repository is defined in another Terraform file because it can't be recreated easily 
data "google_artifact_registry_repository" "my-repo" {
  location      = var.region
  repository_id = "todo-app-image-repo"
}

resource "google_compute_instance" "default" {
    name         = "my-instance"
    machine_type = "e2-micro"
    zone = "us-east1-d"
    boot_disk {
        initialize_params {
            type = "pd-standard"
            image = "ubuntu-2204-jammy-v20240519"
        }
    }
    network_interface {
        network = "default"
    }
    service_account {
        email = google_service_account.app_instance_account.email
        scopes = ["cloud-platform"]
    }
    allow_stopping_for_update = true
    metadata = {
      ssh-keys = "${var.gce_ssh_user}:${var.gce_ssh_pub_key} \n${var.ansible_ssh_user}:${var.ansible_ssh_pub_key}",
    }
}

variable gce_ssh_user {
  type = string
  default = "cycy_menseau"
}

variable gce_ssh_pub_key {
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCj31vynGaZ1BzmyWQVgSpdbM+gS44omU9RIqmtSFeDNLESfLCgheUUrgqkTat6gvJTlR5rHokkf6j4y8dWkmOayxtR9CRfW5OaDIgD+9aYVBxg1sI7GcMFlHZrLqHK+mKYg9GisJIMcE5cQZe9RjUB6JZhNBo5vOdtX1DTTgytsAXpyMTxyoHwtQ4lWZ2W7XY7u3upUXi5dZ3HrR+TZG5lSS1eA5WElXR100XBRL9UXpptUFnVoTjySPzSKMR/vR1P8ZVGtlokJGJZG/40CjTU7NfMG2dF+VN1pXFiVhlngxd2/Bo4b/NgMz06x1M0kiH8HLGqsi+05YoF6KHVQ0lf cycy_menseau"
}

variable ansible_ssh_user {
  type = string
  default = "cycy_menseau"
}

variable ansible_ssh_pub_key {
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8YyXEyKYhTa/Oyj9MapYtgPCoD6aMqYpPZBCFm3uWqKSWZwYcZM5me8nAteJaBxy6LM7cCpJcvRFJQdi+GMCjsQpJirfO2efxvFKb2fPnmo8xclUgPGG30NgaabBXX8Se2MMCUQb1U+kFqPrp/H/AkHjwVyH4eR05kkY98sGLYIZBv/L0GqLXjetY+HgZd5nYzlWgS31E62sKXS9Q7zVwNmCck7tFD35MlkZfL5b+xrNmBgPAsr7ozUVeSoG+u1rEI9eLksuShGdDcWm6vAMTcQyE5NGq0GUp3woVfq8LXykfcqgzg39e5TX+vRKQHFKsXRr50rsQ1QY4j4ies8jj cycy_menseau"
}

variable postgres_ssh_user {
  type = string
  default = "cycy_menseau"
}

variable postgres_ssh_pub_key {
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyQCmhH9rrU0fH+RYFs058WQyALm926LixWcfiLJzApgIorKAvcsiYFxeQNTKQ31WA9xaY3FNbyW8xxQrsMlf7lwcT1m3s35PfJyaRN6BSxS4JPlZInY2q1FRZQ82erbgGzOkNp4K9C0cXt+xVmaDhmfH0MqbRN5BYBoT0AfL2F1JBHm018pHz8lIK6yClfZ2UiFFcrsO+hk2wgxzYV0pTw53/lsDr//KpIxiEp1bLJZxO5jNxZT6s7UcPnXpP1v7uI4BBf1KDQrs6dEECWabJ02NCNQ2LscWeXf2jY2vmkSXvlDbNy1nsTVxQl8iFkPQ4cz1BTQbXOrJ4vjgWMcID cycy_menseau"
}

resource "google_service_account" "app_instance_account" {
    account_id   = "my-compute-engine-account"
    display_name = "Service Account attached to Compute Engine"
}

resource "google_service_account" "registry_reader" {
    account_id   = "artifact-registry-reader"
    display_name = "Service Account used to access Artifact Registry"
}

resource "google_service_account_iam_binding" "iam_binding" {
    service_account_id = google_service_account.registry_reader.name
    role               = "roles/iam.serviceAccountTokenCreator"
    members = [
        google_service_account.app_instance_account.member,
    ]
}

resource "google_artifact_registry_repository_iam_binding" "iam_binding_service_account_role" {
  repository = data.google_artifact_registry_repository.my-repo.repository_id
  role = "roles/artifactregistry.reader"
  members = [
    google_service_account.registry_reader.member,
  ]
}

resource "google_project_iam_binding" "binding-get-instance" {
  project = var.gcp_project_name
  role    = "roles/compute.instanceAdmin.v1"
  members = [
    "serviceAccount:my-github-service-account@java-with-db-terraform.iam.gserviceaccount.com",
  ]
}

resource "google_project_iam_binding" "binding-iap-access" {
  project = var.gcp_project_name
  role    = "roles/iap.tunnelResourceAccessor"
  members = [
    "serviceAccount:my-github-service-account@java-with-db-terraform.iam.gserviceaccount.com",
  ]
}

resource "google_service_account_iam_binding" "admin-account-iam" {
  service_account_id = google_service_account.app_instance_account.name
  role               = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:my-github-service-account@java-with-db-terraform.iam.gserviceaccount.com",
  ]
}

# allow traffic to internet in Compute Instance to fetch docker install
resource "google_compute_router" "nat-router" {
  name    = "nat-router"
  network  = "default"
}

resource "google_compute_router_nat" "nat-config" {
  name                               = "nat-config"
  router                             = "${google_compute_router.nat-router.name}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# allow IAP to access VM without public address

resource "google_compute_firewall" "default" {
  name    = "my-firewall"
  network = "default"

  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_instance" "postgres-instance" {
    name         = "my-postgres-instance"
    machine_type = "e2-micro"
    zone = "us-east1-d"
    boot_disk {
        initialize_params {
            type = "pd-standard"
            image = "ubuntu-2204-jammy-v20240519"
        }
    }
    network_interface {
        network = "default"
    }
    allow_stopping_for_update = true
    metadata = {
      ssh-keys = "${var.postgres_ssh_user}:${var.postgres_ssh_pub_key}",
    }
}

# IP of instance containing postgresql

output postgres-ce-ip {
  value = google_compute_instance.postgres-instance.network_interface.0.network_ip
}

output my-instance-ip {
  value = google_compute_instance.default.network_interface.0.network_ip
}

output my-instance-name {
  value = google_compute_instance.default.name
}

output compute_instance-id {
  value       = google_compute_instance.default.instance_id
  description = "description"
  depends_on  = []
}

resource "local_file" "tf_ansible_vars_file_new" {
  content = <<-DOC
    # Ansible vars_file containing variable values from Terraform.
    # Generated by Terraform mgmt configuration.

    tf_postres_ip: ${google_compute_instance.postgres-instance.network_interface.0.network_ip}
    tf_docker_registry_service_account: ${google_service_account.registry_reader.email}
    tf_docker_registry_name: ${data.google_artifact_registry_repository.my-repo.repository_id}
    tf_region: ${var.region}
    tf_gcp_project_name: ${var.gcp_project_name}
    tf_image_name: ${var.artifact_registry_image_name}
    tf_image_latest_tag: ${data.google_artifact_registry_docker_image.my_image.tags.0}
    DOC
  filename = "./ansible/tf_ansible_vars_file.yml"
}

variable artifact_registry_image_name {
  type = string
  default = "todo-app-java"
}

data "google_artifact_registry_docker_image" "my_image" {
  location = data.google_artifact_registry_repository.my-repo.location
  repository_id = data.google_artifact_registry_repository.my-repo.repository_id
  image_name = var.artifact_registry_image_name
}
