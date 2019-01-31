#!/bin/sh
cd $(dirname $0)

#echo
#ARGS=$#
#for ((i=1;i<=ARGS;i++)); do
#    echo "$i - $(eval "echo \$${i}")"
#done
#exit 128

# VARIABLES
AWS_PROFILE="$1"; shift
IMAGE="$1"; shift
SERVICE="$1"; shift
CLUSTER="$1"; shift
TASK_DEF="$1"; shift
DOCKER_ROOT="$1"; shift
DEPLOY_APP="$1"; shift
DEPLOY_GRP="$1"; shift
DEPLOY_SPEC="$1"; shift

TMP_DIR="/tmp/$(basename $0).$$/"
FILE_TASK_DEF="$TMP_DIR/task-def.json"
FILE_DEPLOY_SPEC="$TMP_DIR/deploy-spec.json"

# ALIASES
aws="aws --profile ${AWS_PROFILE}"

# FUNCTIONS
create_tmp_files(){
  mkdir -p ${TMP_DIR}
  echo "$TASK_DEF" > ${FILE_TASK_DEF}
  echo "$DEPLOY_SPEC" > ${FILE_DEPLOY_SPEC}
}

clean_up(){
  rm -rf ${TMP_DIR}
}

docker_package(){
  docker build -t "${IMAGE}" ${DOCKER_ROOT}
}

docker_deploy(){
  $(aws ecr get-login --no-include-email)
  docker push "$IMAGE"
}

codedeploy_deploy(){
  aws ecs deploy \
    --service ${SERVICE} \
    --cluster ${CLUSTER} \
    --task-definition ${FILE_TASK_DEF} \
    --codedeploy-application ${DEPLOY_APP} \
    --codedeploy-deployment-group ${DEPLOY_GRP} \
    --codedeploy-appspec ${FILE_DEPLOY_SPEC}
}

# MAIN

create_tmp_files   || exit 1
docker_package    || (clean_up && exit 2)
docker_deploy     || (clean_up && exit 3)
codedeploy_deploy || (clean_up && exit 4)

clean_up