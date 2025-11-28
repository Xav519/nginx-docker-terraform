variable "docker_username" {
  type    = string
  default = "xav519"
}

variable "docker_image" {
  type    = string
  default = "nginx-docker-terraform"
}

variable "environment_name" {
  type    = string
  default = "nginx-env"
}

variable "application_name" {
  type    = string
  default = "nginx-app"
}

variable "region" {
  type    = string
  default = "us-east-1"
}
