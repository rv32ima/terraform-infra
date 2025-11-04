variable "prefix" {
  type = string
  default = ""
}

variable "availability_zones" {
  type = list(string)
  default = []
}