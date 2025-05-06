variable "github_owner" {
  description = "GitHub Personal Access Token with 'repo' and 'admin:repo_hook' permissions"
  default   = "dhiemer"
}



# 
# variable "aws_region" {
#   description = "GitHub Personal Access Token with 'repo' and 'admin:repo_hook' permissions"
#   default   = "dhiemer"
# }
# 
# variable "az_preference" {
#   description = "Choose which AZ to use (primary or secondary)"
#   type        = string
#   default     = "primary"
# }
# 
# 
# variable "aws_az_primary" {
#   description = "Primary AZ to build"
#   default   = "us-east-1a"
# }
# 
# variable "aws_az_secondary" {
#   description = "Secondary AZ to build"
#   default   = "us-east-1b"
# }
# 
# 
# 
# locals {
#   availability_zone = var.az_preference == "primary" ? var.aws_az_primary : var.aws_az_secondary
# }
# 


#########################################

# having a bit of fun here...

variable "region_preference" {
  description = "Choose which region to use (primary or secondary)"
  type        = string
  default     = "primary"
  validation {
    condition     = contains(["primary", "secondary"], var.region_preference)
    error_message = "Must be 'primary' or 'secondary'"
  }
}

variable "az_preference" {
  description = "Choose which AZ to use (primary or secondary)"
  type        = string
  default     = "primary"
  validation {
    condition     = contains(["primary", "secondary"], var.az_preference)
    error_message = "Must be 'primary' or 'secondary'"
  }
}

variable "aws_region_primary" {
  description = "Primary AWS region"
  default     = "us-east-1"
}

variable "aws_region_secondary" {
  description = "Secondary AWS region"
  default     = "us-west-2"
}

variable "aws_azs_primary" {
  description = "Primary region AZs"
  type        = map(string)
  default = {
    primary   = "us-east-1a"
    secondary = "us-east-1b"
  }
}

variable "aws_azs_secondary" {
  description = "Secondary region AZs"
  type        = map(string)
  default = {
    primary   = "us-west-2a"
    secondary = "us-west-2b"
  }
}



locals {
  aws_region = var.region_preference == "primary" ? var.aws_region_primary : var.aws_region_secondary

  availability_zone = (
    var.region_preference == "primary"
    ? var.aws_azs_primary[var.az_preference]
    : var.aws_azs_secondary[var.az_preference]
  )
}

