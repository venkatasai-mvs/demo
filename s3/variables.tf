variable "short_prefix" {
  type = string
}

variable "long_prefix" {
  type = string
}

variable "role" {
  type    = string
  default = null
}

variable "tags" {
  type = map(any)
}

variable "administrator_roles" {
  type = list(string)
}

variable "read_roles" {
  type    = list(string)
  default = []
}

variable "write_roles" {
  type    = list(string)
  default = []
}

variable "read_services" {
  type    = list(string)
  default = []
}

variable "write_services" {
  type    = list(string)
  default = []
}

variable "region" {
  type = any
}

variable "versioning" {
  description = "enabling the s3 bucket version"
  type        = bool
  default     = false
}

variable "sse_algorithm" {
  description = "choose the server-side encryption algorithm"
  type        = string
  default     = "aws:kms"
}

variable "persist" {
  type    = bool
  default = false
}

variable "account_id" {
  type = string
}

variable "kms" {
  type    = any
  default = null
}

# Do we have plans to replicate this bucket
variable "replication" {
  type    = bool
  default = true
}

variable "deployment" {
  type    = any
  default = null
}

variable "role_global_name" {
  type    = string
  default = null
}
