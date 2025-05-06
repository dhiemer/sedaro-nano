data "aws_caller_identity" "current" {}


# Get Github Runner Registration Token
data "github_actions_registration_token" "runner" {
  repository = "sedaro-demo"
}


# Data source to retrieve the SecureString parameter
data "aws_ssm_parameter" "secret" {
  name            = "/DaveCICD"
  with_decryption = true 
}

