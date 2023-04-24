# AWS VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.tenancy
  enable_dns_hostnames = true

  tags = {
    "Name" = "${var.name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "demo_gateway" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    "Name" = "${var.name}-igw"
  }
}

# AZ
data "aws_availability_zones" "az" {}

# AWS Subnet
resource "aws_subnet" "demo_subnet" {
  vpc_id                          = aws_vpc.demo_vpc.id
  cidr_block  = var.cidr_block_subnet
  availability_zone    = data.aws_availability_zones.az.names[0]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.name}-subnet"
  }
}

# AWS Route Table
resource "aws_route_table" "demo_route_table" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_gateway.id
  }

  tags = {
    "Name" = "${var.name}-route"
  }
}

# Associate public subnet to route table
resource "aws_route_table_association" "demo_association" {
  subnet_id      = aws_subnet.demo_subnet.id
  route_table_id = aws_route_table.demo_route_table.id
}

# Creating Security Group
resource "aws_security_group" "demosg" {
  name   = "Demo Security Group"
  vpc_id = aws_vpc.demo_vpc.id

  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating key pair
resource "aws_key_pair" "demokey" {
  key_name   = var.key_name
  public_key = file(var.public_key)
}


# Creating AWS Instance
resource "aws_instance" "demo_instance" {

  ami                    = var.ami_id
  instance_type          = var.instance_type
  availability_zone      = data.aws_availability_zones.az.names[0]
  subnet_id              = aws_subnet.demo_subnet.id
  key_name               = aws_key_pair.demokey.id
  vpc_security_group_ids = [aws_security_group.demosg.id]

  tags = {
    "Name" = "${var.name}-instance"
  }

  # SSH into instance 
  connection {
    # The default username for our AMI
    user = "ec2-user"
    # Private key for connection
    private_key = file(var.private_key)
    # Type of connection
    type = "ssh"
    # Host
    host = self.public_ip

  }

  # Installing splunk & creating distributed indexer clustering on newly created instance
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo chkconfig docker on",
      "sudo yum install -y git",
      "sudo chmod 666 /var/run/docker.sock",
      "docker pull dhruvin30/dhsoniweb:v1",
      "docker run -d -p 80:80 dhruvin30/dhsoniweb:v1"
    ]
  }

}
