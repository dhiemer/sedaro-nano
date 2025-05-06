
### Note: This was already created in my account. I have put a data resouce block below to use the existing resource

# ###############################################################################
# # GitHub OIDC provider
# ###############################################################################
# resource "aws_iam_openid_connect_provider" "github" {
#   url = "https://token.actions.githubusercontent.com"
# 
#   client_id_list = [
#     "sts.amazonaws.com",
#     "https://github.com/dhiemer"
#   ]
# 
#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
# 
#   tags = {
#     env = "DaveOps"
#     iac = "true"
#   }
# }
# 
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}




###############################################################################
#  role that the workflow assumes
###############################################################################
data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]  # TODO: remove "data." if not exists
    }

    # All dhiemer projects
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        "repo:dhiemer/*"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = [
        "sts.amazonaws.com",
        "https://github.com/dhiemer"
      ]
    }
  }
}


resource "aws_iam_role" "github_actions" {
  name               = "sedaro_github_actions"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
  tags = {
    Name = ""
    env  = "sedaro"
    iac  = "true"
  }
}

resource "aws_iam_role_policy" "github_actions_inline" {
  name = "sedaro_github_actions-inline"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}
