# Simple ECS web application

## Prerequisites:

- AWS account
- AWS CLI installed
- Terraform
- jq

## Architecture:

- AWS VPC
- Public subnets with ALB
- Private subnets with VPC endpoints
- ECS tasks run in private subnets

The repository contains a Terraform template for provisioning all required AWS resources to run ECS tasks.

Most of the resources are moved to a separate module named `infra`: https://github.com/it6y6en/ecs-infra

Application code is in the `app/` folder with a `Dockerfile`. A simple static web application runs with nginx.


## Usage (2 options):

### 1. Run terraform to provision everything including application deployment:

Uncomment `ecs-task._tf` and `image._tf` files. Build, deployments managed by terraform. To specify release version - create local `terraform.tfvars` with release, example:
```
release_version  = "1.0.0"
```

Run:
```
terraform init
terraform apply --auto-approve
```

### 2. Use terraform only for provisioning vpc, alb, ecs cluster. 

Run:
```
terraform init
terraform apply --auto-approve
```

Then expost output to json file: 
```
terraform output -json > infra.json
``` 

And build, deploy with script:
```
./deply_script.sh build 1.0.0

./deply_script.sh deploy 1.0.0
```

## URL
public url in terraform outputs: `dns_name`

## Security aspects:
- Alpine image to minimize attack surface
- ECS image scans can be enabled to analyze images for known threats and vulnerabilities
- ALB allows only HTTP incoming traffic (IP addresses whitelist can be provided with `.tfvars`)
- Containers run in private subnets. Only ingress HTTP traffic from ALB is allowed.
- Private subnets have no outbound internet access. Endpoints are used to access ECR and CloudWatch.
- Also, WAF can be set up on top of ALB to provide more security features.


#### Other usefull commande to see status of service and tasks definitions
```
aws ecs describe-services --cluster ecs-cluster --services hello-world-service

aws ecs delete-service --cluster ecs-cluster --service hello-world-service --force

aws ecs list-task-definitions --family-prefix hello-world-task --status INACTIVE
```


