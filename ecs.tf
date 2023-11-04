terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  required_version = ">= 1.1.0"

  cloud {
    organization = "sgr-fiap-17"

    workspaces {
      name = "rds-tr"
    }
  }
}

provider "aws" {
  region = "us-east-2" # Substitua pela sua região AWS desejada
}

locals {
  name   = "sgr-vpc"
  region = "us-east-2"

  vpc_cidr = "10.123.0.0/16"
  azs      = ["us-east-2a", "us-east-2b"]

  public_subnets  = ["10.123.1.0/24", "10.123.2.0/24"]
  private_subnets = ["10.123.3.0/24", "10.123.4.0/24"]
  intra_subnets   = ["10.123.5.0/24", "10.123.6.0/24"]

  tags = {
    Example = local.name
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets   = local.intra_subnets

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_ecs_cluster" "sgr-service-cluster" {
  name = "sgr-service-cluster"
}

# resource "aws_ecr_repository" "sgr-service" {
#   name = "sgr-service"
# }

resource "aws_ecs_task_definition" "tech-challenge-task" {
  family                   = "tech-challenge"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  cpu                      = 1
  memory                   = 512


  container_definitions = jsonencode([{
    name  = "sgr-service"
    image = "190197150713.dkr.ecr.us-east-2.amazonaws.com/sgr-service:sgr-service"
  }])
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_ecs_service" "ecs-service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.sgr-service-cluster.id
  task_definition = aws_ecs_task_definition.tech-challenge-task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.public_subnets # Substitua pelo ID da sua subnet
    security_groups = [aws_security_group.tech-sg.id]
  }

  depends_on = [aws_ecs_task_definition.tech-challenge-task]
}

resource "aws_security_group" "tech-sg" {
  name        = "tech-sg"
  description = "My security group for ECS tasks"

  ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}