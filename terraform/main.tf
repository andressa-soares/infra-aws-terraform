locals {
  action  = lower(var.action)
  enabled = local.action == "create" ? 1 : 0
}

# AMI Amazon Linux 2023 mais recente (x86_64).
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "this" {
  count = local.enabled

  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type

  tags = {
    Name   = var.instance_name
    Action = local.action
  }
}
