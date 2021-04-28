resource "aws_s3_bucket" "website" {
  bucket = "${var.myPanda}.devopsplayground.org"
  acl    = "public-read"

  tags = {
    ManagedBy = "terraform"
  }
  website {
    index_document = "index.html"
  }
}
resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "./content/index.html"
  acl          = "public-read"
  content_type = "text/html"
}
resource "aws_s3_bucket_object" "image" {
  bucket       = aws_s3_bucket.website.id
  key          = "image.jpeg"
  source       = "./content/image.jpeg"
  acl          = "public-read"
  content_type = "image/jpeg"
}
data "aws_route53_zone" "main" {
  name         = "devopsplayground.org"
  private_zone = false
}
resource "aws_route53_record" "link" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.myPanda
  type    = "CNAME"
  ttl     = "300"

  records = [aws_s3_bucket.website.website_endpoint]
}