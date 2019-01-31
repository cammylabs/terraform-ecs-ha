# terraform-ecs-ha
This is a custom terraform module designed to provide easy _zero downtime deployment_ using Docker images and AWS ECS.

## Basic usage
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
}
```

## Architecture Overview
`TODO`

## Deployment Overview
`TODO`

