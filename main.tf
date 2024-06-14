variable gcp_project_name {
  type = string
  default = "java-with-db-terraform"
}

provider "google" {
    project     = var.gcp_project_name
    region      = "us-east1"
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

gcloud auth configure-docker us-east1-docker.pkg.dev --quiet

gcloud config set auth/impersonate_service_account ${google_service_account.service_account.email}

newgrp docker

sudo docker pull \
  us-east1-docker.pkg.dev/${var.gcp_project_name}/todo-app-image-repo/todo-app-java:main-0159a3cfa1d9b91af68bc0ddb08d3afb048e8a91

sudo docker run -p 8080:8080 \
  -e MYAPP_JDBC_USER=myuser \
  -e MYAPP_JDBC_PASS=mysecretpassword \
  -e MYAPP_JDBC_URL=jdbc:postgresql://${google_compute_instance.postgres-instance.network_interface.0.network_ip}:5432/todo_db \
  -d \
  us-east1-docker.pkg.dev/${var.gcp_project_name}/todo-app-image-repo/todo-app-java:main-0159a3cfa1d9b91af68bc0ddb08d3afb048e8a91

EOT

    # to check logs : sudo journalctl -u google-startup-scripts.service

    service_account {
        email = google_service_account.service_account.email
        scopes = ["cloud-platform"]
    }
    allow_stopping_for_update = true
    metadata = {
      ssh-keys = "${var.gce_ssh_user}:${var.gce_ssh_pub_key}"
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

newgrp docker
docker pull postgres

touch init.sql

echo "CREATE TABLE todo (
  id SERIAL NOT NULL PRIMARY KEY,
  content VARCHAR(255)
);
INSERT INTO todo (content)
VALUES
    ('Inserted from TF'),
    ('Also inserted from TF');" > init.sql

docker run --name my-postgres -p 5432:5432 -e POSTGRES_USER=myuser -e POSTGRES_PASSWORD=mysecretpassword -e POSTGRES_DB=todo_db \
    -v ./init.sql:/docker-entrypoint-initdb.d/init.sql -d postgres

EOT
    # psql -h localhost -p 5432 -U myuser -d todo_db


    # to check logs : sudo journalctl -u google-startup-scripts.service

    allow_stopping_for_update = true
}

# IP of instance containing postgresql

output postgres-ce-ip {
  value = google_compute_instance.postgres-instance.network_interface.0.network_ip
}
