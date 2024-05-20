terraform {
  backend "s3" {
    bucket = "shiva-s3-tfstate"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.49.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

# Create VPC
resource "aws_vpc" "awsvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Myvpc"
  }
}

# Create Subnets
resource "aws_subnet" "subnet_1a" {
  vpc_id            = aws_vpc.awsvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Main1a"
  }
}

resource "aws_subnet" "subnet_1b" {
  vpc_id            = aws_vpc.awsvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Main1b"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "internetgateway" {
  vpc_id = aws_vpc.awsvpc.id
  tags = {
    Name = "internetgateway"
  }
}

# Create Route Table and Route
resource "aws_route_table" "routingtable" {
  vpc_id = aws_vpc.awsvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetgateway.id
  }

  tags = {
    Name = "routingtable"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "routetableassoc_1a" {
  subnet_id      = aws_subnet.subnet_1a.id
  route_table_id = aws_route_table.routingtable.id
}

resource "aws_route_table_association" "routetableassoc_1b" {
  subnet_id      = aws_subnet.subnet_1b.id
  route_table_id = aws_route_table.routingtable.id
}

# Create Security Group for Web Server
resource "aws_security_group" "webserver_sg" {
  name        = "webserver_sg"
  description = "Allow inbound HTTP and SSH traffic, and all outbound traffic"
  vpc_id      = aws_vpc.awsvpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webserver_sg"
  }
}

# Create EBS Volume
resource "aws_ebs_volume" "webserver_volume" {
  availability_zone = "ap-south-1a"
  size              = 1
  tags = {
    Name = "Webserver01_storage"
  }
}

# Create EC2 Instance
resource "aws_instance" "webserver01" {
  ami                    = "ami-0cc9838aa7ab1dce7"
  availability_zone      = "ap-south-1a"
  instance_type          = "t2.micro"
  key_name               = "vv"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  subnet_id              = aws_subnet.subnet_1a.id
  tags = {
    Name = "Webserver01"
  }
}

# Attach EBS Volume to EC2 Instance
resource "aws_volume_attachment" "webserver_attach" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.webserver_volume.id
  instance_id = aws_instance.webserver01.id
}

# Create Load Balancer Security Group
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.awsvpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb_sg"
  }
}

# Create Target Group
resource "aws_lb_target_group" "target_group" {
  name     = "targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.awsvpc.id
}

# Attach Target Group to EC2 Instance
resource "aws_lb_target_group_attachment" "target_group_attach" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.webserver01.id
  port             = 80
}

# Create Load Balancer
resource "aws_lb" "load_balancer" {
  name               = "loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.subnet_1a.id, aws_subnet.subnet_1b.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# Create Load Balancer Listener
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Define a Launch Template
resource "aws_launch_template" "aws_launch" {
  name_prefix   = "aws_launch"
  image_id      = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  key_name      = "vv"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.webserver_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "aws_launch"
    }
  }
}

variable "asgmin" {
  type    = string
  default = "1"
}

variable "asgmax" {
  type    = string
  default = "2"
}

variable "asgDesired" {
  type    = string
  default = "1"
}

# Create an Auto-Scaling Group
resource "aws_autoscaling_group" "autoscaling" {
  desired_capacity    = var.asgDesired
  max_size            = var.asgmax
  min_size            = var.asgmin
  vpc_zone_identifier = [aws_subnet.subnet_1a.id, aws_subnet.subnet_1b.id]

  launch_template {
    id      = aws_launch_template.aws_launch.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.target_group.arn]

  tag {
    key                 = "Name"
    value               = "AutoScalingGroup"
    propagate_at_launch = true
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "autoscalingattach" {
  autoscaling_group_name = aws_autoscaling_group.autoscaling.id
  lb_target_group_arn    = aws_lb_target_group.target_group.arn
}
