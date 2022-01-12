# terraform-ecs-ha
This is a custom terraform module designed to provide easy _zero downtime deployment_ using Docker images and AWS ECS.

## Basic usage
To get started with module you have to use it as a terraform module on your project.
```hlc
module "terraform-ecs-ha" {
  source = "git@github.com:cammylabs/terraform-ecs-ha.git"

  // Basic App Details
  app_name = "sample-app"
  app_version = "${format("1.0.0-%s", uuid())}"
  docker_root_path = "${path.root}/../output/application"

  // AWS configuration
  aws_profile = "${var.aws_profile}"
  aws_region  = "${var.aws_region}"

  // Network configuration
  vpc_id = "${data.aws_vpc.staging2.id}"
  vpc_subnet_ids = ["${data.aws_subnet_ids.staging2.ids}"]

  route53_zone_id = "${data.aws_route53_zone.domain.zone_id}"
  acm_certificate_arn = "${data.aws_acm_certificate.wildcard.arn}"

  // ECS
  ecs_friendly_dns = "${var.dns_domain}"

  slack_webhook_codedeploy = var.slack_webhook_codedeploy 
}
```
As described in the below topics, although most of the required AWS resources are automatically created by this module, you
should provide some required params in order to use it.
- `aws_profile` - The AWS CLI's profile that will be used to run the deployment
- `aws_region` - The AWS Region that will be used to run the deployment
- `vpc_id` - The VPC Id the AWS resources will be attached to
- `vpc_subnet_ids` - The network subnets this architecture will be running
- `route53_zone_id` - The Route53's Zone Id in which an `A Record` will point to the Load Balancer
- `acm_certificate_arn` - The ACM certificate ARN to be used in the ALB's Target Group Listener
- `ecs_friendly_dns` - A human friendly DNS entry that will point to the Load Balancer

Aside from them, you should also provide:
- `app_name` - An identifier for this project. It should be unique once it will be used as prefix for AWS resources
- `app_version` - A unique version identifier for the application that will be deployed. Whenever this version changes, a new deployment will be automatically triggered.
- `docker_root_path` - The root folder to generate the Docker image. Usually the place where Dockerfile is located.
- `slack_webhook_codedeploy` - Slack generated webhook that will accept codedeploy deployment messages 

Below the remaining parameters that can be optionally configured:
- `app_environment` (default: `staging`) - An identifier for the environment this project is running on. (e.g.: production, staging, etc)
- `ecs_port` (default: `8080`) - The TCP/HTTP(S) port which the software is exposed inside the container.
- `ecs_protocol` (default: `HTTP`) - The protocol in which Target Groups will communicate with the instances. [HTTP/HTTPS/TCP]
- `ecs_cpu` (default: `256`) - Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)
- `ecs_memory` (default: `512`) - Fargate instance memory to provision (in MiB)
- `ecs_task_definition` (default: '') - ECS Fargate task definition file. If defined it will overwrite other ecs_* values.
- `ecs_app_spec` (default: '') - The CodeDeploy AppSpec file. If defined it will overwrite other ecs_* values..

## Architecture Overview
This module leverages the following architecture in order to provide a reliable and easy to maintain runtime environment for your microservices.
![zero downtime architecture - aws fargate and aws codedeploy-2](https://user-images.githubusercontent.com/521936/52188671-387ead00-2888-11e9-9bdc-f64a2f13c490.png)

#### Main goals
- (Almost) zero server maintance in order to build and deploy new versions of an specific service
- Zero Downtime deployment
- Automatic rollback in case of failure
- Least possible dependency on third-party tools (relies mostly on AWS)
- Easy to reproduce/duplicate configuration

#### How it works?
This module expects that you have an application properly configured as Docker image, ready to be deployed into a Docker register. It will take care of:
1. Creating a new AWS ECR's Docker Registry for your new service
1. Spinning up an AWS ECS cluster
1. Regiter all tasks behind an AWS Application Load Balancer
1. Configure an Auto Scaling Group for your service
1. Create an `A Record` pointing your ALB on your AWS Route53 hosted zone.

In order to leverage Zero Downtime deployment, it leans on a Blue Green deployment structure backed by AWS CodeDeploy and AWS Application Load Balancer. By looking to the green _sequence flows_ in the above picture you'll see how requests are handled by the server. Basically:
1. Resolve the microservice's Load Balance FQDNS.
2. Points the request to the Load Balacer.
3. The Load Balancer pick an instance from the active (blue or green) Target Group to actually handle the request.

During a deployment, as we can see in the purple _sequence flows_, AWS CodeDeploy and AWS Application Load Balancer interact
each other, ensuring that the traffic is re-routed from the blue to the green Target Group after a successful deployment.
1. Upload your new Docker image into the ECR.
2. Create and Deploy a task using your just uploaded ECR, and notify AWS CodeDeploy to start the deployment it self.
3. AWS CodeDeploy will notify AWS ECS in order to spin up instances as defined on your task file.
4. Once the tasks are running, all instances are registered into the green Target Group. If the health-check fails during the startup, the deployment is discarded and the instances are terminated.
5. AWS CodeDeploy will re-route all traffic to the new deployed instances, while previous instances will have their connections gracefully drained - ensuring all request were finished before destroy them.
