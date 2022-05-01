# Set up a Terra nodes under a load balancer provisioned using terraform

[https://img.shields.io/badge/dev-in%20progress-important](https://img.shields.io/badge/dev-in%20progress-important)
This project contains a full terranode provisioned and configured using terraform.

------------------------

## 1. Prerequities 

- Terraform version: v1.1.8
- An AWS account

## 2. Configuration

- Configure an AWS profile in your terminal 
- Create a bucket that will contains the tfstate and logs of the load balancer.
  `aws s3 mb <BUCKET_NAME>`
- Change the `terraform.tfvars` files with the suitable variables

## 3. Architecture 

## 4. Installation 

### Manually 

- `terraform init`
- `terraform plan`
- `terraform deploy`


### CI/CD

You can use gitlab ci/cd in order to deploy the project or also github workflows.


## 5. Needs To be Done 

- The 
