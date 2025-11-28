// variables.tf

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "docker_username" {
  description = "Docker Hub username"
  type        = string
  default     = "xav519"
}

variable "docker_image" {
  description = "Docker image repository name (no tag)"
  type        = string
  default     = "nginx-docker-terraform"
}

variable "application_name" {
  description = "Elastic Beanstalk application name"
  type        = string
  default     = "nginx-app"
}

variable "environment_name" {
  description = "Elastic Beanstalk environment name"
  type        = string
  default     = "nginx-env"
}

variable "s3_bucket_prefix" {
  description = "Prefix for S3 bucket name (random suffix appended)"
  type        = string
  default     = "nginx-docker-terraform-bucket"
}

variable "instance_profile_name" {
  description = "IAM instance profile name for EB EC2 instances"
  type        = string
  default     = "nginx-eb-instance-profile"
}
