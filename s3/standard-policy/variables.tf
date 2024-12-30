variable "administrator_roles" {
  description = "list of administration roles"
  type        = list(string)
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

variable "bucket" {
  type = string
}

variable "account_id" {
  type = string
}
