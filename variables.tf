variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "num_subnets" {
  type    = number
  default = 2
}

variable "allowed_ips_list" {
  type        = set(string)
  description = "Allowed IPs for incomming traffic to override with .tfvars or cli arguments"
  default     = ["0.0.0.0/0"]
}

variable "ecr_repository_name" {
  type    = string
  default = "ecs-app-repo"
}

variable "app_name" {
  type    = string
  default = "hello-world"
}

variable "release_version" {
  type    = string
  default = "1.0.0"
}
