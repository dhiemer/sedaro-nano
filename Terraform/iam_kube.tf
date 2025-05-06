##################################
# Kube IAM

resource "aws_iam_role" "kube" {
  name = "sedaro-kube-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}


##################################
# Kube Instance Profile
resource "aws_iam_instance_profile" "kube_profile" {
  name = "sedaro-kube-profile"
  role = aws_iam_role.kube.name
}

resource "aws_iam_role_policy_attachment" "node_ecr_ro" {
  role       = "sedaro-kube-role"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

##################################
# Kube Inline Policy
resource "aws_iam_policy" "kube_inline" {
  name   = "sedaro-kube-policy"
  policy = data.aws_iam_policy_document.kube_inline.json
}

data "aws_iam_policy_document" "kube_inline" {
  statement {
    sid    = "IAMAllow"
    effect = "Allow"
    actions = [
      "ec2:*",
      "ecr:*",
      "ssm:*",
      "ec2:*",
      "kms:*",
      "logs:*",
      "secretsmanager:*",
      "sts:*",
      "logs:*"
    ]
    resources = ["*"]
  }
}

##################################
# Policy Attachments

# Inline
resource "aws_iam_role_policy_attachment" "kube_policy_attachment" {
  role       = aws_iam_role.kube.name
  policy_arn = aws_iam_policy.kube_inline.arn
}

# AmazonSSMManagedInstanceCore
resource "aws_iam_role_policy_attachment" "kube_attach" {
  role       = aws_iam_role.kube.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


