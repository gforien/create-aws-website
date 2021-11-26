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
    sudo service nginx start
    echo '<h1>gforien.com</h1>' > /usr/share/nginx/html
  EOF
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
