variable "short_prefix" {
  type = string
}

variable "long_prefix" {
  type = string
}

variable "role" {
  type = string
}

variable "tags" {
  type = map(any)
}

variable "region" {
  type = any
}

variable "account_id" {
  type = string
}

variable "deployment" {
  type    = any
  default = null
}

variable "bucket" {
  type = any
}

variable "role_global_name" {
  type = string
}

variable "bucket_global_name" {
  type = string
}

variable "kms_name" {
  type    = string
  default = null
}
