output "instance_id" {
  description = "ID da instancia (null quando action = delete)."
  value       = try(aws_instance.this[0].id, null)
}

output "instance_public_ip" {
  description = "IP publico da instancia (null quando action = delete)."
  value       = try(aws_instance.this[0].public_ip, null)
}
