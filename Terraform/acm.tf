#############################################################################################################################################
# Note: This is already provisoned in my personal IaC. I will instead provide a data block to use this cert rather than create it here
#############################################################################################################################################
#
# resource "aws_acm_certificate" "wildcard" {
#   domain_name               = "*.daveops.pro"
#   validation_method         = "DNS"
#   subject_alternative_names = ["daveops.pro"]
# 
# 
#   lifecycle {
#     create_before_destroy = true
#   }
# }
# 
# variable "env_tier" {
#   default = "prod"
#   type    = string
# }
# 
# 
# 
# resource "aws_route53_record" "wildcard_validation_prod" {
#   for_each = (
#     var.env_tier == "prod" ?
#     {
#       for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
#         name   = dvo.resource_record_name
#         record = dvo.resource_record_value
#         type   = dvo.resource_record_type
#       }
#   } : {})
# 
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60 * 10
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.main.zone_id
# }
# 


data "aws_acm_certificate" "wildcard" {
  domain   = "*.daveops.pro"
  types    = ["AMAZON_ISSUED"]
  most_recent = true
}
