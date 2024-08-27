region                   = "europe-west2"
region_zone              = "europe-west2-a"
region_zone_backup       = "europe-west2-b"
ip_range_pods            = "ip-range-pods"
ip_range_services        = "ip-range-services"
name                     = "codematic-test"
env                      = "test"
vpc_cidr                 = "100.10.0.0/16"
ip_whitelist             = "0.0.0.0/0"
ssh_whitelist            = "0.0.0.0/0"
k8_node_instance_type    = "e2-standard-4"
k8_spot_instance_percent = 50
k8_min_node_count        = 1
k8_max_node_count        = 2

