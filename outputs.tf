# output EB URL after deployment
output "elastic_beanstalk_url" {
  value = aws_elastic_beanstalk_environment.nginx_env.endpoint_url
}