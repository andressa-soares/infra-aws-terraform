output "instance_id" {
  value = try(aws_instance.this[0].id, null)
}

output "instance_public_ip" {
  value = try(aws_instance.this[0].public_ip, null)
}
