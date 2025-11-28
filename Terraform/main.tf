terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

############################
# Elastic Beanstalk Application
############################
resource "aws_elastic_beanstalk_application" "nginx_app" {
  name        = var.application_name
  description = "Nginx Docker App deployed via Terraform"
}

############################
# IAM Role & Instance Profile
############################
resource "aws_iam_role" "eb_instance_role" {
  name = "nginx-eb-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eb_instance_role_policy" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "nginx-eb-instance-profile"
  role = aws_iam_role.eb_instance_role.name
}

############################
# Elastic Beanstalk Environment
############################
resource "aws_elastic_beanstalk_environment" "nginx_env" {
  name                = var.environment_name
  application         = aws_elastic_beanstalk_application.nginx_app.name
  solution_stack_name = "64bit Amazon Linux 2 v4.4.0 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  # Tell EB which Docker image to run
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DOCKER_IMAGE"
    value     = "${var.docker_username}/${var.docker_image}:latest"
  }

  # Optional: set other environment variables
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENV"
    value     = "production"
  }

  depends_on = [aws_elastic_beanstalk_application.nginx_app]
}
