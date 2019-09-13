#!/usr/bin/env bash
DIR=$(dirname $0)

if [ ! -f ${DIR}/deploy.conf ]; then
    echo "Deployment not configured. Have you tried rerun terraform module again?"
    exit 2
else
    . ${DIR}/deploy.conf
fi

## FUNCTIONS
docker_package(){
  echo "Building Docker image ${DOCKER_IMAGE}..."
  docker build -t "${DOCKER_IMAGE}" ${DOCKER_FOLDER}
}

docker_deploy(){
  echo "Pushing Docker image ${DOCKER_IMAGE}..."
  $(aws ecr get-login --no-include-email)
  docker push "${DOCKER_IMAGE}"
}

codedeploy_deploy(){
  echo "Notifying CodeDeploy about the new software revision..."
  aws ecs deploy \
    --service ${ECS_SERVICE} \
    --cluster ${ECS_CLUSTER} \
    --task-definition "${ECS_FILE_TASK_DEF}" \
    --codedeploy-application ${ECS_DEPLOY_APP} \
    --codedeploy-deployment-group ${ECS_DEPLOY_GRP} \
    --codedeploy-appspec "${ECS_FILE_DEPLOY_SPEC}"
}

## VARIABLES
AWS_PROFILE=${AWS_PROFILE?"Not defined"}
AWS_REGION=${AWS_REGION?"Not defined"}
DOCKER_FOLDER=${DOCKER_FOLDER?"Not defined"}
DOCKER_IMAGE=${DOCKER_IMAGE?"Not defined"}
ECS_SERVICE=${ECS_SERVICE?"Not defined"}
ECS_CLUSTER=${ECS_CLUSTER?"Not defined"}
ECS_DEPLOY_APP=${ECS_DEPLOY_APP?"Not defined"}
ECS_DEPLOY_GRP=${ECS_DEPLOY_GRP?"Not defined"}
ECS_FILE_TASK_DEF=${ECS_FILE_TASK_DEF?"Not defined"}
ECS_FILE_DEPLOY_SPEC=${ECS_FILE_DEPLOY_SPEC?"Not defined"}

## ALIASES
alias aws="aws --profile ${AWS_PROFILE} --region ${AWS_REGION}"

docker_package && \
  docker_deploy && \
  codedeploy_deploy ||
  exit 3
