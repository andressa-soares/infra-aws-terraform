# Tag de controle: create mantem a EC2, delete destroi (count = 0).
variable "action" {
  type    = string
  default = "create"

  validation {
    condition     = contains(["create", "delete"], var.action)
    error_message = "action deve ser create ou delete."
  }
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
