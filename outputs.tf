# output "bastion" {
#   value     = module.bastion.bastion
#   sensitive = true
# }


output "codematic-kubernetes" {
  value     = module.kubernetes.codematic-kubernetes
  sensitive = true
}

output "network_id" {
  value     = module.vpc.network_id
  sensitive = true
}



output "network_name" {
  value = module.vpc.network_name
}


output "network" {
  value = module.vpc.network
}



output "project_id" {
  value = module.vpc.project_id
}


output "route_names" {
  value = module.vpc.route_names
}

output "subnets" {
  value = module.vpc.subnets
}
# subnets
# A map with keys of form subnet_region/subnet_name and values being the outputs of the google_compute_subnetwork resources used to create corresponding subnets.

output "subnets_ids" {
  value = module.vpc.subnets_ids
}

# subnets_names
# The names of the subnets being created
output "subnets_private_access" {
  value = module.vpc.subnets_private_access
}
# subnets_private_access
# Whether the subnets will have access to Google API's without a public IP

# subnets_regions
# The region where the subnets will be created

# subnets_secondary_ranges
# The secondary ranges associated with these subnets

# subnets_self_links
# The self-links of subnets being created