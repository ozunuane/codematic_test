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
  codematic_cluster = module.kubernetes.codematic-kubernetes
  depends_on        = [module.project, module.network]
}

########################
## kubernetes cluster ##
########################

module "kubernetes" {
  source                   = "./kubernetes"
  name                     = "${var.name}-${var.env}"
  app_name                 = var.app_name
  region                   = var.region
  project                  = module.network.project
  network                  = module.network.network
  private_subnet           = module.network.private_subnet
  public_subnet            = module.network.public_subnet
  region_zone              = var.region_zone
  region_zone_backup       = var.region_zone_backup
  authorized_networks      = var.authorized_networks
  k8_node_instance_type    = var.k8_node_instance_type
  k8_min_node_count        = var.k8_min_node_count
  k8_max_node_count        = var.k8_max_node_count
  k8_spot_instance_percent = var.k8_spot_instance_percent
}


