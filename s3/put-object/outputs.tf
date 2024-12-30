output "bucket" {
  value      = var.bucket
  depends_on = [module.s3_bucket_object]
}

output "key" {
  value      = var.key
  depends_on = [module.s3_bucket_object]
}
