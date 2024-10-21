# S3 버킷 생성
resource "aws_s3_bucket" "test" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

# 객체 소유권 설정
resource "aws_s3_bucket_ownership_controls" "test" {
  bucket = aws_s3_bucket.test.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# ACL 활성화
resource "aws_s3_bucket_acl" "test" {
  depends_on = [aws_s3_bucket_ownership_controls.test]

  bucket = aws_s3_bucket.test.id
  acl    = "private"
}

# 정적 웹사이트 호스팅 설정
resource "aws_s3_bucket_website_configuration" "test" {
  bucket = aws_s3_bucket.test.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
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

# 퍼블릭 액세스 차단 비활성화
resource "aws_s3_bucket_public_access_block" "test" {
  bucket = aws_s3_bucket.test.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 버킷 정책
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid    = "Stmt1729475545628"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.test.arn}/*"] # ARN을 동적으로 참조하도록 수정
  }
}

resource "aws_s3_bucket_policy" "example" {
  depends_on = [aws_s3_bucket_public_access_block.test] # 퍼블릭 액세스 설정이 먼저 적용되도록 의존성 추가

  bucket = aws_s3_bucket.test.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
