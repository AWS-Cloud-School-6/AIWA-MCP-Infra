# OAC 생성
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "example-oac"
  description                       = "OAC for CloudFront to access S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # 항상 서명된 요청 사용
  signing_protocol                  = "sigv4"  # SigV4 프로토콜 사용
}

# CloudFront 배포에 OAC 연동
resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [aws_cloudfront_origin_access_control.oac] # OAC 생성 후 배포

  origin {
    domain_name = aws_s3_bucket.test.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.test.id

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id # OAC 연결
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.test.id
    viewer_protocol_policy = "allow-all"
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
