provider "google" {
  project = "kyo2bay-gcp-run-sql"
}

provider "google-beta" {
  project = "kyo2bay-gcp-run-sql"
}

terraform {
  backend "gcs" {
    bucket = "kyo2bay-gcp-run-sql-tf-state"
  }
}

terraform {
  required_providers {
    google = {
      version = "~> 4.65.0"
    }
  }

  required_version = "~> 1.4.6"
}

data "google_project" "default" {
}

locals {
  services = [
    "artifactregistry.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "oslogin.googleapis.com",
    "secretmanager.googleapis.com",
    "securetoken.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "sqladmin.googleapis.com",
    "sql-component.googleapis.com",
    "vpcaccess.googleapis.com",
  ]
}

resource "google_project_service" "default" {
  for_each = toset(local.services)
  service  = each.value
  project  = data.google_project.default.id
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

locals {
  roles = [
    "roles/cloudsql.admin",
  ]
}

resource "google_service_account" "default" {
  account_id = "gcp-run-sql-sa"
}

resource "google_project_iam_member" "default" {
  for_each = toset(local.roles)
  role     = each.value
  member   = "serviceAccount:${google_service_account.default.email}"
  project  = data.google_project.default.id
}

resource "google_cloud_run_service" "default" {
  name     = "gcp-run-sql"
  location = "asia-northeast1"

  template {
    spec {
      containers {
        image = "gcr.io/${data.google_project.default.project_id}/run-sql"

        env {
          name  = "INSTANCE_UNIX_SOCKET"
          value = "/cloudsql/${data.google_project.default.project_id}:asia-northeast1:${google_sql_database_instance.default.name}"
        }
        env {
          name  = "INSTANCE_CONNECTION_NAME"
          value = "${data.google_project.default.project_id}:asia-northeast1:${google_sql_database_instance.default.name}"
        }
        env {
          name  = "DB_NAME"
          value = google_sql_database.default.name
        }
        env {
          name  = "DB_USER"
          value = google_sql_user.default.name
        }
        env {
          name  = "DB_PASS"
          value = google_sql_user.default.password
        }
      }
      service_account_name = google_service_account.default.email
    }
  }

  autogenerate_revision_name = true
}

resource "google_compute_global_address" "default" {
  name = "gcp-run-sql-lb-ip"
}

output "lb_ip" {
  value = google_compute_global_address.default.address
}

resource "google_compute_region_network_endpoint_group" "default" {
  name                  = "gcp-run-sql-neg"
  region                = "asia-northeast1"
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_service.default.name
  }
}

resource "google_compute_backend_service" "default" {
  name                  = "gcp-run-sql-backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  locality_lb_policy    = "ROUND_ROBIN"

  backend {
    group = google_compute_region_network_endpoint_group.default.id
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = "gcp-run-sql-target-https-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_url_map" "default" {
  name            = "gcp-run-sql-lb"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "gcp-run-sql-forwarding-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}

resource "google_sql_database_instance" "default" {
  name             = "gcp-run-sql-instance"
  region           = "asia-northeast1"
  database_version = "POSTGRES_14"
  settings {
    tier = "db-f1-micro"
  }

  deletion_protection = "true"
}

resource "google_sql_user" "default" {
  name     = "demo_user"
  instance = google_sql_database_instance.default.name
  password = "demo_pass"
}

resource "google_sql_database" "default" {
  name     = "demo_db"
  instance = google_sql_database_instance.default.name
}
