variable "aws_region" {
  default = "eu-west-1"
}

variable "s3_bucket_name" {
  default = "reisinger.co.uk"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id"
}

variable "hostname" {
  default = "reisinger.co.uk"
}
