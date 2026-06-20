output "frontend_url" {
  description = "Game Portal frontend URL (S3 static website)"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "alb_dns_name" {
  description = "ALB DNS name (API endpoint)"
  value       = aws_lb.main.dns_name
}

output "game_build_url" {
  description = "Direct URL to download the game build"
  value       = "https://${aws_s3_bucket.game_builds.bucket}.s3.amazonaws.com/game-v1.0.zip"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.address
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.api.name
}

output "frontend_bucket" {
  description = "Frontend S3 bucket name"
  value       = aws_s3_bucket.frontend.bucket
}
