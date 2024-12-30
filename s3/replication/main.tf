locals {
  sibling_regions = var.deployment != null ? { for region in lookup(var.deployment, "sibling_regions", []) : region.short => region if region.long != var.region.long } : {}
}

resource "aws_s3_bucket_replication_configuration" "object" {
  count  = length(local.sibling_regions) > 0 ? 1 : 0
  bucket = var.bucket.id
  role   = var.role
  dynamic "rule" {
    for_each = local.sibling_regions
    content {
      id       = rule.value.long
      priority = index(lookup(var.deployment, "sibling_regions", []), rule.value)
      status   = "Enabled"
      filter {
      }
      delete_marker_replication {
        status = "Enabled"
      }
      destination {
        bucket        = "arn:aws:s3:::${var.bucket_global_name}-${rule.value.short}-${var.account_id}"
        storage_class = "STANDARD"
        dynamic "encryption_configuration" {
          for_each = var.kms_name != null ? [true] : []
          content {
            replica_kms_key_id = "arn:aws:kms:${rule.value.long}:${var.account_id}:alias/${var.kms_name}"
          }
        }
        metrics {
          status = "Enabled"
          event_threshold {
            minutes = 15
          }
        }
        replication_time {
          status = "Enabled"
          time {
            # https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-time-control.html
            minutes = 15
          }
        }
      }
      # Creating or enabling rules with existing object replication enabled is no longer supported.
      # existing_object_replication {
      #   status = "Enabled"
      # }
      dynamic "source_selection_criteria" {
        for_each = var.kms_name != null ? [true] : []
        content {
          sse_kms_encrypted_objects {
            status = "Enabled"
          }
        }
      }
    }
  }
}

module "replicate_push" {
  for_each   = local.sibling_regions
  source     = "./batch-operation"
  account_id = var.account_id
  bucket     = var.bucket.arn
  role       = var.role
  region     = var.region
  depends_on = [
    aws_s3_bucket_replication_configuration.object,
  ]
}

module "replicate_pull" {
  count      = var.deployment != null ? lookup(var.deployment, "primary_region", var.region).long != var.region.long ? 1 : 0 : 0
  source     = "./batch-operation"
  account_id = var.account_id
  bucket     = "arn:aws:s3:::${var.bucket_global_name}-${var.deployment.primary_region.short}-${var.account_id}"
  role       = "arn:aws:iam::${var.account_id}:role/${var.role_global_name}-${var.deployment.primary_region.short}"
  region     = var.deployment.primary_region
  depends_on = [
    aws_s3_bucket_replication_configuration.object,
  ]
}
