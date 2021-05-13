provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {}

# aws

resource "aws_s3_bucket" "hugo" {
  bucket = var.s3_bucket_name
  acl    = "public-read"
  policy = templatefile("${path.module}/policy.tmpl", { s3_bucket_name = var.s3_bucket_name })

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

# cloudflare

resource "cloudflare_record" "www_redirect" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  value   = "192.0.2.1" # dummy IP, resource is only for www redirect
  type    = "A"
  ttl     = 3600
}

resource "cloudflare_page_rule" "www_redirect" {
  zone_id = var.cloudflare_zone_id
  target  = format("www.%s/*", var.hostname)

  actions {
    forwarding_url {
      url         = format("https://%s/$1", var.hostname)
      status_code = 301
    }
    ssl = "flexible"
  }
}

resource "cloudflare_record" "site" {
  zone_id = var.cloudflare_zone_id
  name    = var.hostname
  value   = format("%s.s3-website.%s.amazonaws.com", var.s3_bucket_name, var.aws_region)
  type    = "CNAME"
  ttl     = 3600
}
