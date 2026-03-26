# EC2 Instance Outputs
output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.app.public_ip
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.app_server.private_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

# Security Group Outputs
output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.app.id
}

# SSH Connection Info
output "ssh_connection" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i <your-private-key> ubuntu@${aws_eip.app.public_ip}"
}