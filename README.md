<h3>This Terraform configuration sets up a secure environment for a database server on AWS. It includes creating a security group, an EBS volume, an EC2 instance, and attaching the EBS volume to the EC2 instance.</h3>

<h4>Components</h4>
<h4>Security Group (dbserversg)</h4>: Manages inbound HTTP (port 80) and SSH (port 22) traffic, and allows all outbound traffic.<br>
<h4>EBS Volume (databasevolume):</h4> Provides persistent storage for the database, with size defined by VolumeSize variable.<br>
<h4>EC2 Instance (dbserver):</h4> Configured with a specific AMI, availability zone, instance type, key pair, and security group.<br>
<h4>Volume Attachment (dbserver_attach):</h4> Attaches the EBS volume to the EC2 instance at /dev/sdh.<br>
<h4>Tags</h4>
Each resource is tagged for easy identification and management.<br>
