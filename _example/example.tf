provider "google" {
  project = "local-concord-408802"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}

#####==============================================================================
##### vpc module call.
#####==============================================================================
module "vpc" {
  source                                    = "SyncArcs/vpc/google"
  version                                   = "1.0.1"
  name                                      = "app"
  environment                               = "test"
  routing_mode                              = "REGIONAL"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
}

#####==============================================================================
##### subnet module call.
#####==============================================================================
module "subnet" {
  source        = "SyncArcs/subnet/google"
  version       = "1.0.1"
  name          = "app"
  environment   = "test"
  subnet_names  = ["subnet-a"]
  gcp_region    = "asia-northeast1"
  network       = module.vpc.vpc_id
  ip_cidr_range = ["10.10.1.0/24"]
}

#####==============================================================================
##### firewall module call.
#####==============================================================================
module "firewall" {
  source        = "SyncArcs/firewall/google"
  version       = "1.0.1"
  name          = "app"
  environment   = "test"
  network       = module.vpc.vpc_id
  source_ranges = ["0.0.0.0/0"]

  allow = [
    { protocol = "tcp"
      ports    = ["22", "80"]
    }
  ]
}

#####==============================================================================
##### compute_instance module call.
#####==============================================================================
module "compute_instance" {
  source                 = "../"
  name                   = "app"
  environment            = "test"
  instance_count         = 1
  instance_tags          = ["foo", "bar"]
  machine_type           = "e2-small"
  image                  = "ubuntu-2204-jammy-v20230908"
  gcp_zone               = "asia-northeast1-a"
  service_account_scopes = ["cloud-platform"]
  subnetwork             = module.subnet.subnet_id

  # Enable public IP only if enable_public_ip is true
  enable_public_ip = true
  metadata = {
    ssh-keys = <<EOF
      test:ssh-rsa AAAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxbLLNM= ashish@ashish
    EOF
  }
}
