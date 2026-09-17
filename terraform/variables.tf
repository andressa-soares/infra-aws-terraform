variable "aws_region" {
  description = "Regiao AWS."
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Valor da tag Name da instancia."
  type        = string
  default     = "ec2-pipeline"
}

variable "instance_type" {
  description = "Tipo da instancia EC2."
  type        = string
  default     = "t3.micro"
}

# Tag de controle: decide se a EC2 deve existir.
#   create -> count = 1 -> instancia criada/mantida
#   delete -> count = 0 -> instancia destruida no proximo apply
variable "action" {
  description = "Tag de controle: create ou delete."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "delete"], lower(var.action))
    error_message = "action deve ser \"create\" ou \"delete\"."
  }
}
