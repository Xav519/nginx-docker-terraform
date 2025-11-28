// main.tf

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
  region = var.aws_region
}

############################
# Build & Push Docker Image (local)
############################
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

############################
# Elastic Beanstalk Application
############################
resource "aws_elastic_beanstalk_application" "nginx_app" {
  name        = var.application_name
  description = "Nginx Docker App deployed via Terraform"
  depends_on  = [null_resource.docker_build_push]
}

############################
# IAM Role & Instance Profile (for EC2 instances)
############################
resource "aws_iam_role" "eb_instance_role" {
  name = "${var.application_name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eb_instance_role_policy" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.eb_instance_role.name
}

############################
# S3 bucket for EB app versions
############################
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "eb_bucket" {
  bucket = "${var.s3_bucket_prefix}-${random_id.suffix.hex}"
  # keep defaults; don't set ACL resource (Bucket owner enforced in many accounts)
}

############################
# Upload zipped Dockerrun (nginx-app.zip) to S3
# Make sure nginx-app.zip is in the same folder as this main.tf
############################
resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.eb_bucket.id
  key    = "nginx-app.zip"
  source = "nginx-app.zip"
  acl    = "private"
}

############################
# EB Application Version (points to S3 object)
############################
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.nginx_app.name
  bucket      = aws_s3_bucket.eb_bucket.id
  key         = aws_s3_object.app_version.key

  depends_on = [null_resource.docker_build_push]
}

############################
# Elastic Beanstalk Environment
############################
resource "aws_elastic_beanstalk_environment" "nginx_env" {
  name                = var.environment_name
  application         = aws_elastic_beanstalk_application.nginx_app.name
  solution_stack_name = "64bit Amazon Linux 2 v4.4.0 running Docker"
  version_label       = aws_elastic_beanstalk_application_version.app_version.name

  # Attach IAM instance profile so EC2 instances can run properly
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENV"
    value     = "production"
  }

  depends_on = [aws_elastic_beanstalk_application_version.app_version]
}
