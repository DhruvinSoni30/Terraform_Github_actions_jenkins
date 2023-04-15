# Provider name
provider "aws" {
  region = var.region
}

# Storing state file on S3 backend
terraform {
  backend "s3" {
    bucket = "tf-state-dhsoni"
    region = "us-west-2"
    key    = "terraform.tfstate"
  }
}
