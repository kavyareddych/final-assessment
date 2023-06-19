output "public_ip" {
  description = "EC2 instance public ip address"
  value       = aws_instance.ec2_instance.public_ip
}

output "keypair_name" {
  description = "EC2 instance keypair name"
  value       = aws_key_pair.ec2_key.key_name
}
