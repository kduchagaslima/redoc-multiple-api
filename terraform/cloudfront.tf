
# 🌍 Política pública para permitir leitura pelo CloudFront
resource "aws_s3_bucket_policy" "openapi_policy" {
  bucket = aws_s3_bucket.app_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject","s3:ListBucket"]
        Resource = ["${aws_s3_bucket.app_bucket.arn}/*","${aws_s3_bucket.app_bucket.arn}"]
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_cloudfront_distribution.openapi_cdn.arn 
          }
        }
      },
      {
        Effect   = "Deny"
        Principal = "*"
        Action   = "*"
        Resource = ["${aws_s3_bucket.app_bucket.arn}/*","${aws_s3_bucket.app_bucket.arn}"]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# 📌 Criando a CloudFront Origin Access Control (OAC) para acesso seguro ao S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-openapi"
  description                       = "Acesso do CloudFront ao S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 🚀 Criando a Distribuição CloudFront
resource "aws_cloudfront_distribution" "openapi_cdn" {
  origin {
    domain_name              = aws_s3_bucket.app_bucket.bucket_regional_domain_name
    origin_id                = "S3-Origin-OpenAPI"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  # 💾 Configuração do Cache
  default_cache_behavior {
    target_origin_id       = "S3-Origin-OpenAPI"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # 🌎 Configuração de Visualização
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # 🔒 SSL com HTTPS
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 🔗 Exibindo a URL do CloudFront
output "cloudfront_url" {
  value = aws_cloudfront_distribution.openapi_cdn.domain_name
  description = "URL do CloudFront para acessar a página OpenAPI"
}
