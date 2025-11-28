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

# Step 3: Create an S3 bucket for EB application versions
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "eb_bucket" {
  bucket = "nginx-docker-terraform-bucket-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_acl" "eb_bucket_acl" {
  bucket = aws_s3_bucket.eb_bucket.id
  acl    = "private"
}

# Step 4: Upload your zip to S3
resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.eb_bucket.id
  key    = "nginx-app.zip"
  source = "../nginx-app.zip"
  acl    = "private"
}

# Step 5: Create Elastic Beanstalk application version
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.nginx_app.name
  bucket      = aws_s3_bucket.eb_bucket.id
  source      = aws_s3_object.app_version.id

  depends_on = [null_resource.docker_build_push]
}

# Step 6: Create Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "nginx_env" {
  name                = "nginx-env"
  application         = aws_elastic_beanstalk_application.nginx_app.name
  solution_stack_name = "64bit Amazon Linux 2 v4.4.0 running Docker"
  version_label       = aws_elastic_beanstalk_application_version.app_version.name

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENV"
    value     = "production"
  }

  depends_on = [aws_elastic_beanstalk_application_version.app_version]
}
