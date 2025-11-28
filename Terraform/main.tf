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
# Step 1: Elastic Beanstalk Application
############################
resource "aws_elastic_beanstalk_application" "nginx_app" {
  name        = var.eb_app_name
  description = "Nginx Docker App deployed via Terraform"
}

############################
# Step 2: IAM Role & Instance Profile for EB
############################
resource "aws_iam_role" "eb_instance_role" {
  name = "${var.eb_app_name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eb_instance_role_policy" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "${var.eb_app_name}-instance-profile"
  role = aws_iam_role.eb_instance_role.name
}

############################
# Step 3: S3 Bucket for EB App Versions
############################
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "eb_bucket" {
  bucket = "${var.eb_app_name}-bucket-${random_id.suffix.hex}"
}

############################
# Step 4: Upload Dockerrun.aws.json to S3
############################
resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.eb_bucket.id
  key    = "nginx-app.zip"
  source = "nginx-app.zip"   # Your zipped Dockerrun.aws.json
  acl    = "private"
}

############################
# Step 5: Create EB Application Version
############################
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.nginx_app.name
  bucket      = aws_s3_bucket.eb_bucket.id
  key         = aws_s3_object.app_version.key
}

############################
# Step 6: Create EB Environment
############################
resource "aws_elastic_beanstalk_environment" "nginx_env" {
  name                = var.eb_env_name
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
