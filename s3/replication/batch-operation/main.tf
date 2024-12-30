module "replicate" {
  source  = "../../../powershell-command"
  command = <<COMMAND
$OPERATION = @{
  S3ReplicateObject = @{}
}
$REPORT = @{
  Bucket = "${var.bucket}"
  Prefix = "batch-replication-report"
  Format = "Report_CSV_20180820"
  Enabled = $true
  ReportScope = "AllTasks"
}
$MANIFEST_GENERATOR = @{
  S3JobManifestGenerator = @{
    ExpectedBucketOwner = "${var.account_id}"
    SourceBucket = "${var.bucket}"
    EnableManifestOutput = $false
    Filter = @{
      EligibleForReplication = $true
      # ObjectReplicationStatuses = @(
      #   "NONE"
      #   "FAILED"
      # )
    }
  }
}
aws s3control create-job --account-id ${var.account_id} `
  --operation "$(ConvertTo-Json "$(ConvertTo-Json -Depth 100 -Compress $OPERATION)")" `
  --report "$(ConvertTo-Json "$(ConvertTo-Json -Depth 100 -Compress $REPORT)")" `
  --manifest-generator "$(ConvertTo-Json "$(ConvertTo-Json -Depth 100 -Compress $MANIFEST_GENERATOR)")" `
  --priority 0 `
  --role-arn ${var.role} `
  --no-confirmation-required `
  --region ${var.region.long}
COMMAND
  # lifecycle {
  #   ignore_changes = all
  # }
}
