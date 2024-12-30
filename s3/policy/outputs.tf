output "statements" {
  value = concat(
    [
      # https://docs.aws.amazon.com/AmazonS3/latest/userguide/setting-repl-config-perm-overview.html
      {
        "Action" : distinct([
          # Replication
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          # Batch Operation
          "s3:ListBucket",
          "s3:PutInventoryConfiguration",
        ]),
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${var.short_prefix}-${var.region.short}-${var.account_id}"
        ]
      },
      {
        "Action" : distinct([
          # Replication
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          # Batch Operation
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetObjectAcl",
          "s3:GetObjectTagging",
          "s3:InitiateReplication",
        ]),
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${var.short_prefix}-${var.region.short}-${var.account_id}/*"
        ]
      },
      {
        "Action" : [
          "kms:Decrypt",
        ],
        "Effect" : "Allow",
        "Condition" : {
          "StringLike" : {
            "kms:ViaService" : "s3.${var.region.long}.amazonaws.com",
            "kms:EncryptionContext:aws:s3:arn" : [
              "arn:aws:s3:::${var.short_prefix}-${var.region.short}-${var.account_id}/*"
            ]
          }
        },
        "Resource" : [
          "*"
        ]
      },
    ],
    jsondecode(var.deployment != null ? jsonencode(flatten([for source_region in lookup(var.deployment, "sibling_regions", []) : [
      {
        "Action" : distinct([
          # Replication
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          # Batch operation
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging"
        ]),
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${var.short_prefix}-${source_region.short}-${var.account_id}/*"
        ]
      },
      {
        "Action" : [
          "kms:Encrypt",
        ],
        "Effect" : "Allow",
        "Condition" : {
          "StringLike" : {
            "kms:ViaService" : "s3.${var.region.long}.amazonaws.com",
            "kms:EncryptionContext:aws:s3:arn" : [
              "arn:aws:s3:::${var.short_prefix}-${source_region.short}-${var.account_id}/*"
            ]
          }
        },
        "Resource" : [
          "*"
        ]
      }
    ] if source_region.long != var.region.long])) : jsonencode([]))
    # jsondecode(var.versioning && var.replicate_region != null ? jsonencode([
    #   {
    #     "Action" : [
    #       "s3:ReplicateObject",
    #       "s3:ReplicateDelete",
    #       "s3:ReplicateTags"
    #     ],
    #     "Effect" : "Allow",
    #     "Resource" : [
    #       "arn:aws:s3:::${var.short_prefix}-${var.region.short}-rpl-${var.replicate_region[0].short}-${var.account_id}/*"
    #     ]
    #   },
    #   {
    #     "Action" : [
    #       "kms:Decrypt"
    #     ],
    #     "Effect" : "Allow",
    #     "Condition" : {
    #       "StringLike" : {
    #         "kms:ViaService" : "s3.${var.replicate_region[0].long}.amazonaws.com",
    #         "kms:EncryptionContext:aws:s3:arn" : [
    #           "arn:aws:s3:::${var.short_prefix}-${var.region.short}-${var.account_id}/*"
    #         ]
    #       }
    #     },
    #     "Resource" : [
    #       "*"
    #     ]
    #   },
    #   {
    #     "Action" : [
    #       "kms:Encrypt"
    #     ],
    #     "Effect" : "Allow",
    #     "Condition" : {
    #       "StringLike" : {
    #         "kms:ViaService" : "s3.${var.replicate_region[0].long}.amazonaws.com",
    #         "kms:EncryptionContext:aws:s3:arn" : [
    #           "arn:aws:s3:::${var.short_prefix}-${var.region.short}-rpl-${var.replicate_region[0].short}-${var.account_id}/*"
    #         ]
    #       }
    #     },
    #     "Resource" : [
    #       "*"
    #     ]
    #   }
    # ]) : jsonencode([]))
  )
}

output "assume_statements" {
  value = concat(
    [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : [
            "s3.amazonaws.com",
            "batchoperations.s3.amazonaws.com",
          ]
        },
        "Effect" : "Allow",
      }
    ]
  )
}

output "identifiers" {
  value = {
    "name" : "${var.short_prefix}-${var.region.short}-${var.account_id}"
    "arn" : "arn:aws:s3:::${var.short_prefix}-${var.region.short}-${var.account_id}"
  }
}

output "long_prefix" {
  value = var.long_prefix
}

output "short_prefix" {
  value = var.short_prefix
}
