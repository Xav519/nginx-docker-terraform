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

############################
# Step 1: Build & Push Docker Image
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
# Step 2: Create Elastic Beanstalk Application
############################
resource "aws_elastic_beanstalk_application" "nginx_app" {
  name        = "nginx-app"
  description = "Nginx Docker App deployed via Terraform"
  depends_on  = [null_resource.docker_build_push]
}

############################
# Step 3: Create IAM Role & Instance Profile
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
# Step 4: Create S3 Bucket for EB App Versions
############################
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "eb_bucket" {
  bucket = "nginx-docker-terraform-bucket-${random_id.suffix.hex}"
}

############################
# Step 5: Upload Zip to S3
############################
resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.eb_bucket.id
  key    = "nginx-app.zip"
  source = "nginx-app.zip"   # Path to your zipped Dockerrun.aws.json
  acl    = "private"
}

############################
# Step 6: Create EB Application Version
############################
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.nginx_app.name
  bucket      = aws_s3_bucket.eb_bucket.id
  key         = aws_s3_object.app_version.key

  depends_on = [null_resource.docker_build_push]
}

############################
# Step 7: Create EB Environment
############################
resource "aws_elastic_beanstalk_environment" "nginx_env" {
  name                = "nginx-env"
  application         = aws_elastic_beanstalk_application.nginx_app.name
  solution_stack_name = "64bit Amazon Linux 2 v4.4.0 running Docker"
  version_label       = aws_elastic_beanstalk_application_version.app_version.name

  # Attach instance profile to allow EC2 instances to run
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  # Custom environment variables
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENV"
    value     = "production"
  }

  depends_on = [aws_elastic_beanstalk_application_version.app_version]
}
