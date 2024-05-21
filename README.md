<h1>This Terraform configuration sets up a secure environment for a database server on AWS. It includes creating a security group, an EBS volume, an EC2 instance, and attaching the EBS volume to the EC2 instance.</h1>

Components
Security Group (dbserversg): Manages inbound HTTP (port 80) and SSH (port 22) traffic, and allows all outbound traffic.
EBS Volume (databasevolume): Provides persistent storage for the database, with size defined by VolumeSize variable.
EC2 Instance (dbserver): Configured with a specific AMI, availability zone, instance type, key pair, and security group.
Volume Attachment (dbserver_attach): Attaches the EBS volume to the EC2 instance at /dev/sdh.
Tags
Each resource is tagged for easy identification and management.
