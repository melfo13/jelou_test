# Load balancer output removed - using single instance deployment

output "instance_public_ip" {
  description = "IP pública de la instancia EC2"
  value       = aws_instance.user_service_instance.public_ip
}

output "instance_public_dns" {
  description = "DNS público de la instancia EC2"
  value       = aws_instance.user_service_instance.public_dns
}

output "elastic_ip" {
  description = "Elastic IP asignada (si está habilitada)"
  value       = var.use_elastic_ip ? aws_eip.user_service_eip[0].public_ip : null
}

output "application_url" {
  description = "URL de la aplicación"
  value       = var.use_elastic_ip ? "http://${aws_eip.user_service_eip[0].public_ip}:3000" : "http://${aws_instance.user_service_instance.public_ip}:3000"
}

output "ssh_connection" {
  description = "Comando para conectarse por SSH"
  value       = var.use_elastic_ip ? "ssh -i ~/.ssh/user-microservice-key.pem ec2-user@${aws_eip.user_service_eip[0].public_ip}" : "ssh -i ~/.ssh/user-microservice-key.pem ec2-user@${aws_instance.user_service_instance.public_ip}"
}

output "security_group_id" {
  description = "ID del Security Group de la aplicación"
  value       = aws_security_group.user_service_sg.id
}

output "key_pair_name" {
  description = "Nombre del Key Pair creado"
  value       = aws_key_pair.user_service_key.key_name
}

output "cloudwatch_log_group" {
  description = "Nombre del CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.user_service_logs.name
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.user_service_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.user_service_vpc.cidr_block
}

output "public_subnet_id" {
  description = "ID de la subnet pública"
  value       = aws_subnet.user_service_public_subnet.id
}

output "private_subnet_id" {
  description = "ID de la subnet privada"
  value       = aws_subnet.user_service_private_subnet.id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.user_service_igw.id
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.user_service_repo.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.user_service_repo.name
}

output "ecr_registry_id" {
  description = "ECR registry ID"
  value       = aws_ecr_repository.user_service_repo.registry_id
}

output "github_ci_access_key_id" {
  description = "GitHub CI IAM user access key ID"
  value       = aws_iam_access_key.github_ci.id
  sensitive   = true
}

output "github_ci_secret_access_key" {
  description = "GitHub CI IAM user secret access key"
  value       = aws_iam_access_key.github_ci.secret
  sensitive   = true
}