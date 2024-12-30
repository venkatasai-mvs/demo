locals {
  hash = md5("${var.bucket}/${var.key}")
}

module "temporary_directory" {
  path   = "${path.root}/.tmp/${local.hash}"
  source = "../../mkdir"
}

locals {
  file          = "${module.temporary_directory.path}/${local.key[length(local.key) - 1]}"
  key           = split("/", var.key)
  bucket_folder = join("/", slice(local.key, 0, length(local.key) - 1))
}

module "s3_bucket_object" {
  source  = "../../powershell-command"
  command = <<COMMAND
      aws s3 sync "s3://${var.bucket}/${local.bucket_folder}" "${module.temporary_directory.path}" --exclude='*' --include='${local.key[length(local.key) - 1]}'
  COMMAND
}
