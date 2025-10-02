# Simple ECS web application

## Prerequisits:

- AWS account
- aws cli installed.
- terraform
- jq

## Architecture:

- AWS VPC
- Public subnets with ALB
- Private subnets with VPC endpoints
- ECS tasks run in private subnets

Repository contains terraform template for provisioning all required aws resources to run ECS tasks. 

Most of the resources moved to separate 'infra' module: https://github.com/it6y6en/ecs-infra

Application code in `app/` folder with `Dockerfile`. Simple static wep application runs with nginx.

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
- No NAT and routes to the internet from private subnets. Endpoints are used to access ECR and CloudWatch.
- Also, WAF can be set up on top of ALB to provide more security features.


#### Other usefull commande to see status of service and tasks definitions
```
aws ecs describe-services --cluster ecs-cluster --services hello-world-service

aws ecs delete-service --cluster ecs-cluster --service hello-world-service --force

aws ecs list-task-definitions --family-prefix hello-world-task --status INACTIVE
```


