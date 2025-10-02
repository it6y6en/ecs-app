terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      app = "riva-web-app"
    }
  }
}

module "infra" {
  #source      = "../ecs-infra"
  source      = "git::https://github.com/it6y6en/ecs-infra.git"
  vpc_cidr    = var.vpc_cidr
  num_subnets = var.num_subnets
  allowed_ips = var.allowed_ips_list
  region      = var.region
}

resource "aws_ecr_repository" "this" {
  name         = var.ecr_repository_name
  force_delete = true
}

resource "aws_lb_target_group" "this" {
  name        = "ecs-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.infra.vpc_id
}

resource "aws_lb_listener_rule" "http_rule" {
  listener_arn = module.infra.alb_listener_arn
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}