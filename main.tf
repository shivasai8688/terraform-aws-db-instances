# Create Security Group for DB Server
resource "aws_security_group" "dbserversg" {
  name        = "dbserver_sg"
  description = "Allow inbound HTTP and SSH traffic, and all outbound traffic"

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
    Name = "dbserver_sg"
  }
}

# Create EBS Volume
resource "aws_ebs_volume" "databasevolume" {
  availability_zone = "ap-south-1a"
  size              = "${var.VolumeSize}"
  tags = {
    Name = "databasevolume"
  }
}

# Create EC2 Instance for DB Server
resource "aws_instance" "dbserver" {
  ami                    = "ami-0cc9838aa7ab1dce7"
  availability_zone      = "${var.InstanceZone}"
  instance_type          = "${var.Machinetype}"
  key_name               = "${var.keyname}"
  security_groups        = [aws_security_group.dbserversg.name]
  tags = {
    Name = "dbserver"
  }
}

# Attach EBS Volume to EC2 Instance
resource "aws_volume_attachment" "dbserver_attach" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.databasevolume.id
  instance_id = aws_instance.dbserver.id
}
