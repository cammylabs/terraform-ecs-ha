# Configuring other providers
provider "archive" { version = "1.1" }
provider "local" { version = "~> 1.1" }
provider "external" { version = "1.0" }
provider "template" { version = "2.0" }

# Configure as an AWS project
provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 1.54"
}

# VPC
data "aws_vpc" "default" { id = "${var.vpc_id}" }
