output "asg_key_name" {
  value = aws_key_pair.generated_key.key_name
}
output "asg_private_key" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}
output "app_alb_dns" {
  value = aws_lb.app_alb.dns_name
}
output "web_alb_dns" {
  value = aws_lb.web_alb.dns_name
}