#!/usr/bin/env bash
set -euo pipefail 
set -x

CONFIG_FILE="infra.json"
ACTION=${1:-}
RELEASE_VERSION=${2:-}

if [[ -z "$ACTION" || -z "$RELEASE_VERSION" ]]; then
  echo "Usage: $0 {build|deploy} <release-version>"
  exit 1
fi

# Read values from infra.json config (JSON)
# to generate it run:
# terraform output -json > infra.json
get_config() {
  jq -r ".$1.value" "$CONFIG_FILE"
}

AWS_REGION=$(get_config region 2>/dev/null || echo "us-east-1")
ECR_REPO=$(get_config ecr_repository_url)
CLUSTER=$(get_config ecs_cluster_name)
SERVICE=$(get_config ecs_service_name)
TASK_FAMILY=$(get_config ecs_task_family)
EXEC_ROLE=$(get_config ecs_execution_role_arn)
TASK_ROLE=$(get_config ecs_task_role_arn)
SUBNETS=$(get_config subnet_ids | jq -r 'join(",")')
SG=$(get_config security_group_id)
TG_ARN=$(get_config lb_target_group_arn)

IMAGE_TAG="$RELEASE_VERSION"
IMAGE_URI="${ECR_REPO}:${IMAGE_TAG}"

build() {
docker build -t "$IMAGE_URI" ./app
if ! docker system info | grep -q "$ECR_REPO"; then
  aws ecr get-login-password --region "$AWS_REGION" \
    | docker login --username AWS --password-stdin "${ECR_REPO%/*}"
fi
docker push "$IMAGE_URI"
}

deploy() {
echo "Registering new task definition..."  
TASKDEF_FILE=$(mktemp)
cat > "$TASKDEF_FILE" <<EOF
{
  "family": "${TASK_FAMILY}",
  "networkMode": "awsvpc",
  "executionRoleArn": "${EXEC_ROLE}",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "hello-world",
      "image": "${IMAGE_URI}",
      "portMappings": [
        { "containerPort": 80, "hostPort": 80, "protocol": "tcp" }
      ],
      "essential": true
    }
  ]
}
EOF

REVISION=$(aws ecs register-task-definition \
  --cli-input-json file://"$TASKDEF_FILE" \
  --query taskDefinition.revision \
  --output text)

if aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
      --query 'services[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
  echo "Updating existing service..."
  aws ecs update-service \
    --cluster "$CLUSTER" \
    --service "$SERVICE" \
    --task-definition "$TASK_FAMILY:$REVISION" \
    --force-new-deployment
else
  echo "Creating new service..."
  aws ecs create-service \
    --cluster "$CLUSTER" \
    --service-name "$SERVICE" \
    --task-definition "$TASK_FAMILY:$REVISION" \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SG],assignPublicIp=DISABLED}" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=hello-world,containerPort=80"
fi
}

case "$ACTION" in
  build) build ;;
  deploy) deploy ;;
  *) echo "Unknown action: $ACTION"; exit 1 ;;
esac
