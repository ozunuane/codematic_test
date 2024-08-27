module "project" {
  source = "./project"

  gcp_project_id = var.gcp_project_id


}



module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.1"

  project_id   = var.gcp_project_id
  network_name = "${var.name}-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "${var.name}-public-subnet-01"
      subnet_ip     = "100.10.9.0/24"
      subnet_region = var.region
    },
    {
      subnet_name           = "${var.name}-private-subnet-02"
      subnet_ip             = "100.10.12.0/24"
      subnet_region         = var.region
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
      description           = "${var.name} private subnet"
    },
    {
      subnet_name               = "subnet-03"
      subnet_ip                 = "100.10.30.0/24"
      subnet_region             = var.region
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
    }
  ]

  secondary_ranges = {
    subnet-public-01 = [
      {
        range_name    = "public-subnet-01-secondary-01"
        ip_cidr_range = "110.0.0.0/24"
      },
    ]

    subnet-private-02 = []
  }

  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    }
    
    # {
    #     name                   = "app-proxy"
    #     description            = "route through proxy to reach app"
    #     destination_range      = "10.50.10.0/24"
    #     tags                   = "app-proxy"
    #     next_hop_instance      = "app-proxy-instance"
    #     next_hop_instance_zone = "us-west1-a"
    # },
  ]
}

module "Nat" {
  source = "./nat"
  app_name = "${var.name}-network-nat"
  vpc_cidr = var.vpc_cidr
  region= var.region
  gcp_project_id= var.gcp_project_id
  network = module.vpc.network_self_link

}



module "bastion" {
  source        = "./bastion"
  app_name      = var.app_name
  region        = var.region
  ssh_whitelist = local.ssh_whitelist
  # config_hash             = var.config_hash
  # deployment_cache_buster = var.deployment_cache_buster
  project        = module.vpc.project_id
  network        = module.vpc.network_self_link
  private_subnet = module.vpc.subnets_names[2]
  # public_subnet     = module.network.public_subnet
  codematic_cluster = module.kubernetes.codematic-kubernetes
  depends_on        = [module.project, module.vpc]
}



module "kubernetes" {
  source   = "./kubernetes"
  app_name = var.app_name
  region   = var.region
  project  = module.vpc.project_id
  network  = module.vpc.network_name
  name     = var.name
  # private_subnet      = module.network.public_subnet
  public_subnet            = "100.10.12.0/24"
  region_zone              = var.region_zone
  region_zone_backup       = var.region_zone_backup
  authorized_networks      = var.authorized_networks
  ip_range_services        = var.ip_range_services
  ip_range_pods            = var.ip_range_pods
  k8_node_instance_type    = var.k8_node_instance_type
  k8_min_node_count        = var.k8_min_node_count
  k8_max_node_count        = var.k8_max_node_count
  k8_spot_instance_percent = var.k8_spot_instance_percent
}



