output "public_ip" {
  value = aws_eip.app.public_ip
}

output "app_url" {
  value = "http://${aws_eip.app.public_ip}"
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/telemetryhub-tf ubuntu@${aws_eip.app.public_ip}"
}

output "instance_id" {
  value = aws_instance.app.id
}

output "github_deploy_role_arn" {
  value = aws_iam_role.github_deploy.arn
}