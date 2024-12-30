module "temporary_directory" {
  path   = "${path.root}/.tmp"
  source = "../../mkdir"
}

locals {
  key = split("/", var.key)
  directory = var.file != null ? join(
    "/", [
      module.temporary_directory.path,
      md5(var.file),
    ]) : join(
    "/", [
      module.temporary_directory.path,
      md5(var.content)
  ])
}

module "content" {
  count  = var.content != null ? 1 : 0
  source = "../../powershell-command"
  command = <<COMMAND
  New-Item -ItemType "directory" -Path "${join("/", concat(
  [local.directory],
  slice(local.key, 0, length(local.key) - 1)
  ))}"
@'
${var.content}
'@ >> "${join("/", concat(
  [local.directory],
  local.key
))}"
  COMMAND
}

module "s3_bucket_object_exists" {
  count      = var.replace ? 0 : 1
  source     = "../../powershell-command"
  command    = <<COMMAND
aws s3api head-object --bucket ${var.bucket} --key ${var.key} 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
  "true"
} else {
  "false"
}
COMMAND
  depends_on = [module.content]
}

module "file_directory" {
  count = var.file != null ? 1 : 0
  path = (join(
    "/",
    concat(
      [
        local.directory,
      ],
      slice(local.key, 0, length(local.key) - 1)
    )
  ))
  source     = "../../mkdir"
  depends_on = [module.temporary_directory]
}

module "copy_into_directory" {
  count   = length(module.file_directory) > 0 ? 1 : 0
  source  = "../../powershell-command"
  command = <<COMMAND
  Copy-Item "${var.file}" -Destination "${module.file_directory[0].path}/${local.key[length(local.key) - 1]}"
  if (-not $?) {
    throw "Unable to copy '${var.file}' to '${module.file_directory[0].path}/${local.key[length(local.key) - 1]}'"
  }
  COMMAND
}

locals {
  file = var.file != null ? split("/", replace(var.file, "\\", "/")) : null
}

module "s3_bucket_object" {
  source = "../../powershell-command"
  command = <<COMMAND
    ${var.content != null || local.file != null ? <<CONTENT
      if (${length(module.s3_bucket_object_exists) > 0 ? (jsondecode(module.s3_bucket_object_exists[0].stdout) == true ? "$false" : "$true") : "$true"}) {
        aws s3 sync "${local.directory}" "s3://${var.bucket}" --exclude='*' --include='${var.key}'
      }
    CONTENT
  : <<CONTENT
      "NO CONTENT"
    CONTENT
}
  COMMAND
}
