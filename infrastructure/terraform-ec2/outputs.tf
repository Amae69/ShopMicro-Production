output "master_public_ip" {
  description = "Public IP address of the Kubernetes master node"
  value       = aws_instance.master.public_ip
}

output "worker-frontend_public_ip" {
  description = "Public IP address of the Kubernetes worker node"
  value       = aws_instance.worker-frontend.public_ip
}

output "worker-backend_public_ip" {
  description = "Public IP address of the Kubernetes worker node"
  value       = aws_instance.worker-backend.public_ip
}

output "vpc_id" {
  value = aws_vpc.main.id
}
