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
      name = "ecs-workspace"
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
  cpu                      = 256
  memory                   = 512
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([{
    name  = "sgr-service"
    image = "190197150713.dkr.ecr.us-east-2.amazonaws.com/sgr-service:sgr-service"
    environment : [
      {
        "name" : "DB_USERNAME",
        "value" : "root"
      },
      {
        "name" : "DB_HOST",
        "value" : "sgr-rds-instance.cu7yj3gjjks1.us-east-2.rds.amazonaws.com"
      },
      {
        "name" : "DB_SCHEMA",
        "value" : "sgr_database"
      },
      {
        "name" : "DB_PASSWORD",
        "value" : "senhamysqlrds"
      }
    ],
  }])
}

variable "iam_policy_name" {
  type    = string
  default = "ecs-iam-policy"
}

resource "aws_iam_policy" "ecs-iam-policy" {
  name = var.iam_policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "ecs_iam_iam_policy_attachment" {
  name       = "Policy Attachement"
  policy_arn = aws_iam_policy.ecs-iam-policy.arn
  roles      = [aws_iam_role.ecs_execution_role.name]
}

resource "aws_ecs_service" "ecs-service" {
  name            = "sgr-service-ecs"
  cluster         = aws_ecs_cluster.sgr-service-cluster.id
  task_definition = aws_ecs_task_definition.tech-challenge-task.arn
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = true
    security_groups  = ["sg-05f8d8ff2e7f81bcc"]
    subnets          = ["subnet-06a9e76e0f6dc9819", "subnet-0259ecbde408105f8", "subnet-00d5e89c1c1ced6a1"]
  }
  desired_count = 1
  depends_on = [aws_ecs_task_definition.tech-challenge-task]
}

# resource "aws_security_group" "tech-sg" {
#   name        = "tech-sg"
#   description = "My security group for ECS tasks"

#   ingress {
#     from_port   = 8083
#     to_port     = 8083
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }