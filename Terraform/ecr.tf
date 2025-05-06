# Define local variables with repository settings
locals {
  ecr_repositories = {
    web = {
      name                 = "sedaro-web"
      expire_untagged_days = 5
      max_image_count      = 7
    },
    app = {
      name                 = "sedaro-app"
      expire_untagged_days = 5
      max_image_count      = 7
    }
    
  }


}

# Create ECR repositories using for_each
resource "aws_ecr_repository" "repos" {
  for_each = local.ecr_repositories

  name                 = each.value.name
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
}




# Create lifecycle policies for each repository
resource "aws_ecr_lifecycle_policy" "policies" {
  for_each = local.ecr_repositories

  repository = aws_ecr_repository.repos[each.key].name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than ${each.value.expire_untagged_days} days"
        selection = {
          tagStatus     = "untagged"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = each.value.expire_untagged_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${each.value.max_image_count} images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = each.value.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}


