
resource "google_compute_network" "vpc" {
  name                    = "vpc1"
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "subnet" {
  name          = "subnet1"
  region        = "asia-south2"
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.0.0.0/24"
}





resource "google_container_cluster" "primary" {
  name                     = "test"
  location                 = "asia-south2-a"
  network                  = google_compute_network.vpc.name
  subnetwork               = google_compute_subnetwork.subnet.name
  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "10.13.0.0/28"
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.11.0.0/21"
    services_ipv4_cidr_block = "10.12.0.0/21"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.7/32"
      display_name = "net1"
    }

  }
}

# Create managed node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.primary.name
  location   = "asia-south2-a"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "dev"
    }

    machine_type = "n1-standard-1"
    # preemptible  = true


    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}




resource "google_compute_address" "my_internal_ip_addr" {
  project      = "valid-moment-410717"
  address_type = "INTERNAL"
  region       = "asia-south2"
  subnetwork   = "subnet1"
  name         = "my-ip"
  address      = "10.0.0.7"
  description  = "An internal IP address for my jump host"
}

resource "google_compute_instance" "default" {
  project      = "valid-moment-410717"
  zone         = "asia-south2-a"
  name         = "ssh"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = "vpc1"
    subnetwork = "subnet1" # Replace with a reference or self link to your subnet, in quotes
    network_ip = google_compute_address.my_internal_ip_addr.address
  }

}


## Creare Firewall to access jump hist via iap


resource "google_compute_firewall" "rules" {
  project = "valid-moment-410717"
  name    = "allow-ssh"
  network = "vpc1" # Replace with a reference or self link to your network, in quotes

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["49.207.211.192/32"]
}



## Create IAP SSH permissions for your test instance

# resource "google_project_iam_member" "project" {
#   project = "valid-moment-410717"
#   role    = "roles/iap.tunnelResourceAccessor"
#   member  = "test-620@valid-moment-410717.iam.gserviceaccount.com"
# }


resource "google_compute_router" "router" {
  project = "valid-moment-410717"
  name    = "nat-router"
  network = "vpc1"
  region  = "asia-south2"
}



module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.2"
  project_id = "valid-moment-410717"
  region     = "asia-south2"
  router     = google_compute_router.router.name
  name       = "nat-config"

}



output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}
