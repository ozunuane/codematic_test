output "bastion" {
  value     = module.bastion.bastion
  sensitive = true
}


output "codematic-kubernetes" {
  value     = module.kubernetes.codematic-kubernetes
  sensitive = true
}


# # output "lb" {
# #   value = {
# #     root          = module.lb.ip_address
# #     microservices = module.lb.microservice_urls
# #   }
# #   sensitive = true
# # }
