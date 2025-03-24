resource "aws_s3_bucket" "app_bucket" {
  bucket = "littlecharlie-api-catalog"

  tags = {
    Name        = "littlecharlie-api-catalog"
    Environment = "Dev"
    Management = "Terraform"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "openapi_bucket_cors" {
  bucket = aws_s3_bucket.app_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = [
      "https://${aws_cloudfront_distribution.openapi_cdn.domain_name}"  # Substitua pelo seu domínio CloudFront
    ]
    expose_headers  = []
    max_age_seconds = 3000
  }
}