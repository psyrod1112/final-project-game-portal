resource "random_id" "suffix" {
  byte_length = 4
}

# --- Frontend bucket ---
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.name_prefix}-frontend-${random_id.suffix.hex}"
  tags   = merge(local.tags, { Name = "${var.name_prefix}-frontend" })
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  index_document { suffix = "index.html" }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.bucket
  key          = "index.html"
  content_type = "text/html"
  content = templatefile("${path.module}/frontend/index.html", {
    api_url = "http://${aws_lb.main.dns_name}"
  })
  depends_on = [aws_s3_bucket_policy.frontend]
}

# --- Game builds bucket ---
resource "aws_s3_bucket" "game_builds" {
  bucket = "${var.name_prefix}-builds-${random_id.suffix.hex}"
  tags   = merge(local.tags, { Name = "${var.name_prefix}-builds" })
}

resource "aws_s3_bucket_public_access_block" "game_builds" {
  bucket                  = aws_s3_bucket.game_builds.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "game_builds" {
  bucket = aws_s3_bucket.game_builds.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.game_builds.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.game_builds]
}

resource "aws_s3_object" "game_placeholder" {
  bucket       = aws_s3_bucket.game_builds.bucket
  key          = "game-v1.0.zip"
  content      = "Game Portal Demo Build v1.0 - placeholder for lab"
  content_type = "application/zip"
  depends_on   = [aws_s3_bucket_policy.game_builds]
}
