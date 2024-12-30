output "id" {
  value = aws_s3_bucket.object.id
  depends_on = [
    aws_s3_bucket_public_access_block.object,
    module.s3_policy,
    module.bugfix_destroy,
    aws_s3_bucket_versioning.object,
    aws_s3_bucket_server_side_encryption_configuration.object,
    //aws_s3_bucket_replication_configuration.object
  ]
}

output "arn" {
  value = aws_s3_bucket.object.arn
  depends_on = [
    aws_s3_bucket_public_access_block.object,
    module.s3_policy,
    module.bugfix_destroy,
    aws_s3_bucket_versioning.object,
    aws_s3_bucket_server_side_encryption_configuration.object,
    //aws_s3_bucket_replication_configuration.object
  ]
}