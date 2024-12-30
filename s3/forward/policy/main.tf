module "lambda_policy" {
  source       = "../../../lambda/policy"
  short_prefix = "${var.short_prefix}-s3-obj-frw"
  long_prefix  = "${var.long_prefix}-s3api-object-forward"
  region       = var.region
  account_id   = var.account_id
}
