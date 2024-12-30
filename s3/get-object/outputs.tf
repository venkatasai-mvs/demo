output "content" {
  value      = file(local.file)
  depends_on = [module.s3_bucket_object]
}
