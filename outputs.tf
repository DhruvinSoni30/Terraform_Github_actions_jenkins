# Getting VPC ID
output "vpc_id" {
  value = aws_vpc.demo_vpc.id
}

# Getting Subnet ID
output "subnet_id" {
  value = aws_subnet.demo_subnet.id
}

# Getting Public IP of EC2 instance
output "public_IP" {
  value = aws_instance.demo_instance.public_ip
}