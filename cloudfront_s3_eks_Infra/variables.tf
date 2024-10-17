variable "region" {
  description = "region"
  type        = string
  default     = "ap-northeast-2"
}

# AWS 프로필 설정 (로컬 인증 사용 시 필요)
variable "profile" {
  description = "The AWS CLI profile to use for credentials"
  type        = string
  default     = "default"
}

# S3 버킷 이름 정의
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "tf-test-hyeob-bucket-991906"
}

# S3 버킷 태그 - 환경 설정
variable "environment" {
  description = "Deployment environment for the S3 bucket"
  type        = string
  default     = "Dev"
}

# S3 파일 업로드 키와 경로
variable "upload_file_path" {
  description = "Path to the file to upload to S3"
  type        = string
  default     = "template/index.html"
}

variable "upload_file_key" {
  description = "Key (path) of the object to be stored in the S3 bucket"
  type        = string
  default     = "index.html"
}

# CloudFront 배포 설명
variable "cloudfront_comment" {
  description = "Comment for the CloudFront distribution"
  type        = string
  default     = "This is a test distribution"
}

# CloudFront 지리적 제한 (Whitelist 국가 목록)
variable "geo_restriction_type" {
  description = "Geo restriction type for CloudFront (none, whitelist, blacklist)"
  type        = string
  default     = "none"
}

variable "geo_locations" {
  description = "List of countries for geo restriction"
  type        = list(string)
  default     = []
}
