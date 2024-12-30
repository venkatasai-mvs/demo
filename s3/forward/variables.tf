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

variable "retention_in_days" {
  type = number
}

variable "src" {
  type = any
}

variable "dst" {
  type = any
}
