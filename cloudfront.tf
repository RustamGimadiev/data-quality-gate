locals {
  cloudfront_origin_name      = "${local.resource_name_prefix}-s3-origin"
  aws_cloudfront_distribution = aws_cloudfront_distribution.reports[0].domain_name
}

resource "aws_cloudfront_origin_access_identity" "data_qa_oai" {
  comment = local.cloudfront_origin_name
}

resource "aws_cloudfront_origin_access_identity" "never_be_reached" {
  comment = "will-never-be-reached.org"
}

data "aws_iam_policy_document" "s3_policy_for_cloudfront" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.fast_data_qa.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.data_qa_oai.id}"
      ]
    }
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.fast_data_qa.arn]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.data_qa_oai.id}"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.fast_data_qa.id
  policy = data.aws_iam_policy_document.s3_policy_for_cloudfront.json
}

resource "aws_cloudfront_distribution" "reports" {
  count = var.create_cloudfront ? 1 : 0

  aliases = var.cloudfront_cnames

  origin {
    domain_name = aws_s3_bucket.fast_data_qa.bucket_regional_domain_name
    origin_id   = local.resource_name_prefix

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.data_qa_oai.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = "will-never-be-reached.org"
    origin_id   = "dummy-origin"

    custom_origin_config {
      origin_protocol_policy = "match-viewer"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = local.resource_name_prefix
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "dummy-origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/profiling/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.resource_name_prefix

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/allure/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.resource_name_prefix

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 2
  ordered_cache_behavior {
    path_pattern     = "/data_docs/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.resource_name_prefix

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Additional cache behavior
  dynamic "ordered_cache_behavior" {
    for_each = var.cloudfront_additional_cache_behaviors
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      allowed_methods  = ordered_cache_behavior.value.allowed_methods
      cached_methods   = ordered_cache_behavior.value.cached_methods
      target_origin_id = local.resource_name_prefix

      forwarded_values {
        query_string = false
        cookies {
          forward = "none"
        }
      }

      dynamic "lambda_function_association" {
        for_each = ordered_cache_behavior.value.lambda_function_associations
        content {
          event_type = lambda_function_association.value.event_type
          lambda_arn = lambda_function_association.value.lambda_arn
        }
      }

      min_ttl                = 0
      default_ttl            = 3600
      max_ttl                = 86400
      compress               = true
      viewer_protocol_policy = "redirect-to-https"
    }
  }

  price_class = "PriceClass_200"

  dynamic "restrictions" {
    for_each = var.cloudfront_location_restrictions != [] ? ["whitelist"] : ["none"]
    content {
      geo_restriction {
        restriction_type = restrictions.value
        locations        = var.cloudfront_location_restrictions
      }
    }
  }

  tags = var.tags

  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == "" ? true : false
    acm_certificate_arn            = var.certificate_arn == "" ? null : var.certificate_arn
    ssl_support_method             = "sni-only"
  }

  web_acl_id = var.cloudfront_acl
}
