terraform {
  required_providers {
    rediscloud = {
      source = "RedisLabs/rediscloud"
      version = "1.0.1"
    }
  }
}

provider "rediscloud" {}

provider "google" {
  project     = "redis-active-active-vpc-peer"
  region      = "us-central1"
  
}

data "rediscloud_payment_method" "card" {
  card_type = "Visa"
}

// Create GCP Subcription in two regions
resource "rediscloud_active_active_subscription" "example" {
  name = "%s" 
  payment_method_id = data.rediscloud_payment_method.card.id 
  cloud_provider = "GCP"

  creation_plan {
    memory_limit_in_gb = 1
    quantity = 1
    replication=false
    support_oss_cluster_api=true
	region {
		region = "us-central1"
		networking_deployment_cidr = "192.168.0.0/24"
		write_operations_per_second = 1000
		read_operations_per_second = 1000
	}
	region {
		region = "europe-west1"
		networking_deployment_cidr = "10.0.1.0/24"
		write_operations_per_second = 1000
		read_operations_per_second = 1000
	}
	}
  }

// Create VPC network within GCP Project
resource "google_compute_network" "network" {
  project = "redis-active-active-vpc-peer"
  name = "redis-active-active-55"
  auto_create_subnetworks = "true"
}

// Create Redis VPC connection Link to GCP account and region
resource "rediscloud_active_active_subscription_peering" "example-peering" {
   subscription_id = rediscloud_active_active_subscription.example.id
   provider_name = "GCP"
   source_region = "us-central1"
   gcp_project_id = google_compute_network.network.project
   gcp_network_name = google_compute_network.network.name
}

output "redis-peering" {
  value = rediscloud_active_active_subscription_peering.example-peering
}

// GCP Approve Redis VPC connection 
resource "google_compute_network_peering" "example-peering" {
  name         = "peering-gcp-example-333"
  network      = google_compute_network.network.self_link
  peer_network = "https://www.googleapis.com/compute/v1/projects/${rediscloud_active_active_subscription_peering.example-peering.gcp_redis_project_id}/global/networks/${rediscloud_active_active_subscription_peering.example-peering.gcp_redis_network_name}"
  depends_on = [
    rediscloud_active_active_subscription_peering.example-peering
  ]
}