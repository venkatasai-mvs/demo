variable "short_prefix" {
  type = string
}

variable "long_prefix" {
  type = string
}

variable "region" {
  type = any
}

variable "account_id" {
  type = string
}

variable "versioning" {
  type    = bool
  default = false
}

variable "deployment" {
  type    = any
  default = null
}
