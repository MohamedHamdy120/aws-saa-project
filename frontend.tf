resource "aws_s3_bucket" "bucket" {
  bucket        = "guestbook-static-721937028581"
  force_destroy = true

  tags = { Name = "guestbook-static" }
}

resource "aws_s3_bucket_public_access_block" "bucket_block_access" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "OAI" {
  comment = "OAI for s3 static bucker"
}

resource "aws_cloudfront_distribution" "cloud-distribution" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.OAI.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = "ALB-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/health"
    allowed_methods        = ["HEAD", "GET", "POST", "OPTIONS", "DELETE", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET"]
    target_origin_id       = "ALB-origin"
    viewer_protocol_policy = "https-only"
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  }

  ordered_cache_behavior {
    path_pattern     = "/messages"
    allowed_methods  = ["HEAD", "GET", "POST", "OPTIONS", "DELETE", "PUT", "PATCH"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "ALB-origin"

    forwarded_values {
      headers      = []
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.bucket.id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "s3-policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Principal = { "AWS" : "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.OAI.id}" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.bucket.arn}/*"
      Effect    = "Allow"
    }]
  })
}
