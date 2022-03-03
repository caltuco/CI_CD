locals {
        config_vars = read_terragrunt_config("config.hcl")
}


inputs = local.config_vars.locals


generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
  provider "aws" {
    region = "${local.config_vars.locals.region}"
}
EOF
}

generate "version" {
  path      = "version.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
  terraform {
    required_version = ">= 0.14"
    required_providers {
      aws = {
        source  = "hashicorp/aws"
            version = "~> 3.0"
      }
    }
  }
EOF
}



# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend  = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config   = {
    bucket         = "${local.config_vars.locals.prefix}-remote-state"
    dynamodb_table = "${local.config_vars.locals.prefix}-remote-state-lock"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.config_vars.locals.region}"
    profile        = "${local.config_vars.locals.aws_profile}"
    encrypt        = true
  }
}
