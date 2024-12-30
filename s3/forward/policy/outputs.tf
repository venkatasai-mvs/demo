output "statements" {
  value = concat(
    module.lambda_policy.statements,
    [
      {
        "Action" : [
          "s3:GetObject",
        ],
        "Resource" : concat(
          lookup(var.identifiers.source.s3, "arns", null) != null ? var.identifiers.source.s3.arns : [],
          lookup(var.identifiers.source.s3, "arn", null) != null ? [var.identifiers.source.s3.arn] : [],
          lookup(var.identifiers.source.s3, "bucket", null) != null ? ["arn:aws:s3:::${var.identifiers.source.s3.bucket}/${var.identifiers.source.s3.key}"] : []
        )
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:PutObject",
        ],
        "Resource" : concat(
          lookup(var.identifiers.destination.s3, "arns", null) != null ? var.identifiers.destination.s3.arns : [],
          lookup(var.identifiers.destination.s3, "arn", null) != null ? [var.identifiers.destination.s3.arn] : [],
          lookup(var.identifiers.destination.s3, "bucket", null) != null ? ["arn:aws:s3:::${var.identifiers.destination.s3.bucket}/${var.identifiers.destination.s3.key}"] : []
        )
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "codepipeline:PutJobSuccessResult",
          "codepipeline:PutJobFailureResult",
        ],
        "Resource" : [
          "*"
        ],
        "Effect" : "Allow"
      }
    ]
  )
}

output "assume_statements" {
  value = concat(
    module.lambda_policy.assume_statements,
    [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "states.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  )
}

output "long_prefix" {
  value = var.long_prefix
}

output "short_prefix" {
  value = var.short_prefix
}

output "identifiers" {
  value = {
    arn = "arn:aws:lambda:${var.region.long}:${var.account_id}:function:${module.lambda_policy.short_prefix}"
    source = {
      s3 = merge(
        lookup(var.identifiers.source.s3, "arns", null) != null ? {
          "arns" : var.identifiers.source.s3.arns
        } : {},
        lookup(var.identifiers.source.s3, "arn", null) != null ? {
          "arn" : var.identifiers.source.s3.arn
        } : {},
        lookup(var.identifiers.source.s3, "bucket", null) != null ? {
          "bucket" : {
            "arn" : "arn:aws:s3:::${var.identifiers.source.s3.bucket}"
            "name" : var.identifiers.source.s3.bucket
          }
          "object" : {
            "arn" : "arn:aws:s3:::${var.identifiers.source.s3.bucket}/${var.identifiers.source.s3.key}"
            "key" : var.identifiers.source.s3.key
          }
        } : {}
      )
    }
    destination = {
      s3 = merge(
        lookup(var.identifiers.destination.s3, "arns", null) != null ? {
          "arns" : var.identifiers.destination.s3.arns
        } : {},
        lookup(var.identifiers.destination.s3, "arn", null) != null ? {
          "arn" : var.identifiers.destination.s3.arn
        } : {},
        lookup(var.identifiers.destination.s3, "bucket", null) != null ? {
          "bucket" : {
            "arn" : "arn:aws:s3:::${var.identifiers.destination.s3.bucket}"
            "name" : var.identifiers.destination.s3.bucket
          }
          "object" : {
            "arn" : "arn:aws:s3:::${var.identifiers.destination.s3.bucket}/${var.identifiers.destination.s3.key}"
            "key" : var.identifiers.destination.s3.key
          }
        } : {}
      )
    }
  }
}
