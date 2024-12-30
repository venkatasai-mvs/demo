module "white_list_bucket" {
  source              = "../../white-list"
  all_actions         = ["s3:*"]
  administrator_roles = var.administrator_roles
  title               = "Bucket"
  resources = [
    "arn:aws:s3:::${var.bucket}",
  ]
  actions_by_role = merge(
    {
      # https://trten.sharepoint.com/sites/intr-plat-eng/SitePages/Storage-Bucket-Lifecycle-Optimization.aspx?OR=Teams-HL&CT=1679066238812#for-aws
      "arn:aws:iam::${var.account_id}:role/service-role/a206255-TRUCCR-Audit" : [
        "s3:ListBucket",
        "s3:GetLifecycleConfiguration",
        "s3:GetBucketTagging",
      ]
      "arn:aws:iam::${var.account_id}:role/service-role/a208375-CloudGuard-Connect-RO-role" : [
        "s3:GetBucketTagging",
      ]
      "arn:aws:iam::${var.account_id}:role/service-role/a206076-TrCloudComplianceReadOnlyRole" : [
        "s3:GetBucketTagging",
      ]
      "arn:aws:iam::${var.account_id}:role/service-role/a206076-TrCloudComplianceFullAccess" : [
        "s3:GetBucketTagging",
      ]
    },
    [
      for role in concat(var.write_roles, var.read_roles) : {
        "${role}" : sort(distinct(concat(
          [
            "s3:GetBucketVersioning",
            "s3:ListBucket",
            "s3:ListBucketVersions",
            # For codepipeline
            "s3:GetBucketAcl",
            "s3:GetBucketLocation",
            # Replication
            "s3:GetReplicationConfiguration",
          ],
          contains(var.write_roles, role) ? [
            # Batch Operation
            "s3:PutInventoryConfiguration",
          ] : [],
        )))
      }
    ]...
  )
  actions_by_service = merge(
    [
      for service in concat(var.write_services, var.read_services) : {
        "${service}" : sort(distinct(concat(
          [
            "s3:GetBucketVersioning",
            "s3:ListBucket",
            "s3:ListBucketVersions",
            # For codepipeline
            "s3:GetBucketAcl",
            "s3:GetBucketLocation",
          ]
        )))
      }
    ]...
  )
}

module "white_list_bucket_key" {
  source              = "../../white-list"
  all_actions         = ["s3:*"]
  administrator_roles = var.administrator_roles
  title               = "BucketKey"
  resources = [
    "arn:aws:s3:::${var.bucket}/*",
  ]
  actions_by_role = merge(
    [
      for role in concat(var.write_roles, var.read_roles) : {
        "${role}" : sort(distinct(concat(
          [
            "s3:GetObject",
            "s3:GetObjectVersion",
            # For cross account object creation
            "s3:GetObjectTagging",
            # Replication
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging",
            # Batch Operation
            "s3:GetObject",
            "s3:GetObjectAcl",
            "s3:GetObjectTagging",
          ],
          contains(var.write_roles, role) ? [
            "s3:DeleteObject",
            "s3:PutObject",
            "s3:RestoreObject",
            # For load balancer logging
            "s3:PutObjectAcl",
            # Permissiosn to be replicated to
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags",
            # Batch Operation
            "s3:PutObject",
            "s3:PutObjectAcl",
            "s3:PutObjectTagging",
            "s3:InitiateReplication",
          ] : [],
        )))
      }
    ]...
  )
  actions_by_service = merge(
    [
      for service in concat(var.write_services, var.read_services) : {
        "${service}" : sort(distinct(concat(
          [
            "s3:GetObject",
            "s3:GetObjectVersion",
          ],
          contains(var.write_services, service) ? [
            "s3:DeleteObject",
            "s3:PutObject",
            "s3:RestoreObject",
            # For load balancer logging
            "s3:PutObjectAcl",
            # Permissiosn to be replicated to
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags"
          ] : [],
        )))
      }
    ]...
  )
}

module "policy_statements" {
  source = "../../compress-statements"
  statements = concat(
    module.white_list_bucket.statements,
    module.white_list_bucket_key.statements,
  )
}

locals {
  policy = {
    #"-------------------": "-------------------"
    "Version" : "2012-10-17",
    "Statement" : module.policy_statements.compressed,
  }
}

# module "bucket_policy_log" {
#   source = "../../log"
#   value  = "BUCKET POLICY: ${var.bucket}: ${jsonencode(local.policy)}"
# }

resource "aws_s3_bucket_policy" "object" {
  bucket = var.bucket
  policy = jsonencode(local.policy)
}
