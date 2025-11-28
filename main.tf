terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "docker_username" {
  type    = string
  default = "xav519"
}

variable "docker_image" {
  type    = string
  default = "nginx-docker-terraform"
}

# Step 1: Build and push Docker image
resource "null_resource" "docker_build_push" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Building Docker image..."
      docker build -t ${var.docker_username}/${var.docker_image}:latest ..
      echo "Logging into Docker Hub..."
      docker login -u ${var.docker_username}
      echo "Pushing Docker image..."
      docker push ${var.docker_username}/${var.docker_image}:latest
    EOT
    working_dir = "${path.module}/.."
  }
}

# Step 2: Create Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "nginx_app" {
  name        = "nginx-app"
  description = "Nginx Docker App deployed via Terraform"
  depends_on  = [null_resource.docker_build_push]
}

# Step 3: Create Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "nginx_env" {
  name                = "nginx-env"
  application         = aws_elastic_beanstalk_application.nginx_app.name
  solution_stack_name = "64bit Amazon Linux 2 v4.4.0 running Docker"

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENV"
    value     = "production"
  }

  depends_on = [aws_elastic_beanstalk_application.nginx_app]
}
