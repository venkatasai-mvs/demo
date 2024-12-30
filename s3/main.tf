# module "s3_replication" {
#   providers = {
#     aws = aws.replicate
#   }
#   source              = "./replication"
#   count               = var.replicate_region != null ? 1 : 0
#   short_prefix        = var.short_prefix
#   long_prefix         = var.long_prefix
#   role                = var.role
#   tags                = var.tags
#   administrator_roles = var.administrator_roles
#   write_roles         = var.write_roles
#   read_roles          = var.read_roles
#   region              = var.region
#   replicate_region    = var.replicate_region
#   sse_algorithm       = var.sse_algorithm
#   persist             = var.persist
#   account_id          = var.account_id
#   kms                 = var.replicate_kms
# }

locals {
  sibling_regions = var.deployment != null ? { for region in lookup(var.deployment, "sibling_regions", []) : region.short => region if region.long != var.region.long } : {}
  write_roles = concat(
    var.write_roles,
    [for name, sibling_region in local.sibling_regions : "arn:aws:iam::${var.account_id}:role/${var.role_global_name}-${sibling_region.short}"]
  )
}

module "kms" {
  count               = (var.kms == null && var.sse_algorithm == "aws:kms") ? 1 : 0
  source              = "../kms"
  short_prefix        = "${var.short_prefix}-s3"
  long_prefix         = "${var.long_prefix}-s3"
  administrator_roles = var.administrator_roles
  read_roles          = concat(var.read_roles, local.write_roles)
  tags                = var.tags
  description         = var.long_prefix
}

resource "aws_s3_bucket" "object" {
  bucket = "${var.short_prefix}-${var.region.short}-${var.account_id}"

  tags = merge(
    {
      Name = "${var.short_prefix}-${var.region.short}-${var.account_id}"
    },
  var.tags)
  force_destroy = !var.persist
}

resource "aws_s3_bucket_versioning" "object" {
  bucket = aws_s3_bucket.object.bucket
  versioning_configuration {
    status = var.versioning || var.replication /*|| var.replicate_region != null*/ ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "object" {
  count  = var.sse_algorithm == null ? 0 : 1
  bucket = aws_s3_bucket.object.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? "alias/${var.kms == null ? module.kms[0].name : var.kms.name}" : null
      sse_algorithm     = var.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_public_access_block" "object" {
  bucket                  = aws_s3_bucket.object.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.object]
}

module "s3_policy" {
  source              = "./standard-policy"
  administrator_roles = var.administrator_roles
  read_roles          = var.read_roles
  write_roles         = local.write_roles
  read_services       = var.read_services
  write_services      = var.write_services
  bucket              = aws_s3_bucket.object.id
  account_id          = var.account_id
  #  depends_on          = [aws_s3_bucket_public_access_block.object]
}

# https://github.com/hashicorp/terraform-provider-aws/issues/12146
module "bugfix_destroy" {
  count       = var.persist ? 0 : 1
  source      = "./delete-objects"
  bucket_name = aws_s3_bucket.object.id
}

module "replication" {
  source       = "./replication"
  short_prefix = var.short_prefix
  long_prefix  = var.long_prefix
  role         = var.role
  tags         = var.tags
  region       = var.region
  account_id   = var.account_id
  deployment   = var.deployment
  bucket = {
    id  = aws_s3_bucket.object.bucket
    arn = aws_s3_bucket.object.arn
  }
  role_global_name   = var.role_global_name
  bucket_global_name = var.short_prefix
  kms_name           = length(module.kms) > 0 ? module.kms[0].name : null
  depends_on = [
    aws_s3_bucket_versioning.object,
    module.s3_policy,
    module.bugfix_destroy,
  ]
}
