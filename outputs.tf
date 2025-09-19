
output "nomad_client_public_ip" {
  value = aws_instance.nomad_client[*].public_ip
}

output "nomad_server_public_ip" {
  value = aws_instance.nomad_server.public_ip
}
