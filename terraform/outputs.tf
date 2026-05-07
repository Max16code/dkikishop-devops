output "alb_dns_name" {
  value = module.networking.alb_dns_name
}

output "asg_name" {
  value = module.compute.asg_name
}

output "vpc_id" {
  value = module.networking.vpc_id
}