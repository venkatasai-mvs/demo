variable "bucket" {
  type = string
}

variable "key" {
  type = string
}

variable "content" {
  type    = string
  default = null
}

variable "file" {
  type    = string
  default = null
}

variable "replace" {
  type    = bool
  default = false
}
