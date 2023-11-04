terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
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

resource "aws_ecs_cluster" "sgr-service-cluster" {
  name = "sgr-service-cluster"
}

resource "aws_ecr_repository" "sgr-service-repository" {
  name = "	sgr-service-repository"
}

resource "aws_ecs_task_definition" "tech-challenge-task" {
  family                   = "tech-challenge"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn        = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "sgr-service"
    image = aws_ecr_repository.sgr-service.repository_url
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
    subnets = ["subnet-xxxxxxxxxxxxxx"] # Substitua pelo ID da sua subnet
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