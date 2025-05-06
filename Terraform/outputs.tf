

# Outputs
output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}



# Output the ECR repository URLs
output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for repo_key, repo in aws_ecr_repository.repos : 
      repo_key => repo.repository_url
  }
}



# Region
output "aws_region" {
  value = local.aws_region
}

# AZs
output "availability_zone" {
  value = local.aws_region
}


