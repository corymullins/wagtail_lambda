# # Route 53 Alias record
# resource "aws_route53_record" "wagtail" {
#   zone_id = "Z01987103IENVQZ5BRYEA"
#   name    = "corymullins.com"
#   type    = "A"
#   alias {
#     name                   = aws_cloudfront_distribution.cf.domain_name
#     zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
#     evaluate_target_health = true
#   }
# }

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  ttl = 60
  type = each.value.type
  zone_id = "Z01987103IENVQZ5BRYEA"
}