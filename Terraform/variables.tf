variable "docker_image" {
  type    = string
  default = "xav519/nginx-docker-terraform:latest"
}

variable "eb_app_name" {
  type    = string
  default = "nginx-app"
}

variable "eb_env_name" {
  type    = string
  default = "nginx-env"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
