# CloudFront 배포 설정
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    # S3 웹사이트 엔드포인트를 도메인으로 사용
    domain_name = aws_s3_bucket_website_configuration.test.website_endpoint
    origin_id   = aws_s3_bucket.test.id

    # 웹사이트 엔드포인트를 사용할 때는 custom_origin_config 필요
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # S3 웹사이트 엔드포인트는 HTTP만 지원
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.test.id
    viewer_protocol_policy = "redirect-to-https" # HTTPS 리다이렉트 추가
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_locations
    }
  }

  price_class = "PriceClass_All"

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
