provider "google" {
    project     = "java-with-db-terraform"
    region      = "us-east1"
}

resource "google_compute_instance" "default" {
    name         = "my-instance"
    machine_type = "e2-micro"
    zone = "us-east1-d"
    boot_disk {
        initialize_params {
            image = "ubuntu-2204-jammy-v20240519"
        }
    }
    network_interface {
        network = "default"
    }
    metadata_startup_script = <<EOT
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc


# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo groupadd docker
sudo usermod -aG docker cycy_menseau

# output of gcloud auth configure-docker us-east1-docker.pkg.dev
mkdir /home/cycy_menseau/.docker
touch /home/cycy_menseau/.docker/config.json
echo '{
  "credHelpers": {
    "us-east1-docker.pkg.dev": "gcloud"
  }
}' > /home/cycy_menseau/.docker/config.json

gcloud config set auth/impersonate_service_account my-compute-engine-account@java-with-db-terraform.iam.gserviceaccount.com

newgrp docker

EOT

    # to check logs : sudo journalctl -u google-startup-scripts.service

    service_account {
        email = google_service_account.service_account.email
        scopes = ["cloud-platform"]
    }
    allow_stopping_for_update = true
}

resource "google_service_account" "service_account" {
    account_id   = "my-compute-engine-account"
    display_name = "Service Account for Compute Engine to access Artifact Registry"
}

resource "google_service_account_iam_binding" "iam_binding" {
    service_account_id = google_service_account.service_account.name
    role               = "roles/iam.serviceAccountTokenCreator"
    members = [
        google_service_account.service_account.member,
    ]
}

resource "google_artifact_registry_repository_iam_binding" "iam_binding_service_account_role" {
  repository = "todo-app-image-repo"
  role = "roles/artifactregistry.reader"
  members = [
    google_service_account.service_account.member,
  ]
}

output compute_instance-id {
  value       = google_compute_instance.default.instance_id
  description = "description"
  depends_on  = []
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