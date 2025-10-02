output "dns_name" {
  value = "http://${module.infra.alb_endpoint}:80"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "ecs_cluster_name" {
  value = module.infra.cluster_name
}

output "ecs_service_name" {
  value = "${var.app_name}-service"
}

output "ecs_task_family" {
  value = "${var.app_name}-task"
}

output "ecs_execution_role_arn" {
  value = module.infra.execution_role_arn
}

output "lb_target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "subnet_ids" {
  value = module.infra.private_subnets
}

output "security_group_id" {
  value = module.infra.app_security_group_id
}

output "region" {
  value = var.region
}