output "public_ip" {
  description = "Public IP of the app server"
  value       = aws_eip.app.public_ip
}

output "app_url" {
  description = "URL to reach the deployed app"
  value       = "http://${aws_eip.app.public_ip}"
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ${var.project_name}-deployer.pem ec2-user@${aws_eip.app.public_ip}"
}

output "db_password" {
  description = "Auto-generated Postgres password"
  value       = random_password.db.result
  sensitive   = true
}
