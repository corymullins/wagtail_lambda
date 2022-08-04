resource random_id bucket_id {
  byte_length  = 8
}

resource "aws_s3_bucket" "frontend_bucket" {
    bucket = "${var.name_prefix}-${random_id.bucket_id.hex}-code"
  tags = {
    Environment = var.environment_tag
  }
}

resource "aws_s3_bucket_website_configuration" "frontend_bucket_config" {
  bucket = aws_s3_bucket.frontend_bucket.bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_acl" "frontend_bucket_acl" {
  bucket = aws_s3_bucket.frontend_bucket.id
  acl    = "private"
}

# resource "aws_s3_bucket_policy" "bucket_policy" {
#   bucket = aws_s3_bucket.frontend_bucket.id
#     policy = <<EOT
# {
#     "Version": "2008-10-17",
#     "Id": "PolicyForCloudFrontPrivateContent",
#     "Statement": [
#         {
#             "Sid": "1",
#             "Effect": "Allow",
#             "Principal": {
#                 "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity EYTSOKDRCWH6U"
#             },
#             "Action": "s3:GetObject",
#             "Resource": "arn:aws:s3:::www.corymullins.com/*"
#         }
#     ]
# }
# EOT
# }

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_bucket_sse" {
  bucket = aws_s3_bucket.frontend_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource aws_s3_bucket_public_access_block code_not_public {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource aws_s3_bucket_object lambda_zip {
  bucket = aws_s3_bucket.frontend_bucket.bucket
  key    = "lambda-${filemd5("../out/lambda.zip")}.zip"
  source = "../out/lambda.zip"
}

resource aws_s3_bucket media {
  bucket = "${var.name_prefix}-${random_id.bucket_id.hex}-media"
  tags = {
    Environment = var.environment_tag
  }
}

resource aws_s3_bucket_public_access_block media_not_public {
  bucket = aws_s3_bucket.media.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

locals {
  static_bucket = "${var.name_prefix}-${random_id.bucket_id.hex}-static"
  static_url = "https://${aws_cloudfront_distribution.cf.domain_name}/s/"
}

resource aws_s3_bucket static {
  bucket = local.static_bucket
  acl = "private"

  tags = {
    Environment = var.environment_tag
  }

  website {
    index_document = "index.html"
  }

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${local.static_bucket}/*"
      ]
    }
  ]
}
POLICY
}

resource aws_s3_bucket_public_access_block static_public {
  bucket = aws_s3_bucket.static.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_object" "static_index_html" {
  bucket = aws_s3_bucket.static.bucket
  key    = "index.html"
  content = "<html><body><a href=\"${aws_apigatewayv2_api.apigw.api_endpoint}\">Home</a></body></html>"
  content_type = "text/html"
}

# S3 bucket data to upload
locals {
  mime_types = {
    "css" = "text/css"
    "html" = "text/html"
    "ico"  = "image/vnd.microsoft.icon"
    "jpeg" = "image/jpeg"
    "js"   = "application/javascript"
    "json" = "application/json"
    "map"  = "application/json"
    "pdf"  = "application/pdf"
    "png"  = "image/png"
    "svg"  = "image/svg+xml"
    "txt"  = "text/plain"
  }
}
resource "aws_s3_object" "frontend_data" {
  for_each = fileset("frontend_data/*", "**/*.*")
  bucket = aws_s3_bucket.frontend_bucket.id
  key = each.key
  source = "frontend_data/${each.key}"
  content_type = lookup(tomap(local.mime_types), element(split(".", each.key), length(split(".", each.key)) - 1))
  etag = filemd5("frontend_data/${each.key}")
}