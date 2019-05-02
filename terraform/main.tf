provider "aws" {
  region = "ap-northeast-2"
}
# creating VPC

resource "aws_vpc" "vpc_avinash" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "Avinash VPC"
    BuildWith = "terraform"
  }
}

# adding public subnet

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${ aws_vpc.vpc_avinash.id }"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name      = "Public Subnet"
    BuildWith = "terraform"
  }
}

# adding internet gateway for external communication

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${ aws_vpc.vpc_avinash.id }"

  tags = {
    Name      = "Internet Gateway"
    BuildWith = "terraform"
  }
}

# create external route to IGW

resource "aws_route" "external_route" {
  route_table_id         = "${ aws_vpc.vpc_avinash.main_route_table_id }"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${ aws_internet_gateway.internet_gateway.id }"
}

# associate subnet public to public route table

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = "${ aws_subnet.public_subnet.id }"
  route_table_id = "${ aws_vpc.vpc_avinash.main_route_table_id }"
}



# Private key variable

variable "private_key" {
  default = "/Users/avinash/work/keys/avinash-test1.pem"
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${ aws_vpc.vpc_avinash.id }"
}


variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default=8080
}



# Creating an EC2 instance

resource "aws_instance" "example" {
  ami = "ami-067c32f3d5b9ace91"
  instance_type = "t2.micro"
  key_name = "avinash-test1"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  associate_public_ip_address = true
  subnet_id = "${ aws_subnet.public_subnet.id }"
  provisioner "remote-exec" {
    inline = ["sudo apt-get -qq install python -y"]
  }
  connection {
    private_key = "${file(var.private_key)}"
    user        = "ubuntu"
  }
  tags {
    Name = "terraform-test"
  }
}



output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}


terraform {
  backend "s3" {
    bucket = "test-avinash-tfstate"
    key    = "tfstate"
    region = "ap-northeast-2"
  }
}
