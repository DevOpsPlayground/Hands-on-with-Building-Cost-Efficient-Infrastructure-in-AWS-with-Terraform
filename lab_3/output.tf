output "website_url" {
  value = aws_s3_bucket.website.website_endpoint
}
output "route53_record" {
  value = aws_route53_record.link.fqdn
}