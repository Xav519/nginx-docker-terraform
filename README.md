# Nginx Docker on AWS Elastic Beanstalk Project

## Project Motivation

I built this project to address a common challenge in modern organizations: deploying applications reliably and consistently in the cloud. Many companies struggle with manual configurations, inconsistent environments, and deployments that are hard to reproduce.

To solve this, I created an automated deployment using AWS Elastic Beanstalk, Docker, and Terraform. The project deploys a containerized Nginx application using Infrastructure as Code, ensuring that the entire environment is created, configured, and updated automatically.

This project demonstrates how automation, containerization, and cloud services work together to improve scalability, reduce errors, and streamline operations. It also helped me strengthen practical skills in AWS, Docker, and Terraform that are directly applicable to real enterprise cloud environments.

---

## Project Overview

This project demonstrates how to deploy a Dockerized Nginx web application on AWS Elastic Beanstalk using Terraform for infrastructure as code.

### Architecture Overview

![alt text](Images/ArchitectureBeanstalkAWS.png)
*This architecture diagram was created using **MermaidChart** ([https://www.mermaidchart.com](https://www.mermaidchart.com)).* <br /><br />

The architecture consists of:

* **Elastic Beanstalk Environment**: Hosts the Docker container running Nginx.
* **S3 Bucket**: Stores application versions (zip files containing the `Dockerrun.aws.json` configuration).
* **Terraform**: Configures and deploys all AWS resources automatically.
* **Docker Hub**: Stores the Docker image for Nginx.

---

## Table of Contents

1. [Project Motivation](#project-motivation)
2. [Architecture Overview](#architecture-overview)
3. [Screenshots](#screenshots)
4. [Prerequisites](#prerequisites)
5. [Project Setup](#project-setup)
6. [Terraform Configuration](#terraform-configuration)
7. [Docker Image and EB Zip](#docker-image-and-eb-zip)
8. [Deploying the Application](#deploying-the-application)
9. [Adding Your Own Website](#adding-your-own-website)
10. [Testing the Deployment](#testing-the-deployment)
11. [Terraform Workflow](#terraform-workflow)
12. [Cleanup](#cleanup)
13. [References](#references)

---

## Prerequisites

* AWS account with permissions for Elastic Beanstalk, S3, and IAM.
* Terraform installed.
* Docker installed and configured locally (optional if using public image only).
* Docker Hub account (optional, only if creating a custom image).
* Git and GitHub for version control.

---

## Installing Terraform

1. Download Terraform from [Terraform Downloads](https://developer.hashicorp.com/terraform/downloads) and add it to your PATH.
2. Verify installation:

```bash
terraform -v
```

---

## Project Setup

1. Create project folder:

```bash
mkdir AWS_projects/nginx-docker-terraform
cd AWS_projects/nginx-docker-terraform
```

2. Create a Dockerfile for Nginx (if building your own image):

```dockerfile
FROM nginx:latest
COPY . /usr/share/nginx/html
```

3. Create Terraform files: `main.tf`, `variables.tf`, and `outputs.tf`.

4. Create a zip file for Elastic Beanstalk deployment containing **`Dockerrun.aws.json`**:

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "xav519/nginx-docker-terraform:latest",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": "80"
    }
  ]
}
```

* Name this zip `nginx-app.zip`.
* Terraform will upload it to S3 and create an Elastic Beanstalk application version from it.

**Note:** The current Docker image only contains default Nginx. The zip is still required to tell Elastic Beanstalk which Docker image to deploy.

---

## Terraform Configuration

Terraform provisions:

* **S3 Bucket**: For storing application versions (`nginx-app.zip`).
* **Elastic Beanstalk Application**: Nginx deployment container.
* **Elastic Beanstalk Environment**: Public-facing load-balanced environment.
* **Docker Pull from Docker Hub**: Elastic Beanstalk pulls the image automatically.

---

## Docker Image and EB Zip

For this project:

1. I built a Docker image locally for Nginx:

```bash
docker build -t xav519/nginx-docker-terraform:latest .
docker login -u xav519
docker push xav519/nginx-docker-terraform:latest
```

2. Uploaded it to a **public Docker Hub repository**: `xav519/nginx-docker-terraform`.

**Important:**

* You **do not need to repeat these steps** when using this Terraform setup.
* Terraform and Elastic Beanstalk will pull the public Docker image automatically.

---

## Deploying the Application

1. Initialize Terraform:

```bash
terraform init
```

2. Plan resources:

```bash
terraform plan
```

3. Apply resources:

```bash
terraform apply
```

Confirm with `yes` when prompted.

---

## Adding Your Own Website

Currently, the Docker image only contains default Nginx. To serve your own website:

1. **Option 1: Update Docker image**

   * Add your website files (`index.html`, CSS, JS) to the Docker build context.
   * Rebuild the image and push it to Docker Hub.
   * Update `Dockerrun.aws.json` if using a new image tag.

2. **Option 2: Use a different zip**

   * Replace the default `nginx-app.zip` with a zip that contains your website files and `Dockerrun.aws.json` pointing to your Docker image.

This ensures your custom website is deployed in Elastic Beanstalk.

---

## Testing the Deployment

1. After Terraform finishes, access the public URL generated by Elastic Beanstalk, e.g.:

![alt text](Images/OutputsBeanstalkURL.png)

2. You should see the Nginx welcome page (default) or your custom website if added:

![alt text](Images/WebsiteAccess.png)

---

## Terraform Workflow

1. Terraform provisions all AWS resources, including:

   * S3 bucket for application versions
   * Elastic Beanstalk application and environment
   * Pulling Docker image from Docker Hub

2. The deployment is fully automated with Infrastructure as Code.

---

## Cleanup

To remove all resources:

```bash
terraform destroy
```

---

## References

* HashiCorp. Terraform Documentation. Retrieved from [https://developer.hashicorp.com/terraform/docs](https://developer.hashicorp.com/terraform/docs)
* Amazon Web Services. AWS Elastic Beanstalk Documentation. Retrieved from [https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/)
* Amazon Web Services. AWS S3 Documentation. Retrieved from [https://docs.aws.amazon.com/s3/index.html](https://docs.aws.amazon.com/s3/index.html)
* Docker. Docker Documentation. Retrieved from [https://docs.docker.com/](https://docs.docker.com/)
* OpenAI. ChatGPT (GPT-4/5 Model). Retrieved from [https://chat.openai.com](https://chat.openai.com)

---

— Xavier Dupuis
