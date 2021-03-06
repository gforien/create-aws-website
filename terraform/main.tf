terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "default"
}

resource "aws_instance" "main" {
  ami             = "ami-0ed961fa828560210"
  instance_type   = "t2.micro"
  key_name        = var.key
  security_groups = [var.sg]
  user_data       = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install -y nginx1
    echo "<h1>${var.target}</h1>" > /usr/share/nginx/html
    sudo service nginx start
  EOF
}

resource "aws_route53_record" "main" {
  zone_id = var.zone
  name    = var.target
  type    = "CNAME"
  ttl     = 600
  records = [aws_instance.main.public_dns]
}

# (Note that variables should be declared in file variables.tf)
variable "key" {
  type        = string
  description = "A pre-existing SSH key for EC2 instances"
  default     = ""                                            # default can be empty
}
variable "sg" {
  type        = string
  description = "A pre-existing security group"
  default     = ""                                            # default can be empty
}
variable "zone" {
  type        = string
  description = "A pre-existing DNS zone in Route53"
  default     = ""
}
variable "target" {
  type        = string
  description = "The subdomain to be created"
  default     = ""
}
