resource "aws_s3_bucket" "test" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

# 파일 업로드
resource "aws_s3_object" "object" {
  bucket       = aws_s3_bucket.test.id
  key          = var.upload_file_key
  source       = var.upload_file_path
  content_type = "text/html"
  etag         = filemd5(var.upload_file_path)
}

# S3 버킷 정책에 OAC 권한 부여
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.test.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.test.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
