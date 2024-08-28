module "project" {
  source = "./project"

  gcp_project_id = var.gcp_project_id
}

module "network" {
  source = "./network"

  app_name       = "${var.name}-${var.env}"
  region         = var.region
  gcp_project_id = var.gcp_project_id

  depends_on = [module.project]
}

########################
### compute/vm ###
########################

module "bastion" {
  source        = "./bastion"
  app_name      = "${var.name}-${var.env}"
  region        = var.region
  ssh_whitelist = local.ssh_whitelist
  # config_hash             = var.config_hash
  # deployment_cache_buster = var.deployment_cache_buster
  project           = module.network.project
  network           = module.network.network
  private_subnet    = module.network.public_subnet ###  Replaced with public subnet ###
  codematic_cluster = module.gke.name
  depends_on        = [module.project, module.network]
}

########################
## kubernetes cluster ##
########################

# module "kubernetes" {
#   source                   = "./kubernetes"
#   name                     = "${var.name}-${var.env}"
#   app_name                 = var.app_name
#   region                   = var.region
#   project                  = module.network.project
#   network                  = module.network.network
#   private_subnet           = module.network.private_subnet
#   public_subnet            = module.network.public_subnet
#   region_zone              = var.region_zone
#   region_zone_backup       = var.region_zone_backup
#   authorized_networks      = var.authorized_networks
#   k8_node_instance_type    = var.k8_node_instance_type
#   k8_min_node_count        = var.k8_min_node_count
#   k8_max_node_count        = var.k8_max_node_count
#   k8_spot_instance_percent = var.k8_spot_instance_percent
# }


module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.gcp_project_id
  name                       = "${var.name}-cluster"
  region                     = var.region
  zones                      =  [var.region_zone, var.region_zone_backup]
  network                    = module.network.name
  subnetwork                 = module.network.public_subnet_name
  ip_range_pods              = "ip-pods-secondary-range"
  ip_range_services          = "ip-services-secondary-range"
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  dns_cache                  = false



  node_pools = [
    {
      name                        = "default-node-pool"
      machine_type                = var.k8_node_instance_type
      node_locations              = "${var.region_zone},${var.region_zone_backup}"
      min_count                   = 1
      max_count                   = 100
      local_ssd_count             = 0
      spot                        = false
      disk_size_gb                = 100
      disk_type                   = "pd-standard"
      image_type                  = "COS_CONTAINERD"
      enable_gcfs                 = false
      enable_gvnic                = false
      logging_variant             = "DEFAULT"
      auto_repair                 = true
      auto_upgrade                = true
      service_account             = var.gcp_client_email
      preemptible                 = false
      initial_node_count          = 80
      max_shared_clients_per_gpu = 2
      initial_node_count = ceil(var.k8_min_node_count * (var.k8_spot_instance_percent / 100))
      min_count          = ceil(var.k8_min_node_count * (var.k8_spot_instance_percent / 100))
      max_count          = ceil(var.k8_max_node_count * (var.k8_spot_instance_percent / 100))
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}